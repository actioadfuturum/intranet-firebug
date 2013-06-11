# ----------------------------------------------------------------------
#
# test-firebug.tcl 
#
#    @author        Josep Vela - jv@actioadfuturum.com
#    @creation-date $Date$
#    @cvs-id        $Id$
#
# ----------------------------------------------------------------------

set now [clock seconds]
set tt "The time is now : " 
append tt [clock format $now -format %H:%M:%S]

fireBug $tt -label "A timestamp sample"

fb_log    $tt 
fb_warn   $now

fb_log    "Plain_Message" 
fb_info   "Info_Message" 
fb_warn   "Warn_Message"
fb_error  "Error_Message"

set aa {a {1 2 3} b {4 5}}
fb_var $aa

set bb {i 10 j 20}
fb_var $bb


set anArray  "i {1 2} j {3 4}"
set aString  "hola radiola"
set aNumber  123


fireBug $tt -label "A timestamp sample"

fireBug anArray
fireBug aString
fireBug aNumber
fireBug "{a {1 2 3} b {4 5}}"

fireBug "i 10 j 20" -label "a simple label printing a dict" -type Log

fireBug "" -label "Group ID as Label" -group begin -collapsed false 
fireBug "Inside_the_group_1" -type WARN 
fireBug "Inside_the_group_2"  
fireBug "" -group end 

fireBug "Group ID as Message" -group begin -collapsed true -color "#FF00FF"
for { set i 1 } { $i <= 10 } { incr i } {
    fireBug "test $i" 
}
fireBug "" -group end

set aTable { {"Col 1 Heading" "Col 2 Heading"} {"Row 1 Col 1" "Row 1 Col 2" } {"Row 2 Col 1" "Row 2 Col 2" } {"Row 3 Col 1" "Row 3 Col 2"} }
fireBug $aTable -label "Table label" -type TABLE

fireBug $aTable -type TABLE


fireBug "one string as string not as list" -label "Test as string" -output string


proc testProcedure {} {
   fireBug "inside procedure test"
}

testProcedure

# ----------------------------------------------------------------------
#   $Log$
# ----------------------------------------------------------------------