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
function Parser:handleError(message)
    local curr = self:currentToken()
    Error:error(message, curr.line, curr.position)
    error(message)
end
function Parser:insertPosition(node)
    local prev = self:peek(-1)
    node.position = prev.position
    node.line = prev.line
end
-- Get the current token
function Parser:currentToken()
    return self.tokens[self.position]
end
-- Peek at any token
function Parser:peek(offset)
    return self.tokens[self.position+offset]
end
-- Advance to the next token
function Parser:advance()
    self.position += 1
end
local precedence = 0
function Parser:expectSemicolon()
    -- Ensure the statement ends with a semicolon
    if self:currentToken().type == "SYMBOL" and self:currentToken().value == ";" then
        self:advance() -- Consume the semicolon
    else
        self:handleError("Expected ';' at the end of statement")
    end
end
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
        elseif self:currentToken().value == "for" then
            node = self:parseForStatement()
        elseif self:currentToken().value == "foreach" then
            node = self:parseForEachStatement()
        elseif self:currentToken().value == "do" then
            node = self:parseCodeblockStatement()
        elseif self:currentToken().value == "continue" then
            self:advance()
            node = { type = "SkipStatement", value = false; }
        elseif self:currentToken().value == "break" then
            self:advance()
            node = { type = "SkipStatement", value = true; }
        else
            self:handleError("Unknown keyword: " .. self:currentToken().value)
        end
    else
        node = self:parseExpression()
    end
    self:expectSemicolon()
    self:insertPosition(node)
    return node
end
function Parser:parseType()
    local type = nil
    if self:currentToken().type == "SYMBOL" and self:currentToken().value == ":" then
        self:advance() -- Consume ':'
        type = "auto"
        if self:currentToken().type == "IDENTIFIER" then
            type = self:currentToken().value
            self:advance() -- Consume the type identifier
        end
    end
    return type
end
function Parser:parseVariableDefinition()
    self:advance() -- Consume 'var'
    if self:currentToken().type ~= "IDENTIFIER" then
        self:handleError("Expected variable name after 'var'")
    end
    local varName = self:currentToken().value
    self:advance() -- Consume the identifier
    local type = self:parseType()
    if self:currentToken().type ~= "OPERATOR" or self:currentToken().value ~= "=" then
        self:handleError("Expected '=' after variable name")
    end
    self:advance() -- Consume '='
    local value = self:parseExpression()
    return { type = "VariableDefinition", name = varName, value = value, vartype = type }
end
function Parser:parseConstDeclaration()
    self:advance() -- Consume 'const'
    if self:currentToken().type ~= "IDENTIFIER" then
        self:handleError("Expected constant name after 'const'")
    end
    local constName = self:currentToken().value
    self:advance() -- Consume the identifier
    local type = self:parseType()
    if self:currentToken().type ~= "OPERATOR" or self:currentToken().value ~= "=" then
        self:handleError("Expected '=' after constant name")
    end
    self:advance() -- Consume '='
    local value = self:parseExpression()
    return { type = "ConstDeclaration", name = constName, value = value, vartype = type }
end

function Parser:parseParameterList()
    -- Parse the parameter list
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "(" then
        self:handleError("Expected '(' after function name")
    end
    self:advance() -- Consume '('
    local parameters = {}
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ")" then
        while true do
            local paramToken = self:currentToken()
            if paramToken.type ~= "IDENTIFIER" then
                self:handleError("Expected parameter name in function declaration")
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
        self:handleError("Expected ')' after parameters")
    end
    self:advance() -- Consume ')'
    return parameters
end

