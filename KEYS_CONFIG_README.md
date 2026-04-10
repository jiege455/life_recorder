# 🔑 密钥配置说明

> **重要提示：** 本仓库为私有仓库，密钥文件可以安全存放。  
> **如果要公开仓库，请务必先删除或加密密钥文件！**

---

## 📁 密钥配置文件

### 文件位置
`lib/config/api_config.dart`

### 配置的密钥

#### 1. AI 标签生成 - DeepSeek
```dart
static const String deepseekApiKey = 'sk-4c521537a01a44aebc4a2bd9f057dde9';
```

#### 2. 语音识别 - 科大讯飞
```dart
static const String iflyAppId = '000dc3e2';
static const String iflyAppKey = 'eeb3a079d047433a30fc7d39a2988f50';
static const String iflyAppSecret = 'N2IxNzU5YzNhMDI3YjQ2N2Q2MzMxNDAx';
```

---

## ⚠️ 公开仓库前的操作

### 如果要将仓库改为公开，必须执行以下步骤：

#### 步骤 1：修改配置文件
打开 `lib/config/api_config.dart`，将密钥改为从环境变量读取：

```dart
class ApiConfig {
  // AI 标签生成 - DeepSeek
  static const String deepseekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );

  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1/chat/completions';

  // 语音识别 - 科大讯飞
  static const String iflyAppId = String.fromEnvironment(
    'IFLY_APP_ID',
    defaultValue: '',
  );

  static const String iflyAppKey = String.fromEnvironment(
    'IFLY_APP_KEY',
    defaultValue: '',
  );

  static const String iflyAppSecret = String.fromEnvironment(
    'IFLY_APP_SECRET',
    defaultValue: '',
  );

  static bool get isDeepseekConfigured => deepseekApiKey.isNotEmpty;
  static bool get isIflyConfigured => iflyAppId.isNotEmpty && iflyAppKey.isNotEmpty && iflyAppSecret.isNotEmpty;
}
```

#### 步骤 2：在 GitHub Secrets 中配置密钥
1. 进入仓库 Settings → Secrets and variables → Actions
2. 添加以下 Secrets：
   - `DEEPSEEK_API_KEY` = `sk-4c521537a01a44aebc4a2bd9f057dde9`
   - `IFLY_APP_ID` = `000dc3e2`
   - `IFLY_APP_KEY` = `eeb3a079d047433a30fc7d39a2988f50`
   - `IFLY_APP_SECRET` = `N2IxNzU5YzNhMDI3YjQ2N2Q2MzMxNDAx`

#### 步骤 3：修改 GitHub Actions 配置
编辑 `.github/workflows/build-android.yml`，添加 `--dart-define` 参数：

```yaml
- run: flutter build apk --release \
    --dart-define=DEEPSEEK_API_KEY=${{ secrets.DEEPSEEK_API_KEY }} \
    --dart-define=IFLY_APP_ID=${{ secrets.IFLY_APP_ID }} \
    --dart-define=IFLY_APP_KEY=${{ secrets.IFLY_APP_KEY }} \
    --dart-define=IFLY_APP_SECRET=${{ secrets.IFLY_APP_SECRET }}
```

#### 步骤 4：删除本说明文件
- 删除 `KEYS_CONFIG_README.md` 文件
- 或者标记为"已迁移到 Secrets"

---

## 🚀 构建说明

### 本地构建（开发时使用）
```bash
flutter build apk --release
```

### GitHub Actions 自动构建
推送代码后自动构建，无需额外配置。

---

## 📝 密钥用途说明

### DeepSeek API
- **用途**：AI 智能标签生成
- **服务**：根据记录内容自动生成标签
- **计费**：按调用次数计费，个人使用费用很低

### 科大讯飞
- **用途**：语音识别
- **服务**：语音转文字
- **计费**：新用户有免费额度，个人使用费用很低

---

## 🔒 安全提醒

1. **私有仓库期间**：密钥可以保留在代码中
2. **公开仓库之前**：必须移除或加密密钥
3. **不要提交**：不要将包含密钥的文件提交到公开仓库
4. **定期检查**：定期检查密钥是否意外泄露

---

## 📞 问题反馈

如有安全问题或疑问，请联系：
- QQ: 2711793818
- 开发者：杰哥网络科技

---

**最后更新：** 2025 年 4 月  
**仓库状态：** 私有仓库  
**密钥状态：** 已配置在代码中（安全）

---

**开发者：杰哥网络科技**
