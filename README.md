# Edge Window Manager for Hammerspoon

一个基于 Hammerspoon 的 macOS 窗口管理工具，可以让窗口智能地贴附在屏幕边缘，并通过鼠标触发显示/隐藏。



https://github.com/user-attachments/assets/be982b2c-f385-463b-b8d4-fdb0de9dce48



## 功能特点

- 支持将窗口贴附在屏幕左侧或右侧边缘
- 智能的鼠标触发显示机制
- 平滑的动画效果
- 多显示器支持
- 热键控制
- 自动隐藏非焦点窗口
- 支持手动拖拽脱离管理

## 安装要求

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) 已安装

## 安装步骤

1. 确保已安装 Hammerspoon
2. 克隆此仓库到 Hammerspoon 的配置目录：
   ```bash
     git clone https://github.com/XiCheng148/EdgeWindow.git ~/.hammerspoon
   ```
 3. 重启 Hammerspoon

## 使用方法

### 默认热键

- `Cmd + Alt + Left`: 将当前窗口贴附到左侧边缘
- `Cmd + Alt + Right`: 将当前窗口贴附到右侧边缘
- `Cmd + Alt + H`: 清除所有边缘贴附的窗口

### 基本操作

1. 使用热键将窗口贴附到屏幕边缘
2. 移动鼠标到屏幕边缘触发区域可显示窗口
3. 鼠标离开窗口区域后窗口自动隐藏
4. 手动拖拽窗口可使其脱离边缘管理

## 配置

可以通过修改 `config.lua` 文件来自定义以下设置：

- 触发区域大小
- 动画持续时间
- 边缘显示大小
- 热键绑定
- 其他参数

## 项目结构

- `init.lua`: 主入口文件
- `EdgeManager.lua`: 核心管理器
- `WindowManager.lua`: 窗口管理
- `StateManager.lua`: 状态管理
- `config.lua`: 配置文件

## 贡献
欢迎提交 Issue 和 Pull Request！

## 致谢

- [Hammerspoon](https://www.hammerspoon.org/) 团队
- 所有贡献者
