local Lexer = {}
local Error = require("error")

Lexer.TokenType = {
    IDENTIFIER = "IDENTIFIER",
    NUMBER = "NUMBER",
    OPERATOR = "OPERATOR",
    PAREN = "PAREN",
    SYMBOL = "SYMBOL",
    KEYWORD = "KEYWORD",
    STRING = "STRING",
    EOF = "EOF",
}
Lexer.Keywords = {
    ["var"] = true,
    ["if"] = true,
    ["else"] = true,
    ["elif"] = true,
    ["efra"] = true,
    ["while"] = true,
    ["true"] = true,
    ["false"] = true,
    ["const"] = true,
    ["null"] = true,
    ["fn"] = true,
    ["return"] = true,
    ["for"] = true,
    ["foreach"] = true,
    ["in"] = true,
    ["do"] = true,
    ["continue"] = true,
    ["break"] = true,
}
Lexer.Operators = {
    ["+"] = "ADD",
    ["-"] = "SUB",
    ["*"] = "MUL",
    ["/"] = "DIV",
    ["%"] = "MOD",
    ["="] = "ASG",
    ["=="] = "EQ",
    ["!="] = "NEQ",
    ["<"] = "LT",
    [">"] = "GT",
    ["<="] = "LTE",
    [">="] = "GTE",
    ["and"] = "AND",
    ["&&"] = "AND2",
    ["or"] = "OR",
    ["||"] = "OR2",
    ["not"] = "NOT",
    ["!"] = "NOT2",
    ["&"] = "BAND",
    ["|"] = "BOR",
    ["^"] = "BXOR",
    ["~"] = "BNOT",
    ["<<"] = "BLSH",
    [">>"] = "BRSH",
    ["+="] = "COMADD",
    ["-="] = "COMSUB",
    ["/="] = "COMDIV",
    ["*="] = "COMMUL",
    ["%="] = "COMMOD",
}
Lexer.Symbols = {
    ["("] = "PSTART",
    [")"] = "PEND",
    [";"] = "SEMICOLON",
    ["{"] = "CBSTART",
    ["}"] = "CBEND",
    ["["] = "SBSTART",
    ["]"] = "SBEND",
    [","] = "COMMA",
    [":"] = "COLON",
    ["."] = "DOT",
}

function Lexer.new(input)
    local self = setmetatable({}, { __index = Lexer })
    self.input = input
    self.position = 1
    self.line_id = 1
    self.line_position = 1
    return self
end

function Lexer:error(err)
    Error:error(err, self.line_id, self.line_position)
    error(err)
end

-- Helper: Check if a character is a letter or a symbol
local function isChar(char)
    return char:match("[%a!%&*+%-[%]^_|=/<>%%]") ~= nil
end
-- Helper: Check if a character is a letter
local function isLetter(char)
    return char:match("[%a_]") ~= nil
end
-- Helper: Check if a character is a digit
local function isDigit(char)
    return char:match("%d") ~= nil
end
local function isOperator(char)
    return Lexer.Operators[char] ~= nil
end
local function isSymbol(char)
    return Lexer.Symbols[char] ~= nil
end

-- Get the current character
function Lexer:currentChar()
    return self.input:sub(self.position, self.position)
end
-- Advance to the next character
function Lexer:advance()
    self.position += 1
    self.line_position += 1
end
-- Insert line and character position to node
function Lexer:insertPosition(node)
    node.position = self.line_position
    node.line = self.line_id
end
-- Skip whitespace
function Lexer:skipWhitespace()
    while self:currentChar():match("%s") do
        if self:currentChar() == "\n" then
            self.line_id += 1
            self.line_position = 1
        end
        self:advance()
    end
end
-- Skip comments (single line for now)
function Lexer:skipComment()
    if self:currentChar() == "#" then
        while self:currentChar() and self:currentChar() ~= "\n" do
            self:advance()
        end
    end
end
function Lexer:readWord()
    local start = self.position
    while isLetter(self:currentChar()) or isDigit(self:currentChar()) do
        self:advance()
    end
    local word = self.input:sub(start, self.position - 1)
    return word
end
function Lexer:readString()
    local quote = self:currentChar()
    self:advance() -- Skip the opening quote
    local value = ""

    while self:currentChar() and self:currentChar() ~= quote do
        if self:currentChar() == "\\" then -- Handle escape sequences
            self:advance()
            local escaped = self:currentChar()
            if escaped == "n" then
                value = value .. "\n"
            elseif escaped == "t" then
                value = value .. "\t"
            elseif escaped == "\\" then
                value = value .. "\\"
            elseif escaped == "\"" or escaped == "'" then
                value = value .. escaped
            else
                self:error("Invalid escape sequence: \\" .. escaped)
            end
        else
            value ..= self:currentChar()
        end
        self:advance()
    end

    if self:currentChar() ~= quote then
        self:error("Unterminated string literal")
    end

    self:advance() -- Skip the closing quote
    return { type = Lexer.TokenType.STRING, value = value }
end
-- Read an identifier
function Lexer:readIdentifier(identifier)
    if Lexer.Keywords[identifier] then
        return { type = Lexer.TokenType.KEYWORD, value = identifier } -- It's a keyword
    else
        return { type = Lexer.TokenType.IDENTIFIER, value = identifier } -- It's an identifier
    end
end
-- Read a number
function Lexer:readNumber()
    local start = self.position
    while isDigit(self:currentChar()) do
        self:advance()
    end
    if self:currentChar() == "." then
        self:advance()
        while isDigit(self:currentChar()) do
            self:advance()
        end
    end
    local number = self.input:sub(start, self.position - 1)
    return { type = Lexer.TokenType.NUMBER, value = tonumber(number) }
end

function Lexer:readOperator()
    local char = self:currentChar()
    local start = self.position
    -- Look ahead for potential multicharacter operators
    while char and (char:match("%a") or char:match("[=<>!]")) do
        char = self:advance()
    end
    local operator = self.input:sub(start, self.position - 1)
    if Lexer.Operators[operator] then
        return { type = Lexer.TokenType.OPERATOR, value = operator }
    else
        self:error("Unknown operator: " .. operator)
        return
    end
end
-- Get the next token
function Lexer:nextToken()
    self:skipWhitespace()
    self:skipComment()
    self:skipWhitespace()
    local char = self:currentChar()
    local node
    if not char or char == "" then
        node = { type = Lexer.TokenType.EOF, line = self.position }
    elseif isDigit(char) then
        node = self:readNumber()
    elseif isSymbol(char) then
        self:advance()
        node = { type = Lexer.TokenType.SYMBOL, value = char }
    elseif isOperator(char) then
        local nextchar = self.input:sub(self.position+1, self.position+1)
        if nextchar ~= "" and isOperator(char..nextchar) then
            self:advance()
            self:advance()
            node = { type = Lexer.TokenType.OPERATOR, value = char..nextchar }
        else
            self:advance()
            node = { type = Lexer.TokenType.OPERATOR, value = char }
        end
    elseif char == "\"" or char == "'" then -- String literals
        node = self:readString()
    elseif isChar(char) then -- Identifiers start with a letter
        local word = self:readWord()
        if isOperator(word) then
            node = { type = Lexer.TokenType.OPERATOR, value = word }
        elseif isLetter(char) then
            node = self:readIdentifier(word)
        end
    end
    if not node then
        self:error("Unexpected character: " .. char)
    end
    self:insertPosition(node)
    return node
end

return Lexer
