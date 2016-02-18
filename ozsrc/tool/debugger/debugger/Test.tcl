#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	�ǣգɤΥƥ���
#
# �ե�����̾
#	Test.tcl
#
# �⥸�塼��̾
#	TEST
#
# ��ǽ
#	Tcl/Tk ��Ȥä��ץ����ʥ��饹�ˤλ�򤹤롣
#
# ����
#

#
# �ٹ�
#	���Υե�����ϡ����֥��ȥåפ������ϡ��ɥ��֤����ǵ��Ҥ���Ƥ��롣
#

# ���
#	�⥸�塼��̾��³���ơ���ʸ���ǻϤޤ�ץ�������������ե�������
#	�ǤΤߥ�����˻��Ѥ��롣��: TEST.Test

#
# �����Х��ѿ�
#
global OZROOT ;
global TEST ;

#
# ���������
#
set TEST(File) Test.tcl ;

#
#	�Ķ��ѿ��Υ����å�
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$TEST(File): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	������ʬ�μ�����
#
set path $OZROOT/lib/gui ;
source $path/debugger2/gui.tcl ;

#-------------------------------------------------------------------------------
#	OZ++¦�����̿���¹Ԥ���ץ�������
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

	# ������ɥ���Ĵ��
    #wm minsize $win [winfo width $win] [winfo height $win] ;
    #wm maxsize $win [winfo width $win] [winfo screenheight $win] ;

	SendOZ "TEST.Ready:$win" ;
}

proc	TEST.Create { win } \
{
	set w [string trimright $win '.'] ;

	# �ᥤ��ե졼�����
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
#	��˥塼�С��κ���
#
# p	�̣ǣϥ⥸�塼��Υѥ�̾
# w	��˥塼�С��Υѥ�̾
#
proc	TEST.menuBar { p w } \
{
	global TEST ;

	#
	# ��˥塼�С��ѥե졼�����
	#
	frame $w -bd 1 -relief raise ;
	pack $w -side top -fill x;

	#
	# ��˥塼�С��ι��ܺ���
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
#	�ᥤ��ե졼��κ���
#
# p	�⥸�塼��Υѥ�̾
# w	�ᥤ��ե졼��Υѥ�̾
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
#	�եå����κ���
#
# p	�̣ǣϥ⥸�塼��Υѥ�̾
# w	�ᥤ��ե졼��Υѥ�̾
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
