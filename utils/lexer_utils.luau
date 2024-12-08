local LexerUtils = {}
local Lexer = require("./lexer")

-- Turn script contents to a token table
function LexerUtils.parseStringToTokens(input)
    local lexer = Lexer.new(input)
    local tokens = {}
    local token = lexer:nextToken()
    while token.type ~= Lexer.TokenType.EOF do
        table.insert(tokens, token)
        token = lexer:nextToken()
    end
    -- since we skip eof token we manually insert it here
    table.insert(tokens, token)
    return tokens
end

return LexerUtils