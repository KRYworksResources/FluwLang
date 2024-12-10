local executor = require("./executor")
local input = [[
    var counter = 0;
    while (counter < 5) {
        counter = counter + 1;
    };
]]
local targetresults = {
    0,
    nil
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
