# Filament Recognition Service

基于 dashscope qwen3-vl-plus 模型的3D打印耗材标签图像识别服务。

## 功能特性

- 使用 qwen3-vl-plus 视觉语言模型识别耗材标签
- 提取品牌、材料类型、颜色、重量、直径等信息
- RESTful API 接口，支持图像上传
- 结构化JSON响应，便于iOS应用集成

## 安装

1. 安装Python依赖：
```bash
pip install -r requirements.txt
```

2. 配置环境变量：
```bash
cp .env.example .env
# 编辑 .env 文件，填入你的 DASHSCOPE_API_KEY
```

## 运行

### 开发环境
```bash
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

### 生产环境
```bash
gunicorn app:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## API 文档

启动服务后，访问以下地址查看自动生成的API文档：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API 接口

### POST /api/v1/recognize

识别耗材标签图像。

**请求：**
- Content-Type: `multipart/form-data`
- 参数: `image` (文件，支持 JPEG, PNG)

**响应：**
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

**错误响应：**
```json
{
  "success": false,
  "error": "错误信息"
}
```

## 环境变量说明

- `DASHSCOPE_API_KEY`: Dashscope API密钥（必需）
- `HOST`: 服务器监听地址（默认: 0.0.0.0）
- `PORT`: 服务器端口（默认: 8000）
- `CORS_ORIGINS`: 允许的CORS来源（默认: *）
- `MODEL_NAME`: 使用的模型名称（默认: qwen-vl-plus）
- `MAX_TOKENS`: 最大token数（默认: 2000）
- `TEMPERATURE`: 模型温度参数（默认: 0.1）
- `MAX_IMAGE_SIZE_MB`: 最大图像大小MB（默认: 10）
- `ALLOWED_IMAGE_TYPES`: 允许的图像类型（默认: jpeg,jpg,png）

## iOS 集成

在iOS应用中，将 `MockImageRecognizer.swift` 替换为调用此API的实现：

1. 将 UIImage 转换为 JPEG/PNG 数据
2. 使用 multipart/form-data 格式上传到 `/api/v1/recognize`
3. 解析返回的JSON并填充表单字段

## 部署

### 使用 Docker（推荐）

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 使用 Nginx 反向代理

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 许可证

MIT
