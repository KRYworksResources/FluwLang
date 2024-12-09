local LexerUtils = require("../utils/lexer_utils")
local Parser = require("../utils/parser")
local Evaluator = require("../utils/evaluator")
local e
e = {
    exec = function(input)
        local results = {}
        local tokens = LexerUtils.parseStringToTokens(input)
        local evaluator = Evaluator.new()
        local parser = Parser.new(tokens)
        local eval_id = 1
        while parser:currentToken().type ~= "EOF" do
            local ast = parser:parseStatement()
            local result = evaluator:evaluate(ast)
            results[eval_id] = result
            eval_id += 1
        end
        return results
    end,
    compare_tables = function(t1, t2)
        for k, v in t1 do
            if type(v) == "table" then
                local equal = e.compare_tables(v, t2[k] or {})
                if not equal then return false end
            else
                if t2[k] ~= v then return false end
            end
        end
        for k, v in t2 do
            if type(v) == "table" then
                local equal = e.compare_tables(v, t1[k] or {})
                if not equal then return false end
            else
                if t1[k] ~= v then return false end
            end
        end
        return true
    end
}
return e