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
#	DebuggerFrontend.tcl
#
# モジュール名
#	DFE
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
global OZROOT ;
global DFE ;

# 初期値設定
set DFE(file) "DebuggerFrontend.tcl" ;
set DFE(exid) "" ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$DFE(file): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

proc	DFE.Window { win title iname exid } \
{
puts stderr "DFE.Window $win, $title, $iname, $exid" ;
	global DFE ;

	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	set site [string range $DFE(exid) 0 3] ;
	set base [string range $DFE(exid) 4 9] ;
	wm title $win "$title: $site $base" ;
	wm iconname $win $iname ;

	# エグゼキュータＩＤの受信
	set DFE(exid) $exid ;

	# メインウィンドウ作成

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
	$menu add command -label New -command "DFE.New $win" ;
	$menu add command -label "Catalog..." -command "DFE.cb $win" ;
	$menu add command -label "Launcher..." -command "DFE.launcher $win" ;
	$menu add command -label "Process..." -command "DFE.process $win" ;
	$menu add command -label "Object..." -command "DFE.object $win" ;
	$menu add command -label "Message..." -command "DFE.message $win" ;
	$menu add command -label "Exception..." -command "DFE.exception $win" ;
	$menu add separator ;
	$menu add command -label Quit -command "DFE.quit $win" ;

	# Update
	button $w.mb.update -text Update -width 10 -relief flat -state disabled ;
	pack $w.mb.update -side right ;

	#
	# 現在のスクールパス
	#
	frame $w.catalog ;
	pack $w.catalog -side top -fill x ;
	entry $w.catalog.path -relief sunken -text "" ;
	pack $w.catalog.path -side top -fill x ;
	bind $w.catalog.path <Return> "DFE.cb $w" ;


	#
	# クラスの名前のリスト表示
	#
	frame $w.class -bd 1 -relief raised ;
	pack $w.class -side top -fill both -expand yes ;
	listbox $w.class.list -bd 1 -relief sunken -geometry 50x10 \
		-yscroll "$w.class.bar set" ;
	pack $w.class.list -side left -fill both -expand yes ;

	scrollbar $w.class.bar -bd 1 -relief sunken \
		-command "DFE.scroll $win {class}" ;
	pack $w.class.bar -side right -fill y ;
	tk_listboxSingleSelect $w.class.list ;
	bind $w.class.list <Double-1> "DFE.select $win" ;

	DFE.footer $w ;

	# ウィンドウの調整
	wm minsize $win [winfo width $win] [winfo height $win] ;
	wm maxsize $win [winfo screenwidth $win] [winfo screenheight $win] ;

	update ;
	EventOZ DFE.Ready "$win" ;
}

# Destory window
proc	DFE.Destroy { w } \
{
	destroy $w ;
}

proc	Source { src } \
{
	global OZROOT ;
	source $OZROOT/$src ;
}

# Tcl/Tk exit
proc	Exit { status } \
{
	exit $status ;
}

# Print status message
proc    DFE.Print { win msg {mode false} } \
{
	set w [string trimright $win '.'] ;
	if { $mode } {
		set pre [lindex [$w.footer.msg configure -text] 4] ;
		$w.footer.msg configure -text $pre$msg ;
	} else {
		$w.footer.msg configure -text $msg ;
	}
	update ;
}

proc	DFE.Enable { win } \
{
	set w [string trimright $win '.'] ;
	$w.mb.debugger configure -state normal ;
	$w.mb.update configure -state normal ;
}

proc	DFE.Disable { win } \
{
	set w [string trimright $win '.'] ;
	$w.mb.debugger configure -state disabled ;
	$w.mb.update configure -state disabled ;
}

proc	DFE.New { win } \
{
	set w [string trimright $win '.'] ;
	DFE.Print $win "" ;
	$w.class.list delete 0 end ;
	$w.catalog.path delete 0 end ;
	$w.mb.debugger configure -state normal ;
	$w.mb.update configure -state disabled ;
	DFE.Print $win "" ;
	update ;
}

proc	DFE.Update args \
{
#puts stderr "DFE.Update args=$args" ;
	set win [lindex $args 0] ;
	set w [string trimright $win '.'] ;
	set path [lindex $args 1] ;
	$w.catalog.path delete 0 end ;
	$w.catalog.path insert 0 $path ;
	$w.class.list delete 0 end ;
	if { 2 < [llength $args] } {
		set names [lrange $args 2 end] ;
		foreach e [lsort $names] {
			$w.class.list insert end $e ;
		}
	}
	DFE.Enable $win ;
	$w.mb.update configure -command "EventOZ DFE.Update $win|$path" ;
	update ;
}

