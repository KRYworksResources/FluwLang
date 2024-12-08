local executor = require("./executor")
local input = [[
    def a = true and false;
    def b = false or true;
    def c = 1 == 1;
    def d = 1 < 2;
    def e = true != true;
]]
local targetresults = {
    false,
    true,
    true,
    true,
    false
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