function Parser:parseFunctionDeclaration()
    self:advance()
    -- Parse the function name
    local nameToken = self:currentToken()
    if nameToken.type ~= "IDENTIFIER" then
        self:handleError("Expected function name after 'fn'")
    end
    self:advance()
    local functionName = nameToken.value
    local parameters = self:parseParameterList()
    -- Parse the function body
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "{" then
        self:handleError("Expected '{' to start function body")
    end
    self:advance() -- Consume '{'
    local body = {
        type = "CodeBlock",
        blocktype = "contained",
        code = {}
    } -- Parse statements inside the function body
    while self:currentToken().value ~= "}" do
        table.insert(body.code, self:parseStatement())
    end
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "}" then
        self:handleError("Expected '}' to end function body")
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
function Parser:parseLambdaExpression()
    self:advance() -- Consume 'fn'
    local parameters = self:parseParameterList()
    -- Parse the function body
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "{" then
        self:handleError("Expected '{' to start function body")
    end
    self:advance() -- Consume '{'
    local body = {
        type = "CodeBlock",
        blocktype = "contained",
        code = {}
    } -- Parse statements inside the function body
    while self:currentToken().value ~= "}" do
        table.insert(body.code, self:parseStatement())
    end
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "}" then
        self:handleError("Expected '}' to end function body")
    end
    self:advance() -- Consume '}'
    -- Return the function declaration AST node
    return {
        type = "LambdaLiteral",
        arguments = parameters,
        body = body,
    }
end
function Parser:parseCodeblockStatement()
    self:advance() -- Consume 'do'
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "{" then
        self:handleError("Expected '{' to start block body")
    end
    self:advance() -- Consume '{'
    local node = {
        type = "CodeBlock",
        blocktype = "block",
        code = {}
    } -- Parse statements inside the block body
    while self:currentToken().value ~= "}" do
        table.insert(node.code, self:parseStatement())
    end
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "}" then
        self:handleError("Expected '}' to end block body")
    end
    self:advance() -- Consume '}'
    return node
end

function Parser:parseReturnStatement()
    self:advance() -- Consume 'return'
    -- Parse the optional return value
    local expression = nil
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ";" then
        expression = self:parseExpression()
    end
    return {
        type = "ReturnExpression",
        value = expression,
    }
end

