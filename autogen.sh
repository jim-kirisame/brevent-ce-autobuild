KEY_PATH=https://github.com/android/platform_build/raw/master/target/product/security/

# 同步源码
git fetch
VERSION=$(git describe --tags `git rev-list --tags --max-count=1`)  
git checkout $VERSION

# 版本查询
SERVER_VER=$(cat brevent-server.txt)
FILE_NAME=br-$SERVER_VER.apk

if [ ! -d tmp ]; then
    mkdir tmp 
fi
cd tmp

# 下载原版APP
if [ ! -f $FILE_NAME ]; then
    wget https://piebridge.me/br/$FILE_NAME
fi
if [ ! -f $FILE_NAME ]; then
    wget https://piebridge.me/br/archive/$FILE_NAME
fi
if [ ! -f $FILE_NAME ]; then
    echo "作者尚未放出$SERVER_VER版本的APK，请稍后再试。"
    echo "或手工下载$SERVER_VER，将其重命名为$FILE_NAME后放到tmp文件夹下。"
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
    mv ce.apk br-$VERSION-ce.apk
else
    echo "apksigner.jar 不存在，将不会对此APK进行签名。"
    mv ce.apk br-$VERSION-ce-unsigned.apk
fi


