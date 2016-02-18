#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	レコード表示
#

# データによるレコード表示
# 引数
# win	ウィンドウ名
# data	レコードデータ
#
proc	Record.Window { win data } \
{
# ウィンドウ作成
	set w [string trimright $win '.'] ;
	set base [lindex $data 0] ;
	if { $w != "" } {
		catch { destroy $win ; }
		toplevel $win ;
	}
	Data.wm $win "Inspect: $base" $base ;

# コントロールバー作成
	frame $w.ribon ;
	button $w.ribon.close -text "Close" -relief flat \
		-command "destroy $win" ;
	pack $w.ribon.close -side right ;
	pack $w.ribon -side top -fill x ;

# データ表示フレーム作成
	set f $w.record ;
	Record.Frame $f $base $data ;
	pack $f -side top -fill both -expand yes ;
	Record.Update $f $f $base ;

# 見えないデータ
	entry $f.leader ;
	$f.leader delete 0 end ;
	$f.leader insert 0 $win ;
}

# デバッグ回線によるレコード表示
# 引数
# p	デバッグ回線を保持しているウィンドウ名
# w	作成するウィンドウ名
# obj	レコードのアドレス
# path	アクセスパス
# type	レコード型
#
proc	Record.window { p w obj path type } \
{
# サブウィンドウ作成
	catch { destroy $w ; }
	toplevel $w ;
	Data.wm $w $path $path ;

#	wm group $w [$p.leader get] ;
#	wm transient $w [$p.leader get] ;
	if { [winfo exists $p.leader] != 0 } {
		wm transient $w [$p.leader get] ;
	}

# レコードデータ読み込み
	set dm [lindex [$p.data get] 0] ;
	Unix.Send $dm "record $obj $type" ;
	set value "" ;
	set ret [Record.Recv $dm value] ;
	set name [Record.last $path] ;
	set size [lindex $ret 2] ;
	set data [list $name $obj $size $type $value] ;

# データ表示フレーム作成
	set f $w.record ;
	Record.Frame $f $path $data ;
	Record.Update $f $f [Record.last $path] ;

# サブコントロール作成
	button $w.close -text "Close" -command "destroy $w" ;
	pack $f -side top -fill both -expand yes ;
	pack $w.close -side bottom -fill x ;

# 見えないデータ
	entry $f.leader ;
	$f.leader delete 0 end ;
	$f.leader insert 0 $p ;
}

# データ表示フレーム作成
# 引数
# w	作成するフレーム名
# path	アクセスパス
# data	レコードデータ
#
proc	Record.Frame { w path data } \
{
	frame $w ;

# 見えないデータ
	entry $w.data ;
	$w.data delete 0 end ;
	$w.data insert 0 $data ;

# タイトル部のフレーム作成
	frame $w.title ;
	label $w.title.path -relief sunken -bd 1 -text $path ;
	menubutton $w.title.type -relief raise -bd 1 -text RECORD \
		-menu $w.title.type.menu ;
	menu $w.title.type.menu ;
	menubutton $w.title.info -relief sunken -bd 1 \
		-text [string range [lindex $data 3] 1 end] \
		-menu $w.title.info.menu ;
	menu $w.title.info.menu ;
	$w.title.info.menu add command -label "Size: [lindex $data 2]" ; 
	$w.title.info.menu add command -label "Address: [lindex $data 1]" ; 
	pack $w.title.path -side top -fill x ;
	pack $w.title.type -side left ;
	pack $w.title.info -side right -fill x -expand yes ;
	pack $w.title -side top -fill x ;

# データ部のフレーム作成
	Data.Frame $w.view ;
	Record.menu $w $w.view [Record.last $path] [lindex $data 4] ;
	pack $w.view -side top -fill both -expand yes ;
}

# データ部のフレームの表示内容の更新
# 引数
# p	データを保持しているウィンドウ名
# w	データ表示フレーム名
# path	表示するアクセスパス
#
proc	Record.Update { p w base {path ""} } \
{
	Record.update $p $w.view $base $path ;
}


proc	Record.update { p w base {path ""} } \
{
	set list [Record.search $p $base $path] ;
	set data [lindex $list 4] ;

# アクセスパスとレコードの識別子（クラスＩＤ？）の更新
	$w.header.cid configure -text [string range [lindex $list 3] 1 end];
	destroy $w.header.cid.menu ;
	menu $w.header.cid.menu ;
	$w.header.cid.menu add command -label "Size: [lindex $list 2]" ;
	set work [lindex $list 1] ;
	if { [string range $work 0 1] == "0x" } {
		$w.header.cid.menu add command -label "Position: Head" ;
	} else {
		$w.header.cid.menu add command -label "Position: $work" ;
	}
	$w.header.path configure -text $path ;

# リストボックとスクロールバーの調整
	Data.Adjust $w [llength $data] ;

# 変数名と値のリストボックへの設定
	Data.Clear $w ;
	foreach a $data {
		$w.name.listbox insert end [lindex $a 0] ;
		set type [lindex $a 3] ;
		if { "[string range $type 0 0]" == "R" } {
			$w.value.listbox insert end [string range $type 1 end] ;
		} else {
			$w.value.listbox insert end [lindex $a 4] ;
		}
		$w.list insert end $a ;
	}

# データ表示フレームの更新イベント設定
	bind $w.value.listbox <Double-1> "Record.select $p $w $base $path" ;

# 変数の情報表示のイベント設定
	bind $w.name.listbox <Double-1> "Data.type $p $w $base" ;


	update ;
}

