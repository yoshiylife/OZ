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
proc	arrayInspect { w id { obj 0 } { inst "" } { dm 0 } } {

	catch { destroy $w }
	toplevel $w
	wm title $w "Array Object Inspect $obj"
	wm iconname $w "A-Inspect"
#	wm geometry $w +0+0
	wm minsize $w 390 125
	wm maxsize $w [winfo screenwidth $w]  [winfo screenheight $w]

	request $dm "config $obj"

# type
	gets $dm data
	debug "type $data"
	set objectType [lindex $data 0]
	set type [lindex $objectType 6]

# prompt
	gets $dm data
	debug "prompt $data"


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
	if { $type == "ARRAY" || $type == "STATIC" || $type == "LOCAL" || $type == "GLOBAL" } {
		set flag 1
	} else {
		set flag 0
	}
	request $dm "instance $obj $inst"
	$w.array.list.body delete 0 end
	set no 0
	while { [gets $dm data] > 0 } {
		debug $data
		if { $data == "!CMD>>" } { break }
		if { $flag == 0 } {
			$w.array.list.body insert end [lindex $data 0]
		} else {
			set data [lindex $data 0]
			set data [lrange $data 1 end]
			foreach i $data {
				if { $type == "GLOBAL" } {
					set id [string range [lindex $i 0] 2 17]
				} else {
					set id [lindex $i 0]
				}
				$w.array.list.body insert end [format "%10d: %s" $no $id]
				incr no
			}
		}
	}
	set width [expr [string length [$w.array.list.body get 0]]+1]
	set height [$w.array.list.body size]
	if { $height > 40 } {
		set height 40
	} else {
		set height [incr height]
	}
	set height "x$height"
	$w.array.list.body configure -geometry $width$height
	if { $flag == 0 } {
		bind $w.array.list.body <1> no_op ;
		bind $w.array.list.body <B1-Motion> no_op ;
		bind $w.array.list.body <Double-1> no_op ;
	} else {
		bind $w.array.list.body <Double-1> "arrayInspect_Inspect $w $dm $id $type $inst"
	}

}

proc	arrayInspect_Inspect { w dm id type inst } {
	set parent [winfo parent $w]
	if { $type == "ARRAY" || $type == "STATIC" || $type == "LOCAL" || $type == "GLOBAL" } {
		foreach i [$w.array.list.body curselection] {
			set type [string range $inst 1 end]
			set target [lindex [$w.array.list.body get $i] 1]
			if { $target != "0x00000000" && $target != "0000000000000000" } {
				if { [winfo exists "$parent.$target"] == 0 } {
					set t [string range $type 0 0]
					if { $t == "*" } {
						frame $parent.$target -relief sunken
						arrayInspect $parent.$target $id $target $type $dm
					} else {
						if { $t == "G" } {
							invoke objectInspect $target
						} else {
							objectInspect $parent.$target $id $target $type $dm
						}
					}
				} else {
					error "Already displayed: $target"
				}
			}
		}
	}
	$w.array.list.body select clear
}
