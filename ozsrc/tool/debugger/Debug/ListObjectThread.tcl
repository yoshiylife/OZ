#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：グローバルオブジェクト単位のスレッド一覧
#
# ファイル名
#	ListObjectThread.tcl
#
# モジュール名
#	LOT
#
# 機能
#	指定されたグローバルオブジェクト（セル）上のスレッドの一覧を表示する。
#
# 参照
#	class	ListObjectThread
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

# メモ
#	モジュール名に続いて、小文字で始まるプロシージャは当該ファイル内
#	でのみローカルに使用する。例: LOT.test

#
# グローバル変数
#
global OZROOT ;
global LOT ;

#
# 初期値設定
#
set LOT(file) ListObjectThread.tcl ;
set LOT(items) "tid status suspend pid oid" ;
set LOT(oid) "" ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$LOT(file): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

proc	LOT.Window { win title iname oid } \
{
#puts stderr "LOT.Window $win, $title, $iname, $oid" ;
	global LOT ;
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;

	set LOT(oid) $oid ;
	label $w.title -text $LOT(oid) ;
	pack $w.title -side top ;
	LOT.frame $win $w.main ;

	frame $w.op ;
	pack $w.op -side top -fill x ;

	frame $w.op.tid ;
	pack $w.op.tid -side left ;
	set i 0 ;
	foreach f { Suspend Resume Kill } {
		button $w.op.tid.$i -text $f \
			-command "LOT.operate $win $w.main.tid.list $f" -state disabled ;
		pack $w.op.tid.$i -side left ;
		incr i ;
	}

	button $w.op.update -text Update -command "LOT.list $win" ;
	pack $w.op.update -side right ;
	button $w.op.quit -text Quit -command "LOT.quit $win $w.op.quit" ;
	pack $w.op.quit -side right ;

	LOT.footer $w ;

	update ;

	# ウィンドウの調整
    wm minsize $win [winfo width $win] [winfo height $win] ;
    wm maxsize $win [winfo width $win] [winfo screenheight $win] ;

	EventOZ LOT.Ready "$win" ;
}

proc	LOT.Create { win } \
{
	set w [string trimright $win '.'] ;

	# メインフレーム作成
	LOT.frame $win $w.main ;

	frame $w.op ;
	pack $w.op -side top -fill x ;

	button $w.op.update -text Update -command "LOT.list $win" ;
	pack $w.op.update -side right ;
	button $w.op.quit -text Quit -command "LOT.quit $win $w.op.quit" ;
	pack $w.op.quit -side right ;

	update ;
	EventOZ LOT.Ready "$win" ;
}

# Destory frame
proc	LOT.Destroy { w } \
{
	destroy $w ;
}

# Tcl/Tk exit
proc	Exit { status } \
{
	exit $status ;
}

# Print status message
proc	LOT.Print { win msg {mode false} } \
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

proc	LOT.Clear { win } \
{
	global LOT ;
	set w [string trimright $win '.'] ;
	foreach f $LOT(items) {
		$w.main.$f.list delete 0 end ;
	}
	LOT.Print $win "" ;
}

proc	LOT.Disable { win } \
{
	global LOT ;
	set w [string trimright $win '.'] ;
	proc nop { } { }
	bind $w.main.tid.list <Double-1> "nop" ;
	$w.op.update configure -state disabled ;
	if { [winfo exists $w.op.tid] } {
		foreach f [winfo children $w.op.tid] {
			$f configure -state disabled ;
		}
	}
}

proc	LOT.Enable { win } \
{
	set w [string trimright $win '.'] ;
	$w.op.update configure -state normal ;
	if { [winfo exists $w.op.tid] } {
		foreach f [winfo children $w.op.tid] {
			$f configure -state normal ;
		}
	}
	bind $w.main.tid.list <Double-1> "LOT.seltid $win %W" ;
}

proc	LOT.Set { win tid status suspend pid oid } \
{
	global LOT ;

	foreach f $LOT(items) {
		eval "set LOT($tid,$f) $$f" ;
	}
}

proc	LOT.Update args \
{
	global LOT ;

	set	win [lindex $args 0] ;
	set w [string trimright $win '.'] ;
	set tids [lrange $args 1 end] ;

	foreach f $LOT(items) {
		$w.main.$f.list delete 0 end ;
	}
	foreach tid [lsort $tids] {
		foreach f $LOT(items) {
			$w.main.$f.list insert end $LOT($tid,$f) ;
		}
	}
	update ;
}

proc	LOT.List { win } \
{
#puts stderr "LOT.List win=$win" ;
	global LOT ;
	set w [string trimright $win '.'] ;
	LOT.list $win ;
}

#
#-------------------------------------------------------------------------------

