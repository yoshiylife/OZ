#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：グローバルオブジェクトリスト
#
# ファイル名
#	ListGlobalObject.tcl
#
# モジュール名
#	LGO
#
# 機能
#	グローバルオブジェクトの一覧を表示する。
#
# 参照
#	class	ListGlobalObject
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

# メモ
#	モジュール名に続いて、小文字で始まるプロシージャは当該ファイル内
#	でのみローカルに使用する。例: LGO.test

#
# グローバル変数
#
global OZROOT ;
global LGO ;

#
# 初期値設定
#
set LGO(File) ListGlobalObject.tcl ;
set LGO(Items) "oid status permanent suspended safely preload" ;
set LGO(Modes) "All Loaded Ready Suspended SwappedOut Preloading" ;
set i 0 ;
foreach mode $LGO(Modes) {
	set LGO(Mode,$mode) $i ;
	incr i ;
}

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$LGO(File): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

proc	LGO.Window { win title iname } \
{
	global LGO ;
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;

	LGO.menuBar $win $w.mb ;

	# Mode
	set menu $w.mb.mode.m ;
	menubutton $w.mb.mode -text "-" -menu $menu -state disabled ;
	menu $menu ;
	pack $w.mb.mode -side left ;
	foreach e $LGO(Modes) {
		$menu add radiobutton -label $e -command "LGO.list $win $e" ;
	}

	LGO.frame $win $w.main ;

	frame $w.op1 ;
	pack $w.op1 -side top -fill x ;
	set i 0 ;
	foreach f { Suspend Resume Flush Load Remove Restore Stop Queued } {
		button $w.op1.$i -text $f \
			-command "LGO.operate $win $w.main.oid.list $f" -state disabled ;
		pack $w.op1.$i -side left -fill x -expand yes ;
		incr i ;
	}

	frame $w.op2 ;
	pack $w.op2 -side top -fill x ;
	set i 0 ;
	foreach f { Permanentize Transientize AddPreloading RemovePreloading } {
		button $w.op2.$i -text $f \
			-command "LGO.operate $win $w.main.oid.list $f" -state disabled ;
		pack $w.op2.$i -side left -fill x -expand yes ;
		incr i ;
	}

	frame $w.op3 ;
	pack $w.op3 -side top -fill x ;
	set i 0 ;
	foreach f { Lookup } {
		button $w.op3.$i -text $f \
			-command "LGO.operate $win $w.main.oid.list $f" -state disabled ;
		pack $w.op3.$i -side left -fill x -expand yes ;
		incr i ;
	}

	LGO.footer $w ;

	update ;

	# ウィンドウの調整
    wm minsize $win [winfo width $win] [winfo height $win] ;
    wm maxsize $win [winfo width $win] [winfo screenheight $win] ;

	EventOZ LGO.Ready "$win" ;
}

proc	LGO.Create { win } \
{
	set w [string trimright $win '.'] ;

	# ＬＧＯメインフレーム作成
	LGO.frame $win $w.main ;

	update ;
	EventOZ LGO.Ready "$win" ;
}

# Destory frame
proc	LGO.Destroy { w } \
{
	destroy $w ;
}

# Tcl/Tk exit
proc	Exit { status } \
{
	exit $status ;
}

# Print status message
#proc	LGO.Print { win msg {mode false} } \
#{
#	set w [string trimright $win '.'] ;
#	if { $mode } {
#		set pre [lindex [$w.footer.msg configure -text] 4] ;
#		$w.footer.msg configure -text $pre$msg ;
#	} else {
#		$w.footer.msg configure -text $msg ;
#	}
#	update ;
#}

proc	LGO.Clear { win } \
{
	global LGO ;
	set w [string trimright $win '.'] ;
	foreach f $LGO(Items) {
		$w.main.$f.list delete 0 end ;
	}
	Print $win false "" ;
}

proc	LGO.Disable { win } \
{
	global LGO ;
	set w [string trimright $win '.'] ;
	proc nop { } { }
	bind $w.main.oid.list <Double-1> "nop" ;
	if { [winfo exists $w.mb] } {
		$w.mb.list configure -state disabled ;
		$w.mb.update configure -state disabled ;
	}
	if { [winfo exists $w.mb.mode] } {
		$w.mb.mode configure -state disabled ;
	}
	foreach op { op1 op2 op3 } {
		if { [winfo exists $w.$op] } {
			foreach f [winfo children $w.$op] {
				$f configure -state disabled ;
			}
		}
	}
	update ;
}

