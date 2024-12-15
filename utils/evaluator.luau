local Evaluator = {}
local Error = require("error")
local Types = require("types")

local function mix_tables(t1, t2)
    local base = table.clone(t1)
    for k, v in t2 do
        base[k] = v
    end
    return base
end

function Evaluator:getSymbol(id, symbols)
    local entry = (symbols or {})[id] or self.symbolTable[id]
    if entry then return entry end
    if self.parent then return self.parent:getSymbol(id) end
    return nil
end
function Evaluator:setVariable(id, value, symbols)
    local entry = (symbols or {})[id] or self.symbolTable[id]
    if not entry then
        if self.parent then
            return self.parent:setVariable(id, value)
        end
        self:handleError(`Variable '{id}' is undefined.`)
    end
    if not entry.mutable then
        self:handleError(`Cannot modify constant '{id}'.`)
    end
    local typeaccepted = Types.isValueType(entry.type, entry, value)
    if not typeaccepted then
        self:handleError(`Invalid value given to type: {entry.type} = {value}`)
    end
    entry.value = value
    return value
end
local function createVariable(self, value, type, symbolType, mutable)
    if type == "auto" then
        type = Types.getDataTypeNameById(Types.luaGetValueType(value))
    end
    local var = {
        type = type,
        vartype = symbolType,
        value = value,
        mutable = mutable
    }
    local typeaccepted = Types.isValueType(type, var, value)
    if not typeaccepted then
        self:handleError(`Invalid value given to type: {type} = {value}`)
    end
    return var
end
function Evaluator:declareSymbol(id, value, type, symbolType, mutable, symbols)
    if self:getSymbol(id, symbols) then
        self:handleError(`Symbol '{id}' is already declared.`)
    end
    self.symbolTable[id] = createVariable(self, value, type, symbolType, mutable)
end

local function switch_case(var, cases, default, ...)
    local f = cases[var] or default
    return f and f(...)
end

local binary_expression_cases = {
    ["+"] = function(left, right)
        if type(left) == "string" or type(right) == "string" then
            return left .. right
        else
            return left + right
        end
    end,
    ["-"] = function(left, right) return left - right end,
    ["*"] = function(left, right) return left * right end,
    ["/"] = function(left, right) return left / right end,
    ["%"] = function(left, right) return left % right end,
    ["=="] = function(left, right) return left == right end,
    ["!="] = function(left, right) return left ~= right end,
    ["<"] = function(left, right) return left < right end,
    [">"] = function(left, right) return left > right end,
    ["<="] = function(left, right) return left <= right end,
    [">="] = function(left, right) return left >= right end,
    ["and"] = function(left, right) return left and right end,
    ["or"] = function(left, right) return left or right end,
    ["&&"] = function(left, right) return left and right end,
    ["||"] = function(left, right) return left or right end,
    ["^"] = function(left, right) return bit32.bxor(left, right) end,
    ["&"] = function(left, right) return bit32.band(left, right) end,
    ["|"] = function(left, right) return bit32.bor(left, right) end,
    ["<<"] = function(left, right) return bit32.lshift(left, right) end,
    [">>"] = function(left, right) return bit32.rshift(left, right) end,
}

