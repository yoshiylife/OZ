#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	�������ץ�������ª
#
# �ե�����̾
#	exception.tcl
#
# ��ǽ
#	ɸ�����Ϥ��饨�����ץ�����å������򼡤η������ɤ߹��ߡ�
#	��ɬ�פʥإå������������ɽ�����롣
#
#		���å���󳫻ϻ�	<���������塼���ɣ�>\n
#		�̾��				<�������ץ�����å�������Х��ȿ�>\n
#							<�������ץ�����å�����>
#		��λ��				quit\n
#
# ����
#	class DebuggerExceptionCapture
#

#
# �ٹ�
#	���Υե�����ϡ����֥��ȥåפ������ϡ��ɥ��֤����ǵ��Ҥ���Ƥ��롣
#

#
# �����Х��ѿ�
#
global ExecutorID ;
global OZROOT ;
global Capture ;
set Capture(NotCaught) true ;
set Capture(Caught) false ;
set Capture(ReRaise) false ;
set Capture(DoubleFault) false ;
set Option(Process-ID) false ;
set Option(Object-ID) false ;
set Option(Exception-ID) false ;
set Option(Exception-Param) false ;
set Option(Date) false ;
set Option(Time) false ;

#
#	�Ķ��ѿ��Υ����å�
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "exception.tcl: You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	������ʬ�μ�����
#
set path $OZROOT/lib/gui ;
source $path/debugger2/capture.tcl ;
source $path/inspector/inspect.tcl ;

#
#	�ᥤ�󥦥���ɥ��κ���
#
# win		������ɥ�
# title		������ɥ��Υ����ȥ�
# iconname	��������Υ����ȥ�
#
proc	Capture.Window { win title iconname } \
{
	global OZROOT ;

#
# ������ɥ������ʥȥåפΥѥ��Ǥ�����
#
	set w [string trimright $win .] ;
	if { $w != "" } {
		catch { destroy $win ; }
		toplevel $win ;
	}
	wm title $win $title ;
	wm iconname $win $iconname ;

#
# ��˥塼�С��κ���
#
	frame $w.mb -bd 1 -relief raise ;
	pack $w.mb -side top -fill x;

	# File
	set menu $w.mb.file.m ;
	menubutton $w.mb.file -text File -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.file -side left ;
	#$menu add command -label New -command "Capture.new $win" ;
	$menu add command -label Save -command "Capture.save $win old" ;
	$menu add command -label "Save as..." -command "Capture.save $win new";
	$menu add command -label Clear -command "Capture.clear ." ;
	$menu add separator ;
	$menu add command -label Quit -command "destroy $win" ;

	# Capture
	set menu $w.mb.capture.m
	menubutton $w.mb.capture -text Capture -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.capture -side left ;
	foreach e "NotCaught Caught ReRaise DoubleFault" {
		$w.mb.capture.m add checkbutton -label $e \
			-variable Capture($e) -onvalue true -offvalue false ;
	}

	# Option
	set menu $w.mb.option.m ;
	menubutton $w.mb.option -text Option -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.option -side left ;
	foreach e "Date Time Process-ID Object-ID Exception-ID Exception-Param" {
		$w.mb.option.m add checkbutton -label $e \
			-variable Option($e) -onvalue true -offvalue false ;
	}

# �������ץ�����å�����ɽ���ե졼��κ���
	set f [Capture.frame $w 80 24] ;
	pack $f -side top -fill both -expand yes ;

# ������ɥ���Ĵ��
	set_expandable $win ;

	Capture.clear $win ;
}

