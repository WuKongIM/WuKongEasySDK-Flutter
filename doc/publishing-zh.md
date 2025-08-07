# 发布指南

本指南提供将 WuKong Easy SDK 发布到 pub.dev 的详细步骤。

## 前置条件

### 1. Pub.dev 账户设置

1. **创建账户**: 访问 [pub.dev](https://pub.dev) 并使用 Google 账户登录
2. **验证邮箱**: 确保您的 Google 账户邮箱已验证
3. **发布者设置**: 可选择为专业包创建已验证的发布者

### 2. 身份验证设置

```bash
# 安装或更新 pub CLI
dart pub global activate pub_api

# 登录到 pub.dev（这将打开浏览器）
dart pub login
```

验证身份验证：
```bash
dart pub token list
```

## 发布前检查清单

### 1. 版本管理

在 `pubspec.yaml` 中更新版本：
```yaml
name: wukong_easy_sdk
description: A lightweight Flutter SDK for WuKongIM that enables real-time chat functionality in 5 minutes.
version: 1.0.0  # 更新此版本
```

### 2. 更新日志

在 `CHANGELOG.md` 中更新新版本：
```markdown
## [1.0.0] - 2024-01-XX

### 新增
- 初始版本功能...

### 变更
- 破坏性变更...

### 修复
- 错误修复...
```

### 3. 文档验证

- [ ] README.md 内容全面且最新
- [ ] README.zh-CN.md 与英文版本匹配
- [ ] API 文档完整
- [ ] 示例应用程序正常工作
- [ ] 文档中的所有代码示例已测试

### 4. 代码质量检查

```bash
# 运行静态分析
flutter analyze

# 运行所有测试
flutter test

# 检查格式
dart format --set-exit-if-changed .

# 验证示例应用
cd example
flutter analyze
flutter test
cd ..
```

### 5. 包验证

```bash
# 验证包结构
dart pub publish --dry-run
```

此命令将：
- 检查包结构
- 验证 pubspec.yaml
- 确认所有必需文件存在
- 检查常见问题

## 发布流程

### 步骤 1: 最终验证

```bash
# 清理并获取依赖
flutter clean
flutter pub get

# 运行全面测试
flutter test --coverage

# 再次验证包
dart pub publish --dry-run
```

### 步骤 2: 创建 Git 标签

```bash
# 确保所有更改已提交
git add .
git commit -m "chore: prepare for v1.0.0 release"

# 创建并推送标签
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

### 步骤 3: 发布到 Pub.dev

```bash
# 发布包
dart pub publish
```

系统将提示您：
1. 查看包内容
2. 确认发布
3. 输入 'y' 继续

### 步骤 4: 验证发布

1. **检查 pub.dev**: 访问 `https://pub.dev/packages/wukong_easy_sdk`
2. **验证版本**: 确保新版本已列出
3. **测试安装**: 在测试项目中尝试安装：

```bash
# 创建测试项目
flutter create test_wukong
cd test_wukong

# 添加依赖
flutter pub add wukong_easy_sdk

# 验证是否工作
flutter pub get
```

## 发布后步骤

### 1. 更新文档

- [ ] 如需要，更新 README 徽章
- [ ] 验证文档在 pub.dev 上正确渲染
- [ ] 更新任何外部文档链接

### 2. 创建 GitHub 发布

1. 转到 GitHub 仓库
2. 点击 "Releases" → "Create a new release"
3. 使用标签 `v1.0.0`
4. 复制更新日志内容作为发布说明
5. 如需要，附加任何额外资源

### 3. 宣布发布

- [ ] 使用最新版本更新项目 README
- [ ] 通知团队/社区关于发布
- [ ] 更新任何依赖项目

## 故障排除

### 常见问题

**1. 身份验证问题**
```bash
# 清除并重新验证
dart pub logout
dart pub login
```

**2. 包验证错误**
- 检查 pubspec.yaml 格式
- 确保所有必需字段存在
- 验证文件结构符合 pub.dev 要求

**3. 版本冲突**
- 确保版本号高于之前版本
- 如需要，检查预发布版本
- 验证语义版本控制合规性

**4. 文档问题**
- 确保 README.md 存在且全面
- 检查所有链接正常工作
- 验证代码示例准确

### 获取帮助

- **Pub.dev 帮助**: https://dart.dev/tools/pub/publishing
- **Flutter 文档**: https://docs.flutter.dev/development/packages-and-plugins/developing-packages
- **社区支持**: https://github.com/WuKongIM/wukong_easy_sdk/discussions

## 安全考虑

### 1. 敏感信息

- [ ] 代码中无 API 密钥或机密
- [ ] 示例中无个人信息
- [ ] 敏感文件有适当的 .gitignore

### 2. 依赖项

- [ ] 所有依赖项来自可信来源
- [ ] 无已知安全漏洞
- [ ] 计划定期依赖项更新

### 3. 代码审查

- [ ] 所有代码已审查
- [ ] 无恶意或可疑代码
- [ ] 实现了适当的错误处理

## 回滚程序

如果发布后发现问题：

1. **立即响应**:
   ```bash
   # 撤回有问题的版本（7天内）
   dart pub retract <version>
   ```

2. **修复并重新发布**:
   - 在代码中修复问题
   - 增加版本号
   - 再次遵循发布流程

3. **沟通**:
   - 在更新日志中更新修复详情
   - 通过 GitHub issues/discussions 通知用户
   - 如需要，更新文档

## 自动化（未来增强）

考虑设置 GitHub Actions 进行自动发布：

```yaml
# .github/workflows/publish.yml
name: Publish to pub.dev
on:
  push:
    tags:
      - 'v*'
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart pub publish --force
        env:
          PUB_TOKEN: ${{ secrets.PUB_TOKEN }}
```

这使得在标签推送到仓库时能够自动发布。
