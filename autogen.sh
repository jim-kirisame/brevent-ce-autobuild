#!/bin/sh
KEY_PATH=https://github.com/android/platform_build/raw/master/target/product/security/

# 同步源码
echo "同步源码……"
git fetch

echo "查询远端版本"
# 版本查询
for i in `curl -s https://piebridge.me/br/`; do
    if [[ $i =~ href=\"(.*)\"\>br-(v[0-9]\.[0-9]\.[0-9][a-z]?)(.play)?\.apk ]]; then
        urls[0]="https://piebridge.me/br/${BASH_REMATCH[1]}"
        vers[0]="${BASH_REMATCH[2]}"
    fi
done

for i in `curl -s https://piebridge.me/br/archive/`; do
    if [[ $i =~ href=\"(.*)\"\>br-(v[0-9]\.[0-9]\.[0-9][a-z]?)(.play)?\.apk ]]; then
        urls=("${urls[@]}" "https://piebridge.me/br/archive/${BASH_REMATCH[1]}")
        vers=("${vers[@]}" "${BASH_REMATCH[2]}")
    fi
done

VERSIONS=$(git describe --tags `git rev-list --tags --max-count=10`)

for tag in $VERSIONS; do
    git checkout $tag
    SERVER_VER=$(cat brevent-server.txt)
    i=0
    for ver in ${vers[@]} ; do
        if [[ "$ver" = "$SERVER_VER" ]] ; then
            url=${urls[$i]};
            break 2;
        fi
        ((i++));
    done 
done


FILE_NAME=br-$ver.apk
echo "当前编译版本：$ver"

if [ ! -d tmp ]; then
    mkdir tmp 
fi
cd tmp

# 下载原版APP
if [ ! -f $FILE_NAME ]; then
    wget $url -O $FILE_NAME;
fi
if [ ! -f $FILE_NAME ]; then
    echo "作者尚未放出$ver版本的APK，请稍后再试。"
    echo "或手工下载$ver，将其重命名为$FILE_NAME后放到tmp文件夹下。"
    exit -1;
fi

cd ../

# 编译
gradle clean
gradle :brevent:aR

if [ ! -f ce.apk ]; then
    echo "编译失败，请查看上方日志以获取更多信息。"
    exit -1;
fi

# 添加黑域服务器
cd tmp
unzip $FILE_NAME classes2.dex
jar uf ../ce.apk classes2.dex
rm classes2.dex
cd ../

# 检测并下载签名密钥
if [ ! -e testkey.pk8 ]; then
    wget $KEY_PATH/testkey.pk8
fi
if [ ! -e testkey.x509.pem ]; then
    wget $KEY_PATH/testkey.x509.pem
fi

# 签名
if [ -f apksigner.jar ]; then
    java -jar apksigner.jar sign --key testkey.pk8 --cert testkey.x509.pem ce.apk
    mv ce.apk br-$ver-ce.apk
else
    echo "apksigner.jar 不存在，将不会对此APK进行签名。"
    mv ce.apk br-$ver-ce-unsigned.apk
fi


