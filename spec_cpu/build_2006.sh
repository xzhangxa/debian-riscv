#!/bin/bash

DEVDIR=$(cd `dirname $0` && pwd)
BUILD_PATH=$DEVDIR/cpu2006

CURRENT_DATE=$(date +"%Y%m%d-%H%M%S")
LOGFILE=$DEVDIR/buildlog-2006-$CURRENT_DATE.log

sudo apt install -y build-essential gfortran

echo "`date +%H:%M:%S` : Start CPU SPEC 2006 Extracting"  | tee -a $LOGFILE

if [ -e cpu2006-1.2.tar.xz ]; then
	if [ -d $BUILD_PATH ]; then
		rm -rf $BUILD_PATH
	fi
    echo "Extracting cpu2006-1.2.tar.xz ..." | tee -a $LOGFILE
	mkdir -p $BUILD_PATH
	tar -xf cpu2006-1.2.tar.xz -C $BUILD_PATH
else
    echo "cpu2006-1.2.tar.xz doesn't exist. Please copy the file to $DEVDIR." | tee -a $LOGFILE
    exit
fi

echo "`date +%H:%M:%S` : Start CPU SPEC 2006 Patching"  | tee -a $LOGFILE

cd "$BUILD_PATH"
git init && git add -A && git commit -m "SPEC CPU 2006" && git am $DEVDIR/patch/2006/*.patch

echo "`date +%H:%M:%S` : Start CPU SPEC 2006 Building RISC-V tool linux-riscv64"  | tee -a $LOGFILE

export CFLAGS="$CFLAGS -fcommon"
export PERLFLAGS="-A libs=-lm -A libs=-ldl -A libs=-lc -A ldflags=-lm -A cflags=-lm -A ccflags=-lm -Dlibpth=/usr/lib/riscv64-linux-gnu -A ccflags=-fwrapv"

cd "$BUILD_PATH/tools/src"
./buildtools 2>&1 | tee -a $LOGFILE

export SPEC="$BUILD_PATH"
cd "$BUILD_PATH"
cp "$DEVDIR/config/2006/linux-riscv64-unmatched.cfg" "$BUILD_PATH/config/linux-riscv64-unmatched.cfg"
source ./shrc
runspec --config=linux-riscv64-unmatched.cfg --action=build --tune=base all
