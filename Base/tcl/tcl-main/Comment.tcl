#=auto==========================================================================
#   Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Comment.tcl,v $
#   Date:      $Date: 2006/04/19 21:38:23 $
#   Version:   $Revision: 1.24 $
# 
#===============================================================================
# FILE:        Comment.tcl
# PROCEDURES:  
#   CommentInit verbose
#   PrintCopyright fid isTcl verbose
#   ProcessFile file verbose
#   CopyrightFile filename verbose
#   CommentFile filename verbose
#   Polish data
#   ProcessModule modpath verbose
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC CommentInit
# Sets a global variable for the copyright file name
# .ARGS
# int verbose set this flag to 1 if you want to see debugging print outs, default is 0
# .END
#-------------------------------------------------------------------------------
proc CommentInit { {verbose 0} } {
    global Comment

    if {[info exist ::env(SLICER_HOME)] == 0} {
        if {[info exist ::SLICER_HOME] == 1} { 
            set ::env(SLICER_HOME) $::SLICER_HOME
        } else {
            set cwd [pwd]
            cd [file dirname [info script]]
            cd ..
            cd ..
            cd ..
            cd ..
            set ::env(SLICER_HOME) [pwd]
            
            cd $cwd
        }
        if {$verbose} {
            puts "reset env slicer home to $::env(SLICER_HOME)"
        }
    }
    set Comment(copyrightFileName) [file join $::env(SLICER_HOME) Doc copyright copyrightShort.txt]

    # read in the copyright
    if {[catch {set fid [open $Comment(copyrightFileName) r]} errmsg] == 1} {
        puts "CommentInit: error opening file $Comment(copyrightFileName): $errmsg"
        set Comment(copyright) "(c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved."
    } else {
        set Comment(copyright) [read $fid]
        close $fid
        # now revert the cvs key words to blank
        regexp {[ ]*[$]RCSfile([^$]*)[$]} $Comment(copyright) matchvar s1
        regsub $s1 $Comment(copyright) "" Comment(copyright)

        regexp {[ ]*[$]Date([^$]*)[$]} $Comment(copyright) matchvar s1
        regsub $s1 $Comment(copyright) "" Comment(copyright)

        regexp {[ ]*[$]Revision([^$]*)[$]} $Comment(copyright) matchvar s1
        regsub $s1 $Comment(copyright) "" Comment(copyright)
    }
    # check to see that the copyright year is current
    set thisYear [clock format [clock seconds] -format %Y]
    if {[regexp {\(c\) Copyright (\d\d\d\d) .*} $Comment(copyright) matchVar yr] == 1} {
        if {$verbose} {
            puts "Year in file = $yr, this year = $thisYear"
        }
        if {$yr != $thisYear} {
            puts "Warning: updating year in copyright text to $thisYear from $yr"
            regsub -all " $yr " $Comment(copyright) " $thisYear " Comment(copyright)
        }
    }

    # can now call split on line breaks to get each line
    if {$verbose} {
        puts "got copyright:\n$Comment(copyright)"
    }
}

#-------------------------------------------------------------------------------
# .PROC PrintCopyright
#
# Prints the copyright notice on the top of the file.
# .ARGS
# str fid  File ID returned from opening the file
# int isTcl 1 if this is a TCL file, and 0 otherwise
# int verbose set this flag to 1 to see debugging print outs, defaults to 0
# .END
#-------------------------------------------------------------------------------
proc PrintCopyright {fid isTcl {verbose 0} } {

    global Comment

    if {[info exist Comment(copyrightFileName)] == 0 ||
        [info exist Comment(copyright)] == 0} {
        # set the vars
        CommentInit
    }

    if {$verbose} {
        puts "PrintCopyright: isTcl = $isTcl, copyright file is $Comment(copyrightFileName) and text has been set"
    }

    if {$isTcl == 1} {
        foreach l [split  $Comment(copyright) "\n"] {
            puts $fid "\# $l"
        }
    } else {
        puts $fid "/*=auto=========================================================================\n"
        foreach l [split $Comment(copyright) "\n"] {
            puts $fid "$l"
        }
        puts $fid "=========================================================================auto=*/"
    }
}

