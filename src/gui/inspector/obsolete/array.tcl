#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	����ɽ��
#

global	ArrayTypes ;
set ArrayTypes { CHAR SHORT INT LONG FLOAT DOUBLE \
			PROCESS GLOBAL LOCAL STATIC RECORD ARRAY } ;

# �ǥХå���������Ѥ�������ɽ��
# ����
# win	������ɥ�̾
# dm	�ǥХå�����
# obj	����Υ��ɥ쥹
# base	���������ѥ�
# type	���֥������ȷ�
#
proc	Array.Window { win dm obj base type {range "0...-1"} } \
{
# ������ɥ�����
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $win ; }
		toplevel $win ;
	}
	Data.wm $win "Inspect: $base" $base ;

# ����ȥ���С�����
	frame $w.ribon ;
	button $w.ribon.quit -relief flat -bd 1 \
		-text "Quit" -command "Unix.Close $dm ; destroy $win" ;
	pack $w.ribon.quit -side right ;
	pack $w.ribon -side top -fill x ;

# �ǡ���ɽ���ե졼�����
	set f $w.object ;
	Unix.Send $dm "head $obj" ;
	Unix.Recv $dm data ;
	Unix.Status $dm ;
	set data "$dm [lindex $data 1] [lindex $data 2] $type $obj" ;
	Array.Frame $f $base $data ;
	pack $f -side top -fill both -expand yes ;
	Array.Update $f $f $base ;

# �����ʤ��ǡ���
	entry $f.leader ;
	$f.leader delete 0 end ;
	$f.leader insert 0 $win ;
}

# �ǥХå������ˤ������ɽ��
# ����
# p	�ǥХå��������ݻ����Ƥ��륦����ɥ�̾
# w	�������륦����ɥ�̾
# obj	����Υ��ɥ쥹
# path	���������ѥ�
# type	���֥������ȷ�
#
proc	Array.window { p w obj path type } \
{
# ���֥�����ɥ�����
	catch { destroy $w ; }
	toplevel $w ;
	Data.wm $w $path $path ;

#	wm group $w [$p.leader get] ;
#	wm transient $w [$p.leader get] ;
	if { [winfo exists $p.leader] != 0 } {
		wm transient $w [$p.leader get] ;
	}

# �ǡ���ɽ���ե졼�����
	set dm [lindex [$p.data get] 0] ;
	set f $w.array ;
	Unix.Send $dm "head $obj" ;
	Unix.Recv $dm data ;
	Unix.Status $dm ;
	set data "$dm [lindex $data 1] [lindex $data 2] $type $obj" ;
	Array.Frame $f $path $data ;
	Array.Update $f $f $path ;

# ���֥���ȥ������
	button $w.close -text "Close" -command "destroy $w" ;
	pack $f -side top -fill both -expand yes ;
	pack $w.close -side bottom -fill x ;

# �����ʤ��ǡ���
	entry $f.leader ;
	$f.leader delete 0 end ;
	$f.leader insert 0 $p ;
}

# �ǡ���ɽ���ե졼�����
# ����
# w	��������ե졼��̾
# path	���������ѥ�
# data	�ǥХå�����
#
proc	Array.Frame { w path data } \
{
	frame $w ;

# �����ʤ��ǡ���
	entry $w.data ;
	$w.data delete 0 end ;
	$w.data insert 0 $data ;

# �����ȥ����Υե졼�����
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

# �ǡ������Υե졼�����
	Data.Frame $w.view ;
	pack forget $w.view.header.cid ;
	pack forget $w.view.header.path ;
	pack $w.view.header.path -side top ;
	pack $w.view -side top -fill both -expand yes ;
}

proc	Array.Update { p w base } \
{
# ɽ�����
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

# ���������ѥ��ȥ��饹�ɣĤι���
	$w.header.path configure -text $range ;

# �ꥹ�ȥܥå��ȥ�������С���Ĵ��
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

# �ǡ���ɽ���ե졼��ι������٥������
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
