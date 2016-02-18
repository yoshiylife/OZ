#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッグメッセージの捕捉
#
# ファイル名
#	message.tcl
#
# 機能
#	標準入力からデバッグメッセージを次の形式で読み込み、
#	不必要なヘッダ部を取り除いて表示する。
#
#		セッション開始時	<エグゼキュータＩＤ>\n
#		通常時				<デバッグメッセージ総バイト数>\n
#							<デバッグメッセージ>
#		終了時				quit\n
#
# 参照
#	class DebuggerMessageCapture
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
global Capture ;		# メニュー
global Withdraw ;		# メニュー
global Option ;			# メニュー
global Exception ;
# デフォルト設定
set Capture(Default) true ;						# 必ずこの値で、変更不可
set Capture(Process) true ;
set Capture(Object) true ;
set Capture(Exception) true ;
set Withdraw(Default) false ;					# 必ずこの値で、変更不可
set Withdraw(Process) true ;
set Withdraw(Object) true ;
set Withdraw(Exception) true ;
set Option(Process-ID,Default) false ;
set Option(Process-ID,Process) false ;			# 必ずこの値で、変更不可
set Option(Process-ID,Object) false ;
set Option(Process-ID,Exception) false ;
set Option(Object-ID,Default) false ;
set Option(Object-ID,Process) false ;
set Option(Object-ID,Object) false ;			# 必ずこの値で、変更不可
set Option(Object-ID,Exception) false ;
set Option(Date,Default) false ;
set Option(Date,Process) false ;
set Option(Date,Object) false ;
set Option(Date,Exception) false ;
set Option(Time,Default) false ;
set Option(Time,Process) false ;
set Option(Time,Object) false ;
set Option(Time,Exception) false ;
set Exception Process ;							# 出力先

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "message.tcl: You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	共通部分の取り込み
#
set path $OZROOT/lib/gui ;
source $path/debugger2/capture.tcl ;

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
	global Capture Withdraw Option Exception ;

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
	menubutton $w.mb.file -text File -width 8 -menu $menu ;
	menu $menu ;
	pack $w.mb.file -side left ;
	$menu add command -label New -command "Capture.new $win" ;
	$menu add command -label Save -command "Capture.save $win old" ;
	$menu add command -label "Save as..." -command "Capture.save $win new";
	$menu add command -label Clear -command "Capture.clear ." ;
	$menu add separator ;
	$menu add command -label Quit -command "destroy $win" ;

	# Capture
	set menu $w.mb.capture.m
	menubutton $w.mb.capture -text Capture -width 8 -menu $menu ;
	menu $menu ;
	pack $w.mb.capture -side left ;
	foreach e "Process Object" {
		$w.mb.capture.m add checkbutton -label $e \
			-variable Capture($e) -onvalue true -offvalue false ;
	}
	$menu add separator ;
	$w.mb.capture.m add radiobutton -label "Exception/Default" \
		-variable Exception -value Default ;
	$w.mb.capture.m add radiobutton -label "Exception/Process" \
		-variable Exception -value Process ;

	# Withdraw
	set menu $w.mb.withdraw.m ;
	menubutton $w.mb.withdraw -text Withdraw -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.withdraw -side left ;
	foreach e "Process Object Exception" {
		$w.mb.withdraw.m add checkbutton -label $e \
			-variable Withdraw($e) -onvalue true -offvalue false ;
	}

	# Option->Date
	set menu $w.mb.date.m ;
	menubutton $w.mb.date -text Date -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.date -side left ;
	foreach e "Default Process Object Exception" {
		$menu add checkbutton -label $e \
			-variable Option(Date,$e) -onvalue true -offvalue false ;
	}

	# Option->Time
	set menu $w.mb.time.m ;
	menubutton $w.mb.time -text Time -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.time -side left ;
	foreach e "Default Process Object Exception" {
		$menu add checkbutton -label $e \
			-variable Option(Time,$e) -onvalue true -offvalue false ;
	}

	# Option->Process ID
	set menu $w.mb.pid.m ;
	menubutton $w.mb.pid -text Process-ID -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.pid -side left ;
	foreach e "Default Object Exception" {
		$menu add checkbutton -label $e \
			-variable Option(Process-ID,$e) -onvalue true -offvalue false ;
	}

	# Option->Object ID
	set menu $w.mb.oid.m ;
	menubutton $w.mb.oid -text Object-ID -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.oid -side left ;
	foreach e "Default Process Object Exception" {
		$menu add checkbutton -label $e \
			-variable Option(Object-ID,$e) -onvalue true -offvalue false ;
	}

# デバッグメッセージ表示フレームの作成
	set f [Capture.frame $w 80 24] ;
	pack $f -side top -fill both -expand yes ;

# ウィンドウの調整
	set_expandable $win ;

	Capture.clear $win ;
}

#
#	表示状態を新規にする
#
proc	Capture.new { win } \
{
	set w [string trimright $win .] ;
	Capture.clear $win ;
	catch {
		destroy $w.wProcess ;
		destroy $w.wObject ;
	}
}

