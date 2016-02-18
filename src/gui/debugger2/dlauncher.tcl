#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# グローバル変数
#
global OZROOT ;
global ClassName ;
global ClassID ;
set ClassName "" ;
set ClassID "" ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "exception.tcl: You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	共通部分の取り込み
#
set path $OZROOT/lib/gui ;
source $path/inspector/inspect.tcl ;

#
#	Launch width debug flags
#
global dflags ;
set w .
	wm title $w "Debugger(Launcher) Version 0.02" ;
	wm iconname $w Debugger ;
#	wm geometry $w +0+0
#	wm minsize $w 442 1
#	wm maxsize $w 442 [winfo screenheight $w] ;
	wm minsize $w 1 1 ;
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w] ;

	frame .ribon -bd 2 ;
	button .ribon.clear -text "Clear" -width 10 \
		-command "clean .stat.value" ;
	button .ribon.list -text "List" -width 10 -command \
		{ classList .stat.value .ribon.list .list .name.value }
	button .ribon.kill -text "Kill" -width 10 -state disabled -command \
		{ kill .stat.value .ribon.invoke .id }
	button .ribon.invoke -text "Initialize" -width 10 -command \
		{ invoke .stat.value .ribon.invoke .id }
	button .ribon.inspect -text "Inspect" -width 10 -state disabled -command \
		{ inspect .stat.value .id }
	button .ribon.close -text "Close" -width 10 -command "destroy $w" ;
	pack .ribon.clear .ribon.kill -side left ;
	#.ribon.list
	pack .ribon.invoke .ribon.inspect -side left ;
	pack .ribon.close -side right ;
	
	frame .dflags -bd 5 ;
	label .dflags.title -text "Debug Flags" ;
	pack .dflags.title -side left ;
	frame .dflags.body ;
	checkbutton .dflags.body.public -text Public -anchor nw \
		-onvalue "1" -offvalue "0" -width 10 \
		-variable dflags(public) -relief raised ;
	checkbutton .dflags.body.protected -text Protected -anchor nw \
		-onvalue "1" -offvalue "0" -width 10 \
		-variable dflags(protected) -relief raised ;
	checkbutton .dflags.body.private -text Private -anchor nw \
		-onvalue "1" -offvalue "0" -width 10 \
		-variable dflags(private) -relief raised ;
	checkbutton .dflags.body.record -text Record -anchor nw \
		-onvalue "1" -offvalue "0" -width 10 \
		-variable dflags(record) -relief raised ;
	pack .dflags.title -side top ;
	pack .dflags.body.public .dflags.body.protected \
		.dflags.body.private .dflags.body.record -side left ;
	pack .dflags.body -side left ;

	frame .name -bd 5 ;
	label .name.label -text "Class Name" ;
	entry .name.value -relief sunken ;
	pack .name.label -side left ;
	pack .name.value -side right -fill x -expand yes ;

	frame .id -bd 5 ;
	label .id.label -text "Public ID" ;
	label .id.value ;
	pack .id.label -side left ;
	pack .id.value -side right -fill x -expand yes ;

	frame .list -bd 5 ;

	frame .stat -relief raised -bd 1 ;
	label .stat.value -anchor nw -relief sunken -bd 1 ;
	pack .stat.value -side left -fill x -expand yes ;

	pack .ribon -side top -fill x ;
	pack .name -side top -fill x ;
	pack .id -side top -fill x ;
	pack .dflags -side top -fill x ;
	pack .list -side top -fill both -expand yes ;
	pack .stat -side left -fill x -expand yes ;

	bind .name.value <Return> \
	{
		if { [string length [.name.value get]] != 0 } {
			invoke .stat.value .ribon.invoke .name ;
		}
	}
#	bind .name.value <Double-Button-1> \
#		{ classList .stat.value .ribon.list .list %W }

if { 2 <= $argc  } {
	.name.value delete 0 end ;
	.name.value insert end [lindex $argv 0] ;
	.id.value configure -text [lindex $argv 1] ;
	set ClassName [lindex $argv 0] ;
	set ClassID [lindex $argv 1] ;
}

proc	no_op {} \
{
# Nothing
}

proc	goProc { stat msg } \
{
#puts stderr $msg ;
	$stat configure -text "$msg ..." ;
	update ;
}

proc	doneProc { stat } \
{
	set msg [lindex [$stat configure -text] 4] ;
	$stat configure -text "$msg Done." ;
	update ;
}

proc	errProc { stat } \
{
	set msg [lindex [$stat configure -text] 4] ;
	$stat configure -text "$msg Error." ;
	update ;
}

proc	killProc { stat } \
{
	set msg [lindex [$stat configure -text] 4] ;
	$stat configure -text "$msg Kill." ;
	update ;
}

proc	msgProc { stat msg } \
{
	$stat configure -text "$msg." ;
	update ;
}