proc	Record.jump { p w base {path ""} } \
{
	if { [Record.search $p $base $path] == "" } { return ; }
	Record.update $p $w $base $path ;
}

proc	Record.search { p base {path ""} } \
{
	set data [list [$p.data get]] ;
	set flag 0 ;
	foreach p [join [split $base.$path .] " "] {
		set flag 0 ;
		foreach d $data {
			set name [lindex $d 0] ;
			set type [lindex $d 3] ;
			set t [string range $type 0 0] ;
			if { ( $p == $name || $p == "" ) && $t == "R" } {
				set posi [lindex $d 1] ;
				set size [lindex $d 2] ;
				set data  [lindex $d 4] ;
				set flag 1 ;
				break ;
			}
		}
		if { $flag == 0 } { break ; }
	}
	if { $flag == 0 } { return "" ; } ;
	return [list $name $posi $size $type $data] ;
}

proc	Record.menu { p w base insts {path ""} } \
{
	set count [Record.add $p $w $base $insts $path] ;
	if { $count == 1 } {
		$w.header.path.menu delete 0 ;
	}
}

proc	Record.add { p w base insts path } \
{
	set count 1 ;
	$w.header.path.menu add command -label $path \
		-command "Record.jump $p $w $base $path" ;
	foreach inst $insts {
		set type [lindex $inst 3] ;
		if { "[string range $type 0 0 ]" == "R" } {
			set name [join "$path [lindex $inst 0]" .] ;
			set r [Record.add $p $w $base [lindex $inst 4] $name] ;
			set count [expr $count + $r] ;
		}
	}
	return $count ;
}

proc	Record.select { p w base {path ""} } \
{
	set indices [$w.value.listbox curselection] ;
	if { [llength $indices] == 0 } { return ; }
	set index [lindex $indices 0] ;
	set data [$w.list get $index] ;
	if { $path == "" } {
		set name [lindex $data 0] ;
	} else {
		set name .[lindex $data 0] ;
	}
	set type [lindex $data 3] ;
	if { "[string range $type 0 0 ]" == "R" } {
		if { [Record.search $p $base $path$name] == "" } { return ; }
		Record.update $p $w $base $path$name ;
	}
}

proc	Record.base { path } \
{
	set list [split $path "."] ;
	set n [llength $list] ;
	if { $n < 2 } { return "" ; }
	set n [expr $n - 2] ;
	set list [join [lrange $list 0 $n] "."] ;
	return $list ;
}

proc	Record.last { path } \
{
	set list [split $path "."] ;
	set n [llength $list] ;
	set n [expr $n - 1] ;
	return [lindex $list $n] ;
}

proc	Record.read { dm count aList } \
{
	upvar $aList list ;
	set ret 0 ;
	for { set i 0 } { $i < $count } { incr i } {
		set ret [Unix.Recv $dm data] ;
		if { $ret < 0 } { break ; }
		set type [lindex $data 3] ;
		if { "[string range $type 0 0]" == "R" } {
			set value "" ;
			set ret [Record.read $dm [lindex $data 4] value ] ;
			if { $ret < 0 } { break ; }
			lappend list [lreplace $data 4 4 $value] ;
		} else {
			lappend list $data ;
		}
	}
	return $ret ;
}

proc	Record.Recv { dm aList } \
{
	upvar $aList list ;
	set value "" ;
	Unix.Recv $dm record ;
	Record.read $dm [lindex $record 4] value ;
	Unix.Status $dm ;
	set list $value ;
	return $record ;
}

proc	Record.Inspect { win oid name type obj {mode remote} } \
{
	set dm "" ;
	set data "" ;
	switch $mode {
	file	{ Unix.Open $oid dm "-F" ; }
	local	{ Unix.Open $oid dm "-L" ; }
	default	{ Unix.Open $oid dm ; }
	}
	Unix.Status $dm ;				# prompt

# レコードデータ読み込み
	Unix.Send $dm "record $obj $type" ;
	set value "" ;
	set ret [Record.Recv $dm value] ;
	set data [list $name $obj [lindex $ret 2] $type $value] ;
	Record.Window $win $data ;
}

proc	Record.test {} \
{
	source tk.tcl ;
	source data.tcl ;
	set r1 "abcdefghijklmnopqrstuvwxyz 0 4 R0001000002000001 {{a 1 4 int 1} {b 2 4 int 2} {c 3 4 R0001000002000002 {{A 0 4 int 1} {B 0 4 R0001000002000003 {{r1_1 0 4 int a} {r1_2 1 4 int b}} } }} {d 4 4 int 4} {d 5 4 int 5} {e 0 4 R0001000002000004 {}} {f 6 4 int 6} {g 7 4 int 7} {h 8 4 int 8} {i 9 4 int 9} {j 10 4 int 10} {k 11 4 int 11}}" ;
	Record.Window . $r1 ;

#	set w .test
#	toplevel $w
#	wm minsize $w 1 1
#	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w] ;
#	wm title $w Record ;
#	wm iconname $w Record ;
#	button .test.c -text "Close" -command "destroy $w" ;
#	pack .test.c .test.r -side top -fill both -expand yes ;
#	Record.Update .test.r .test.r test ;
}
