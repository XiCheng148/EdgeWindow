local utils = {}

function utils.isPointInRect(point, rect)
    return point.x >= rect.x and point.x <= rect.x + rect.w and
           point.y >= rect.y and point.y <= rect.y + rect.h
end

return utils
