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

proc	processList { w exid } {

	catch { destroy $w }
	toplevel $w
	wm title $w "Process List [string range $exid 4 9]"
	wm iconname $w "P-List"
#	wm geometry $w +0+0
#	wm minsize $w 442 1
#	wm maxsize $w 442 [winfo screenheight $w]
	wm minsize $w 1 1
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w]

	frame $w.ribon
	frame $w.pid
	frame $w.oid
	frame $w.status
	frame $w.scroll

	button $w.ribon.refresh -text Refresh \
		-command "processList_Refresh $w $exid"
	button $w.ribon.inspect -text Inspect \
		-command "processList_Inspect $w"
	button $w.ribon.kill -text Kill \
		-command "processList_Kill $w"
	button $w.ribon.status -text Status \
		-command "processList_Status $w"
	button $w.ribon.close -text Close \
		-command "destroy $w"
	pack $w.ribon.refresh $w.ribon.inspect $w.ribon.kill $w.ribon.status -side left -fill x
	pack $w.ribon.close -side right -fill x


	label $w.pid.dummy -text " "
	label $w.pid.title -relief raised \
		-text "Process ID"
	listbox $w.pid.body -relief raised \
		-geometry 17x10 \
		-yscroll "$w.scroll.body set"
	pack $w.pid.dummy $w.pid.title -side top -fill x
	pack $w.pid.body -side bottom -fill both -expand yes


	label $w.oid.dummy -text " "
	label $w.oid.title -relief raised \
		-text "Global Object ID"
	listbox $w.oid.body -relief raised \
		-geometry 17x10 \
		-yscroll "$w.scroll.body set"
	pack $w.oid.dummy $w.oid.title -side top -fill x
	pack $w.oid.body -side bottom -fill both -expand yes


	label $w.status.title -relief raised \
		-text "Status"

	frame $w.status.pt
	label $w.status.pt.title -relief raised \
		-text "PT"
	listbox $w.status.pt.body -relief raised \
		-geometry 15x10 \
		-yscroll "$w.scroll.body set"
	pack $w.status.pt.title -side top -fill x
	pack $w.status.pt.body -side bottom -fill both -expand yes

	frame $w.status.ps
	label $w.status.ps.title -relief raised \
		-text "PS"
	listbox $w.status.ps.body -relief raised \
		-geometry 18x10 \
		-yscroll "$w.scroll.body set"
	pack $w.status.ps.title -side top -fill x
	pack $w.status.ps.body -side bottom -fill both -expand yes

	pack $w.status.title -side top -fill x
	pack $w.status.pt -side left -fill both -expand yes
	pack $w.status.ps -side left -fill both -expand yes


	label $w.scroll.dummy -text " "
	label $w.scroll.title -text " "
	scrollbar $w.scroll.body -relief sunken \
		-command "processList_Scroll $w"
	pack $w.scroll.dummy $w.scroll.title -side top -fill x
	pack $w.scroll.body -side bottom -fill both -expand yes


	pack $w.ribon -side top -fill x
	pack $w.pid $w.oid $w.status -side left -fill both -expand yes
	pack $w.scroll -side right -fill y

#	bind $w.pid.body <B1-Motion> no_op ;
#	bind $w.oid.body <B1-Motion> no_op ;
	bind $w.status.pt.body <1> no_op ;
	bind $w.status.pt.body <B1-Motion> no_op ;
	bind $w.status.ps.body <1> no_op ;
	bind $w.status.ps.body <B1-Motion> no_op ;
	bind $w.pid.body <Double-1> "processList_Inspect $w"
	bind $w.oid.body <Double-1> "processList_Inspect $w"

	processList_Refresh $w $exid ;
}

proc	processList_Scroll { w pos } {
	$w.pid.body yview $pos ;
	$w.oid.body yview $pos ;
	$w.status.pt.body yview $pos ;
	$w.status.ps.body yview $pos ;
}

proc	processList_Refresh { w exid } {
	set data [unix_proclist $exid]
	$w.pid.body delete 0 end ;
	$w.oid.body delete 0 end ;
	$w.status.pt.body delete 0 end ;
	$w.status.ps.body delete 0 end ;
	foreach l $data {
		$w.pid.body insert end [lindex $l 0]
		$w.oid.body insert end [lindex $l 2]
		$w.status.pt.body insert end [lindex $l 4]
		$w.status.ps.body insert end ""
	}
}

proc	processList_Inspect { w } {
	foreach i [$w.oid.body curselection] {
		set oid [$w.oid.body get $i]
		invoke objectInspect $oid
	}
	$w.oid.body select clear
	foreach i [$w.pid.body curselection] {
		set pid [$w.pid.body get $i]
		set status [$w.status.pt.body get $i]
		if { $status == "EXITED" || $status == "KILLED" } {
			error "Already $pid status is $status"
		} else {
			invoke processInspect $pid
		}
	}
	$w.pid.body select clear
}

proc	processList_Status { w } {
	foreach i [$w.pid.body curselection] {
		set pid [$w.pid.body get $i]
		set data [unix_procstat $pid]
		$w.status.ps.body delete $i
		$w.status.ps.body insert $i [lindex [lindex $data 0] 1]
	}
}

proc	processList_Kill { w } {
	foreach i [$w.pid.body curselection] {
		set pid [$w.pid.body get $i]
		invoke buildupNow $pid
	}
}
