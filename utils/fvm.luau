local FluwVM = {}
local LexerUtils = require("lexer_utils")
local Parser = require("parser")
local Evaluator = require("evaluator")

function FluwVM:execute(input:string)
    local tokens = LexerUtils.parseStringToTokens(input)
    local parser = Parser.new(tokens)
    local astree = {}
    while parser:currentToken().type ~= "EOF" do
        local node = parser:parseStatement()
        table.insert(astree, node)
    end
    for i=1, #astree do
        local node = astree[i]
        self.Evaluator:evaluate(node)
    end
end

function FluwVM:pushToEnv(key:string, value:any)
    self.Evaluator:declareSymbol(key, value, nil, "luanative", true, {})
end
function FluwVM:getResult()
    return self.Evaluator:getResult()
end

function FluwVM.new()
    local vm = setmetatable({}, {
        __index = FluwVM
    })
    vm.Evaluator = Evaluator.new()
    return vm
end

return FluwVM