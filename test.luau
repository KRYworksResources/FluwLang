local FS = require("@lune/fs")
local files = FS.readDir("./tests/")
local error = require("./utils/error")
error.stderr = function(...) end
error.stderr = function(...) end

local function log(...)
    print("[TESTS]: ", ...)
end

local successes, fails = 0, 0
local pstr = ""
local startClock = os.clock()
for _,path in files do
    local func = require("./tests/"..path)
    if type(func) ~= "function" then continue end
    local success, err = pcall(func)
    if not success then
        fails += 1
        log(`{path} failed: {err}`)
    else
        successes += 1
    end
    pstr ..= if success then "." else "!"
end
log(pstr)
print(`SUCCESSFUL: {successes}\nFAILED: {fails}`)
print(string.format("All tests finished in %.3f seconds!", os.clock()-startClock))