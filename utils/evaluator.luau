local Evaluator = {}
local Error = require("error")

local function mix_tables(t1, t2)
    local base = table.clone(t1)
    for k, v in t2 do
        base[k] = v
    end
    return base
end

function Evaluator:evaluate(node, variables, definedsymbols)
    variables = variables or {}
    definedsymbols = definedsymbols or {}
    local function get_variable(name:string)
        return variables[name] or self.symbolTable[name] or self.constants[name]
    end
    local function symbol_exists(name:string)
        return definedsymbols[name] or self.symbolExists[name] or self.constantsExists[name]
    end
    if not node then
        Error:error("Nil node given to evaluator")
        error("Nil node given to evaluator")
        return
    end
    if node.type == "NullPointer" then
        return nil
    elseif node.type == "BooleanLiteral" or node.type == "StringLiteral" then
        return node.value
    elseif node.type == "UnaryExpression" then
        local value = self:evaluate(node.value)
        if node.operator == "-" then return -value
        elseif node.operator == "not" then return not value
        elseif node.operator == "~" then return bit32.bnot(value)
        else
            Error:error("Unknown unary operator: " .. node.operator)
            error("Unknown unary operator: " .. node.operator)
        end
    elseif node.type == "ArrayExpression" then
        local array = {}
        for _, elementNode in ipairs(node.elements) do
            table.insert(array, self:evaluate(elementNode))
        end
        return array
    elseif node.type == "DictExpression" then
        local dict = {}
        for k, v in node.pairs do
            local key = self:evaluate(k)
            local value = self:evaluate(v)
            dict[key] = value
        end
        return dict
    elseif node.type == "TableIndex" then
        local table = self:evaluate(node.base)
        if self.symbolType[node.value] == "fn" then
            Error:error("Can't index a function value.")
            error("Can't index a function value.")
        end
        local index = self:evaluate(node.index)
        return table[index]
    elseif node.type == "NumberLiteral" then
        return node.value
    elseif node.type == "BinaryExpression" then
        local left = self:evaluate(node.left)
        local right = self:evaluate(node.right)
        if node.operator == "+" then
            if type(left) == "string" or type(right) == "string" then
                return left .. right
            else
                return left + right
            end
        elseif node.operator == "-" then
            return left - right
        elseif node.operator == "*" then
            return left * right
        elseif node.operator == "/" then
            return left / right
        elseif node.operator == "%" then
            return left % right
        elseif node.operator == "==" then
            return left == right
        elseif node.operator == "!=" then
            return left ~= right
        elseif node.operator == "<" then
            return left < right
        elseif node.operator == ">" then
            return left > right
        elseif node.operator == "<=" then
            return left <= right
        elseif node.operator == ">=" then
            return left >= right
        elseif node.operator == "and" then
            return left and right
        elseif node.operator == "or" then
            return left or right
        elseif node.operator == "&&" then
            return left and right
        elseif node.operator == "||" then
            return left or right
        elseif node.operator == "^" then
            return bit32.bxor(left, right)
        elseif node.operator == "&" then
            return bit32.band(left, right)
        elseif node.operator == "|" then
            return bit32.bor(left, right)
        elseif node.operator == "<<" then
            return bit32.lshift(left, right)
        elseif node.operator == ">>" then
            return bit32.rshift(left, right)
        else
            Error:error("Unknown operator: " .. node.operator)
            error("Unknown operator: " .. node.operator)
        end
    elseif node.type == "IfStatement" then
        local condition = self:evaluate(node.condition)
        if condition then
            return self:evaluate(node.thenBlock)
        elseif node.elseBlock then
            return self:evaluate(node.elseBlock)
        end
        return nil
    elseif node.type == "WhileStatement" then
        local condition = self:evaluate(node.condition)
        local result = nil
        while condition do
            result = self:evaluate(node.codeBlock)
            condition = self:evaluate(node.condition)
        end
        return result
    elseif node.type == "CodeBlock" then
        local results = {}
        for _, block in node.code do
            local value = self:evaluate(block, variables, definedsymbols)
            table.insert(results, value)
        end
        return results
    elseif node.type == "AssignmentExpression" then
        if self.constants[node.variable] then
            Error:error("Constants can't be redeclared.")
            error("Constants can't be redeclared.")
        elseif not symbol_exists(node.variable) then
            Error:error(`Variable '{node.variable}' is undefined.`)
            error(`Variable '{node.variable}' is undefined.`)
        end
        local value = self:evaluate(node.value)
        self.symbolTable[node.variable] = value
        return value
    elseif node.type == "VariableDefinition" then
        if self.constants[node.name] then
            Error:error(`A constant '{node.name}' is already declared before.`)
            error(`A constant '{node.name}' is already declared before.`)
        end
        local value = self:evaluate(node.value)
        self.symbolTable[node.name] = value
        self.symbolExists[node.name] = true
        self.symbolType[node.name] = "var"
        return value
    elseif node.type == "ConstDeclaration" then
        if self.constants[node.name] then
            Error:error(`Constant '{node.name}' is already declared.`)
            error(`Constant '{node.name}' is already declared.`)
        elseif symbol_exists(node.variable) then
            Error:error(`A variable with name '{node.name}' is already defined.`)
            error(`A variable with name '{node.name}' is already defined.`)
        end
        local value = self:evaluate(node.value)
        self.constants[node.name] = value
        self.constantsExists[node.name] = true
        self.symbolType[node.name] = "const"
        return value
    elseif node.type == "FunctionDeclaration" then
        local fn = {
            arguments = node.arguments,
            body = node.body,
            type = "fn",
        }
        if symbol_exists(node.variable) then
            Error:error(`The symbol '{node.name}' is already declared before.`)
            error(`The symbol '{node.name}' is already declared before.`)
        end
        self.symbolTable[node.name] = fn
        self.symbolExists[node.name] = true
        self.symbolType[node.name] = "fn"
        return
    elseif node.type == "FunctionCall" then
        local fn = self:evaluate(node.base)
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
    elseif node.type == "Identifier" then
        if not symbol_exists(node.value) then
            Error:error(`Undefined identifier: '{node.value}'`)
            error(`Undefined identifier: '{node.value}'`)
        end
        local value = get_variable(node.value)
        return value
    elseif node.type == "ReturnExpression" then
	local value = self:evaluate(node.value)
	return value
    else
        Error:error(`Unknown node type: {node.type}`)
        error(`Unknown node type: {node.type}`)
    end
end

function Evaluator.new()
    local self = setmetatable({}, { __index = Evaluator })
    self.symbolExists = {} -- Stores if a variable exists
    self.symbolTable = {} -- Stores variable names and values
    self.constants = {} -- Stores constant names and values
    self.constantsExists = {} -- Stores if a constant exists
    self.symbolType = {} -- Stores the base type of symbols
    return self
end

return Evaluator
