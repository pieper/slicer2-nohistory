#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Document.tcl,v $
#   Date:      $Date: 2006/08/29 17:05:51 $
#   Version:   $Revision: 1.30 $
# 
#===============================================================================
# FILE:        Document.tcl
# PROCEDURES:  
#   ReadInput
#   HtmlHead
#   BlueGrayLine
#   HtmlFoot
#   DocumentProc
#   DocumentFile the the the if
#   DocumentIndex the
#   DocumentParseAuto
#   DocumentGenerateAuto
#   DocumentAll
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC ReadInput
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ReadInput {filename} {
    if {[catch {set fid [open $filename r]} errmsg] == 1} {
        puts "$errmsg"
        return ""
    }
    set data [read $fid]
    if {[catch {close $fid} errorMessage]} {
            tk_messageBox -type ok -message "The following error occurred saving a file : ${errorMessage}" 
        puts "Aborting due to : ${errorMessage}"
            exit 1
      }
    return $data
}

#-------------------------------------------------------------------------------
# .PROC HtmlHead
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc HtmlHead {fid title {styleFile "../../style.css"} \
    {homeFile "../../index.html"}} {
    puts $fid \
"<html>
<head>
<title>$title</title>
<link rel=stylesheet type='text/css' href='$styleFile'>
</head>
<body bgcolor=white>
<!-------------------------- Heading -------------------------------->
<body bgcolor=white>
<a name=top></a>
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td align=left>
    &nbsp;<a href='$homeFile' target='_top'>www.slicer.org</a>
</td>
<td align=right>
        <a href='http://www.na-mic.org/Wiki/index.php/Slicer'>NA-MIC.org/Wiki/index.php/Slicer</a>&nbsp;
</td> 
</tr> 
</table>

[BlueGrayLine]"
}

#-------------------------------------------------------------------------------
# .PROC BlueGrayLine
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc BlueGrayLine {} {
    return "
<!-------------------------- Blue/Gray line ------------------------------>
<table border=0 cellspacing=0 width=100%>
<tr><td bgcolor=#FFFFFF><table border=0 cellspacing=0 cellpadding=0><tr><td height=2></td></tr></table></td></tr>
<tr><td bgcolor=#e5e5e5><table border=0 cellspacing=0 cellpadding=0><tr><td height=2></td></tr></table></td></tr>
<tr><td bgcolor=#333399><table border=0 cellspacing=0 cellpadding=0><tr><td height=2></td></tr></table></td></tr></table>"
}

#-------------------------------------------------------------------------------
# .PROC HtmlFoot
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc HtmlFoot {fid} {
    puts $fid \
"</body>
</html>"
}

#-------------------------------------------------------------------------------
# .PROC DocumentProc
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DocumentProc {fid p} {
    global Comments
    
    set name $Comments($p,proc)
    set desc $Comments($p,desc)
    set args $Comments($p,argList)

    puts $fid \
"<a name='$name'></a>
<h2>$name</h2>
<p>
$desc
"

    if {$args != ""} {
        puts $fid \
"<table cellpadding=3 cellspacing=3 border=0 align=center>
<tr>
<th class=box>Parameter</th>
<th class=box>Type</th>
<th class=box>Description</th>
</tr>"

        set n 1
        foreach a $args {
            set n [expr [incr n] % 2]
            set type $Comments($p,$a,type)
            set name $Comments($p,$a,name)
            set desc $Comments($p,$a,desc)
            puts $fid \
"<tr>
<td class=box$n>$name</td>
<td class=box$n>$type</td>
<td class=box$n>$desc</td>
</td>
</tr>"
        }
        puts $fid \
"</table>"
    }
}

