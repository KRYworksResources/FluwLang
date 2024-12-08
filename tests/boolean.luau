local executor = require("./executor")
local input = [[
    def a = true;
    def b = false;
]]
local targetresults = {
    true,
    false
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
