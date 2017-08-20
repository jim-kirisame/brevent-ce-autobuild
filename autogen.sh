KEY_PATH=https://github.com/android/platform_build/raw/master/target/product/security/

# 同步源码
git fetch
VERSION=$(git describe --tags `git rev-list --tags --max-count=1`)  
git checkout $VERSION

# 编译
gradle clean
gradle :brevent:aR


SERVER_VER=$(cat brevent-server.txt)
FILE_NAME=br-$SERVER_VER.apk
mkdir tmp 
cd tmp

# 添加黑域服务器
if [ ! -f $FILE_NAME ]; then
    wget https://piebridge.me/br/archive/$FILE_NAME
fi
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
    mv ce.apk br-$VERSION-ce.apk
else
    echo "apksigner.jar 不存在，将不会对此APK进行签名。"
    mv ce.apk br-$VERSION-ce-unsigned.apk
fi

rm -rf tmp
