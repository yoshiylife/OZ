#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	Inspect Object
#
global dflagsValue ;

proc	objectInspect { w id { obj 0 } { type "" } { dm 0 } } \
{
	global dflags ;

	catch { destroy $w }
	toplevel $w
	if { $dm == 0 } {
		set globalType 1
		wm title $w "Global Object Inspect $id"
		wm iconname $w "G-Inspect"
		Unix.Open $id dm ;

		Unix.Status $dm ;				# prompt
		Unix.Send $dm "getentry $id" ;
		Unix.Recv $dm data ;				# status
		if { [Unix.Recv $dm data] <= 0 } {
			Unix.Close $dm
			destroy $w
			error "Not found object: $id"
			return
		}
		debug "ENTRY:$data" ;
		set entry [lindex $data 1] ;			# entry
		Unix.Recv $dm data ;				# object
		if { $obj == 0 } { set obj [lindex $data 1] ; }
		Unix.Recv $dm data ;				# size
		Unix.Recv $dm data ;				# parts
		Unix.Recv $dm data ;				# config
		Unix.Status $dm ;				# prompt
		if { $obj == 0 } {
			Unix.Close $dm
			destroy $w
			error "Display only loaded object: $id"
			return
		}
		Unix.Send $dm "suspend $entry" ;		# suspend
		if { [Unix.Status $dm] != 0 } {
			error "Already suspended Global Object: $id"
			return
		}
	} else {
		set globalType 0
		wm title $w "Local Object Inspect $id.$obj"
		wm iconname $w "L-Inspect"
	}
#	wm geometry $w +0+0
#	wm minsize $w 460 280
#	wm maxsize $w 460 [winfo screenheight $w]
	wm minsize $w 1 1
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w]

	Unix.Send $dm "config $obj" ;
	Unix.Recv $dm data ;					# type
	set objectType "[lrange $data 0 0 ] [lrange $data 3 end]"
	set config [lindex $data 2]

	frame $w.ribon
	frame $w.info
	frame $w.config
	frame $w.list -bd 5 ;

	button $w.ribon.refresh -text Refresh \
		-command "objectInspect_Refresh $w $dm $id $obj"
	button $w.ribon.inspect -text Inspect \
		-command "objectInspect_Inspect $w $dm $id $globalType"
	if { $globalType == 1 } {
#		button $w.ribon.trace -text Trace \
#			-command "objectInspect_Trace $w $id"
		button $w.ribon.process -text Threads \
			-command "objectInspect_ThreadList $w.tlist $dm $entry $id"
		button $w.ribon.close -text Close \
			-command "objectInspect_Close $w $dm $entry"
		pack $w.ribon.refresh $w.ribon.inspect $w.ribon.process -side left -fill x
	} else {
		button $w.ribon.close -text Close \
			-command "destroy $w"
		pack $w.ribon.refresh $w.ribon.inspect -side left -fill x
	}
	pack $w.ribon.close -side right -fill x


	frame $w.info.title
	frame $w.info.value
	label $w.info.title.type -relief raised \
		-text "Object Type:"
	label $w.info.value.type -relief raised \
		-text "$objectType"

	label $w.info.title.config -relief raised \
		-text "Configured Class ID:"
	label $w.info.value.config -relief raised \
		-text "$config"
	pack $w.info.title.type $w.info.title.config -side top -fill x
	pack $w.info.value.type $w.info.value.config -side top -fill x -expand yes

	pack $w.info.title -side left -fill x
	pack $w.info.value -side right -fill x -expand yes

	Unix.Recv $dm data ;					# title
	Unix.Recv $dm data ;					# title

	label $w.config.title -relief raised \
		-text "Configuration"
	pack $w.config.title -side top -fill x -expand yes

	set conf [objectInspect_Config_Make $w.config $dm $id $obj]

	label $w.title -relief raised -text "Class ID" ;

	label $w.list.title -text "Instance Variables"
	frame $w.list.instance ;
	listbox $w.list.instance.name -relief raised \
		-geometry 40x10 \
		-yscroll "$w.list.scroll set"