#-------------------------------------------------------------------------------
# .PROC DocumentFile
# 
# .ARGS
# path docdir the top level of the documentation directory
# path dir  the subdir to put this documentation into
# str filename the name of the file to produce documentation for
# int level if level is one, look for the default style in ../../style.css
# .END
#-------------------------------------------------------------------------------
proc DocumentFile {docdir dir filename {level "1"}} {
    global Comments prog

    Comment [ReadInput $filename]
    set name [file root [file tail $filename]]

    # Open output file
    set docfile [file join [file join $docdir $dir] $name.html]    
    if {[catch {set fid [open $docfile w]} errmsg] == 1} {
        puts "DocumentFile: Attempted to open $docfile:\n$errmsg"
        exit
    }

    # if directory level is deeper than 1, need to look higher for
    # the style file than the default ../../style.css

    # special case for the Base/tcl files, level is 0
    if {$level == 0} {
        set default "../style.css"
    } else {
        set default "../../style.css"
    }
    set styleFile $default
    for {set i "1"} { $i < $level} { incr i} {
        set styleFile "../$styleFile" 
    }
    
    HtmlHead $fid $name $styleFile

    # List procecures
    puts $fid \
"<h2><font color='#993333'>[file tail $filename]</font> Procedures:</h2>
<ul>"
    foreach p $Comments(idList) {
        set name $Comments($p,proc)
        puts $fid \
"<li><a href='#$name'>$name</a>"
    }
    puts $fid \
"</ul>"

    # Document each procedure
    foreach p $Comments(idList) {
        DocumentProc $fid $p
    }

    HtmlFoot $fid
    if {[catch {close $fid} errorMessage]} {
        tk_messageBox -type ok -message "The following error occurred saving a file: ${errorMessage}"
        puts "Aborting due to: ${errorMessage}"
        exit 1
    }
}

#-------------------------------------------------------------------------------
# .PROC DocumentIndex
# 
# .ARGS
# path docdir the top level documentation directory in which to build an index.html
# .END
#-------------------------------------------------------------------------------
proc DocumentIndex {docdir} {
    global Index
    
    # Open output file
    set docfile [file join $docdir index.html]
    if {[catch {set fid [open $docfile w]} errmsg] == 1} {
        puts "$errmsg"
        exit
    }

    HtmlHead $fid "TCL Source Index" "../style.css" "../index.html"

    # List files
    foreach dir [lsort $Index(dirList)] {
        puts $fid \
"<h2>$dir</h2>
<ul>"

        foreach name [lsort $Index($dir)] {
            puts $fid \
"<li><a href='[file join $dir $name.html]'>$name</a>"
        }
        puts $fid \
"</ul>"
    }

    HtmlFoot $fid
    if {[catch {close $fid} errorMessage]} {
                tk_messageBox -type ok -message "The following error occurred sa
ving a file: ${errorMessage}"
                puts "Aborting due to: ${errorMessage}"
                exit 1
        }
}

#-------------------------------------------------------------------------------
# .PROC DocumentParseAuto
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DocumentParseAuto {dir fileList} {
    global Contents

    set Contents(idList) ""
    set fileList [lsort -decreasing $fileList]

    # Read and parse each file
    foreach file $fileList {
        
        set data [ReadInput $file]
        if {$data != ""} {
            set tail [file root [file tail $file]]
            regexp {auto(.*)} $tail match id
            set subId ""
            if {[regexp {auto(.*)-(.*)} $tail match id subId] == 0} {
                lappend Contents(idList) $id
                set Contents($id,subList) ""
            } else {
                lappend Contents($id,subList) $subId
                set Contents($id,subList) [lsort $Contents($id,subList)]
            }
        }

        if {[regexp {<title>(.*)</title>} $data match title] == 1} {
            
            # Strip title
            regsub {<title>(.*)</title>} $data {} data
        
            # Strip leading white space
            regsub "^\[\n\t \]*" $data {} data

            if {$subId == ""} {
                set Contents($id,0,title) $title
                set Contents($id,0,html) $data
            } else {
                set Contents($id,$subId,title) $title
                set Contents($id,$subId,html) $data
            }
        }
    }

    # Read configuration info
    set file [file join $dir auto.xml]
    set data [ReadInput $file]
    set Contents(title) ""
    set Contents(teaser) ""
    set Contents(summary) ""
    regexp {<title>(.*)</title>}     $data match Contents(title)
    regexp {<teaser>(.*)</teaser>}   $data match Contents(teaser)
    regexp {<summary>(.*)</summary>} $data match Contents(summary)

    set Contents(idList) [lsort $Contents(idList)]
}

