local FluwVM = {}
local LexerUtils = require("lexer_utils")
local Parser = require("parser")
local Types = require("types")
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

function FluwVM:pushToEnv(key:string, value:any, typecheck:boolean?)
    if type(value) == "table" then
        value = { type = "dict", value = value }
    end
    local datatype
    if typecheck then
        datatype = Types.getDataTypeNameById(Types.luaGetValueType(value))
    end
    self.Evaluator:declareSymbol(key, value, datatype, "luanative", true, {})
end
function FluwVM:pullFromEnv(key:string)
    local entry = self.Evaluator:getSymbol(key, {})
    if not entry then return end
    local value = entry.value
    if type(value) == "table" then
        if value.type == "fn" then
            return self.Evaluator:fluwFnToFunction(value)
        else
            return value.value
        end
    end
    return value
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