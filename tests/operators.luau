local executor = require("./executor")
local input = [[
    var a = true and false;
    var b = false or true;
    var c = 1 == 1;
    var d = 1 < 2;
    var e = true != true;
]]
local targetresults = {
    false,
    true,
    true,
    true,
    false
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
