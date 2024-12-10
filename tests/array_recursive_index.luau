local executor = require("./executor")
local input = [[
    var a = [
        [
            1
        ],
        [
            2
        ]
    ];
    var b = a[1][1];
    var c = a[2][1];
]]
local targetresults = {
    {
        {1}, {2}
    },
    1, 2
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
