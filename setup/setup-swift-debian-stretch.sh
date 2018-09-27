SWIFT_PACKAGE="swift-4.2-RELEASE-ubuntu18.04"
SWIFT_URL="https://swift.org/builds/swift-4.2-release/ubuntu1804/swift-4.2-RELEASE/swift-4.2-RELEASE-ubuntu18.04.tar.gz"

PREV_WD="$(pwd)"

# Install Necessary Swift Components
apt-get update
apt-get -y install software-properties-common
apt-add-repository "deb http://deb.debian.org/debian stretch-backports main contrib non-free"
apt-get update
apt-get -y install clang-6.0 libpython2.7 libcurl3



# Create Swift Folder
cd /root/
mkdir .swift
cd .swift

wget http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu55_55.1-7_amd64.deb
dpkg -i libicu55_55.1-7_amd64.deb
rm libicu55_55.1-7_amd64.deb

# Download and Unpack
wget $SWIFT_URL
tar xzf "${SWIFT_PACKAGE}.tar.gz"
if [ -f /root/.swift/current ]
then
	rm /root/.swift/current
	echo "removed old symlink"
fi
ln -s /root/.swift/"${SWIFT_PACKAGE}" /root/.swift/current

