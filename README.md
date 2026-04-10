# AI 人生记录器 📝

> **记录生活的美好瞬间，用 AI 留住每一份感动**  
> **开发者：杰哥网络科技** | QQ: 2711793818

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-00B4AB?logo=dart)](https://dart.dev)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/jiege455/life_recorder/build-android.yml)](https://github.com/jiege455/life_recorder/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 🌟 项目简介

**AI 人生记录器**是一款智能的 Flutter 日记应用，集成了 AI 标签生成、语音识别、每日提醒等功能，帮助你轻松记录生活点滴，留住美好回忆。

### ✨ 核心亮点

- 🤖 **AI 智能标签** - DeepSeek AI 自动生成标签，快速分类
- 🎤 **语音输入** - 科大讯飞语音识别，说话即可记录
- ⏰ **每日提醒** - 定时提醒，养成记录好习惯
- 🔒 **隐私保护** - PIN 码 + 生物识别，双重安全保障
- 📊 **数据统计** - 多维度分析，了解你的生活轨迹
- 🎨 **精美 UI** - 现代化设计，支持深色模式

---

## 📱 功能特性

### 🎯 核心功能

#### 🏷️ AI 智能标签
- 基于 DeepSeek AI 大模型
- 根据记录内容自动生成合适的标签
- 支持自定义常用标签
- 快速分类和检索

#### 🎤 语音输入
- 科大讯飞高精度语音识别
- 支持实时识别，边说边显示
- 识别准确率高达 95%+
- 解放双手，记录更便捷

#### ⏰ 每日提醒
- 每天固定时间发送通知
- 可自定义提醒时间
- 支持测试通知功能
- 帮助养成记录习惯

#### 🔒 隐私保护
- 4 位 PIN 码锁
- 指纹/面部识别
- 紧急解锁功能
- 加密存储，安全可靠

#### 📊 统计分析
- 记录总数统计
- 本周/月记录趋势
- 最常用标签
- 心情分布图表
- 年度回顾报告

#### 📅 日历视图
- 按日期查看记录
- 每天记录数量显示
- 快速跳转
- 月视图/周视图

### 🎨 界面设计

- ✅ 现代化 Material Design 3
- ✅ 支持深色/浅色模式
- ✅ 流畅的动画效果
- ✅ 响应式布局
- ✅ 适配不同屏幕尺寸

---

## 🔧 技术架构

### 技术栈

```
前端框架：Flutter 3.x
编程语言：Dart 3.x
状态管理：Provider
本地数据库：SQLite (sqflite)
AI 服务：DeepSeek API
语音识别：科大讯飞 iFLYTEK
通知系统：flutter_local_notifications
生物识别：local_auth
```

### 项目结构

```
lib/
├── main.dart                 # 应用入口
├── config/                   # 配置文件
│   ├── api_config.dart      # API 配置
│   └── ...
├── pages/                    # 页面
│   ├── home_page.dart       # 首页
│   ├── add_record_page.dart # 添加记录
│   ├── settings_page.dart   # 设置
│   ├── reminder_page.dart   # 提醒设置
│   └── ...
├── services/                 # 服务层
│   ├── ai_service.dart      # AI 服务
│   ├── speech_service.dart  # 语音服务
│   ├── reminder_service.dart# 提醒服务
│   ├── lock_service.dart    # 隐私锁服务
│   └── ...
├── widgets/                  # 组件
└── utils/                    # 工具类
```

### 核心服务

| 服务 | 说明 | 状态 |
|------|------|------|
| `ReminderService` | 每日提醒服务 | ✅ 正常 |
| `LockService` | 隐私锁服务 | ✅ 正常 |
| `AiService` | AI 标签生成 | ✅ 正常 |
| `SpeechService` | 语音识别 | ✅ 正常 |
| `TagService` | 标签管理 | ✅ 正常 |

---

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Android 5.0+ / iOS 12.0+

### 安装依赖

```bash
flutter pub get
```

### 配置密钥

在 `lib/config/api_config.dart` 中配置：

```dart
class ApiConfig {
  // AI 标签生成 - DeepSeek
  static const String deepseekApiKey = 'your_api_key';
  
  // 语音识别 - 科大讯飞
  static const String iflyAppId = 'your_app_id';
  static const String iflyAppKey = 'your_app_key';
  static const String iflyAppSecret = 'your_app_secret';
}
```

### 运行应用

```bash
flutter run
```

### 构建 APK

```bash
flutter build apk --release
```

---

## 📦 构建与发布

### GitHub Actions 自动构建

项目已配置 GitHub Actions，推送代码后自动构建 APK：

```yaml
# .github/workflows/build-android.yml
name: Build Android APK
on:
  push:
    branches: [ main ]
```

### 手动构建

#### Android
```bash
flutter build apk --release
flutter build appbundle --release  # 发布到 Google Play
```

#### iOS
```bash
flutter build ios --release
```

---

## 🎯 使用指南

### 1. 首次使用

1. **同意用户协议和隐私政策**
2. **设置应用主题**（浅色/深色/跟随系统）
3. **可选：设置隐私锁**保护隐私

### 2. 添加记录

1. 点击首页右下角 **+** 按钮
2. 输入记录内容（或按住语音按钮说话）
3. 点击 **生成标签** 或选择常用标签
4. 选择心情（可选）
5. 添加图片（可选）
6. 点击 **保存**

### 3. 设置每日提醒

1. 进入 **设置** → **每日提醒**
2. 开启提醒开关
3. 设置提醒时间（默认 20:00）
4. 点击 **测试通知** 验证

### 4. 启用隐私锁

1. 进入 **设置** → **隐私锁**
2. 开启隐私锁开关
3. 设置 4 位 PIN 码
4. 可选：启用生物识别

---

## 📊 功能演示

### 首页
- 记录列表
- 心情筛选
- 搜索功能
- 下拉刷新

### 添加记录
- 文本输入
- 语音输入
- AI 标签生成
- 常用标签
- 图片上传
- 心情选择

### 统计页面
- 记录总数
- 本周统计
- 标签云
- 心情分布
- 趋势图表

### 日历视图
- 月视图
- 日记录
- 快速跳转

---

## 🔐 隐私与安全

### 数据加密
- PIN 码加密存储
- 本地数据库加密
- 不上传任何用户数据到云端

### 权限说明

| 权限 | 用途 | 必需 |
|------|------|------|
| 麦克风 | 语音输入 | 否 |
| 相机 | 拍照记录 | 否 |
| 存储 | 保存图片 | 否 |
| 通知 | 每日提醒 | 否 |
| 生物识别 | 隐私解锁 | 否 |

### 隐私保护
- ✅ 所有数据本地存储
- ✅ 不收集用户信息
- ✅ 不追踪用户行为
- ✅ 开源代码，透明可审计

---

## 🧪 测试

### 运行测试
```bash
flutter test
```

### 测试覆盖
- 服务层测试
- 工具类测试
- 组件测试

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 提交 Bug
请在 Issue 中提供：
1. 设备型号和系统版本
2. 复现步骤
3. 预期行为和实际行为
4. 截图或录屏（如有）

### 功能建议
请在 Issue 中说明：
1. 功能描述
2. 使用场景
3. 预期效果

---

## 📄 开源协议

MIT License

---

## 📞 联系方式

### 开发者信息
- **开发者**: 杰哥网络科技
- **QQ**: 2711793818
- **邮箱**: (待添加)

### 问题反馈
- GitHub Issues: https://github.com/jiege455/life_recorder/issues
- QQ 群：(待添加)

---

## 🙏 致谢

感谢以下开源项目和服务：

- [Flutter](https://flutter.dev) - 跨平台框架
- [DeepSeek](https://deepseek.com) - AI 标签生成
- [科大讯飞](https://www.xfyun.cn) - 语音识别
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) - 通知插件
- [local_auth](https://pub.dev/packages/local_auth) - 生物识别插件
- [provider](https://pub.dev/packages/provider) - 状态管理

---

## 📅 更新日志

### v1.0.0 (2025-04-10)
- ✅ 修复每日提醒通知权限问题
- ✅ 优化隐私锁 PIN 码验证逻辑
- ✅ 优化生物识别功能
- ✅ 添加测试通知功能
- ✅ 添加详细的使用说明文档

### v0.9.0 (2025-04-06)
- ✅ 初始版本发布
- ✅ AI 标签生成功能
- ✅ 语音输入功能
- ✅ 每日提醒功能
- ✅ 隐私锁功能

---

## 📸 应用截图

（待添加应用截图）

---

## 🎯 未来计划

- [ ] 云端备份和同步
- [ ] 多语言支持
- [ ] 桌面小组件
- [ ] 导出为 PDF/Markdown
- [ ] 时间轴视图
- [ ] 更多统计图表
- [ ] 语音日记朗读
- [ ] 情感分析

---

## ⭐ 给项目点赞

如果你觉得这个项目对你有帮助，请给个 ⭐ Star 支持一下！

---

**Made with ❤️ by 杰哥网络科技**

---

**最后更新**: 2025-04-10  
**当前版本**: v1.0.0  
**仓库状态**: 私有仓库
