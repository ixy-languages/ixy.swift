apt-get update
apt-get install software-properties-common
apt-add-repository "deb http://deb.debian.org/debian stretch-backports main contrib non-free"
apt-get update
apt-get install clang-6.0 libpython2.7 libcurl3 libicu-dev
wget https://swift.org/builds/swift-4.1.3-release/ubuntu1610/swift-4.1.3-RELEASE/swift-4.1.3-RELEASE-ubuntu16.10.tar.gz
tar xzf swift-4.1.3-RELEASE-ubuntu16.10.tar.gz
export PATH=/root/swift-4.1.3-RELEASE-ubuntu16.10/usr/bin:"${PATH}"
export PATH=/usr/lib/llvm-6.0/bin:"${PATH}"

