local Error = {}

Error.stderr = print
Error.stdout = print
function Error:error(err, line, character)
    Error.stderr(`FluwError {line or 1}:{character or 1} :: {err}`)
end
function Error:warn(err, line, character)
    Error.stdout(`FluwWarn {line or 1}:{character or 1} :: {err}`)
end

return Error