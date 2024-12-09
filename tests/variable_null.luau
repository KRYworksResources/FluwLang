local executor = require("./executor")
local input = [[
    var a = null;
    a = "notnull";
    var b = "notnull";
    b = null;
]]
local targetresults = {
    nil,
    "notnull",
    "notnull",
    nil
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