proc	classIdentify { stat className } \
{
	if { $className  == "" } {
		tk_dialog .error "Class Name Input" \
			"You must be enter Class Name" \
			error "OK" "OK" ;
		return ;
	}

	set len [string length $className] ;
	if { $len == 16 } {
		set test [string trim $className 0123456789abcdef] ;
		if { [string length $test] == 0 } {
			doneProc $stat ;
			return $className ;
		}
	}
	goProc $stat "Search $className" ;
	if { [catch { exec sb $className 0 } id] != 0 } {
		tk_dialog .error "Class Name Search" \
			"$className is not found" \
			error "OK" "OK" ;
		errProc $stat ;
		return ;
	}
	doneProc $stat ;

	return $id ;
}

proc	classList_Refresh { stat flag list } \
{

	global env ;
	set school $env(OZROOT)/etc/boot-school ;
	set cpath $env(OZROOT)/lib/boot-class ;

	goProc $stat "Search Launchable" ;
	set cmd "sb Launchable 1" ;
	if { [catch { exec sh -c $cmd } id] != 0 } {
		tk_dialog .error "Launchable Class ID" \
			"Can't get 'Launchable' class id." \
			error "OK" "OK" ;
		errProc $stat ;
		return ;
	}
	doneProc $stat ;

	goProc $stat "Search School" ;
	set cmd "grep '^0 \[^<\]*\$' $school|cut -f2 -d' '| tail -r"
	if { [catch { exec sh -c $cmd } names] != 0 } {
		tk_dialog .error "Search Launchable Class ID" \
			"Can't search school file." \
			error "OK" "OK" ;
		errProc $stat ;
		return ;
	}
	doneProc $stat ;

	$stat configure -width 30 ;
	$list.list delete 0 end ;
	foreach name $names {
		goProc $stat "Search $name" ;
		set cmdl0 "p=`sb $name 0`;" ;
		set cmdl1 "fgrep $id $cpath/\$p/public.h>/dev/null;" ;
		set cmdl2 "if \[ \$? -eq 0 \]; then echo $name ; fi; exit 0 " ;
		set cmd $cmdl0$cmdl1$cmdl2 ;
		if { [catch { exec sh -c $cmd } name] != 0 } {
			tk_dialog .error "Launchable Class ID" \
				"Can't search directory for class: $name" \
				error "OK" "OK" ;
			errProc $stat ;
			continnue ;
		}
		if { $name != "" } {
			$list.list insert end $name ;
		}
		doneProc $stat ;
		set now [lindex [$flag configure -text] 4] ;
		if { [string compare $now "Stop"] != 0 } {
			msgProc $stat Stop ;
			return ;
		}
	}
	msgProc $stat Done ;
	$stat configure -width 0 ;
}

proc	classList { stat flag w field } \
{
	set now [lindex [$flag configure -text] 4] ;
	if { [string compare $now "List"] == 0 } {
		$flag configure -text "Rescan" ;
		listbox $w.list -yscroll "$w.bar set" -relief sunken ;
		scrollbar $w.bar -command "$w.list yview" -relief sunken ;
		pack $w.list -side left -fill both -expand yes ;
		pack $w.bar -side right -fill y ;
		bind $w.list <B1-Motion> no_op ;
		bind $w.list <Double-Button-1> \
			"classList_Select $stat $w.list $field" ;
		.ribon.invoke configure -state disabled ;
		.ribon.clear configure -state disabled ;
		$flag configure -text "Stop" ;
		classList_Refresh $stat $flag $w ;
		$flag configure -text "Rescan" ;
		.ribon.invoke configure -state normal ;
		.ribon.clear configure -state normal ;
	}
	if { [string compare $now "Stop"] == 0 } {
		$flag configure -text "Rescan" ;
	}
	if { [string compare $now "Rescan"] == 0 } {
		.ribon.invoke configure -state disabled ;
		.ribon.clear configure -state disabled ;
		$flag configure -text "Stop" ;
		classList_Refresh $stat $flag $w ;
		$flag configure -text "Rescan" ;
		.ribon.invoke configure -state normal ;
		.ribon.clear configure -state normal ;
	}
}

proc	classList_Select { stat list field } \
{
	set now [lindex [$field configure -state] 3] ;
	if { [string compare $now "normal"] == 0 } {
		set i [lindex [$list curselection] 0]
		if { $i != "" } {
			$field delete 0 end
			$field insert 0 [$list get $i] ;
		}
	}
	$list select clear ;
}

proc	setup { stat } \
{
	global ClassName ClassID ;
	set name [.name.value get] ;
	set id [lindex [.id.value configure -text] 4] ;
	if { [string compare $name $ClassName] != 0 || $id == "" } {
		set id [classIdentify $stat $name] ;
		if { $id == "" } { return ; }
		set ClassName $name ;
		set ClassID $id ;
	}
	.ribon.invoke configure -text "Initialize" ;
	.name.value configure -state disabled ;
	.id.value configure -text  $id ;
	return $id ;
}

