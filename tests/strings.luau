local executor = require("./executor")
local input = [[
    def a = "hello";
    def b = "world";
    def c = '!';
]]
local targetresults = {
    "hello",
    "world",
    "!"
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
