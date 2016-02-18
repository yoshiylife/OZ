#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	デバッガ：スケジューラのロードとヒープの使用状況の表示
#
# ファイル名
#	LoadAndHeapMeter.tcl
#
# モジュール名
#	LHM
#
# 機能
#	　OZ++ エグゼキュータのスケジューラのロードとヒープの使用状況を
#	０〜１００以上の値を使って表示する。
#
# 参照
#	class	LoadAndHeapMeter
#	class	LoadAndHeapMonitor
#

#
# 警告
#	このファイルは、タブストップが４、ハードタブが８で記述されている。
#

# メモ
#	モジュール名に続いて、小文字で始まるプロシージャは当該ファイル内
#	でのみローカルに使用する。例: LHM.test

#
# グローバル変数
#
global OZROOT ;
global LHM ;

#
# 初期値設定
#
set LHM(title) "Load & Heap" ;
set LHM(file) "LoadAndHeapMeter.tcl" ;
set LHM(type) "load heap" ;
#set LHM(foot,load) "Load:"
#set LHM(foot,heap) "Heap:"
set LHM(data,load) "" ;
set LHM(data,heap) "" ;
set LHM(item,load) "" ;
set LHM(item,heap) "" ;
set LHM(width) 150 ;
set LHM(height) 100 ;
set LHM(loop) true ;
set LHM(allow) true ;
set LHM(interval) 2 ;
set LHM(last,load) 1.0 ;
set LHM(last,heap) 1.0 ;
#set LHM(color,back) white ;
set LHM(color,back) "" ;
set	LHM(color,load) Red ;
set	LHM(color,heap) Blue ;

#
#	環境変数のチェック
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$LHM(file): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#-------------------------------------------------------------------------------
#	OZ++側からの命令を実行するプロシージャ
#

proc	LHM.Window { win title iname } \
{
#puts stderr "LHM.Window $win, $title, $iname" ;
	global LHM ;

	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;

	frame $w.top ;
	pack $w.top -side top -fill x ;
#	label $w.top.title -text "$site $base" ;
#	pack $w.top.title -side left -fill x -expand yes ;
#	button $w.top.quit -relief flat -text Quit -command "LHM.quit $win" ;
#	pack $w.top.quit -side right ;

	LHM.frame $win $w.main ;

#	LHM.footer $w.footer ;
	Footer $win ;

	update ;

	# ウィンドウの調整
    wm minsize $win [winfo width $win] [winfo height $win] ;
    wm maxsize $win [winfo screenwidth $win] [winfo screenheight $win] ;

	bind $w.main.graph <Expose> "LHM.expose $win" ;
	bind $w.main.graph <Double-1> "LHM.property $win" ;

	EventOZ LHM.Ready "$win|$LHM(interval)" ;
}

proc	LHM.Create { win } \
{
	set w [string trimright $win '.'] ;

	# メインフレーム作成
	LHM.frame $win $w.main ;

	bind $w.main.graph <Expose> "LHM.expose $win" ;
	bind $w.main.graph <Double-1> "LHM.property $win" ;

	update ;
	EventOZ LHM.Ready "$win|$LHM(interval)" ;
}

proc	LHM.Change { win oid } \
{
#puts stderr "LHM.Change $win, $oid" ;
	global LHM ;

	set w [string trimright $win '.'] ;
#	set site [string range $oid 0 3] ;
#	set base [string range $oid 4 9] ;
#	$w.top.title configure -text "$site $base" ;
	$w.main.graph delete all ;
	foreach t $LHM(type) {
		global LHM ;
		set LHM(item,$t) "" ;
		set LHM(data,$t) "" ;
		set LHM(last,$t) 1.0 ;
#		eval "$w.footer.$t configure -text $LHM(foot,$t)" ;
		eval "LHM.update $w.main.graph $t $LHM(color,$t) true" ;
	}
	update ;
	EventOZ LHM.Update "$win|$LHM(interval)" ;
}

proc	LHM.Update { win {oid ""} {load ""} {heap ""} } \
{
#puts stderr "LHM.Update $win, $load, $heap" ;
	global LHM ;

	set w [string trimright $win '.'] ;

	if { [string compare $oid "0000000000000000"] == 0 } {
		set flag [tk_dialog .dialog "OZ++ $LHM(title) Meter Install" \
					"Install $LHM(title) Monitor" \
					question No Yes No ;]
		EventOZ LHM.Install "$win|$flag" ;
		return ;
	}

	Print $win false [string range $oid 4 9] ;

	if { $LHM(allow) } {
		# リサイズのチェック
		set flag [LHM.resize $w.main.graph] ;
		if { $flag } {
			$w.main.graph delete all ;
#			LHM.rect $w.main.graph ;
		}

		# グラフの描画
		foreach t $LHM(type) {
#			eval "$w.footer.$t configure -text $LHM(foot,$t)$$t" ;
			eval "LHM.update $w.main.graph $t $LHM(color,$t) $flag $$t" ;
		}
		update ;
	}

	if { $LHM(loop) } {
		EventOZ LHM.Update $win|$LHM(interval) ;
	}
}

