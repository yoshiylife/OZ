#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：デバッグ用ラウンチャブル
#
# ファイル名
#	DebugLaunchable.tcl
#
# モジュール名
#	DL
#
# プロシージャ
#	Window, Enable, Disable, ( GUI: Destroy, Print, Exit )
#
# イベント
#	Ready, Initialize, Launch, Kill, Inspect, Quit
#
# 機能
#
# 参照
#	class	DebugLaunchable, PackageSelector, GUI
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

#
# グローバル変数
#
global OZROOT ;
global DL ;

#
# 初期値設定
#
set DL(file) DebugLaunchable.tcl ;
set DL(op) "initialize launch kill inspect quit" ;
set DL(caption,initialize) Initialize ;
set DL(caption,launch) Launch ;
set DL(caption,kill) Kill ;
set DL(caption,inspect) Inspect ;
set DL(caption,quit) Quit ;
set DL(dflags,fork) 0 ;
set DL(dflags,constructor) 0 ;
set DL(dflags,public) 0 ;
set DL(dflags,protected) 0 ;
set DL(dflags,private) 0 ;
set DL(dflags,record) 0 ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$DL(file): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

#	Create window
proc	DL.Window { win title iname {cname ""} } \
{
	global DL ;

	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;

	entry $w.package -text $cname -relief sunken ;
	pack $w.package -side top -fill x -expand yes ;
	bind $w.package <Double-1> "EventOZ DL.Test $win" ;

	frame $w.op ;
	pack $w.op -side top -fill x -expand yes ;
	set items "" ;
	foreach e $DL(op) {
		button $w.op.$e -width 8 -state disabled \
			-text $DL(caption,$e) -command "DL.$e $win" ;
		append items "$w.op.$e " ;
	}
	eval "pack $items -side left -fill x -expand yes " ;

	frame $w.dflags ;
	foreach t "Fork Constructor Public Protected Private Record" {
		set p [string tolower $t] ;
		checkbutton $w.dflags.$p -anchor nw -relief flat \
			-offvalue 0 -onvalue 1 -variable DL(dflags,$p) \
			-text $t -command "DL.flag $win $t" ;
		pack $w.dflags.$p -side left -expand yes ;
	}
	pack $w.dflags -fill both -side top -expand yes ;

	Footer $w ;

	update ;

	# ウィンドウの調整
	wm minsize $win [winfo width $win] [winfo height $win] ;
	wm maxsize $win [winfo width $win] [winfo height $win] ;

	DL.Enable . ;
	EventOZ DL.Ready "$win" ;
}

#
proc	DL.Enable args \
{
	global DL ;

	set win [lindex $args 0] ;
	set w [string trimright $win '.'] ;
	if { [llength $args] == 1 } {
		foreach e $DL(op) {
			$w.op.$e configure -state normal ;
		}
	} else {
		foreach e [lrange $args 1 end] {
			$w.op.[string tolower $e] configure -state normal ;
		}
	}
}

#
proc	DL.Disable args \
{
	global DL ;

	set win [lindex $args 0] ;
	set w [string trimright $win '.'] ;
	if { [llength $args] == 1 } {
		foreach e $DL(op) {
			$w.op.$e configure -state disabled ;
		}
	} else {
		foreach e [lrange $args 1 end] {
			$w.op.[string tolower $e] configure -state disabled ;
		}
	}
}

#
proc	DL.Update { win package } \
{
	set w [string trimright $win '.'] ;
	$w.package delete 0 end ;
	$w.package insert 0 $package ;
}

#
#-------------------------------------------------------------------------------

#
proc	DL.flag { win part } \
{
	global DL ;

	set f [string tolower $part] ;
	EventOZ DL.Flag "$win|$part|$DL(dflags,$f)" ;
}

#
proc	DL.initialize { win } \
{
	set w [string trimright $win '.'] ;
	set name [$w.package get] ;
	if { $name != "" } {
		DL.Disable $win ;
		Print $win false "Initialize..." ;
		EventOZ DL.Initialize "$win|$name" ;
	}
}

#
proc	DL.launch { win } \
{
	DL.Disable $win ;
	Print $win false "Launch..." ;
	EventOZ DL.Launch "$win" ;
}

#
proc	DL.kill { win } \
{
	DL.Disable $win ;
	Print $win false "Kill..." ;
	EventOZ DL.Kill "$win" ;
}

#
proc	DL.inspect { win } \
{
	DL.Disable $win ;
	Print $win false "Inspect..." ;
	EventOZ DL.Inspect "$win" ;
}

#
proc	DL.quit { win } \
{
	DL.Disable $win ;
	Print $win false "Quit..." ;
	EventOZ DL.Quit "$win" ;
}

#
# Test
#
if { $argc > 0 } {
	source ../Lib/GUI.tcl ;
	foreach n $argv {
		switch $n {
		DL.Window {
				DL.Window . "OZ++ Debug Launchable" "DL" ;
				.op.quit configure -command "exit 0" ;
				Print . false "Update..." ;
				Print . true "Done." ;
				DL.Enable .
			}
		}
	}
}

# End of file: DebugLaunchable.tcl
