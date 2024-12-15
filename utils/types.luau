local Types = {
    DataTypes = {
        any = 1,
        auto = 2, -- should normally not be reachable
        ["function"] = 3,
        float = 4,
        bool = 5,
        dictionary = 6,
        array = 7,
        luafunction = 8,
        luanative = 9,
        null = 10,
        cothread = 11,
        string = 12,
        int = 13,
    }
}

local reversedLookupDataTypes = {}
do
    for k,v in Types.DataTypes do
        reversedLookupDataTypes[v] = k
    end
end

function Types.getDataTypeNameById(id)
    return reversedLookupDataTypes[id]
end

local Error = require("error")
local function handleError(message)
    Error:error(message)
    error(message)
end

local luaPrimitiveToType = {
    ["nil"] = "null",
    boolean = "bool",
    number = "float",
    string = "string",
    userdata = "luanative",
    ["function"] = "function",
    thread = "cothread",
    table = "dict"
}
function Types.luaGetValueType(value)
    return Types.DataTypes[luaPrimitiveToType[type(value)] or "any"]
end
function Types.getValueType(entry)
    return Types.DataTypes[entry.type or "unknown"] or Types.DataTypes.any
end
local function isArray(tbl)
    return type(tbl) == "table" and (#tbl > 0 or next(tbl) == nil)
end
function Types.isValueType(datatype, entry, value)
    if not datatype or not value then return true end
    if type(datatype) == "string" then
        datatype = Types.DataTypes[entry.type or "unknown"] or Types.DataTypes.any
    end
    if datatype == Types.DataTypes.any then return true
    elseif datatype == Types.DataTypes.auto then
        handleError(`Tried to typecheck an 'auto' variable!`);
        return
    elseif datatype == Types.DataTypes["function"] then
        if type(value) == "function" then return true end
        local valid = type(value) == "table"
        if not valid then return false end
        return value.type == "fn"
    elseif datatype == Types.DataTypes.float then return type(value) == "number"
    elseif datatype == Types.DataTypes.bool then return type(value) == "boolean"
    elseif datatype == Types.DataTypes.dictionary then return type(value) == "table"
    elseif datatype == Types.DataTypes.array then return isArray(value)
    elseif datatype == Types.DataTypes.luafunction then
        return entry.vartype == "luanative" and type(value) == "function"
    elseif datatype == Types.DataTypes.luanative then return entry.vartype == "luanative"
    elseif datatype == Types.DataTypes.null then return value == nil
    elseif datatype == Types.DataTypes.cothread then return type(value) == "thread"
    elseif datatype == Types.DataTypes.string then return type(value) == "string"
    elseif datatype == Types.DataTypes.int then return type(value) == "number" and value % 1 == 0
    end
    handleError(`Unknown datatype ({datatype}) was given to typecheck!`);
    return
end

return Types