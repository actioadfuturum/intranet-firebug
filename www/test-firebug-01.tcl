# ----------------------------------------------------------------------
#
# test-firebug.tcl 
#
#    @author        Josep Vela - jv@actioadfuturum.com
#    @creation-date $Date$
#    @cvs-id        $Id$
#
# ----------------------------------------------------------------------

fb_log    "Plain_Message" 
fb_info   "Info_Message" 
fb_warn   "Warn_Message"
fb_error  "Error_Message"

set now [clock seconds]
set tt "The time is now : " 
append tt [clock format $now -format %H:%M:%S]

fb_log    $tt 
fb_warn   $now

fireBug $tt -label "A timestamp sample"

# ----------------------------------------------------------------------
#   $Log$
# ----------------------------------------------------------------------