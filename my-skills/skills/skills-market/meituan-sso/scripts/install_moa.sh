#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 开始环境配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ===== 步骤 1：添加 /etc/hosts 规则 =====
echo ""
echo "📌 步骤 1：配置 /etc/hosts..."

# 备份
cp /etc/hosts /etc/hosts.bak
echo "✅ 已备份 /etc/hosts -> /etc/hosts.bak"

# 添加规则（避免重复添加）
add_host() {
    local rule="$1"
    if grep -qF "$rule" /etc/hosts; then
        echo "⚠️  已存在，跳过: $rule"
    else
        echo "$rule" >> /etc/hosts
        echo "✅ 已添加: $rule"
    fi
}

add_host "103.63.160.9    msp.meituan.net"
add_host "127.0.0.1       localhost.moa.sankuai.com"
add_host "103.63.160.9    msp.meituan.com"
add_host "103.63.160.9    www.dpfile.com"

echo "当前 /etc/hosts 内容："
cat /etc/hosts

# ===== 步骤 2：配置 Chromium supervisor =====
echo ""
echo "📌 步骤 2：配置 Chromium supervisor..."

SUPERVISOR_CONF="/etc/supervisor/supervisord.conf"

if [ ! -f "$SUPERVISOR_CONF" ]; then
    echo "❌ supervisor 配置文件不存在: $SUPERVISOR_CONF"
    exit 1
fi

# 备份 supervisor 配置
cp "$SUPERVISOR_CONF" "${SUPERVISOR_CONF}.bak"
echo "✅ 已备份 supervisor 配置"

# 检查是否已有 chromium 配置
if grep -q "program:chromium" "$SUPERVISOR_CONF"; then
    echo "⚠️  已存在 chromium 配置，更新参数..."
    # 更新 proxy-bypass-list 参数
    sed -i 's|--proxy-bypass-list=[^"]*|--proxy-bypass-list=localhost.moa.sankuai.com|g' "$SUPERVISOR_CONF"
    echo "更新 proxy-bypass-list 参数"
    # 如果没有该参数则追加
    if ! grep -q "proxy-bypass-list" "$SUPERVISOR_CONF"; then
        sed -i '/--remote-debugging-port=9222/ s|$| --proxy-bypass-list=localhost.moa.sankuai.com|' "$SUPERVISOR_CONF"
        echo "追加 proxy-bypass-list 参数"
    fi
else
    echo "supervisor不存在chromium配置"
    exit 1
fi

# 重新加载 supervisor 配置并重启 chromium
echo "重新加载 supervisor 配置..."
supervisorctl reread
supervisorctl update
supervisorctl restart chromium
echo "✅ Chromium 已重启"

# ===== 步骤 3：安装 MOA =====
echo ""
echo "📌 步骤 3：安装 MOA..."

# 下载 MOA
echo "下载 MOA..."
wget --no-proxy \
  https://msstest.sankuai.com/octo-test/MOA_for_linux_1.0.8_install.deb \
  -O /tmp/MOA_for_linux_1.0.8_install.deb

if [ $? -ne 0 ]; then
    echo "❌ MOA 下载失败"
    exit 1
fi
echo "✅ MOA 下载成功"

# 安装依赖
echo "安装依赖..."
apt-get update -y
apt-get install -f libnss3-tools -y

# 设置权限
chmod 644 /tmp/MOA_for_linux_1.0.8_install.deb

# 设置machine_id
python3 -c "import uuid; print(uuid.uuid4().hex)" > /etc/machine-id

# 同步 machine-id 到 dbus
mkdir -p /var/lib/dbus
cp /etc/machine-id /var/lib/dbus/machine-id

# 设置运行时目录
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)
mkdir -p $XDG_RUNTIME_DIR
echo "✅ XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

# 创建 MOA 目录
mkdir -p /home/.local/share/MOA
mkdir -p /root/.local/share/MOA
echo "✅ MOA 目录创建完成"

# 安装 MOA
echo "安装 MOA..."
apt-get install -y /tmp/MOA_for_linux_1.0.8_install.deb

if [ $? -eq 0 ]; then
    echo "✅ MOA 安装成功"
else
    echo "❌ MOA 安装失败"
    exit 1
fi

# ===== 步骤 4：清除代理环境变量 =====
echo ""
echo "📌 步骤 4：清除代理环境变量..."

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
echo "✅ 代理环境变量已清除"

# ===== 步骤 5：后台守护进程启动 MOA =====
echo ""
echo "📌 步骤 5：配置 MOA 守护进程..."

# 添加 MOA 到 supervisor
if grep -q "program:moa" "$SUPERVISOR_CONF"; then
    echo "⚠️  MOA supervisor 配置已存在，跳过"
else
    cat >> "$SUPERVISOR_CONF" << MOAEOF

[program:moa]
command=/opt/moa/moatray --no-sandbox
autostart=true
autorestart=true
startsecs=5
startretries=999
stderr_logfile=/var/log/supervisor/moa.err
stdout_logfile=/var/log/supervisor/moa.log
environment=XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
MOAEOF
    echo "✅ MOA supervisor 配置已添加"
fi

# 重新加载 supervisor 并启动 MOA
supervisorctl reread
supervisorctl update
supervisorctl start moa
