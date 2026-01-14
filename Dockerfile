# Dockerfile for Gemini Business API（带注册功能）
# 使用 uv 管理依赖，包含 Chromium + ChromeDriver 支持注册功能
FROM python:3.11-slim

WORKDIR /app

# 安装 Chromium、ChromeDriver 和必要的依赖（使用 Debian 官方源，更稳定）
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv
RUN pip install --no-cache-dir uv

# 复制依赖配置文件
COPY pyproject.toml uv.lock ./

# 使用 uv 同步依赖
RUN uv sync --frozen --no-dev

# 复制项目文件
COPY main.py .
COPY core ./core
COPY util ./util
COPY templates ./templates
COPY static ./static

# 创建数据目录
RUN mkdir -p ./data/images

# 声明数据卷
VOLUME ["/app/data"]

# 设置环境变量（Chromium 路径和 headless 模式）
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver
ENV TZ=Asia/Shanghai

# 启动主服务
CMD ["uv", "run", "python", "-u", "main.py"]
