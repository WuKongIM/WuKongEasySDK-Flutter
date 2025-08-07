# 包维护指南

本指南涵盖 WuKong Easy SDK 的持续维护程序，包括依赖管理、兼容性更新和社区贡献处理。

## 依赖管理

### 定期依赖更新

**月度依赖审查**
```bash
# 检查过时的依赖项
flutter pub outdated

# 更新依赖项
flutter pub upgrade

# 更新后测试
flutter test
flutter analyze
```

**依赖更新流程**
1. **审查变更**: 检查更新日志中的破坏性变更
2. **更新约束**: 如需要修改 `pubspec.yaml`
3. **彻底测试**: 运行完整测试套件
4. **更新文档**: 如果 API 变更影响使用
5. **创建 PR**: 提交变更进行审查

**关键依赖更新**
```bash
# 对于安全更新，立即优先处理
flutter pub upgrade --major-versions

# 广泛测试
flutter test --coverage
cd example && flutter test && cd ..

# 更新锁定文件
flutter pub deps
```

### 依赖兼容性矩阵

| 依赖项 | 当前版本 | 最小版本 | 最大版本 | 说明 |
|--------|----------|----------|----------|------|
| `web_socket_channel` | ^3.0.0 | 3.0.0 | <4.0.0 | 核心 WebSocket |
| `uuid` | ^4.0.0 | 4.0.0 | <5.0.0 | 消息 ID |
| Flutter SDK | >=3.0.0 | 3.0.0 | <4.0.0 | 框架 |
| Dart SDK | >=3.0.0 | 3.0.0 | <4.0.0 | 语言 |

### 依赖安全

**安全扫描**
```bash
# 检查已知漏洞
dart pub audit

# 审查安全公告
# 立即更新有漏洞的包
```

**安全更新协议**
1. **立即评估**: 评估漏洞影响
2. **紧急更新**: 更新受影响的依赖项
3. **测试**: 验证功能保持完整
4. **发布**: 立即发布补丁版本
5. **沟通**: 通知用户安全更新

## Flutter/Dart 版本兼容性

### 版本支持策略

**支持的版本**
- **Flutter**: 最新稳定版 + 前一个稳定版
- **Dart**: 支持的 Flutter 版本包含的版本
- **最小支持**: 新稳定版发布后 6 个月

**兼容性测试矩阵**

| Flutter 版本 | Dart 版本 | 支持状态 | 测试频率 |
|-------------|-----------|----------|----------|
| 3.16.x | 3.2.x | ✅ 活跃 | 每周 |
| 3.13.x | 3.1.x | ✅ 活跃 | 每月 |
| 3.10.x | 3.0.x | ⚠️ 传统 | 每季度 |
| <3.10.x | <3.0.x | ❌ 不支持 | 无 |

### 版本更新流程

**Flutter SDK 更新**
```bash
# 更新 Flutter
flutter upgrade

# 检查兼容性
flutter doctor

# 使用新版本测试
flutter clean
flutter pub get
flutter test
flutter analyze

# 测试示例应用
cd example
flutter clean
flutter pub get
flutter run
cd ..
```

**破坏性变更处理**
1. **早期测试**: 使用 beta/dev 渠道测试
2. **影响评估**: 识别破坏性变更
3. **代码更新**: 修改代码以兼容
4. **文档**: 更新迁移指南
5. **版本升级**: 如需要增加主版本号

### 兼容性测试

**自动化测试设置**
```yaml
# .github/workflows/compatibility.yml
name: Compatibility Testing
on:
  schedule:
    - cron: '0 0 * * 1'  # 每周一
  workflow_dispatch:

jobs:
  test-flutter-versions:
    strategy:
      matrix:
        flutter-version: ['3.16.x', '3.13.x', '3.10.x']
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ matrix.flutter-version }}
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze
```

## 破坏性变更管理

### 破坏性变更策略

**何时引入破坏性变更**
- 需要 API 变更的安全漏洞
- 需要结构变更的性能改进
- 具有破坏性变更的依赖项更新
- 为更好开发者体验的 API 简化

**破坏性变更流程**
1. **RFC（征求意见）**: 在 GitHub Discussions 中提议变更
2. **社区反馈**: 收集用户输入
3. **实施**: 在功能分支中开发变更
4. **迁移指南**: 创建详细的迁移文档
5. **弃用期**: 将旧 API 标记为弃用（最少 3 个月）
6. **主版本发布**: 发布破坏性变更

### 弃用工作流

**将 API 标记为弃用**
```dart
@Deprecated('使用 newMethod() 代替。将在 v2.0.0 中移除')
void oldMethod() {
  // 实现
}

/// [oldMethod] 的替代方法。
/// 
/// 迁移示例：
/// ```dart
/// // 旧方式
/// oldMethod();
/// 
/// // 新方式
/// newMethod();
/// ```
void newMethod() {
  // 新实现
}
```

**弃用时间表**
- **公告**: GitHub issue + 更新日志条目
- **弃用**: 使用 @Deprecated 注释标记 API
- **警告期**: 3-6 个月的警告期
- **移除**: 下一个主版本发布

### 迁移指南模板

```markdown
# 迁移指南：v1.x 到 v2.0

## 破坏性变更

### 1. 连接 API 变更

**旧 API：**
```dart
await sdk.connect(url, token);
```

**新 API：**
```dart
final config = WuKongConfig(serverUrl: url, token: token);
await sdk.init(config);
await sdk.connect();
```

**迁移步骤：**
1. 将直接连接调用替换为 init + connect
2. 更新配置参数
3. 测试连接功能

### 2. 事件监听器变更

