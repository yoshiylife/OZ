#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	オブジェクト表示
#

# デバッグ回線を使用したオブジェクト表示
# 引数
# win	ウィンドウ名
# dm	デバッグ回線
# obj	オブジェクトのアドレス
# base	アクセスパス
# type	オブジェクト型
#
proc	Object.Window { win dm obj base type } \
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
	Unix.Send $dm "head @$obj" ;
	Unix.Recv $dm data ;
	Unix.Status $dm ;
	set size [lindex $data 2] ;
	set ccid [lindex $data 3] ;
	set data "$dm $size $ccid $type $obj " ;
	Object.Frame $f $base $data ;
	pack $f -side top -fill both -expand yes ;
	Object.Update $f $f $base [string range $type 1 end] ;

# 見えないデータ
	entry $f.leader ;
	$f.leader delete 0 end ;
	$f.leader insert 0 $win ;
	return $w.ribon ;
}

# デバッグ回線によるレコード表示
# 引数
# p	デバッグ回線を保持しているウィンドウ名
# w	作成するウィンドウ名
# obj	オブジェクトのアドレス
# path	アクセスパス
# type	オブジェクト型
#
proc	Object.window { p w obj path type } \
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
	set f $w.object ;
	Unix.Send $dm "head @$obj" ;
	Unix.Recv $dm data ;
	Unix.Status $dm ;
	set size [lindex $data 2] ;
	set ccid [lindex $data 3] ;
	set data "$dm $size $ccid $type $obj" ;
	Object.Frame $f $path $data ;
	Object.Update $f $f $path [string range $type 1 end] ;

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
proc	Object.Frame { w path data } \
{
	frame $w ;

# 見えないデータ
	entry $w.data ;
	$w.data delete 0 end ;
	$w.data insert 0 $data ;

# タイトル部のフレーム作成
	frame $w.title ;
	label $w.title.path -relief sunken -bd 1 -text $path ;
	menubutton $w.title.type -relief raise -bd 1 \
		-menu $w.title.type.menu ;
	menu $w.title.type.menu ;
	menubutton $w.title.info -relief sunken -bd 1 \
		-text [string range [lindex $data 3] 1 end] \
		-menu $w.title.info.menu ;
	menu $w.title.info.menu ;
	$w.title.info.menu add command -label "Size: [lindex $data 2]" ; 
	$w.title.info.menu add command -label "Address: [lindex $data 4]" ; 
	if { [lindex $data 1] < 0 } {
		$w.title.type configure -text STATIC ;
	} else {
		$w.title.type configure -text OBJECT ;
		$w.title.info.menu add command \
			-label "Parts: [lindex $data 1]" ; 
	}
	pack $w.title.path -side top -fill x ;
	pack $w.title.type -side left ;
	pack $w.title.info -side right -fill x -expand yes ;
	pack $w.title -side top -fill x ;

# データ部のフレーム作成
	Data.Frame $w.view ;
	pack $w.view -side top -fill both -expand yes ;

}

proc	Object.Update { p w base start } \
{
# コンフィグレーション
	set data [$w.data get] ;
	set dm [lindex $data 0] ;
	set obj [lindex $data 4] ;
	set config "" ;
	set ccid 0 ;
	Object.config $dm $obj ccid config ;
	$w.title.info configure -text $ccid ;
	if { [llength $config] > 1 } {
		set part 0 ;
		foreach e $config {
		  set cid [lindex $e 1] ;
		  set path $cid:$part ;
		  $w.view.header.path.menu add command -label "#$part $cid" \
		 	-command "Object.update $p $w.view $base $path";
		  incr part ;
		}
	}

# 見えないデータ
	entry $w.view.config ;
	$w.view.config delete 0 end ;
	$w.view.config insert 0 $config ;

# キャスト
	Object.update $p $w.view $base $start ;
}

