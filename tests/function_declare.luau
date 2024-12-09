local executor = require("./executor")
local input = [[
    fn a(b, c) {};
]]
local targetresults = {
    nil
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
