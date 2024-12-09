local Parser = {}
local Error = require("error")

Parser.Operator = {
    ["not"] = 5, -- Unary operator
    ["+"] = 2, -- Addition
    ["-"] = 2, -- Subtraction
    ["*"] = 3, -- Multiplication
    ["/"] = 3, -- Division
    ["%"] = 3, -- Modulus
    ["<"] = 2, -- Smaller than
    [">"] = 2, -- Bigger than
    ["<="] = 2, -- Smaller than or equal to
    [">="] = 2, -- Bigger than or equal to
    ["=="] = 2, -- Equal to
    ["!="] = 2, -- Not equal to
    ["^"] = 4, -- Bitwise XOR
    ["&"] = 4, -- Bitwise AND
    ["|"] = 4, -- Bitwise OR
    ["<<"] = 4, -- Bitwise Left Shift
    [">>"] = 4, -- Bitwise Right Shift
    ["and"] = 1, -- AND operator
    ["or"] = 1, -- OR operator
    ["&&"] = 1, -- AND operator
    ["||"] = 1, -- OR operator
}

function Parser.new(tokens)
    local self = setmetatable({}, { __index = Parser })
    self.tokens = tokens
    self.position = 1
    return self
end
-- Get the current token
function Parser:currentToken()
    return self.tokens[self.position]
end
-- Advance to the next token
function Parser:advance()
    self.position += 1
end
local precedence = 0
-- Parse statements and variable definitions
function Parser:parseStatement()
    local node
    precedence = 0
    -- Check for variable definition (e.g., var x = 5;)
    if self:currentToken().type == "KEYWORD" then
        if self:currentToken().value == "if" then
            node = self:parseIfStatement()
        elseif self:currentToken().value == "while" then
            node = self:parseWhileStatement()
        elseif self:currentToken().value == "var" then
            node = self:parseVariableDefinition()
        elseif self:currentToken().value == "const" then
            node = self:parseConstDeclaration()
        elseif self:currentToken().value == "fn" then
            node = self:parseFunctionDeclaration()
        elseif self:currentToken().value == "return" then
            node = self:parseReturnStatement()
        else
            error("Unknown keyword: " .. self:currentToken().value)
        end
    else
        node = self:parseExpression()
    end
    -- Ensure the statement ends with a semicolon
    if self:currentToken().type == "SYMBOL" and self:currentToken().value == ";" then
        self:advance() -- Consume the semicolon
    else
        Error:error("Expected ';' at the end of statement")
        error("Expected ';' at the end of statement")
    end
    return node
end
function Parser:parseVariableDefinition()
    self:advance() -- Consume 'var'
    if self:currentToken().type ~= "IDENTIFIER" then
        error("Expected variable name after 'var'")
    end
    local varName = self:currentToken().value
    self:advance() -- Consume the identifier
    if self:currentToken().type ~= "OPERATOR" or self:currentToken().value ~= "=" then
        error("Expected '=' after variable name")
    end
    self:advance() -- Consume '='
    local value = self:parseExpression()
    return { type = "VariableDefinition", name = varName, value = value }
end
function Parser:parseConstDeclaration()
    self:advance() -- Consume 'const'
    if self:currentToken().type ~= "IDENTIFIER" then
        error("Expected constant name after 'const'")
    end
    local constName = self:currentToken().value
    self:advance() -- Consume the identifier
    if self:currentToken().type ~= "OPERATOR" or self:currentToken().value ~= "=" then
        error("Expected '=' after constant name")
    end
    self:advance() -- Consume '='
    local value = self:parseExpression()
    return { type = "ConstDeclaration", name = constName, value = value }
end
function Parser:parseFunctionDeclaration()
    self:advance()
    -- Parse the function name
    local nameToken = self:currentToken()
    if nameToken.type ~= "IDENTIFIER" then
        self:error("Expected function name after 'fn'")
    end
    self:advance()
    local functionName = nameToken.value
    -- Parse the parameter list
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "(" then
        error("Expected '(' after function name")
    end
    self:advance() -- Consume '('
    local parameters = {}
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ")" then
        while true do
            local paramToken = self:currentToken()
            if paramToken.type ~= "IDENTIFIER" then
                Error:error("Expected parameter name in function declaration")
            end
            self:advance()
            table.insert(parameters, paramToken.value)
            if self:currentToken().type == "SYMBOL" and self:currentToken().value == "," then
                self:advance()
            else
                break
            end
        end
    end
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ")" then
        error("Expected ')' after parameters")
    end
    self:advance() -- Consume ')'
    -- Parse the function body
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "{" then
        error("Expected '{' to start function body")
    end
    self:advance() -- Consume '{'
    local body = {
        type = "CodeBlock",
        blocktype = "Callable",
        code = {}
    } -- Parse statements inside the function body
    while self:currentToken().value ~= "}" do
        table.insert(body.code, self:parseStatement())
    end
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "}" then
        error("Expected '}' to end function body")
    end
    self:advance() -- Consume '}'
    -- Return the function declaration AST node
    return {
        type = "FunctionDeclaration",
        name = functionName,
        arguments = parameters,
        body = body,
    }
