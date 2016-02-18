#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	Unix command
#
proc	debug { msgString } \
{
	puts stderr "$msgString" ;
	flush stderr ;
}

proc	Unix.Open { oid aFile { option "" } } \
{
	global OZROOT ;
	upvar $aFile file ;
	global Unix.Option ;
	set cmd "$OZROOT/bin/debugger $option -N objinspect -T $oid" ;
	debug "OPEN:$cmd" ;
	return [catch { set file [open |$cmd "r+"] ; }] ;
}

proc	Unix.Close { file } \
{
	Unix.Send $file "quit" ;
	catch { close $file ; }
}

proc	Unix.Recv { file aBuff } \
{
	upvar $aBuff buff ;
	set ret [gets $file buff] ;
	set buff [lindex $buff 0] ;
	if { $ret < 0 } {
		debug "RECV GETS ERROR" ;
	} else {
		debug "RECV:$buff" ;
		if { $buff == "!CMD>>" } {
			set ret -1 ;
		} elseif { $buff == "!Error" } {
			gets $file buff ;			# prompt
			set ret -2 ;
		}
	}
	return $ret ;
}

proc	Unix.Status { file } \
{
	set status 0 ;
	while { 1 } {
		set ret [gets $file data] ;
		set data [lindex $data 0] ;
		if { $ret < 0 } {
			debug "SKIP GETS ERROR" ;
			set status -3 ;
			break ;
		} else {
			debug "SKIP:$data" ;
			if { $data == "!CMD>>" } {
				if { $status < 0 } {
					set status -1 ;
				}
				break ;
			} elseif { $data == "!Error" } {
				set status -2 ;
			}
		}
	}
	debug "SKIP BREAK" ;
	return $status ;
}

proc	Unix.Send { file buff } \
{
	debug "SEND:$buff" ;
	puts $file $buff ;
	flush $file ;
}
