#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	Capture Exception
#

wm title . "ExceptionMonitor"
wm iconname . "ExceptionMonitor"
frame .ribon ;
button .ribon.quit -text "Close" -command "exit" ;
pack .ribon.quit -side right ;
pack .ribon

proc	createCapWindow { w name } \
{
	toplevel $w ;
	wm title $w $name
	wm iconname $w $name
#	wm geometry $w +0+0 ;
#	wm minsize $w 442 1 ;
#	wm maxsize $w 442 [winfo screenheight $w] ;
	wm minsize $w 1 1
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w] ;

	frame $w.ribon ;
	button $w.ribon.abort -text "Abort"
	button $w.ribon.cont -text "Continue"
	button $w.ribon.quit -text "Close" -command "destroy $w" ;
	pack $w.ribon.abort -side left ;
	pack $w.ribon.cont -side left ;
	pack $w.ribon.quit -side right ;

	frame $w.log -relief raised -borderwidth 1 ;
	listbox $w.log.msg -relief sunken -borderwidth 1 \
		-yscrollcommand "$w.log.bar set" ;
	scrollbar $w.log.bar -command "$w.log.msg yview" ;
	pack $w.log.msg -side left -fill both -expand yes ;
	pack $w.log.bar -side right -fill y ;

	pack $w.ribon -side top -fill x -expand yes ;
	pack $w.log -side top -fill both -expand yes ;
}

proc	MainLoop { } \
{
	set data [gets stdin] ;
	if { [string length $data] < 74 } {
		return ;
	}
	set head [string range $data 0 74] ;
	set data [string range $data 75 end] ;
	set cf [lindex $head 2] ;
	set id [lindex $head 3] ;
	set pid [lindex $head 4] ;
	set oid [lindex $head 5] ;
	if { [winfo exists .$cf$id ] == 0 } {
		if { "@" == [string range $cf 0 0] } {
			set name "Capture DebugMessage Process:$pid"
		} elseif { "#" == [string range $cf 0 0] } {
			set name "Capture DebugMessage Object:$oid"
		} elseif { "!" == [string range $cf 0 0] } {
			set name "Capture Exception Process:$pid on Object:$oid"
		} else {
			set name "Capture DebugMessage $pid from $oid"
		}
		createCapWindow .$cf$id $name
		update ;
	}
	.$cf$id.log.msg insert end "$data\n"
#	.$cf$id.log.msg yview -pickplace insert ;
	update ;
	puts stdout "ok" ;
	flush stdout ;
}

global count ;
set count 0 ;

#set head "0x12345678 0x12345678 x 1234567890123456 1234567890123456 1234567890123456"
#debugMessage $head "test message 1" ;
#debugMessage $head "test message 2" ;

addinput stdin "MainLoop" ;