end

function Parser:parseReturnStatement()
    self:advance() -- Consume 'return'
    -- Parse the optional return value
    local expression = nil
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ";" then
        expression = self:parseExpression()
    end
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ";" then
        error("Expected ';' after return statement")
    end
    self:advance() -- Consume ';'
    return {
        type = "RETURN",
        value = expression,
    }
end

function Parser:parseIfStatement()
    self:advance() -- Consume 'if'
    if self:currentToken().value ~= "(" then
        error("Expected '(' after 'if'")
    end
    self:advance() -- Consume '('
    local condition = self:parseExpression() -- Parse the condition
    if self:currentToken().value ~= ")" then
        error("Expected ')' after condition")
    end
    self:advance() -- Consume ')'
    if self:currentToken().value ~= "{" then
        error("Expected '{' to start if block")
    end
    self:advance() -- Consume '{'
    local thenBlock = {
        type = "CodeBlock",
        blocktype = "Conditional",
        code = {}
    } -- Parse statements inside the 'if' block
    while self:currentToken().value ~= "}" do
        table.insert(thenBlock.code, self:parseStatement())
    end
    self:advance() -- Consume '}'
    local elseBlock = nil
    if self:currentToken().value == "else" then
        self:advance() -- Consume 'else'
        if self:currentToken().value ~= "{" then
            error("Expected '{' after 'else'")
        end
        self:advance() -- Consume '{'
        elseBlock = {
            type = "CodeBlock",
            blocktype = "Conditional",
            code = {}
        }
        while self:currentToken().value ~= "}" do
            table.insert(elseBlock.code, self:parseStatement())
        end
        self:advance() -- Consume '}'
    elseif self:currentToken().value == "elif" or self:currentToken().value == "efra" then
        elseBlock = self:parseIfStatement() -- Parse 'elif' recursively
    end
    return {
        type = "IfStatement",
        condition = condition,
        thenBlock = thenBlock,
        elseBlock = elseBlock,
    }
end
function Parser:parseWhileStatement()
    self:advance() -- Consume 'while'
    if self:currentToken().value ~= "(" then
        error("Expected '(' after 'while'")
    end
    self:advance() -- Consume '('
    local condition = self:parseExpression() -- Parse the condition
    if self:currentToken().value ~= ")" then
        error("Expected ')' after condition")
    end
    self:advance() -- Consume ')'
    if self:currentToken().value ~= "{" then
        error("Expected '{' to start while block")
    end
    self:advance() -- Consume '{'
    local codeBlock = {
        type = "CodeBlock",
        blocktype = "Conditional",
        code = {}
    } -- Parse statements inside the 'while' block
    while self:currentToken().value ~= "}" do
        table.insert(codeBlock.code, self:parseStatement())
    end
    self:advance() -- Consume '}'
    return {
        type = "WhileStatement",
        condition = condition,
        codeBlock = codeBlock,
    }
end

function Parser:parseExpression()
    return self:parseAssignment()
end

-- Parse an array
function Parser:parseArray()
    local elements = {}
    while self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "]" do
        local element = self:parseExpression()
        table.insert(elements, element)
        if self:currentToken().type == "SYMBOL" and self:currentToken().value == "," then
            self:advance() -- Skip the ','
        elseif self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "]" then
            Error:error("Expected ',' or ']', but got " .. (self:currentToken().value or "EOF"), nil, self.position)
            error("Parsing error")
        end
    end
    self:advance() -- Skip the ']'
    return { type = "ArrayExpression", elements = elements }
end

-- Parse a dictionary
function Parser:parseDictionary()
    local pairs = {}
    while self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "}" do
        local key = self:parseExpression()
        if not (self:currentToken().type == "SYMBOL" and self:currentToken().value == ":") then
            Error:error("Expected ':' after key in dictionary", nil, self.position)
            error("Parsing error")
        end
        self:advance() -- Skip the ':'
        local value = self:parseExpression()
        pairs[key] = value
        if self:currentToken().type == "SYMBOL" and self:currentToken().value == "," then
            self:advance() -- Skip the ','
        elseif self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "}" then
            Error:error("Expected ',' or '}', but got " .. (self:currentToken().value or "EOF"), nil, self.position)
            error("Parsing error")
        end
    end
    self:advance() -- Skip the '}'
    return { type = "DictExpression", pairs = pairs }
