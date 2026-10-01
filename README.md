# argo-tunnel

1. 卸载 cloudflared 服务和程序
cloudflared service uninstall
apt-get purge -y cloudflared
rm -f /etc/apt/sources.list.d/cloudflared.list /usr/share/keyrings/cloudflare-public-v2.gpg
rm -rf /etc/cloudflared /root/.cloudflared

2. 卸载 xray
systemctl stop xray
systemctl disable xray
bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
rm -rf /usr/local/etc/xray

3. 确认清干净
systemctl status cloudflared xray --no-pager
ss -tlnp | grep 10000

前两个应显示 could not be found，后面不应有 10000 的输出。


4. 重新运行脚本
bash /root/node.sh
