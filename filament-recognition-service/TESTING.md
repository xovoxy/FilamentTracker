# 测试指南

## 准备工作

1. **安装依赖**
```bash
pip install -r requirements.txt
```

2. **配置环境变量**
创建 `.env` 文件（参考 `.env.example`）：
```bash
DASHSCOPE_API_KEY=your_api_key_here
```

3. **启动服务**
```bash
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

## 测试方法

### 1. 使用测试脚本

```bash
python test_api.py <image_path>
```

示例：
```bash
python test_api.py test_image.jpg
```

### 2. 使用 curl

```bash
curl -X POST "http://localhost:8000/api/v1/recognize" \
  -F "image=@test_image.jpg"
```

### 3. 使用 Python requests

```python
import requests

with open('test_image.jpg', 'rb') as f:
    files = {'image': f}
    response = requests.post(
        'http://localhost:8000/api/v1/recognize',
        files=files
    )
    print(response.json())
```

### 4. 使用 Swagger UI

启动服务后，访问：http://localhost:8000/docs

在 Swagger UI 中可以：
- 查看所有API端点
- 直接测试API
- 上传图片进行识别

## 预期响应格式

### 成功响应
```json
{
  "success": true,
  "data": {
    "brand": "Bambu Lab",
    "material": "PLA",
    "colorName": "Matte Charcoal",
    "colorHex": "#333333",
    "weight": "1000",
    "diameter": 1.75
  },
  "confidence": 0.85
}
```

### 错误响应
```json
{
  "success": false,
  "error": "错误信息"
}
```

## 常见问题

1. **API密钥错误**
   - 确保 `.env` 文件中的 `DASHSCOPE_API_KEY` 正确
   - 检查API密钥是否有效

2. **图像格式不支持**
   - 支持格式：JPEG, JPG, PNG
   - 最大文件大小：10MB（可在配置中修改）

3. **识别失败**
   - 确保图片清晰，标签信息可见
   - 检查网络连接
   - 查看服务日志获取详细错误信息

## 性能测试

使用 `ab` (Apache Bench) 进行压力测试：

```bash
# 需要先准备一个测试图片文件
ab -n 10 -c 2 -p test_image.jpg -T "multipart/form-data" \
   http://localhost:8000/api/v1/recognize
```

注意：由于使用AI模型，响应时间可能较长（通常5-15秒），不适合高并发场景。
