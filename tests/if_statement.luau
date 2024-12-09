local executor = require("./executor")
local input = [[
    var if1 = true;
    if (if1) {
        var p1 = false;
        var p2 = true;
    };
]]
local targetresults = {
    true, 
    {
        false,
        true
    }
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
