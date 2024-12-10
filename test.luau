local FS = require("@lune/fs")
local IO = require("@lune/stdio")
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
        IO.write(IO.color("red"))
        log(`{path} failed: {err}`)
        IO.write(IO.color("reset"))
    else
        successes += 1
    end
    pstr ..= if success then IO.color("green").."|" else IO.color("red").."!"
end
log(pstr)
IO.write(IO.color("reset"))
print(
    `{IO.color("green")}SUCCESSFUL:{IO.color("reset")} {successes}\n{IO.color("red")}FAILED: {IO.color("reset")}{fails}`)
print(string.format("All tests finished in %d ms!", (os.clock()-startClock)*1000))