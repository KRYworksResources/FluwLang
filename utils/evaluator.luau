local Evaluator = {}
local Error = require("error")

local function mix_tables(t1, t2)
    local base = table.clone(t1)
    for k, v in t2 do
        base[k] = v
    end
    return base
end

function Evaluator:getValue(id:string, symbols)
    symbols = symbols or {}
    local value = symbols[id] or self.symbolTable[id] or self.constants[id]
    if not value and self.parent then
        local prnt = self.parent
        value = prnt:getValue(id)
    end
    return value
end
function Evaluator:doesSymbolExist(id:string, symbols)
    symbols = symbols or {}
    local value = symbols[id] or self.symbolExists[id] or self.constantsExists[id]
    if not value and self.parent then
        local prnt = self.parent
        value = prnt:doesSymbolExist(id)
    end
    return value
end
function Evaluator:setVariable(id:string, value:any, symval, symdef)
    symval = symval or {}
    symdef = symdef or {}
    if self.constantsExists[id] then
        Error:error("Constants can't be redeclared.")
        error("Constants can't be redeclared.")
    elseif not (self.symbolExists[id] or symdef[id]) then
        if self.parent then
            local prnt = self.parent
            if prnt:doesSymbolExist(id) then
                prnt:setVariable(id, value)
                return
            end
        end
        Error:error(`Variable '{id}' is undefined.`)
        error(`Variable '{id}' is undefined.`)
    end
    local target_write = if symdef[id] then symval else self.symbolTable
    target_write[id] = value
    return value
end

