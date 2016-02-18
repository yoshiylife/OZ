#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：オブジェクトテーブルの表示
#
# ファイル名
#	ListObjectTable.tcl
#
# モジュール名
#	LOT
#
# 機能
#	エグゼキュータのオブジェクトテーブルを表示する。
#
# 参照
#	class	ListObjectTable
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
set LOT(file) ListObjectTable.tcl ;
set LOT(items) "oid status cid loaded suspended" ;

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

proc	LOT.Window { win title iname } \
{
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;

	LOT.frame $win $w.main ;

	frame $w.op ;
	pack $w.op -side top -fill x ;

	frame $w.op.oid ;
	pack $w.op.oid -side left ;
	set i 0 ;
	foreach f { Suspend Resume Threads } {
		button $w.op.oid.$i -text $f \
			-command "LOT.operate $win $w.main.oid.list $f" -state disabled ;
		pack $w.op.oid.$i -side left ;
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

	button $w.op.update -text Update -command "LOT.list $w" ;
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
	bind $w.main.oid.list <Double-1> "nop" ;
	$w.op.update configure -state disabled ;
	if { [winfo exists $w.op.oid] } {
		foreach f [winfo children $w.op.oid] {
			$f configure -state disabled ;
		}
	}
	update ;
}

proc	LOT.Enable { win } \
{
	set w [string trimright $win '.'] ;
	$w.op.update configure -state normal ;
	if { [winfo exists $w.op.oid] } {
		foreach f [winfo children $w.op.oid] {
			$f configure -state normal ;
		}
	}
	bind $w.main.oid.list <Double-1> "LOT.seloid $win %W" ;
	update ;
}

proc	LOT.Set { win oid status cid loaded suspended } \
{
	global LOT ;

	foreach f $LOT(items) {
		eval "set LOT($oid,$f) $$f" ;
	}
}

proc	LOT.Update args \
{
	global LOT ;

	set	win [lindex $args 0] ;
	set w [string trimright $win '.'] ;
	set oids [lrange $args 1 end] ;

	foreach f $LOT(items) {
		$w.main.$f.list delete 0 end ;
	}
	foreach oid [lsort $oids] {
		foreach f $LOT(items) {
			$w.main.$f.list insert end $LOT($oid,$f) ;
		}
	}
	update ;
}

proc	LOT.List { win } \
{
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
	LOT.mkItem $w.oid $w.scroll.bar "Global Object ID" 16 ;
	LOT.mkItem $w.status $w.scroll.bar "Status" ;
	LOT.mkItem $w.cid $w.scroll.bar "Configured ID" 16 ;
	LOT.mkItem $w.loaded $w.scroll.bar "Loaded" ;
	LOT.mkItem $w.suspended $w.scroll.bar "Suspended" ;

	# Scrollbar
	frame $w.scroll ;
	pack $w.scroll -side right -fill y ;
	label $w.scroll.title -text " " ;
	scrollbar $w.scroll.bar -bd 1 -relief sunken \
		-command "LOT.scroll $w {$LOT(items)}" ;
	pack $w.scroll.title -side top ;
	pack $w.scroll.bar -side top -fill y -expand yes ;

	# Bind
	tk_listboxSingleSelect $w.oid.list ;
	LOT.nop $w status cid loaded suspended ;
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

proc	LOT.seloid { p field } \
{
puts stderr "LOT.seloid p=$p, field=$field" ;
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	EventOZ LOT.SelOID "$p|[$field get $i]" ;
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
	set w [string trimright $win '.'] ;
	LOT.Disable $win ;
	LOT.Print $win "" ;
	EventOZ LOT.List "$win" ;
}

proc	LOT.operate { win field op } \
{
	set i [lindex [$field curselection] 0] ;
	if { $i == "" } {
		return ;
	}
	LOT.Disable $win ;
	set oid [$field get $i] ;
	LOT.Disable $win ;
	LOT.Print $win "$op $oid..." ;
	EventOZ LOT.Operate "$win|$op|$oid" ;
}

#
# Test
#
catch {
if { $argc > 0 } {
	foreach n $argv {
		switch $n {
		LOT.Window	{
				LOT.Window . "List of Object Table" "OList" ;
				LOT.Enable . ;
				LOT.Append . 1 Queue 1 Yes Yes Yes No ;
				LOT.Append . 2 Ready 2 No Yes No No ;
				LOT.Append . 3 Stop 3 No No No No ;
			}
		LOT.Create	{
				global LOT ;
				frame .lpt ;
				pack .lpt ;
				LOT.Create .lpt ;
				LOT.Enable .lpt ;
				LOT.Append . 1 Queue 1 Yes Yes Yes No ;
				LOT.Append . 2 Ready 2 No Yes No No ;
				LOT.Append . 3 Stop 3 No No No No ;
			}
		}
	}
}
}

# End of file: ListObjectTable.tcl
