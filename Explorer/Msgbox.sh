#!/bin/bash

#变量
#ctrlf='/opt/QtPalmtop/data/z/common/ctrl.dat'
ctrlf="$(dirname "$0")/term.dat"
declare -a tmp=($(<"$ctrlf"))
up="${tmp[0]}" ; down="${tmp[1]}"
left="${tmp[2]}" ; right="${tmp[3]}"
pageup="${tmp[4]}" ; pagedown="${tmp[5]}"
back="${tmp[6]}"
declare -a space upline midline downline

#转义字符串
titc='\E[91;40m' ; linc='\E[32;40m'
declare -a term=('\E[34;40m  ' '\E[92;44m> \E[91;102m')
end='\E[0m'  ; delete='\E[J' ; del='\E[2K'
declare -a frame=('\E[96;45m╔═\E[0m' \
'\E[96;45m══\E[0m' '\E[96;45m═╗\E[0m' \
'\E[96;45m║ \E[0m' '\E[96;45m ║\E[0m' \
'\E[96;45m╚═\E[0m' '\E[96;45m══\E[0m' \
'\E[96;45m═╝\E[0m' '##')
#frame框架顺序: 左上 上 右上 左 右 左下 下 右下

#函数
prog_quit(){
  echo -e "\E[?25h" ; stty echo ; exit $select
}
prog_auto(){
  for ((n=0;n<${#message[@]};n++)) ; do
    if ((${#message[n]}>xy[2])) ; then
      xy[2]="${#message[n]}"
    fi
  done
  for ((n=0;n<${#choose[@]};n++)) ; do
    if ((${#choose[n]}>xy[2])) ; then
      xy[2]="${#choose[n]}"
    fi
  done
  xy[2]=$((xy[2]+1))
}

#初始化
echo -ne "\E[?25l" ; stty -echo
if [ "$1" = "" ] ; then
  declare -a xy=(4 14 0 0)\
  message=('Here is a message box.' '这是一个小提示选择框' 'Made by Norman (ZHIYB)')\
  choose=('Exit' 'Quit' 'Escape' '退出程序')
  prog_auto ; xy[2]=$((xy[2]/2))
else
  eval declare -a xy=($1) message=($2) choose=($3)
  if [ "${xy[2]}" = 0 ] ; then prog_auto ; fi
  xy[2]=$((xy[2]/2))
fi
for ((n=1;n<=xy[2]*2+4;n++)) ; do
  space[n]="${space[n-1]} "
  upline[n]="${upline[n-1]}${frame[1]}"
  midline[n]="${midline[n-1]}${frame[8]}"
  downline[n]="${downline[n-1]}${frame[6]}"
done
dat="${xy[3]}"

#主程序
echo -ne "\E[$((xy[0]<0?0:xy[0]));$((xy[1]-2))H$del$delete${frame[0]}${upline[xy[2]+2]}${frame[2]}"
for ((n=0;n<${#message[@]};n++)) ; do
  echo -ne "\E[$((xy[0]+n+1));$((xy[1]-2))H${frame[3]} $titc${message[n]}${space[xy[2]*2-${#message[n]}+3]}${frame[4]}"
done
echo -ne "
\E[$((xy[0]+${#message[@]}+1));$((xy[1]-2))H${frame[3]} $linc${midline[xy[2]+1]} ${frame[4]}"
until [ "$quit" = 1 ] ; do
  for ((n=0;n<${#choose[@]};n++)) ; do
    echo -ne "\E[$((xy[0]+${#message[@]}+2+n));$((xy[1]-2))H${frame[3]} ${term[((dat==n))]}${choose[n]}$end${space[xy[2]*2-${#choose[n]}+1]}${frame[4]}"
  done
  echo -ne "\E[$((xy[0]+${#message[@]}+${#choose[@]}+2));$((xy[1]-2))H${frame[5]}${downline[xy[2]+2]}${frame[7]}"
  read -sn 3 key
  case "$key" in
  "$up" ) ((dat--)) ; ((dat=dat<0?${#choose[@]}-1:dat)) ;;
  "$down" ) ((dat++)) ; ((dat=dat>${#choose[@]}-1?0:dat)) ;;
  "$left" ) dat=0 ;;
  "$right" ) dat="$((${#choose[@]}-1))" ;;
  "" ) quit=1 ; select="$dat" ;;
  esac
done
prog_quit
