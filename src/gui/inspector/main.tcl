#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# CAUTION
#	This source file is written in tabstop=4,hardtabs=8.

#
# Inspector (Unix command line).
#

set i [string last / $argv0] ;
if { $i < 0 } { set i 0 } else { incr i }
set j [string last . $argv0] ;
if { $j < 0 } { set j end } else { set j [expr $j -1] }
set cmdName [string range $argv0 $i $j]

#
# Global varaible
#
global OZCLASS ;		# local class path (executor id)
global OZROOT ;
set OZCLASS "" ;
set OZROOT "" ;

#
# Check enviroment.
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	errout "You must be setenv OZROOT" ;
	exit 1 ;
}

#
# Common
#
set path $OZROOT/lib/gui ;
source $path/inspector/inspect.tcl ;

#
# Get Site ID.
#
global SiteID ;
if { [catch { set SiteID [exec cat $OZROOT/etc/site-id] ; }] } {
	errout "Can't get site-id" ;
	exit 1 ;
}

#
# Change working direcotry.
#
if { [catch { cd $OZROOT/images ; }] } {
	errout "Can't cd to $OZROOT/images" ;
	exit 1 ;
}

#
# Output error message.
#
proc	errout { msg } \
{
	puts stderr "$cmdName: $msg" ;
	flush stderr ;
}

#
# No operation
#
proc	nop {} {}

#
# Return the last element from list.
#
proc	llast { list } \
{
	set len [llength $list] ;
	if { $len == 0 } {
		return "" ;
	} else {
		return [lindex $list [expr $len - 1]] ;
	}
}

#
# Compatiblity for Tcl-7.4 & Tk-4.0.
#
proc	ReSize { path width height } \
{
	global tk_version ;
	if { $tk_version >= 4.0 } {
		$path configure -width $width -height $height ;
	} else {
		set work x$height ;
		$path configure -geometry $width$work ;
	}
}

#
# List up global object ID from object image files.
#
proc	Inspector.File { win w sid {eid ""} } \
{
	if { $eid == "" } {
		Inspector.Message "Select Executor ID..." ;
		set eid [Inspector.select $win $w.work] ;
		Inspector.Message "Done." ;
	}
	if { $eid == "" } { return ; }
	set p $eid/objects ;
	set opt "-nocomplain" ;
	Inspector.Message "Search..." ;
	set list [glob $opt $p/\[0-f\]\[0-f\]\[0-f\]\[0-f\]\[0-f\]\[0-f\]] ;
	Inspector.Message "Done." ;
	$w.list.oid delete 0 end ;
	$w.list.stat delete 0 end ;
	$w.label.mode configure -text File ;
	$w.mb.update configure -command "Inspector.File $win $w $sid $eid" ;
	foreach path $list {
		set name [llast [split $path /]] ;
		$w.list.oid insert end $sid$eid$name ;
		$w.list.stat insert end "-" ;
	}
	bind $w.list.oid <Double-1> "Inspector.Inspect %W file" ;
}

#
# List up global object ID from local executor.
#
proc	Inspector.Local { win w sid {eid ""} } \
{
	if { $eid == "" } {
		Inspector.Message "Select Executor ID..." ;
		set eid [Inspector.select $win $w.work /tmp/Dm] ;
		Inspector.Message "Done." ;
	}
	if { $eid == "" } { return ; }
	set base 000000 ;
	set cmd "debugger -N objlist -T $sid$eid$base" ;
	Inspector.Message "Search..." ;
	if { [catch { set list [eval "exec $cmd"] }] } {
		Inspector.Message "Not found." ;
		return ;
	}
	Inspector.Message "Done." ;
	$w.list.oid delete 0 end ;
	$w.list.stat delete 0 end ;
	$w.label.mode configure -text Local ;
	$w.mb.update configure -command "Inspector.Local $win $w $sid $eid" ;
	foreach data $list {
		$w.list.oid insert end [lindex $data 0] ;
		$w.list.stat insert end [lindex $data 2] ;
	}
	bind $w.list.oid <Double-1> "Inspector.Inspect %W local" ;
}

