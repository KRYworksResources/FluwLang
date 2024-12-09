local executor = require("./executor")
local input = [[
    var a = [
        "value",
        [
            "ooOOrecursiveOOoo"
        ]
    ];
]]
local targetresults = {
    {
        "value",
        {
            "ooOOrecursiveOOoo"
        }
    }
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
