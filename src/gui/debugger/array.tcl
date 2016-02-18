#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	Inspect	Array
#
global	arrayObjectTypes ;
set arrayObjectTypes ARRAY.STATIC.LOCAL.GLOBAL.RECORD ;

proc	arrayInspect { w id { obj 0 } { inst "" } { dm 0 } } {

	catch { destroy $w }
	toplevel $w
	wm title $w "Array Object Inspect $obj"
	wm iconname $w "A-Inspect"
#	wm geometry $w +0+0
	wm minsize $w 390 125
	wm maxsize $w [winfo screenwidth $w]  [winfo screenheight $w]

	Unix.Send $dm "config $obj" ;
	Unix.Recv $dm data ;					#type
	Unix.Status $dm;
	set objectType $data ;
	set type [lindex $objectType 6] ;

	frame $w.ribon
	frame $w.info
	frame $w.array

	button $w.ribon.refresh -text Refresh \
		-command "arrayInspect_Refresh $w $dm $id $obj $type $inst"
	button $w.ribon.inspect -text Inspect \
		-command "arrayInspect_Inspect $w $dm $id $type $inst"
	button $w.ribon.close -text Close \
		-command "destroy $w"
	pack $w.ribon.refresh $w.ribon.inspect -side left -fill x
	pack $w.ribon.close -side right -fill x

	frame $w.info.title
	frame $w.info.value
	label $w.info.title.type -relief raised \
		-text "Object Type:"
	label $w.info.value.type -relief raised \
		-text "$objectType"
	label $w.info.title.inst -relief raised \
		-text "Instance Type:"
	label $w.info.value.inst -relief raised \
		-text "$inst"
	pack $w.info.title.type $w.info.title.inst -side top -fill x
	pack $w.info.value.type $w.info.value.inst -side top -fill x -expand yes

	pack $w.info.title -side left -fill x
	pack $w.info.value -side right -fill x -expand yes

	frame $w.array.list
	label $w.array.list.title -relief raised \
		-text "Array Contents"
	listbox $w.array.list.body -relief raised \
		-yscroll "$w.array.scroll.body set"
#		-font "-misc-fixed-*-*-*-*-14-*-*-*-*-*-*-*"
	frame $w.array.scroll
	label $w.array.scroll.dummy -text " "
	scrollbar $w.array.scroll.body -relief sunken \
		-command "$w.array.list.body yview "
	pack $w.array.list.title -side top -fill x
	pack $w.array.list.body -side bottom -fill both -expand yes
	pack $w.array.scroll.dummy -side top -fill x
	pack $w.array.scroll.body -side bottom -fill y -expand yes

	pack $w.array.list -side left -fill both -expand yes
	pack $w.array.scroll -side right -fill y


	pack $w.ribon -side top -fill x
	pack $w.info -side top -fill x
	pack $w.array -side top -fill both -expand yes

	arrayInspect_Refresh $w $dm $id $obj $type $inst
}


proc	arrayInspect_Refresh { w dm id obj type inst} {
	global arrayObjectTypes ;
	if { [string first $type $arrayObjectTypes] < 0 } {
		destroy $w.array.list.body ;
		text $w.array.list.body ;
		pack $w.array.list.body -side bottom -fill both -expand yes ;
		$w.array.list.body delete 0.0 end ;
		set flag 0 ;
	} else {
		destroy $w.array.list.body ;
		listbox $w.array.list.body -relief raised \
			-yscroll "$w.array.scroll.body set" ;
		pack $w.array.list.body -side bottom -fill both -expand yes ;
		$w.array.list.body delete 0 end ;
		bind $w.array.list.body <Double-1> \
			"arrayInspect_Inspect $w $dm $id $type $inst" ;
		set flag 1 ;
	}
	Unix.Send $dm "instance $obj $inst" ;
	Unix.Recv $dm data ;					#-ARRAY-
	set height 0 ;
	set width 0 ;
	while { [Unix.Recv $dm data] > 0 } {
		if { $flag == 0 } {
			$w.array.list.body insert end "$data\n" ;
			set i [string length $data] ;
			if { $width < $i } { set width $i ; }
			incr height ;
		} else {
			set data [lrange $data 1 end]
			foreach i $data {
				if { $type == "GLOBAL" } {
					set id [string range [lindex $i 0] 2 17]
					set d [format "%10d: %s" $height $id] ;
				} else {
					set id [lindex $i 0]
					set d [format "%10d: *%s" $height $id] ;
				}
				set i [string length $d] ;
				if { $width < $i } { set width $i ; }
				$w.array.list.body insert end $d ;
				incr height ;
			}
		}
	}
	if { $height > 40 } {
		set height 40
		pack $w.array.scroll -side right -fill y ;
	} else {
		set height [incr height]
		pack forget $w.array.scroll ;
	}
	if { $flag == 0 } {
		$w.array.list.body configure -width $width -height $height ;
	} else {
		set height "x$height" ;
		$w.array.list.body configure -geometry $width$height ;
	}
}

proc	arrayInspect_Inspect { w dm id type inst } {
	global arrayObjectTypes ;
	set parent [winfo parent $w]
	if { [string first $type $arrayObjectTypes] < 0 } {
		$w.array.list.body select clear ;
		return ;
	}
	set type [string range $inst 1 end] ;
	foreach i [$w.array.list.body curselection] {
		set data [lindex [$w.array.list.body get $i] 1]
		set name $i ;
		set pos $i ;
		set size [$w.info.value.type configure -text] ;
		set size [lindex [lindex $size 4] 7] ;
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
	$w.array.list.body select clear ;
}
