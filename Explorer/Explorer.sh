#!/bin/bash

#变量
#app='/opt/QtPalmtop/bin/z'
app="$PWD"
listfile='/tmp/ListSelect.tmp' ; null='/dev/null'
recycle="$PWD/Recycle"
outfile='/tmp/DirFile.tmp' ; lstmp='/tmp/ls.tmp'
#optbin='/opt/QtPalmtop/bin'
declare -a dir style click clickterms \
title=('文件管理' '打开文件' '选择文件' '保存文件') bak \
clickbak clickmsg=('选择此项' '取消选择') \
clickshow=('[ ]' '\E[94m[\E[31mX\E[94m]') \
dirlink=("挂载到此文件夹" "进入链接目录") \
linkshow=([1]="进入链接目录") clicknames \
tar=("打开..." "打开..." "解压...") copy ok=("完成")
xy="4 14 0 0" ; select=1
for ((n=1;n<=255;n++)) ; do
  ok[$n]="失败"
done

#转义序列
inc='\E[33;40m' ; comc='\E[31m' ; end='\E[0m'
declare -a color=('\E[94m' '\E[92m' '\E[96m'\
 '\E[95m' '\E[31m' '\E[22;36m' '\E[92m') linkp=('' '\E[3;1H\E[2K')

#函数
prog_find(){
  n=0 ; unset dir[@] ; ls -1a > "$lstmp"
  while read line ; do
    if [ "${click[n]}" = "" ] ; then click[$n]=0 ; fi
    prog_sure ; dir[$((n++))]="$line"
  done < "$lstmp"
  if [ "${dir[*]}" != "${bak[*]}" ] ; then
    prog_click_back
  fi
  for ((n=0;n<=${#dir[@]};n++)) ; do
    bak[$n]="${dir[n]}"
  done
  $app/List.sh "  ${title[open]}  "\
  "${PWD:((${#PWD}>36?-36:0))}" "" "0" "10" "$((select-1))"\
  "'..' `for ((n=2;n<${#dir[@]};n++)) ; do echo "'${clickshow[click[n]]}${color[style[n]]}${dir[n]}'" ; done`\
  '> $inc目录操作...' '> $inc选择项操作...' '> $inc磁盘信息' '> $inc退出'"
}
prog_sure(){
  if [ -d "$line" ] ; then style[n]=0
    if [ -h "$line" ] ; then style[n]=5 ; fi
  elif [ -h "$line" ] ; then style[n]=2
  elif [ -b "$line" ] ; then style[n]=3
  elif [ -c "$line" ] ; then style[n]=4
  else
    if [ "${line:(-7)}" = '.tar.gz' ] ; then style[n]=6
    else style[n]=1
    fi
  fi
}
prog_msgbox_dirmenu(){
  $app/Msgbox.sh "$xy" "目录操作"\
  "'运行命令...' '新建文件(夹)...' 创建链接 粘贴 查找 返回"
  case "$?" in
  0 ) prog_msgbox_run ;;
  1 ) prog_msgbox_new ;;
  2 ) prog_link_make ;;
  3 ) prog_paste ;;
  4 ) prog_search ;;
  esac
}
prog_msgbox_run(){
  echo -e "$inc此功能未完成!$end"
}
prog_msgbox_new(){
  $app/Msgbox.sh "$xy" "'新建文件(夹)'"\
  "新建文件 新建文件夹 取消"
  case "$?" in
  0 ) prog_input "新建文件" ; echo -n "" >> "$read" ;;
  1 ) prog_input "新建文件夹" ; mkdir "$read" ;;
  esac
}
prog_link_make(){
  if [ "$mount" = "" ] ; then
    echo -e "$inc没有选择链接原文件!$end" ; return
  fi
  prog_input 创建链接 ; ln -sn "$mount" "./$read"
  echo -e "$inc链接创建${ok[$?]}!$end"
}
prog_input(){
  echo -e "\E[1m$inc$1 请输入名称: $end"
  read -r read
}
prog_paste(){
  if [ "${copy[0]}" = "" ] ; then
    echo -e "$inc剪贴板中无文件!$end"
    usleep 500000 ; return
  fi
  echo -e "$inc粘贴中...$end"
  for ((n=1;n<${#copy[@]};n++)) ; do
    echo -e "$inc$n/$((${#copy[@]}-1)): ${copy[n]}$end"
    if [ "${copy[0]}" = 0 ] ; then mv "${copy[n]}" .
    else cp -rf "${copy[n]}" .
    fi
  done
}
prog_search(){
  echo -e "$inc此功能未完成!$end"
}
prog_file(){
  pwd="$PWD/${dir[select]}" ; tmp="$1"
  if [ "$tmp" = 2 ] ; then tmp=0 ; fi
  echo -ne "${linkp[$1]}$3$end"
  if [ $1 = 2 ] ; then
    $app/Msgbox.sh "$xy" "配置文件" "还原配置 取消"
    if [ $? = 0 ] ; then echo "${PWD}/${dir[select]}" > /tmp/BakFilename.tmp ; echo -e "\033[?25h" ; stty echo ; break ; exit 1 ; fi 
  fi
  $app/Msgbox.sh "$xy" "$2"\
  "'${clickmsg[click[select]]}' '运行...' ${linkshow[$1]} ${tar[$1]} '挂载/链接' ' 重命名' '删除...' '返回'"
  case "$?" in
  0 ) click[$select]=$((click[select]==0)) ;;
  1 ) prog_file_msgbox_run ;;
  $((tmp+1)) ) cd "$(dirname "$(readlink "${dir[select]}")")" ; select=1 ;;
  $((tmp+2)) )
    if [ "$1" = 2 ] ; then prog_unpick
    else prog_file_open
    fi ;;
  $((tmp+3)) ) prog_mount ;;
  $((tmp+4)) ) prog_rename ;;
  $((tmp+5)) ) prog_delete ;;
  esac
}
prog_file_open(){
  $app/Msgbox.sh "$xy" "打开文件 请选择打开方式:"\
  "'备份还原' '  Vim  ' 'MPlayer' '  返回  '"
  tmp=$?
  if [ "$tmp" = 3 ] ; then return ; fi
  case $tmp in
  0 ) echo "$PWD/${dir[select]}" > /tmp/BakFilename.tmp ;;
  1 ) vim "$PWD/${dir[select]}" ;;
  2 ) mplayer "$PWD/${dir[select]}" ;;
  esac
}
prog_file_msgbox_run(){
  $app/Msgbox.sh "$xy" "运行文件"\
  "在此终端运行 取消"
  case "$?" in
  0 ) (${dir[select]}) ;;
  esac
}
prog_mount(){
  mount="$pwd"
  echo -e "$inc$pwd已储存为挂载/链接原文件!$end" ; sleep 1s
}
prog_delete(){
  $app/Msgbox.sh "$xy" "删除文件 '确定要删除?'"\
  "删除到回收站 彻底删除 取消删除操作"
  case "$?" in
  0 )
    rm -rf "$recycle/${dir[select]}" > "$null"
    mv "${dir[select]}" "$recycle" ; tmp="$?" ;;
  1 ) rm -rf "${dir[select]}" ; tmp="$?" ;;
  2 ) return ;;
  esac
  echo -e "$inc删除${ok[tmp]}!$end" ; usleep 500000
}
prog_rename(){
  prog_input 重命名文件
  mv "${dir[select]}" "$read"
  echo -e "$inc重命名${ok[$?]}!$end" ; usleep 500000
}
prog_click_back(){
  clickbak=(${click[@]}) ; unset click[@]
  for ((n=0;n<=${#bak[@]};n++)) ; do
    if [ "${clickbak[n]}" = 1 ] ; then
      if [ "${bak[n]}" = "${dir[n]}" ] ; then
        click[$n]=1 ; continue
      fi
      for ((m=0;m<=${#dir[@]};m++)) ; do
        if [ "${bak[n]}" = "${dir[m]}" ] ; then
          click[$m]=1
        fi
      done
    fi
  done
}
prog_click(){
  clicknum=0 ; unset clickterms[@] ; unset clicknames[@]
  declare -a clickterms ; declare -a clicknames
  for ((n=0;n<=${#dir[@]};n++)) ; do
    if [ "${click[n]}" = 1 ] ; then
      clickterms[${#clickterms[@]}]="$PWD/${dir[n]}"
      clicknames[${#clicknames[@]}]="${dir[n]}"
      ((clicknum++))
    fi
  done
  if [ $clicknum = 0 ] ; then
    echo ; echo -e "$inc无选择项!$end"
    usleep 500000 ; return
  fi
  $app/Msgbox.sh "$xy" "选择项操作 已选择$clicknum项"\
  "剪切 复制 '删除...' '打包...' '返回'"
  case $? in
  0 ) prog_multicut ;;
  1 ) prog_multicopy ;;
  2 ) prog_multidelete ;;
  3 ) prog_pickup ;;
  esac
}
prog_click_clear(){
  unset clicktrems[@] clickname[@] click[@] ; clicknum=0
}
prog_multicut(){
  unset copy[@] ; copy[0]=0 ; prog_copy_data
  echo -e "$inc剪切: 已储存$clicknum个文件到剪贴板$end"
  usleep 500000
}
prog_multicopy(){
  unset copy[@] ; copy[0]=1 ; prog_copy_data
  echo -e "$inc复制: 已储存$clicknum个文件到剪贴板$end"
  usleep 500000
}
prog_copy_data(){
  for ((n=0;n<${#clickterms[@]};n++)) ; do
    copy[${#copy[@]}]="${clickterms[n]}"
  done
}
prog_multidelete(){
  $app/Msgbox.sh "$xy" "删除文件 已选择$clicknum个文件"\
  "删除到回收站 彻底删除 取消删除操作"
  tmp="$?"
  if [ $tmp = 2 ] ; then return ; fi
  echo -e "$inc正在删除文件中...$end"
  for ((n=0;n<${#clickterms[@]};n++)) ; do
    echo -e "$inc$((n+1))/${#clickterms[@]}: ${clickterms[n]}$end"
    if [ $tmp = 0 ] ; then
      rm -rf "$recycle/`basename "${clickterms[n]}"`" > "$null"
      mv "${clickterms[n]}" "$recycle"
    else
      rm -rf "${clickterms[n]}"
    fi
  done
  unset click[@] ; select=1
}
prog_pickup(){
  $app/Msgbox.sh "$xy" "'创建.tar.gz压缩文件' '已选择$clicknum项'"\
  "'压缩到当前目录' '压缩到家目录' '压缩到根目录' '取消'"
  case $? in
  0 ) tardir="$PWD" ;;
  1 ) tardir="$HOME" ;;
  2 ) tardir="/" ;;
  3 ) return ;;
  esac
  prog_input "文件打包"
  echo -e "$inc压缩到$tardir/$read.tar.gz: 压缩中...$end"
  tar -czvf "$tardir/$read.tar.gz" -C "$PWD" ${clicknames[@]}
  echo -e "$inc压缩${ok[$?]}!$end"
}
prog_dir(){
  echo -e "${linkp[$1]}$3$end"
  $app/Msgbox.sh "$xy" "文件夹$2"\
  "'进入' ${linkshow[$1]} '${clickmsg[click[select]]}' '挂载到此文件夹' '挂载/链接' '重命名' '删除...' '返回'"
  case $? in
  0 ) cd "${dir[select]}" ; prog_click_clear ; select=1 ;;
  $1 ) cd "`readlink "${dir[select]}"`" ; select=1 ;;
  $((1+$1)) ) click[$select]=$((click[select]==0)) ;;
  $((2+$1)) ) prog_mount_to ;;
  $((3+$1)) ) pwd="$PWD/${dir[select]}" ; prog_mount ;;
  $((4+$1)) ) prog_rename ;;
  $((5+$1)) ) prog_delete ;;
  esac
}
prog_mount_to(){
  if [ "$mount" = "" ] ; then
    echo -e "$inc没有选择挂载原文件!$end"
    usleep 500000 ; return
  fi
  umount -l "${dir[select]}" ; usleep 300000
  mount "$mount" "${dir[select]}"
  echo -e "$inc挂载${ok[$?]}!$end"
}
prog_unpick(){ 
  $app/Msgbox.sh "$xy" "解压文件"\
  "解压到当前目录 解压到家目录  解压到根目录 取消"
  case $? in
  0 ) tardir="$PWD" ;;
  1 ) tardir="$HOME" ;;
  2 ) tardir="/" ;;
  3 ) return ;;
  esac
  tar -xzvf "${dir[select]}" -C "$tardir"
  echo -e "$inc解压${ok[$?]}$end"
}

#初始化
mkdir -p "$recycle"
initdir="$1"
power=1 ; open=0

#主程序
stty -echo ; stty erase '^?' ; cd "$initdir"
trap 'echo -e "\033[?25h" ; stty echo ; exit 0' 2
until [ "$quit" = 1 ] ; do
  prog_find ; select="$(($(<$listfile)+1))"
  case "$select" in
  1 ) cd .. ;;
  ${#dir[@]} ) prog_msgbox_dirmenu ;;
  $((${#dir[@]}+1)) ) prog_click ;;
  $((${#dir[@]}+2)) ) df -h
    echo -e "$inc按回车键继续...$end" ; read -s ;;
  $((${#dir[@]}+3)) ) exit 1 ;;
  * )
    case "${style[select]}" in
    0 ) prog_dir 0 ;;
    1 ) prog_file 0 普通文件 ;;
    2 ) prog_file 1 文件链接 "\E[2G$inc地址: `readlink "${dir[select]}"`" ;;
    5 ) prog_dir 1 链接 "\E[2G$inc地址: `readlink "${dir[select]}"`" ;;
    6 ) prog_file 2 压缩文件 ;;
    esac ;;
  esac
done
echo $result > $outfile ; echo -e "\033[?25h" ; stty echo ; exit 0