#		-font "-misc-fixed-*-*-*-*-14-*-*-*-*-*-*-*"
	listbox $w.list.instance.value -relief raised \
		-geometry 20x10 \
		-yscroll "$w.list.scroll set"
	listbox $w.list.instance.indiv
	scrollbar $w.list.scroll -relief sunken \
		-command "objectInspect_Scroll $w.list.instance"
	pack $w.list.instance.name $w.list.instance.value \
		-side left -fill both -expand yes
	pack $w.list.title -side top -fill x
	pack $w.list.instance -side left -fill both -expand yes ;
	pack $w.list.scroll -side right -fill y ;
	pack $w.list -side left -fill both -expand yes

	frame $w.dflags -bd 5 ;
	label $w.dflags.title -text "Debug Statement ON/OFF" ;

	frame $w.dflags.body ;
	set d $w.dflags.body ;
	checkbutton $w.dflags.body.const -text Constructor -anchor nw \
		-onvalue "0x02" -offvalue "0" -width 12 \
		-variable dflagsValue($d.const) -relief raised ;
	checkbutton $w.dflags.body.public -text Public -anchor nw \
		-onvalue "0x04" -offvalue "0" -width 12 \
		-variable dflagsValue($d.public) -relief raised ;
	checkbutton $w.dflags.body.protected -text Protected -anchor nw \
		-onvalue "0x08" -offvalue "0" -width 12 \
		-variable dflagsValue($d.protected) -relief raised ;
	checkbutton $w.dflags.body.private -text Private -anchor nw \
		-onvalue "0x10" -offvalue "0" -width 12 \
		-variable dflagsValue($d.private) -relief raised ;
	checkbutton $w.dflags.body.record -text Record -anchor nw \
		-onvalue "0x01" -offvalue "0" -width 12 \
		-variable dflagsValue($d.record) -relief raised ;
	pack $w.dflags.body.const -side left ;
	pack $w.dflags.body.public -side left ;
	pack $w.dflags.body.protected -side left ;
	pack $w.dflags.body.private -side left ;
	pack $w.dflags.title -side top ;
	pack $w.dflags.body -side top ;


	pack $w.ribon -side top -fill x
	pack $w.info -side top -fill x
	pack $w.config -side top -fill both
	pack $w.title -side top -fill x ;
	pack $w.dflags -side top -fill x ;
	pack $w.list -side bottom -fill both -expand yes

	bind $conf <Double-1> "objectInspect_Refresh $w $dm $id $obj" ;
	bind $w.list.instance.value <Double-1> \
		"objectInspect_Inspect $w $dm $id $globalType"

	bind $w.list.instance.name <B1-Motion> no_op ;
	bind $w.list.instance.name <Double-1> no_op ;

	objectInspect_Refresh $w $dm $id $obj
}

proc	objectInspect_DebugFlags { w dm obj index } \
{
	global dflagsValue ;
	set d $w.dflags.body ;
	set dflags 0x81000000 ;
	set dflags [expr $dflags | $dflagsValue($d.const)] ;
	set dflags [expr $dflags | $dflagsValue($d.public)] ;
	set dflags [expr $dflags | $dflagsValue($d.protected)] ;
	set dflags [expr $dflags | $dflagsValue($d.private)] ;
	set dflags [expr $dflags | $dflagsValue($d.record)] ;
	Unix.Send $dm "odebug $obj $index [format 0x%08x $dflags]" ;
	Unix.Status $dm ;
}

proc	objectInspect_Scroll { w pos } \
{
	$w.name yview $pos ;
	$w.value yview $pos ;
}

proc	objectInspect_Config_Scroll { w pos } \
{
	$w.runtime.list yview $pos ;
	$w.compiled.list yview $pos ;
}

proc	objectInspect_Config_Make { w dm id obj } \
{
	frame $w.frame
	frame $w.frame.runtime
	label $w.frame.runtime.title -relief raised \
		-text "Runtime ID"
	listbox $w.frame.runtime.list -relief raised \
		-yscroll "$w.frame.scroll.body set"
	pack $w.frame.runtime.title -side top -fill x
	pack $w.frame.runtime.list -side top -fill y -expand yes

	frame $w.frame.compiled
	label $w.frame.compiled.title -relief raised \
		-text "Compiled ID"
	listbox $w.frame.compiled.list -relief raised \
		-yscroll "$w.frame.scroll.body set"
	pack $w.frame.compiled.title -side top -fill x
	pack $w.frame.compiled.list -side top -fill y -expand yes

	frame $w.frame.scroll
	label $w.frame.scroll.title -text " "
	scrollbar $w.frame.scroll.body -relief sunken \
		-command "objectInspect_Config_Scroll $w.frame.list"
	pack $w.frame.scroll.title -side top -fill x
	pack $w.frame.scroll.body -side bottom -fill y -expand yes

	pack $w.frame.runtime $w.frame.compiled -side left -fill y -expand yes
	pack $w.frame.scroll -side right -fill y -expand yes

	pack $w.frame -side top -fill y -expand yes

	while { [Unix.Recv $dm data] > 0 } {
		$w.frame.runtime.list insert end [lindex $data 1]
		$w.frame.compiled.list insert end [lindex $data 2]
	}

	set width 17
	set height [$w.frame.runtime.list size]
	if { $height > 10 } {
		set height 10
	} else {
		set height [incr height]
	}
	set height "x$height"
	$w.frame.runtime.list configure -geometry $width$height
	$w.frame.compiled.list configure -geometry $width$height

	bind $w.frame.runtime.list <B1-Motion> no_op ;
	bind $w.frame.compiled.list <B1-Motion> no_op ;
	bind $w.frame.compiled.list <1> no_op ;

	return $w.frame.runtime.list

}

