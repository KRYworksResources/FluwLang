local executor = require("./executor")
local input = [[
    5 & 3;
    5 | 3;
    5 ^ 3;
    ~5;
    5 << 1;
    5 >> 1;
]]
local targetresults = {
    bit32.band(5, 3),
    bit32.bor(5, 3),
    bit32.bxor(5, 3),
    bit32.bnot(5),
    bit32.lshift(5, 1),
    bit32.rshift(5, 1),
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