proc	LGO.Enable { win } \
{
	set w [string trimright $win '.'] ;
	if { [winfo exists $w.mb] } {
		$w.mb.list configure -state normal ;
		$w.mb.update configure -state normal ;
	}
	if { [winfo exists $w.mb.mode] } {
		$w.mb.mode configure -state normal ;
	}
	foreach op { op1 op2 op3 } {
		if { [winfo exists $w.$op] } {
			foreach f [winfo children $w.$op] {
				$f configure -state normal ;
			}
		}
	}
	bind $w.main.oid.list <Double-1> "LGO.select $win %W" ;
	update ;
}

proc	LGO.Set { win oid status permanent suspended safely preload } \
{
	global LGO ;
	foreach f $LGO(Items) {
		eval "set LGO($oid,$f) $$f" ;
	}
}

proc	LGO.Update args \
{
	global LGO ;

	set	win [lindex $args 0] ;
	set w [string trimright $win '.'] ;
	set oids [lrange $args 1 end] ;

	foreach f $LGO(Items) {
		$w.main.$f.list delete 0 end ;
	}
	foreach oid [lsort $oids] {
		foreach f $LGO(Items) {
			$w.main.$f.list insert end $LGO($oid,$f) ;
		}
	}
	update ;
}

proc	LGO.List { win mode } \
{
	global LGO ;
	set w [string trimright $win '.'] ;
	$w.mb.mode.m invoke $LGO(Mode,$mode) ;
}

#
#-------------------------------------------------------------------------------

#
#	メニューバーの作成
#
# p	ＬＧＯモジュールのパス名
# w	メニューバーのパス名
#
proc	LGO.menuBar { p w } \
{
	global LGO ;

	#
	# メニューバー用フレーム作成
	#
	frame $w -bd 1 -relief raise ;
	pack $w -side top -fill x;

	#
	# メニューバーの項目作成
	#

	# List
	set menu $w.list.m ;
	menubutton $w.list -text Manager -width 10 -menu $menu -state disabled ;
	menu $menu ;
	pack $w.list -side left ;
	$menu add command -label Architecture -command "LGO.cmd $p Architecture" ;
	$menu add command -label ExecutorID -command "LGO.cmd $p ExecutorID" ;
	$menu add command -label Domain -command "LGO.cmd $p Domain" ;
	$menu add command -label "Server..." -command "LGO.server $p" ;
	$menu add separator ;
	$menu add command -label Quit -command "LGO.quit $p" ;

	# Update
	button $w.update -text Update -width 10 -relief flat -state disabled ;
	pack $w.update -side right ;
}

proc	LGO.mkItem { item sbar title {width ""} } \
{
	frame $item ;
	if { $width == "" } { set width [string length $title] ; }
	label $item.title -text $title -width $width ;
	listbox $item.list -bd 1 -relief sunken \
			-yscroll "$sbar set" -geometry [expr $width+1]x10 ;
	pack $item -side left -fill y ;
	pack $item.title -side top ;
	pack $item.list -side top -fill both -expand yes ;
}

#
#	メインフレームの作成
#
# p	ＬＧＯモジュールのパス名
# w	メインフレームのパス名
#
proc	LGO.frame { p w } \
{
	global LGO ;

	frame $w -bd 1 -relief raised ;
	pack $w -side top -fill both -expand yes ;

	# Make items
	LGO.mkItem $w.oid $w.scroll.bar "Global Object ID" 16 ;
	LGO.mkItem $w.status $w.scroll.bar "Status" 15 ;
	LGO.mkItem $w.permanent $w.scroll.bar "Permanent" ;
	LGO.mkItem $w.suspended $w.scroll.bar "Suspended" ;
	LGO.mkItem $w.safely $w.scroll.bar "Safely" ;
	LGO.mkItem $w.preload $w.scroll.bar "Preload" ;

	# Scrollbar
	frame $w.scroll ;
	pack $w.scroll -side right -fill y ;
	label $w.scroll.title -text " " ;
	scrollbar $w.scroll.bar -bd 1 -relief sunken \
		-command "LGO.scroll $w {$LGO(Items)}" ;
	pack $w.scroll.title -side top ;
	pack $w.scroll.bar -side top -fill y -expand yes ;

	# Bind
	tk_listboxSingleSelect $w.oid.list ;
	LGO.nop $w status permanent suspended safely preload ;
}

