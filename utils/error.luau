local Error = {}

Error.stderr = print
Error.stdout = print
function Error:error(err, line, character)
    Error.stderr(`FlowError {line or 1}:{character or 1} :: {err}`)
end
function Error:warn(err, line, character)
    Error.stdout(`FlowWarn {line or 1}:{character or 1} :: {err}`)
end

return Error