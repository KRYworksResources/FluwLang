local Evaluator = {}
local Error = require("error")

function Evaluator:evaluate(node)
    if not node then
        Error:error("Empty node given to evaluator")
        error("Empty node given to evaluator")
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
    elseif node.type == "IfCodeBlock" then
        local results = {}
        for _, block in node.code do
            local value = self:evaluate(block)
            table.insert(results, value)
        end
        return results
    elseif node.type == "AssignmentExpression" then
        if self.constants[node.variable] then
            Error:error("Constants can't be redeclared.")
            error("Constants can't be redeclared.")
        elseif not self.symbolExists[node.variable] then
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
        return value
    elseif node.type == "ConstDeclaration" then
        if self.constants[node.name] then
            Error:error(`Constant '{node.name}' is already declared.`)
            error(`Constant '{node.name}' is already declared.`)
        elseif self.symbolTable[node.name] then
            Error:error(`A variable with name '{node.name}' is already defined.`)
            error(`A variable with name '{node.name}' is already defined.`)
        end
        local value = self:evaluate(node.value)
        self.constants[node.name] = value
        return value
    elseif node.type == "Identifier" then
        if not (self.symbolExists[node.value] or self.constants[node.value]) then
            Error:error(`Undefined identifier: '{node.value}'`)
            error(`Undefined identifier: '{node.value}'`)
        end
        local value = self.symbolTable[node.value] or self.constants[node.value]
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
    return self
end

return Evaluator