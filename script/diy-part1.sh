#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
set -e
if [ "$1" == "--local" ]; then
  set -v
fi

git_clone() {
  path=`pwd`
  if [ -d $2 ]; then
    cd $2
    git pull
    cd $path
  else
    mkdir -p "$2"
    git clone $1 --depth=1 $2
  fi
}

# 修改标准目录，若不需要注释掉即可，此代码对 action 编译没有任何影响
sed -i 's/$(TOPDIR)\/staging_dir/\/tmp\/openwrt\/staging_dir/g' rules.mk
mkdir -p /tmp/openwrt/staging_dir
ln -sf /tmp/openwrt/staging_dir staging_dir

sed -i 's/$(TOPDIR)\/build_dir/\/tmp\/openwrt\/build_dir/g' rules.mk
mkdir -p /tmp/openwrt/build_dir
ln -sf /tmp/openwrt/build_dir build_dir

mkdir -p /tmp/openwrt/binary
ln -sf /tmp/openwrt/binary bin

mkdir -p /tmp/openwrt/download
mkdir -p /tmp/openwrt/mirror
mkdir -p /tmp/openwrt/ccache
mkdir -p /tmp/openwrt/log

##    添加你的自定义包    ##

# git_clone $url $path