#-------------------------------------------------------------------------------
# .PROC DocumentGenerateAuto
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DocumentGenerateAuto {dir} {
    global Contents

    foreach id $Contents(idList) {
        puts $id
        set Contents($id,0,num) [expr [lsearch $Contents(idList) $id] + 1]
        foreach subId $Contents($id,subList) {
            puts $id-$subId
            set index ${id},${subId}
            set Contents($index,num) $Contents($id,0,num)$subId
        }
    }

    #--------------------------------------------------
    # Open index.html
    #--------------------------------------------------
    set docfile [file join $dir index.html]
    if {[catch {set fid [open $docfile w]} errmsg] == 1} {
        puts "$errmsg"
        exit
    }

    #--------------------------------------------------
    # Write header
    #--------------------------------------------------
    puts $fid \
"<html>
<head>
<title>$Contents(title)</title>
<link rel=stylesheet type='text/css' href='../style.css'>
</head>

<!-------------------------- Heading -------------------------------->
<body bgcolor=white>
<a name=top></a>
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td align=left>
    &nbsp;<a href='../index.html' target='_top'>www.slicer.org</a>
</td>
<td align=right> 
        <a href='http://www.na-mic.org/Wiki/index.php/Slicer'>NA-MIC.org/Wiki/index.php/Slicer</a>&nbsp;
</td> 
</tr> 
</table>

[BlueGrayLine]

<!---------------------------------------------------------------------------
                           Introduction
---------------------------------------------------------------------------->
<h2>$Contents(title)</h2>

<blockquote>
<table border=0 cellpadding=0 cellspacing=0>
<tr>
<td valign=top>
    <center><img src='../images/logo.jpg'></center>
</td>
<td>
    <blockquote>
    <p class=teaser>$Contents(teaser)
    </p>
    <p>
    $Contents(summary)
    </blockquote>
</td>
</tr>
</table>

<!---------------------------------------------------------------------------
                          Table of Contents
---------------------------------------------------------------------------->
<table border=0 cellpadding=2 cellspacing=15>"

    #--------------------------------------------------
    # Write Table of Contents
    #--------------------------------------------------
    foreach {id1 id2} $Contents(idList) {
        set num $Contents($id1,0,num)
        puts $fid \
"<tr>
<td valign=top>
    <b><em>${num}. </em><a href='#${num}'>$Contents($id1,0,title)</a>"
        foreach subId $Contents($id1,subList) {
            set num $Contents($id1,$subId,num)
            puts $fid \
"    <br><small>&nbsp;&nbsp;&nbsp; <em>${subId}. </em><a href='#${num}'>$Contents($id1,$subId,title)</a></small>"
        } 
        puts $fid "</td>"

        if {$id2 != ""} {
            set num $Contents($id2,0,num)
            puts $fid \
"<td valign=top>
    <b><em>${num}. </em><a href='#${num}'>$Contents($id2,0,title)</a>"
            foreach subId $Contents($id2,subList) {
                set num $Contents($id2,$subId,num)
                puts $fid \
"    <br><small>&nbsp;&nbsp;&nbsp; <em>${subId}. </em><a href='#${num}'>$Contents($id2,$subId,title)</a></small>"
            } 
            puts $fid "</td>"
        }
        puts $fid "</tr>"
    }
    
    puts $fid \
"</table>
</blockquote>
[BlueGrayLine]
"

    #--------------------------------------------------
    # Write Chapters
    #--------------------------------------------------
    foreach id $Contents(idList) {
        foreach subId "0 $Contents($id,subList)" {
            set index ${id},${subId}
            set num $Contents($index,num)

            puts $fid \
"<!---------------------------------------------------------------------------
                                  $num
---------------------------------------------------------------------------->
<h2><a name='${num}'></a><em>${num}. </em>$Contents($index,title)</h2>
$Contents($index,html)
"
            if {$Contents($index,html) != ""} {
                puts $fid \
"<!-- top -->
<p><a href='#top'><small>top</small></a>
[BlueGrayLine]"
            }
        }
    }

    HtmlFoot $fid
    if {[catch {close $fid} errorMessage]} {
                tk_messageBox -type ok -message "The following error occurred sa
ving a file: ${errorMessage}"
                puts "Aborting due to: ${errorMessage}"
                exit 1
        }
}