proc	LHM.Set { win interval } \
{
#puts stderr "LHM.Set win=$win,interval=$interval" ;
	global LHM ;
	set LHM(interval) $interval ;
}

#
#-------------------------------------------------------------------------------

#
#	メインフレームの作成
#
# p	モジュールのパス名
# w	メインフレームのパス名
#
proc	LHM.frame { p w } \
{
	global LHM ;

	frame $w -bd 0 -relief raised ;
	pack $w -side top -fill both -expand yes ;

	canvas $w.graph -width $LHM(width) -height $LHM(height) -bd 0 ;
	if { $LHM(color,back) != "" } {
		$w.graph configure -background $LHM(color,back) ;
	}
	pack $w.graph -side left -fill both -expand yes -padx 0 -pady 0 ;
#	LHM.rect $w.graph ;
}

proc	LHM.rect { w {flag true} } \
{
	global LHM ;
	set width [expr $LHM(width)-1] ;
	set height [expr $LHM(height)-1] ;
	if { $flag } {
		$w delete tagRect0 tagRect1 tagRect2 ;
	}
	$w create line 0 0 $width 0 -tag tagRect0 ;
	$w create line 0 0 0 $height -tag tagRect1 ;
	$w create line $width 0 $width $height -tag tagRect2 ;
}

#
#	フッターの作成
#
# p	モジュールのパス名
# w	メインフレームのパス名
#
proc	LHM.footer { w } \
{
	global LHM ;
	frame $w -bd 1 -relief raised ;
	pack $w -side bottom -fill x ;
	foreach t $LHM(type) {
		label $w.$t -bd 1 -relief sunken -fg $LHM(color,$t) -width 8 -anchor nw;
		pack $w.$t -side left -fill x -expand yes ;
	}
}

#
#	モジュールの終了
#
# win	メインフレームのパス名
#
proc	LHM.quit { win } \
{
	global LHM ;
	set w [string trimright $win '.'] ;
#	$w.top.quit configure -state disabled ;
	set LHM(loop) false ;
	EventOZ LHM.Quit $win ;
#	wm withdraw $win ;
}

proc	LHM.update { w f c flag {v ""} } \
{
	global LHM ;

	set width [expr $LHM(width)-1] ;
	set height [expr $LHM(height)-1] ;
	set item $LHM(item,$f) ;
	set data $LHM(data,$f) ;
	set last $LHM(last,$f) ;

	# 古くなったデータの処理（ウィンドウのリサイズを考慮）をする。
	set len [llength $data] ;
	if { $len > $width } {
		set start [expr $len - $width] ;
		if { $flag != "true" } {
			foreach tag [lrange $item 0 $start] {
				$w delete $tag ; 
			}
		}
		set item [lrange $item $start end] ;
		set data [lrange $data $start end] ;
		if { $flag != "true" } {
			foreach tag $item {
				$w move $tag -1 0 ;
			}
		}
	}

	# グラフ（線）の描画
	set len [llength $data] ;
	if { $len > 0 } {
		if { $flag } {
			# 全てのデータを再度描画する。
			set item "" ;
			set last [expr (100-[lindex $data 0])/100.0] ;
			foreach u $data {
				set x [llength $item] ;
				set y [expr (100-$u)/100.0] ;
				set tag [$w create line \
							$x \
							[expr $last * $height] \
							[expr $x + 1] \
							[expr $y * $height] \
								-fill $c] ;
				lappend item $tag ;
				set last $y ;
			}
		}
		# 最新線を描画し、タグのリストに加える。
		if { $v != "" } {
			set x [llength $item] ;
			set y [expr (100-$v)/100.0] ;
			set tag [$w create line \
						$x \
						[expr $last * $height] \
						[expr $x + 1] \
						[expr $y * $height] \
							-fill $c] ;
			lappend item $tag ;
			lappend data $v ;
			set last $y ;
		}
	} elseif { $len == 0 } {
		# 線を描画できない
		if { $v != "" } {
			set item "" ;
			set data $v ;
			set last [expr (100-$v)/100.0] ;
		}
	}

	set LHM(item,$f) $item ;
	set LHM(data,$f) $data ;
	set LHM(last,$f) $last ;
}

