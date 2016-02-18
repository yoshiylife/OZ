#-------------------------------------------------------------------------------
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	��å�����ɽ���ե졼��κ���
#
#	Capture.frame, Capture.message, Capture.clear, Capture.save
#

global OZROOT ;

#
#	�ե����륻�쥯��(filesel.tcl)�μ�ư���ǥ�������
#
set path $OZROOT/lib/gui ;
set auto_index(my_file_selector) "source $path/wb2/filesel.tcl" ;
set auto_index(set_center) "source $path/wb2/if-to-oz.tcl" ;
set auto_index(set_expandable) "source $path/wb2/if-to-oz.tcl" ;

#
#	��å�����ɽ���ե졼��Υե졼�����
#
# win		��������ե졼��οƥѥ�
# width		����ʸ��ñ�̡�
# height	�⤵��ʸ��ñ�̡�
#
proc	Capture.frame { win {width 80} {height 24} } \
{
	set p [string trimright $win .] ;
	set w $p.capture ;

# ����ץ����ѥե졼��κ���
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
#	��å�����ɽ���ե졼��Υ�å�����ɽ��
#
# win		���������ե졼��οƥѥ�
# ahead		���󥵡��Ȱ��֤��Ԥ���Ƭ�Ǥʤ���в��Ԥ���
# tag		�������դ���
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
#	��å�����ɽ���ե졼��Υ�å��������
#
# win	���������ե졼��οƥѥ�
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
#	��å�����ɽ���ե졼��Υ�å�������¸
#
# win	���������ե졼��οƥѥ�
# mode	�������ե��������ꤹ�뤫��(new)
#
proc	Capture.save { win mode } \
{
	global OZROOT ;
	set path /tmp ;
	set p [string trimright $win .] ;
	set w $p.capture ;

	# �ե�����̾�γ���
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

	# �ǽ�ξ��Υե�����̾�γ���
	if { $name == "" } {
		$w.name delete 0 end ;
		my_file_selector $w.fsel Capture.name $w $path ;
		grab set $w.fsel ;
		tkwait window $w.fsel ;
		set name [$w.name get] ;
		if { $name == "" } { return ; }
	}

	# ��񤭤ξ��γ�ǧ
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

#	�ե����륻�쥯��(my_file_selector)�ȤΣɡ���
proc	Capture.name { name w } \
{
	$w.name delete 0 end ;
	$w.name insert 0 $name ;
}

proc	Capture.nop { } \
{
}

#
#	End of ��å�����ɽ���ե졼��κ���
#-------------------------------------------------------------------------------

