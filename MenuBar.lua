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
        -- self.menubar:setIcon(hs.image.imageFromPath(hs.configdir .. "/icons/menubar.svg"))
        self.menubar:setTitle('👀')
        self:updateMenu()
    else
        log.error("Menubar", "Failed to create menubar")
    end
end

function Menubar:updateMenu()
    if not self.menubar then return end

    local menuTable = {
        {
            title = "添加至左边 \t ^ ⌘ ←",
            fn = function()
                self.callbacks.addToLeft()
                self:updateMenu()
            end,
        },
        {
            title = "添加至右边 \t ^ ⌘ →",
            fn = function()
                self.callbacks.addToRight()
                self:updateMenu()
            end,
        },
        {
            title = "清除所有 \t ^ ⌘ H",
            fn = function()
                self.callbacks.clearAll()
                self:updateMenu()
            end,
        },
        { title = "-" } -- 分隔线
    }

    -- 获取所有窗口并按 space 分组
    local windows = self.callbacks.getAllWindows()
    local windowsBySpace = {}
    
    -- 按 space 分组
    for _, info in pairs(windows) do
        local space = info.space
        if not windowsBySpace[space] then
            windowsBySpace[space] = {left = {}, right = {}}
        end
        
        -- 根据 edge 判断左右
        if info.edge == "left" then
            table.insert(windowsBySpace[space].left, info)
        elseif info.edge == "right" then
            table.insert(windowsBySpace[space].right, info)
        end
    end

    -- 获取所有 space 并按照真实顺序排序
    local spaces = {}
    local spaceIndex = {}  -- 用于记录 space ID 到序号的映射
    
    -- 获取所有显示器
    local screens = hs.screen.allScreens()
    -- 获取每个显示器上的 spaces
    for _, screen in ipairs(screens) do
        local screenSpaces = hs.spaces.spacesForScreen(screen)
        -- 为每个 space 记录它的显示顺序
        for order, spaceID in ipairs(screenSpaces) do
            if windowsBySpace[spaceID] then  -- 只记录有窗口的 space
                table.insert(spaces, spaceID)
                spaceIndex[spaceID] = order  -- 使用系统实际的顺序
            end
        end
    end

    -- 按 space 添加到菜单
    for _, space in ipairs(spaces) do
        -- 只有当这个 space 有窗口时才添加分组
        if #windowsBySpace[space].left > 0 or #windowsBySpace[space].right > 0 then
            -- 添加 space 分隔标题
            table.insert(menuTable, { title = "-" })  -- 分隔线
            table.insert(menuTable, {
                title = "桌面 " .. spaceIndex[space],
                disabled = true  -- 使标题显示为灰色且不可点击
            })
            
            -- 添加左边的窗口
            for _, info in ipairs(windowsBySpace[space].left) do
                table.insert(menuTable, {
                    title = info.title,
                    fn = function() info.window:focus() end,
                    -- indent = 1  -- 添加缩进
                })
            end
            
            -- 添加右边的窗口
            for _, info in ipairs(windowsBySpace[space].right) do
                table.insert(menuTable, {
                    title = info.title,
                    fn = function() info.window:focus() end,
                    -- indent = 1  -- 添加缩进
                })
            end
        end
    end

    table.insert(menuTable, { title = "-" })
    table.insert(menuTable, {
        title = "重启！",
        fn = function()
            self.callbacks.clearAll()
            self:updateMenu()
            -- 延迟 0.5 秒执行
            hs.timer.doAfter(0.5, function()
                hs.reload()
            end)
        end
    })

    self.menubar:setMenu(menuTable)
end

function Menubar:destroy()
    if self.menubar then
        self.menubar:delete()
        self.menubar = nil
    end
end

return Menubar
