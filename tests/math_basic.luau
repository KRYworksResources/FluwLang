local executor = require("./executor")
local input = [[
    2 + 2;
    2 - 2;
    2 / 2;
    2 * 2;
    2 % 2;
]]
local targetresults = {
    4,
    0,
    1,
    4,
    0
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
