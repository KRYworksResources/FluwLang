local executor = require("./executor")
local input = [[
    const a = "hello, world!";
    const b = true;
]]
local targetresults = {
    "hello, world!",
    true,
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