local node_type_cases = {
    ["NullPointer"] = function(_self, _node, _variables)
        return nil
    end,
    ["Literal"] = function(_self, node, _variables)
        return node.value
    end,
    ["LambdaLiteral"] = function(_self, node, _variables)
        return {
            arguments = node.arguments,
            body = node.body,
            type = "fn",
        }
    end,
    ["UnaryExpression"] = function(self, node, variables)
        local value = self:evaluate(node.value, variables)
        local operator = node.operator
        if operator == "-" then return -value
        elseif operator == "not" then return not value
        elseif operator == "~" then return bit32.bnot(value)
        end
        self:handleError("Unknown unary operator: " .. node.operator)
        return
    end,
    ["ArrayExpression"] = function(self, node, variables)
        local array = {}
        for _, elementNode in ipairs(node.elements) do
            table.insert(array, self:evaluate(elementNode, variables))
        end
        return { type = "array", value = array }
    end,
    ["DictExpression"] = function(self, node, variables)
        local dict = {}
        for k, v in node.pairs do
            local key = self:evaluate(k, variables)
            local value = self:evaluate(v, variables)
            dict[key] = value
        end
        return { type = "dict", value = dict }
    end,
    ["TableIndex"] = function(self, node, variables)
        local table = self:evaluate(node.base, variables)
        local index = self:evaluate(node.index, variables)
        if table.type == "array" and (typeof(index) ~= "number" and index % 1 ~= 0) then
            self:handleError(`Attempted to index array with non-integer value: {index}`)
        elseif table.type == "fn" then
            self:handleError(`Attempted to index a function value`)
        end
        return table.value[index]
    end,
    ["BinaryExpression"] = function(self, node, variables)
        local left = self:evaluate(node.left, variables)
        local right = self:evaluate(node.right, variables)
        return switch_case(node.operator, binary_expression_cases, function()
            self:handleError("Unknown operator: " .. node.operator)
        end, left, right)
    end,
    ["IfStatement"] = function(self, node, variables)
        local condition = self:evaluate(node.condition, variables)
        if condition then
            self:evaluate(node.thenBlock, variables)
        elseif node.elseBlock then
            self:evaluate(node.elseBlock, variables)
        end
    end,
    ["WhileStatement"] = function(self, node, variables)
        local condnode = node.condition
        local codeblock = node.codeBlock
        local condition = self:evaluate(condnode, variables)
        self.loopContext = { breakFlag = false, continueFlag = false }
        while condition and not self.resulted do
            self:evaluate(codeblock, variables)
            if self.loopContext.breakFlag then
                break
            elseif self.loopContext.continueFlag then
                self.loopContext.continueFlag = false -- Reset 'continue'
            end
            condition = self:evaluate(condnode, variables)
        end
        self.loopContext = nil
    end,
    ["ForStatement"] = function(self, node, variables)
        self:evaluate(node.definition, variables)
        local condnode = node.condition
        local opnode = node.operation
        local codeblock = node.codeBlock
        local condition = self:evaluate(condnode, variables)
        self.loopContext = { breakFlag = false, continueFlag = false }
        while condition and not self.resulted do
            condition = self:evaluate(condnode, variables)
            self:evaluate(codeblock, variables)
            self:evaluate(opnode, variables)
            if self.loopContext.breakFlag then
                break
            elseif self.loopContext.continueFlag then
                self.loopContext.continueFlag = false -- Reset 'continue'
            end
        end
        self.loopContext = nil
    end,
    ["ForEachStatement"] = function(self, node, variables)
        local key, value = node.key, node.value
        local kn, vn = key.name, value.name
        local codeblock = node.codeBlock
        self:evaluate(key, variables)
        self:evaluate(value, variables)
        local source = self:evaluate(node.source, variables)
        self.loopContext = { breakFlag = false, continueFlag = false }
        for k, v in source.value do
            if self.resulted then break end
            variables[kn] = createVariable(self, k, nil, "loop", true)
            variables[vn] = createVariable(self, v, nil, "loop", true)
            self:evaluate(codeblock, variables)
            if self.loopContext.breakFlag then
                break
            elseif self.loopContext.continueFlag then
                self.loopContext.continueFlag = false -- Reset 'continue'
            end
        end
        self.loopContext = nil
    end,
    ["CodeBlock"] = function(self, node, variables)
	    local nself = Evaluator.new()
        nself.loopContext = self.loopContext
        nself.parent = self
        for _, block in node.code do
            nself:evaluate(block, variables)
            -- If part of a loop and break/continue is encountered, stop execution
            if nself.loopContext and (nself.loopContext.breakFlag or nself.loopContext.continueFlag) then
                break
            end
        end
        if node.blocktype == "block" and nself.resulted then
            self.resulted = true
            self.result = nself.result
        end
        return nself.result
    end,
    ["AssignmentExpression"] = function(self, node, variables)
        local value = self:evaluate(node.value, variables)
        local target = node.target
        if target.type == "TableIndex" then
            local table = self:evaluate(target.base, variables)
            local index = self:evaluate(target.index, variables)
            if table.type == "array" and (typeof(index) ~= "number" and index % 1 ~= 0) then
                self:handleError(`Attempted to index array with non-integer value: {index}`)
            elseif table.type == "fn" then
                self:handleError(`Attempted to index a function value`)
            end
            table.value[index] = value
        elseif node.target.type == "Identifier" then
            self:setVariable(target.value, value, variables)
        else
            self:handleError(`Invalid assignee ({target.type}) given to assignment`)
        end
        return value
    end,
    ["CompoundAssignmentExpression"] = function(self, node, variables)
        local value = self:evaluate(node.value, variables)
        local target = node.target
        local operator = node.operator
        if target.type == "TableIndex" then
            local table = self:evaluate(target.base, variables)
            local index = self:evaluate(target.index, variables)
            if table.type == "array" and (typeof(index) ~= "number" and index % 1 ~= 0) then
                self:handleError(`Attempted to index array with non-integer value: {index}`)
            elseif table.type == "fn" then
                self:handleError(`Attempted to index a function value`)
            end
            table.value[index] = switch_case(operator, binary_expression_cases, function()
                self:handleError("Unsupported operator in compound assignment: " .. operator)
            end, table.value[index], value)
        elseif target.type == "Identifier" then
            local current = self:evaluate(target, variables)
            local target_value = switch_case(operator, binary_expression_cases, function()
                self:handleError("Unsupported operator in compound assignment: " .. operator)
            end, current, value)
            self:setVariable(target.value, target_value, variables)
        else
            self:handleError(`Invalid assignee ({target.type}) given to assignment`)
        end
        return value
    end,
    ["VariableDefinition"] = function(self, node, variables)
        local value = self:evaluate(node.value, variables)
        self:declareSymbol(node.name, value, node.vartype, "any", true, variables)
        return value
    end,
    ["TempVariableDefinition"] = function(self, node, variables)
        local name = node.name
        if self:getSymbol(name, variables) then
            self:handleError(`Symbol '{name}' is already declared.`)
        end
        local value = self:evaluate(node.value, variables)
        variables[name] = createVariable(self, value, nil, "any", true)
        return value
    end,
    ["ConstDeclaration"] = function(self, node, variables)
        local value = self:evaluate(node.value, variables)
        self:declareSymbol(node.name, value, node.vartype, "any", false, variables)
        return value
    end,
    ["FunctionDeclaration"] = function(self, node, variables)
        local fn = {
            arguments = node.arguments,
            body = node.body,
            type = "fn",
        }
        self:declareSymbol(node.name, fn, nil, "fn", true, variables)
    end,
    ["FunctionCall"] = function(self, node, variables)
        local base = node.base
        local fnEntry = self:evaluate(base, variables)
        if type(fnEntry) == "table" then
            if not fnEntry.type or fnEntry.type ~= "fn" then
                self:handleError(`'{base.value}' is not a function.`)
            end
            if #node.args ~= #fnEntry.arguments then
                self:handleError(`Function '{base.value}' expects {#fnEntry.arguments} arguments, got {#node.args}.`)
            end
            local localVars = {}
            for i, argName in fnEntry.arguments do
                localVars[argName] = createVariable(self, self:evaluate(node.args[i], variables), nil, "any", true)
            end
            return self:evaluate(fnEntry.body, mix_tables(variables, localVars))
        elseif type(fnEntry) == "function" then
            local localVars = {}
            for i = 1, #node.args do
                localVars[i] = self:evaluate(node.args[i], variables)
            end
            return fnEntry(table.unpack(localVars))
        end
        return
    end,
    ["Identifier"] = function(self, node, variables)
        local name = node.value
        local symbol = self:getSymbol(name, variables)
        if not symbol then
            self:handleError(`Undefined identifier: '{name}'`)
        end
        return symbol.value
    end,
    ["ReturnExpression"] = function(self, node, variables)
        local value = self:evaluate(node.value, variables)
        self.resulted = true
        self.result = value
        return value
    end,
    ["SkipStatement"] = function(self, node, _variables)
        if not self.loopContext then
            self:handleError("Skip statement used outside of a loop.")
        end
        if node.value then
            self.loopContext.breakFlag = true
        else
            self.loopContext.continueFlag = true
        end
    end,
}

function Evaluator:evaluate(node, symbols)
    if self.resulted then return self.result end
    symbols = symbols or {}
    if not node then
        self:handleError("Nil node given to evaluator")
        return
    end
    self.parsing = node
    return switch_case(node.type, node_type_cases, function()
        self:handleError(`Unknown node type: {node.type}`)
    end, self, node, symbols)
end

function Evaluator:fluwFnToFunction(fn)
    return function(...)
        --TODO
    end
end

function Evaluator:getResult()
    local result = self.result
    if not result then return end
    if type(result) == "table" then
        if result.type == "fn" then
            return self:fluwFnToFunction(result)
        else
            return result.value
        end
    end
    return result 
end

function Evaluator:handleError(message)
    local curr = self.parsing
    Error:error(message, curr.line, curr.position)
    error(message)
end

function Evaluator.new()
    local self = setmetatable({}, { __index = Evaluator })
    self.symbolTable = {} -- Centralized symbol storage
    self.result = nil -- Stores result given by a return statement
    self.resulted = false -- Is this evaluator finished?
    self.parent = nil -- Parent scope evaluator
    self.parsing = nil -- Currently parsed node
    self.loopContext = nil -- Looping context system
    return self
end

return Evaluator
