#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# データ表示
#

proc	Data.Frame { w } \
{
	frame $w -bd 6 ;

# アクセスパスと識別子（クラスＩＤ？）
	frame $w.header ;
	menubutton $w.header.cid -anchor nw -relief sunken -bd 1 -width 16 \
		-menu $w.header.cid.menu ;
	menu $w.header.cid.menu ;
	menubutton $w.header.path -anchor nw -relief sunken -bd 1 \
		-menu $w.header.path.menu ;
	menu $w.header.path.menu ;
	pack $w.header.cid -side left ;
	pack $w.header.path -side right -fill x -expand yes ;
	pack $w.header -side top -fill x ;

# データなしの時のコメント
	label $w.comment -relief sunken -bd 1 -width 52 \
		-text Nothing ;
	pack $w.comment -side top -fill x -expand yes ;

# 変数名のリスト
	frame $w.name ;
#	label $w.name.title -text "Name" ;
	listbox $w.name.listbox -relief sunken -bd 1 ;
#	pack $w.name.title -side top -fill x ;
	pack $w.name.listbox -side top -fill both -expand yes ;

# 値のリスト
	frame $w.value ;
#	label $w.value.title -text "Value" ;
	listbox $w.value.listbox -relief sunken -bd 1 ;
#	pack $w.value.title -side top -fill x ;
	pack $w.value.listbox -side top -fill y -expand yes ;

# 変数名と値のリストのスクロールバー
	frame $w.scroll ;
#	label $w.scroll.title -text " " ;
	scrollbar $w.scroll.body -relief sunken -bd 1 \
		-command "Data.scroll {$w.name.listbox $w.value.listbox}" ;

#

# 見えないデータ
	listbox $w.list ;
}

proc	Data.scroll { wins pos } \
{
	foreach w $wins {
		$w yview $pos ;
	}
}

proc	Data.wm { w title iconname } \
{
	wm minsize $w 1 1
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w] ;
	wm title $w $title ;
	wm iconname $w $iconname ;
}

proc	Data.type { p w base } \
{
	foreach i [$w.name.listbox curselection] {
		set data [$w.list get $i] ;
		set name [lindex $data 0] ;
		set addr [lindex $data 1] ;
		set size [lindex $data 2] ;
		set type [Data.TypeName [lindex $data 3]] ;
		set obj [string range [lindex $data 4] 1 end] ;
		set f $w.name.listbox.$i ;
		catch { destroy $f }
		toplevel $f ;
		wm title $f $name ;
		wm iconname $f $name ;
		frame $f.title ;
		label $f.title.name -text "NAME:" -anchor w ;
		label $f.title.type -text "TYPE:" -anchor w ;
		label $f.title.addr -text "ADDR:" -anchor w ;
		label $f.title.size -text "SIZE:" -anchor w ;
		frame $f.value ;
		label $f.value.name -text $name ;
		label $f.value.type -text $type ;
		label $f.value.addr -text $addr ;
		label $f.value.size -text $size ;
		button $f.close -text Close -command "destroy $f" ;
		pack $f.close -side bottom ;
		pack $f.title.name -side top -fill x ;
		pack $f.title.type -side top -fill x ;
		pack $f.title.addr -side top -fill x ;
		pack $f.title.size -side top -fill x ;
		pack $f.title -side left ;
		pack $f.value.name -side top ;
		pack $f.value.type -side top ;
		pack $f.value.addr -side top ;
		pack $f.value.size -side top ;
		pack $f.value -side left ;
	}
}

proc	Data.Adjust { w size } \
{
	pack forget $w.comment ;
	pack forget $w.name ;
	pack forget $w.value ;
	pack forget $w.scroll ;
	if { $size == 0 } {
		pack $w.comment -side top -fill x ;
	} elseif { $size <= 10 } {
		ReSize $w.name.listbox 30 $size ;
		ReSize $w.value.listbox 22 $size ;
		$w.name.listbox configure -yscroll "" ;
		$w.value.listbox configure -yscroll "" ;
		pack $w.name -side left -fill both -expand yes ;
		pack $w.value -side left -fill y ;
	} else {
		ReSize $w.name.listbox 30 10 ;
		ReSize $w.value.listbox 22 10 ;
		pack $w.scroll.body -side top -fill y -expand yes
		$w.name.listbox configure -yscroll "$w.scroll.body set" ;
		$w.value.listbox configure -yscroll "$w.scroll.body set" ;
		pack $w.name -side left -fill both -expand yes ;
		pack $w.value $w.scroll -side left -fill y ;
	}
}

proc	Data.Clear { w } \
{
	$w.name.listbox delete 0 end
	$w.value.listbox delete 0 end
	$w.list delete 0 end
}

proc	Data.Inspect { p w path } \
{
	set dm [lindex [$p.data get] 0 ] ;
	foreach i [$w.value.listbox curselection] {
		set data [$w.list get $i] ;
		set name [lindex $data 0] ;
		set type [lindex $data 3] ;
		set obj [string range [lindex $data 4] 1 end] ;
		if { $obj == 0 } { continue ; } ;
		switch "[string toupper [string range $type 0 0]]" {
		"*" { Array.window $p $w.$obj $obj $path.$name $type ; }
		"R" { Record.window $p $w.$obj $obj $path.$name $type ; }
		"O" { Object.window $p $w.$obj $obj $path.$name $type ; }
		"@" { Process.Window $w.$obj $dm $obj $path.$name $type ; }
#		"G" {
#			set oid [lindex $data 4] ;
#			GlobalInspect .$oid $oid $type ;
#		} ;
		}
	}
}

proc	Data.TypeName { type } \
{
	set name "" ;
	while { [string length $type] > 0 } {
		set c [string range $type 0 0] ;
		switch "$c" {
		"v" { set name "void $name" ; break ; }
		"c" { set name "char $name" ; break ; }
		"C" { set name "unsigned char $name" ; break ; }
		"s" { set name "short $name" ; break ; }
		"S" { set name "unsigned short $name" ;break ;  }
		"i" { set name "int $name" ;break ;  }
		"I" { set name "unsigned int $name" ;break ;  }
		"l" { set name "long $name" ;break ;  }
		"L" { set name "unsigned long $name" ;break ;  }
		"f" { set name "float $name" ;break ;  }
		"d" { set name "double $name" ;break ;  }
		"z" { set name "condition $name" ;break ;  }
		"@" { append name " @" ; }
		"G" -
		"R" -
		"O" -
		"o" {
			set cid [string range $type 1 16] ;
			switch "$c" {
			"G" { set name "global $cid $name" ; }
			"R" { set name "record class $cid $name" ; }
			"O" { set name "class $cid $name" ; }
			"o" { set name "static class $cid $name" ; }
			}
			break ;
		}
		"*" { append name "\[\]" ; }
		default { append name $c }
		}
		set type [string range $type 1 end] ;
	}
	return $name ;
}

proc	ReSize { path width height } \
{
	global tk_version ;
	if { $tk_version >= 4.0 } {
		$path configure -width $width -height $height ;
	} else {
		set work x$height ;
		$path configure -geometry $width$work ;
	}
}
