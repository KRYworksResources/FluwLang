local FS = require("@lune/fs")
local files = FS.readDir("./tests/")

local function log(...)
    print("[TESTS]: ", ...)
end

local successes, fails = 0, 0
local pstr = ""
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