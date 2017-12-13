PATH=/sbin:/usr/sbin:/bin:/usr/bin
SSH=22
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
	iptables -F # テーブル初期化
	iptables -X # チェーンを削除
	iptables -Z # パケットカウンタ・バイトカウンタをクリア
	iptables -P INPUT   ACCEPT
	iptables -P OUTPUT  ACCEPT
	iptables -P FORWARD ACCEPT
}
finailize()
{
	/etc/init.d/iptables save && # 設定の保存
	/etc/init.d/iptables restart && # 保存したもので再起動してみる
	return 0
	return 1
}
if [ "$1" == "dev" ]
then
	iptables() { echo "iptables $@"; }
	finailize() { echo "finailize"; }
fi
initialize
iptables -P INPUT   DROP # すべてDROP。すべての穴をふさいでから必要なポートを空けていくのが良い。
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
trap 'finailize && exit 0' 2 # Ctrl-C をトラップする
echo "In 30 seconds iptables will be automatically reset."
echo "Don't forget to test new SSH connection!"
echo "If there is no problem then press Ctrl-C to finish."
sleep 30
echo "rollback..."
initialize
