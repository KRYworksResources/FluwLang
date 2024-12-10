local executor = require("./executor")
local input = [[
    var if1 = false;
    if (if1) {
        var p1 = false;
        var p2 = true;
    } elif (!if1) {
        var p1 = true;
        var p2 = false;
    };
    if (false) {
        var p1 = true;
        var p2 = false;
    } else {
        var p1 = false;
        var p2 = true;
    };
]]
local targetresults = {
    false, 
    nil,
    nil
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
