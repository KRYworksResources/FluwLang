local Fluw = require("./init")
local error = require("./utils/error")
error.stderr = function(...) end
error.stderr = function(...) end
local IO = require("@lune/stdio")

print("Fluw REPL v1.0-alpha")
while true do
    local Input = IO.prompt("text")
    local Success, Result = pcall(Fluw.executeString, Input)
    if Success then
        IO.write(IO.color("reset"))
        print(`= {Result}`)
    else
        IO.write(IO.color("red"))
        print(`! {Result}`)
    end
end