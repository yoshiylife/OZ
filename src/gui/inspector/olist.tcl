#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	List up Global Object
#

proc	objectList { w exid } {

	catch { destroy $w }
	toplevel $w
	wm title $w "Global Object List [string range $exid 4 9]"
	wm iconname $w "O-List"
#	wm geometry $w +0+0
#	wm minsize $w 400 1
#	wm maxsize $w 400 [winfo screenheight $w]
	wm minsize $w 1 1
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w]

	frame $w.ribon
	frame $w.oid
	frame $w.cid
	frame $w.status
	frame $w.scroll

	button $w.ribon.refresh -text Refresh \
		-command "objectList_Refresh $w $exid"
	button $w.ribon.inspect -text Inspect \
		-command "objectList_Inspect $w"
#	button $w.ribon.process -text Process \
#		-command "objectList_Process $w $exid"
	button $w.ribon.snap -text Snap \
		-command "objectList_Snap $w"
	button $w.ribon.status -text Status \
		-command "objectList_Status $w"
	button $w.ribon.close -text Close \
		-command "destroy $w"
#	pack $w.ribon.refresh $w.ribon.inspect $w.ribon.process $w.ribon.snap $w.ribon.status -side left -fill x
	pack $w.ribon.refresh $w.ribon.inspect $w.ribon.snap $w.ribon.status -side left -fill x
	pack $w.ribon.close -side right -fill x


	label $w.oid.dummy -text " "
	label $w.oid.title -relief raised \
		-text "Global Object ID"
	listbox $w.oid.body -relief raised \
		-geometry 17x10 \
		-yscroll "$w.scroll.body set"
	pack $w.oid.dummy $w.oid.title -side top -fill x
	pack $w.oid.body -side bottom -fill both -expand yes


	label $w.cid.dummy -text " "
	label $w.cid.title -relief raised \
		-text "Configured ID"
	listbox $w.cid.body -relief raised \
		-geometry 17x10 \
		-yscroll "$w.scroll.body set"
	pack $w.cid.dummy $w.cid.title -side top -fill x
	pack $w.cid.body -side bottom -fill both -expand yes


	label $w.status.title -relief raised \
		-text "Status"

	frame $w.status.ot
	label $w.status.ot.title -relief raised \
		-text "OT"
	listbox $w.status.ot.body -relief raised \
		-geometry 9x10 \
		-yscroll "$w.scroll.body set"
	pack $w.status.ot.title -side top -fill x
	pack $w.status.ot.body -side bottom -fill both -expand yes

	frame $w.status.om
	label $w.status.om.title -relief raised \
		-text "OM"
	listbox $w.status.om.body -relief raised \
		-geometry 10x10 \
		-yscroll "$w.scroll.body set"
	pack $w.status.om.title -side top -fill x
	pack $w.status.om.body -side bottom -fill both -expand yes

	pack $w.status.title -side top -fill x
	pack $w.status.ot -side left -fill both -expand yes
	pack $w.status.om -side left -fill both -expand yes


	label $w.scroll.dummy -text " "
	label $w.scroll.title -text " "
	scrollbar $w.scroll.body -relief sunken \
		-command "objectList_Scroll $w"
	pack $w.scroll.dummy $w.scroll.title -side top -fill x
	pack $w.scroll.body -side top -fill y -expand yes


	pack $w.ribon -side top -fill x
	pack $w.oid $w.cid $w.status -side left -fill both -expand yes
	pack $w.scroll -side left -fill y

#	bind $w.oid.body <B1-Motion> no_op ;
#	bind $w.cid.body <B1-Motion> no_op ;
	bind $w.status.ot.body <1> no_op ;
	bind $w.status.ot.body <B1-Motion> no_op ;
	bind $w.status.om.body <1> no_op ;
	bind $w.status.om.body <B1-Motion> no_op ;
	bind $w.oid.body <Double-1> "objectList_Inspect $w"

	objectList_Refresh $w $exid ;
}

proc	objectList_Scroll { w pos } {
	$w.oid.body yview $pos ;
	$w.cid.body yview $pos ;
	$w.status.ot.body yview $pos ;
	$w.status.om.body yview $pos ;
}

proc	objectList_Refresh { w id } {
	set data [unix_objlist $id]
	$w.oid.body delete 0 end ;
	$w.cid.body delete 0 end ;
	$w.status.ot.body delete 0 end ;
	$w.status.om.body delete 0 end ;
	foreach l $data {
		$w.oid.body insert end [lindex $l 0]
		$w.cid.body insert end [lindex $l 1]
		$w.status.ot.body insert end [lindex $l 2]
		$w.status.om.body insert end ""
	}
}

proc	objectList_Inspect { w } {
	foreach i [$w.oid.body curselection] {
		set id [$w.oid.body get $i]
		invoke objectInspect $id
	}
	$w.oid.body select clear
}

proc	objectList_Snap { w } {
	foreach i [$w.oid.body curselection] {
		set id [$w.oid.body get $i]
		invoke buildupNow $id
	}
	$w.oid.body select clear
}

proc	objectList_Status { w } {
	foreach i [$w.oid.body curselection] {
		set id [$w.oid.body get $i]
		invoke buildupNow $id
	}
	$w.oid.body select clear
}

#proc	objectList_Process { w id } {
#	foreach i [$w.oid.body curselection] {
#		set id [$w.oid.body get $i]
#		invoke threadList $id
#	}
#	$w.oid.body select clear
#}
