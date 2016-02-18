#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：プロセステーブルの表示
#
# ファイル名
#	ListProcessTable.tcl
#
# モジュール名
#	LPT
#
# 機能
#	当該エグゼキュータのプロセステーブルを表示する。
#
# 参照
#	class	ListProcessTable
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

# メモ
#	モジュール名に続いて、小文字で始まるプロシージャは当該ファイル内
#	でのみローカルに使用する。例: LPT.test

#
# グローバル変数
#
global OZROOT ;
global LPT ;

#
# 初期値設定
#
set LPT(file) ListProcessTable.tcl ;
set LPT(items) "pid status oid tid runstat" ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$LPT(file): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

proc	LPT.Window { win title iname } \
{
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;

	LPT.frame $win $w.main ;

	frame $w.op ;
	pack $w.op -side top -fill x ;

	frame $w.op.pid ;
	pack $w.op.pid -side left ;
	set i 0 ;
	foreach f { Suspend Resume Kill Status } {
		button $w.op.pid.$i -text $f \
			-command "LPT.operate $win $w.main.pid.list $f" -state disabled ;
		pack $w.op.pid.$i -side left ;
		incr i ;
	}

	button $w.op.update -text Update -command "LPT.list $win" ;
	pack $w.op.update -side right ;
	button $w.op.quit -text Quit -command "LPT.quit $win $w.op.quit" ;
	pack $w.op.quit -side right ;

	LPT.footer $w ;

	update ;

	# ウィンドウの調整
    wm minsize $win [winfo width $win] [winfo height $win] ;
    wm maxsize $win [winfo width $win] [winfo screenheight $win] ;

	EventOZ LPT.Ready "$win" ;
}

proc	LPT.Create { win } \
{
	set w [string trimright $win '.'] ;

	# メインフレーム作成
	LPT.frame $win $w.main ;

	frame $w.op ;
	pack $w.op -side top -fill x ;

	button $w.op.update -text Update -command "LPT.list $w" ;
	pack $w.op.update -side right ;
	button $w.op.quit -text Quit -command "LPT.quit $win $w.op.quit" ;
	pack $w.op.quit -side right ;

	update ;
	EventOZ LPT.Ready "$win" ;
}

# Destory frame
proc	LPT.Destroy { w } \
{
	destroy $w ;
}

# Tcl/Tk exit
proc	Exit { status } \
{
	exit $status ;
}

# Print status message
proc	LPT.Print { win msg {mode false} } \
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

proc	LPT.Clear { win } \
{
	global LPT ;
	set w [string trimright $win '.'] ;
	foreach f $LPT(items) {
		$w.main.$f.list delete 0 end ;
	}
	LPT.Print $win "" ;
}

proc	LPT.Disable { win } \
{
	global LPT ;
	set w [string trimright $win '.'] ;
	proc nop { } { }
	bind $w.main.pid.list <Double-1> "nop" ;
	bind $w.main.oid.list <Double-1> "nop" ;
	bind $w.main.tid.list <Double-1> "nop" ;
	$w.op.update configure -state disabled ;
	if { [winfo exists $w.op.pid] } {
		foreach f [winfo children $w.op.pid] {
			$f configure -state disabled ;
		}
	}
}

proc	LPT.Enable { win } \
{
	set w [string trimright $win '.'] ;
	$w.op.update configure -state normal ;
	if { [winfo exists $w.op.pid] } {
		foreach f [winfo children $w.op.pid] {
			$f configure -state normal ;
		}
	}
	bind $w.main.pid.list <Double-1> "LPT.selpid $win %W" ;
	bind $w.main.oid.list <Double-1> "LPT.seloid $win %W" ;
	bind $w.main.tid.list <Double-1> "LPT.seltid $win %W" ;
}

proc	LPT.Set { win pid status oid tid {runstat ""} } \
{
	global LPT ;

	foreach f $LPT(items) {
		eval "set LPT($pid,$f) $$f" ;
	}
}

proc	LPT.Update args \
{
	global LPT ;

	set win [lindex $args 0] ;
	set w [string trimright $win '.'] ;
	set pids [lrange $args 1 end] ;
	foreach f $LPT(items) {
		$w.main.$f.list delete 0 end ;
	}
	foreach pid [lsort $pids] {
		foreach f $LPT(items) {
			$w.main.$f.list insert end $LPT($pid,$f) ;
		}
	}
	update ;
}

