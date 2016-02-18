#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：ディレクトリサーバからのエントリ選択
#
# ファイル名
#	EntrySelector.tcl
#
# モジュール名
#	ETS
#
# プロシージャ
#	Window, Update, Enable, Disable, ( GUI: Destroy, Print, Exit )
#
# イベント
#	Ready, Chdir, Lookup, Update, Commit, Dismiss
#
# 機能
#	ディレクトリサーバをブラウズし、１つのエントリーを選択する。
#
# 参照
#	Tcl/Tk	GUI.tcl
#	class	EntrySelector
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#
#
# グローバル変数
#
global ETS ;

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

#	Create window
proc	ETS.Window { win title iname } \
{
#puts stderr "ETS.Window win=$win" ;

	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;
	set p [winfo parent $win] ;
	if { $p != "" } {
		set pg [winfo geometry $p] ;
		wm geometry $win [string trimleft $pg 0123456789x] ;
	}

	# 現在のディレクトリ名
	entry $w.path -bd 1 -relief sunken -state disabled ;
	pack $w.path -side top -fill x ;
	bind $w.path <Return> "ETS.chdir $win %W" ;
	
	#
	#	現在のディレクトリの内容表示
	#
	frame $w.main ;
	pack $w.main -side top -fill both -expand yes ;

	# ディレクトリとエントリの一覧
	frame $w.main.namedir -bd 1 -relief raised ;
	pack $w.main.namedir -side left -fill both -expand yes ;
	listbox $w.main.namedir.list -bd 1 -relief sunken \
		-yscroll "$w.main.namedir.sbar set" ;
	scrollbar $w.main.namedir.sbar -bd 1 -relief sunken \
		-command "$w.main.namedir.list yview" ;
	pack $w.main.namedir.list -side left -fill both -expand yes ;
	pack $w.main.namedir.sbar -side right -fill y ;
	tk_listboxSingleSelect $w.main.namedir.list ;

	frame $w.op ;
	pack $w.op -side top -fill x ;
	button $w.op.commit -text Commit -state disabled -padx 10 \
		-command "ETS.select $win $w.main.namedir.list true" ;
	button $w.op.update -text Update -state disabled -padx 10 \
		-command "ETS.update $win" ;
	button $w.op.dismiss -text Dismiss -state disabled -padx 10 \
		-command "ETS.dismiss $win" ;
	pack $w.op.commit $w.op.update $w.op.dismiss \
		-side left -fill x -expand yes ;

	Footer $w ;

	update ;

	# ウィンドウの調整
	wm minsize $win [winfo width $win] [winfo height $win] ;
	wm maxsize $win [winfo screenwidth $win] [winfo screenheight $win] ;

	EventOZ ETS.Ready "$win" ;
}

#	Update list of current work directory
proc	ETS.Update args \
{
#puts stderr "ETS.Update args=$args" ;
	set w [string trimright [lindex $args 0] '.'] ;
	set path [lindex $args 1] ;

	set state [lindex [$w.path configure -state] 4] ;
	if { $state == "disabled" } {
		$w.path configure -state normal ;
	}
	$w.path delete 0 end ;
	$w.path insert end $path ;
	if { $state == "disabled" } {
		$w.path configure -state $state ;
	}
	
	$w.main.namedir.list delete 0 end ;
	if { $path != ":" } {
		$w.main.namedir.list insert end : ;
	}
	foreach e [lsort [lrange $args 2 end]] {
		$w.main.namedir.list insert end $e ;
	}
	update ;
}

proc	ETS.Enable { win } \
{
	set w [string trimright $win '.'] ;

	$w.path configure -state normal ;
	bind $w.main.namedir.list <Double-1> "ETS.select $win %W" ;
	$w.op.commit configure -state normal ;
	$w.op.update configure -state normal ;
	$w.op.dismiss configure -state normal ;
}

proc	ETS.Disable { win } \
{
	set w [string trimright $win '.'] ;

	$w.path configure -state disabled ;
	bind $w.main.namedir.list <Double-1> {} ;
	$w.op.commit configure -state disabled ;
	$w.op.update configure -state disabled ;
	$w.op.dismiss configure -state disabled ;
}

#
#-------------------------------------------------------------------------------

proc	ETS.update { win } \
{
	ETS.Disable $win ;
	Print $win false "Update..." ;
	EventOZ ETS.Update "$win" ;
}

proc	ETS.dismiss { win } \
{
	ETS.Disable $win ;
	EventOZ ETS.Dismiss "$win" ;
}

proc	ETS.chdir { win {field ""} } \
{
	ETS.Disable $win ;
	set w [string trimright $win '.'] ;
	Print $win false "Chdir..." ;
	if { $field != "" } {
		set path [$field get] ;
	} else {
		set path "" ;
	}
	EventOZ ETS.Chdir "$win|$path" ;
}

proc	ETS.select { win field {flag false}} \
{
	ETS.Disable $win ;
	set w [string trimright $win '.'] ;
	set index [lindex [$field curselection] 0] ;
	if { $index == "" } {
		if { $flag } {
			Print $win false "Commit..." ;
			EventOZ ETS.Commit "$win" ;
		} else {
			Print $win false "Please select." ;
			ETS.Enable $win ;
		}
	} else {
		set name [$field get $index] ;
		if { [string index $name 0] == ":" } {
			# change to child or parent
			Print $win false "Chdir..." ;
			if { [string length $name] == 1 } {
				EventOZ ETS.Chdir "$win" ;
			} else {
				EventOZ ETS.Chdir "$win|[string range $name 1 end]" ;
			}
		} else {
			# selected entry
			if { $flag } {
				set cmd Commit ;
			} else {
				set cmd Lookup ;
			}
			Print $win false "$cmd..." ;
			EventOZ ETS.$cmd "$win|$name" ;
		}
	}
}

#
# Test
#
if { $argc > 0 } {
	source ../Lib/GUI.tcl ;
	foreach n $argv {
		switch $n {
		ETS.Window {
				ETS.Window . "OZ++ Entry Selector" "ETS" ;
				.op.dismiss configure -command "exit 0" ;
				Print . false "Update..." ;
				ETS.Update . cpath pkg1 pkg2 :dir1 :di2r ;
				Print . true "Done." ;
				ETS.Enable .
			}
		}
	}
}

# End of file: EntrySelector.tcl