proc	LOT.mkItem { item sbar title {width ""} } \
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
proc	LOT.frame { p w } \
{
	global LOT ;

	frame $w -bd 1 -relief raised ;
	pack $w -side top -fill both -expand yes ;

	# Make items
	LOT.mkItem $w.tid $w.scroll.bar "Thread ID" 10 ;
	LOT.mkItem $w.status $w.scroll.bar "Status" 13 ;
	LOT.mkItem $w.suspend $w.scroll.bar "Suspend" ;
	LOT.mkItem $w.pid $w.scroll.bar "Process ID" 16 ;
	LOT.mkItem $w.oid $w.scroll.bar "Invoke from" 16 ;

	# Scrollbar
	frame $w.scroll ;
	pack $w.scroll -side right -fill y ;
	label $w.scroll.title -text " " ;
	scrollbar $w.scroll.bar -bd 1 -relief sunken \
		-command "LOT.scroll $w {$LOT(items)}" ;
	pack $w.scroll.title -side top ;
	pack $w.scroll.bar -side top -fill y -expand yes ;

	# Bind
	tk_listboxSingleSelect $w.tid.list ;
	LOT.nop $w status suspend pid oid ;
}

#
#	フッターの作成
#
# p	モジュールのパス名
# w	メインフレームのパス名
#
proc	LOT.footer { w } \
{
	frame $w.footer -bd 1 -relief raised ;
	pack $w.footer -side bottom -fill x ;
	label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
	pack $w.footer.msg -side left -fill x -expand yes ;
}

proc	LOT.nop args \
{
#puts stderr "LOT.nop args=$args" ;
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

proc	LOT.seltid { p field } \
{
puts stderr "LOT.selpid p=$p, field=$field" ;
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	EventOZ LOT.SelTID "$p|[$field get $i]" ;
}

proc	LOT.quit { win item } \
{
	$item configure -state disabled ;
	EventOZ LOT.Quit "$win" ;
}

proc	LOT.scroll { w fields pos } \
{
	foreach f $fields {
		$w.$f.list yview $pos ;
	}
}

proc	LOT.list { win } \
{
	global LOT ;
	set w [string trimright $win '.'] ;
	LOT.Disable $win ;
	LOT.Print $win "" ;
	EventOZ LOT.List "$win|$LOT(oid)" ;
}

proc	LOT.operate { win field op } \
{
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	LOT.Disable $win ;
	set tid [$field get $i] ;
	LOT.Disable $win ;
	LOT.Print $win "$op $tid..." ;
	EventOZ LOT.Operate "$win|$op|$tid" ;
}

#
# Test
#
if { $argc > 0 } {
	foreach n $argv {
		switch $n {
		LOT.Window	{
				source ../Lib/GUI.tcl ;
				LOT.Window . "List of Object's Thread" "TList" \
								1234123456123456 ;
				LOT.Enable . ;
				LOT.Set . 0x123450 Free No 1234123456123456 0 ;
				LOT.Set . 0x123451 Create No 1234123456123456 0 ;
				LOT.Set . 0x123452 Ready No 1234123456123456 0 ;
				LOT.Set . 0x123453 Running No 1234123456123456 0 ;
				LOT.Set . 0x123454 Suspend Yes 1234123456123456 0 ;
				LOT.Set . 0x123455 WaitLock No 1234123456123456 0 ;
				LOT.Set . 0x123456 WaitCondition No 1234123456123456 0 ;
				LOT.Set . 0x123457 WaitSuspend No 1234123456123456 0 ;
				LOT.Set . 0x123458 WaitTimer No 1234123456123456 0 ;
				LOT.Set . 0x123459 Zombi No 1234123456123456 0 ;
				LOT.Update . 0x123450 0x123451 0x123452 0x123453 0x123454 \
							0x123455 0x123456 0x123457 0x123458 0x123459
			}
		LOT.Create	{
				source ../Lib/GUI.tcl ;
				global LOT ;
				frame .lot ;
				pack .lot ;
				LOT.Create .lot ;
				LOT.Enable .lot ;
				LOT.Set . 0x123450 Free No 1234123456123456 0 ;
				LOT.Set . 0x123451 Create No 1234123456123456 0 ;
				LOT.Set . 0x123452 Ready No 1234123456123456 0 ;
				LOT.Set . 0x123453 Running No 1234123456123456 0 ;
				LOT.Set . 0x123454 Suspend Yes 1234123456123456 0 ;
				LOT.Set . 0x123455 WaitLock No 1234123456123456 0 ;
				LOT.Set . 0x123456 WaitCondition No 1234123456123456 0 ;
				LOT.Set . 0x123457 WaitSuspend No 1234123456123456 0 ;
				LOT.Set . 0x123458 WaitTimer No 1234123456123456 0 ;
				LOT.Set . 0x123459 Zombi No 1234123456123456 0 ;
				LOT.Update . 0x123450 0x123451 0x123452 0x123453 0x123454 \
							0x123455 0x123456 0x123457 0x123458 0x123459
			}
		}
	}
}

# End of file: ListProcessTable.tcl
