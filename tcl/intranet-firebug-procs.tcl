# /packages/intranet-firebug/tcl/intranet-firebug-procs.tcl
#
# Copyright (C) 2012 - Josep Vela - jv@actioadfuturum.com
#
# 
# This code is released under the MIT License.
# For additional information please see http://opensource.org/licenses/MIT


ad_library {

    Information 

    @author jv@actioadfuturum.com
    @cvs-id $Id$
}


namespace eval fb {}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

#ad_proc -public im_portfolio_project_priority_1 {} { return 70000 }


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# is_array - auxiliary procedure for log facilities
# ----------------------------------------------------------------------
proc is_array {string} {
    
    set v1 [regexp -all {\{} $string]
    set v2 [regexp -all {\}} $string]

    if { $v1 != $v2 } {
	##puts "Parentheses unbalanced! $v1 * $v2 "
	return false
    } else {
	##puts "parent ok -  $v1 * $v2 "
	if {$v1 == 0} {return false}
	return true
    }
}


# ----------------------------------------------------------------------
# compile_json - simple marshalling json format 
# ----------------------------------------------------------------------
# http://wiki.tcl.tk/13419

# data is plain old tcl values
# spec is defined as follows:
# {string} - data is simply a string, "quote" it if it's not a number
# {list} - data is a tcl list of strings, convert to JSON arrays
# {list list} - data is a tcl list of lists
# {list dict} - data is a tcl list of dicts
# {dict} - data is a tcl dict of strings
# {dict xx list} - data is a tcl dict where the value of key xx is a tcl list
# {dict * list} - data is a tcl dict of lists
# etc..

proc compile_json {spec data} {
   while [llength $spec] {
     set type [lindex $spec 0]
     set spec [lrange $spec 1 end]
     
     switch -- $type {
       dict {
         lappend spec * string
         
         set json {}
         foreach {key val} $data {
           foreach {keymatch valtype} $spec {
             if {[string match $keymatch $key]} {
               lappend json [subst {"$key":[compile_json $valtype $val]}]
               break
             }
           }
         }
         return "{[join $json ,]}"
       }
       list {
         if {![llength $spec]} {
           set spec string
         } else {
           set spec [lindex $spec 0]
         }
         set json {}
         foreach {val} $data {
           lappend json [compile_json $spec $val]
         }
         return "\[[join $json ,]\]"
       }
       string {
         if {[string is double -strict $data]} {
           return $data
         } else {
           return "\"$data\""
         }
       }
       default {error "Invalid type"}
     }
   }
}

# ----------------------------------------------------------------------
# fireBug - the log function 
# ----------------------------------------------------------------------
#  
#
# First firebug TCL (Wildfire) protocol implemetation. Based on FirePHP.
#
# Documentation follows:
#
# The Response Header Protocol
#
# All FirePHP response headers are prefixed with "X-Wf-" (according to the Wildfire protocol) and can be sent in 
# any order and position. 
# Note the sample headers below have been manually ordered to be sequential, something the extension does itself 
# automatically based on the numeric index.
# X-Wf-Protocol-1     http://meta.wildfirehq.org/Protocol/JsonStream/0.2
# X-Wf-1-Plugin-1     http://meta.firephp.org/Wildfire/Plugin/FirePHP/Library-FirePHPCore/0.3
# X-Wf-1-Structure-1  http://meta.firephp.org/Wildfire/Structure/FirePHP/FirebugConsole/0.1
#
# Sample: prints "Hello World" in console
# X-Wf-1-1-1-1        62|[{"Type":"LOG","File":" ... Test.php","Line":3},"Hello World"]|
# 
# X-Wf-1-1-1-1        ...
# X-Wf-1-1-1-2        ...
# X-Wf-1-1-1-3        ...
# 
# The value of the data headers must follow a specific format to be recognized by the FirePHP extension.
# <size> | [ <meta> , <body> ] |
# 
# Where:
# size is the number of bytes between the two |
# This will often be equivalent to the number of characters, unless your message body contains unicode characters in which case you may find characters != bytes. 
# For example, including a Euro symbol Eur will use 3 bytes, and thus the string "It cost Eur 10" requires the size to be 13 and not 11.
# meta is a JSON object containing information about the log message
# body is the actual log message (again in JSON format)
# You should keep the character length of each header value to under 5,000 characters or Firefox will not be able to parse it correctly. If your log message is longer than this limit you may split it into several headers.
# X-Wf-1-1-1-1    17245|[{"Type":"LOG"},["Element 0","Element 1", ... |\
# X-Wf-1-1-1-2    | ... ,"Element 399", ... |\
# X-Wf-1-1-1-3    | ... ,"Element 799"]]|
#
# Note the size (of the entire log message) is specified for the first header and a backslash is used at the end of the first and second header to join it to the next. The last header has no backslash to indicate the end of the log message.
# You can split the message any way you wish as long as when the headers are combined (removing the backslashes and "|") it forms a valid JSON string.