**旧 API：**
```dart
sdk.onMessage = (message) => print(message);
```

**新 API：**
```dart
sdk.addEventListener(WuKongEvent.message, (message) => print(message));
```

**迁移步骤：**
1. 将回调属性替换为 addEventListener 调用
2. 存储监听器引用以便清理
3. 更新事件处理逻辑
```

## 社区贡献管理

### 贡献审查流程

**拉取请求审查检查清单**
- [ ] 代码遵循项目样式指南
- [ ] 包含测试且通过
- [ ] 文档已更新
- [ ] 破坏性变更已记录
- [ ] 更新日志已更新
- [ ] 如需要，示例应用已更新

**审查时间表**
- **初始响应**: 48 小时内
- **完整审查**: 1 周内
- **反馈响应**: 3 天内
- **最终决定**: 2 周内

### 问题管理

**问题分类流程**
1. **标记**: 应用适当标签（bug、feature、question）
2. **优先级**: 分配优先级（critical、high、medium、low）
3. **分配**: 分配给适当的维护者
4. **响应**: 48 小时内提供初始响应

**问题标签**
- `bug`: 某些功能不工作
- `enhancement`: 新功能或请求
- `documentation`: 文档改进或添加
- `good first issue`: 适合新手
- `help wanted`: 需要额外关注
- `question`: 需要进一步信息
- `wontfix`: 不会处理

### 社区指南

**行为准则执行**
- 需要尊重的沟通
- 鼓励建设性反馈
- 零容忍骚扰
- 明确的升级程序

**贡献者认可**
- 贡献者列在 CONTRIBUTORS.md 中
- 对重大贡献的特别认可
- 年度贡献者感谢

## 性能监控

### 性能基准

**连接性能**
```dart
// 基准连接时间
final stopwatch = Stopwatch()..start();
await sdk.connect();
stopwatch.stop();
print('连接时间: ${stopwatch.elapsedMilliseconds}ms');
// 目标: < 2000ms
```

**消息吞吐量**
```dart
// 基准消息发送
final messages = 100;
final stopwatch = Stopwatch()..start();
for (int i = 0; i < messages; i++) {
  await sdk.send(channelId: 'test', payload: {'index': i});
}
stopwatch.stop();
print('消息/秒: ${messages / (stopwatch.elapsedMilliseconds / 1000)}');
// 目标: > 50 消息/秒
```

**内存使用监控**
```bash
# 测试期间监控内存使用
flutter run --profile
# 使用 DevTools 监控内存
```

### 性能回归测试

**自动化性能测试**
```yaml
# .github/workflows/performance.yml
name: Performance Tests
on:
  pull_request:
    branches: [main]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test test/performance/
      - name: Check performance regression
        run: |
          # 与基线指标比较
          # 如果性能下降 > 10% 则失败
```

## 文档维护

### 文档审查计划

**月度审查**
- [ ] API 文档准确性
- [ ] 代码示例功能
- [ ] 链接有效性
- [ ] 截图更新

**季度审查**
- [ ] 完整文档检修
- [ ] 用户反馈集成
- [ ] 可访问性改进
- [ ] 翻译更新

### 文档自动化

**自动化文档生成**
```bash
# 生成 API 文档
dart doc

# 验证文档
dart doc --validate-links

# 更新文档站点
# 部署到 GitHub Pages 或类似服务
```

**文档测试**
```bash
# 测试文档中的所有代码示例
dart test test/documentation/
```

## 监控和分析

### 包分析

**要监控的关键指标**
- pub.dev 的下载统计
- GitHub 仓库星标/分叉
- 问题解决时间
- 社区参与度

**月度报告**
- 包采用趋势
- 常见问题和解决方案
- 社区反馈摘要
- 性能指标

### 健康监控

**包健康指标**
- 测试覆盖率百分比
- 静态分析分数
- 依赖项新鲜度
- 文档完整性
- 社区活动水平

**自动化健康检查**
```bash
# 每周健康检查脚本
#!/bin/bash
echo "运行包健康检查..."

# 测试覆盖率
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 静态分析
flutter analyze

# 依赖项检查
flutter pub outdated

# 文档检查
dart doc --validate-links

echo "健康检查完成！"
```

## 长期维护策略

### 路线图规划

**年度规划流程**
1. **社区调查**: 收集用户反馈和功能请求
2. **技术评估**: 评估新的 Flutter/Dart 功能
3. **竞争分析**: 审查类似包和行业趋势
4. **资源规划**: 分配开发资源
5. **路线图发布**: 与社区分享计划

**路线图类别**
- **核心功能**: 基本功能改进
- **开发者体验**: API 改进和工具
- **性能**: 优化和效率提升
- **平台支持**: 新平台兼容性
- **生态系统集成**: 第三方服务集成

### 继任规划

**维护者入职**
- 维护程序的全面文档
- 逐步责任转移
- 知识分享会议
- 访问所有必要账户和工具

**总线因子缓解**
- 多个维护者具有完全访问权限
- 所有关键任务的记录程序
- 定期知识转移会议
- 紧急联系程序

### 生命周期结束规划

**包生命周期阶段**
1. **活跃开发**: 定期更新和新功能
2. **维护模式**: 仅错误修复和安全更新
3. **传统支持**: 仅关键安全修复
4. **生命周期结束**: 不再更新

**生命周期结束流程**
1. **6个月通知**: 宣布生命周期结束时间表
2. **迁移指南**: 提供替代方案和迁移路径
3. **最终发布**: 最后稳定版本，带有清晰文档
4. **存档**: 将仓库标记为已存档
5. **重定向**: 更新文档指向替代方案
