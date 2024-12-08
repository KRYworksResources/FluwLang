local Error = {}

function Error:error(err, line, character)
    print(`FlowError {line or 1}:{character or 1} :: {err}`)
end
function Error:warn(err, line, character)
    print(`FlowWarn {line or 1}:{character or 1} :: {err}`)
end

return Error