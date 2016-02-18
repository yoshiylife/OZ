#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	配列表示
#

global	ArrayTypes ;
set ArrayTypes { CHAR SHORT INT LONG FLOAT DOUBLE \
			PROCESS GLOBAL LOCAL STATIC RECORD ARRAY } ;

# デバッグ回線を使用した配列表示
# 引数
# win	ウィンドウ名
# dm	デバッグ回線
# obj	配列のアドレス
# base	アクセスパス
# type	オブジェクト型
#
proc	Array.Window { win dm obj base type {range "0...-1"} } \
{
# ウィンドウ作成
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $win ; }
		toplevel $win ;
	}
	Data.wm $win "Inspect: $base" $base ;

# コントロールバー作成
	frame $w.ribon ;
	button $w.ribon.quit -relief flat -bd 1 \
		-text "Quit" -command "Unix.Close $dm ; destroy $win" ;
	pack $w.ribon.quit -side right ;
	pack $w.ribon -side top -fill x ;

# データ表示フレーム作成
	set f $w.object ;
	Unix.Send $dm "head $obj" ;
	Unix.Recv $dm data ;
	Unix.Status $dm ;
	set data "$dm [lindex $data 1] [lindex $data 2] $type $obj" ;
	Array.Frame $f $base $data ;
	pack $f -side top -fill both -expand yes ;
	Array.Update $f $f $base ;

# 見えないデータ
	entry $f.leader ;
	$f.leader delete 0 end ;
	$f.leader insert 0 $win ;
}

# デバッグ回線による配列表示
# 引数
# p	デバッグ回線を保持しているウィンドウ名
# w	作成するウィンドウ名
# obj	配列のアドレス
# path	アクセスパス
# type	オブジェクト型
#
proc	Array.window { p w obj path type } \
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

# データ表示フレーム作成
	set dm [lindex [$p.data get] 0] ;
	set f $w.array ;
	Unix.Send $dm "head $obj" ;
	Unix.Recv $dm data ;
	Unix.Status $dm ;
	set data "$dm [lindex $data 1] [lindex $data 2] $type $obj" ;
	Array.Frame $f $path $data ;
	Array.Update $f $f $path ;

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
# data	デバッグ情報
#
proc	Array.Frame { w path data } \
{
	frame $w ;

# 見えないデータ
	entry $w.data ;
	$w.data delete 0 end ;
	$w.data insert 0 $data ;

# タイトル部のフレーム作成
	frame $w.title ;
	label $w.title.path -relief sunken -bd 1 -text $path ;
	menubutton $w.title.type -relief raise -bd 1 -text ARRAY \
		-menu $w.title.type.menu ;
	menu $w.title.type.menu ;
	menubutton $w.title.info -relief sunken -bd 1 \
		-text [Data.TypeName [lindex $data 3]] \
		-menu $w.title.info.menu ;
	menu $w.title.info.menu ;
	$w.title.info.menu add command -label "Size: [lindex $data 2]" ; 
	$w.title.info.menu add command -label "Address: [lindex $data 4]" ; 
	$w.title.info.menu add command -label "Elements: [lindex $data 1]" ; 
	pack $w.title.path -side top -fill x ;
	pack $w.title.type -side left ;
	pack $w.title.info -side right -fill x -expand yes ;
	pack $w.title -side top -fill x ;

# データ部のフレーム作成
	Data.Frame $w.view ;
	pack forget $w.view.header.cid ;
	pack forget $w.view.header.path ;
	pack $w.view.header.path -side top ;
	pack $w.view -side top -fill both -expand yes ;
}

proc	Array.Update { p w base } \
{
# 表示レンジ
	set data [$w.data get] ;
	set dm [lindex $data 0] ;
	set n [lindex $data 1] ;
	set unit 256 ;
	set si 0 ;
	for { set si 0 } { $si < $n } { set si [expr $si + $unit] } {
		if { $n <= [expr $si +$unit] } {
			set range "$si...[expr $n-1]" ;
			$w.view.header.path.menu add command -label $range \
				-command "Array.update $p $w.view $base $range";
			break ;
		} else {
			set range "$si...[expr $si+$unit-1]" ;
			$w.view.header.path.menu add command -label $range \
				-command "Array.update $p $w.view $base $range";
		}
	}
	if { $n < $unit } {
		$w.view.header.path.menu delete 0 ;
		Array.update $p $w.view $base "0...[expr $n-1]" ;
	} else {
		Array.update $p $w.view $base "0...[expr $unit-1]" ;
	}
}

proc	Array.update { p w base range } \
{
	set indexs [join [split $range .] " "] ;
	set sindex [lindex $indexs 0] ;
	set eindex [lindex $indexs 1] ;
	set count [expr $eindex - $sindex + 1] ;
	set dm [lindex [$p.data get] 0] ;
	set obj [lindex [$p.data get] 4] ;
	set type [string range [lindex [$p.data get] 3] 1 end] ;

	Unix.Send $dm "array $obj $sindex $eindex" ;
	Unix.Recv $dm data ;
	set size [expr [lindex $data 2]/[lindex $data 4]] ;
	if { [lindex $data 3] == "CHAR" } {
		set cFlag true ;
	} else {
		set cFlag false ;
	}

# アクセスパスとクラスＩＤの更新
	$w.header.path configure -text $range ;

# リストボックとスクロールバーの調整
	Data.Adjust $w $count ;

# Setup Array member
	Data.Clear $w ;
	set flag 0 ;
	set pos 0 ;
	for { set i 0 } { $i < $count } { incr i } {
		if { [Unix.Recv $dm data] < 0 } {
			set flag 1 ;
			break ;
		}
		set v [lrange $data 1 end] ;
		set name [format "%d" [expr $sindex+$i] ] ;
		$w.name.listbox insert end $name ;
		if { $cFlag } {
			$w.value.listbox insert end [format "%s %c" $v $v ] ;
		} else {
			$w.value.listbox insert end $v ;
		}
		$w.list insert end "$name $pos $size $type $v" ;
		set pos [expr $pos + $size] ;
	}
	if { $flag == 0 } { Unix.Status $dm ; }

# データ表示フレームの更新イベント設定
	bind $w.value.listbox <Double-1> "Data.Inspect $p $w $base" ;

	update ;
}

proc	Array.Inspect { win oid name type obj {mode remote} } \
{
	set dm "" ;
	set data "" ;
	switch $mode {
	file	{ Unix.Open $oid dm "-F" ; }
	local	{ Unix.Open $oid dm "-L" ; }
	default	{ Unix.Open $oid dm ; }
	}
	Unix.Status $dm ;				# prompt
	Array.Window $win $dm $obj $name $type ;
}

proc	Array.Test {} \
{
	source unix.tcl ;
	source data.tcl ;
	source tk.tcl ;
	Array.Inspect . 000700110c000001 Owner *c 0xef5e4028 ;
}
