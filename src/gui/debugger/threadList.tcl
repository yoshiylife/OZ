#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	List up Process
#

proc	threadList { w oid } {

	catch { destroy $w }
	toplevel $w
	wm title $w "Thread List $oid"
	wm iconname $w "T-List"
#	wm geometry $w +0+0
#	wm minsize $w 442 1
#	wm maxsize $w 442 [winfo screenheight $w]
	wm minsize $w 1 1
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w]

	frame $w.ribon
	frame $w.tid
	frame $w.pid
	frame $w.status
	frame $w.scroll

	button $w.ribon.refresh -text Refresh \
		-command "threadList_Refresh $w $oid"
	button $w.ribon.inspect -text Inspect \
		-command "threadList_Inspect $w"
	button $w.ribon.close -text Close \
		-command "destroy $w"
	pack $w.ribon.refresh $w.ribon.inspect -side left -fill x
	pack $w.ribon.close -side right -fill x


	label $w.tid.title -relief raised \
		-text "Thread ID"
	listbox $w.tid.body -relief raised \
		-geometry 11x10 \
		-yscroll "$w.scroll.body set"
	pack $w.tid.title -side top -fill x
	pack $w.tid.body -side bottom -fill both -expand yes


	label $w.pid.title -relief raised \
		-text "Process ID"
	listbox $w.pid.body -relief raised \
		-geometry 17x10 \
		-yscroll "$w.scroll.body set"
	pack $w.pid.title -side top -fill x
	pack $w.pid.body -side bottom -fill both -expand yes


	label $w.status.title -relief raised \
		-text "Thread Status"
	listbox $w.status.body -relief raised \
		-geometry 15x10 \
		-yscroll "$w.scroll.body set"
	pack $w.status.title -side top -fill x
	pack $w.status.body -side bottom -fill both -expand yes

	label $w.scroll.title -text " "
	scrollbar $w.scroll.body -relief sunken \
		-command "threadList_Scroll $w"
	pack $w.scroll.title -side top -fill x
	pack $w.scroll.body -side top -fill y -expand yes


	pack $w.ribon -side top -fill x
	pack $w.tid $w.pid $w.status -side left -fill both -expand yes
	pack $w.scroll -side left -fill y

	bind $w.tid.body <B1-Motion> no_op ;
	bind $w.tid.body <1> no_op ;
	bind $w.status.body <B1-Motion> no_op ;
	bind $w.status.body <1> no_op ;
	bind $w.pid.body <Double-1> "threadList_Inspect $w"

	threadList_Refresh $w $oid ;
}

proc	threadList_Scroll { w pos } {
	$w.tid.body yview $pos ;
	$w.pid.body yview $pos ;
	$w.status.body yview $pos ;
}

proc	threadList_Refresh { w oid } {
	set data [unix_tlist $oid]
	$w.tid.body delete 0 end ;
	$w.pid.body delete 0 end ;
	$w.status.body delete 0 end ;
	foreach l $data {
		$w.tid.body insert end [lindex $l 0]
		$w.pid.body insert end [lindex $l 1]
		$w.status.body insert end [lindex $l 3]
	}
}

proc	threadList_Inspect { w } {
	foreach i [$w.pid.body curselection] {
		set pid [$w.pid.body get $i]
		invoke processInspect $pid
	}
	$w.pid.body select clear
}