proc	LHM.resize { w } \
{
	global LHM ;
	set flag false ;
	set width [winfo width $w] ;
	set height [winfo height $w] ;
	if { $width != $LHM(width) } {
		set LHM(width) $width ;
		set flag true ;
	}
	if { $height != $LHM(height) } {
		set LHM(height) $height ;
		set flag true ;
	}
	return $flag ;
}

proc	LHM.expose { win } \
{
#puts stderr "LHM.expose win=$win" ;
	global LHM ;

	set w [string trimright $win '.'] ;

	set LHM(allow) false ;

	# リサイズのチェック
	set flag [LHM.resize $w.main.graph] ;
	if { $flag } {
		$w.main.graph delete all ;
#		LHM.rect $w.main.graph ;
		foreach t $LHM(type) {
			LHM.update $w.main.graph $t $LHM(color,$t) true ;
		}
		update ;
	}
	set LHM(allow) true ;
}

proc	LHM.setival { w f } \
{
#puts stderr "LHM.setival w=$w f=$f" ;
	global LHM ;

	set val [$f get] ;
	if { 1 < $val } {
		set LHM(interval) [format "%d" $val] ;
		destroy $w ;
	}
}

proc	LHM.select { w f } \
{
#puts stderr "LHM.select w=$w f=$f" ;
	global LHM ;

	EventOZ LHM.Select $w ;
	destroy $f ;
}

proc	LHM.remove { w f } \
{
#puts stderr "LHM.remove w=$w f=$f" ;
	global LHM ;

	EventOZ LHM.Remove $w ;
	destroy $f ;
}

proc	LHM.property { win } \
{
	global LHM ;

	set w [string trimright $win '.'] ;
	catch { destroy $w.p ; }
	toplevel $w.p -bd 5 ;
	wm title $w.p "OZ++ $LHM(title) Meter Property" ;
	wm transient $w.p $win ;
	wm geometry $w.p [string trimleft [winfo geometry $win] 0123456789x] ;
	frame $w.p.f -bd 5 ;
	pack $w.p.f -side top ;
	label $w.p.f.l -text "Sampling Time(sec):" ;
	entry $w.p.f.e -relief sunken -width 6 ;
	$w.p.f.e delete 0 end ;
	$w.p.f.e insert 0 $LHM(interval) ;
	bind $w.p.f.e <Return> "LHM.setival $w.p $w.p.f.e" ;
	frame $w.p.o ;
	pack $w.p.o -side top -fill x -expand yes ;
	button $w.p.o.s -text "Server" -command "LHM.select $win $w.p " ;
	button $w.p.o.r -text "Remove" -command "LHM.remove $win $w.p " ;
	button $w.p.o.q -text "Quit" -command "destroy $w.p ; LHM.quit $win" ;
	button $w.p.d -text Dismiss -command "destroy $w.p" ;
	pack $w.p.f.l $w.p.f.e -side left ;
	pack $w.p.o.s $w.p.o.r $w.p.o.q -side left -fill x -expand yes ;
	pack $w.p.d -side bottom -fill x -expand yes ;
}

#
# Test
#
if { $argc > 0 } {
	source ../Lib/GUI.tcl ;
	foreach n $argv {
		switch $n {
		LHM.Window	{
				LHM.Window . "OZ++ $LHM(title) Meter" "LHM" 1234123456123456 ;
				LHM.Update . 0000123456000000 ;
				LHM.Update . 0000123456000000 0 100 ;
				for { set i 0 } { $i <= 100 } { incr i } {
					LHM.Update . 0000123456000000 $i 10 ;
				}
				for { set i 20 } { $i <= 100 } { incr i } {
					LHM.Update . 0000123456000000 [expr 100 - $i] 20 ;
				}
				LHM.Update . 0000123456000000 100 0 ;
				LHM.Update . 0000123456000000 ;
			}
		LHM.Create	{
				frame .cpu ;
				pack .cpu ;
				LHM.Create .cpu ;
				button .cpu.quit -text Quit -command "LHM.quit .cpu" ;
				pack .cpu.quit -side right ;
				LHM.Update .cpu TEST 20 10 ;
			}
		test	{
				LHM.Window . "OZ++ $LHM(title) Meter" "LHM" 1234123456123456 ;
#				LHM.Window . "OZ++ $LHM(title) Meter" "LHM" "" ;
			}
		}
	}
}

# End of file: LoadAndHeapMeter.tcl
