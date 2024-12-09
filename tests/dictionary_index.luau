local executor = require("./executor")
local input = [[
    var a = {
        "key": "value"
    };
    var b = a["key"];
]]
local targetresults = {
    {
        key = "value"
    },
    "value"
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
