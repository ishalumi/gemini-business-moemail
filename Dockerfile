# Dockerfile for Gemini Business API（带注册功能）
# 使用 uv 管理依赖，包含 Chromium + ChromeDriver 支持注册功能
FROM python:3.11-slim

WORKDIR /app

# 安装 Chromium、ChromeDriver、Xvfb、tini 和必要的依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver \
    xvfb \
    tini \
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

# 复制启动脚本（转换 CRLF 为 LF，避免 Linux 容器报错）
COPY start.sh /app/start.sh
RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/start.sh

# 设置环境变量（Chromium 路径和 Xvfb 显示）
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver
ENV DISPLAY=:99
ENV TZ=Asia/Shanghai

# 使用 tini 作为 PID 1，负责信号转发与僵尸进程回收
ENTRYPOINT ["tini", "--"]

# 启动主服务（通过 start.sh 启动 Xvfb + 应用）
CMD ["/app/start.sh"]
