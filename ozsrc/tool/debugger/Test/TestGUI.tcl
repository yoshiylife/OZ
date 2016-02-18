#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	�ǥХå����ƥ���
#
# �ե�����̾
#	TestGUI.tcl
#
# ��ǽ
#
# ����
#	class	TestGUI, GUI
#

#
# �ٹ�
#	���Υե�����ϡ����֥��ȥåפ������ϡ��ɥ��֤����ǵ��Ҥ���Ƥ��롣
#

#
# �����Х��ѿ�
#
global TEST ;

#-------------------------------------------------------------------------------
#	OZ++¦�����̿���¹Ԥ���ץ�������
#

#	Create window
proc	TEST.Window { win title iname } \
{
	set w [string trimright $win '.'] ;
	if { $w != "" } {
		catch { destroy $w ; }
		toplevel $w ;
	}
	wm title $win $title ;
	wm iconname $win $iname ;

	frame $w.op ;
	pack $w.op -side top -fill x -expand yes ;
	button $w.op.test -text Test -width 10 -state disabled \
		-command "TEST.test $win" ;
	button $w.op.quit -text Quit -width 10 -state disabled \
		-command "TEST.quit $win" ;
	pack $w.op.test $w.op.quit -side left -fill x -expand yes ;

	Footer $w ;

	update ;

	# ������ɥ���Ĵ��
	wm minsize $win [winfo width $win] [winfo height $win] ;
	wm maxsize $win [winfo width $win] [winfo height $win] ;

	EventOZ TEST.Ready "$win" ;
}

#
proc	TEST.Enable { win } \
{
	set w [string trimright $win '.'] ;
	$w.op.test configure -state normal ;
	$w.op.quit configure -state normal ;
}

#
proc	TEST.Disable { win } \
{
	set w [string trimright $win '.'] ;
	$w.op.test configure -state disabled ;
	$w.op.quit configure -state disabled ;
}

#
#-------------------------------------------------------------------------------

#
proc	TEST.test { win } \
{
	TEST.Disable $win ;
	Print $win false "Test..." ;
	set data "" ;
	for { set i 0 } { $i < 1000 } { incr i } {
		append data "a" ;
	}
puts stderr "Test.Test 1000" ;
	EventOZ TEST.Test "$win|$data" ;
}

#
proc	TEST.quit { win } \
{
	TEST.Disable $win ;
	EventOZ TEST.Quit "$win" ;
}

# End of file: TestGUI.tcl
