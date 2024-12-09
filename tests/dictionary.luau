local executor = require("./executor")
local input = [[
    var a = {
        "key": "value",
        5: true,
        2 + 2: 1 * 3
    };
]]
local targetresults = {
    {
        key = "value",
        [5] = true,
        [4] = 3
    }
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
