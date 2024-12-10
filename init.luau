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

function Fluw.executeString(input)
    local tokens = LexerUtils.parseStringToTokens(input)
    local evaluator = Evaluator.new()
    local parser = Parser.new(tokens)
    while parser:currentToken().type ~= "EOF" do
        local ast = parser:parseStatement()
        evaluator:evaluate(ast)
    end
    return evaluator:getResult()
end

return Fluw