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
#	puts stderr "$msgString"
#	flush stderr
}

proc	Unix.Open { oid aFile } \
{
	upvar $aFile file ;
	global remote ;
	set exid [string range $oid 4 9] ;
	set cmd "debugger -X $exid -N objinspect $remote -T $oid" ;
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
	while { 1 } {
		set ret [gets $file data] ;
		set data [lindex $data 0] ;
		if { $ret < 0 } {
			debug "SKIP GETS ERROR" ;
			break ;
		} else {
			debug "SKIP:$data" ;
			if { $data == "!CMD>>" } {
				set ret 0 ;
				break ;
			} elseif { $data == "!Error" } {
				set ret -1 ;
			}
		}
	}
	debug "SKIP BREAK" ;
	return $ret ;
}

proc	Unix.Send { file buff } \
{
	debug "SEND:$buff" ;
	puts $file $buff ;
	flush $file ;
}

proc	request { dm { reqString "\n" } } \
{
	global remote
	puts $dm $reqString
	flush $dm
# for debug
#	puts stderr "REQUEST:$reqString"
#	flush stderr
}

proc	unix_objlist { exid } \
{
	global remote
	set cmd "debugger -N objlist $remote -T $exid" ;
	debug "EXEC: $cmd" ;
	set data [eval "exec $cmd"] ;
	return $data ;
}

proc	unix_proclist { exid } \
{
	global remote
	set cmd "debugger -N proclist $remote -T $exid" ;
	debug "EXEC: $cmd" ;
	set data [eval "exec $cmd"] ;
	return $data ;
}

proc	unix_procstat { pid } \
{
	global remote
	set cmd "debugger -N procstat $remote -T -i $pid" ;
	debug "EXEC: $cmd" ;
	set data [eval "exec $cmd"] ;
	return $data ;
}

proc	unix_tdump { exid tid } \
{
	global remote
	set cmd "debugger -N tdump $remote -T $exid $tid" ;
	debug "EXEC: $cmd" ;
	set data [eval "exec $cmd"] ;
	return $data ;
}

proc	unix_tlist { oid } \
{
	global remote
	set cmd "debugger -N tlist $remote -T $oid" ;
	debug "EXEC: $cmd" ;
	set data [eval "exec $cmd"] ;
	return $data ;
}

proc	unix_gstep { oid } \
{
	global remote
	set cmd "debugger -N gstep $remote -T $oid"
	debug "OPEN|: $cmd"
	set dm [open |$cmd "r+"]
	return $dm
}

proc	unix_dmopen { oid } \
{
	global remote
	set cmd "debugger -N objinspect $remote -T $oid"
	debug "OPEN|: $cmd"
	set dm [open |$cmd "r+"]
	return $dm
}

proc	unix_dmclose { dm } \
{
	global remote
	request $dm "quit"
	catch { close $dm }
}