#
#	フッターの作成
#
# p	ＬＧＯモジュールのパス名
# w	メインフレームのパス名
#
proc	LGO.footer { w } \
{
	frame $w.footer -bd 1 -relief raised ;
	pack $w.footer -side bottom -fill x ;
	label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
	pack $w.footer.msg -side left -fill x -expand yes ;
}

proc	LGO.nop args \
{
#puts stderr "LGO.nop args=$args" ;
	if { [llength $args] > 1 } {
		set p "[lindex $args 0]." ;
		set l [lrange $args 1 end] ;
	} else {
		set p "" ;
		set l [lindex $args 0] ;
	}
	proc	nop { } { }
	foreach e $l {
		set w $p$e.list ;
		bind $w <1> nop ;
		bind $w <2> nop ;
		bind $w <3> nop ;
		bind $w <B1-Motion> nop ;
		bind $w <B2-Motion> nop ;
		bind $w <B3-Motion> nop ;
		bind $w <Double-1> nop ;
		bind $w <Double-2> nop ;
		bind $w <Double-3> nop ;
	}
}

proc	LGO.select { win field } \
{
#puts stderr "LGO.select p=$p, field=$field" ;
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	LGO.Disable $win ;
	set oid [$field get $i ] ;
	Print $win false "Select $oid..." ;
	EventOZ LGO.Select "$win|$oid" ;
}

proc	LGO.cmd { win cmd } \
{
	LGO.Disable $win ;
	Print $win false "$cmd... " ;
	EventOZ LGO.Operate "$win|$cmd|0" ;
}

proc	LGO.server { win } \
{
	LGO.Disable $win ;
	Print $win false "Server... " ;
	EventOZ LGO.Server "$win" ;
}

proc	LGO.quit { win } \
{
	LGO.Disable $win ;
	EventOZ LGO.Quit "$win" ;
}

proc	LGO.scroll { w fields pos } \
{
	foreach f $fields {
		$w.$f.list yview $pos ;
	}
}

proc	LGO.list { win mode } \
{
	set w [string trimright $win '.'] ;
	LGO.Disable $win ;
	if { [winfo exists $w.mb.mode] } {
		$w.mb.mode configure -text "$mode" ;
	}
	if { [winfo exists $w.mb] } {
		$w.mb.update configure -command "LGO.list $win $mode" ;
	}
	Print $win false "" ;
	EventOZ LGO.List "$win|$mode" ;
}

proc	LGO.operate { win field op } \
{
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	set oid [$field get $i] ;
	LGO.Disable $win ;
	Print $win false "$op $oid..." ;
	EventOZ LGO.Operate "$win|$op|$oid" ;
}

#
# Test
#
if { $argc > 0 } {
	foreach n $argv {
		switch $n {
		LGO.Window	{
			source ../Lib/GUI.tcl
			LGO.Window . "Global Object List" "GList" ;
			LGO.Enable . ;
			LGO.Set . 1234567890000001 status permanent suspended safely pre;
			LGO.Set . 1234567890000002 status permanent suspended safely pre;
			LGO.Update . 1234567890000002 1234567890000001 ;
			}
		LGO.Create	{
			source GUI.tcl
			global LGO ;
			frame .lgo ;
			set LGO(Status) false ;
			set LGO(permanent) false ;
			set LGO(suspended) false ;
			set LGO(safely) false ;
			LGO.Create .lgo ;
			button .quit -text Quit -command "destroy ." ;
			pack .lgo -side top ;
			pack .quit -side bottom ;
			LGO.Enable .lgo ;
			LGO.Set .lgo 1234567890000001 status permanent suspended safely pre;
			LGO.Set .lgo 1234567890000002 status permanent suspended safely pre;
			LGO.Update .lgo 1234567890000002 1234567890000001 ;
			}
		}
	}
}

# End of file: ListGlobalObject.tcl
