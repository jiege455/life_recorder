# AI人生记录器 (Life Recorder)

一款基于Flutter开发的移动应用，使用AI技术自动为用户记录的生活点滴打标签。

## 功能特性

- 📝 **记录管理** - 添加、查看、删除生活记录
- 🤖 **AI自动打标签** - 使用DeepSeek API智能生成标签
- 🎤 **语音输入** - 支持语音转文字，方便快速记录
- 😊 **心情记录** - 支持选择不同心情状态
- 📅 **时间线展示** - 按日期分组展示记录
- 📊 **统计卡片** - 显示总记录数、本周记录数、最常用标签

## 技术栈

- **框架**: Flutter 3.0+
- **状态管理**: Riverpod
- **本地数据库**: SQLite (sqflite)
- **网络请求**: Dio
- **语音识别**: speech_to_text
- **AI服务**: DeepSeek API

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── database/
│   └── database_helper.dart  # 数据库操作类
├── pages/
│   ├── home_page.dart        # 主页面
│   └── add_record_page.dart  # 添加记录页面
└── services/
    └── ai_service.dart      # AI服务类
```

## 配置说明

### 1. API密钥配置

在 `lib/services/ai_service.dart` 文件中替换您的DeepSeek API密钥：

```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

获取API密钥：https://platform.deepseek.com/

### 2. 依赖安装

```bash
flutter pub get
```

### 3. 运行应用

```bash
# debug模式
flutter run

# release模式
flutter build apk --release
```

## 开发者信息

- 开发者：杰哥网络科技
- 联系QQ：2711793818

## 许可证

本项目仅供学习交流使用。
