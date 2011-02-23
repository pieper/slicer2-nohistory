#!/bin/sh
# \
exec tclkitsh "$0" ${1+"$@"}

#
# make-launchers.tcl
#

set __comment {

    This script creates the stand-alone executables
    (starpacks) to startup slicer from an arbitrary directory.

    See www.equi4.com for info about starkits and starpacks.

}

set starkitRelease "-200403"

puts "making linux..."
exec tclkitsh starkit${starkitRelease}/sdx.kit wrap slicer2 -runtime starkit${starkitRelease}/tclkit-linux-x86
file rename -force slicer2 ../../slicer2-linux-x86

puts "making linux 64 bit..."
exec tclkitsh starkit${starkitRelease}/sdx.kit wrap slicer2 -runtime starkit${starkitRelease}/tclkit-linux-x86_64
file rename -force slicer2 ../../slicer2-linux-x86_64

puts "making solaris..."
exec tclkitsh starkit${starkitRelease}/sdx.kit wrap slicer2 -runtime starkit${starkitRelease}/tclkit-solaris-sparc
file rename -force slicer2 ../../slicer2-solaris-sparc

puts "making win32..."
exec  tclkitsh starkit${starkitRelease}/sdx.kit wrap slicer2.exe -runtime starkit${starkitRelease}/tclkit-win32.exe
file rename -force slicer2.exe ../../slicer2-win32.exe

puts "making darwin..."
exec  tclkitsh starkit${starkitRelease}/sdx.kit wrap slicer2.exe -runtime starkit${starkitRelease}/tclkit-darwin-ppc
file rename -force slicer2.exe ../../slicer2-darwin-ppc

puts "making darwin x86..."
exec  tclkitsh starkit${starkitRelease}/sdx.kit wrap slicer2.exe -runtime starkit${starkitRelease}/tclkit-darwin-x86
file rename -force slicer2.exe ../../slicer2-darwin-x86
