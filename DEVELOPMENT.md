# EdgeWindow 开发文档

本文档旨在帮助开发者理解 EdgeWindow 的代码结构和开发流程。

## 📁 项目结构

```
EdgeWindow/
├── init.lua           # 入口文件，初始化 EdgeManager
├── EdgeManager.lua    # 核心管理器，协调各组件工作
├── WindowManager.lua  # 窗口管理，处理窗口操作
├── StateManager.lua   # 状态管理，维护窗口状态
├── MenuBar.lua        # 菜单栏界面实现
├── config.lua         # 配置文件
└── log.lua            # 日志管理
```

## 🔄 核心组件

### EdgeManager

EdgeManager 是核心管理器，负责：
- 初始化和协调其他组件
- 处理鼠标事件和窗口事件
- 管理窗口触发区域
- 处理快捷键事件

主要方法：
- `new()`: 创建新实例
- `init()`: 初始化组件
- `setupWindowFilter()`: 设置窗口过滤器
- `setupMouseWatcher()`: 设置鼠标监听
- `handleHotkey()`: 处理快捷键事件

### WindowManager

负责窗口的具体操作：
- 获取和设置窗口位置
- 处理窗口动画
- 管理窗口列表

主要方法：
- `moveWindow()`: 移动窗口
- `getAllWindows()`: 获取所有管理的窗口
- `isValidWindow()`: 检查窗口是否有效

### StateManager

管理窗口状态：
- 跟踪窗口移动状态
- 维护窗口显示/隐藏状态
- 保存窗口原始位置

主要方法：
- `setState()`: 设置窗口状态
- `getState()`: 获取窗口状态
- `isWindowMoving()`: 检查窗口是否正在移动

### MenuBar

实现菜单栏界面：
- 显示窗口列表
- 提供快捷操作按钮
- 显示状态信息

## 🔧 开发指南

### 添加新功能

1. 确定新功能属于哪个组件
2. 在相应组件中实现功能
3. 在 EdgeManager 中集成新功能
4. 更新配置文件（如需要）
5. 添加日志记录

### 代码风格

- 使用驼峰命名法
- 函数和方法添加注释说明
- 保持代码简洁，避免重复
- 使用有意义的变量名

### 错误处理

- 使用 pcall 或 xpcall 处理可能的错误
- 记录详细的错误信息到日志
- 提供用户友好的错误提示

### 性能考虑

- 避免频繁的窗口操作
- 优化鼠标位置检查逻辑
- 合理使用定时器
- 减少不必要的状态更新

## 🧪 测试

目前项目没有自动化测试，建议添加：
- 单元测试：测试各个组件的功能
- 集成测试：测试组件间的交互
- 性能测试：测试在大量窗口下的表现

## 🐛 调试

1. 启用详细日志：
   ```lua
   hs.logger.defaultLogLevel = 'debug'
   ```

2. 使用 Hammerspoon 控制台：
   - 按 `Cmd + Alt + C` 打开控制台
   - 查看错误信息和日志输出

3. 使用 `hs.inspect()` 查看对象内容：
   ```lua
   print(hs.inspect(windowObject))
   ```

## 📝 提交规范

1. 创建功能分支：
   ```bash
   git checkout -b feature/your-feature
   ```

2. 提交信息格式：
   ```
   feat: 添加新功能
   fix: 修复问题
   docs: 更新文档
   style: 代码格式修改
   refactor: 代码重构
   test: 添加测试
   chore: 构建过程或辅助工具的变动
   ```

3. 提交 Pull Request 前：
   - 确保代码符合风格规范
   - 测试功能是否正常
   - 更新相关文档
   - 添加必要的注释

## 🔜 待办事项

- [ ] 添加单元测试框架
- [ ] 实现配置持久化
- [ ] 优化性能监控
- [ ] 改进错误处理机制
- [ ] 支持插件系统
