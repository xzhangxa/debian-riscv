#!/bin/bash

DEVDIR=$(cd `dirname $0` && pwd)
BUILD_PATH=$DEVDIR/cpu2017

CURRENT_DATE=$(date +"%Y%m%d-%H%M%S")
LOGFILE=$DEVDIR/buildlog-$CURRENT_DATE.log

sudo apt install -y build-essential gfortran

echo "`date +%H:%M:%S` : Start CPU SPEC 2017 Extracting"  | tee -a $LOGFILE

if [ -e cpu2017-1.1.8.tar.xz ]
then
	if [ -d $SBUILD_PATH ]
	then
		rm -rf $BUILD_PATH
	fi
    echo "Extracting cpu2017-1.1.8.tar.xz ..." | tee -a $LOGFILE
	mkdir -p $BUILD_PATH
	tar -xf cpu2017-1.1.8.tar.xz -C $BUILD_PATH
else
    echo "cpu2017-1.1.8.tar.xz doesn't exist. Please copy the file to $DEVDIR." | tee -a $LOGFILE
	exit
fi

echo "`date +%H:%M:%S` : Start CPU SPEC 2017 Patching"  | tee -a $LOGFILE

cd "$BUILD_PATH"
git init && git add -A && git commit -m "SPEC CPU 2017" && git am $DEVDIR/patch/2017/*.patch

export CFLAGS="$CFLAGS -fcommon"
export PERLFLAGS="-A libs=-lm -A libs=-ldl -A libs=-lc -A ldflags=-lm -A cflags=-lm -A ccflags=-lm -Dlibpth=/usr/lib/riscv64-linux-gnu -A ccflags=-fwrapv"
export SPEC="$BUILD_PATH"
export SKIPTOOLSINTRO=1

cd "$BUILD_PATH/tools/src"
./buildtools 2>&1 | tee -a $LOGFILE

cd "$BUILD_PATH"
./bin/packagetools linux-riscv64 2>&1 | tee -a $LOGFILE

cd "$BUILD_PATH"
cp "$DEVDIR/config/2017/linux-riscv64-unmatched.cfg" "$BUILD_PATH/config/linux-riscv64-unmatched.cfg"
source ./shrc
runcpu --config=linux-riscv64-unmatched.cfg --action=build --tune=base all
