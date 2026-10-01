cat > /root/node.sh << 'EOF'
#!/bin/bash
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "请用 root 运行"; exit 1; }

read -rp "节点域名 (如 sub.example.com): " DOMAIN
read -rsp "Cloudflare Tunnel token (输入不显示): " CF_TOKEN; echo
[ -n "$DOMAIN" ] && [ -n "$CF_TOKEN" ] || { echo "域名和 token 不能为空"; exit 1; }

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl openssl

# xray
bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
UUID=$(xray uuid)
WSPATH="/$(openssl rand -hex 6)"
mkdir -p /usr/local/etc/xray
cat > /usr/local/etc/xray/config.json << EOT
{
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": 10000,
    "protocol": "vless",
    "settings": { "clients": [{ "id": "$UUID" }], "decryption": "none" },
    "streamSettings": { "network": "ws", "wsSettings": { "path": "$WSPATH" } }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOT
xray run -test -config /usr/local/etc/xray/config.json
systemctl enable xray
systemctl restart xray

# cloudflared
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg > /usr/share/keyrings/cloudflare-public-v2.gpg
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' > /etc/apt/sources.list.d/cloudflared.list
apt-get update
apt-get install -y cloudflared
cloudflared service install "$(printf '%s' "$CF_TOKEN" | tr -d ' \n\r')"
unset CF_TOKEN

sleep 3
echo; echo "== 状态 =="
systemctl is-active xray cloudflared
ss -tlnp | grep ':10000' || echo "警告: 10000 未在监听"
echo; echo "== 客户端参数 =="
echo "UUID: $UUID"
echo "Path: $WSPATH"
echo "vless://$UUID@优选IP:443?encryption=none&security=tls&sni=$DOMAIN&type=ws&host=$DOMAIN&path=$(printf '%s' "$WSPATH" | sed 's#/#%2F#')#$DOMAIN"
EOF
chmod 700 /root/node.sh
bash /root/node.sh
