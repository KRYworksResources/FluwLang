local LexerUtils = require("../utils/lexer_utils")
local Parser = require("../utils/parser")
local Evaluator = require("../utils/evaluator")
local e = {
    exec = function(input)
        local results = {}
        local tokens = LexerUtils.parseStringToTokens(input)
        local evaluator = Evaluator.new()
        local parser = Parser.new(tokens)
        while parser:currentToken().type ~= "EOF" do
            local ast = parser:parseStatement()
            local result = evaluator:evaluate(ast)
            table.insert(results, result)
        end
        return results
    end,
    compare_tables = function(t1, t2)
        for k, v in t1 do
            if t2[k] ~= v then return false end
        end
        for k, v in t2 do
            if t1[k] ~= v then return false end
        end
        return true
    end
}
return e