end

-- Parse assignments (e.g., x = expression)
function Parser:parseAssignment()
    local token = self:currentToken()
    if token.type == "IDENTIFIER" then
        local variableName = token.value
        self:advance()
        -- Check if it's an assignment
        if self:currentToken().value == "=" then
            self:advance()
            local expression = self:parseExpression()
            return { type = "AssignmentExpression", variable = variableName, value = expression }
        else
            -- Backtrack when it's not an assignment
            self.position -= 1
        end
    end
    -- Fall back to parsing as an expression
    return self:parseBinaryExpression()
end

-- Parse binary expressions
function Parser:parseBinaryExpression()
    local left = self:parsePrimary()
    while self:currentToken().type == "OPERATOR" do
        local operator = self:currentToken().value
        local operatorprecedence = Parser.Operator[operator] or 0
        -- If the current operator has lower , stop parsing
        if operatorprecedence < precedence or 
            (operatorprecedence == precedence and operator ~= "^") then
            break
        end
        self:advance() -- Consume the operator
        -- Parse the right-hand side with higher 
        local right = self:parseExpression(operatorprecedence)
        left = {
            type = "BinaryExpression",
            operator = operator,
            left = left,
            right = right,
        }
    end
    return left
end
-- Parse primary values (numbers, variables, parentheses)
function Parser:parsePrimary()
    local token = self:currentToken()
    if token.type == "NUMBER" then
        self:advance()
        return { type = "NumberLiteral", value = token.value }
    elseif token.type == "STRING" then
        self:advance()
        return { type = "StringLiteral", value = token.value }
    elseif token.type == "IDENTIFIER" then
        self:advance()
        local next_token = self:currentToken()
        if next_token.type == "SYMBOL" then
            if next_token.value == "[" then
                self:advance()
                local index = self:parseExpression()
                if not (self:currentToken().type == "SYMBOL" and self:currentToken().value == "]") then
                    Error:error("Expected closing ']' for indexing")
                    error("Expected closing ']' for indexing")
                end
                self:advance()
                return {
                    type = "TableIndex",
                    base = { type = "Identifier", value = token.value },
                    index = index,
                }
            elseif next_token.value == "(" then
                self:advance() -- Consume '('
                local args = {}
                if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ")" then
                    while true do
                        local paramToken = self:currentToken()
                        self:advance()
                        table.insert(args, paramToken.value)
                        if self:currentToken().type == "SYMBOL" and self:currentToken().value == "," then
                            self:advance()
                        else
                            break
                        end
                    end
                end
                if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ")" then
                    error("Expected ')' after arguments")
                end
                self:advance() -- Consume ')'
                return {
                    type = "FunctionCall",
                    base = { type = "Identifier", value = token.value },
                    args = args,
                }
            end
        end
        return { type = "Identifier", value = token.value }
    elseif token.type == "KEYWORD" then
        if token.value == "true" or token.value == "false" then
            self:advance()
            return { type = "BooleanLiteral", value = token.value == "true" }
        elseif token.value == "null" then
            self:advance()
            return { type = "NullPointer" }
        end
    elseif token.type == "SYMBOL" then
        self:advance()
        if token.value == "(" then
            local expression = self:parseExpression()
            if self:currentToken().type == "SYMBOL" and self:currentToken().value == ")" then
                self:advance()
            else
                Error:error("Expected ')'")
                error("Expected ')'")
            end
            return expression
        elseif token.value == "[" then
            return self:parseArray()
        elseif token.value == "{" then
            return self:parseDictionary()
        end
    elseif token.type == "OPERATOR" and token.value == "-" then
        -- Handle unary minus
        self:advance() -- Consume '-'
        local expression = self:parsePrimary()
        return { type = "UnaryExpression", operator = "-", value = expression }
    elseif token.type == "OPERATOR" and token.value == "~" then
        -- Handle bitwise
        self:advance() -- Consume '~'
        local expression = self:parsePrimary()
        return { type = "UnaryExpression", operator = "~", value = expression }
    elseif token.type == "OPERATOR" and (token.value == "not" or token.value == "!") then
        -- Handle not call
        self:advance() -- Consume 'not'
        local expression = self:parsePrimary()
        return { type = "UnaryExpression", operator = "not", value = expression }
    end
    Error:error(`Unexpected token: {token.value or "EOF"}#{token.type or "EOF"}`)
    error(`Unexpected token: {token.value or "EOF"}#{token.type or "EOF"}`)
end

return Parser