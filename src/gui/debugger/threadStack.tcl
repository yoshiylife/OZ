#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	Inspect Process
#
proc	processInspect { w pid } {
	set cmdTstack "tdump"

	catch { destroy $w }
	toplevel $w
	wm title $w "Process Inspect $pid"
	wm iconname $w "P-Inspect"
#	wm geometry $w +0+0
	wm minsize $w 230 160
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w]

	set dm [unix_dmopen $pid]

# prompt
	gets $dm data
	debug $data

	request $dm "attach $pid"

	frame $w.ribon -background LightYellow2
	frame $w.info -background LightYellow2
	frame $w.stack -background LightYellow2
	frame $w.content -background LightYellow2

	button $w.ribon.inspect \
		-background LightYellow2 -activebackground SkyBlue1 \
		-text Inspect \
		-command "processInspect_Inspect $w"
	button $w.ribon.kill \
		-background LightYellow2 -activebackground SkyBlue1 \
		-text Kill \
		-command "processInspect_Kill $w $pid"
	button $w.ribon.close \
		-background LightYellow2 -activebackground SkyBlue1 \
		-text Close \
		-command "destroy $w"
	pack $w.ribon.inspect $w.ribon.kill -side left -fill x
	pack $w.ribon.close -side right -fill x


	frame $w.info.title -background LightYellow2
	frame $w.info.value -background LightYellow2
	label $w.info.title.status -background LightYellow2 \
		-relief raised \
		-text "Running Status:"
	label $w.info.value.status -background LightYellow2 \
		-relief raised
	pack $w.info.title.status -side top -fill x
	pack $w.info.value.status -side top -fill x -expand yes

	pack $w.info.title -side left -fill x
	pack $w.info.value -side right -fill x -expand yes

	frame $w.stack.oid -background LightYellow2
	label $w.stack.oid.title -background LightYellow2 \
		-relief raised \
		-text "Global Object Chain"
	listbox $w.stack.oid.list -background LightYellow2 -selectbackground SkyBlue1 \
		-relief raised \
		-yscroll "$w.stack.oid.scroll set"
	scrollbar $w.stack.oid.scroll -foreground LightYellow2 -activeforeground SkyBlue1 \
		 -relief sunken \
		-command "$w.stack.oid.list yview"
	pack $w.stack.oid.title -side top -fill x
	pack $w.stack.oid.list -side left -fill y -expand yes
	pack $w.stack.oid.scroll -side right -fill y -expand yes
	pack $w.stack.oid -side top -fill y -expand yes

	label $w.content.title -background LightYellow2 \
		-relief raised \
		-text "Stack Contents"
	listbox $w.content.list -background LightYellow2 -selectbackground SkyBlue1 \
		-relief raised \
		-font "-misc-fixed-*-*-*-*-14-*-*-*-*-*-*-*" \
		-yscroll "$w.content.scroll set"
	scrollbar $w.content.scroll -foreground LightYellow2 -activeforeground SkyBlue1 \
		 -relief sunken \
		-command "$w.content.list yview "
	pack $w.content.title -side top -fill x
	pack $w.content.list -side left -fill both -expand yes
	pack $w.content.scroll -side right -fill y

	pack $w.ribon -side top -fill x
	pack $w.info -side top -fill x
	pack $w.stack -side top -fill both -expand yes
	pack $w.content -side top -fill both -expand yes

	bind $w.stack.oid.list <B1-Motion> no_op ;
	bind $w.content.list <B1-Motion> no_op ;
	bind $w.stack.oid.list <Double-1> "processInspect_Contents $w "
	bind $w.content.list <Double-1> "processInspect_Inspect $w"

	while { [gets $dm data] > 0 } {
		debug $data
		if { [string compare $data "!CMD>>"] == 0 } { break }
		set data [lindex $data 0]
		if { [string compare [lindex $data 0] "Status:"] == 0 } {
			$w.info.value.status configure -text [lindex $data 1]
			continue ;
		}
		if { [string compare [lindex $data 0] "Handle:"] == 0 } {
			set handle [lindex $data 1]
			set thread [lindex $data 2]
			$w.ribon.close configure -command "processInspect_Close $w $dm $handle $thread"
			continue ;
		}
		$w.stack.oid.list insert end "[lindex $data 1]  [lindex $data 5]"
	}
	set width 29
	set height [$w.stack.oid.list size]
	if { $height > 5 } {
		set height 5
	} else {
		set height [incr height]
	}
	set height "x$height"
	$w.stack.oid.list configure -geometry $width$height

	processInspect_Contents $w

}

proc	processInspect_Close { w dm handle tid } {
	request $dm "detach $handle $tid"

# prompt
	gets $dm data
	debug "prompt $data"

	unix_dmclose $dm
	destroy $w
}

proc	processInspect_Contents { w } {
	set index [$w.stack.oid.list curselection]
	if { $index == "" } {
		set index [expr [$w.stack.oid.list size]-1]
		$w.stack.oid.list select to $index
	}
	set data [$w.stack.oid.list get $index]
	$w.content.title configure -text "Stack Contents [lrange $data 0 1]"
	set data [unix_tdump [lindex $data 0] [lindex $data 1]]
	$w.content.list delete 0 end ;
	set i 0
	foreach l $data {
		incr i
		if { $i == 4 } {
			$w.content.list insert end $l
			set i 0
		}
	}
	set width 70
	set height [$w.content.list size]
	if { $height > 10 } {
		set height 10
	} else {
		set height [incr height]
	}
	set height "x$height"
	$w.content.list configure -geometry $width$height
}

proc	processInspect_Inspect { w } {
#	set parent [winfo parent [winfo parent $w]]
	set progName "objectInspect"
	foreach i [$w.stack.oid.list curselection] {
		set oid [lindex [$w.stack.oid.list get $i] 0]
		invoke $progName $oid
	}
	foreach i [$w.content.list curselection] {
		set work [$w.content.title configure -text]
		set data [lindex $work [expr [llength $work]-1]]
		set id [lindex $data 2]
		invoke2 objectInspect $id [lindex [$w.content.list get $i] 2]
#		if { [winfo exists $parent.$progName] == 0 } {
#			frame $parent.$progName -background LightYellow2 -relief sunken
#		}
#		if { [winfo exists $parent.$progName.$id] == 0 } {
#			$progName $parent.$progName.$id $id [lindex [$w.content.list get $i] 2]
#		} else {
#			error "Already displayed Object: $id"
#		}
	}
}

proc	processInspect_Kill { w pid } {
	invoke buildupNow $pid
}
