#=auto==========================================================================
# Copyright (c) 2000 Surgical Planning Lab, Brigham and Women's Hospital
#  
# Direct all questions regarding this copyright to slicer@ai.mit.edu.
# The following terms apply to all files associated with the software unless
# explicitly disclaimed in individual files.   
# 
# The authors hereby grant permission to use, copy, (but NOT distribute) this
# software and its documentation for any NON-COMMERCIAL purpose, provided
# that existing copyright notices are retained verbatim in all copies.
# The authors grant permission to modify this software and its documentation 
# for any NON-COMMERCIAL purpose, provided that such modifications are not 
# distributed without the explicit consent of the authors and that existing
# copyright notices are retained in all copies. Some of the algorithms
# implemented by this software are patented, observe all applicable patent law.
# 
# IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF,
# EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE IS PROVIDED ON AN
# 'AS IS' BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
# MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
#===============================================================================
# FILE:        Parse.tcl
# PROCEDURES:  
#   MainMrmlReadVersion2.0 filename verbose
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC MainMrmlReadVersion2.0
# 
# Opens a MRML2.0 file and reads and parses it to return a string that is
# a list of MRML nodes in the file. Each string element is itself a list of
# (key value) pairs of the attributes of the node. So the format is:<br>
# <code>(nodeName (key1 value1) (key2 value2)) (nodeName (key1 value1))</code>
#
# .ARGS
# str filename Full pathname of the MRML2.0 file to read and parse.
# str verbose set to 1 if you want to print debug information during parsing.
# .END
#-------------------------------------------------------------------------------
proc MainMrmlReadVersion2.0 {fileName {verbose 1}} {

	# Returns list of tags on success else 0

	# Read file
	if {[catch {set fid [open $fileName r]} errmsg] == 1} {
	    puts $errmsg
	    tk_messagebox -message $errmsg
	    return 0
	}
	set mrml [read $fid]
	close $fid

	# Check that it's the right file type and version
	if {[regexp {<!DOCTYPE MRML SYSTEM "mrml20.dtd">} $mrml match] == 0} {
		set errmsg "The file is NOT MRML version 2.0"
		tk_messageBox -message $errmsg
		return 0
	}

	# Strip off everything but the body
	if {[regexp {<MRML>(.*)</MRML>} $mrml match mrml] == 0} {
		# There's no content in the file
		return ""
	}

	# Strip leading white space
	regsub "^\[\n\t \]*" $mrml "" mrml

	set tags1 ""
	while {$mrml != ""} {

		# Find next tag
		if {[regexp {^<([^ >]*)([^>]*)>([^<]*)} $mrml match tag attr stuffing] == 0} {
				set errmsg "Invalid MRML file. Can't parse tags:\n$mrml"
			puts "$errmsg"
			tk_messageBox -message "$errmsg"
			return 0
		}

		# Strip off this tag, so we can continue.
		if {[lsearch "Transform /Transform" $tag] != -1} {
			set str "<$tag>"
		} else {
			set str "</$tag>"
		}
		set i [string first $str $mrml]
		set mrml [string range $mrml [expr $i + [string length $str]] end]

		# Give the EndTransform tag a name
		if {$tag == "/Transform"} {
			set tag EndTransform
		}

		# Append to List of tags1
		lappend tags1 "$tag {$attr} {$stuffing}"

		# Strip leading white space
		regsub "^\[\n\t \]*" $mrml "" mrml
	}

	# Parse the attribute list for each tag
	set tags2 ""
	foreach pair $tags1 {
		set tag [lindex $pair 0]
		set attr [lindex $pair 1]
		set stuffing [lindex $pair 2]

		# Add the options (the "stuffing" from inside the start and end tags)
		set attrList ""
		lappend attrList "options $stuffing"

		# Strip leading white space
		regsub "^\[\n\t \]*" "$attr $stuffing" "" attr

		while {$attr != ""} {
		
			# Find the next key=value pair (and also strip it off... all in one step!)
			if {[regexp "^(\[^=\]*)\[\n\t \]*=\[\n\t \]*\['\"\](\[^'\"\]*)\['\"\](.*)$" \
				$attr match key value attr] == 0} {
				set errmsg "Invalid MRML file. Can't parse attributes:\n$attr"
				puts "$errmsg"
				tk_messageBox -message "$errmsg"
				return 0
			}
			lappend attrList "$key $value"

			# Strip leading white space
			regsub "^\[\n\t \]*" $attr "" attr
		}

		# Add this tag
		lappend tags2 "$tag $attrList"
	}
	return $tags2
}