#
# List up global object ID from remote executor.
#
proc	Inspector.Remote { win w {sid ""} {eid ""} } \
{
	if { $eid == "" } {
		Inspector.Message "Input Target Executor ID..." ;
		set ids [Inspector.input $win $w.work $sid] ;
		Inspector.Message "Done." ;
	} else {
		set ids [list $sid $eid] ;
	}
	if { [llength $ids] < 2 }  { return ; }
	set sid [lindex $ids 0] ;
	set eid [lindex $ids 1] ;
	set base 000000 ;
	set cmd "debugger -R -N objlist -T $sid$eid$base" ;
	Inspector.Message "Search..." ;
	if { [catch { set list [eval "exec $cmd"] }] } {
		Inspector.Message "Not found." ;
		return ;
	}
	Inspector.Message "Done." ;
	$w.list.oid delete 0 end ;
	$w.list.stat delete 0 end ;
	$w.label.mode configure -text Remote ;
	$w.mb.update configure -command "Inspector.Remote $win $w $sid $eid" ;
	foreach data $list {
		$w.list.oid insert end [lindex $data 0] ;
		$w.list.stat insert end [lindex $data 2] ;
	}
	Inspector.Message "Input Class Executor ID..." ;
	set local [Inspector.select $win $w.work /tmp/Dm] ;
	Inspector.Message "Done." ;
	bind $w.list.oid <Double-1> "Inspector.Inspect %W $local" ;
}

#
# Input Executor ID.
#
proc	Inspector.input { win w {sid ""} } \
{
	global SiteID ;
	global selExID ;	# temporary
	set selExID "" ;

	catch { destroy $w } ;
	toplevel $w ;
	wm title $w "Executor ID" ;
	wm transient $w $win ;
	set pg [winfo geometry $win] ;
	wm geometry $w [string trimleft $pg 0123456789x] ;

	frame $w.footer -bd 3 ;
	pack $w.footer -side bottom -fill x ;
	button $w.footer.dismiss -text "Dismiss" -command "destroy $w" ;
	button $w.footer.commit -text "Commit" -command "$w.commit $w selExID" ;
	pack $w.footer.dismiss $w.footer.commit -side left -expand yes ;

	frame $w.title -bd 3 ;
	pack $w.title -side left -fill both ;
	label $w.title.sid -text "Site ID" -anchor nw ;
	pack $w.title.sid -side top -fill x ;
	label $w.title.eid -text "Executor ID" ;
	pack $w.title.eid -side top -fill x ;

	frame $w.value -bd 3 ;
	pack $w.value -side left ;
	entry $w.value.sid -width 4 -relief sunken ;
	entry $w.value.eid -width 6 -relief sunken ;
	pack $w.value.sid -side top -anchor nw ;
	pack $w.value.eid -side top ;

	bind $w.value.sid <Return> "$w.reform $w 4 %W ; focus $w.value.eid" ;
	bind $w.value.sid <Tab> "$w.reform $w 4 %W ; focus $w.value.eid" ;
	bind $w.value.eid <Return> "$w.reform $w 6 %W ; focus $w.value.sid" ;
	bind $w.value.eid <Tab> "$w.reform $w 6 %W ; focus $w.value.sid" ;
	proc	$w.commit { w var } \
	{
		global SiteID $var ;
		set sid [$w.reform $w 4 $w.value.sid] ;
		if { [string length $sid] != 0 } {
			set sid [format "%04x" 0x$sid] ;
		} else {
			set sid $SiteID ;
		}
		set eid [$w.reform $w 6 $w.value.eid] ;
		if { [string length $eid] == 0 } { return ; }
		set eid [format "%06x" 0x$eid] ;
		set $var [list $sid $eid] ;
		destroy $w ;
	}
	proc	$w.strip { w width data } \
	{
		if { [string index $data 0] == "0" 
			&& [string tolower [string index $data 1]] == "x" } {
				set data [string range $data 2 end] ;
		} elseif { [string tolower [string index $data 1]] == "x" } {
			set data [string range $data 1 end] ;
		}
		if { [string length $data] > $width } {
			set data [string range $data 0 [expr $width-1]] ;
		}
		return $data ;
	}
	proc	$w.reform { w width input } \
	{
		set data [$w.strip $w $width [$input get]] ;
		if { [string length $data] == 0 } { return ; }
		$input delete 0 end ;
		set x x ;
		$input insert 0 [format "%0$width$x" 0x$data] ;
		return $data ;
	}

	$w.value.sid delete 0 end ;
	if { [string length $sid] == 0 } {
		$w.value.sid insert 0 $SiteID ;
	} else {
		$w.value.sid insert 0 $sid ;
	}
	grab $w ;
	tkwait window $w ;
	return $selExID ;
}