#-------------------------------------------------------------------------------
# .PROC ProcessFile
#
# This procedure processes a file to call either CommentFile or CopyrightFile
# depending on the file's type.
# .ARGS
# str file  the path of the file to parse, relative to slicer/program
# int verbose set this flag to 1 to see debugging print outs, defaults to 0
# .END
#-------------------------------------------------------------------------------
proc ProcessFile {file {verbose 0}} {
    set ext [file extension $file]
    if {$verbose} {
        puts "ProcessFile file = $file\n\text = $ext"
    }
    if {$ext == ".tcl"} { 
        # Go to town
        if {$verbose} { puts "ext == .tcl, calling CommentFile" }
        CommentFile $file $verbose
    } else {
        # Just add the copyright
        if {$verbose} { puts "Not a tcl file, calling CopyrightFile" }
        CopyrightFile $file $verbose
    }
}

#-------------------------------------------------------------------------------
# .PROC CopyrightFile
#
# Adds the copyright to any file by stripping off any existing automatically
# generated comments, and adding new ones.
# .ARGS
# str filename the name of the file to edit
# int verbose set this flag to 1 to see debugging print outs, defaults to 0
# .END
#-------------------------------------------------------------------------------
proc CopyrightFile {filename {verbose 0} } {
    global Comments

    if {$verbose} {
        puts "Copyrightfile $filename, will call PrintCopyRight with 0"
    }

    # Read file into "data"
    if {[catch {set fid [open $filename r]} errmsg] == 1} {
        puts "CopyrightFile: $errmsg"
        exit
    }
    set data [read $fid]
    if {[catch {close $fid} errorMessage]} {
       tk_messageBox -type ok -message "The following error occurred saving the input file: ${errorMessage}"
       puts "Aborting due to : ${errorMessage}"
       exit 1
    }

    # Strip auto commment block off
    regsub {/\*=auto===.*===auto=\*/} $data REPLACE-AND-CONQUER data
    regsub "REPLACE-AND-CONQUER\n" $data {} data

    # Add comments to the file
    if {[catch {set fid [open $filename w]} errmsg] == 1} {
        "CopyrightFile: $errmsg"
        exit
    }
    # it's not a tcl file, so last arg is 0
    PrintCopyright $fid 0 $verbose
    puts -nonewline $fid $data

    if {[catch {close $fid} errorMessage]} {
       tk_messageBox -type ok -message "The following error occurred saving the commented file: ${errorMessage}"
       puts "Aborting due to : ${errorMessage}"
       exit 1
    }
}

#-------------------------------------------------------------------------------
# .PROC CommentFile
#
# This procedure does everything CopyrightFile does except it also adds
# skeleton procedural comments. The file must be TCL source code.
# .ARGS
# str filename the full pathname of the TCL file to comment
# int verbose prints debug info if 1
# .END
#-------------------------------------------------------------------------------
proc CommentFile {filename {verbose 0}} {
    global Comments

    if {$verbose} { puts "CommentFile $filename: exists = [ file exist $filename]" }

    # Read file into "data"
    if {[catch {set fid [open $filename r]} errmsg] == 1} {
        puts "CommentFile: $errmsg"
        exit
    }
    set data [read $fid]
    if {[catch {close $fid} errorMessage]} {
       tk_messageBox -type ok -message "The following error occurred while saving the input file: ${errorMessage}"
       puts "Aborting due to : ${errorMessage}"
       exit 1
    }

    # Strip auto commment block off
    regsub  "#=auto===.*===auto=\n" $data {} data

    # Polish it
    set data [Polish $data]
    
    # Comment it
    Comment $data

    # Add comments to the file
    if {[catch {set fid [open $filename w]} errmsg] == 1} {
        "CommentFile: $errmsg"
        exit
    }

    if { [string range $data 0 1] != "#!" } {
        # only add the comment to the start if this isn't meant to be an executable script

        puts $fid "#=auto=========================================================================="
        # it's a tcl file, so last arg is 1
        PrintCopyright $fid 1
        puts $fid "#==============================================================================="
        puts $fid "# FILE:        [file tail $filename]"
        puts $fid "# PROCEDURES:  "
        foreach i $Comments(idList) {
            puts -nonewline $fid "#   $Comments($i,proc)"
            foreach a $Comments($i,argList) {
                puts -nonewline $fid " $Comments($i,$a,name)"
            }
            puts $fid ""
        }
        puts $fid "#==========================================================================auto="
    }

    puts -nonewline $fid $data

    if {[catch {close $fid} errorMessage]} {
       tk_messageBox -type ok -message "The following error occurred saving a file: ${errorMessage}" 
       puts "Aborting due to : ${errorMessage}"
       exit 1
       }

    # Print comments to stdout
    if {$verbose == 0} {
        return
    }
    foreach i $Comments(idList) {
        puts "PROC=$Comments($i,proc)"
        if {$Comments($i,desc) != ""} {
            puts "DESC=$Comments($i,desc)"
        }
        if {$Comments($i,argList) != ""} {
            puts "ARGS="
            foreach a $Comments($i,argList) {
                foreach p "name type desc" {
                    puts "  $p: $Comments($i,$a,$p)"
                }
                puts ""
            }
        }
        puts ""
    }
}

