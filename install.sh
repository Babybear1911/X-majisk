##########################################################################################
#
# Magisk 模块安装脚本
#
##########################################################################################
##########################################################################################
#
# 说明:
#
# 1. 将你的文件放入system文件夹里(请删除占位文件，即system文件夹下的'placeholder'文件)
# 2. 在'module.prop'文件中填写你的模块信息
# 3. 在此文件中配置和实现回调
# 4. 如果需要引导脚本（开机脚本），请将它们添加到common/post-fs-data.sh或common/service.sh中
# 5. 将附加或修改的系统属性添加到common/system.prop中
#
# 6. 本文档中翻译存在不明确的词：
#        installation framework——安装机制（安装框架似乎更好）
#        boot_scripts——引导脚本（启动脚本，开机脚本）
#        print——打印
#        functions——函数（功能）
#
##########################################################################################

##########################################################################################
# 配置
##########################################################################################

# 如果*不*希望magisk为您装载任何文件，请设置为true。
# 大多数模块都将用到此功能（即*不*会将此标志设置为true）
SKIPMOUNT=false

# 如果需要加载system.prop，请设置为true。
PROPFILE=false

# 如果需要post-fs-data脚本，则设置为true
POSTFSDATA=false

# 如果需要late_start service脚本，则设置为true
LATESTARTSERVICE=false

##########################################################################################
# 替换列表
##########################################################################################

# 列出你想在系统中直接替换的所有目录
# 查看文档以了解您为什么需要此功能

# 按以下格式构建（写）你的替换列表
# 下面是一个示例：
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# 在下面构建（写）你的替换列表
REPLACE="
"

##########################################################################################
#
# 函数回调
#
# 安装机制（安装框架）将调用下方函数。
# 您没有修改'update-binary'文件的能力，这是您实现自定义的唯一方法
# 安装的进行是通过执行这些函数（通过这些函数的执行来进行安装）
#
# 运行回调时，安装机制将确保Magisk内部的busybox路径*已预先加载*到总路径，
# 所以所有常用命令应该都存在。
# 此外，安装机制还将确保/data、/system、/vendor被正确地挂载。
#
##########################################################################################
##########################################################################################
#
# 安装框架将导出一些变量和函数。
# 您应该使用这些变量和函数来进行安装。
#
# !请不要使用任何Magisk的内部路径，因为它们不是公共API。
# !请不要在util_functions.sh中使用其他函数，因为它们也不是公共API。
# !不能保证非公共API在版本之间保持兼容性。
#
# 可用变量:
#
# MAGISK_VER (string):当前已安装Magisk的版本的字符串(字符串形式的Magisk版本)
# MAGISK_VER_CODE (int):当前已安装Magisk的版本的代码(整型变量形式的Magisk版本)
# BOOTMODE (bool):如果模块当前安装在Magisk Manager中，则为true。
# MODPATH (path):你的模块应该被安装到的路径
# TMPDIR (path):一个你可以临时存储文件的路径
# ZIPFILE (path):模块的安装包（zip）的路径
# ARCH (string): 设备的体系结构。其值为arm、arm64、x86、x64之一
# IS64BIT (bool):如果$ARCH(上方的ARCH变量)为arm64或x64，则为true。
# API (int):设备的API级别（Android版本）
#
# 可用函数:
#
# ui_print <msg>
#     打印(print)<msg>到控制台
#     避免使用'echo'，因为它不会显示在定制recovery的控制台中。
#
# abort <msg>
#     打印错误信息<msg>到控制台并终止安装
#     避免使用'exit'，因为它会跳过终止的清理步骤
#
# set_perm <target> <owner> <group> <permission> [context]
#     如果[context]为空,则它默认为"u:object_r:system_file:s0"
#     此函数是以下命令的简写
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     如果[context]为空,则它默认为"u:object_r:system_file:s0"
#     对于<directory>中的所有文件，它将调用：
#       set_perm file owner group filepermission context
#     对于<directory>中的所有目录（包括其自身），它将调用：
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# 如果需要引导脚本（boot scripts，即开机脚本）,请不要使用常规引导脚本(post-fs-data.d/service.d)
# *仅*使用模块脚本，因为它关联到模块状态(删除/禁用)，并且可以保证在以后的Magisk版本中保持
# 相同的行为。
# 通过设置在上面的“配置”部分中的标志(true/false)来启用引导脚本。
##########################################################################################

# 设置安装模块时要显示的内容

print_modname() {
  ui_print "******************************"
  ui_print "        Magisk 模块示例        "
  ui_print "******************************"
}

# 在on_install中复制/解压缩模块的文件到$MODPATH

on_install() {
  # 以下代码默认实现:将$ZIPFILE/system提取到$MODPATH
  # 可以自行扩展/更改代码逻辑
  ui_print "- 正在提取模块文件"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
}

# 以下是权限设置
# 这个函数将在on_install完成后调用
# 只有某些特殊文件需要特定权限，大多数情况下使用默认权限就即可

set_permissions() {
  # 下方代码是默认权限设置规则，请*不要*删除
  set_perm_recursive $MODPATH 0 0 0755 0644

  # 例子:
  # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
  # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
}

# 您可以添加更多函数（功能）来协助您的自定义脚本代码
