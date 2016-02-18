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
#	olist.tcl
#
# 機能
#	グローバルオブジェクトの一覧を表示する。
#
# 参照
#	class	TestListObject, GUI
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

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "olist.tcl: You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	共通部分の取り込み
#
set path $OZROOT/lib/gui ;
set auto_index(set_expandable) "source $path/wb2/if-to-oz.tcl" ;

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

proc	OLS.Start { w exid } \
{
	global ExecutorID ;

	# エグゼキュータＩＤの受信
	set ExecutorID $exid ;

	# メインウィンドウ作成
	set exid "[string range $ExecutorID 4 9]"
	set title "OZ++ Debugger Object List: Executor($exid)" ;
	set iname "List($exid)" ;
	OLS.Window $w $title $iname ;

	OLS.disabled $w ;
	update ;
	SendOZ "OLS.Update:$w" ;
}

proc	OLS.Update { w } \
{
	OLS.disbled $w ;
	update ;
	SendOZ "OLS.Update:$w" ;
}

proc	OLS.Append { w oid status } \
{
	$w.list.oid insert end $oid ;
	$w.list.status insert end $status ;
	update ;
}

proc	OLS.Normal { w } \
{
	$w.mb.file configure -state normal ;
	$w.mb.update configure -state normal ;
	update ;
}

proc	OLS.Clear { w } \
{
	$w.list.oid delete 0 end ;
	$w.list.status delete 0 end ;
	update ;
}

# Destory window
proc	OLS.Destroy { w } \
{
	destroy $w ;
}

# Tcl/Tk exit
proc	Exit { status } \
{
	exit $status ;
}

# Print status message
proc	OLS.Print { w msg {mode false} } \
{
	if { $mode } {
		set pre [lindex [$w.footer.msg configure -text] 4] ;
		$w.footer.msg configure -text $pre$msg ;
	} else {
		$w.footer.msg configure -text $msg ;
	}
	update ;
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
proc	OLS.Window { w title iname } \
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

	# Object List
	set menu $w.mb.file.m ;
	menubutton $w.mb.file -text File -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.file -side left ;
	$menu add command -label Suspend -command "OLS.suspend $w" ;
	$menu add command -label Resume -command "OLS.resume $w" ;
	$menu add separator ;
	$menu add command -label Quit -command "OLS.quit $w" ;

	# Update
	button $w.mb.update -text Update -width 10 -relief flat \
		-state disabled -command "OLS.update $w" ;
	pack $w.mb.update -side right ;

	#
	# リスト表示
	#
	frame $w.list -bd 1 -relief raised ;
	pack $w.list -side top -fill both -expand yes ;
	listbox $w.list.oid -bd 1 -relief sunken \
		-yscroll "$w.list.scrollbar set" ;
	listbox $w.list.status -bd 1 -relief sunken ;
	scrollbar $w.list.scrollbar -bd 1 -relief sunken \
		-command "OLS.scroll {$w.list.oid $w.list.status}" ;
	pack $w.list.oid -side left -fill both -expand yes ;
	pack $w.list.status -side left -fill both ;
	pack $w.list.scrollbar -side right -fill y ;
	tk_listboxSingleSelect $w.list.oid ;
	proc	nop { } { }
	bind $w.list.status <1> nop ;
	bind $w.list.status <2> nop ;
	bind $w.list.status <3> nop ;
	bind $w.list.status <B1-Motion> nop ;
	bind $w.list.status <B2-Motion> nop ;
	bind $w.list.status <B3-Motion> nop ;
	bind $w.list.status <Double-1> nop ;
	bind $w.list.status <Double-2> nop ;
	bind $w.list.status <Double-3> nop ;

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

proc	OLS.quit { w } \
{
	destroy $w ;
	SendOZ "OLS.Quit:$w" ;
}

proc	OLS.scroll { wins pos } \
{
	foreach w $wins {
		$w yview $pos ;
	}
}

proc	OLS.update { w } \
{
	OLS.disabled $w ;
	SendOZ "OLS.Update:$w" ;
}

proc	OLS.suspend { w } \
{
	set i [lindex [$w.list.oid curselection] 0] ;
	if { $i == "" } { return ; }
	set oid [$w.list.oid get $i] ;
	OLS.Print $w "Suspend $oid..." ;
	SendOZ "OLS.Suspend:$w|$oid" ;
}

proc	OLS.resume { w } \
{
	set i [lindex [$w.list.oid curselection] 0] ;
	if { $i == "" } { return ; }
	set oid [$w.list.oid get $i] ;
	OLS.Print $w "Resume $oid..." ;
	SendOZ "OLS.Resume:$w|$oid" ;
}

proc	OLS.disabled { w } \
{
	$w.mb.file configure -state disabled ;
	$w.mb.update configure -state disabled ;
	update ;
}


wm withdraw . ;

# End of file: dfe.tcl
