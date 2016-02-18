#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	ＧＵＩのテスト
#
# ファイル名
#	Test.tcl
#
# モジュール名
#	TEST
#
# 機能
#	Tcl/Tk を使ったプログラム（クラス）の試験をする。
#
# 参照
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

# メモ
#	モジュール名に続いて、小文字で始まるプロシージャは当該ファイル内
#	でのみローカルに使用する。例: TEST.Test

#
# グローバル変数
#
global OZROOT ;
global TEST ;

#
# 初期値設定
#
set TEST(File) Test.tcl ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$TEST(File): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	共通部分の取り込み
#
set path $OZROOT/lib/gui ;
source $path/debugger2/gui.tcl ;

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

proc	TEST.Window { win title iname } \
{
	global TEST ;
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;

	TEST.menuBar $win $w.mb ;

	TEST.frame $win $w.main ;

	TEST.footer $w ;

	update ;

	# ウィンドウの調整
    #wm minsize $win [winfo width $win] [winfo height $win] ;
    #wm maxsize $win [winfo width $win] [winfo screenheight $win] ;

	SendOZ "TEST.Ready:$win" ;
}

proc	TEST.Create { win } \
{
	set w [string trimright $win '.'] ;

	# メインフレーム作成
	TEST.frame $win $w.main ;

	update ;
	SendOZ "TEST.Ready:$win" ;
}

# Print status message
proc	TEST.Print { win msg {mode false} } \
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

proc	TEST.Clear { win } \
{
	set w [string trimright $win '.'] ;
	TEST.Print $win "" ;
}

proc	TEST.Disable { win } \
{
	set w [string trimright $win '.'] ;
	if { [winfo exists $w.mb] } {
		$w.mb.test configure -stat disabled ;
	}
	$w.main.test configure -state disabled ;
}

proc	TEST.Enable { win } \
{
	set w [string trimright $win '.'] ;
	if { [winfo exists $w.mb] } {
		$w.mb.test configure -stat normal ;
	}
	$w.main.test configure -state normal ;
}

#
#-------------------------------------------------------------------------------

#
#	メニューバーの作成
#
# p	ＬＧＯモジュールのパス名
# w	メニューバーのパス名
#
proc	TEST.menuBar { p w } \
{
	global TEST ;

	#
	# メニューバー用フレーム作成
	#
	frame $w -bd 1 -relief raise ;
	pack $w -side top -fill x;

	#
	# メニューバーの項目作成
	#

	# TEST
	set menu $w.test.m ;
	menubutton $w.test -text Test -width 10 -menu $menu -stat disabled ;
	menu $menu ;
	pack $w.test -side left ;
	$menu add separator ;
	$menu add command -label Quit -command "TEST.quit $p" ;

	# Update
	button $w.clear -text Clear -width 10 -relief flat \
		-command "TEST.Clear $p" ;
	pack $w.clear -side right ;
}

#
#	メインフレームの作成
#
# p	モジュールのパス名
# w	メインフレームのパス名
#
proc	TEST.frame { p w } \
{
	global TEST ;

	frame $w -bd 1 -relief raised ;
	pack $w -side top -fill both -expand yes ;

	button	$w.test -text Test -command "TEST.test $p" ;
	pack $w.test -side top -fill x -expand yes ;
}

#
#	フッターの作成
#
# p	ＬＧＯモジュールのパス名
# w	メインフレームのパス名
#
proc	TEST.footer { w } \
{
	frame $w.footer -bd 1 -relief raised ;
	pack $w.footer -side bottom -fill x ;
	label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
	pack $w.footer.msg -side left -fill x -expand yes ;
}

proc	TEST.test { w } \
{
	TEST.Disable $w ;
	SendOZ "TEST.Test:$w" ;
}

proc	TEST.quit { w } \
{
	TEST.Disable $w ;
	SendOZ "TEST.Quit:$w" ;
}

#
# Test
#
if { $argc > 0 } {
	foreach n $argv {
		switch $n {
		TEST.Window	{
				TEST.Window . "Test" "Test" ;
				TEST.Enable . ;
			}
		TEST.Create	{
				global TEST ;
				frame .test ;
				TEST.Create .test ;
				pack .test -side top ;
				button .quit -text Quit -command "exit 0" ;
				pack .quit -side right ;
				TEST.Enable .test ;
			}
		}
	}
}

# End of file: Test.tcl
