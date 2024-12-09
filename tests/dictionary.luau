local executor = require("./executor")
local input = [[
    var key = "meow";
    var a = {
        "key": "value",
        5: true,
        2 + 2: 1 * 3,
        key: {
            "recursive": true,
        }
    };
]]
local targetresults = {
    "meow", -- the string we define lol
    {
        key = "value",
        [5] = true,
        [4] = 3,
        meow = {
            recursive = true
        }
    }
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
