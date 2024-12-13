local executor = require("./executor")
local input = [[
    var a = [
        "value",
        [
            "ooOOrecursiveOOoo"
        ]
    ];
    return a[2][1];
]]
local targetresult = "ooOOrecursiveOOoo"
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
