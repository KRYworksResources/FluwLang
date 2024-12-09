local executor = require("./executor")
local input = [[
    fn a(b, c) {
        b;
        c;
    };
    a(1, 2);
]]
local targetresults = {
    nil,
    {
        1, 2
    }
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
