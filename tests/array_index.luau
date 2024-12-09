local executor = require("./executor")
local input = [[
    var a = [
        "value"
    ];
    var b = a[1];
]]
local targetresults = {
    {
        "value"
    },
    "value"
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
