#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガフロントエンド：ユーザＩ／Ｆ
#
# ファイル名
#	dfe.tcl
#
# 機能
#	ユーザからの指示をOZ++側のデバッガフロントエンドに伝える。
#	あるいは、OZ++側のデバッガフロントエンドからの命令を実行する。
#
# 参照
#	class	DebuggerFrontend, GUI
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

#
# グローバル変数
#
global ExecutorID ;
global OZROOT ;
global School ;			# SDBとのＩ／Ｆ

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "dfe.tcl: You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	共通部分の取り込み
#
set path $OZROOT/lib/gui ;
set auto_index(my_file_selector) "source $path/wb2/filesel.tcl" ;
set auto_index(set_center) "source $path/wb2/if-to-oz.tcl" ;
set auto_index(set_expandable) "source $path/wb2/if-to-oz.tcl" ;
source $path/debugger2/sdb.tcl ;
source $path/debugger/inspect0.tcl ;

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

proc	DFE.Main { w exid } \
{
	global ExecutorID ;
#puts stderr "DFE.Main w=$w, exid=$exid" ;

	# エグゼキュータＩＤの受信
	set ExecutorID $exid ;

	# メインウィンドウ作成
	set exid "[string range $ExecutorID 4 9]"
	set title "OZ++ Debugger: Executor($exid)" ;
	set iname "Debugger($exid)" ;
	DFE.Window $w $title $iname ;

	update ;
}

# Destory window
proc	DFE.Destroy { w } \
{
	destroy $w ;
}

# Tcl/Tk exit
proc	Exit { status } \
{
	exit $status ;
}

# Print status message
proc	DFE.Print { w msg {mode false} } \
{
	if { $mode } {
		set pre [lindex [$w.footer.msg configure -text] 4] ;
		$w.footer.msg configure -text $pre$msg ;
	} else {
		$w.footer.msg configure -text $msg ;
	}
	update ;
}

proc	DFE.New { w } \
{
	DFE.Print $w "" ;
	$w.class.name delete 0 end ;
	$w.school.path configure -text "" ;
	$w.mb.debugger configure -state normal ;
	$w.mb.update configure -state disabled ;
	DFE.Print $w "" ;
	update ;
}

proc	DFE.Update args \
{
	set w [lindex $args 0] ;
	set path [lindex $args 1] ;
	$w.school.path configure -text $path ;
	$w.class.name delete 0 end ;
	if { 2 < [llength $args] } {
		set names [lrange $args 2 end] ;
		foreach e [lsort $names] {
			$w.class.name insert end $e ;
		}
	}
	$w.mb.update configure -state normal ;
	$w.mb.debugger configure -state normal ;
	update ;
}

proc	DFE.Launcher { w name pid } \
{
#puts stderr "DFE.Launcher w=$w, name=$name, pid=$pid" ;
	DFE.Print $w "$pid" true ;
	set ret [DFE.check $w $pid] ;
	if { $ret == "" } {
		SendOZ "DFE.Launcher:$w|$name|$pid" ;
	} else {
		DFE.Print $w " not Launchable." true ;
	}
	$w.mb.debugger configure -state normal ;
	$w.mb.update configure -state normal ;
}

#
#-------------------------------------------------------------------------------

#
#	メインウィンドウの作成
#
# w		ウィンドウ
# title	ウィンドウのタイトル
# iname	アイコンのタイトル
#
proc	DFE.Window { w title iname } \
{
	global OZROOT ;

	#
	# ウィンドウ作成
	#
	catch { destroy $w ; }
	toplevel $w ;
	wm title $w $title ;
	wm iconname $w $iname ;

	#
	# メニューバーの作成
	#
	frame $w.mb -bd 1 -relief raise ;
	pack $w.mb -side top -fill x;

	# Debugger
	set menu $w.mb.debugger.m ;
	menubutton $w.mb.debugger -text Debugger -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.debugger -side left ;
	$menu add command -label New -command "DFE.New $w" ;
	$menu add command -label "School..." -command "DFE.sdb $w" ;
	$menu add command -label "Launcher..." -command "DFE.launcher $w" ;
	$menu add command -label "Process..." -command "DFE.process $w" ;
	$menu add command -label "Object..." -command "DFE.object $w" ;
	$menu add command -label "Message..." -command "DFE.message $w" ;
	$menu add command -label "Exception..." -command "DFE.exception $w" ;
	$menu add separator ;
	$menu add command -label Quit -command "DFE.quit $w" ;

	# Update
	button $w.mb.update -text Update -width 10 -relief flat -state disabled ;
	pack $w.mb.update -side right ;

	#
	# 現在のスクールパス
	#
	frame $w.school ;
	pack $w.school -side top -fill x ;
	label $w.school.path -text "" ;
	pack $w.school.path -side top -fill x ;

	#
	# クラスの名前のリスト表示
	#
	frame $w.class -bd 1 -relief raised ;
	pack $w.class -side top -fill both -expand yes ;
	listbox $w.class.name -bd 1 -relief sunken -geometry 50x10 \
		-yscroll "$w.class.scrollbar set" ;
	scrollbar $w.class.scrollbar -bd 1 -relief sunken \
		-command "DFE.scroll {$w.class.name}" ;
	pack $w.class.name -side left -fill both -expand yes ;
	pack $w.class.scrollbar -side right -fill y ;
	tk_listboxSingleSelect $w.class.name ;
	bind $w.class.name <Double-1> "DFE.select $w" ;

	#
	# フッターの作成
	#
	frame $w.footer -bd 1 -relief raised ;
	pack $w.footer -side bottom -fill x ;
	label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
	pack $w.footer.msg -side left -fill x -expand yes ;

	# ウィンドウの調整
	set_expandable $w ;

	update ;
}