proc	clean { stat } \
{
	global ClassName ClassID ;
	if { [string length [.name.value get]] != 0 } {
		.ribon.invoke configure -state normal ;
	} else {
		.ribon.invoke configure -state disabled ;
	}
	.ribon.invoke configure -text "Initialize" ;
	.name.value configure -state normal ;
	.ribon.list configure -state normal ;
	.ribon.kill configure -state disabled ;
	.ribon.inspect configure -state disabled ;
	.name.value delete 0 end ;
	.name.value insert end $ClassName ;
	.id.value configure -text $ClassID ;
}

proc	kill { stat key field } \
{
	goProc $stat "Kill" ;
	set id [lindex [$field.value configure -text] 4] ;
	set now [lindex [$key configure -text] 4] ;
	set cmd "0" ;
	if { [string compare $now "Initialize"] == 0 } {
		set cmd "1" ;
	}
	if { [string compare $now "Launch"] == 0 } {
		set cmd "2" ;
	}
	puts stdout "$id 0$cmd";
	flush stdout ;
}

proc	invoke { stat key field } \
{
	global dflags ;
	set now [lindex [$key configure -text] 4] ;
	if { [string compare $now "Initialize"] == 0 } {
		set id [setup .stat.value] ;
		if { $id == "" } { return ; }
		goProc $stat "Invoking Initialize" ;
set p "$dflags(public)$dflags(protected)$dflags(private)$dflags(record)" ;
		puts stdout "$id 1$p";
		flush stdout ;
		.ribon.inspect configure -state normal ;
	}
	if { [string compare $now "Launch"] == 0 } {
		set id [lindex [$field.value configure -text] 4] ;
		if { $id == "" } { return ; }
		goProc $stat "Invoking Launch" ;
set p "$dflags(public)$dflags(protected)$dflags(private)$dflags(record)" ;
		puts stdout "$id 2$p";
		flush stdout ;
	}
	$key configure -state disabled ;
	.ribon.kill configure -state normal ;
	.ribon.list configure -state disabled ;
}

proc	inspect { stat field } \
{
	goProc $stat "Inspect" ;
	set id [lindex [$field.value configure -text] 4] ;
	puts stdout "$id 30000";
	flush stdout ;
	.ribon.inspect configure -state disabled ;
}

proc	MainLoop { } \
{
	set stat .stat.value ;
	set data [gets stdin] ;
	set id [lindex $data 0] ;
	if { [string compare $id [lindex [.id.value configure -text] 4]] != 0 } {
		return ;
	}
	set cmd [string range [lindex $data 1] 0 0] ;
	set status [string range [lindex $data 1] 1 1] ;
# Initialize() response
	if {  $cmd == 1 } {
		if { $status == 0 } {
			doneProc $stat ;
			.ribon.invoke configure -state normal ;
			.ribon.invoke configure -text "Launch" ;
			.ribon.kill configure -state disabled ;
		} elseif { $status == 1 } {
			killProc $stat ;
			.ribon.invoke configure -state normal ;
			.ribon.invoke configure -text "Initialize" ;
			.ribon.kill configure -state disabled ;
		} else {
			errProc $stat ;
			clean $stat ;
		}
	}
# Launch() response
	if { $cmd == 2 } {
		if { $status == 0 } {
			doneProc $stat ;
			.ribon.invoke configure -state normal ;
			.ribon.invoke configure -text "Launch" ;
			.ribon.kill configure -state disabled ;
		} elseif { $status == 1 } {
			killProc $stat ;
			.ribon.invoke configure -state normal ;
			.ribon.invoke configure -text "Launch" ;
			.ribon.kill configure -state disabled ;
		} else {
			errProc $stat ;
			clean $stat ;
		}
	}
# Inspect response
	if { $cmd == 3 } {
		if { $status == 0 } {
			doneProc $stat ;
			.ribon.inspect configure -state normal ;
			set oid [lindex $data 2] ;
			set obj [lindex $data 3] ;
			set type O0000000000000000 ;
			Object.Inspect .obj $oid [.name.value get] $type $obj local ;
		} else {
			errProc $stat ;
			clean $stat ;
		}
	}
	if { $cmd == 0 } {
		if { $status == 1 } {
			doneProc $stat ;
			.ribon.invoke configure -state normal ;
			.ribon.invoke configure -text "Initialize" ;
			.ribon.kill configure -state disabled ;
		} elseif { $status == 2 } {
			doneProc $stat ;
			.ribon.invoke configure -state normal ;
			.ribon.invoke configure -text "Launch" ;
			.ribon.kill configure -state disabled ;
		} else {
			errProc $stat ;
			clean $stat ;
		}
	}
}

focus .name.value

addinput stdin "MainLoop" ;
