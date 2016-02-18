#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：ＯＺ＋＋とのＩ／Ｆ
#
# ファイル名
#	GUI.tcl
#
# モジュール名
#	GUI
#
# 機能
#	デバッガ：ＯＺ＋＋とのＩ／Ｆをとるための初期設定を行う。
#
# 参照
#	class	GUI
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

# メモ

#
# グローバル変数
#
global OZROOT ;
global GUI ;

#
# 初期値設定
#
set GUI(File) "gui.tcl" ;
rename proc SuperProc ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$GUI(File): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	共通部分の取り込み
#

#
#	エラーメッセージの出力に対応するためのプロシージャ定義の再定義
#
# name	プロシージャ名
# args	引数
# body	手続き
#
SuperProc	proc { name args body } \
{
	SuperProc $name $args "\
		if { \[catch { $body } result \] == 1 } {\
			puts stderr \"In $name\" ;\
			puts stderr \$result ;\
			return 1 ;\
		} else {\
			return \$result ;\
		} " ;
}

#
#	ＯＺ＋＋側へのイベント送信
#
# name	モジール名.イベント名		
# args		イベントの引数
#
proc	EventOZ { name args } \
{
	puts stdout "$name:$args" ;
	if { [catch { flush stdout ; }] != 0 } {
		exit 1 ;
	}
}

#
#	ＯＺ＋＋側へのメッセージ送信
#
# msg	メッセージ
#
proc	SendOZ { msg } \
{
	puts stdout $msg ;
	flush stdout ;
}

#
#	Tcl/Tk プロセス終了
#
# status	プロセスの終了ステータス
#
proc	Exit { status } \
{
	exit $status ;
}

#
#	標準フッターの作成
#
# win	作成するパス
#
proc	Footer { win } \
{
	set w [string trimright $win '.'] ;
	frame $w.footer -bd 1 -relief raised ;
	pack $w.footer -side bottom -fill x ;
	label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
	pack $w.footer.msg -side left -fill x -expand yes ;
}

#
#	標準フッターへのメッセージ出力
#
# args	[0]: path, [1]: append flag, [2]: message, ...
#
proc	Print args \
{
	set win [lindex $args 0] ;
	set flag [lindex $args 1] ;
	set msg [lrange $args 2 end] ;
	set w [string trimright $win '.'] ;
	set txt "" ;
	foreach m $msg {
		append txt "$m " ;
	}
	if { $flag } {
		set pre [lindex [$w.footer.msg configure -text] 4] ;
		$w.footer.msg configure -text $pre$txt ;
	} else {
		$w.footer.msg configure -text $txt ;
	}
	update ;
}

#
#	スクリプトの取り込み
#
# src	ファイル名
#
proc	Source { src } \
{
	global OZROOT ;
	set argc 0 ;
	source $OZROOT/$src ;
}

#
#	ウィンドウ（ツリー）の削除
#
proc	Destroy { win } \
{
	destroy $win ;
}
