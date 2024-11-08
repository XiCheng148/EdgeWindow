local utils = require("utils")

local ErrorHandler = {}

function ErrorHandler.wrap(fn, context)
    return function(...)
        local success, result = xpcall(fn, debug.traceback, ...)
        if not success then
            utils.log("Error in", context, ":", result)
            return nil
        end
        return result
    end
end

function ErrorHandler.assert(condition, message, context)
    if not condition then
        utils.log("Assertion failed in", context, ":", message)
        return false
    end
    return true
end

return ErrorHandler
