#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#
global OZROOT ;
set OZROOT $env(OZROOT) ;
set path $OZROOT/lib/gui ;
set auto_index(Unix.Open) "source $path/inspector/unix.tcl"
set auto_index(Data.Frame) "source $path/inspector/data.tcl"
set auto_index(Data.wm) "source $path/inspector/data.tcl"
set auto_index(Object.Window) "source $path/inspector/object.tcl"
set auto_index(Object.window) "source $path/inspector/object.tcl"
set auto_index(Object.Inspect) "source $path/inspector/object.tcl"
set auto_index(Array.Window) "source $path/inspector/array.tcl"
set auto_index(Array.window) "source $path/inspector/array.tcl"
set auto_index(Array.Inspect) "source $path/inspector/array.tcl"
set auto_index(Record.Window) "source $path/inspector/record.tcl"
set auto_index(Record.window) "source $path/inspector/record.tcl"
set auto_index(Record.Inspect) "source $path/inspector/record.tcl"
set auto_index(Process.Window) "source $path/inspector/process.tcl"
set auto_index(Process.window) "source $path/inspector/process.tcl"
set auto_index(Process.Inspect) "source $path/inspector/process.tcl"

proc	Inspect { win oid name type obj {mode remote} } \
{
	set dm "" ;
	set data "" ;
	switch $mode {
	file	{ Unix.Open $oid dm "-F" ; }
	local	{ Unix.Open $oid dm "-L" ; }
	remote	{ Unix.Open $oid dm "-X 0x[string range $oid 4 9]"; }
	default	{ Unix.Open $oid dm "-X $mode"; }
	}
	Unix.Status $dm ;				# prompt
	switch "[string toupper [string range $type 0 0]]" {
	"*" { Array.Window $win $dm $obj $name $type ; }
	"R" { Record.Window $win $dm $obj $name $type ; }
	"O" { Object.Window $win $dm $obj $name $type ; }
	"@" { Process.Window $win $dm $obj $name $type ; }
	default { ; }
	}
}

proc	Address { dm oid aObject } \
{
	upvar $aObject obj ;
	set data "" ;
	Unix.Send $dm "getentry $oid" ;
	Unix.Recv $dm data ;				# status
	if { [Unix.Recv $dm data] <= 0 } {
		return "Not found Global Object: $oid" ;
	}
	set entry [lindex $data 1] ;			# entry
	Unix.Recv $dm data ;				# object
	set obj [lindex $data 1] ;
	Unix.Recv $dm data ;				# size
	Unix.Recv $dm data ;				# parts
	Unix.Recv $dm data ;				# config
	Unix.Status $dm ;				# prompt
	if { $obj == 0 } {
		return "Not loading Global Object: $oid" ;
	}
	return "" ;
}

proc	GlobalInspect { w oid type {mode remote} } \
{
	set dm "" ;
	set data "" ;
	switch $mode {
	file	{ Unix.Open $oid dm "-F" ; }
	local	{ Unix.Open $oid dm "-L" ; }
	default	{ Unix.Open $oid dm "-X [string range $oid 4 9]" ; }
	}
	Unix.Status $dm ;				# prompt
	if { $mode == "file" } {
		set obj 1 ;
	} else {
		set msg [Address $dm $oid obj] ;
		if { $msg != "" } {
			error $msg ;
			destroy $win ;
			return
		}
	}

	set ribon [Object.Window $w $dm $obj $oid $type] ;
	if { $mode != "file" } {
		button $ribon.threads -relief flat -bd 1 \
			-text "Threads" ;
		pack $ribon.threads -side left ;
	}
}

#Inspect . 0fff00110c000005 TEST R0fff00110c000033 0xeedca1a8 ;
#Inspect . 0fff00110c000005 TEST *O00010000020006a1 0xeedde0d8 ;
#Inspect . 0fff001500000002 PROBLEM * 0xeeb09d90 ;

#GlobalInspect . 0001001902000002 O0000000000000000 ;
#Process.Inspect . 0001000001000002 ;

#Inspect . 0001001902000026 Exception O00010000020002e5 0xf6c4ef80 ;
#Inspect . 0001001902000026 Exception O00010000020002e5 0xf6b883b0 ;

#GlobalInspect . 0001001902000005 0000000000000000 ;
#Inspect . 0001001902000005 TEST O000100190200005b 0xf69b6068 ;
#Inspect . 0001001902000005 Process @v 0x000065 ;
#Inspect . 0f0f000e01000003 Exception O0000000000000000 0xeeb13ce0 ;
#GlobalInspect . 0f0f000e04000060 O0000000000000000 ;