proc	objectInspect_Config_Selection { w id } \
{
	set index [$w.config.frame.runtime.list curselection]
	if { $index == "" } {
		set index [expr [$w.config.frame.runtime.list size]-1]
		$w.config.frame.runtime.list select to $index
	}
	set data [lindex [$w.config.frame.runtime.list get $index] 0]
	$w.title configure -text "Object Part No.$index $data" ;
	return [list $index $data]
}

proc	objectInspect_Refresh { w dm id obj } \
{
	set data [objectInspect_Config_Selection $w $id]
	set index [lindex $data 0]
	set conf [lindex $data 1]

	Unix.Send $dm "instance $obj $conf $index" ;
	Unix.Recv $dm data ;
	set count [lindex $data 4] ;
	set dflags [lindex $data 5] ;

	set d $w.dflags.body ;
	if { $dflags & 0x02 } {
		$d.const select ;
	} else {
		$d.const deselect ;
	}
	if { $dflags & 0x04 } {
		$d.public select ;
	} else {
		$d.public deselect ;
	}
	if { $dflags & 0x08 } {
		$d.protected select ;
	} else {
		$d.protected deselect ;
	}
	if { $dflags & 0x10 } {
		$d.private select ;
	} else {
		$d.private deselect ;
	}
	if { $dflags & 0x01 } {
		$d.record select ;
	} else {
		$d.record deselect ;
	}
	$d.const configure -command \
		"objectInspect_DebugFlags $w $dm $obj $index" ;
	$d.public configure -command \
		"objectInspect_DebugFlags $w $dm $obj $index" ;
	$d.protected configure -command \
		"objectInspect_DebugFlags $w $dm $obj $index" ;
	$d.private configure -command \
		"objectInspect_DebugFlags $w $dm $obj $index" ;
	$d.record configure -command \
		"objectInspect_DebugFlags $w $dm $obj $index" ;

	set flag 0 ;
	set f $w.list.instance ;
	$f.name delete 0 end
	$f.value delete 0 end
	$f.indiv delete 0 end
	for { set i 0 } { $i < $count } { incr i } {
		if { [Unix.Recv $dm data] < 0 } {
			set flag 1 ;
			break ;
		}
		$f.name insert end [lindex $data 0]
		$f.indiv insert end [lrange $data 1 3]
		$f.value insert end [lindex $data 4]
	}
	set height [$f.name size]
	if { $height > 10 } {
		pack $w.list.scroll -side left -fill y
		set height 10
	} else {
		pack forget $w.list.scroll ;
	}
	if { $height == 0 } {
		$f configure -height 1 ;
		pack forget $f.name $f.value ;
	} else {
		pack $f.name $f.value -side left -fill both -expand yes ;
		set height "x$height" ;
		$f.name configure -geometry 40$height ;
		$f.value configure -geometry 20$height ;
	}
	if { $flag == 0 } { Unix.Status $dm ; }
}

