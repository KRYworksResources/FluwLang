local Evaluator = {}
local Error = require("error")

function Evaluator:evaluate(node)
    if not node then
        Error:error("Empty node given to evaluator")
        error("Empty node given to evaluator")
        return
    end
    if node.type == "BooleanLiteral" then
        return node.value
    elseif node.type == "UnaryExpression" then
        local value = self:evaluate(node.value)
        if node.operator == "-" then return -value
        elseif node.operator == "not" then return not value
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
            return left + right
        elseif node.operator == "-" then
            return left - right
        elseif node.operator == "*" then
            return left * right
        elseif node.operator == "/" then
            return left / right
        elseif node.operator == "^" then
            return left ^ right
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
        else
            Error:error("Unknown operator: " .. node.operator)
            error("Unknown operator: " .. node.operator)
        end
    elseif node.type == "AssignmentExpression" then
        local value = self:evaluate(node.value)
        self.symbolTable[node.variable] = value
        return value
    elseif node.type == "VariableDefinition" then
        local value = self:evaluate(node.value)
        self.symbolTable[node.name] = value
        return value
    elseif node.type == "Identifier" then
        local value = self.symbolTable[node.value]
        if value == nil then
            Error:error("Undefined variable: " .. node.value)
            error("Undefined variable: " .. node.value)
        end
        return value
    else
        Error:error("Unknown node type: " .. node.type)
        error("Unknown node type: " .. node.type)
    end
end

function Evaluator.new()
    local self = setmetatable({}, { __index = Evaluator })
    self.symbolTable = {} -- Stores variable names and values
    return self
end

return Evaluator