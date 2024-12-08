local executor = require("./executor")
local input = [[
    1.1 + 1.1;
    10 * 2.5;
    -1.5 + 1.5;
    12.5555 * 10;
]]
local targetresults = {
    2.2,
    25,
    0,
    125.555
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
