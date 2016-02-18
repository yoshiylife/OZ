#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	Exception Capture
#		(No operation)
#

wm title . "ExceptionCapture"
wm iconname . "ExceptionCapture"
frame .ribon ;
button .ribon.quit -text "Close" -command "exit" ;
pack .ribon.quit -side right ;
pack .ribon

proc	exceptionName { eid } \
{
	set h_cid [string range $eid 0 7] ;
	set l_cid [string range $eid 7 15] ;
	set id [string range $eid 17 end] ;
	if { $h_cid == 0 && $l_cid == 0 && $id <= 15 } {
		set name $id ;
		set name [lindex { \
				DoubleFault \
				Any \
				Undefined \
				Abort \
				ChildAborted \
				ObjectNotFound \
				ClassNotFound \
				CodeNotFound \
				LayoutNotFound 
				GlobalInvokeFailed \
				NoMemory \
				ForkFailed \
				KillSelf \
				ChildDoubleFault \
				IllegalInvoke \
				NarrowFailed \
				ArrayRangeOverflow \
				TypeCorrectionFailed } [expr $id+2]] ;
	} else {
		set name $id ;
	}
	return $name ;
}

proc	createExceptionCapture { w id } \
{
	toplevel $w ;
	wm title $w "Exception Capture: $id"
	wm iconname $w $id
#	wm geometry $w +0+0 ;
#	wm minsize $w 442 1 ;
#	wm maxsize $w 442 [winfo screenheight $w] ;
	wm minsize $w 1 1
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w] ;

	frame $w.ribon ;
	frame $w.oid -relief raised -bd 1 ;
	frame $w.cid -relief raised -bd 1 ;
	frame $w.name -relief raised -bd 1 ;
	frame $w.arg -relief raised -bd 1 ;
	frame $w.stat -relief raised -bd 1 ;
	frame $w.scroll ;

	button $w.ribon.close -text "Close" -command "destroy $w" ;
	pack $w.ribon.close -side right ;

	label $w.oid.title -text "Global Object ID" -relief sunken -bd 1 ;
	listbox $w.oid.body -geometry 17x5 -yscroll "$w.scroll.body set" \
		-relief sunken -bd 1 ;
	pack $w.oid.title -side top -fill x ;
	pack $w.oid.body -side bottom -fill both -expand yes ;

	label $w.cid.title -text "Class ID" -relief sunken -bd 1 ;
	listbox $w.cid.body -geometry 17x5 -yscroll "$w.scroll.body set" \
		-relief sunken -bd 1 ;
	pack $w.cid.title -side top -fill x ;
	pack $w.cid.body -side bottom -fill both -expand yes ;

	label $w.name.title -text "Exception #" -relief sunken -bd 1 ;
	listbox $w.name.body -geometry 8x5 -yscroll "$w.scroll.body set" \
		-relief sunken -bd 1 ;
	pack $w.name.title -side top -fill x ;
	pack $w.name.body -side bottom -fill both -expand yes ;

	label $w.arg.title -text "Argument" -relief sunken -bd 1 ;
	listbox $w.arg.body -geometry 19x5 -yscroll "$w.scroll.body set" \
		-relief sunken -bd 1 ;
	pack $w.arg.title -side top -fill x ;
	pack $w.arg.body -side bottom -fill both -expand yes ;

	label $w.stat.title -text "Status" -relief sunken -bd 1 ;
	listbox $w.stat.body -geometry 10x5 -yscroll "$w.scroll.body set" \
		-relief sunken -bd 1 ;
	pack $w.stat.title -side top -fill x ;
	pack $w.stat.body -side bottom -fill both -expand yes ;

	label $w.scroll.title -text " " -relief sunken -bd 1 ;
	scrollbar $w.scroll.body -command "exceptionCapture_Scroll $w" \
		-relief sunken -bd 1 ;
	pack $w.scroll.title -side top -fill x ;
	pack $w.scroll.body -side top -fill y -expand yes ;

	pack $w.ribon -side top -fill x ;
	pack $w.oid -side left -fill y ;
	pack $w.cid -side left -fill y ;
	pack $w.name -side left -fill both -expand yes ;
	pack $w.arg -side left -fill y ;
	pack $w.stat -side left -fill both -expand yes ;
	pack $w.scroll -side left -fill y ;

}

proc	exceptionCapture_Scroll { w pos } \
{
	$w.oid.body yview $pos ;
	$w.cid.body yview $pos ;
	$w.name.body yview $pos ;
	$w.arg.body yview $pos ;
	$w.stat.body yview $pos ;
}

proc	captureLoop { } \
{
	set data [gets stdin] ;
	if { [string length $data] < 120 } {
		return ;
	}
	set head [string range $data 0 120] ;
	set data [string range $data 120 end] ;
	set cf [lindex $head 2] ;
	set tid [lindex $head 3] ;
	set pid [lindex $head 4] ;
	set oid [lindex $head 5] ;
	set eid [lindex $head 6] ;
	set arg [lindex $head 7] ;
	set stat [lindex $data 0] ;
	if { [winfo exists .$cf$tid ] == 0 } {
		createExceptionCapture .$cf$tid $pid
		update ;
	}
	set name [exceptionName $eid] ;
	.$cf$tid.oid.body insert end $oid ;
	.$cf$tid.cid.body insert end [string range $eid 0 15] ;
	.$cf$tid.name.body insert end $name ;
	.$cf$tid.arg.body insert end $arg ;
	.$cf$tid.stat.body insert end $stat ;
	update ;
	puts stdout "ok" ;
	flush stdout ;
}

#set data "0x11111111 0x22222222 x 3333333333333333 4444444444444444 5555555555555555 6666666666666666:00000001 8888888899999999:A DoubleFault Continue"

addinput stdin "captureLoop" ;
