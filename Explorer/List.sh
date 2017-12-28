#!/bin/bash

#文件位置
#ctrlf="/opt/QtPalmtop/data/z/common/ctrl.dat" #按键数据
ctrlf="$(dirname "$0")/term.dat"
outf="/tmp/ListSelect.tmp"

#其它数据
declare -a tmp=(`cat $ctrlf`)    #按键数据处理
up="${tmp[0]}"    #上键数据
down="${tmp[1]}"    #下键数据
left="${tmp[2]}"    #左键数据
right="${tmp[3]}"    #右键数据
pageup="${tmp[4]}"    #上翻页键数据
pagedown="${tmp[5]}"    #下翻页键数据
back="${tmp[6]}"    #返回键数据

#颜色数据
titc='\E[1;31;40m'    #标题
errc='\E[1;34;40m'    #错误  没有列表项目
color='\E[1;34;40m'    #版权  Made By Norman (ZHIYB)
linc='\E[1;32;40m'    #分割  ###分割线###颜色
inc='\E[1;33;40m'    #提示  提示文字
declare -a listc=('\E[0;34;40m' '\E[1;34;102m') \
term=('\E[0;34;40m' '\E[1;32;44m')
light="\E[1;37;40m"    #高亮  强调文字
end='\E[0m'    #返回  返回初始颜色

#显示内容
if [ "$1" = "" ] ; then
  in_title="      列表选择" ; in_made="      AR-B-P-B"
  in_show="1" ; in_pagenum="0" ; in_init="0"
  declare -a in_list=( '列表选择程序'\
  '参数: 标题 关于 错误 强调 数量 初始'\
  '参数1: 程序标题'\
  '参数2: 程序关于信息'\
  '参数3: 无选项错误显示'\
  '参数4: 选项左右提示条显示?'\
  '参数5: 每页显示数量'\
  '参数6: 初始选定项(从0开始)'\
  '参数7: 列表项'\
  '列表项详细信息见第二页'\
  '程序返回值: 选择的项目(从0开始)'\
  '返回值从0到255,共可返回256项'\
  '列表项输入说明:'\
  '全部列表项用\"\"括住,作为位置参数7'\
  '项与项之间用空格分开'\
  '最好把每一项都分别用'\'\''括住'\
  '某些特殊字符需用\\转义'\
  '其它:'\
  '可以在文本参数中使用\E[32;41mecho\E[7m转义\E[27m序列'\
  '位置参数必须存在(不为空)'\
  '否则会显示本帮助'\
  '它还会自动把选择的项保存到'\
  "\E[31m$outf文件中"\
  '这样就能选超过256个项了' )
else
  in_title="$1" ; in_made="$2" ; in_err="$3"
  in_show="$4" ; in_pagenum="$5" ; in_init="$6"
  eval declare -a in_list=($7) #列表项
  if [ "$in_init" = "" ] ; then in_init=0 ; fi
fi
lines="$linc################################################$end" #分割线
title="$titc$in_title$color$in_made$end"    #标题
if [ "$in_show" = 1 ] ; then
  declare -a chl=('------ ' '>>>>>> ') chr=(' ------' ' <<<<<<')
else declare -a chl=('' '') chr=('' '')
fi

#函数
prog_Auto(){
  ((pagenum=in_pagenum==0?$(tput lines)-4:in_pagenum))
  n=$lnum ; pages=0
  while ((n>pagenum)) ; do
    ((pages++)) ; ((n-=pagenum))
  done
}

#主程序
lnum=${#in_list[@]} ; prog_Auto
quit=0 ; dat=$in_init ; pageno=1
echo -ne '\E[?25l' ; stty -echo
until [ "$quit" = "1" ] ; do
  if [ "$pages" = "0" ] ; then
    n=0 ; page=$lnum #页面显示项
  else
    page=0 ; pageno=1 ; n=$dat
    while ((n>((pagenum-1)))) ; do
      ((page+=pagenum)) ; ((n-=pagenum)) ; ((pageno++))
    done
    n=$page ; ((page+=pagenum))
    if ((page>=((lnum+pagenum)))) ; then
      ((n-=pagenum)) ; ((pageno--)) ; page=$lnum
    elif ((page>lnum)) ; then page=$lnum
    fi
  fi
  clear ; echo -e "$title\n$lines\n$inc上下键选择,左右键翻页: 第$light$pageno$inc, 共$light$((tmp=$pages+1))$inc页$end"
  if [ "${#in_list[@]}" = "0" ] ; then
    echo -e "$errc$in_err$end" ; dat=0 ; quit=1
    read -s ; continue
  fi
  until [ "$n" = "$page" ] ; do
    echo -e "${term[((tmp=n++==dat))]}${chl[tmp]}${listc[tmp]}${in_list[((n-1))]}${term[tmp]}${chr[tmp]}$end"
  done
  read -sn 3 key
  if [ "$key" = "$up" ] ; then ((dat--))
    ((dat=dat==-1?lnum-1:dat))
  elif [ "$key" = "$down" ] ; then ((dat++))
    ((dat=dat==lnum?0:dat))
  elif [ "$key" = "$right" ] ; then ((dat+=pagenum))
    ((dat=dat>=lnum?lnum-1:dat))
  elif [ "$key" = "$left" ] ; then
    ((dat=dat>=lnum?lnum-pagenum:((dat<pagenum?0:dat-pagenum))))
  elif [ "$key" = "" ] ; then
    quit=1
  fi
  prog_Auto
done
echo -n $dat > "$outf" ; echo -ne '\E[?25h'
stty echo ; exit $dat