#-------------------------------------------------------------------------------
# .PROC Polish
#
# For each procedure in a file, this routine polishes the procedural comments
# if the existing comments fall into one of 3 pathological cases.
# The polished output looks like the following except that the keywords that
# begin with a . are listed in small letters in this documentation so that
# the comment program can run on itself!
# <code><pre>
# #------------------------------
# # .proc MyProc
# #
# # .args
# # .end
# #------------------------------
# proc MyProc {} {
# }
# </code></pre>
# <p>
# The 3 pathological cases are:
# <p>
# <code><pre>
# proc MyProc {} {
# }
# 
# #-----------------------------
# # MyProc
# #-----------------------------
# proc MyProc {} {
# }
#
# #-----------------------------
# # .proc MyProc
# # .end
# #-----------------------------
# proc MyProc {} {
# }
#
# </code></pre>
#
# .ARGS
# str data the text for the entire file
# .END
#-------------------------------------------------------------------------------
proc Polish {data} {

    # .IGNORE

    set line "#-------------------------------------------------------------------------------"
    
    # Fix procs with no comments
    set numsubs 0
    while {[regexp "\n\nproc (\[^ \]*) " $data match name] == 1} {
        # this can get stuck in an infintite loop if there's a space between 
        # an already existing comment and the proc
        regsub "proc $name " $data \
            "$line\n# .PROC ${name}\n# \n# .ARGS\n# .END\n$line\nproc $name " data
        incr numsubs
        if {$numsubs > 200} {
            puts "ERROR: possible infinite loop while commenting proc '${name}'.\nCheck file for a space between an existing comment and proc '${name}', or for two instances of the proc."
            puts "\tmatch = $match"
            puts "\tfirst part of data = [string range $data 0 200]"
            exit
        } 
    }

    # Fix procs with just a procedure name
    while {[regexp "$line\n# (\[^ \n\]*) *\n$line\nproc (\[^ \]*) " \
        $data match cname name] == 1 && $cname == $name} {
        regsub "$line\n# ${name} *\n$line\nproc $name " $data \
          "$line\n# .PROC ${name}\n# \n# .ARGS\n# .END\n$line\nproc $name " data
    }

    # Fix procs with just the .PROC and .END
    while {[regexp "$line\n# .PROC (\[^ \]*) *\n# .END\n$line\nproc (\[^ \]*) " \
        $data match cname name] == 1 && $cname == $name} {
        regsub "$line\n# .PROC ${name} *\n# .END\n$line\nproc $name " $data \
          "$line\n# .PROC ${name}\n# \n# .ARGS\n# .END\n$line\nproc $name " data
    }

    # .ENDIGNORE
    return $data
}

