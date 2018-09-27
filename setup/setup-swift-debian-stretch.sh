SWIFT_PACKAGE="swift-4.2-RELEASE-ubuntu18.04"
SWIFT_URL="https://swift.org/builds/swift-4.2-release/ubuntu1804/swift-4.2-RELEASE/swift-4.2-RELEASE-ubuntu18.04.tar.gz"

PREV_WD="$(pwd)"
pathadd() {
	if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
		export PATH="$1:${PATH}"
	fi
}

# Install Necessary Swift Components
apt-get update
apt-get -y install software-properties-common
apt-add-repository "deb http://deb.debian.org/debian stretch-backports main contrib non-free"
apt-get update
apt-get -y install clang-6.0 libpython2.7 libcurl3 libicu-dev

# Install unstable libicu60
if [-f /etc/apt/preferences.d/swift-unstable-libicu ]
then
	echo "apt pinning already installed. skipping"
else
	cat <<EOT>> /etc/apt/preferences.d/swift-unstable-libicu
Package: *
Pin: release a=stable
Pin-Priority: 700

Package: *
Pin: release a=unstable
Pin-Priority: 600
EOT
fi

apt-get update
apt-get install libicu60


# Create Swift Folder
cd /root/
mkdir .swift
cd .swift

# Download and Unpack
wget $SWIFT_URL
tar xzf "${SWIFT_PACKAGE}.tar.gz"
if [-f /root/.swift/current ]
then
	rm /root/.swift/current
	echo "removed old symlink"
fi
ln -s /root/.swift/"${SWIFT_PACKAGE}" /root/.swift/current

pathadd /root/.swift/current/usr/bin
pathadd /usr/lib/llvm-6.0/bin
