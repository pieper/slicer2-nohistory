
set __comment__ {

    tarup.tcl
    sp - 2003-05

    source this file into a running slicer2.6 to make a distribution 
    copy of slicer in a new directory based on the currently loaded Modules.
    The resulting program will be self-contained, without intermediate build
    files, CVS directories, and stripped of debugging symbols if possible.

    the tarup proc does the following steps:
    - makes the destination directory
    - copies the toplevel launcher and script
    - copies the tcl libs and binaries
    - copies the vtk libs and wrapping files
    - copies the itk libs
    - copies the slicerbase libs and wrapping files
    - copies each of the modules libs and wrapping files
    - removes CVS dirs that have been copied by accident
    - makes a .tar.gz or a .zip of the resulting distribution
    - if upload flag is not local, will upload to the na-mic.org server

    It does all this while taking into account platform differences in naming schemes
    and directory layouts.
    

    NB: remember to check that all shared libraries are included in the appropriate
    bin directory.  These should be placed in the VTK_DIR
    for windows visual studio 7, the following files are needed for a debug build:
        msvci70d.dll msvcp70d.dll msvcr70d.dll
    for linux redhat7.3
        ld-2.2.5.so libpthread-0.9.so libstdc++-3-libc6.2-2-2.10.0.so libstdc++.so.5  libgcc_s.so.1
    for solaris
        libgcc_s.so.1 libstdc++.so.3  
    for darwin
        nothing known
}

#
# returns a list of full paths to libraries that match the input list and that the vtk binary dynamically links to.
# doesn't work with ++ in the toMatch string
# on error, return an empty list
#
proc GetLinkedLibs { {toMatch {}} } {
    set liblist ""
    if {$toMatch == {}} {
        set toMatch [list "libgcc" "libstdc"]
    }
    switch $::tcl_platform(os) {
        "SunOS" -
        "Linux" {
            if {[catch {set lddpath [exec which ldd]} errMsg] == 1} {
                puts "Using which to find ldd is not working: $errMsg"
                return ""
            }
            # check if it says no first
            if {[regexp "^no ldd" $lddpath matchVar] == 1} {
                puts "No ldd in the path: $lddpath"
                return ""
            }
            set lddresults [exec $lddpath $::env(VTK_DIR)/bin/vtk]
        }
        "Darwin" {
            if {[catch {set lddpath [exec which otools]} errMsg] == 1} {
                puts "Using which to find otools is not working: $errMsg"
                return ""
            }
            # did it find it?
            if {[regexp "^no otools" $lddpath matchVar] == 1} {
                puts "No otools in the path: $lddpath"
                return ""
            }
            set lddpath "$lddpath -L"
            set lddresults [exec $lddpath $::env(VTK_DIR)/bin/vtk]
        }
        default { 
            puts "Unable to get libraries"
            return ""
        }
    }
    set lddlines [split $lddresults "\n"]
    foreach l $lddlines {
        # just grab anyones that match the input strings
        foreach strToMatch $toMatch {
            if {[regexp $strToMatch $l matchVar] == 1} {
                # puts "working on $l"
                foreach lddtoken [split $l] {
                    if {[file pathtype $lddtoken] == "absolute"} {
                        lappend liblist $lddtoken
                        if {$::Module(verbose)} {
                            puts "Found [lindex $liblist end]"
                        }
                        break
                    }
                }
            } else { 
                # puts "skipping $l" 
            }
        }
    }
    if {$::Module(verbose)} {
        puts "Got library list $liblist"
    }
    return $liblist
}

#
# print out usage information
#
proc tarup_usage {} {
    puts "Call 'tarup' to create a binary archive. Optional arguments:"
    puts "\tuploadFlag"
    puts "\t\tnightly, to upload to na-mic.org\\Slicer\\Downloads\\Nightly using curl, overwriting the last nightly file found there."
    puts "\t\tsnapshot (default), to upload to the Snapshots subdir for this os"
    puts "\t\trelease, to upload to the Release subdir for this os"
    puts "\t\tlocal, to make a local copy, no upload"
    puts "\tincludeSource\n\t\t0, to make a binary release (default)\n\t\t1, to include the cxx directories"
    puts "Example: tarup local 0"
    puts "Caveat: upload to na-mic.org is only allowed from trusted machines at BWH."
}

