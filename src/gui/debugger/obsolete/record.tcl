#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#

proc	Record.Window { win data } \
{
# Base Window
	set w [string trimright $win '.'] ;
	set base [lindex $data 0] ;
	set r $w.record ;
	if { $w != "" } {
		catch { destroy $win ; }
		toplevel $win ;
	}
	Record.wm $win "Inspect: $base" $base ;

	frame $w.ribon ;
	button $w.ribon.close -text "Close" -command "destroy $win" ;
	button $w.ribon.up -text "Up" -command "Record.up $r $r $r.path" ;
	pack $w.ribon.up -side left ;
	pack $w.ribon.close -side right ;
	pack $w.ribon -side top -fill x ;

	if [catch { Record.Frame $r $data }] { return ; }
	pack $r -side top -fill both -expand yes ;
	Record.Update $r $r $base ;

# Indivisual data
	entry $w.record.leader ;
	$w.record.leader delete 0 end ;
	$w.record.leader insert 0 $win ;
}

proc	Record.window { p w path } \
{
# Sub Window
	catch { destroy $w ; }
	toplevel $w ;
	Record.wm $w $path $path ;

#	wm group $w [$p.leader get] ;
	if { [winfo exists $p.leader] != 0 } {
		wm transient $w [$p.leader get] ;
	}

	if { [catch { Record.frame $w } ""] == "" } { return ; }
#	pack $w -side top -fill both -expand yes ;
	Record.Update $p $w $path ;

# Indivisual data
	entry $w.leader ;
	$w.leader delete 0 end ;
	$w.leader insert 0 $p ;
}

proc	Record.wm { w title iconname } \
{
	wm minsize $w 1 1
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w] ;
	wm title $w $title ;
	wm iconname $w $iconname ;
}

proc	Record.Frame { w data } \
{
	frame $w -relief sunken -bd 1 ;

# Indivisual data
	entry $w.data ;
	$w.data delete 0 end ;
	$w.data insert 0 $data ;

	Record.frame $w ;

# Setup Binding
	bind $w.name.list <Double-1> \
		"Record.down $w $w $w.path $w.name.list" ;

	return $w ;
}

proc	Record.frame { w } \
{
# Class ID
	frame $w.cid ;
	label $w.cid.title -relief sunken -bd 1 -text Record ;
	label $w.cid.value -anchor nw -relief sunken -bd 1 ;
	pack $w.cid.title -side left ;
	pack $w.cid.value -side right -fill x -expand yes ;
	pack $w.cid -side top -fill x ;

# Access path
	label $w.path -anchor nw -relief sunken -bd 1 ;
	pack $w.path -side top -fill x ;

	label $w.comment -relief sunken -bd 1 -text "----- Nothing -----" ;

# Record member name
	frame $w.name ;
#	label $w.name.title -text "Name" ;
	listbox $w.name.list -relief sunken -bd 1 ;
#	pack $w.name.title -side top -fill x ;
	pack $w.name.list -side top -fill both -expand yes ;

# Record member value
	frame $w.value ;
#	label $w.value.title -text "Value" ;
	listbox $w.value.list -relief sunken -bd 1 ;
#	pack $w.value.title -side top -fill x ;
	pack $w.value.list -side top -fill y -expand yes ;

# Scrollbar for name&value
	frame $w.scroll ;
#	label $w.scroll.title -text " " ;
	scrollbar $w.scroll.body -relief sunken -bd 1 \
		-command "Record.scroll $w" ;

# Indivisual data
	listbox $w.list ;

	return $w ;
}

proc	Record.Update { p w path } \
{
	set list [Record.search $p $path] ;
	set data [lindex $list 4] ;

# Setup ClassID & Access path
	$w.cid.value configure -text [lindex $list 3] ;
	$w.path configure -text $path ;

# Setup Listbox&Scrollbar
	pack forget $w.comment ;
	pack forget $w.name ;
	pack forget $w.value ;
	pack forget $w.scroll ;
	set l [llength $data] ;
	if { $l == 0 } {
		pack $w.comment -side top -fill x ;
	} elseif { $l < 10 } {
		$w.name.list configure -geometry 20x$l ;
		$w.value.list configure -geometry 20x$l ;
		$w.name.list configure -yscroll "" ;
		$w.value.list configure -yscroll "" ;
		pack $w.name -side left -fill both -expand yes ;
		pack $w.value -side left -fill y ;
	} else {
#		pack $w.scroll.title -side top -fill x
		pack $w.scroll.body -side top -fill y -expand yes
		$w.name.list configure -geometry 20x10 \
			-yscroll "$w.scroll.body set" ;
		$w.value.list configure -geometry 20x10 \
			-yscroll "$w.scroll.body set" ;
		pack $w.name -side left -fill both -expand yes ;
		pack $w.value $w.scroll -side left -fill y ;
	}

# Setup Record member
	$w.name.list delete 0 end ;
	$w.value.list delete 0 end ;
	$w.list delete 0 end ;
	foreach a $data {
		$w.name.list insert end [lindex $a 0] ;
		set type [lindex $a 3] ;
		if { "[string range $type 0 0]" == "R" } {
			$w.value.list insert end <[string range $type 1 end]> ;
		} else {
			$w.value.list insert end [lindex $a 4] ;
		}
		$w.list insert end $a ;
	}

# Setup Binding
	bind $w.value.list <Double-1> "Record.select $p $w $path" ;

	update ;
}