#-------------------------------------------------------------------------------
# .PROC DocumentAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DocumentAll {prog {outputdir ""} {what "doc tcl"} {moduleName ""}} {
    global Index

    # Document the guides
    #------------------------------------------
    if {[lsearch $what "doc"] != -1} {
        if {$outputdir != ""} {
            set docdir $outputdir
        } else {
            set docdir [file join [file dirname $prog] doc]
        }

        foreach file [glob -nocomplain $docdir/*] {
            if {[file isdirectory $file] == 1} {
                set dir [file join $docdir $file]
                set fileList ""
                foreach file [glob -nocomplain $dir/auto*.html] {
                    if {[file isdirectory $file] == 0} {
                        lappend fileList $file
                    }
                }
                if {$fileList != ""} {
                    # Find directory in which to make index.html
                    set dir [file dirname [lindex $fileList 0]]
                    puts $dir
                    DocumentParseAuto $dir $fileList
                    DocumentGenerateAuto $dir
                } 
            }
        }
    }

    # Document the TCL source code
    #------------------------------------------
    if {[lsearch $what "tcl"] != -1} {
        # Find the directory to place the output html files
        

        if {$outputdir != ""} {
            set docdir [file join $outputdir tcl]
        } else {
            set docdir [file join [file join [file dirname $prog] \
                                       doc] tcl]
        }

        # Create the doc dir if necessary
        if {[file exists $docdir] == 0} {
            puts "Creating directory $docdir"
            if {[catch {file mkdir $docdir} errmsg] == 1} {
                puts "Cannot create directory $docdir: $errmsg"
                exit
            }
        }
        # Document each file
        set Index(dirList) ""
        set dirs ". tcl-main tcl-modules tcl-shared tcl-modules/Editor tcl-modules/Volumes" 
        # levels we are deep in the directory structure, 
        # relative to slicer/Base
        set levels " 0 1 1 1 2 2"

        foreach dir $dirs level $levels {
            puts $dir
            # Create this subdirectory if necessary
            if {[file exists [file join $docdir $dir]] == 0} {
                puts "Creating directory [file join $docdir $dir]"
                if {[catch {file mkdir [file join $docdir $dir]} errmsg] == 1} {
                    puts "Cannot create directory [file join $docdir $dir]: $errmsg"
                    exit
                }
            }

            set Index($dir) ""
            lappend Index(dirList) $dir
            foreach file [glob -nocomplain $prog/$dir/*.tcl] {
                puts $file
                lappend Index($dir) [file root [file tail $file]]
                DocumentFile $docdir $dir $file $level
            }
        }
        # Build an index
        # DocumentIndex $docdir

        if {$::doModsFlag} {
            if {$::verbose} {
                puts "\nTrying to create tcl docs for the modules as well\n\tdocdir = $docdir\n\tSLICER_HOME = $::SLICER_HOME"
            }
            set modDir [file join $::SLICER_HOME Modules]
            if {$moduleName != ""} {
                set moduleTclPaths [file join $modDir $moduleName tcl]
                if {$::verbose} {
                    puts "moduleTclPaths $moduleTclPaths"
                }
            } else {
                # grab the module tcl dirs and the paths to them
                set moduleTclPaths [glob -nocomplain $modDir/*/tcl]
            }
            foreach modpath $moduleTclPaths {
                set modName [file tail [file dirname $modpath]]
                set level 1
                # create the output doc subdir if needed 
                set dir [file join $docdir $modName]
                if {[file exists $dir] == 0} {
                    puts "Creating directory $dir"
                    if {[catch {file mkdir $dir} errmsg] == 1} {
                        puts "Cannot create directory $dir: $errmsg"
                        exit
                    }
                }
                puts $modName
                set Index($modName) ""
                lappend Index(dirList) $modName
                foreach file [glob -nocomplain $modpath/*.tcl] {
                    if {$::verbose} { puts "Calling DocumentFile $docdir $modName $file $level" }
                    puts $file
                    lappend Index($modName) [file root [file tail $file]]
                    DocumentFile $docdir $modName $file $level
                }
            }
        }
        # Build an index
        DocumentIndex $docdir
    }
}
