local utils = require("utils")

local ErrorHandler = {}

function ErrorHandler.wrap(fn, context)
    return function(...)
        local success, result = xpcall(fn, debug.traceback, ...)
        if not success then
            -- todo
            return nil
        end
        return result
    end
end

function ErrorHandler.assert(condition, message, context)
    if not condition then
        -- todo
        return false
    end
    return true
end

return ErrorHandler
