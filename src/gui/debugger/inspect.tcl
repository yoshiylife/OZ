#! wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#

set i [string last / $argv0] ;
if { $i < 0 } { set i 0 } else { incr i }
set j [string last . $argv0] ;
if { $j < 0 } { set j end } else { set j [expr $j -1] }
set cmdName [string range $argv0 $i $j]

global remote
set remote "-L"

global ozroot
set ozroot $env(OZROOT)
set path $ozroot/lib/gui/debugger
#set auto_path [linsert $auto_path 0 $ozroot/lib/gui/debugger]
source $path/unixCommand.tcl
set path $ozroot/lib/gui/debugger
set auto_index(testList) "source $path/testList.tcl"
set auto_index(objectList) "source $path/objectList.tcl"
set auto_index(processList) "source $path/processList.tcl"
set auto_index(objectInspect) "source $path/object.tcl"
set auto_index(processInspect) "source $path/processInspect.tcl"
set auto_index(globalTrace) "source $path/globalTrace.tcl"
set auto_index(threadList) "source $path/threadList.tcl"
set auto_index(buildupNow) "source $path/buildupNow.tcl"

set auto_index(arrayInspect) "source $path/array.tcl"

set auto_index(Record.Recv) "source $path/record.tcl"
set auto_index(Record.Window) "source $path/record.tcl"
set auto_index(Record.Frame) "source $path/record.tcl"
set auto_index(Record.Update) "source $path/record.tcl"

proc	no_op {} \
{
#Nothing
}

proc	error { msgString } \
{
	if { [winfo exists .error] == 0 } {
		frame .error
	}
	tk_dialog .error "Error" $msgString error 0 "OK";
}

proc	invoke { progName id } \
{
	if { [winfo exists .$progName] == 0 } {
		frame .$progName -relief sunken
	}
	if { [winfo exists .$progName.$id] == 0 } {
		$progName .$progName.$id $id
	} else {
		error "Already displayed: $progName $id"
	}
}

proc	invoke2 { progName id obj } \
{
	if { [winfo exists .$progName] == 0 } {
		frame .$progName -relief sunken
	}
	if { [winfo exists .$progName.$id] == 0 } {
		$progName .$progName.$id $id $obj
	} else {
		error "Already displayed: $progName $id"
	}
}

proc	error { msgString } \
{
	if { [winfo exists .error] == 0 } {
		frame .error
	}
	tk_dialog .error "Error" $msgString error 0 "OK";
}

# Main window
if { $argc < 2 } {
wm title . "Debugger(Inspector) Ver 0.01"
#wm geometry . +0+0
wm iconname . "Debugger"

frame	.ribon -relief sunken
button	.ribon.glist -text "Object List" -command "go objectList"
button	.ribon.plist -text "Process List" -command "go processList"
button	.ribon.quit -text "Quit" \
		-command { puts stdout "@q"; flush stdout; destroy .; }

pack	.ribon.glist .ribon.plist -side left -fill x
pack	.ribon.quit -side right -fill x
pack	.ribon -side top -fill x

frame	.sel
radiobutton	.sel.local -text Local -anchor sw -command { set remote "-L" }
radiobutton	.sel.remote -text Remote -anchor sw -command { set remote "-X [strip 6 $argv]" }
pack	.sel.local .sel.remote -side top -fill x -expand yes
pack	.sel -side left

if { $remote == "-L" } {
.sel.local select
}

frame	.id
frame	.id.title
label	.id.title.id -text "ID"
label	.id.title.hex -text "(Hex)"
pack	.id.title.id .id.title.hex -side top

frame	.id.site
label	.id.site.title -text "Site" -anchor w
entry	.id.site.value -width 4 -relief sunken
pack	.id.site.title .id.site.value -side top

frame	.id.exec 
label	.id.exec.title -text "Executor" -anchor e
entry	.id.exec.value -width 6 -relief sunken
pack	.id.exec.title .id.exec.value -side top

pack	.id.title -side left
pack	.id.site -side left
pack	.id.exec -side left
pack	.id -side bottom

bind	.id.exec.value <Tab> { move 6 .id.exec.value .id.site.value }
bind	.id.exec.value <Return> { move 6 .id.exec.value .id.site.value }
bind	.id.site.value <Tab> { move 4 .id.site.value .id.exec.value }
bind	.id.site.value <Return> { move 4 .id.site.value .id.exec.value }

.id.site.value insert 0 [exec cat $ozroot/etc/site-id]
}

proc	strip { width data } \
{
	if { [string range $data 0 1] == "0x"
		|| [string range $data 0 1] == "0X" } {
		set data [string range $data 2 end] ;
	}
	if { [string length $data] > $width } {
		set data [string range $data 0 [expr $width-1]] ;
	}
	return $data ;
}

proc	reform { width input } \
{
	set data [$input get]
	set data [strip width data]
	set x "x"
	set exid [format "%0$width$x" 0x[$input get]]
	$input delete 0 end
	$input insert 0 $exid
}

proc	move { w a b } \
{
	reform $w $a ;
	focus $b ;
}

proc	go { progName } {
	reform 4 .id.site.value
	reform 6 .id.exec.value
	set id [.id.site.value get][.id.exec.value get]000000
	invoke $progName $id
}

if { $argc == 1 } {
	.id.exec.value insert 0 [strip 6 $argv]
	reform 6 .id.exec.value
} elseif { $argc == 2 } {
	invoke [lindex $argv 0] [lindex $argv 1]
} elseif { $argc > 2 } {
	puts stderr "Usage: $cmdName 0x<Target Executor ID>"
	flush stderr
	exit 1
}
