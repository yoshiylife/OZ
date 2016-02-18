#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	プロセス表示
#

# デバッグ回線を使用したオブジェクト表示
# 引数
# win	ウィンドウ名
# dm	デバッグ回線
# obj	オブジェクトのアドレス
# base	アクセスパス
# type	オブジェクト型
#
proc	Process.Window { win dm obj base type } \
{
# ウィンドウ作成
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $win ; }
		toplevel $win ;
	}
	set data ""
	Unix.Send $dm "id" ;
	Unix.Recv $dm data ;
	Unix.Status $dm ;
	set pid [string range $data 0 10][string range $obj 2 end] ;
	Data.wm $win "Inspect Process: $pid" $pid ;

# コントロールバー作成
	frame $w.ribon ;
	button $w.ribon.quit -relief flat -bd 1 -text "Quit" ;
	pack $w.ribon.quit -side right ;
	pack $w.ribon -side top -fill x ;

# データ表示フレーム作成
	set f $w.process ;
	Process.Frame $f $pid $base $type ;
	Unix.Send $dm "attach $obj" ;
	set handle "" ;
	set tid "" ;
	set status "" ;
	set last "" ;
	set flag 0 ;
	set count 0 ;
	while { 1 } {
		if { [Unix.Recv $dm data] < 0 } {
			set flag 1 ;
			break ;
		}
		if { [lindex $data 0] == "Status:" } {
			set status [lindex $data 1] ;
			continue ;
		}
		if { [lindex $data 0] == "Handle:" } {
			set handle [lindex $data 1] ;
			set tid [lindex $data 2] ;
			continue ;
		}
		set last "#$count [lindex $data 1] [lindex $data 5]" ;
		$f.view.header.path.menu add command -label $last \
			-command "Process.update $f $f.view [list $last]" ;
		incr count ;
	}
	if { $flag == 0 } { Unix.Status $dm ; }
	pack $f -side top -fill both -expand yes ;
	Process.Update $f $f [list $dm $count $status $last $pid] ;
	$w.ribon.quit configure -command "Process.close $win $dm $handle $tid" ;

# 見えないデータ
	entry $f.leader ;
	$f.leader delete 0 end ;
	$f.leader insert 0 $win ;
	return $w.ribon ;
}

proc	Process.close { w dm handle tid } \
{
	Unix.Send $dm "detach $handle $tid" ;
	Unix.Close $dm ;
	destroy $w ;
}

# データ表示フレーム作成
# 引数
# w	作成するフレーム名
# path	アクセスパス
# data	デバッグ情報
#
proc	Process.Frame { w pid base type } \
{
	frame $w ;

# タイトル部のフレーム作成
	frame $w.title ;
	label $w.title.path -relief sunken -bd 1 -text $pid ;
	menubutton $w.title.type -relief raise -bd 1 -text PROCESS \
		-menu $w.title.type.menu ;
	menu $w.title.type.menu ;
	menubutton $w.title.info -relief sunken -bd 1 \
		-menu $w.title.info.menu ;
	menu $w.title.info.menu ;
	pack $w.title.path -side top -fill x ;
	pack $w.title.type -side left ;
	pack $w.title.info -side right -fill x -expand yes ;
	pack $w.title -side top -fill x ;

# データ部のフレーム作成
	Data.Frame $w.view ;
	pack $w.view -side top -fill both -expand yes ;
}

proc	Process.dflags { w obj part acc v } \
{
	set dflags [$w.dflags.value get] ;
	set dm [$w.data get] ;
	if { [expr $dflags & $v] == $v } {
		$w.dflags.$acc deselect ;
		set dflags [expr $dflags & [expr ~ $v]] ;
		if { [expr $dflags & 0x01f] == 0 } {
			set dflags 0 ;
		}
	} else {
		$w.dflags.$acc select ;
		set dflags [expr $dflags | $v] ;
		set dflags [expr $dflags | 0x81000000] ;
	}
	Unix.Send $dm "odebug $obj $part [format 0x%08x $dflags]" ;
	Unix.Status $dm ;
	$w.dflags.value delete 0 end ;
	$w.dflags.value insert 0 $dflags ;
}


proc	Process.Update { p w data } \
{

# 見えないデータ
	entry $w.data ;
	$w.data delete 0 end ;
	$w.data insert 0 $data ;
	$w.title.info configure -text [lindex $data 2] ;
	Process.update $p $w.view [lindex $data 3] ;
}

proc	tdump { pid oid tid } \
{
	set cmd "debugger -X [string range $pid 4 9] -N tdump -T $oid $tid" ;
	debug "EXEC: $cmd" ;
	set data [eval "exec $cmd"] ;
	return $data ;
}

proc	Process.update { p w sid } \
{
	set data [$p.data get] ;
	set dm [lindex $data 0] ;
	set pid [lindex $data 4] ;

	set level [lindex $sid 0] ;
	set oid [lindex $sid 1] ;
	set tid [lindex $sid 2] ;

	$w.header.path configure -text $oid:$tid ;
	$w.header.cid configure -text $level ;

# 変数名と値のリストボックへの設定
	set flag 0 ;
	Data.Clear $w ;
	set data [tdump $pid $oid $tid] ;
	set i 0 ;
	set count 0 ;
	foreach l $data {
		incr i
		if { $i == 4 } {
			set addr [lindex $l 0] ;
			set name [lindex $l 1] ;
			set self [lindex $l 2] ;
			set cid [lindex $l 3] ;
			$w.name.listbox insert end "$cid $name";
			$w.value.listbox insert end "$addr $self" ;
			$w.list insert end "$oid:$tid.$name O$cid $self";
			set i 0 ;
			incr count ;
		}
	}

# リストボックとスクロールバーの調整
	Data.Adjust $w $count ;

# データ表示フレームの更新イベント設定
	bind $w.value.listbox <Double-1> \
		"Process.Self $p $w $pid $oid" ;

	update ;
}

proc	Process.Self { p w pid oid } \
{
	foreach i [$w.value.listbox curselection] {
		set data [$w.list get $i] ;
		if { [llength $data] < 3 } { continue ; }
		set name [lindex $data 0] ;
		set type [lindex $data 1] ;
		set obj [lindex $data 2] ;
		Inspect $p.$pid:$obj $oid $name $type $obj [string range $pid 4 9];
	}
}

proc	Process.Inspect { win oid base type pid {mode remote} } \
{
	set dm "" ;
	set data "" ;
	switch $mode {
	file	{ Unix.Open $pid dm "-F" ; }
	local	{ Unix.Open $pid dm "-L" ; }
	remote	{ Unix.Open $pid dm "-X [string range $pid 4 9]" ; }
	default	{ Unix.Open $pid dm "-X $mode" ; }
	}
	Unix.Status $dm ;				# prompt
	Process.Window $win $dm $pid $base $type ;
}

proc	Process.test {} \
{
	source unix.tcl ;
	source record.tcl ;
	source array.tcl ;
	source object.tcl ;
	source inspect.tcl ;
	source tk.tcl ;
	source data.tcl ;
	Process.Inspect . 0fff001901000016 remote ;
}