proc	Object.update { p w base path } \
{
	set data [$p.data get] ;
	set dm [lindex $data 0] ;
	set obj [lindex $data 4] ;

	set work [split $path :] ;
	set cid [lindex $work 0] ;
	set part 0 ;
	if { [llength $work] > 1 } {
		set part [lindex $work 1] ;
	}

# 実行時クラスＩＤへの変換
	set runtime "" ;
	set vid "" ;
	Object.convert $w $cid vid runtime part ;

	Unix.Send $dm "instance $obj $runtime $part" ;
	Unix.Recv $dm data ;
	set count [lindex $data 4] ;
	set dflags [lindex $data 5] ;

# デバッグフラグ
	set f $w.footer ;
	catch { destroy $f } ;
	frame $f ;
	entry $f.value ;
	checkbutton $f.public$obj -text Public \
		-anchor nw -width 9 -relief flat ;
	checkbutton $f.protected$obj -text Protected \
		-anchor nw -width 9 -relief flat ;
	checkbutton $f.private$obj -text Private \
		-anchor nw -width 9 -relief flat ;
	checkbutton $f.record$obj -text Record \
		-anchor nw -width 9 -relief flat ;
	pack $f.public$obj -side left -expand yes ;
	pack $f.protected$obj -side left -expand yes ;
	pack $f.private$obj -side left -expand yes ;
	pack $f.record$obj -side left -expand yes ;
	pack $f -fill both -side bottom -expand yes ;
	$f.value delete 0 end ;
	$f.value insert 0 $dflags ;
	set work "{public 0x04} {protected 0x08} {private 0x10} {record 0x01}" ;
	foreach d $work {
		set n [lindex $d 0] ;
		set b [lindex $d 1] ;
		if { $dflags & $b } {
			$f.$n$obj select ;
		} else {
			$f.$n$obj deselect ;
		}
		set cmd "Object.dflags $f $dm $obj $part $n$obj $b" ;
		$f.$n$obj configure -command $cmd ;
	}

# アクセスパスとクラスＩＤの更新
	$w.header.cid configure -text $runtime ;
	destroy $w.header.cid.menu ;
	menu $w.header.cid.menu ;
	$w.header.cid.menu add command -label "Size: [lindex $data 2]" ;
	if { [lindex $data 1] >= 0 } {
		$w.header.cid.menu add command \
			-label "Part#: [lindex $data 1]" ;
	}
	$w.header.path configure -text $vid ;

# リストボックとスクロールバーの調整
	Data.Adjust $w $count ;

# 変数名と値のリストボックへの設定
	set flag 0 ;
	Data.Clear $w ;
	for { set i 0 } { $i < $count } { incr i } {
		if { [Unix.Recv $dm data] < 0 } {
			set flag 1 ;
			break ;
		}
		set type [Data.TypeName [lindex $data 3]] ;
		$w.name.listbox insert end [lindex $data 0] ;
		$w.value.listbox insert end [lindex $data 4] ;
		$w.list insert end $data ;
	}
	if { $flag == 0 } { Unix.Status $dm ; }

# データ表示フレームの更新イベント設定
	bind $w.value.listbox <Double-1> "Data.Inspect $p $w $base" ;

# 変数の情報表示のイベント設定
	bind $w.name.listbox <Double-1> "Data.type $p $w $base" ;

	update ;
}

proc	Object.dflags { w dm obj part acc v } \
{
	set dflags [$w.value get] ;
	if { [expr $dflags & $v] == $v } {
		$w.$acc deselect ;
		set dflags [expr $dflags & [expr ~ $v]] ;
		if { [expr $dflags & 0x01f] == 0 } {
			set dflags 0 ;
		}
	} else {
		$w.$acc select ;
		set dflags [expr $dflags | $v] ;
		set dflags [expr $dflags | 0x81000000] ;
	}
	Unix.Send $dm "odebug $obj $part [format 0x%08x $dflags]" ;
	Unix.Status $dm ;
	$w.value delete 0 end ;
	$w.value insert 0 $dflags ;
}

proc	Object.convert { w cid aVersion aRuntime aPart } \
{
	upvar $aVersion version $aRuntime runtime $aPart part ;
	set p $part ;
	set part -1 ;
	foreach e [$w.config get] {
		incr part ;
		set runtime [lindex $e 0] ;
		set version [lindex $e 1] ;
		if { [string compare $cid [lindex $e 0]] == 0
			|| [string compare $cid [lindex $e 1]] == 0 } {
			if { $p == 0 || ($p != 0 && $p == $part) } {
				break ;
			}
		}
	}
	return ;
}

proc	Object.config { dm obj aConfiguredClassID aConfiguration } \
{
	upvar $aConfiguredClassID ccid $aConfiguration config ;

	set config "" ;
	set ccid 0000000000000000 ;
	set data "" ;
	Unix.Send $dm "config $obj" ;
	Unix.Recv $dm data ;
	set count [lindex $data 6] ;
	set ccid [lindex $data 2] ;
	Unix.Recv $dm data ;
	Unix.Recv $dm data ;
	set flag 0 ;
	for { set i 0 } { $i < $count } { incr i } {
		if { [Unix.Recv $dm data] < 0 } {
			set flag 1 ;
			break ;
		}
		lappend config "[lindex $data 1] [lindex $data 2]" ;
	}
	if { $flag == 0 } { Unix.Status $dm ; }
}

proc	Object.Inspect { win oid name type obj {mode remote} } \
{
	set dm "" ;
	set data "" ;
	switch $mode {
	file	{ Unix.Open $oid dm "-F" ; }
	local	{ Unix.Open $oid dm "-L" ; }
	default	{ Unix.Open $oid dm "-X [string range $oid 4 9]" ; }
	}
	Unix.Status $dm ;				# prompt
	Object.Window $win $dm $obj $name $type ;
}

proc	Object.test {} \
{
	source unix.tcl ;
	source record.tcl ;
	source array.tcl ;
	source tk.tcl ;
	source data.tcl ;
}
