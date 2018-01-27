 #!/bin/bash

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

#Initialization
userlimit="/usr/local/SSR-Bash-Python/timelimit.db"
nowdate=$(date +%Y%m%d%H%M)
declare -a param=($1 $2 $3)
unset edit

#Set function
checkonly(){
	if [[ -e ${userlimit} ]];then
		for line in $(cat ${userlimit})
		do
			if [[ ! -z ${line} ]];then
				port=$(echo ${line} | awk -F':' '{ print $1 }')
				limitdate=$(echo ${line} | awk -F':' '{ print $2 }')
				if [[ ${nowdate} -ge ${limitdate} ]];then
					cd /usr/local/shadowsocksr/
					python mujson_mgr.py -d -p ${port} 1>/dev/null 2>&1
					sed -i '/'"${line}"'/d' ${userlimit}
				fi
			fi
		done
	fi
}

Add(){
	if [[ ! -e ${userlimit} ]];then
		touch ${userlimit}
	fi
	checkuser=$(grep -i "${param[1]}:" ${userlimit})
	if [[ ${edit} == "yes" || -z ${checkuser} ]];then
		if [[ ${param[2]} == *d ]];then
			timing=$(echo ${param[2]} | sed 's\d\\g')
			dating=$(date +%Y%m%d%H%M --date="+${timing}day")
		elif [[ ${param[2]} == *m ]];then
			timing=$(echo ${param[2]} | sed 's\m\\g')
			dating=$(date +%Y%m%d%H%M --date="+${timing}month")
		elif [[ ${param[2]} == *h ]];then
			timing=$(echo ${param[2]} | sed 's\h\\g')
			dating=$(date +%Y%m%d%H%M --date="+${timing}hour")
		else
			echo "错误的参数属性值"
			exit 1
		fi
		echo "${param[1]}:${dating}" >> ${userlimit}
	else
		Edit
	fi

}

Edit(){
	checkuser=$(grep -i "${param[1]}:" ${userlimit})
	if [[ -z ${checkuser} ]];then
		echo "用户不存在!"
		exit 2
	else
		limitdate=$(echo ${checkuser} | awk -F':' '{ print $2 }')
		edit="yes"
		sed -i '/'"${checkuser}"'/d' ${userlimit}
		Add
	fi
}

EasyAdd(){
	echo "1.使用用户名"
	echo "2.使用端口"
	echo ""
	while :; do echo
		read -p "请选择： " lsid
		if [[ ! $lsid =~ ^[1-2]$ ]]; then
			echo "输入错误! 请输入正确的数字!"
		else
			break	
		fi
	done
	if [[ ${lsid} == 1 ]];then
		read -p "输入用户名： " uid
		cd /usr/local/shadowsocksr
		checkuid=$(python mujson_mgr.py -l -u ${uid})
		if [[ -z ${checkuid} ]];then
			echo "用户名不存在！"
			EasyAdd
		else
			read -p "请输入有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m): " limit
			if [[ -z ${limit} ]];then
				limit="1m"
			fi
			port=$(python mujson_mgr.py -l -u ${uid} | grep "port :" | awk -F" : " '{ print $2 }')
			bash /usr/local/SSR-Bash-Python/timelimit.sh a ${port} ${limit} || EasyAdd
		fi
	fi
	if [[ ${lsid} == 2 ]];then
		read -p "输入端口号： " port
		cd /usr/local/shadowsocksr
		checkuid=$(python mujson_mgr.py -l -p ${port})
		if [[ -z ${checkuid} ]];then
			echo "用户不存在!"
			EasyAdd
		else
			read -p "请输入有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m): " limit
			if [[ -z ${limit} ]];then
				limit="1m"
			fi
			bash /usr/local/SSR-Bash-Python/timelimit.sh a ${port} ${limit} || EasyAdd
		fi
	fi
}

EasyEdit(){
	echo "1.使用用户名"
	echo "2.使用端口"
	echo ""
	while :; do echo
		read -p "请选择： " lsid
		if [[ ! $lsid =~ ^[1-2]$ ]]; then
			echo "输入错误! 请输入正确的数字!"
		else
			break	
		fi
	done
	if [[ ${lsid} == 1 ]];then
		read -p "输入用户名： " uid
		cd /usr/local/shadowsocksr
		checkuid=$(python mujson_mgr.py -l -u ${uid})
		if [[ -z ${checkuid} ]];then
			echo "用户名不存在！"
			EasyEdit
		else
			port=$(python mujson_mgr.py -l -u ${uid} | grep "port :" | awk -F" : " '{ print $2 }')
			datelimit=$(cat ${userlimit} | grep "${port}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9}\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
			echo -e "当前用户端口号：${port},有效期至：${datelimit}\n"
			read -p "请输入新的有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m): " limit
			if [[ -z ${limit} ]];then
				limit="1m"
			fi
			bash /usr/local/SSR-Bash-Python/timelimit.sh e ${port} ${limit} || EasyEdit
		fi
	fi
	if [[ ${lsid} == 2 ]];then
		read -p "输入端口号： " port
		cd /usr/local/shadowsocksr
		checkuid=$(python mujson_mgr.py -l -p ${port})
		if [[ -z ${checkuid} ]];then
			echo "用户不存在!"
			EasyEdit
		else
			datelimit=$(cat ${userlimit} | grep "${port}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9}\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
			echo -e "当前用户端口号：${port},有效期至：${datelimit}\n"
			read -p "请输入新的有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m): " limit
			if [[ -z ${limit} ]];then
				limit="1m"
			fi
			bash /usr/local/SSR-Bash-Python/timelimit.sh e ${port} ${limit} || EasyEdit
		fi
	fi
}

#Main
case ${param[0]} in
	a|A)
 		if [[ -z ${param[1]} && -z ${param[2]} ]];then
 			EasyAdd
 		else
 			Add
 		fi
 		;;
 	e|E)
 		if [[ -z ${param[1]} && -z ${param[2]} ]];then
 			EasyEdit
 		else
 			Edit
 		fi
 		;;
 	c|C)
 		checkonly
 		;;
 	*)
 		echo "错误的参数值!"
 		;;
 esac