function Parser:parseIfStatement()
    self:advance() -- Consume 'if'
    if self:currentToken().value ~= "(" then
        self:handleError("Expected '(' after 'if'")
    end
    self:advance() -- Consume '('
    local condition = self:parseExpression() -- Parse the condition
    if self:currentToken().value ~= ")" then
        self:handleError("Expected ')' after condition")
    end
    self:advance() -- Consume ')'
    if self:currentToken().value ~= "{" then
        self:handleError("Expected '{' to start if block")
    end
    self:advance() -- Consume '{'
    local thenBlock = {
        type = "CodeBlock",
        blocktype = "block",
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
            self:handleError("Expected '{' after 'else'")
        end
        self:advance() -- Consume '{'
        elseBlock = {
            type = "CodeBlock",
            blocktype = "block",
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
        self:handleError("Expected '(' after 'while'")
    end
    self:advance() -- Consume '('
    local condition = self:parseExpression() -- Parse the condition
    if self:currentToken().value ~= ")" then
        self:handleError("Expected ')' after condition")
    end
    self:advance() -- Consume ')'
    if self:currentToken().value ~= "{" then
        self:handleError("Expected '{' to start while block")
    end
    self:advance() -- Consume '{'
    local codeBlock = {
        type = "CodeBlock",
        blocktype = "block",
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
function Parser:parseForStatement()
    self:advance() -- Consume 'for'
    if self:currentToken().value ~= "(" then
        self:handleError("Expected '(' after 'for'")
    end
    self:advance() -- Consume '('
    if self:currentToken().value ~= "var" then
        self:handleError("Expected variable defition after '('")
    end
    self:advance() -- Consume 'var'
    if self:currentToken().type ~= "IDENTIFIER" then
        self:handleError("Expected variable name after 'var'")
    end
    local varName = self:currentToken().value
    self:advance() -- Consume the identifier
    if self:currentToken().type ~= "OPERATOR" or self:currentToken().value ~= "=" then
        self:handleError("Expected '=' after variable name")
    end
    self:advance() -- Consume '='
    local value = self:parseExpression()
    local var = { type = "TempVariableDefinition", name = varName, value = value }
    self:expectSemicolon()
    local condition = self:parseExpression() -- Parse the condition
    self:expectSemicolon()
    local operation = self:parseExpression() -- Parse the operation
    if self:currentToken().value ~= ")" then
        self:handleError("Expected ')' after condition")
    end
    self:advance() -- Consume ')'
    if self:currentToken().value ~= "{" then
        self:handleError("Expected '{' to start for block")
    end
    self:advance() -- Consume '{'
    local codeBlock = {
        type = "CodeBlock",
        blocktype = "block",
        code = {}
    } -- Parse statements inside the 'for' block
    while self:currentToken().value ~= "}" do
        table.insert(codeBlock.code, self:parseStatement())
    end
    self:advance() -- Consume '}'
    return {
        type = "ForStatement",
        definition = var,
        condition = condition,
        operation = operation,
        codeBlock = codeBlock,
    }
end
function Parser:parseForEachStatement()
    self:advance() -- Consume 'for'
    if self:currentToken().value ~= "(" then
        self:handleError("Expected '(' after 'foreach'")
    end
    self:advance() -- Consume '('
    if self:currentToken().type ~= "IDENTIFIER" then
        self:handleError("Expected index identifier after '('")
    end
    local key_id = self:currentToken().value
    self:advance() -- Consume the key
    if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "," then
        self:handleError("Expected ',' after key name")
    end
    self:advance() -- Consume ','
    if self:currentToken().type ~= "IDENTIFIER" then
        self:handleError("Expected value identifier after key")
    end
    local value_id = self:currentToken().value
    self:advance() -- Consume the value
    if self:currentToken().type ~= "KEYWORD" or self:currentToken().value ~= "in" then
        self:handleError("Expected 'in' after value name")
    end
    self:advance() -- Consume 'in'
    local source = self:parseExpression()
    if self:currentToken().value ~= ")" then
        self:handleError("Expected ')' after condition")
    end
    self:advance() -- Consume ')'
    if self:currentToken().value ~= "{" then
        self:handleError("Expected '{' to start foreach block")
    end
    self:advance() -- Consume '{'
    local codeBlock = {
        type = "CodeBlock",
        blocktype = "block",
        code = {}
    } -- Parse statements inside the 'foreach' block
    while self:currentToken().value ~= "}" do
        table.insert(codeBlock.code, self:parseStatement())
    end
    local key = { type = "TempVariableDefinition", name = key_id, value = { type = "NullPointer" } }
    local value = { type = "TempVariableDefinition", name = value_id, value = { type = "NullPointer" } }
    self:advance() -- Consume '}'
    return {
        type = "ForEachStatement",
        key = key,
        value = value,
        source = source,
        codeBlock = codeBlock,
    }
end

function Parser:parseExpression()
    local node = self:parseAssignment()
    self:insertPosition(node)
    return node
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
            self:handleError("Expected ',' or ']', but got " .. (self:currentToken().value or "EOF"))
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
            self:handleError("Expected ':' after key in dictionary")
        end
        self:advance() -- Skip the ':'
        local value = self:parseExpression()
        pairs[key] = value
        if self:currentToken().type == "SYMBOL" and self:currentToken().value == "," then
            self:advance() -- Skip the ','
        elseif self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "}" then
            self:handleError("Expected ',' or '}', but got " .. (self:currentToken().value or "EOF"))
        end
    end
    self:advance() -- Skip the '}'
    return { type = "DictExpression", pairs = pairs }
end

-- Parse assignments (e.g., x = expression, table["key"] = value)
function Parser:parseAssignment()
    local token = self:currentToken()
    -- Parse the left-hand side (LHS)
    local bt_pos = self.position
    local lhs
    if token.type == "IDENTIFIER" then
        self:advance() -- Consume the identifier
        lhs = { type = "Identifier", value = token.value }
        lhs = self:parseIdentifierExtensions(lhs) -- Handle recursive indexing (e.g., table["key"])
    else
        -- Not a valid assignment target
        return self:parseBinaryExpression()
    end
    -- Check for assignment operator
    if self:currentToken().type == "OPERATOR" then
        local operator = self:currentToken().value
        self:advance() -- Consume operator
        if operator == "=" then
            local expression = self:parseExpression() -- Parse the right-hand side (RHS)
            return {
                type = "AssignmentExpression",
                target = lhs,
                value = expression,
            }
        elseif operator:match("^[%+%-*/%%]=") then
            -- Compound assignment (e.g., +=, -=, etc.)
            local expression = self:parseExpression() -- Parse the RHS
            local compoundOperator = operator:sub(1, string.len(operator) - 1) -- Extract the operator (e.g., "+" from "+=")
            return {
                type = "CompoundAssignmentExpression",
                target = lhs,
                operator = compoundOperator,
                value = expression,
            }
        end
    end
    -- Not an assignment; backtrack
    self.position = bt_pos
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
function Parser:parseIdentifierExtensions(baseNode)
    local currentNode = baseNode
    while true do
        local nextToken = self:currentToken()
        if nextToken.type == "SYMBOL" and nextToken.value == "[" then
            -- Handle `table[index]`
            self:advance() -- Consume `[`
            local index = self:parseExpression()
            if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= "]" then
                self:handleError("Expected closing ']' for indexing")
            end
            self:advance() -- Consume `]`
            currentNode = {
                type = "TableIndex",
                base = currentNode,
                index = index,
            }
        elseif nextToken.type == "SYMBOL" and nextToken.value == "." then
            -- Handle `table.key`
            self:advance() -- Consume `.`
            if self:currentToken().type ~= "IDENTIFIER" then
                self:handleError("Expected identifier after '.'")
            end
            local key = self:currentToken().value
            self:advance()
            currentNode = {
                type = "TableIndex",
                base = currentNode,
                index = { type = "Literal", value = key },
            }
        elseif nextToken.type == "SYMBOL" and nextToken.value == "(" then
            self:advance() -- Consume '('
            local args = {}
            if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ")" then
                while true do
                    local paramToken = self:parseExpression()
                    table.insert(args, paramToken)
                    if self:currentToken().type == "SYMBOL" and self:currentToken().value == "," then
                        self:advance()
                    else
                        break
                    end
                end
            end
            if self:currentToken().type ~= "SYMBOL" or self:currentToken().value ~= ")" then
                self:handleError("Expected ')' after arguments")
            end
            self:advance() -- Consume ')'
            return {
                type = "FunctionCall",
                base = currentNode,
                args = args,
            }
        else
            break -- No more extensions
        end
    end

    return currentNode
end
-- Parse primary values (numbers, variables, parentheses)
function Parser:parsePrimary()
    local token = self:currentToken()
    if token.type == "NUMBER" or token.type == "STRING" then
        self:advance()
        return { type = "Literal", value = token.value }
    elseif token.type == "IDENTIFIER" then
        self:advance()
        local basenode = { type = "Identifier", value = token.value }
        return self:parseIdentifierExtensions(basenode)
    elseif token.type == "KEYWORD" then
        if token.value == "true" or token.value == "false" then
            self:advance()
            return { type = "Literal", value = token.value == "true" }
        elseif token.value == "null" then
            self:advance()
            return { type = "NullPointer" }
        elseif token.value == "fn" then
            return self:parseLambdaExpression()
        end
    elseif token.type == "SYMBOL" then
        self:advance()
        if token.value == "(" then
            local expression = self:parseExpression()
            if self:currentToken().type == "SYMBOL" and self:currentToken().value == ")" then
                self:advance()
            else
                self:handleError("Expected ')'")
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
    self:handleError(`Unexpected token: {token.value or "EOF"}#{token.type or "EOF"}`)
    return
end

return Parser
