#!/bin/sh

##### config #####

CPU_ARCH=x64							# Win32 or x64
PLATFORM="Visual Studio 15 2017 Win64"	# target platform
BOOST_VER=1_69_0						# boost version

# path to MSBuild.exe
export PATH=$PATH:"/cygdrive/c/Program Files (x86)/Microsoft Visual Studio/2017/Community/MSBuild/15.0/Bin"

echo "##### check necessary cmd #####"

function chk_cmd(){
	if ! which $1 > /dev/null 2>&1; then
		echo "install $1 first."
		exit
	fi
}

chk_cmd python
chk_cmd curl
chk_cmd git
chk_cmd unzip

echo "##### download libraries #####"

if [ ! -d hyperscan ]; then git clone https://github.com/intel/hyperscan.git; fi

function download(){
	if [ ! -e `basename $1` ]; then curl -L -O $1; fi
}

download http://www.colm.net/files/ragel/ragel-6.10.tar.gz
download https://dl.bintray.com/boostorg/release/${BOOST_VER//_/.}/source/boost_${BOOST_VER}.tar.bz2
download https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.bz2
download https://github.com/Kitware/CMake/releases/download/v3.13.2/cmake-3.13.2-win64-x64.zip
download https://www.sqlite.org/2018/sqlite-amalgamation-3260000.zip

echo "##### extract #####"

if [ ! -d cmake-3.13.2-win64-x64 ]; then unzip -q cmake-3.13.2-win64-x64.zip; fi
if [ ! -d hyperscan/sqlite3 ]; then
	unzip -q sqlite-amalgamation-3260000.zip
	mv sqlite-amalgamation-3260000 hyperscan/sqlite3
fi
if [ ! -d ragel-6.10 ]; then tar zxf ragel-6.10.tar.gz; fi

cd hyperscan
if [ ! -d boost_${BOOST_VER} ]; then tar jxf ../boost_${BOOST_VER}.tar.bz2; fi
if [ ! -d pcre-8.41 ]; then tar jxf ../pcre-8.41.tar.bz2; fi

if ! which ragel > /dev/null 2>&1; then
	echo "##### install ragel #####"
	
	pushd ../ragel-6.10
	./configure
	make
	make install
	popd
fi

echo "##### build #####"

CXXFLAGS="/MP /FS" CFLAGS="/MP /FS" \
../cmake-3.13.2-win64-x64/bin/cmake -G "$PLATFORM" -DBOOST_ROOT=`cygpath -w $PWD`/boost_${BOOST_VER}/..

for config in Release Debug; do
	nice -n 10 MsBuild.exe ALL_BUILD.vcxproj /t:build /p:Configuration=$config
	mkdir -p lib/$CPU_ARCH.$config
	mv lib/*.* lib/$CPU_ARCH.$config
done
