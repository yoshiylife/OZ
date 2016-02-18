#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：パッケージの選択
#
# ファイル名
#	PackageSelector.tcl
#
# モジュール名
#	PKS
#
# プロシージャ
#	Window, Update, Type, Enable, Disable, ( GUI: Destroy, Print, Exit )
#
# イベント
#	Ready, Chdir, Select, Choice, Update, Commit, Dismiss
#
# 機能
#	カタロクをブラウズし、 パッケージを選択する。
#
# 参照
#	Tcl/Tk	GUI.tcl
#	class	PackageSelector
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

#
# グローバル変数
#
global PKS ;

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

#	Create window
proc	PKS.Window { win title iname } \
{
#puts stderr "PKS.Window win=$win" ;

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

	# 現在のディレクトリ
	entry $w.path -bd 1 -relief sunken -state disabled ;
	pack $w.path -side top -fill x ;
	bind $w.path <Return> "PKS.chdir $win %W" ;
	
	#
	#	カタログ
	#
	frame $w.main ;
	pack $w.main -side top -fill both -expand yes ;

	# ディレクトリの内容
	frame $w.main.catalog -bd 1 -relief raised ;
	pack $w.main.catalog -side left -fill both -expand yes ;
	listbox $w.main.catalog.list -bd 1 -relief sunken \
		-yscroll "$w.main.catalog.sbar set" ;
	scrollbar $w.main.catalog.sbar -bd 1 -relief sunken \
		-command "$w.main.catalog.list yview" ;
	pack $w.main.catalog.list -side left -fill both -expand yes ;
	pack $w.main.catalog.sbar -side right -fill y ;
	tk_listboxSingleSelect $w.main.catalog.list ;

	#
	#	パッケージ
	#
	frame $w.main.package -bd 1 -relief raised ;
	pack $w.main.package -side left -fill both -expand yes ;
	set package $w.main.package ;

	# 現在のパッケージ名
	label $package.path -bd 1 -relief sunken -anchor nw ;
	pack $package.path -side top -fill x ;
	
	# パッケージの内容（スクール中のクラス名のリスト）
	frame $package.contents -bd 1 -relief raised ;
	pack $package.contents -side top -fill both -expand yes ;
	listbox $package.contents.list -bd 1 -relief sunken \
		-yscroll "$package.contents.sbar set" ;
	scrollbar $package.contents.sbar -bd 1 -relief sunken \
		-command "$package.contents.list yview" ;
	pack $package.contents.list -side left -fill both -expand yes ;
	pack $package.contents.sbar -side right -fill y ;
	tk_listboxSingleSelect $package.contents.list ;

	frame $w.op ;
	pack $w.op -side top -fill x ;
	button $w.op.commit -text Commit -state disabled \
		-command "PKS.select $win $w.main.catalog.list true" ;
	button $w.op.update -text Update -state disabled \
		-command "PKS.update $win" ;
	button $w.op.dismiss -text Dismiss -state disabled \
		-command "PKS.dismiss $win" ;
	pack $w.op.commit $w.op.update $w.op.dismiss -side left -fill x -expand yes;

	Footer $w ;

	update ;

	# ウィンドウの調整
	wm minsize $win [winfo width $win] [winfo height $win] ;
	wm maxsize $win [winfo screenwidth $win] [winfo screenheight $win] ;

	EventOZ PKS.Ready "$win" ;
}

#	Update list of current work directory
proc	PKS.Update args \
{
#puts stderr "PKS.Update args=$args" ;
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
	
	$w.main.catalog.list delete 0 end ;
	if { $path != ":" } {
		$w.main.catalog.list insert end : ;
	}
	foreach e [lsort [lrange $args 2 end]] {
		$w.main.catalog.list insert end $e ;
	}
	$w.main.package.path configure -text "" ;
	$w.main.package.contents.list delete 0 end ;
	update ;
}

#	Type list of class in current work school
proc	PKS.Type args \
{
#puts stderr "PKS.Type args=$args" ;
	set w [string trimright [lindex $args 0] '.'] ;
	set path [lindex $args 1] ;

	$w.main.package.path configure -text $path ;
	$w.main.package.contents.list delete 0 end ;
	foreach e [lsort [lrange $args 2 end]] {
		$w.main.package.contents.list insert end $e ;
	}
	update ;
}

proc	PKS.Enable { win } \
{
	set w [string trimright $win '.'] ;

	$w.path configure -state normal ;
	bind $w.main.catalog.list <Double-1> "PKS.select $win %W" ;
	bind $w.main.package.contents.list <Double-1> "PKS.choice $win %W" ;
	$w.op.commit configure -state normal ;
	$w.op.update configure -state normal ;
	$w.op.dismiss configure -state normal ;
}

proc	PKS.Disable { win } \
{
	set w [string trimright $win '.'] ;

	$w.path configure -state disabled ;
	bind $w.main.catalog.list <Double-1> {} ;
	bind $w.main.package.contents.list <Double-1> {} ;
	$w.op.commit configure -state disabled ;
	$w.op.update configure -state disabled ;
	$w.op.dismiss configure -state disabled ;
}

#
#-------------------------------------------------------------------------------

proc	PKS.update { win } \
{
	PKS.Disable $win ;
	Print $win false "Update..." ;
	EventOZ PKS.Update "$win" ;
}

proc	PKS.dismiss { win } \
{
	PKS.Disable $win ;
	EventOZ PKS.Dismiss "$win" ;
}

proc	PKS.chdir { win {field ""} } \
{
	PKS.Disable $win ;
	set w [string trimright $win '.'] ;
	Print $win false "Chdir..." ;
	if { $field != "" } {
		set path [$field get] ;
	} else {
		set path "" ;
	}
	EventOZ PKS.Chdir "$win|$path" ;
}

proc	PKS.choice { win field } \
{
	PKS.Disable $win ;
	set w [string trimright $win '.'] ;
	set index [lindex [$field curselection] 0] ;
	if { $index != "" } {
		Print $win false "Choice..." ;
		set name [$field get $index] ;
		EventOZ PKS.Choice "$win|$name" ;
	}
}

proc	PKS.select { win field {flag false}} \
{
	PKS.Disable $win ;
	set w [string trimright $win '.'] ;
	set index [lindex [$field curselection] 0] ;
	if { $index == "" } {
		if { $flag } {
			Print $win false "Commit..." ;
			EventOZ PKS.Commit "$win" ;
		} else {
			Print $win false "Please select." ;
			PKS.Enable $win ;
		}
	} else {
		set name [$field get $index] ;
		if { [string index $name 0] == ":" } {
			# change to child or parent
			Print $win false "Chdir..." ;
			if { [string length $name] == 1 } {
				EventOZ PKS.Chdir "$win" ;
			} else {
				EventOZ PKS.Chdir "$win|[string range $name 1 end]" ;
			}
		} else {
			# selected school
			if { $flag } {
				set cmd Commit ;
			} else {
				set cmd Select ;
			}
			Print $win false "$cmd..." ;
			EventOZ PKS.$cmd "$win|$name" ;
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
		PKS.Window {
				PKS.Window . "OZ++ Package Selector" "PKS" ;
				.op.dismiss configure -command "exit 0" ;
				Print . false "Update..." ;
				PKS.Update . cpath pkg1 pkg2 :dir1 :di2r ;
				PKS.Type . school class3 class2 class1 ;
				Print . true "Done." ;
				PKS.Enable .
			}
		}
	}
}

# End of file: PackageSelector.tcl
