local utils = {}

function utils.isPointInRect(point, rect)
    return point.x >= rect.x and point.x <= rect.x + rect.w and
           point.y >= rect.y and point.y <= rect.y + rect.h
end

function utils.log(...)
    print(string.format("[EdgeManager] %s", table.concat({...}, " ")))
end

return utils