#
# Select Executor ID.
#
proc	Inspector.select { win w {path ""} } \
{
	global selExID ;	# temporary
	set selExID "" ;

	catch { destroy $w } ;
	toplevel $w ;
	wm title $w "Executor ID" ;
	wm transient $w $win ;
	set pg [winfo geometry $win] ;
	wm geometry $w [string trimleft $pg 0123456789x] ;

	label $w.title -text "Executor ID" ;
	pack $w.title -side top -fill x ;
	frame $w.eid -bd 1 -relief sunken ;
	pack $w.eid -side top -fill x -expand yes ;
	listbox $w.eid.listbox -yscroll "$w.eid.scroll set" ;
	scrollbar $w.eid.scroll ;
	pack $w.eid.listbox -side left -fill y -expand yes ;
	pack $w.eid.scroll -side right -fill y -expand yes ;

	frame $w.footer ;
	pack $w.footer -side bottom -fill x ;
	button $w.footer.dismiss -text "Dismiss" -command "destroy $w" ;
	button $w.footer.select -text "Select" \
		-command "$w.select $w selExID" ;
	pack $w.footer.dismiss $w.footer.select -side left -expand yes ;


	bind $w.eid.listbox <Double-1> "$w.select $w selExID" ;
	proc	$w.select { w var } \
	{
		global $var ;
		set field $w.eid.listbox ;
		foreach sel [$field curselection] {
			set $var [$field get $sel] ;
			break ;
		}
		destroy $w ;
	}

	set opt "-nocomplain" ;
	set list [glob $opt $path\[0-f\]\[0-f\]\[0-f\]\[0-f\]\[0-f\]\[0-f\]] ;
	$w.eid.listbox delete 0 end ;
	foreach path $list {
		set name [llast [split $path Dm/] ] ;
		$w.eid.listbox insert end $name ;
	}

	grab $w ;
	tkwait window $w ;
	return $selExID ;
}

proc	Inspector.scroll { wins pos } \
{
	foreach w $wins {
		$w yview $pos ;
	}
}

proc	Inspector.suspend { dm oid aObject } \
{
	upvar $aObject obj ;
	set data "" ;

	# Get object table entry
	Unix.Send $dm "getentry $oid" ;
	if { [Unix.Recv $dm data] <= 0 } {
		return "Not found." ;
	}
	Unix.Recv $dm data ;					# entry
	set entry [lindex $data 1] ;
	Unix.Recv $dm data ;					# object
	set obj [lindex $data 1] ;
	Unix.Recv $dm data ;					# size
	Unix.Recv $dm data ;					# parts
	Unix.Recv $dm data ;					# config
	Unix.Status $dm ;						# prompt
	if { $obj == 0 } {
		Unix.Send $dm "relentry $entry" ;
		Unix.Status $dm ;
		return "Not yet loaded." ;
	}

	# Suspend object
	Unix.Send $dm "suspend $entry" ;
	if { [Unix.Status $dm] < 0 } {
		Unix.Send $dm "relentry $entry" ;
		Unix.Status $dm ;
		return "Can't suspend." ;
	}
	return "" ;
}