proc	DFE.Launcher { win name ccid } \
{
#puts stderr "DFE.Launcher w=$w, name=$name, ccid=$ccid" ;
	set w [string trimright $win '.'] ;
	DFE.Print $win "$ccid" true ;
	set ret [DFE.check $win $ccid] ;
	if { $ret == "" } {
		EventOZ DFE.Launcher "$win|$name|$ccid" ;
	} else {
		DFE.Print $win " not Launchable." true ;
	}
	DFE.Enable $win ;
}

#
#-------------------------------------------------------------------------------

#
#   フッターの作成
#
proc    DFE.footer { w } \
{
	frame $w.footer -bd 1 -relief raised ;
	pack $w.footer -side bottom -fill x ;
	label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
	pack $w.footer.msg -side left -fill x -expand yes ;
}

#
#	Compiler FrontEnd Daemon
#
proc	DFE.cfed { win file cmd aResult } \
{
	set w [string trimright $win '.'] ;
	upvar $aResult result ;
	set result "" ;
	set ret 0 ;
	DFE.Print $win "." true ;
	if { [catch { puts $file $cmd ; flush $file ; } ] } {
		DFE.Print $win "Command Error." true ;
		tk_dialog $w.error "Send command to CFED" \
			"Can't command($cmd) to cfed." \
			error "OK" "OK" ;
		puts $file "quit" ; flush $file ; close $file ;
		return -1 ;
	}
	DFE.Print $win "." true ;
	set work "" ;
	while { 1 } {
		if { [catch {gets $file} work] } {
			DFE.Print $win "Return Error." true ;
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
	DFE.Print $win "." true ;
	return $ret ;
}

proc	DFE.check { win pid } \
{
#puts stderr "DFE.check w=$w, pid=$pid" ;
	global DFE OZROOT ;

	set w [string trimright $win '.'] ;

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
	set cpath $OZROOT/images/[string range $DFE(exid) 4 9]/classes ;
	catch { exec fgrep -s $launchable $cpath/$pid/public.h } ret ;
#puts stderr "DFE.check=$ret" ;

	return $ret ;
}

proc	DFE.cb { win } \
{
	set w [string trimright $win '.'] ;
	set path [$w.catalog.path get] ;
	CB.Window $w.cb "Catalog Browser" "CB" ;
	update ;
}

proc	DFE.launcher { win } \
{
	DFE.Print $win "Launcher..." ;
	EventOZ DFE.Launcher "$win" ;
}

proc	DFE.process { win } \
{
	global DFE ;

    set w [string trimright $win '.'] ;
	processList .process $DFE(exid) ;
}

proc	DFE.object { win } \
{
	global DFE ;

    set w [string trimright $win '.'] ;
	objectList .object $DFE(exid) ;
}

proc	DFE.exception { win } \
{
	DFE.Print $win "Exception Capture..." ;
	EventOZ DFE.Excepton "$win" ;
}

proc	DFE.message { win } \
{
	DFE.Print $win "Message Capture..." ;
	EventOZ DFE.Message "$win" ;
}

proc	DFE.quit { win } \
{
	DFE.Disable $win ;
	EventOZ DFE.Quit "$win" ;
}

proc	DFE.scroll { win fields pos } \
{
    set w [string trimright $win '.'] ;
	foreach f $fields {
		$w.$f.list yview $pos ;
	}
}

proc	DFE.update { win path } \
{
	DFE.Print $win "Catalog..." ;
	DFE.Disable $win ;
	EventOZ DFE.Update "$win|$path" ;
}

proc	DFE.select { win } \
{
	global DFE ;

    set w [string trimright $win '.'] ;
	DFE.Print $win "Launcher..." ;
	set i [lindex [$w.class.list curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	DFE.Disable $win ;
	set name [$w.class.list get $i] ;
	EventOZ DFE.Select "$win|$name" ;
}

#
# Test
#
if { $argc > 0 } {
	foreach n $argv {
		switch $n {
		DFE.Window {
				source ../Lib/GUI.tcl ;
				DFE.Window . "OZ++ Debugger Frontend" "DFE" 0001123456000000 ;
				DFE.Update . a b c ;
			}
		}
	}
}

# End of file: DebuggerFrontend.tcl
