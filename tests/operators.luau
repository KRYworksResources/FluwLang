local executor = require("./executor")
local input = [[
    var a = true and false;
    var a2 = true && false;
    var b = false or true;
    var b2 = false || true;
    var c = 1 == 1;
    var d = 1 < 2;
    var e = true != true;
    var f = not true;
    var g = !false;
]]
local targetresults = {
    false,
    false,
    true,
    true,
    true,
    true,
    false,
    false,
    true
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
