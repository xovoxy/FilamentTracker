# iOS 图像识别服务集成完成

## ✅ 已完成的集成

### 1. 代码修改

- ✅ **AddMaterialView.swift**: 已更新为使用 `ImageRecognizer` 替代 `MockImageRecognizer`
- ✅ **ImageRecognizer.swift**: 已创建真实API调用实现
- ✅ **错误处理**: 已添加用户友好的错误提示

### 2. 文件位置

- `FilamentTracker/Services/ImageRecognizer.swift` - 真实API识别器
- `FilamentTracker/Services/MockImageRecognizer.swift` - 保留作为备用

## 📋 使用前准备

### 1. 配置API端点

编辑 `FilamentTracker/Services/ImageRecognizer.swift`，修改 `apiBaseURL`：

```swift
private let apiBaseURL: String = {
    #if DEBUG
    // 开发环境：iOS模拟器使用 localhost，真机需要使用电脑IP
    return "http://localhost:8000"  // 或 "http://192.168.1.100:8000"
    #else
    // 生产环境：使用HTTPS服务器
    return "https://your-api-server.com"
    #endif
}()
```

**重要提示：**
- iOS模拟器可以使用 `http://localhost:8000`
- 真机设备必须使用电脑的局域网IP地址（如 `http://192.168.1.100:8000`）
- 生产环境必须使用HTTPS

### 2. 启动Python服务

```bash
cd filament-recognition-service
pip install -r requirements.txt

# 创建.env文件并配置API密钥
cp env.example .env
# 编辑.env文件，填入 DASHSCOPE_API_KEY

# 启动服务
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

### 3. 配置网络权限（仅开发环境需要）

如果使用HTTP（非HTTPS），需要在Xcode中添加网络权限：

1. 在Xcode中打开项目
2. 选择项目 Target → Build Settings
3. 搜索 "Info.plist"
4. 找到 "Info.plist Values" 或直接编辑 Info.plist
5. 添加以下配置：

**方法1：通过Xcode界面**
- 选择 Target → Info
- 添加 "App Transport Security Settings" (Dictionary)
- 添加 "Allow Arbitrary Loads" (Boolean) = YES
- 或者添加 "Exception Domains" (Dictionary) → "localhost" (Dictionary) → "NSExceptionAllowsInsecureHTTPLoads" (Boolean) = YES

**方法2：直接编辑Info.plist（如果存在）**
在 `Info.plist` 中添加：
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

## 🧪 测试

1. 启动Python服务（确保在运行）
2. 在iOS应用中打开"添加材料"页面
3. 点击"自动填充"按钮
4. 选择或拍摄耗材标签图片
5. 等待识别结果填充表单

## 🔧 故障排除

### 问题：连接被拒绝

**解决方案：**
- 检查Python服务是否正在运行
- 确认API URL配置正确
- 真机测试时，确保使用电脑的IP地址而不是localhost
- 确保iOS设备和服务器在同一网络

### 问题：网络错误

**解决方案：**
- 检查网络连接
- 确认防火墙没有阻止连接
- 检查Info.plist中的网络权限配置

### 问题：识别失败

**解决方案：**
- 确保图片清晰，标签信息可见
- 检查Python服务日志查看详细错误
- 确认DASHSCOPE_API_KEY配置正确

## 📱 功能说明

### 自动填充字段

识别服务会自动填充以下字段：
- **品牌** (brand)
- **材料类型** (material)
- **颜色名称** (colorName)
- **颜色代码** (colorHex)
- **重量** (weight) - 自动转换为kg
- **直径** (diameter)

### 错误提示

如果识别失败，会显示错误提示，用户可以：
- 查看错误信息
- 手动填写表单
- 重试识别

## 🚀 生产部署

1. **使用HTTPS**: 生产环境必须使用HTTPS服务器
2. **更新API URL**: 在 `ImageRecognizer.swift` 中设置生产服务器URL
3. **移除HTTP权限**: 删除Info.plist中的NSAllowsArbitraryLoads配置
4. **测试验证**: 确保生产环境API正常工作

## 📝 代码变更总结

### AddMaterialView.swift
- 添加了错误状态变量 (`showErrorAlert`, `errorMessage`)
- 修改 `analyzeImage` 方法使用 `ImageRecognizer` 替代 `MockImageRecognizer`
- 添加了错误处理和用户提示

### ImageRecognizer.swift (新建)
- 实现了真实的HTTP API调用
- 支持multipart/form-data图像上传
- 完善的错误处理
- 支持开发和生产环境配置

## ✨ 下一步

1. 在Xcode中添加 `ImageRecognizer.swift` 到项目（如果还没有）
2. 配置API端点URL
3. 启动Python服务
4. 测试图像识别功能
5. 根据需要调整错误处理和用户体验