#-------------------------------------------------------------------------------
# .PROC Comment
#
# This procedure forms a global array 'Comments' containing the contents of
# the comments at the procedure level in the file
# .ARGS
# str data    The file contents to parse.
# .END
#-------------------------------------------------------------------------------
proc Comment {data} {
    global Comments

    # .IGNORE
    # Ignore this routine so that the comment program can run on itself
    regsub -all {\.IGNORE.*\.ENDIGNORE} $data {} data

    # Delete all comment markers
    #
    regsub -all "^#" $data {} data
    regsub -all "\n#" $data "\n" data
    regsub -all "^//" $data {} data
    regsub -all "\n//" $data "\n" data
    regsub -all "^/\*" $data {} data
    regsub -all {/[\*]} $data {} data

    # Replace all instances of ".PROC" with "|" and then split the
    # data into a list of the text that was delimited by "|"
    #
    regsub -all {\|} $data "##pipe##" data
    regsub -all {\.PROC} $data "|" data
    set procList [lrange [split $data |] 1 end]

    # Build an array of comment parts:
    # Comments(idList)
    # Comments(id,proc)
    # Comments(id,desc)
    # Comments(id,argList)
    # Comments(id,arg,type)
    # Comments(id,arg,name)
    # Comments(id,arg,desc)
    #
    set Comments(idList) ""
    set id 1
    foreach p $procList {

        # Delete everything after, and including, ".END"
        regsub {\.END.*} $p {} p 

        # Strip off everything before ".ARGS" as the description
        regsub -all {\.ARGS} $p "|" p 
        set list [split $p |]
        set desc [lindex $list 0]
        set args [lindex $list 1] 

        # Strip leading white space off
        set desc [string trimleft $desc]

        # Strip off the first word of the desc as the proc name
        regexp "(.*?)\[\n\].*" $desc match proc

        # Note the following line treats the string as a list, which        
        # is too dangerous since a quote-comma sequence crashes it
        #set proc [lindex $desc 0]

        regsub "$proc" $desc {} desc

        # Note the following line would have stripped off the
        # line returns:
        # set desc [lrange $desc 1 end]

        # Strip leading white space of the description
        regsub "^\[\n\t \]*" $desc {} desc

        # Delineate args by newlines 
        regsub -all "\n" $args "|" args 
        set argList [lrange [split $args |] 1 end]

        # Restore "##pipe##" to "|"
        regsub -all {##pipe##} $desc {|} desc 
        regsub -all {##pipe##} $args {|} args

        # Set array values
        lappend Comments(idList) $id 
        set Comments($id,proc) $proc
        set Comments($id,desc) $desc

        # Break arguments into components: type, name, desc
        set arg 1
        set Comments($id,argList) ""
        foreach a $argList {
            if {[llength $a] > 1} { 
                lappend Comments($id,argList) $arg
                set Comments($id,$arg,type) [lindex $a 0]
                set Comments($id,$arg,name) [lindex $a 1]
                set Comments($id,$arg,desc) [lrange $a 2 end]
                incr arg
            }
        }
        incr id
    }
    # .ENDIGNORE
}

#-------------------------------------------------------------------------------
# .PROC ProcessModule
#
# This procedure will process the tcl and cxx files in the same subdirectories of a
# single module.
# .ARGS
# str modpath    The full path to the module to comment
# int verbose    If 1 will print out debugging info
# .END
#-------------------------------------------------------------------------------
proc ProcessModule { modpath {verbose 0 } } {
    set modsubdirs "tcl cxx"
    foreach modsub $modsubdirs {
        set thisdir [file join $modpath $modsub]
        if {[file isdirectory $thisdir] == 1} {
            if {$verbose} { puts "found directory $thisdir" }
            # don't bother switching on the cxx or tcl dirs for now
            foreach file "[glob -nocomplain $thisdir/*.tcl] \
                              [glob -nocomplain $thisdir/*.h] \
                              [glob -nocomplain $thisdir/*.cxx]" {
                puts "$file"
                ProcessFile $file
            }
        }
    }
}
