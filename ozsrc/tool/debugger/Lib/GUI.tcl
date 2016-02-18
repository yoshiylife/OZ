#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	�ǥХå����ϣڡܡܤȤΣɡ���
#
# �ե�����̾
#	GUI.tcl
#
# �⥸�塼��̾
#	GUI
#
# ��ǽ
#	�ǥХå����ϣڡܡܤȤΣɡ��Ƥ�Ȥ뤿��ν�������Ԥ���
#
# ����
#	class	GUI
#

#
# �ٹ�
#	���Υե�����ϡ����֥��ȥåפ������ϡ��ɥ��֤����ǵ��Ҥ���Ƥ��롣
#

# ���

#
# �����Х��ѿ�
#
global OZROOT ;
global GUI ;

#
# ���������
#
set GUI(File) "gui.tcl" ;
rename proc SuperProc ;

#
#	�Ķ��ѿ��Υ����å�
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "$GUI(File): You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	������ʬ�μ�����
#

#
#	���顼��å������ν��Ϥ��б����뤿��Υץ�����������κ����
#
# name	�ץ�������̾
# args	����
# body	��³��
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
#	�ϣڡܡ�¦�ؤΥ��٥������
#
# name	�⥸����̾.���٥��̾		
# args		���٥�Ȥΰ���
#
proc	EventOZ { name args } \
{
	puts stdout "$name:$args" ;
	if { [catch { flush stdout ; }] != 0 } {
		exit 1 ;
	}
}

#
#	�ϣڡܡ�¦�ؤΥ�å���������
#
# msg	��å�����
#
proc	SendOZ { msg } \
{
	puts stdout $msg ;
	flush stdout ;
}

#
#	Tcl/Tk �ץ�����λ
#
# status	�ץ����ν�λ���ơ�����
#
proc	Exit { status } \
{
	exit $status ;
}

#
#	ɸ��եå����κ���
#
# win	��������ѥ�
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
#	ɸ��եå����ؤΥ�å���������
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
#	������ץȤμ�����
#
# src	�ե�����̾
#
proc	Source { src } \
{
	global OZROOT ;
	set argc 0 ;
	source $OZROOT/$src ;
}

#
#	������ɥ��ʥĥ꡼�ˤκ��
#
proc	Destroy { win } \
{
	destroy $win ;
}
