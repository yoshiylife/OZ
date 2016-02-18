#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	エクセプションの捕捉
#
# ファイル名
#	exception.tcl
#
# 機能
#	標準入力からエクセプションメッセージを次の形式で読み込み、
#	不必要なヘッダ部を取り除いて表示する。
#
#		セッション開始時	<エグゼキュータＩＤ>\n
#		通常時				<エクセプションメッセージ総バイト数>\n
#							<エクセプションメッセージ>
#		終了時				quit\n
#
# 参照
#	class DebuggerExceptionCapture
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

#
# グローバル変数
#
global ExecutorID ;
global OZROOT ;
global Capture ;
set Capture(NotCaught) true ;
set Capture(Caught) false ;
set Capture(ReRaise) false ;
set Capture(DoubleFault) false ;
set Option(Process-ID) false ;
set Option(Object-ID) false ;
set Option(Exception-ID) false ;
set Option(Exception-Param) false ;
set Option(Date) false ;
set Option(Time) false ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "exception.tcl: You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	共通部分の取り込み
#
set path $OZROOT/lib/gui ;
source $path/debugger2/capture.tcl ;
source $path/inspector/inspect.tcl ;

#
#	メインウィンドウの作成
#
# win		ウィンドウ
# title		ウィンドウのタイトル
# iconname	アイコンのタイトル
#
proc	Capture.Window { win title iconname } \
{
	global OZROOT ;

#
# ウィンドウ作成（トップのパスでも作れる）
#
	set w [string trimright $win .] ;
	if { $w != "" } {
		catch { destroy $win ; }
		toplevel $win ;
	}
	wm title $win $title ;
	wm iconname $win $iconname ;

#
# メニューバーの作成
#
	frame $w.mb -bd 1 -relief raise ;
	pack $w.mb -side top -fill x;

	# File
	set menu $w.mb.file.m ;
	menubutton $w.mb.file -text File -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.file -side left ;
	#$menu add command -label New -command "Capture.new $win" ;
	$menu add command -label Save -command "Capture.save $win old" ;
	$menu add command -label "Save as..." -command "Capture.save $win new";
	$menu add command -label Clear -command "Capture.clear ." ;
	$menu add separator ;
	$menu add command -label Quit -command "destroy $win" ;

	# Capture
	set menu $w.mb.capture.m
	menubutton $w.mb.capture -text Capture -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.capture -side left ;
	foreach e "NotCaught Caught ReRaise DoubleFault" {
		$w.mb.capture.m add checkbutton -label $e \
			-variable Capture($e) -onvalue true -offvalue false ;
	}

	# Option
	set menu $w.mb.option.m ;
	menubutton $w.mb.option -text Option -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.option -side left ;
	foreach e "Date Time Process-ID Object-ID Exception-ID Exception-Param" {
		$w.mb.option.m add checkbutton -label $e \
			-variable Option($e) -onvalue true -offvalue false ;
	}

# エクセプションメッセージ表示フレームの作成
	set f [Capture.frame $w 80 24] ;
	pack $f -side top -fill both -expand yes ;

# ウィンドウの調整
	set_expandable $win ;

	Capture.clear $win ;
}

#
#	エクセプションメッセージ表示＆インスペクタ起動
# 
# win	ウィンドウのパス
# type	種類（NotCaught,Caught,ReRaise,DoubleFault）
# date	送信時の日付
# time	送信時の時刻
# iD	送信先
# pid	送信プロセス
# oid	送信オブジェクト
#
proc	Capture.Message { win type date time id pid oid data } \
{
	global Capture Option ;

	# ウィンドウのパス名作成
	set w [string trimright $win .] ;

	set eid [lindex $data 0] ;
	set obj [lindex $data 1] ;
	set ename [lindex $data 2] ;
	set data [lrange $data 3 end] ;

	# インスペクタを起動？
	if { [lindex [split $eid :] 0] != "0000000000000000" } {
		if { $Capture($type) } {
			Inspect .inspect $pid Process @$eid $obj ;
		} else {
			set dm "" ;
			set work "" ;
			Unix.Open $pid dm "-L" ;
			Unix.Status $dm ;				# prompt
			Unix.Send $dm "type [string range $eid 1 end]" ;
			Unix.Recv $dm work ;
			Unix.Status $dm ;				# prompt
			Unix.Close $dm ;
			set work [lindex $work 0] ;
			if { $work != "" } { set ename $work ; }
		}
	}

	# 表示内容の作成
	set head "" ;
	if { $Option(Date) } { append head "$date " ; }
	if { $Option(Time) } { append head "$time " ; }
	if { $Option(Process-ID) } { append head "PID:$pid " ; }
	if { $Option(Object-ID) } { append head "OID:$oid " ; }
	if { $Option(Exception-ID) } { append head "$eid " ; }
	if { $Option(Exception-Param) } { append head "$obj " ; }

	# メッセージ表示
	Capture.message $w "$head$ename $data\n" ;
}

proc	Capture.Control { win } \
{
	# ウィンドウのパス名作成
	set p [string trimright $win .] ;

	puts stdout ok ;
	flush stdout ;
}

#
#	メインループ
#
# 機能
#	エクセプションメッセージを捕捉する。その内容を解釈し、
#	適切にインスペクタを起動する。
#
#	エクセプションの種別		記号	（一時停止要求あり）
#		Not Caught				 N			n
#		Caught					 C			c
#		ReRaise					 R			r
#		Double Fault			 F			f
#
proc	MainLoop { } \
{
	# エクセプションメッセージ総バイト数の獲得
	set size [gets stdin] ;
	if { $size == "quit" } {
		exit 0 ;											# 終了
	}
	set data [read stdin $size] ;
	if { [string length $data] < 77 } {
		return ;											# ヘッダ異常
	}

	# エクセプションメッセージのヘッダ解釈
	set head [string range $data 0 77] ;					# ヘッダ取り出し
	set data [string range $data 78 end] ;					# データ取り出し
	set date [lrange $head 0 2] ;							# 発生した日付
	set time [lindex $head 3] ;								# 発生した時間
	set year [lindex $head 4] ;								# 発生した年
	set cf [lindex $head 5] ;								# 種別
	set id [lindex $head 6] ;								# ターゲット
	set pid [lindex $head 7] ;								# 発生したＰＩＤ
	set oid [lindex $head 8] ;								# 発生したＯＩＤ

	# エクセプションメッセージ記録＆インスペクタ起動
	set flag false ;
	switch [string toupper $cf] {
	N -	n { Capture.Message . NotCaught   "$date" $time $id $pid $oid $data ; }
	C -	c { Capture.Message . Caught      "$date" $time $id $pid $oid $data ; }
	R -	r { Capture.Message . ReRaise     "$date" $time $id $pid $oid $data ; }
	F -	f { Capture.Message . DoubleFault "$date" $time $id $pid $oid $data ; }
	}

	# エクセプションメッセージへの応答
	Capture.Control . ;
}

# エグゼキュータＩＤの受信
set ExecutorID [gets stdin] ;

# メインウィンドウ作成
set exid "[string range $ExecutorID 4 9]"
set title "Exception Capture: Executor($exid)" ;
set iname "Executor($exid)" ;
Capture.Window . $title $iname ;

# メッセージ待ち
addinput stdin "MainLoop" ;

# End of file: messasge.tcl
