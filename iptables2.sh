#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
OS=CentOS
[ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
[ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
[ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
OS=CentOS
CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
OS=Debian
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
OS=Debian
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
OS=Ubuntu
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
[ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
echo "Does not support this OS, Please contact the author! "
kill -9 $$
fi
#定义变量
SSH=$(netstat -nlp | grep sshd | awk '{print $4}' | awk -F : '{print $NF}' | sort -n | uniq)
FTP=20,21
DNS=53
SMTP=25,465,587
POP3=110,995
IMAP=143,993
HTTP=80,443
IDENT=113
NTP=123
MYSQL=3306
NET_BIOS=135,137,138,139,445
DHCP=67,68
initialize() 
{
	iptables -F
	iptables -X
	iptables -Z 
	iptables -P INPUT   ACCEPT
	iptables -P OUTPUT  ACCEPT
	iptables -P FORWARD ACCEPT
}
setiptables(){
initialize
iptables -P INPUT   DROP 
iptables -P OUTPUT  ACCEPT
iptables -P FORWARD DROP
iptables -A INPUT -i lo -j ACCEPT # SELF -> SELF
if [ "$LOCAL_NET" ]
then
	iptables -A INPUT -p tcp -s $LOCAL_NET -j ACCEPT # LOCAL_NET -> SELF
fi
if [ "${ALLOW_HOSTS}" ]
then
	for allow_host in ${ALLOW_HOSTS[@]}
	do
		iptables -A INPUT -p tcp -s $allow_host -j ACCEPT # allow_host -> SELF
	done
fi
if [ "${DENY_HOSTS}" ]
then
	for deny_host in ${DENY_HOSTS[@]}
	do
		iptables -A INPUT -s $deny_host -m limit --limit 1/s -j LOG --log-prefix "deny_host: "
		iptables -A INPUT -s $deny_host -j DROP
	done
fi
iptables -A INPUT  -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -N STEALTH_SCAN # "STEALTH_SCAN" という名前でチェーンを作る
iptables -A STEALTH_SCAN -j LOG --log-prefix "stealth_scan_attack: "
iptables -A STEALTH_SCAN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG     -j STEALTH_SCAN
iptables -A INPUT -f -j LOG --log-prefix 'fragment_packet:'
iptables -A INPUT -f -j DROP
 
iptables -N PING_OF_DEATH # "PING_OF_DEATH" という名前でチェーンを作る
iptables -A PING_OF_DEATH -p icmp --icmp-type echo-request \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 10 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_PING_OF_DEATH \
         -j RETURN
iptables -A PING_OF_DEATH -j LOG --log-prefix "ping_of_death_attack: "
iptables -A PING_OF_DEATH -j DROP
iptables -A INPUT -p icmp --icmp-type echo-request -j PING_OF_DEATH
iptables -N SYN_FLOOD # "SYN_FLOOD" という名前でチェーンを作る
iptables -A SYN_FLOOD -p tcp --syn \
         -m hashlimit \
         --hashlimit 200/s \
         --hashlimit-burst 3 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_SYN_FLOOD \
         -j RETURN
iptables -A SYN_FLOOD -j LOG --log-prefix "syn_flood_attack: "
iptables -A SYN_FLOOD -j DROP
iptables -A INPUT -p tcp --syn -j SYN_FLOOD
iptables -N HTTP_DOS # "HTTP_DOS" という名前でチェーンを作る
iptables -A HTTP_DOS -p tcp -m multiport --dports $HTTP \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 100 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_HTTP_DOS \
         -j RETURN
iptables -A HTTP_DOS -j LOG --log-prefix "http_dos_attack: "
iptables -A HTTP_DOS -j DROP
iptables -A INPUT -p tcp -m multiport --dports $HTTP -j HTTP_DOS
iptables -A INPUT -p tcp -m multiport --dports $IDENT -j REJECT --reject-with tcp-reset
iptables -A INPUT -d 192.168.1.255   -j LOG --log-prefix "drop_broadcast: "
iptables -A INPUT -d 192.168.1.255   -j DROP
iptables -A INPUT -d 255.255.255.255 -j LOG --log-prefix "drop_broadcast: "
iptables -A INPUT -d 255.255.255.255 -j DROP
iptables -A INPUT -d 224.0.0.1       -j LOG --log-prefix "drop_broadcast: "
iptables -A INPUT -d 224.0.0.1       -j DROP
iptables -A INPUT -p icmp -j ACCEPT # ANY -> SELF
iptables -A INPUT -p tcp -m multiport --dports $HTTP -j ACCEPT # ANY -> SELF
iptables -A INPUT -p tcp -m multiport --dports $SSH -j ACCEPT # ANY -> SEL
if [ "$LIMITED_LOCAL_NET" ]
then
	# SSH
	iptables -A INPUT -p tcp -s $LIMITED_LOCAL_NET -m multiport --dports $SSH -j ACCEPT # LIMITED_LOCAL_NET -> SELF
	
	# FTP
	iptables -A INPUT -p tcp -s $LIMITED_LOCAL_NET -m multiport --dports $FTP -j ACCEPT # LIMITED_LOCAL_NET -> SELF
	# MySQL
	iptables -A INPUT -p tcp -s $LIMITED_LOCAL_NET -m multiport --dports $MYSQL -j ACCEPT # LIMITED_LOCAL_NET -> SELF
fi
if [ "$ZABBIX_IP" ]
then
	# Zabbix関連を許可
	iptables -A INPUT -p tcp -s $ZABBIX_IP --dport 10050 -j ACCEPT # Zabbix -> SELF
fi
iptables -A INPUT  -j LOG --log-prefix "drop: "
iptables -A INPUT  -j DROP
}
if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
	iptables-restore < /etc/iptables.up.rules
        setiptables
	iptables-save > /etc/iptables.up.rules
fi

if [[ ${OS} == CentOS ]];then
	if [[ $CentOS_RHEL_version == 7 ]];then
		iptables-restore < /etc/iptables.up.rules
		setiptables
		iptables-save > /etc/iptables.up.rules
	else
                setiptables
		/etc/init.d/iptables save
		/etc/init.d/iptables restart
	fi
fi
echo -e "\n在一分钟内，iptables配置将被自动重置。"
echo "请尝试建立新的SSH连接测试！"
echo "如果没有问题，请输入jdkskq完成配置，输入其它值也将重置。"
read -n 6 -t 60 rsum
if [[ ${rsum} == jdkskq ]];then
    echo -e "\n配置已生效"
    exit 0
else
echo -e "\n回滚..."
if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
	iptables-restore < /etc/iptables.up.rules
        initialize
	iptables-save > /etc/iptables.up.rules
fi
if [[ ${OS} == CentOS ]];then
	if [[ $CentOS_RHEL_version == 7 ]];then
		iptables-restore < /etc/iptables.up.rules
		initialize
		iptables-save > /etc/iptables.up.rules
	else
                initialize
		/etc/init.d/iptables save
		/etc/init.d/iptables restart
	fi
fi
echo "配置已还原"
exit 0
fi
