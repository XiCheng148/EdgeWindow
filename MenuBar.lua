local Menubar = {}
Menubar.__index = Menubar

local log = require("log")

function Menubar:new(callbacks)
    local self = setmetatable({}, Menubar)

    -- 只接收需要的回调函数

    self.callbacks = {
        addToLeft = callbacks.addToLeft,         -- 添加到左边的回调
        addToRight = callbacks.addToRight,       -- 添加到右边的回调
        clearAll = callbacks.clearAll,           -- 清除所有的回调
        getAllWindows = callbacks.getAllWindows, -- 获取窗口列表的回调
    }

    self:init()
    return self
end

function Menubar:init()
    self.menubar = hs.menubar.new()
    if self.menubar then
        self.menubar:setTitle("📌")
        self:updateMenu()
    else
        log.error("Menubar", "Failed to create menubar")
    end
end

function Menubar:updateMenu()
    if not self.menubar then return end

    local menuTable = {
        {
            title = "添加至左边",
            fn = function()
                self.callbacks.addToLeft()
                self:updateMenu()
            end
        },
        {
            title = "添加至右边",
            fn = function()
                self.callbacks.addToRight()
                self:updateMenu()
            end
        },
        {
            title = "清除所有",
            fn = function()
                self.callbacks.clearAll()
                self:updateMenu()
            end
        },
        {
            title = "配置设置",
            fn = function()
                if not self.configUI then
                    self.configUI = require("ConfigUI"):new()
                end
                self.configUI:show()
            end
        },
        { title = "-" }, -- 分隔线
        {
            title = "重启！",
            fn = function()
                hs.reload()
            end
        },
        { title = "-" } -- 分隔线
    }

    -- 添加当前管理的窗口列表
    local windows = self.callbacks.getAllWindows()
    for _, info in pairs(windows) do
        local windowTitle = info.window:application():name() or "Unknown"
        local menuItem = {
            title = string.format("%s (%s)", windowTitle, info.edge),
            fn = function()
                info.window:focus()
            end
        }
        table.insert(menuTable, menuItem)
    end

    self.menubar:setMenu(menuTable)
end

function Menubar:destroy()
    if self.menubar then
        self.menubar:delete()
        self.menubar = nil
    end
end

return Menubar