# http://www.firephp.org/Wiki/Reference/Protocol
#
# TODO:
#  - no character length control
#  - no unicode character length correct calculatin
#  - better JSON serialization
#  - better line number, and file specification
#  - no enable/disable support
#
proc fireBug { msg args } {
    array set opts {-type LOG -collapsed {} -color {} -label {} -group {} -output {} -enabled {} }
    set n [array size opts]
    array set opts $args 
    if {$n != [array size opts]} { error "unknown option(s)" }

    set enabled_v [string tolower $opts(-enabled) ]
    set enabled_p [string is true $enabled_v]
    if { $enabled_p } {
    } else {
    }

    # set fb_enabled [ad_get_client_property "firebug" "isEnabled"]
    # if {$fb_enabled == ""} { 
    # 	set contador false
    # } else {
    # 	set contador true
    # }

    # ad_set_client_property  "firebug" "isEnabled" $contador

    if {[ string is false $enabled_v ]} {
    } else {
	set enabled_p true
    }
 
    # TODO: better control

    set output_v [string tolower $opts(-output)]
    switch $output_v {
    	"string" {set v {string}}
    	"dict"   {set v {dict} } 
    	"list"   {set v {list} }
	""       {
	             set v {string}
	             if {[is_array $msg]} { set v {dict} }
	         }
    	default  {set v {string} }
    }


    set type_v [string toupper $opts(-type)]
    switch $type_v { 
        	"LOG"   {}
        	"INFO"  {}
        	"WARN"  {}
        	"ERROR" {}
	        "TABLE" { set v {list list} }
        	default {
        	   set type_v "LOG"
        	}
    } 

    set theD [dict create Type $type_v]

    # TODO: better file and line identification and trace facilities

    # set ii [info frame [info frame]]
    # set theType [dict get $ii type] 
    # switch $theType {
    #     "source" {
    #         set theLine [dict get $ii line] 
    #         set theFile [dict get $ii file]
    #     }
    #     "proc" {
    #         set theLine [dict get [info frame -2] line] 
    #         set theFile [dict get [info frame -2] proc]
    #     }
    #     "eval" {
    #         set theLine [dict get $ii line] 
    #         set theFile {TCL eval: info not available}
    #     }
    #     "precompiled" { 
    #         set theLine {0}
    #         set theFile {TCL precompiled: info not available}
    #     }
    # }

    # temporary fix for line and file
    set theLine 1
    set theFile "not used"

    if {[string length $theFile] > 40} { set theFile "...[string range $theFile 40 end]" }
    dict set theD Line $theLine
    dict set theD File "$theFile"


    if {$opts(-label) != ""} {
	dict set theD Label  $opts(-label) 
    } else {
	if { $type_v == "TABLE" } { dict set theD Label "Table default label" }
    }
    
    set group_v [string toupper $opts(-group)]
    switch $group_v {

	"" { }
   	
	"BEGIN" { 
	    dict set theD Type "GROUP_START"

	    set collapsed_v [string tolower $opts(-collapsed)]
   	    switch $collapsed_v {
		""      { dict remove theD Collapsed }
		"true"  -
		"false" { dict set theD Collapsed $collapsed_v }
		default { error "wrong collapsed value" }
	    }
		
	    set color_v $opts(-color)
	    switch $color_v {
		""      { dict set theD Color red }
		default { dict set theD Color $color_v }
	   }

	   if {$opts(-label) == ""} {
	       if {$msg != ""} { dict set theD Label  $msg } else { dict set theD Label "Default Group Label" }
	   } 

	}
	
	"END"	{ 
	   dict set theD Type "GROUP_END" 
	}
	
	default {
	   error "wrong group parameter use: begin or end"
	}
    }
    
    
    set headers [ns_conn outputheaders]

    set fb_idx [ns_set get $headers "X-Wf-1-Index"]

    if {$fb_idx == ""} {
	ns_set put $headers  "X-Wf-1-Plugin-1"	        "http://meta.firephp.org/Wildfire/Plugin/FirePHP/Library-FirePHPCore/0.3"
	ns_set put $headers  "X-Wf-1-Structure-1"	"http://meta.firephp.org/Wildfire/Structure/FirePHP/FirebugConsole/0.1" 
        ns_set put $headers  "X-Wf-Protocol-1"	        "http://meta.wildfirehq.org/Protocol/JsonStream/0.2" 
	set fb_idx 0
    }

    incr fb_idx
    set json_msg       [format {[%s,%s]} [compile_json {dict} $theD] [compile_json $v $msg]]

    ns_set put $headers  "X-Wf-1-1-1-$fb_idx" "[string length $json_msg]|$json_msg|"
    ns_set update $headers "X-Wf-1-Index" "$fb_idx"
}

# ----------------------------------------------------------------------
# simple driver procedures
# ----------------------------------------------------------------------

proc fb_log    {msg {lbl {}}} {fireBug $msg -label $lbl -type LOG    -output string   }
proc fb_info   {msg {lbl {}}} {fireBug $msg -label $lbl -type INFO   -output string   }
proc fb_warn   {msg {lbl {}}} {fireBug $msg -label $lbl -type WARN   -output string   }
proc fb_error  {msg {lbl {}}} {fireBug $msg -label $lbl -type ERROR  -output string   }
proc fb_var    {msg {lbl {}}} {
    if {$lbl == "" } {set lbl "Variable"} 
    dict set outMsg $lbl $msg
    fireBug $msg -label $lbl  -type LOG    -output list 
}        


