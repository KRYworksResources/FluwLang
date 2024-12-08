local Fluw = {}
local LexerUtils = require("./utils/lexer_utils")
local Parser = require("./utils/parser")
local Evaluator = require("./utils/evaluator")

function Fluw.evaluateExpression(input)
    local tokens = LexerUtils.parseStringToTokens(input)
    local parser = Parser.new(tokens)
    local evaluator = Evaluator.new()
    while parser:currentToken().type ~= "EOF" do
        local ast = parser:parseExpression()
        local result = evaluator:evaluate(ast)
        print(result)
    end
    return 0
end

return Fluw