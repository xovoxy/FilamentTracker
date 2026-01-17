# Docker 部署指南

## 快速开始

### 1. 构建镜像

```bash
docker build -t filament-recognition:latest .
```

### 2. 运行容器

#### 方式1：使用docker run

```bash
docker run -d \
  --name filament-recognition \
  -p 8000:8000 \
  -e DASHSCOPE_API_KEY=your_api_key_here \
  filament-recognition:latest
```

#### 方式2：使用docker-compose（推荐）

1. 创建 `.env` 文件：
```bash
cp env.example .env
# 编辑 .env 文件，填入 DASHSCOPE_API_KEY
```

2. 启动服务：
```bash
docker-compose up -d
```

3. 查看日志：
```bash
docker-compose logs -f
```

4. 停止服务：
```bash
docker-compose down
```

## 环境变量配置

可以通过环境变量或 `.env` 文件配置服务：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| DASHSCOPE_API_KEY | - | Dashscope API密钥（必需） |
| HOST | 0.0.0.0 | 监听地址 |
| PORT | 8000 | 监听端口 |
| CORS_ORIGINS | * | CORS允许的来源 |
| MODEL_NAME | qwen-vl-plus | 使用的模型名称 |
| MAX_TOKENS | 2000 | 最大token数 |
| TEMPERATURE | 0.1 | 模型温度参数 |
| MAX_IMAGE_SIZE_MB | 10 | 最大图像大小（MB） |
| ALLOWED_IMAGE_TYPES | jpeg,jpg,png | 允许的图像类型 |

## 生产环境部署

### 1. 使用环境变量文件

```bash
docker run -d \
  --name filament-recognition \
  -p 8000:8000 \
  --env-file .env \
  filament-recognition:latest
```

### 2. 使用docker-compose（推荐）

```bash
# 编辑 docker-compose.yml 中的环境变量
# 然后运行
docker-compose up -d
```

### 3. 使用Nginx反向代理

创建 `nginx.conf`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 增加超时时间（AI识别可能需要较长时间）
        proxy_read_timeout 120s;
        proxy_connect_timeout 120s;
        proxy_send_timeout 120s;
    }
}
```

### 4. 使用HTTPS（Let's Encrypt）

```bash
# 使用certbot获取SSL证书
certbot --nginx -d your-domain.com

# 或使用docker-compose添加nginx和certbot
```

## 常用命令

### 查看日志

```bash
# docker run方式
docker logs -f filament-recognition

# docker-compose方式
docker-compose logs -f
```

### 进入容器

```bash
docker exec -it filament-recognition /bin/bash
```

### 重启服务

```bash
# docker run方式
docker restart filament-recognition

# docker-compose方式
docker-compose restart
```

### 停止服务

```bash
# docker run方式
docker stop filament-recognition
docker rm filament-recognition

# docker-compose方式
docker-compose down
```

### 更新镜像

```bash
# 重新构建
docker build -t filament-recognition:latest .

# 停止旧容器
docker-compose down

# 启动新容器
docker-compose up -d
```

## 健康检查

容器包含健康检查，可以通过以下方式查看：

```bash
docker ps
# 查看STATUS列，应该显示 "healthy"
```

手动检查：

```bash
curl http://localhost:8000/health
```

## 故障排除

### 问题：容器无法启动

**检查日志：**
```bash
docker logs filament-recognition
```

**常见原因：**
- DASHSCOPE_API_KEY未设置或无效
- 端口被占用
- 镜像构建失败

### 问题：API调用失败

**检查：**
1. 容器是否运行：`docker ps`
2. 端口是否正确映射：`docker port filament-recognition`
3. 日志是否有错误：`docker logs filament-recognition`

### 问题：识别速度慢

**优化建议：**
- 增加容器资源限制（CPU/内存）
- 使用GPU加速（需要nvidia-docker）
- 优化图像大小

## 多环境部署

### 开发环境

```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### 生产环境

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 安全建议

1. **不要将API密钥提交到代码仓库**
2. **使用环境变量或密钥管理服务**
3. **生产环境使用HTTPS**
4. **限制CORS来源**
5. **定期更新基础镜像**

## 性能优化

### 使用多阶段构建（可选）

如果需要更小的镜像，可以使用多阶段构建：

```dockerfile
# 构建阶段
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# 运行阶段
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
# ... 其余配置
```

### 资源限制

在 `docker-compose.yml` 中添加：

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      memory: 1G
```

## 监控和日志

### 日志管理

```bash
# 限制日志大小
docker run --log-opt max-size=10m --log-opt max-file=3 ...
```

### 使用监控工具

- Prometheus + Grafana
- ELK Stack
- Datadog