#
#	Compiler FrontEnd Daemon
#
proc	DFE.cfed { w file cmd aResult } \
{
	upvar $aResult result ;
	set result "" ;
	set ret 0 ;
	DFE.Print $w "." true ;
	if { [catch { puts $file $cmd ; flush $file ; } ] } {
		DFE.Print $w "Command Error." true ;
		tk_dialog $w.error "Send command to CFED" \
			"Can't command($cmd) to cfed." \
			error "OK" "OK" ;
		puts $file "quit" ; flush $file ; close $file ;
		return -1 ;
	}
	DFE.Print $w "." true ;
	set work "" ;
	while { 1 } {
		if { [catch {gets $file} work] } {
			DFE.Print $w "Return Error." true ;
			tk_dialog $w.error "Recv response from CFED" \
				"Can't return command($cmd) from CFED." \
				error "OK" "OK" ;
			puts $file "quit" ; flush $file ; close $file ;
			return -1 ;
		}
		set ret [split $work :] ;
		if { [lindex $ret 0] == "TCL" && [lindex $ret 1] == "Success" } {
			set ret [lindex $ret 2] ;
			break ;
		}
		append result $work ;
	}
	DFE.Print $w "." true ;
	return $ret ;
}

proc	DFE.check { w pid } \
{
#puts stderr "DFE.check w=$w, pid=$pid" ;
	global ExecutorID OZROOT ;

	# クラス Launchable のクラスＩＤ獲得
	set file "" ;
	set launchable "" ;
	set cmd "$OZROOT/bin/cfed -t" ;
	if { [catch {open |$cmd "r+"} file] } {
		tk_dialog $w.error "Get ID of class: Launchable" \
			"Can't execute cfed." \
			error "OK" "OK" ;
		return "Can't execute cfed" ;
	}
	set ret [DFE.cfed $w $file "list Launchable 1" launchable] ;
	if { $ret } {
		tk_dialog $w.error "Get ID of class: Launchable" \
			"Not found class: Launchable." \
			error "OK" "OK" ;
		puts $file "quit" ; flush $file ; close $file ;
		return "class Launchable not found" ;
	}
	puts $file "quit" ; flush $file ; close $file ;

	# Launchable を継承したクラスか
	set cpath $OZROOT/images/[string range $ExecutorID 4 9]/classes ;
	catch { exec fgrep -s $launchable $cpath/$pid/public.h } ret ;
#puts stderr "DFE.check=$ret" ;

	return $ret ;
}

proc	DFE.sdb { w } \
{
	global School ;

	set path [lindex [$w.school.path configure -text] 4] ;
	if { $path == "" } {
		SDB.Main $w.sdb ;
		SendOZ "SDB.Chdir:$w.sdb|:" ;
	} else {
		SDB.Main $w.sdb ;
		SendOZ "SDB.Chdir:$w.sdb" ;
	}
	grab $w.sdb ;
	tkwait window $w.sdb ;

	if { $School != "" } {
		$w.mb.update configure -command "DFE.update $w $School" ;
		DFE.update $w $School ;
	}
}

proc	DFE.launcher { w } \
{
	DFE.Print $w "Launcher..." ;
	SendOZ "DFE.Launcher:$w" ;
}

proc	DFE.process { w } \
{
	global ExecutorID ;
	processList .process $ExecutorID ;
}

proc	DFE.object { w } \
{
	global ExecutorID ;
	objectList .object $ExecutorID ;
}

proc	DFE.exception { w } \
{
	DFE.Print $w "Exception Capture..." ;
	SendOZ "DFE.Excepton:$w" ;
}

proc	DFE.message { w } \
{
	DFE.Print $w "Message Capture..." ;
	SendOZ "DFE.Message:$w" ;
}

proc	DFE.quit { w } \
{
	destroy $w ;
	SendOZ "DFE.Quit:$w" ;
}

proc	DFE.scroll { wins pos } \
{
	foreach w $wins {
		$w yview $pos ;
	}
}

proc	DFE.update { w path } \
{
	DFE.Print $w "School..." ;
	$w.mb.debugger configure -state disabled ;
	$w.mb.update configure -state disabled ;
	SendOZ "DFE.Update:$w|$path" ;
}

proc	DFE.select { w } \
{
	global OZROOT ExecutorID ;

	DFE.Print $w "Launcher..." ;
	set i [lindex [$w.class.name curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	$w.mb.debugger configure -state disabled ;
	$w.mb.update configure -state disabled ;
	set name [$w.class.name get $i] ;
	SendOZ "DFE.Select:$w|$name" ;
}

wm withdraw . ;

# End of file: dfe.tcl
