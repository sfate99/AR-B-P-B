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
		elif [[ ${param[2]} == "a" ]];then
			exit 0
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
		Add
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
			read -p "请输入有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m){默认：一个月[1m]}: " limit
			if [[ -z ${limit} ]];then
				limit="1m"
			fi
			port=$(python mujson_mgr.py -l -u ${uid} | grep "port :" | awk -F" : " '{ print $2 }')
			bash /usr/local/SSR-Bash-Python/timelimit.sh a ${port} ${limit} || EasyAdd
			datelimit=$(cat ${userlimit} | grep "${port}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9}\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
			if [[ -z ${datelimit} ]];then
				datelimit="永久"
			fi
			echo -e "添加成功!当前用户端口号：${port},有效期至：${datelimit}\n"
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
			read -p "请输入有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m){默认：一个月[1m]}: " limit
			if [[ -z ${limit} ]];then
				limit="1m"
			fi
			bash /usr/local/SSR-Bash-Python/timelimit.sh a ${port} ${limit} || EasyAdd
			datelimit=$(cat ${userlimit} | grep "${port}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9}\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
			if [[ -z ${datelimit} ]];then
				datelimit="永久"
			fi
			echo -e "添加成功!当前用户端口号：${port},有效期至：${datelimit}\n"
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
			if [[ -z ${datelimit} ]];then
				datelimit="永久"
			fi
			echo -e "当前用户端口号：${port},有效期至：${datelimit}\n"
			read -p "请输入新的有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m){默认：永久[a]}: " limit
			if [[ -z ${limit} ]];then
				limit="a"
			fi
		fi
	fi
	if [[ ${lsid} == 2 ]];then
		read -p "输入端口号： " port
		cd /usr/local/shadowsocksr
		checkuid=$(python mujson_mgr.py -l -p ${port} 2>/dev/null)
		if [[ -z ${checkuid} ]];then
			echo "用户不存在!"
			EasyEdit
		else
			datelimit=$(cat ${userlimit} | grep "${port}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9}\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
			if [[ -z ${datelimit} ]];then
				datelimit="永久"
			fi
			echo -e "当前用户端口号：${port},有效期至：${datelimit}\n"
			read -p "请输入新的有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m){默认：永久[a]}: " limit
			if [[ -z ${limit} ]];then
				limit="a"
			fi
		fi
	fi
	bash /usr/local/SSR-Bash-Python/timelimit.sh e ${port} ${limit} || EasyEdit
	datelimit=$(cat ${userlimit} | grep "${port}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9}\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
	if [[ -z ${datelimit} ]];then
		datelimit="永久"
	fi
	echo -e "修改成功!当前用户端口号：${port},新的有效期至：${datelimit}\n"
}

readme(){
	echo "Usage: $0 params [port] [expiration time]"
	echo "params can be one or more of the following :"
	echo "    a | A    : Add a time limit for a user."
	echo "    e | E    : Modify a user's time limit."
	echo "If you do not add any parameters after the first parameter,you will enter a simple interface to operate."
	echo ""
	echo 'About the second parameter "port" :'
	echo "    As the unique identifier of a user,the port number is unique and the script determines the user's basis.So when you add an account with the same port number,the script will overwrite the original record without any hint."
	echo ""
	echo 'About the third parameter "expiration time" :'
	echo '    Account expiration date refers to the period from the current date.This is true whether it is added or modified.The format is "number+unit".For example,one month is "1m",one day is "1d" and one hour is "1h".'
	echo ""
	echo "Note: This script does not interact with other scripts.When you add traffic to a user, the script will still be deleted as before."
	echo ""
	echo "e.g.: "
	echo "bash ./timelimit.sh a 443 1m      #You will add a month's validity to a user with a port number of 443."
	echo ""
	echo "If you find a bug, send it to 'stackzhao@gmail.com'"
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
 		readme
 		;;
esac
exit 0