# iOS 集成指南

## 概述

本指南说明如何将Python图像识别服务集成到iOS应用中。

## 文件说明

- `MockImageRecognizer.swift`: 原有的模拟实现（用于开发和测试）
- `ImageRecognizer.swift`: 新的真实API实现（调用Python服务）

## 集成步骤

### 1. 将 ImageRecognizer.swift 添加到 Xcode 项目

1. 在 Xcode 中，右键点击 `Services` 文件夹
2. 选择 "Add Files to FilamentTracker..."
3. 选择 `ImageRecognizer.swift` 文件
4. 确保 "Copy items if needed" 已勾选
5. 点击 "Add"

### 2. 配置 API 端点

编辑 `ImageRecognizer.swift`，修改 `apiBaseURL`：

```swift
private let apiBaseURL: String = {
    #if DEBUG
    // 开发环境：使用本地服务器
    // 注意：iOS模拟器使用 localhost，真机需要使用电脑的IP地址
    return "http://192.168.1.100:8000"  // 替换为你的电脑IP
    #else
    // 生产环境：使用服务器URL
    return "https://your-api-server.com"
    #endif
}()
```

**重要提示：**
- iOS模拟器可以使用 `http://localhost:8000`
- 真机设备必须使用电脑的局域网IP地址（如 `http://192.168.1.100:8000`）
- 生产环境必须使用HTTPS

### 3. 切换到真实API

在 `AddMaterialView.swift` 中，将：

```swift
let recognizedData = try await MockImageRecognizer.shared.analyze(image)
```

替换为：

```swift
let recognizedData = try await ImageRecognizer.shared.analyze(image)
```

### 4. 配置网络权限（Info.plist）

如果使用HTTP（非HTTPS），需要在 `Info.plist` 中添加：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <!-- 或者只允许特定域名 -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**注意：** 生产环境应使用HTTPS，不需要此配置。

### 5. 错误处理

`ImageRecognizer` 会抛出 `ImageRecognizerError`，你可以在 `AddMaterialView.swift` 中增强错误处理：

```swift
private func analyzeImage(_ image: UIImage) {
    isAnalyzing = true
    
    Task {
        do {
            let recognizedData = try await ImageRecognizer.shared.analyze(image)
            
            await MainActor.run {
                withAnimation {
                    // ... 填充表单字段
                    isAnalyzing = false
                }
            }
        } catch let error as ImageRecognizerError {
            await MainActor.run {
                isAnalyzing = false
                // 显示错误提示
                print("Recognition error: \(error.localizedDescription)")
                // 可以在这里添加用户友好的错误提示
            }
        } catch {
            await MainActor.run {
                isAnalyzing = false
                print("Unknown error: \(error)")
            }
        }
    }
}
```

## 测试

### 本地测试

1. 启动Python服务：
```bash
cd filament-recognition-service
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

2. 确保iOS应用中的API URL正确配置

3. 在iOS应用中测试图像识别功能

### 获取电脑IP地址

**macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows:**
```cmd
ipconfig
```

查找 `192.168.x.x` 或 `10.x.x.x` 格式的IP地址。

## 可选：保留Mock实现作为后备

如果你想在API不可用时自动切换到Mock实现，可以创建一个包装类：

```swift
class AdaptiveImageRecognizer {
    static let shared = AdaptiveImageRecognizer()
    
    private init() {}
    
    func analyze(_ image: UIImage) async throws -> RecognizedFilamentData {
        do {
            // 尝试使用真实API
            return try await ImageRecognizer.shared.analyze(image)
        } catch {
            // API失败时使用Mock实现
            print("API failed, using mock: \(error)")
            return try await MockImageRecognizer.shared.analyze(image)
        }
    }
}
```

然后在 `AddMaterialView.swift` 中使用：

```swift
let recognizedData = try await AdaptiveImageRecognizer.shared.analyze(image)
```

## 生产部署注意事项

1. **使用HTTPS**: 生产环境必须使用HTTPS，确保数据传输安全
2. **API密钥安全**: 不要在iOS应用中硬编码API密钥
3. **错误处理**: 实现完善的错误处理和用户提示
4. **超时设置**: 根据网络情况调整超时时间
5. **图片压缩**: 考虑在上传前压缩图片以减少传输时间
6. **缓存**: 可以考虑缓存识别结果，避免重复识别相同图片

## 故障排除

### 问题：连接被拒绝

**解决方案：**
- 检查Python服务是否正在运行
- 检查防火墙设置
- 确认IP地址和端口正确
- 确保iOS设备和服务器在同一网络

### 问题：超时

**解决方案：**
- 增加超时时间（在 `ImageRecognizer.swift` 中）
- 检查网络连接
- 考虑压缩图片大小

### 问题：CORS错误

**解决方案：**
- 检查Python服务的CORS配置
- 确保允许iOS应用的来源

## 性能优化建议

1. **图片压缩**: 在上传前压缩图片（已在代码中实现，quality=0.8）
2. **异步处理**: 使用async/await避免阻塞UI
3. **进度指示**: 显示加载状态（已在AddMaterialView中实现）
4. **错误重试**: 实现自动重试机制（可选）
