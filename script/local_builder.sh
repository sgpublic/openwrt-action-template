#!/bin/bash
set -e

##    自定义配置    ##
CONFIG_FILE="$WORK_ROOT/config/origin.config"
PATCH_FILES="$WORK_ROOT/patches"
DIY_P1_SH="$WORK_ROOT/script/diy-part1.sh"
DIY_P2_SH="$WORK_ROOT/script/diy-part2.sh"
THREAD=$(nproc)
OUTPUT_DIR="$WORK_ROOT/local"
##    自定义配置    ##






declare -a _STEP_STACK=(
  Clone_Source_Code
  Load_Custom_Feeds
  Update_Feeds
  Install_Feeds
  Load_Custom_Configuration
  Download_Package
  Copy_Patch_Files
  Compile_The_Firmware
  Organize_Files
  Upload_Firmware_To_Release
)

runing() {
  echo -e "\e[1;33m  runing:\e[0m \e[1;34m$1\e[0m"
}

execute() {
  runing "$1"
  $1
}

comfirm() {
  echo -e "\e[1;36m  $1: \e[0m\c"
}

main() {
  comfirm "Do you need to initialize your Linux? (y/N)"
  read _need

  if [[ "$_need" =~ ^[yY]$ ]]; then
    execute "sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc"
    execute "sudo apt update -y"
    execute "sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev file wget -y"
    execute "sudo apt clean"
  fi

  if [ -d 'openwrt.bak' ]; then
    comfirm "Do you want to use git cache? If you select No, ite will be deleted. (Y/n)"
    read _need
    if [[ "$_need" =~ ^[nN]$ ]]; then
      execute "rm -rf ./openwrt.bak"
    fi
  fi

  if [ -d '/tmp/openwrt' ]; then
    comfirm "Do you want to use build cache? If you select No, it will be deleted. (Y/n)"
    read _need
    if [[ "$_need" =~ ^[nN]$ ]]; then
      execute "rm -rf /tmp/openwrt/build_dir"
      execute "rm -rf /tmp/openwrt/staging_dir"
      execute "rm -rf /tmp/openwrt/binary"
    fi
  fi

  execute "mkdir -p /tmp/openwrt"

  for _element in ${_STEP_STACK[@]}; do
    $_element
  done
}

_STEP_CURRENT=0
print_step() {
  _STEP_CURRENT=$((_STEP_CURRENT+1))
  echo -e "\e[1;32m  Step $_STEP_CURRENT (${#_STEP_STACK[@]} total): $1\e[0m"
}

Clone_Source_Code() {
  print_step 'Clone source code'
  execute "rm -rf openwrt"
  . $WORK_ROOT/openwrt-detail.sh
  if [ ! -d 'openwrt.bak' ]; then
    execute "git clone -b $REPO_BRANCH $REPO_URL openwrt.bak"
    execute "cd openwrt.bak"
    execute "mkdir -p /tmp/openwrt/staging_dir"
    if [ ! -d "staging_dir" ]; then
      execute "ln -s /tmp/openwrt/staging_dir ./"
    fi
    execute "mkdir -p /tmp/openwrt/build_dir"
    if [ ! -d "build_dir" ]; then
      execute "ln -s /tmp/openwrt/build_dir ./"
    fi
  else
    execute "cd openwrt.bak"
    execute "git pull origin $REPO_BRANCH"
  fi
}

Load_Custom_Feeds() {
  print_step 'Load custom feeds'
  execute "bash $DIY_P1_SH --local"
}

Update_Feeds() {
  print_step 'Update feeds'
  execute "./scripts/feeds update -a"
  execute "cp -r ../openwrt.bak ../openwrt"
  execute "cd ../openwrt"
}

Install_Feeds() {
  print_step 'Install feeds'
  execute "./scripts/feeds install -a"
}

Load_Custom_Configuration() {
  print_step 'Load custom configuration'
  execute "cp $CONFIG_FILE ./.config"
  execute "bash $DIY_P2_SH --local"
}

Download_Package() {
  print_step 'Download package'
  comfirm "Do you need to change the config file? (y/N)"
  read _need
  if [[ "$_need" =~ ^[yY]$ ]]; then
    runing "make menuconfig -j$THREAD"
    make menuconfig -j$THREAD || make menuconfig V=s
  else
    runing "make defconfig -j$THREAD"
    make defconfig -j$THREAD || make defconfig V=s
  fi
  mkdir -p $OUTPUT_DIR
  execute "cp ./.config $OUTPUT_DIR/"
  runing "make download -j2"
  make download -j$THREAD
  execute "rm -rf /tmp/openwrt/download/go-mod-cache"
  runing "find /tmp/openwrt/download -size -1024c -exec ls -l {} \;"
  find /tmp/openwrt/download -size -1024c -exec ls -l {} \;
  runing "find /tmp/openwrt/download -size -1024c -exec rm -f {} \;"
  find /tmp/openwrt/download -size -1024c -exec rm -f {} \;
}

Copy_Patch_Files() {
  print_step 'Copy patch files'
  if [[ -e "$PATCH_FILES/*" ]]; then
    execute "cp -r $PATCH_FILES/* ./"
  else
    echo "No patch files, skip."
  fi
}

Compile_The_Firmware() {
  print_step 'Compile the firmware'
  execute "rm -rf /tmp/openwrt/binary/targets"
  runing "make -j$THREAD || make V=s"
  make -j$THREAD || make V=s
}

Organize_Files() {
  print_step 'Organize files'
  mkdir -p $OUTPUT_DIR
  execute "rm -rf $OUTPUT_DIR/bin/"
  execute "rm -rf /tmp/openwrt/binary/targets/*/*/packages"
}

Upload_Firmware_To_Release() {
  print_step 'Upload firmware to release'
  runing "mkdir -p $OUTPUT_DIR/bin"
  mkdir -p $OUTPUT_DIR/bin
  execute "cp -r /tmp/openwrt/binary/targets/*/*/* $OUTPUT_DIR/bin/"
}

main