#
#	�������ץ�����å�����ɽ�������󥹥ڥ�����ư
# 
# win	������ɥ��Υѥ�
# type	�����NotCaught,Caught,ReRaise,DoubleFault��
# date	������������
# time	�������λ���
# iD	������
# pid	�����ץ���
# oid	�������֥�������
#
proc	Capture.Message { win type date time id pid oid data } \
{
	global Capture Option ;

	# ������ɥ��Υѥ�̾����
	set w [string trimright $win .] ;

	set eid [lindex $data 0] ;
	set obj [lindex $data 1] ;
	set ename [lindex $data 2] ;
	set data [lrange $data 3 end] ;

	# ���󥹥ڥ�����ư��
	if { [lindex [split $eid :] 0] != "0000000000000000" } {
		if { $Capture($type) } {
			Inspect .inspect $pid Process @$eid $obj ;
		} else {
			set dm "" ;
			set work "" ;
			Unix.Open $pid dm "-L" ;
			Unix.Status $dm ;				# prompt
			Unix.Send $dm "type [string range $eid 1 end]" ;
			Unix.Recv $dm work ;
			Unix.Status $dm ;				# prompt
			Unix.Close $dm ;
			set work [lindex $work 0] ;
			if { $work != "" } { set ename $work ; }
		}
	}

	# ɽ�����Ƥκ���
	set head "" ;
	if { $Option(Date) } { append head "$date " ; }
	if { $Option(Time) } { append head "$time " ; }
	if { $Option(Process-ID) } { append head "PID:$pid " ; }
	if { $Option(Object-ID) } { append head "OID:$oid " ; }
	if { $Option(Exception-ID) } { append head "$eid " ; }
	if { $Option(Exception-Param) } { append head "$obj " ; }

	# ��å�����ɽ��
	Capture.message $w "$head$ename $data\n" ;
}

proc	Capture.Control { win } \
{
	# ������ɥ��Υѥ�̾����
	set p [string trimright $win .] ;

	puts stdout ok ;
	flush stdout ;
}

#
#	�ᥤ��롼��
#
# ��ǽ
#	�������ץ�����å���������ª���롣�������Ƥ��ᤷ��
#	Ŭ�ڤ˥��󥹥ڥ�����ư���롣
#
#	�������ץ����μ���		����	�ʰ������׵ᤢ���
#		Not Caught				 N			n
#		Caught					 C			c
#		ReRaise					 R			r
#		Double Fault			 F			f
#
proc	MainLoop { } \
{
	# �������ץ�����å�������Х��ȿ��γ���
	set size [gets stdin] ;
	if { $size == "quit" } {
		exit 0 ;											# ��λ
	}
	set data [read stdin $size] ;
	if { [string length $data] < 77 } {
		return ;											# �إå��۾�
	}

	# �������ץ�����å������Υإå����
	set head [string range $data 0 77] ;					# �إå����Ф�
	set data [string range $data 78 end] ;					# �ǡ������Ф�
	set date [lrange $head 0 2] ;							# ȯ����������
	set time [lindex $head 3] ;								# ȯ����������
	set year [lindex $head 4] ;								# ȯ������ǯ
	set cf [lindex $head 5] ;								# ����
	set id [lindex $head 6] ;								# �������å�
	set pid [lindex $head 7] ;								# ȯ�������Уɣ�
	set oid [lindex $head 8] ;								# ȯ�������ϣɣ�

	# �������ץ�����å�������Ͽ�����󥹥ڥ�����ư
	set flag false ;
	switch [string toupper $cf] {
	N -	n { Capture.Message . NotCaught   "$date" $time $id $pid $oid $data ; }
	C -	c { Capture.Message . Caught      "$date" $time $id $pid $oid $data ; }
	R -	r { Capture.Message . ReRaise     "$date" $time $id $pid $oid $data ; }
	F -	f { Capture.Message . DoubleFault "$date" $time $id $pid $oid $data ; }
	}

	# �������ץ�����å������ؤα���
	Capture.Control . ;
}

# ���������塼���ɣĤμ���
set ExecutorID [gets stdin] ;

# �ᥤ�󥦥���ɥ�����
set exid "[string range $ExecutorID 4 9]"
set title "Exception Capture: Executor($exid)" ;
set iname "Executor($exid)" ;
Capture.Window . $title $iname ;

# ��å������Ԥ�
addinput stdin "MainLoop" ;

# End of file: messasge.tcl
