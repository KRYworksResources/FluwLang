local executor = require("./executor")
local input = [[
    var a = true;
    var b = false;
]]
local targetresults = {
    true,
    false
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
