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
    return a[key];
]]
local targetresult = {
    recursive = true
}
return function()
    local result = executor.run(input)
    assert(executor.compare_tables(result, targetresult), "Assertion failed!")
end
