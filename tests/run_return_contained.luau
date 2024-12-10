local executor = require("./executor")
local input = [[
    fn contained() {
        return 1;
    };
    contained();
]] -- we dont return values so it should be nil
local targetresult = nil
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