proc	objectInspect_Inspect { w dm id globalType } \
{
	if { $globalType == 0 } {
		set parent [winfo parent $w]
	} else {
		set parent $w
	}
	foreach i [$w.list.instance.value curselection] {
		set name [$w.list.instance.name get $i]
		set indiv [$w.list.instance.indiv get $i] ;
		set pos [lindex $indiv 0] ;
		set size [lindex $indiv 1] ;
		set type [lindex $indiv 2] ;
		set data [$w.list.instance.value get $i]
		if { "[string range $data 0 2]" == "*0x"
			&& "$data" != "*0x00000000" } {
			set d [string range $data 1 end] ;
			set f $parent.$d ;
			if [winfo exists $f] {
				error "Already displayed Object: $d"
				break ;
			}
			frame $f -relief sunken
			switch "[string range $type 0 0]" {
			"*" { arrayInspect $f $id $d $type $dm }
			"R" {
				Unix.Send $dm "record $d $type $size" ;
				set value "" ;
				Record.Recv $dm value ;
				set data [list $name $pos $size $type $value] ;
				Record.Window $f $data ;
			}
			"o" {
				objectInspect $f $id $d $type $dm ;
			}
			default { objectInspect $f $id $d $type $dm }
			}
		} elseif { "[string range $type 0 0]" == "G"
			&& $data != 0 } {
				invoke objectInspect $data
		}
	}
	$w.list.instance.value select clear
	$w.list.instance.name select clear
}

proc	objectInspect_Close { w dm entry } \
{
	Unix.Send $dm "resume $entry"
	Unix.Status $dm ;

	Unix.Send $dm "relentry $entry"
	Unix.Status $dm ;

	Unix.Close $dm
	destroy $w
}

proc	objectInspect_Trace { w id } \
{
#	invoke globalTrace $id
	invoke buildupNow $id
}

proc	objectInspect_ThreadList { w dm entry oid } \
{

	catch { destroy $w }
	toplevel $w
	wm title $w "Global Object Thread List $oid"
	wm iconname $w "GOT-List"
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
		-command "objectInspect_ThreadList_Refresh $w $dm $entry"
	button $w.ribon.inspect -text Inspect \
		-command "objectInspect_ThreadList_Inspect $w"
	button $w.ribon.suspend -text Suspend \
		-command "objectInspect_ThreadList_Suspend $w $dm $entry"
	button $w.ribon.resume -text Resume \
		-command "objectInspect_ThreadList_Resume $w $dm $entry"
	button $w.ribon.close -text Close \
		-command "destroy $w"
	pack $w.ribon.refresh $w.ribon.inspect $w.ribon.suspend $w.ribon.resume -side left -fill x
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
		-command "objectInspect_ThreadList_Scroll $w"
	pack $w.scroll.title -side top -fill x
	pack $w.scroll.body -side top -fill y -expand yes


	pack $w.ribon -side top -fill x
	pack $w.tid $w.pid $w.status -side left -fill both -expand yes
	pack $w.scroll -side left -fill y

	bind $w.status.body <B1-Motion> no_op ;
	bind $w.status.body <1> no_op ;
	bind $w.pid.body <Double-1> "objectInspect_ThreadList_Inspect $w"

	objectInspect_ThreadList_Refresh $w $dm $entry ;
}

proc	objectInspect_ThreadList_Scroll { w pos } \
{
	$w.tid.body yview $pos ;
	$w.pid.body yview $pos ;
	$w.status.body yview $pos ;
}

proc	objectInspect_ThreadList_Refresh { w dm entry } \
{
# prompt
	Unix.Send $dm "tlist $entry"
	#Unix.Recv $dm data ;
	#set data [lindex $data 0]

	$w.tid.body delete 0 end ;
	$w.pid.body delete 0 end ;
	$w.status.body delete 0 end ;
	while { [Unix.Recv $dm data] > 0 } {
		$w.tid.body insert end [lindex $data 0]
		$w.pid.body insert end [lindex $data 1]
		$w.status.body insert end [lindex $data 3]
	}
}

proc	objectInspect_ThreadList_Inspect { w } \
{
	foreach i [$w.pid.body curselection] {
		set pid [$w.pid.body get $i]
		invoke processInspect $pid
	}
	$w.pid.body select clear
}

proc	objectInspect_ThreadList_Suspend { w dm entry } \
{
	foreach i [$w.tid.body curselection] {
		set tid [$w.tid.body get $i]
		Unix.Send $dm "tsuspend $tid" ;
		Unix.Status $dm ;
	}
	$w.tid.body select clear
	objectInspect_ThreadList_Refresh $w $dm $entry ;
}

proc	objectInspect_ThreadList_Resume { w dm entry } \
{
	foreach i [$w.tid.body curselection] {
		set tid [$w.tid.body get $i]
		Unix.Send $dm "tresume $tid" ;
		Unix.Status $dm ;
	}
	$w.tid.body select clear
	objectInspect_ThreadList_Refresh $w $dm $entry ;
}
