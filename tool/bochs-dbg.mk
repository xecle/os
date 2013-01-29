#!/bin/bash
# script to build bochs-dbg
# libgtk2.0-dev needed

base=`pwd`
wget http://nchc.dl.sourceforge.net/project/bochs/bochs/2.6/bochs-2.6.tar.gz
tar xf bochs-2.6.tar.gz
mkdir build
mkdir root
cd build

../bochs-2.6/configure --enable-plugins --with-x11 --enable-debugger --enable-disasm \
	--enable-debugger-gui --enable-long-phy-address --enable-pci --enable-usb \
	CFLAGS="`pkg-config gtk+-2.0 --cflags --libs`" --prefix=/usr \
	CC=gcc-4.7 CXX=g++-4.7 CPP=cpp-4.7
make install DESTDIR=${base}/root

cd ${base}/root
size=`du . -c | tail -n 1 | grep -o "[0-9]*"`
mkdir DEBIAN
control="
Package: bochs-dbg
\nVersion: 2.6
\nArchitecture: `dpkg-architecture -qDEB_BUILD_ARCH`
\nMaintainer: Xecle <xecle@hotmail.com>
\nInstalled-Size: ${size}
\nDepends: libasound2 (>> 1.0.24.1), libc6 (>= 2.11), libgcc1 (>= 1:4.1.1), libltdl7 (>= 2.4), libstdc++6 (>= 4.1.1) 
\nSuggests: debootstrap, grub-rescue-pc, gcc | c-compiler, libc-dev
\nSection: misc
\nPriority: extra
\nHomepage: http://bochs.sourceforge.net/
\nDescription: IA-32 PC emulator Bochs debug version
\n Bochs is a highly portable free IA-32 (x86) PC emulator written in C++, that
\n runs on most popular platforms. It includes emulation of the Intel x86 CPU,
\n common I/O devices, and a custom BIOS.
\n .
\n Bochs is capable of running most operating systems inside the emulation
\n including GNU, GNU/Linux, *BSD, FreeDOS, MSDOS and Windows 95/NT."

echo -e ${control} > DEBIAN/control
find usr/ -type f -exec md5sum {} + > DEBIAN/md5sums

cd ${base}
dpkg -b root/ bochs-dbg-2.6.deb
rm -rf root build bochs-2.6