proc	Record.override { p w pre field } \
{
	set path [string trimright $pre.[$field get] "."] ;
	if { [Record.search $p $path] == "" } { return ; }
	Record.Update $p $w $path ;
}

proc	Record.down { p w base field} \
{
	set i [lindex [$field curselection] 0] ;
	set path [lindex [$base configure -text] 4].[$field get $i] ;
	if { [Record.search $p $path] == "" } { return ; }
	Record.Update $p $w $path ;
}

proc	Record.up { p w field } \
{
	set path [Record.base [lindex [$field configure -text] 4]] ;
	if { [Record.search $p $path] == "" } { return ; }
	Record.Update $p $w $path ;
}

proc	Record.search { p path } \
{
	set data [list [$p.data get]] ;
	set flag 0 ;
	foreach p [split $path "."] {
		set flag 0 ;
		foreach d $data {
			set name [lindex $d 0] ;
			set type [lindex $d 3] ;
			if { $p == $name && "[string range $type 0 0]" == "R" } {
				set posi [lindex $d 1] ;
				set size [lindex $d 2] ;
				set data  [lindex $d 4] ;
				set flag 1 ;
				break ;
			}
		}
		if { $flag == 0 } { break ; }
	}
	if { $flag == 0 } { return "" ; }
	return [list $name $posi $size $type $data] ;
}

proc	Record.inspect { p path } \
{
	set win [join [split $path "."] "_"] ;
	Record.window $p $p.$win $path ;
}

proc	Record.select { p w path } \
{
	foreach f "$w.name $w.value" {
		foreach i [$f.list curselection] {
			set data [$w.list get $i] ;
			set name [lindex $data 0] ;
			set type [lindex $data 3] ;
			if { "[string range $type 0 0 ]" == "R" } {
				Record.inspect $p $path.$name ;
			}
		}
	}
}

proc	Record.scroll { w pos } \
{
	$w.name.list yview $pos ;
	$w.value.list yview $pos ;
}

proc	Record.base { path } \
{
	set list [split $path "."] ;
	set n [llength $list] ;
	if { $n < 2 } { return "" ; }
	set n [expr $n - 2] ;
	set list [join [lrange $list 0 $n] "."] ;
	return $list ;
}

proc	Record.read { dm count aList } \
{
	upvar $aList list ;
	set ret 0 ;
	for { set i 0 } { $i < $count } { incr i } {
		set ret [Unix.Recv $dm data] ;
		if { $ret < 0 } { break ; }
		set type [lindex $data 3] ;
		if { "[string range $type 0 0]" == "R" } {
			set value "" ;
			set ret [Record.read $dm [lindex $data 4] value ] ;
			if { $ret < 0 } { break ; }
			lappend list [lreplace $data 4 4 $value] ;
		} else {
			lappend list $data ;
		}
	}
	return $ret ;
}

proc	Record.Recv { dm aList } \
{
	upvar $aList list ;
	set value "" ;
	Unix.Recv $dm record ;
	set ret [Record.read $dm [lindex $record 4] value] ;
	Unix.Status $dm ;
	set list $value ;
	return $ret ;
}

proc	Record.test {} \
{
	set r1 "test 0 4 R0001000002000001 {{a 1 4 int 1} {b 2 4 int 2} {c 3 4 R0001000002000002 {{A 0 4 int 1} {B 0 4 R0001000002000003 {{r1_1 0 4 int a} {r1_2 1 4 int b}} } }} {d 4 4 int 4} {d 5 4 int 5} {e 0 4 R0001000002000004 {}} {f 6 4 int 6} {g 7 4 int 7} {h 8 4 int 8} {i 9 4 int 9} {j 10 4 int 10} {k 11 4 int 11}}" ;
	Record.Window . $r1 ;

#	set w .test
#	toplevel $w
#	wm minsize $w 1 1
#	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w] ;
#	wm title $w Record ;
#	wm iconname $w Record ;
#	Record.Frame .test.r $r1 ;
#	button .test.c -text "Close" -command "destroy $w" ;
#	pack .test.c .test.r -side top -fill both -expand yes ;
#	Record.Update .test.r .test.r test ;
}

#Record.test
