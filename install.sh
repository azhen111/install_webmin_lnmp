#!/bin/bash
set -e

echo "👉 开始安装指定版本 LNMP + Webmin 面板"

echo "👉 更新系统"
apt update && apt upgrade -y

echo "👉 安装基础依赖"
apt install -y curl gnupg2 ca-certificates lsb-release software-properties-common

# ----------------------------
# 安装 Nginx 1.18.0
# ----------------------------
echo "👉 安装 Nginx 1.18.0"
add-apt-repository -y ppa:ondrej/nginx
apt update
apt install -y nginx=1.18.0-0ubuntu1

# ----------------------------
# 安装 MySQL 5.7
# ----------------------------
echo "👉 安装 MySQL 5.7"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.24-1_all.deb <<< $'1\n'
apt update
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server
mysql --version

# ----------------------------
# 安装 PHP 7.4 + 常用扩展
# ----------------------------
echo "👉 安装 PHP 7.4"
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php7.4 php7.4-fpm php7.4-cli php7.4-mysql php7.4-curl php7.4-zip php7.4-mbstring php7.4-xml php7.4-gd php7.4-bcmath

# ----------------------------
# 安装 Redis 6.2.7
# ----------------------------
echo "👉 安装 Redis 6.2.7"
cd /usr/local/src
wget http://download.redis.io/releases/redis-6.2.7.tar.gz
tar xzf redis-6.2.7.tar.gz
cd redis-6.2.7
make && make install
echo "Redis 安装完成"
redis-server --version

# ----------------------------
# 安装 phpMyAdmin 5.2
# ----------------------------
echo "👉 安装 phpMyAdmin 5.2"
cd /var/www/html
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.tar.gz
tar xzf phpMyAdmin-5.2.0-all-languages.tar.gz
mv phpMyAdmin-5.2.0-all-languages phpmyadmin
rm phpMyAdmin-5.2.0-all-languages.tar.gz

# ----------------------------
# 配置 Nginx 支持 PHP
# ----------------------------
echo "👉 配置 Nginx 虚拟主机"
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

systemctl reload nginx

# ----------------------------
# 安装 Webmin
# ----------------------------
echo "👉 安装 Webmin 面板"
wget -qO- http://www.webmin.com/jcameron-key.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/webmin.gpg >/dev/null
echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
apt update
apt install -y webmin

echo "✅ 安装完成！"
echo "========================================"
echo "Webmin 登录地址: https://$(hostname -I | awk '{print $1}'):10000"
echo "使用系统 root 账号登录"
echo "phpMyAdmin: http://$(hostname -I | awk '{print $1}')/phpmyadmin"
echo "========================================"