proc	LPT.List { win } \
{
	global LPT ;
	set w [string trimright $win '.'] ;
	LPT.list $win ;
}

#
#-------------------------------------------------------------------------------

proc	LPT.mkItem { item sbar title {width ""} } \
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
# p	モジュールのパス名
# w	メインフレームのパス名
#
proc	LPT.frame { p w } \
{
	global LPT ;

	frame $w -bd 1 -relief raised ;
	pack $w -side top -fill both -expand yes ;

	# Make items
	LPT.mkItem $w.pid $w.scroll.bar "Process ID" 16 ;
	LPT.mkItem $w.status $w.scroll.bar "Status" 8 ;
	LPT.mkItem $w.oid $w.scroll.bar "Global Object ID" 16 ;
	LPT.mkItem $w.tid $w.scroll.bar "Thread ID" 10 ;
	LPT.mkItem $w.runstat $w.scroll.bar "Running Status" ;

	# Scrollbar
	frame $w.scroll ;
	pack $w.scroll -side right -fill y ;
	label $w.scroll.title -text " " ;
	scrollbar $w.scroll.bar -bd 1 -relief sunken \
		-command "LPT.scroll $w {$LPT(items)}" ;
	pack $w.scroll.title -side top ;
	pack $w.scroll.bar -side top -fill y -expand yes ;

	# Bind
	tk_listboxSingleSelect $w.pid.list ;
	tk_listboxSingleSelect $w.oid.list ;
	tk_listboxSingleSelect $w.tid.list ;
	LPT.nop $w status runstat ;
}

#
#	フッターの作成
#
# p	モジュールのパス名
# w	メインフレームのパス名
#
proc	LPT.footer { w } \
{
	frame $w.footer -bd 1 -relief raised ;
	pack $w.footer -side bottom -fill x ;
	label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
	pack $w.footer.msg -side left -fill x -expand yes ;
}

proc	LPT.nop args \
{
#puts stderr "LPT.nop args=$args" ;
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

proc	LPT.selpid { p field } \
{
puts stderr "LPT.selpid p=$p, field=$field" ;
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	EventOZ LPT.SelPID "$p|[$field get $i]" ;
}

proc	LPT.seloid { p field } \
{
puts stderr "LPT.seloid p=$p, field=$field" ;
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	EventOZ LPT.SelOID "$p|[$field get $i]" ;
}

proc	LPT.seltid { p field } \
{
puts stderr "LPT.seltid p=$p, field=$field" ;
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	EventOZ LPT.SelTID "$p|[$field get $i]" ;
}

proc	LPT.quit { win item } \
{
	$item configure -state disabled ;
	EventOZ LPT.Quit "$win" ;
}

proc	LPT.scroll { w fields pos } \
{
	foreach f $fields {
		$w.$f.list yview $pos ;
	}
}

proc	LPT.list { win } \
{
	set w [string trimright $win '.'] ;
	LPT.Disable $win ;
	LPT.Print $win "" ;
	EventOZ LPT.List "$win" ;
}

proc	LPT.operate { win field op } \
{
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	LPT.Disable $win ;
	set pid [$field get $i] ;
	LPT.Disable $win ;
	LPT.Print $win "$op $pid..." ;
	EventOZ LPT.Operate "$win|$op|$pid" ;
}

#
# Test
#
catch {
if { $argc > 0 } {
	foreach n $argv {
		switch $n {
		LPT.Window	{
				source ../Lib/GUI.tcl
				LPT.Window . "List of Process Table" "PList" ;
				LPT.Enable . ;
				LPT.Set . 1234123456abcdef Running \
					1234123456abcdef 1234123456abcdef ;
				LPT.Update . 1234123456abcdef ;
			}
		LPT.Create	{
				source ../Lib/GUI.tcl
				global LPT ;
				frame .lpt ;
				pack .lpt ;
				LPT.Create .lpt ;
				LPT.Enable .lpt ;
				LPT.Append .lpt 0 status rootOn forkedBy ;
				LPT.Append .lpt 1 status rootOn forkedBy ;
			}
		}
	}
}
}

# End of file: ListProcessTable.tcl