local function switch_case(var, cases, default, ...)
    local f = cases[var] or default
    if not f then return end
    return f(...)
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
    ["NullPointer"] = function(_self, _node, _variables, _definedsymbols)
        return nil
    end,
    ["Literal"] = function(_self, _node, _variables, _definedsymbols)
        return _node.value
    end,
    ["UnaryExpression"] = function(self, node, variables, definedsymbols)
        local value = self:evaluate(node.value, variables, definedsymbols)
        if node.operator == "-" then return -value
        elseif node.operator == "not" then return not value
        elseif node.operator == "~" then return bit32.bnot(value)
        else
            Error:error("Unknown unary operator: " .. node.operator)
            error("Unknown unary operator: " .. node.operator)
        end
    end,
    ["ArrayExpression"] = function(self, node, variables, definedsymbols)
        local array = {}
        for _, elementNode in ipairs(node.elements) do
            table.insert(array, self:evaluate(elementNode, variables, definedsymbols))
        end
        return array
    end,
    ["DictExpression"] = function(self, node, variables, definedsymbols)
        local dict = {}
        for k, v in node.pairs do
            local key = self:evaluate(k, variables, definedsymbols)
            local value = self:evaluate(v, variables, definedsymbols)
            dict[key] = value
        end
        return dict
    end,
    ["TableIndex"] = function(self, node, variables, definedsymbols)
        local table = self:evaluate(node.base, variables, definedsymbols)
        if self.symbolType[node.value] == "fn" then
            Error:error("Can't index a function value.")
            error("Can't index a function value.")
        end
        local index = self:evaluate(node.index, variables, definedsymbols)
        return table[index]
    end,
    ["BinaryExpression"] = function(self, node, variables, definedsymbols)
        local left = self:evaluate(node.left, variables, definedsymbols)
        local right = self:evaluate(node.right, variables, definedsymbols)
        return switch_case(node.operator, binary_expression_cases, function()
            Error:error("Unknown operator: " .. node.operator)
            error("Unknown operator: " .. node.operator)
        end, left, right)
    end,
    ["IfStatement"] = function(self, node, variables, definedsymbols)
        local condition = self:evaluate(node.condition, variables, definedsymbols)
        if condition then
            self:evaluate(node.thenBlock, variables, definedsymbols)
        elseif node.elseBlock then
            self:evaluate(node.elseBlock, variables, definedsymbols)
        end
    end,
    ["WhileStatement"] = function(self, node, variables, definedsymbols)
        local condition = self:evaluate(node.condition, variables, definedsymbols)
        while condition and not self.resulted do
            self:evaluate(node.codeBlock, variables, definedsymbols)
            condition = self:evaluate(node.condition, variables, definedsymbols)
        end
    end,
    ["ForStatement"] = function(self, node, variables, definedsymbols)
        self:evaluate(node.definition, variables, definedsymbols)
        local condition = self:evaluate(node.condition, variables, definedsymbols)
        while condition and not self.resulted do
            condition = self:evaluate(node.condition, variables, definedsymbols)
            self:evaluate(node.codeBlock, variables, definedsymbols)
            self:evaluate(node.operation, variables, definedsymbols)
        end
    end,
    ["ForEachStatement"] = function(self, node, variables, definedsymbols)
        self:evaluate(node.key, variables, definedsymbols)
        self:evaluate(node.value, variables, definedsymbols)
        local source = self:evaluate(node.source, variables, definedsymbols)
        for k, v in source do
            if self.resulted then break end
            variables[node.key.name] = k
            variables[node.value.name] = v
            self:evaluate(node.codeBlock, variables, definedsymbols)
        end
    end,
    ["CodeBlock"] = function(self, node, variables, definedsymbols)
	    local nself = Evaluator.new()
        nself.parent = self
        for _, block in node.code do
            nself:evaluate(block, variables, definedsymbols)
        end
        if node.blocktype == "block" and nself.resulted then
            self.resulted = true
            self.result = nself.result
        end
        return nself:getResult()
    end,
    ["AssignmentExpression"] = function(self, node, variables, definedsymbols)
        local value = self:evaluate(node.value, variables, definedsymbols)
        if node.target.type == "TableIndex" then
            local table = self:evaluate(node.target.base, variables, definedsymbols)
            local index = self:evaluate(node.target.index, variables, definedsymbols)
            table[index] = value
        elseif node.target.type == "Identifier" then
            self:setVariable(node.target.value, value, variables, definedsymbols)
        elseif type(node.target) == "string" then
            self:setVariable(node.target, value, variables, definedsymbols)
        else
            Error:error(`Invalid assignee ({node.target.type}) given to assignment`)
            error(`Invalid assignee ({node.target.type}) given to assignment`)
        end
        return value
    end,
    ["VariableDefinition"] = function(self, node, variables, definedsymbols)
        if self.constants[node.name] then
            Error:error(`A constant '{node.name}' is already declared before.`)
            error(`A constant '{node.name}' is already declared before.`)
        end
        local value = self:evaluate(node.value, variables, definedsymbols)
        self.symbolTable[node.name] = value
        self.symbolExists[node.name] = true
        self.symbolType[node.name] = "var"
        return value
    end,
    ["TempVariableDefinition"] = function(self, node, variables, definedsymbols)
        if self.constants[node.name] then
            Error:error(`A constant '{node.name}' is already declared before.`)
            error(`A constant '{node.name}' is already declared before.`)
        end
        local value = self:evaluate(node.value, variables, definedsymbols)
        variables[node.name] = value
        definedsymbols[node.name] = "tempvar"
        return value
    end,
    ["ConstDeclaration"] = function(self, node, variables, definedsymbols)
        if self.constants[node.name] then
            Error:error(`Constant '{node.name}' is already declared.`)
            error(`Constant '{node.name}' is already declared.`)
        elseif self:doesSymbolExist(node.variable, definedsymbols) then
            Error:error(`A variable with name '{node.name}' is already defined.`)
            error(`A variable with name '{node.name}' is already defined.`)
        end
        local value = self:evaluate(node.value, variables, definedsymbols)
        self.constants[node.name] = value
        self.constantsExists[node.name] = true
        self.symbolType[node.name] = "const"
        return value
    end,
    ["FunctionDeclaration"] = function(self, node, _variables, definedsymbols)
        local fn = {
            arguments = node.arguments,
            body = node.body,
            type = "fn",
        }
        if self:doesSymbolExist(node.variable, definedsymbols) then
            Error:error(`The symbol '{node.name}' is already declared before.`)
            error(`The symbol '{node.name}' is already declared before.`)
        end
        self.symbolTable[node.name] = fn
        self.symbolExists[node.name] = true
        self.symbolType[node.name] = "fn"
        return
    end,
    ["FunctionCall"] = function(self, node, variables, definedsymbols)
        local fn = self:evaluate(node.base, variables, definedsymbols)
        if self.symbolType[node.base.value] ~= "fn" then
            Error:error("Can't call a non-function value.")
            error("Can't call a non-function value.")
        end
        local argvars = {}
        local argexists = {}
        for i, v in node.args do
            argvars[fn.arguments[i]] = v
            argexists[fn.arguments[i]] = true
        end
        return self:evaluate(fn.body, mix_tables(variables, argvars), mix_tables(definedsymbols, argexists))
    end,
    ["Identifier"] = function(self, node, variables, definedsymbols)
        if not self:doesSymbolExist(node.value, definedsymbols) then
            Error:error(`Undefined identifier: '{node.value}'`)
            error(`Undefined identifier: '{node.value}'`)
        end
        local value = self:getValue(node.value, variables)
        return value
    end,
    ["ReturnExpression"] = function(self, node, variables, definedsymbols)
        local value = self:evaluate(node.value, variables, definedsymbols)
        self.resulted = true
        self.result = value
        return value
    end,
}

function Evaluator:evaluate(node, variables, definedsymbols)
    if self.resulted then return self.result end
    variables = variables or {}
    definedsymbols = definedsymbols or {}
    if not node then
        Error:error("Nil node given to evaluator")
        error("Nil node given to evaluator")
        return
    end
    return switch_case(node.type, node_type_cases, function()
        Error:error(`Unknown node type: {node.type}`)
        error(`Unknown node type: {node.type}`)
    end, self, node, variables, definedsymbols)
end

function Evaluator:getResult()
    return self.result
end

function Evaluator.new()
    local self = setmetatable({}, { __index = Evaluator })
    self.symbolExists = {} -- Stores if a variable exists
    self.symbolTable = {} -- Stores variable names and values
    self.constants = {} -- Stores constant names and values
    self.constantsExists = {} -- Stores if a constant exists
    self.symbolType = {} -- Stores the base type of symbols
    self.result = nil -- Stores result given by a return statement
    self.resulted = false -- Is this evaluator finished?
    self.parent = nil -- Parent scope evaluator
    return self
end

return Evaluator