proc	Inspector.Inspect { w mode } \
{
	foreach i [$w curselection] {
		set oid [$w get $i] ;
		set dm "" ;
		set data "" ;
		set obj "" ;
		switch $mode {
		file	{ Unix.Open $oid dm "-F" ; }
		local	{ Unix.Open $oid dm "-L" ; }
		default { Unix.Open $oid dm "-X $mode" ; }
		}
		Unix.Status $dm ;				# prompt
		if { $mode == "file" } {
			set obj 1 ;
		} else {
			Inspector.Message "Suspend..." ;
			set msg [Inspector.suspend $dm $oid obj] ;
			if { $msg != "" } {
				Inspector.Message $msg ;
				return
			}
			Inspector.Message "Done." ;
		}
		Object.Window $w.$oid $dm $obj $oid O0000000000000000 ;
	}
}

#
# Main window
#
wm withdraw .

set	win ".top" ;
toplevel $win ;
wm title $win "Inspector Ver 0.01"
wm geometry $win +0+0
wm iconname $win "Inspector"
wm maxsize $win [winfo screenwidth $win] [winfo screenheight $win] ;

set	w ".top.main" ;
frame $w ;
pack $w -side top -fill both -expand yes ;

#
# Menu bar
#
frame $w.mb -bd 1 -relief raise ;
pack $w.mb -side top -fill x;

# File
menubutton $w.mb.open -text Open -width 6 -menu $w.mb.open.m ;
menu $w.mb.open.m ;
$w.mb.open.m add command -label "File..." \
	-command "Inspector.File $win $w $SiteID" ;
$w.mb.open.m add command -label "Local..." \
	-command "Inspector.Local $win $w $SiteID" ;
$w.mb.open.m add command -label "Remote..." \
	-command "Inspector.Remote $win $w" ; # -state disabled ;
$w.mb.open.m add separator ;
$w.mb.open.m add command -label "Quit" -command "exit 0" ;
pack $w.mb.open -side left ;

# Update
button $w.mb.update -text Update -width 6 -relief flat ;
pack $w.mb.update -side right ;

#
# Mode
#
frame $w.label ;
pack $w.label -side top -fill x ;
label $w.label.mode -width 6 ;
pack $w.label.mode -side left -fill x -expand yes ;

#
# List box of Global object ID and status
#
frame $w.list -bd 2 ;
pack $w.list -side top -fill both -expand yes ;
listbox $w.list.oid -bd 1 -relief sunken -yscrollcommand "$w.list.scroll set" ;
ReSize $w.list.oid 17 10 ;
listbox $w.list.stat -bd 1 -relief sunken ;
ReSize $w.list.stat 8 10 ;
scrollbar $w.list.scroll -bd 1 -relief sunken \
	-command "Inspector.scroll {$w.list.oid $w.list.stat}" ;
pack $w.list.oid -side left -fill both -expand yes ;
pack $w.list.stat -side left -fill both -expand yes ;
pack $w.list.scroll -side right -fill y ;
tk_listboxSingleSelect $w.list.oid ;

bind $w.list.stat <1> nop ;
bind $w.list.stat <2> nop ;
bind $w.list.stat <3> nop ;
bind $w.list.stat <B1-Motion> nop ;
bind $w.list.stat <B2-Motion> nop ;
bind $w.list.stat <B3-Motion> nop ;
bind $w.list.stat <Double-1> nop ;
bind $w.list.stat <Double-2> nop ;
bind $w.list.stat <Double-3> nop ;

#
# Footer for message
#
frame $w.footer -bd 1 -relief raised ;
pack $w.footer -side bottom -fill x ;
label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
pack $w.footer.msg -side left -fill x -expand yes ;

set body "{$w.footer.msg configure -text \$msg ; update ;}"
eval "proc Inspector.Message { msg } $body" ;

