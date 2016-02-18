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
#		スクールディレクトリブラウザ
#
# ファイル名
#	sdb.tcl
#
# 機能
#	スクールディレクトリをブラウザし、スクールを選択する。
#	dfe.tcl が取り込むことを前提とする。
#
# 参照
#	class	DebuggerFrontendLaunchable, GUI
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

#
# グローバル変数
#
global School ;
set School "" ;		# DFE とのＩ／Ｆ

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

#	Create window
proc	SDB.Main { w } \
{
#puts stderr "SDB.Main w=$w" ;
	global School ;

	# スクール選択ウィンドウ作成
	SDB.window $w ;
	$w.footer.dismiss configure -state disabled ;

	set School "" ;
}

#	Update list of current work directory
proc	SDB.Update args \
{
#puts stderr "SDB.Update args=$args" ;
	set w [lindex $args 0] ;
	set cwd [lindex $args 1] ;
	$w.cwd.path delete 0 end ;
	$w.cwd.path insert end $cwd ;
	if { [llength $args] > 2 } {
		$w.dirs.listbox delete 0 end ;
		if { $cwd != ":" } {
			$w.dirs.listbox insert end : ;
		}
		foreach e [lrange $args 2 end] {
			$w.dirs.listbox insert end $e ;
		}
	}
	$w.footer.dismiss configure -state normal ;
	update ;
}

#
#-------------------------------------------------------------------------------

#
#	メインウィンドウの作成
#
# w		ウィンドウ
#
proc	SDB.window { w } \
{
	global OZROOT ;

	#
	# ウィンドウ作成
	#
	catch { destroy $w ; }
	toplevel $w ;

	set title "School Directory" ;
	set iname "School Directory" ;
	wm title $w $title ;
	wm iconname $w $iname ;
	set pg [winfo geometry [winfo parent $w]] ;
	wm geometry $w [string trimleft $pg 0123456789x] ;

	# 物理スクールディレクトリのＯＩＤとスクールディレクトリの現在のパス
	frame $w.cwd ;
	entry $w.cwd.path -relief sunken ;
	pack $w.cwd -side top -fill x ;
	pack $w.cwd.path -side top -fill x -expand yes ;
	
	# スクールディレクトリの内容
	frame $w.dirs -bd 1 -relief raised ;
	pack $w.dirs -side top -fill both -expand yes ;
	listbox $w.dirs.listbox -bd 1 -relief sunken \
		-yscroll "$w.dirs.scrollbar set" ;
	scrollbar $w.dirs.scrollbar -bd 1 -relief sunken \
		-command "$w.dirs.listbox yview" ;
	pack $w.dirs.listbox -side left -fill both -expand yes ;
	pack $w.dirs.scrollbar -side right -fill y ;
	tk_listboxSingleSelect $w.dirs.listbox ;

	#
	# フッターの作成
	#
	frame $w.footer ;
	pack $w.footer -side bottom -fill x ;
	button $w.footer.dismiss -text Dismiss -command "destroy $w" ;
	pack $w.footer.dismiss -side top ;

	# ウィンドウの調整
	set_expandable $w ;

	# イベント動作の定義
	bind $w.cwd.path <Return> "SDB.chdir $w %W" ;
	bind $w.dirs.listbox <Double-1> \
		"SDB.select $w %W" ;

}

proc	SDB.chdir { w field } \
{
	set path [$field get] ;
	if { $path != "" } {
		SendOZ "SDB.Chdir:$w|$path" ;
	}
}

proc	SDB.select { w field } \
{
	global School ;

	set index [lindex [$field curselection] 0] ;
	if { $index != "" } {
		set name [$field get $index] ;
		if { $name == ":" } {
			# change to parent
			SendOZ "SDB.Chdir:$w" ;
		} elseif { [string first : $name] < 0 } {
			# selected school
			set path [string trimright [$w.cwd.path get] :]:$name ;
			set School $path ;
			destroy $w ;
		} else {
			# change to child
			SendOZ "SDB.Chdir:$w|$name" ;
		}
	}
}

# End of file: sdb.tcl
