#/bin/sh
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
echo "##################################
      AR-B-P-B 自检系统
             V1.0 Alpha
##################################"
rm -f report.json
#List /usr/local
echo "############Filelist of /usr/local" >> report.json
cd /usr/local
ls >> report.json
#List /usr/local/ssr-bash-python
echo "############Filelist of /usr/local/SSR-Bash-Python" >> report.json
cd /usr/local/SSR-Bash-Python
ls >> report.json
#List /usr/local/shadowsockr
echo "############Filelist of /usr/local/shadowsockr" >> report.json
cd /usr/local/shadowsocksr
ls >> report.json
echo "############File test" >> report.json
#Check File Exist
if [ ! -f "/usr/local/bin/ssr" ]; then
  echo "SSR-Bash-Python主文件缺失，请确认服务器是否成功连接至Github"
  echo "SSR Miss" >> report.json
  exit
fi
if [ ! -f "/usr/local/SSR-Bash-Python/server.sh" ]; then
  echo "SSR-Bash-Python主文件缺失，请确认服务器是否成功连接至Github"
  echo "SSR Miss" >> report.json
  exit
fi
if [ ! -f "/usr/local/shadowsocksr/stop.sh" ]; then
  echo "SSR主文件缺失，请确认服务器是否成功连接至Github"
  echo "SSR Miss" >> report.json
  exit
fi

#Firewall
echo "############Firewall test" >> report.json
iptables -L >> report.json

echo "检测完成，未发现严重问题，如仍有任何问题请提交report.json"
