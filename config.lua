return {
  MOVE_THRESHOLD = 15,  -- 移动判定阈值
  ANIMATION_DURATION = 0,  -- 动画持续时间(时间长会有卡卡的感觉)
  EDGE_PEEK_SIZE = 15,  -- 边缘露出的宽度
  EDGE_TRIGGER_SIZE = 6,  -- 边缘触发器的宽度
  HOTKEYS = {
      LEFT = {
          mods = {"cmd", "ctrl"},
          key = "left"
      },
      RIGHT = {
          mods = {"cmd", "ctrl"},
          key = "right"
      },
      CLEAR = {
          mods = {"cmd", "ctrl"},
          key = "h"
      }
  }
}