#
#	サブウィンドウの作成
#
# win		ウィンドウ
# type		種別
# title		ウィンドウのタイトル
# iconname	アイコンのタイトル
#
proc	Capture.window { w type title iconname } \
{
	global OZROOT ;
	global Withdraw ;

# ウィンドウ作成
	toplevel $w ;
	wm title $w $title ;
	wm iconname $w $iconname ;
	if { $Withdraw($type) } { wm withdraw $w ; }

# キャプチャ用フレームの作成
	set f [Capture.frame $w 80 24] ;
	pack $f -side top -fill both -expand yes ;

# フッターの作成
	frame $w.footer
	pack $w.footer -side bottom -fill x ;
	button $w.save -text "Save" -command "Capture.save $w old" ;
	button $w.new -text "Save..." -command "Capture.save $w new" ;
	button $w.clear -text "Clear" -command "Capture.clear $w" ;
	button $w.close -text "Close" -command "destroy $w" ;
	pack $w.save $w.new $w.clear $w.close -side left -fill x -expand yes ;

# ウィンドウの調整
	set_expandable $w ;

	Capture.clear $w ;
}

#
#	デバッグメッセージ表示
# 
# win	ウィンドウのパス
# type	種類（Default,Process,Object,Exception）
# date	送信時の日付
# time	送信時の時刻
# iD	送信先
# pid	送信プロセス
# oid	送信オブジェクト
#
proc	Capture.Message { win type date time id pid oid data } \
{
	global Capture Withdraw Option Exception ;

	# ウィンドウのパス名作成
	set p [string trimright $win .] ;
	if { $type == "Exception" } {
		set key $Exception ;
	} else {
		set key $type ;
	}
	if { $key == "Default" } {
		set w $win ;
		set key Default ;
	} else {
		set w $p.w$key.$id ;
		if { [winfo exist $p.w$key] == 0 } { frame $p.w$key ; }
	}

	# デバッグメッセージを表示？
	if { $Capture($type) } { } else { return ; }

	# 表示内容の作成
	set head "" ;
	if { $Option(Date,$type) } { append head "$date " ; }
	if { $Option(Time,$type) } { append head "$time " ; }
	if { $Option(Process-ID,$type) } { append head "PID:$pid " ; }
	if { $Option(Object-ID,$type) } { append head "OID:$oid " ; }

	# ウィンドウ作成
	set msg "" ;
	if { $type != "Default" && [winfo exists $w] == 0 } {
		set title "Debug Message Capture: $key" ;
		append title "($id)" ;
		set iname $key ;
		append iname "($id)" ;
		Capture.window $w $type $title $iname ;
		if { $type == "Exception" } {
			set msg "Received Exception from PID:$pid OID:$oid\n";
		} else {
			set msg "Received Message from PID:$pid OID:$oid\n";
		}
		if { $Withdraw($type) } {
			Capture.message $p $msg true $w ;
		} else {
			Capture.message $p $msg ;
		}
	}
	if { $type == "Exception" } {
		if { $Withdraw($type) } { } else { Capture.message $p $msg ; }
	}

	# メッセージ表示
	if { $type == "Exception" } {
		set eid [lindex $data 0] ;
		set val [lindex $data 1] ;
		set name [lindex $data 2] ;
		set msg [lrange $data 3 end] ;
		if { $name == "User" } {
			append eid "($val)" ;
			Capture.message $w "$head$msg\t$eid\n" ;
		} else {
			append name "($val)" ;
			Capture.message $w "$head$msg\t$name\n" ;
		}
	} else {
		Capture.message $w "$head$data" ;
	}
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
#	デバッグメッセージを受信する。その内容を解釈し、
#	適切なメッセージ記録のための処理を呼び出す。
#
#	デバッグメッセージの種別		記号
#		デバッガへの出力			 D
#		プロセスへの出力			 P
#		オブジェクトへの出力		 O
#		（エクセプション）			 N C R F n c r f
#
proc	MainLoop { } \
{
	# デバッグメッセージ総バイト数の獲得
	set size [gets stdin] ;
	if { $size == "quit" } {
		exit 0 ;											# 終了
	}
	set data [read stdin $size] ;
	if { [string length $data] < 77 } {
		return ;											# ヘッダ異常
	}

	# デバッグメッセージのヘッダ解釈
	set head [string range $data 0 77] ;					# ヘッダ取り出し
	set data [string range $data 78 end] ;					# データ取り出し
	set date [lrange $head 0 2] ;							# 発生した日付
	set time [lindex $head 3] ;								# 発生した時間
	set year [lindex $head 4] ;								# 発生した年
	set cf [lindex $head 5] ;								# 種別
	set id [lindex $head 6] ;								# ターゲット
	set pid [lindex $head 7] ;								# 発生したＰＩＤ
	set oid [lindex $head 8] ;								# 発生したＯＩＤ

	# デバッグメッセージ記録
	switch [string toupper $cf] {
		D	{ Capture.Message . Default  "$date" $time $id $pid $oid $data ; }
		P	{ Capture.Message . Process   "$date" $time $id $pid $oid $data ; }
		O	{ Capture.Message . Object    "$date" $time $id $pid $oid $data ; }
		N	-	n	-
		C	-	c	-
		R	-	r	-
		F	-	f	-
		O	{ Capture.Message . Exception "$date" $time $id $pid $oid $data ; }
	default { Capture.Message . Default  "$date" $time $id $pid $oid $data ; }
	}

	# デバッグメッセージへの応答
	Capture.Control . ;
}

# エグゼキュータＩＤの受信
set ExecutorID [gets stdin] ;

# メインウィンドウ作成
set exid "[string range $ExecutorID 4 9]"
set title "Debug Message Capture: Executor($exid)" ;
set iname "Executor($exid)" ;
Capture.Window . $title $iname ;

# メッセージ待ち
addinput stdin "MainLoop" ;

# End of file: messasge.tcl