#
# copy files and create an archive, and upload
#
proc tarup { {uploadFlag "snapshot"} {includeSource 0} } {

    set cwd [pwd]
    cd $::env(SLICER_HOME)
puts "uploadFlag = $uploadFlag"

    # need to figure out which version of windows visual studio was used to build
    # so we need the original variables
    source $::env(SLICER_HOME)/slicer_variables.tcl

    ### Some simple error checking to see if the directories exist

    foreach dirname "VTK_DIR VTK_SRC_DIR ITK_BINARY_PATH TCL_BIN_DIR" {
       set dir $::env($dirname)
       eval { \
             if {[file exist $dir] == 0} { \
               puts "$dirname is set to $dir which does not exist"; \
               return
           } \ 
        }
    }

    set exe ""
    set suffix ""

    switch $::env(BUILD) {
        "solaris8" { set target solaris-sparc }
        "darwin-ppc" { set target darwin-ppc }
    "darwin-x86" { set target darwin-x86 }
        "redhat7.3" -
        "linux-x86" { set target linux-x86 }
        "linux-x86_64" { set target linux-x86 }
        "win32" { set target win32 ; set suffix -x86 ; set exe .exe}
        default {error "unknown build target $::env(BUILD)"}
    }

    set create_archive "true"
    if {$uploadFlag == "local"} {
        set do_upload "false"
    } else {
        set do_upload "true"
    }

    if { [info exists ::env(TMPDIR)] } {
        set archivedir [file normalize $::env(TMPDIR)]
    } else {
        if { [info exists ::env(TMP)] } {
            set archivedir [file normalize $::env(TMP)]
        } else {
            switch $::env(BUILD) {
                "solaris8" { set archivedir /tmp }
                "Darwin" - "darwin-ppc" - "darwin-x86" - "linux-x86" - "linux-x86_64" - "redhat7.3" { set archivedir /var/tmp }
                "win32" { set archivedir c:/Temp }
            }
        }
    }
    set date [clock format [clock seconds] -format %Y-%m-%d]
    if { $::tcl_platform(machine) == "x86_64" } {
        set suffix "_64"
    } 
    set archivedir $archivedir/slicer$::SLICER(version)-${target}${suffix}-$date


    puts "Creating distribution in $archivedir..."
    set skipMakingArchive 0
    if { [file exists $archivedir] } {
        set resp [tk_messageBox -message "$archivedir exists\nOkay: delete and regenerate it.\nCancel: tar/zip it up as is." -type okcancel]
        if { $resp == "cancel" } {
        #    return
            set skipMakingArchive 1
        } else {
        file delete -force $archivedir
        }
    }
    if {$skipMakingArchive == 0} {

    file mkdir $archivedir

    if { ![file writable $archivedir] } {
        error "can't write to $archivedir"
    }

    #
    # grab the top-level files - the launch executable and script
    # - add suffix, for example, _64 to name of launcher
    #
    puts " -- copying launcher files"
    file copy slicer2-$target$exe $archivedir/slicer2-$target$suffix$exe
    file copy launch.tcl $archivedir
    file copy slicer_variables.tcl $archivedir

    #
    # grab the copyright text file
    #
    file mkdir $archivedir/Doc
    file copy -force Doc/copyright $archivedir/Doc
    file copy -force Doc/library_copyrights $archivedir/Doc

    #
    # grab the tcl libraries and binaries
    # - take the entire bin and lib dirs, which leaves out demos and doc 
    #   if tcl came from the ActiveTcl distribution.
    # - this is big, but worth having so people can build better apps
    #   (this will include xml, widgets, table, soap, and many other handy things)
    #
    puts " -- copying tcl files"
    file mkdir $archivedir/Lib/$::env(BUILD)/tcl-build
    file copy -force $::env(TCL_LIB_DIR) $archivedir/Lib/$::env(BUILD)/tcl-build/lib
    file copy -force $::env(TCL_BIN_DIR) $archivedir/Lib/$::env(BUILD)/tcl-build/bin

    puts " -- copying teem files"
    if { $::env(BUILD) == "win32" } {
    # special case due to the teem-build dir structure on windows
    # - env(TEEM_BIN_DIR) ends in bin/$::env(VTK_BUILD_SUBDIR) on win32 and just bin on unix
        file mkdir $archivedir/Lib/$::env(BUILD)/teem-build/bin
        file copy -force $::env(TEEM_BIN_DIR) $archivedir/Lib/$::env(BUILD)/teem-build/bin
    } else {
        file mkdir $archivedir/Lib/$::env(BUILD)/teem-build
        file copy -force $::env(TEEM_BIN_DIR) $archivedir/Lib/$::env(BUILD)/teem-build
    }

    puts " -- copying sandbox files"
    file mkdir $archivedir/Lib/$::env(BUILD)/NAMICSandBox-build
    file copy -force $::env(SANDBOX_BIN_DIR) $archivedir/Lib/$::env(BUILD)/NAMICSandBox-build
    if { $::tcl_platform(os) == "Linux" && 
            $::tcl_platform(machine) == "x86_64" } {
        # special case to handle shared build on 64 bit
        file copy -force $::env(SANDBOX_BIN_DIR)/../Distributions/bin/libDistributions.so $archivedir/Lib/$::env(BUILD)/NAMICSandBox-build/bin
    }


    #
    # grab the vtk libraries and binaries
    # - bring in the tcl wrapping files and a specially modified
    #   version of pkgIndex.tcl that allows for relocatable packages
    #
    puts " -- copying vtk files"
    file mkdir $archivedir/Lib/$::env(BUILD)/VTK/Wrapping/Tcl
    set vtkparts { vtk vtkbase vtkcommon vtkpatented vtkfiltering
            vtkrendering vtkgraphics vtkhybrid vtkimaging 
            vtkinteraction vtkio vtktesting }
    foreach vtkpart $vtkparts {
        file copy -force $::env(VTK_SRC_DIR)/Wrapping/Tcl/$vtkpart $archivedir/Lib/$::env(BUILD)/VTK/Wrapping/Tcl
    }



    file mkdir $archivedir/Lib/$::env(BUILD)/VTK-build/Wrapping/Tcl
    switch $::tcl_platform(os) {
        "SunOS" -
        "Linux" - 
        "Darwin" {
            file copy -force $::env(VTK_DIR)/Wrapping/Tcl/pkgIndex.tcl $archivedir/Lib/$::env(BUILD)/VTK-build/Wrapping/Tcl
        }
        default { 
            file mkdir $archivedir/Lib/$::env(BUILD)/VTK-build/Wrapping/Tcl/$::env(VTK_BUILD_SUBDIR)
            file copy -force $::env(VTK_DIR)/Wrapping/Tcl/$::env(VTK_BUILD_SUBDIR)/pkgIndex.tcl $archivedir/Lib/$::env(BUILD)/VTK-build/Wrapping/Tcl/$::env(VTK_BUILD_SUBDIR)
        }
    }

    file mkdir $archivedir/Lib/$::env(BUILD)/VTK-build/bin
    switch $::tcl_platform(os) {
        "SunOS" -
        "Linux" { 
            set libs [glob $::env(VTK_DIR)/bin/*.so*]
            foreach lib $libs {
                file copy $lib $archivedir/Lib/$::env(BUILD)/VTK-build/bin
                set ll [file tail $lib]
                exec strip $archivedir/Lib/$::env(BUILD)/VTK-build/bin/$ll
            }
            file copy $::env(VTK_DIR)/bin/vtk $archivedir/Lib/$::env(BUILD)/VTK-build/bin
            file copy -force $::env(SLICER_HOME)/Scripts/slicer-vtk-pkgIndex.tcl $archivedir/Lib/$::env(BUILD)/VTK-build/Wrapping/Tcl/pkgIndex.tcl
        }
        "Darwin" {
            set libs [glob $::env(VTK_DIR)/bin/*.dylib]
            foreach lib $libs {
                file copy $lib $archivedir/Lib/$::env(BUILD)/VTK-build/bin
            }
            file copy $::env(VTK_DIR)/bin/vtk $archivedir/Lib/$::env(BUILD)/VTK-build/bin
            file copy -force $::env(SLICER_HOME)/Scripts/slicer-vtk-pkgIndex.tcl $archivedir/Lib/$::env(BUILD)/VTK-build/Wrapping/Tcl/pkgIndex.tcl
        }
        default { 
            file mkdir $archivedir/Lib/$::env(BUILD)/VTK-build/bin/$::env(VTK_BUILD_SUBDIR)
            set libs [glob $::env(VTK_DIR)/bin/$::env(VTK_BUILD_SUBDIR)/*.dll]
            foreach lib $libs {
                file copy $lib $archivedir/Lib/$::env(BUILD)/VTK-build/bin/$::env(VTK_BUILD_SUBDIR)
            }
            file copy -force $::env(SLICER_HOME)/Scripts/slicer-vtk-pkgIndex.tcl $archivedir/Lib/$::env(BUILD)/VTK-build/Wrapping/Tcl/$::env(VTK_BUILD_SUBDIR)/pkgIndex.tcl
        }
    }
    #
    # grab the shared libraries and put them in the vtk bin dir
    #
    puts " -- copying shared development libraries"
    set sharedLibDir $archivedir/Lib/$::env(BUILD)/VTK-build/bin
    set checkForSymlinks 1
    switch $::tcl_platform(os) {
      "SunOS" {
          set sharedLibs [GetLinkedLibs [list libgcc libstd]]
          if {$sharedLibs == ""} {
              set sharedLibs [list libgcc_s.so.1 libstdc++.so.3]
              set sharedSearchPath [split $::env(LD_LIBRARY_PATH) ":"]
          } else {
              set sharedSearchPath ""
              if {$::Module(verbose)} { puts "GetLinkedLibs returned $sharedLibs" }
          }
      }
      "Linux" {
#         set sharedLibs [list ld-2.2.5.so libpthread-0.9.so libstdc++-3-libc6.2-2-2.10.0.so]
          set sharedLibs [GetLinkedLibs [list libstdc libgcc_s]]
          if {$sharedLibs == ""} {
              set sharedLibs [list libstdc++-libc6.2-2.so.3 libstdc++.so.5 libgcc_s.so.1]
              set sharedSearchPath [split $::env(LD_LIBRARY_PATH) ":"]
          } else {
              set sharedSearchPath ""
          }
      }
      "Darwin" {
          set sharedLibs [list ]
          set sharedSearchPath [split $::env(DYLD_LIBRARY_PATH) ":"]
      }
      default {
          switch $::GENERATOR {
              "Visual Studio 7" {
                  set sharedLibs [list msvci70d.dll msvci70.dll msvcp70d.dll msvcp70.dll msvcr70d.dll msvcr70.dll]
              }
              "Visual Studio 7 .NET 2003" {
                  set sharedLibs [list msvcp71d.dll msvcp71.dll msvcr71d.dll msvcr71.dll]
              }
              default {
                  error "unknown build system for tarup: $GENERATOR"
              }
        
          }
          set sharedSearchPath [concat [split $::env(PATH) ";"] $::env(LD_LIBRARY_PATH)]
          set sharedLibDir $archivedir/Lib/$::env(BUILD)/VTK-build/bin/$::env(VTK_BUILD_SUBDIR)
          set checkForSymlinks 0
      }
    }
    set foundLibs ""
    foreach slib $sharedLibs { 
        if {$::Module(verbose)} { puts "LIB $slib"  }
        # don't copy if it's already in the archive dir (take the tail of the full path to slib)
        if {![file exists [file join $sharedLibDir [file tail $slib]]]} {
            set slibFound 0
            if {$sharedSearchPath == ""} {
                if {$::Module(verbose)} { puts "Should have fully qualified path from GetLinkedLibs for $slib" }
                lappend foundLibs $slib
                set slibFound 1
            }
            foreach spath $sharedSearchPath { 
                if {$::Module(verbose) && !$slibFound} { puts "checking dir $spath" }
                if {!$slibFound && [file exists [file join $spath $slib]]} { 
                    if {$::Module(verbose)} { puts "found $slib in dir $spath, copying to $sharedLibDir" }
                    lappend foundLibs [file join $spath $slib]
                    set slibFound 1
                }
            }
            if {!$slibFound} {
                puts "WARNING: $slib not found, tarup may be incomplete. Place it in one of these directories and rerun tarup: \n $sharedSearchPath"
                DevErrorWindow "WARNING: $slib not found, tarup may be incomplete. Place it in a directory in your search path and rerun tarup."
            }
        } else { 
            if {$::Module(verbose)} { puts "$slib is already in $sharedLibDir" } 
        }
    }
    foreach slib $foundLibs {
        # check if it's a symlink (but not on windows)
        if {$checkForSymlinks} {
            # at this point each one is a fully qualified path
            set checkpath $slib
            while {[file type $checkpath] == "link"} {
                # need to resolve it to a real file so that file copy will work
                set sympath [file readlink $checkpath]
                if {[file pathtype $sympath] == "relative"} {
                    # if the link is relative to the last path, take the dirname of the last one 
                    # and append the new path to it, then normalize it
                    set checkpath [file normalize [file join [file dirname $checkpath] $sympath]]
                }
            }
            # the links may have changed the name of the library file 
            # (ie adding minor version numbers onto the end)
            # so copy the new file into the old file name
            file copy $checkpath [file join $sharedLibDir [file tail $slib]]
            puts "\tCopied $checkpath to $sharedLibDir/[file tail $slib]" 
        } else {
            # copy it into the shared vtk bin dir
            file copy $slib  $sharedLibDir
            puts "\tCopied $slib to $sharedLibDir"
        }
        
    }

    #
    # grab the itk libraries 
    #
    puts " -- copying itk files"
    file mkdir $archivedir/Lib/$::env(BUILD)/Insight-build/bin

    switch $::tcl_platform(os) {
        "SunOS" -
        "Linux" { 
            set libs [glob -nocomplain $::env(ITK_BINARY_PATH)/bin/*.so]
            foreach lib $libs {
                file copy $lib $archivedir/Lib/$::env(BUILD)/Insight-build/bin
                set ll [file tail $lib]
                exec strip $archivedir/Lib/$::env(BUILD)/Insight-build/bin/$ll
            } 
        }
        "Darwin" {
            set libs [glob -nocomplain $::env(ITK_BINARY_PATH)/bin/*.dylib]
            foreach lib $libs {
                file copy $lib $archivedir/Lib/$::env(BUILD)/Insight-build/bin
            }
        }
        default { 
            file mkdir $archivedir/Lib/$::env(BUILD)/Insight-build/bin/$::env(VTK_BUILD_SUBDIR)
            set libs [glob -nocomplain $::env(ITK_BINARY_PATH)/bin/$::env(VTK_BUILD_SUBDIR)/*.dll]
            foreach lib $libs {
                file copy $lib $archivedir/Lib/$::env(BUILD)/Insight-build/bin/$::env(VTK_BUILD_SUBDIR)
            }
        }
    }


    #
    # grab the Base build and tcl
    #
    puts " -- copying SlicerBase files"
    file mkdir $archivedir/Base
    file copy -force Base/tcl $archivedir/Base
    if {$includeSource} {
        file copy -force Base/cxx $archivedir/Base
    }
    # get the servers directory
    file copy -force servers $archivedir
    file mkdir $archivedir/Base/Wrapping/Tcl/vtkSlicerBase
    file copy Base/Wrapping/Tcl/vtkSlicerBase/pkgIndex.tcl $archivedir/Base/Wrapping/Tcl/vtkSlicerBase
    file copy Base/Wrapping/Tcl/vtkSlicerBase/vtkSlicerBase.tcl $archivedir/Base/Wrapping/Tcl/vtkSlicerBase
    switch $::tcl_platform(os) {
        "SunOS" -
        "Linux" { 
            file mkdir $archivedir/Base/builds/$::env(BUILD)/bin
            set libs [glob Base/builds/$::env(BUILD)/bin/*.so]
            foreach lib $libs {
                file copy $lib $archivedir/Base/builds/$::env(BUILD)/bin
                set ll [file tail $lib]
                exec strip $archivedir/Base/builds/$::env(BUILD)/bin/$ll
            }
        }
        "Darwin" {
            file mkdir $archivedir/Base/builds/$::env(BUILD)/bin
            set libs [glob Base/builds/$::env(BUILD)/bin/*.dylib]
            foreach lib $libs {
                file copy $lib $archivedir/Base/builds/$::env(BUILD)/bin
            }
        }
        default { 
            file mkdir $archivedir/Base/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_SUBDIR)
            set libs [glob Base/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_SUBDIR)/*.dll]
            foreach lib $libs {
                file copy $lib $archivedir/Base/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_SUBDIR)
            }
        }
    }

    #
    # grab all the slicer Modules
    # - the ones currently loaded are the ones in env(SLICER_MODULES_TO_REQUIRE)
    # - they are either in env(SLICER_HOME)/Modules or in a directory
    #   in the list env(SLICER_MODULES)
    #
    puts " -- copying Modules"
    foreach mod $::env(SLICER_MODULES_TO_REQUIRE) {

        set moddir ""
        if { [file exists $::env(SLICER_HOME)/Modules/$mod] } {
            set moddir $::env(SLICER_HOME)/Modules/$mod
        } else {
            foreach m $::env(SLICER_MODULES) {
                if { [file exists $m/$mod] } {
                    set moddir $m/$mod
                    break
                }
            }
        }
        if { $moddir == "" } {
            puts stderr "can't find source directory for $mod -- skipping"
            continue
        }

        puts "    $mod"

        set moddest $archivedir/Modules/$mod
        file mkdir $moddest
        if { [file exists $moddir/tcl] } {
            file copy -force $moddir/tcl $moddest
        } else {
            # for a Modules that use an uppercase tcl directory name
            if { [file exists $moddir/Tcl] } {
                file copy -force $moddir/Tcl $moddest
            }
        }
        if {$includeSource} {
            if { [file exists $moddir/cxx] } {
                file copy -force $moddir/cxx $moddest
            }
        }
        file mkdir $moddest/Wrapping/Tcl/$mod
        file copy $moddir/Wrapping/Tcl/$mod/pkgIndex.tcl $moddest/Wrapping/Tcl/$mod
        file copy $moddir/Wrapping/Tcl/$mod/$mod.tcl $moddest/Wrapping/Tcl/$mod
        switch $::tcl_platform(os) {
            "SunOS" -
            "Linux" { 
                file mkdir $moddest/builds/$::env(BUILD)/bin
                set libs [glob -nocomplain $moddir/builds/$::env(BUILD)/bin/*.so]
                foreach lib $libs {
                    file copy $lib $moddest/builds/$::env(BUILD)/bin
                    set ll [file tail $lib]
                    exec strip $moddest/builds/$::env(BUILD)/bin/$ll
                }
            }
            "Darwin" {
                file mkdir $moddest/builds/$::env(BUILD)/bin
                set libs [glob -nocomplain $moddir/builds/$::env(BUILD)/bin/*.dylib]
                foreach lib $libs {
                    file copy $lib $moddest/builds/$::env(BUILD)/bin
                }
            }
            default { 
                file mkdir $moddest/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_SUBDIR)
                set libs [glob -nocomplain $moddir/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_SUBDIR)/*.dll]
                foreach lib $libs {
                    file copy $lib $moddest/builds/$::env(BUILD)/bin/$::env(VTK_BUILD_SUBDIR)
                }
            }
        }
        if { [file exists $moddir/images] } {
            file copy -force $moddir/images $moddest
        }
        if { [file exists $moddir/data] } {
            file copy -force $moddir/data $moddest
        }

       

        # TODO: these as special cases for the birn Query Atlas and 
        # should be generalized (maybe a manifest file or something)
        if { [file exists $moddir/java] } {
            file copy -force $moddir/java $moddest
        }
        if { [file exists $moddir/talairach] } {
            file copy -force $moddir/talairach $moddest
        }
    }

    #
    # remove any stray CVS dirs in target
    #
    foreach cvsdir [rglob $archivedir CVS] {
        file delete -force $cvsdir
    }
} 
# end of skipping making the archive

    #
    # make an archive of the new directory at the same level
    # with the destination
    #
    if { $create_archive == "true" } {
        cd $archivedir/..

        set archroot [file tail $archivedir]

        # make and save the archive file name and extension for unix systems, reset for win32
        set curlfile [file dirname $archivedir]/$archroot.tar.gz
        set curldestext ".tar.gz"
        switch $::tcl_platform(os) {
            "SunOS" {
                puts " -- making $archroot.tar.gz from $archivedir"
                #exec gtar cvfz $archroot.tar.gz $archroot
                exec tar cfE $archroot.tar $archroot
                exec gzip -f $archroot.tar
            }
            "Linux" -
            "Darwin" {
                puts " -- making $archroot.tar.gz"
                exec tar cfz $archroot.tar.gz $archroot
            }
            default { 
                puts " -- making $archroot.zip"
                exec zip -r $archroot.zip $archroot
                set curlfile $archroot.zip
                set curldestext ".zip"
            }
        }
    }

    if { $do_upload == "true" } {

        set namic_url "http://www.na-mic.org/Slicer/Upload.cgi"
        switch $uploadFlag {
            "nightly" {
                set curldest "${namic_url}/Nightly/slicer$::SLICER(version)-${target}${suffix}${curldestext}"
            }
            "snapshot" {
                set curldest "${namic_url}/Snapshots/$::env(BUILD)/slicer$::SLICER(version)-${target}${suffix}-${date}${curldestext}"
            }
            "release" {
                set curldest "${namic_url}/Release/$::env(BUILD)/slicer$::SLICER(version)-${target}${suffix}-${date}${curldestext}"
            }
            default {
                puts "Invalid uploadFlag \"$uploadFlag\", setting curldest to snapshot value"
                set curldest "${namic_url}/Snapshots/$::env(BUILD)/slicer$::SLICER(version)-${target}${suffix}-${date}${curldestext}"
            }
        }

        puts " -- upload $curlfile to $curldest"
        switch $::tcl_platform(os) {
            "SunOS" -
            "Linux" {
                exec xterm -e curl --connect-timeout 120 --silent --show-error --upload-file $curlfile $curldest
            }
            "Darwin" {
                exec /usr/X11R6/bin/xterm -e curl --connect-timeout 120 --silent --show-error --upload-file $curlfile $curldest
            }
            default { 
                exec curl --connect-timeout 120 --silent --show-error --upload-file $curlfile $curldest
            }
        }
        puts "See http://www.na-mic.org/Slicer/Download, in the $uploadFlag directory, for the uploaded file."
        # puts "curlfile is $curlfile"
        # puts "curldest is $curldest"
    } else {
        puts "Archive complete: ${curlfile}"
    }

    cd $cwd

    puts "tarup complete."
}


#
# recursive glob - find all files and/or directories in or below 'path'
# that match 'pattern'
# - note, if a directory matches, it's contents are not searched for further matches
#
proc rglob { path {pattern *} } {

    if { [string match "*/$pattern" $path] } {
        return $path
    } 
    if { ![file isdirectory $path] } {
        return ""
    } else {
        set vals ""
        foreach p [glob -nocomplain $path/*] {
            set v [rglob $p $pattern]
            if { $v != "" } {
                set vals [concat $vals $v]
            }
        }
        return $vals
    }
}

tarup_usage
