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

