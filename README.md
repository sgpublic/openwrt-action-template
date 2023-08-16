# OpenWrt-Action

## 如何使用

使用此仓库模板创建您的仓库，您需要修改以下文件：

+ openwrt-detail.sh

  此文件定义你想使用的

+ script/diy-part1.sh

  此文件为自定义第一部分，主要进行插件包、主题包拉取，以及一些其他编译前准备，在 `./scripts/feeds update` 前执行。

  脚本内定义了函数 `git_clone`，此函数在目录存在时拉取最新 commit，不存在时执行 clone，使用方式如下：

  ```shell
  git_clone <仓库链接> <保存路径>
  ```

  脚本内还编写了修改标准目录的相关命令，作用为缓存下载、编译结果以加速二次编译，仅适用于官方仓库，优先适配最新 release，若不需要注释掉即可。

+ sript/diy-part2.sh

  此文件为自定义第二部分，主要进行编译前自定义配置，在 `./scripts/feeds install` 后、`make menuconfig` 或 `make defconfig` 前执行。

+ config/origin.config

  此文件为编译配置，主要定义编译时所有细节，请在使用 action 编译前，在本机使用 `make menuconfig` 完成配置之后，将 `.config` 文件内容覆盖到此文件。

您还需要执行以下操作：

+ 添加 TOKEN

  您需要为您的仓库添加您的 GitHub Token，具体而言：Setting -> Secrets and variables -> Actions -> New repository secret，然后 Name 填写为 `TOKEN`，Secret 填写为您的 GitHub Token，关于如何生成 Token 请参阅：[管理个人访问令牌 - GitHub 文档](https://docs.github.com/zh/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#创建-personal-access-token-classic)，您至少需要勾选：gist、repo、workflow。

最后，您可以在 `Actions` 中开始编译您的固件。

## 本机编译

若您想要在本地执行编译，您可以使用 `./script/local_builder.sh` 脚本一键编译，此脚本仅在 Debian 11 上完成测试。

具体而言：

1. 将您使用此模板仓库创建的仓库克隆到本地（后称为“仓库目录”），使用 `ln -s` 创建软链接，将仓库根目录的 `build.sh` 链接到您为 OpenWrt 编译准备的工作目录（后称为“工作目录”）根目录下。
2. 修改 `build.sh` 内的 `WORK_ROOT` 变量为您的仓库目录。
3. cd 到您的工作目录，直接执行 `./build` 即可开始编译。

脚本执行过程中会询问以下问题：

+ Do you need to initialize your Linux?

  默认 `n`，定义是否需要为您安装 OpenWrt 编译所需要的相关依赖。

+ Do you want to use git cache? If you select No, ite will be deleted.

  默认 `y`，定义是否使用 openwrt 仓库缓存，否则删除缓存重新 clone。

+ Do you want to use build cache? If you select No, it will be deleted.

  默认 `y`，定义是否保留编译缓存，否则删除编译缓存。

+ Do you need to change the config file?

  默认 `n`，定义是否修改配置，是则执行 `make menuconfig`，否则执行 `make defconfig`。
