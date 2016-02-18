#-------------------------------------------------------------------------------
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	メッセージ表示フレームの作成
#
#	Capture.frame, Capture.message, Capture.clear, Capture.save
#

global OZROOT ;

#
#	ファイルセレクタ(filesel.tcl)の自動ローディング設定
#
set path $OZROOT/lib/gui ;
set auto_index(my_file_selector) "source $path/wb2/filesel.tcl" ;
set auto_index(set_center) "source $path/wb2/if-to-oz.tcl" ;
set auto_index(set_expandable) "source $path/wb2/if-to-oz.tcl" ;

#
#	メッセージ表示フレームのフレーム作成
#
# win		作成するフレームの親パス
# width		幅（文字単位）
# height	高さ（文字単位）
#
proc	Capture.frame { win {width 80} {height 24} } \
{
	set p [string trimright $win .] ;
	set w $p.capture ;

# キャプチャ用フレームの作成
	frame $w -bd 1 -relief raised ;
	text $w.text -width 80 -height 24 -bd 1 -relief sunken \
		-yscrollcommand "$w.scrollbar set" ;
	scrollbar $w.scrollbar -bd 1 -relief sunken \
		-command "$w.text yview" ;
	pack $w.text -side left -fill both -expand yes ;
	pack $w.scrollbar -side right -fill y ;

	entry $w.name ;
	$w.name delete 0 end ;

	return $w ;
}

#
#	メッセージ表示フレームのメッセージ表示
#
# win		作成したフレームの親パス
# ahead		インサート位置が行の先頭でなければ改行する
# tag		タグを付ける
#
proc	Capture.message { win msg {ahead false} {tag ""} } \
{
	set p [string trimright $win .] ;
	set w $p.capture ;
	if { $ahead } {
		if { [lindex [split [$w.text index end] .] 1] != "0" } {
			$w.text insert end "\n" ;
		}
	}
	$w.text insert end $msg ;
	if { $tag != "" } {
		$w.text tag add $tag \
			"end -1 lines linestart" "end -1 lines lineend" ;
		$w.text tag configure $tag -borderwidth 1 -relief raised \
			-foreground Black -background LightBlue ;
		$w.text tag bind $tag <Double-1> \
			"wm deiconify $tag ;\
			 $w.text tag configure $tag -background \
				[lindex [$w.text configure -background] 4] ;\
			 $w.text tag delete $tag ;\
			" ;
		$w.text tag bind $tag <Enter> \
			"$w.text tag configure $tag -background LightCyan" ;
		$w.text tag bind $tag <Leave> \
			"$w.text tag configure $tag -background LightBlue" ;
	}
	if { [lindex [split [$w.text index end] .] 1] != "0" } {
		$w.text yview -pickplace end ;
	} else {
		$w.text yview -pickplace "end - 1 lines" ;
	}
	update ;
	return $w ;
}

#
#	メッセージ表示フレームのメッセージ削除
#
# win	作成したフレームの親パス
proc	Capture.clear { win } \
{
	set p [string trimright $win .] ;
	set w $p.capture ;
	$w.text delete 1.0 end ;
	$w.text yview -pickplace 1 ;
	update ;
	return $w ;
}

#
#	メッセージ表示フレームのメッセージ保存
#
# win	作成したフレームの親パス
# mode	新しいファイルを指定するか。(new)
#
proc	Capture.save { win mode } \
{
	global OZROOT ;
	set path /tmp ;
	set p [string trimright $win .] ;
	set w $p.capture ;

	# ファイル名の獲得
	set name "" ;
	if { $mode == "new" } {
		$w.name delete 0 end ;
		my_file_selector $w.fsel Capture.name $w $path ;
		grab set $w.fsel ;
		tkwait window $w.fsel ;
		set name [$w.name get] ;
		if { $name == "" } { return ; }
	} else {
		set name [$w.name get] ;
	}

	# 最初の場合のファイル名の獲得
	if { $name == "" } {
		$w.name delete 0 end ;
		my_file_selector $w.fsel Capture.name $w $path ;
		grab set $w.fsel ;
		tkwait window $w.fsel ;
		set name [$w.name get] ;
		if { $name == "" } { return ; }
	}

	# 上書きの場合の確認
	if { $mode == "new" && [file exists $name] == 1 } {
		set ret [tk_dialog $w.dialog "Debug Message Capture: Save" \
					"Overwrite: $name" questhead "Cancel" "Ok" "Cancel"]
		if { $ret == "Cancel" } { return ; }
	}

	if { $mode == "new" } {
		set file [open "$name" w] ;
		puts $file [$w.text get 1.0 "end -1 chars"] ;
		close $file ;
	} else {
		set file [open "$name" a] ;
		puts $file [$w.text get 1.0 "end -1 chars"] ;
		close $file ;
	}
}

#	ファイルセレクタ(my_file_selector)とのＩ／Ｆ
proc	Capture.name { name w } \
{
	$w.name delete 0 end ;
	$w.name insert 0 $name ;
}

proc	Capture.nop { } \
{
}

#
#	End of メッセージ表示フレームの作成
#-------------------------------------------------------------------------------

