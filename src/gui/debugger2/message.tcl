#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	�ǥХå���å���������ª
#
# �ե�����̾
#	message.tcl
#
# ��ǽ
#	ɸ�����Ϥ���ǥХå���å������򼡤η������ɤ߹��ߡ�
#	��ɬ�פʥإå������������ɽ�����롣
#
#		���å���󳫻ϻ�	<���������塼���ɣ�>\n
#		�̾��				<�ǥХå���å�������Х��ȿ�>\n
#							<�ǥХå���å�����>
#		��λ��				quit\n
#
# ����
#	class DebuggerMessageCapture
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
global Capture ;		# ��˥塼
global Withdraw ;		# ��˥塼
global Option ;			# ��˥塼
global Exception ;
# �ǥե��������
set Capture(Default) true ;						# ɬ�������ͤǡ��ѹ��Բ�
set Capture(Process) true ;
set Capture(Object) true ;
set Capture(Exception) true ;
set Withdraw(Default) false ;					# ɬ�������ͤǡ��ѹ��Բ�
set Withdraw(Process) true ;
set Withdraw(Object) true ;
set Withdraw(Exception) true ;
set Option(Process-ID,Default) false ;
set Option(Process-ID,Process) false ;			# ɬ�������ͤǡ��ѹ��Բ�
set Option(Process-ID,Object) false ;
set Option(Process-ID,Exception) false ;
set Option(Object-ID,Default) false ;
set Option(Object-ID,Process) false ;
set Option(Object-ID,Object) false ;			# ɬ�������ͤǡ��ѹ��Բ�
set Option(Object-ID,Exception) false ;
set Option(Date,Default) false ;
set Option(Date,Process) false ;
set Option(Date,Object) false ;
set Option(Date,Exception) false ;
set Option(Time,Default) false ;
set Option(Time,Process) false ;
set Option(Time,Object) false ;
set Option(Time,Exception) false ;
set Exception Process ;							# ������

#
#	�Ķ��ѿ��Υ����å�
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "message.tcl: You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	������ʬ�μ�����
#
set path $OZROOT/lib/gui ;
source $path/debugger2/capture.tcl ;

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
	global Capture Withdraw Option Exception ;

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
	menubutton $w.mb.file -text File -width 8 -menu $menu ;
	menu $menu ;
	pack $w.mb.file -side left ;
	$menu add command -label New -command "Capture.new $win" ;
	$menu add command -label Save -command "Capture.save $win old" ;
	$menu add command -label "Save as..." -command "Capture.save $win new";
	$menu add command -label Clear -command "Capture.clear ." ;
	$menu add separator ;
	$menu add command -label Quit -command "destroy $win" ;

	# Capture
	set menu $w.mb.capture.m
	menubutton $w.mb.capture -text Capture -width 8 -menu $menu ;
	menu $menu ;
	pack $w.mb.capture -side left ;
	foreach e "Process Object" {
		$w.mb.capture.m add checkbutton -label $e \
			-variable Capture($e) -onvalue true -offvalue false ;
	}
	$menu add separator ;
	$w.mb.capture.m add radiobutton -label "Exception/Default" \
		-variable Exception -value Default ;
	$w.mb.capture.m add radiobutton -label "Exception/Process" \
		-variable Exception -value Process ;

	# Withdraw
	set menu $w.mb.withdraw.m ;
	menubutton $w.mb.withdraw -text Withdraw -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.withdraw -side left ;
	foreach e "Process Object Exception" {
		$w.mb.withdraw.m add checkbutton -label $e \
			-variable Withdraw($e) -onvalue true -offvalue false ;
	}

	# Option->Date
	set menu $w.mb.date.m ;
	menubutton $w.mb.date -text Date -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.date -side left ;
	foreach e "Default Process Object Exception" {
		$menu add checkbutton -label $e \
			-variable Option(Date,$e) -onvalue true -offvalue false ;
	}

	# Option->Time
	set menu $w.mb.time.m ;
	menubutton $w.mb.time -text Time -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.time -side left ;
	foreach e "Default Process Object Exception" {
		$menu add checkbutton -label $e \
			-variable Option(Time,$e) -onvalue true -offvalue false ;
	}

	# Option->Process ID
	set menu $w.mb.pid.m ;
	menubutton $w.mb.pid -text Process-ID -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.pid -side left ;
	foreach e "Default Object Exception" {
		$menu add checkbutton -label $e \
			-variable Option(Process-ID,$e) -onvalue true -offvalue false ;
	}

	# Option->Object ID
	set menu $w.mb.oid.m ;
	menubutton $w.mb.oid -text Object-ID -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.oid -side left ;
	foreach e "Default Process Object Exception" {
		$menu add checkbutton -label $e \
			-variable Option(Object-ID,$e) -onvalue true -offvalue false ;
	}

# �ǥХå���å�����ɽ���ե졼��κ���
	set f [Capture.frame $w 80 24] ;
	pack $f -side top -fill both -expand yes ;

# ������ɥ���Ĵ��
	set_expandable $win ;

	Capture.clear $win ;
}

#
#	ɽ�����֤򿷵��ˤ���
#
proc	Capture.new { win } \
{
	set w [string trimright $win .] ;
	Capture.clear $win ;
	catch {
		destroy $w.wProcess ;
		destroy $w.wObject ;
	}
}

#
#	���֥�����ɥ��κ���
#
# win		������ɥ�
# type		����
# title		������ɥ��Υ����ȥ�
# iconname	��������Υ����ȥ�
#
proc	Capture.window { w type title iconname } \
{
	global OZROOT ;
	global Withdraw ;

# ������ɥ�����
	toplevel $w ;
	wm title $w $title ;
	wm iconname $w $iconname ;
	if { $Withdraw($type) } { wm withdraw $w ; }

# ����ץ����ѥե졼��κ���
	set f [Capture.frame $w 80 24] ;
	pack $f -side top -fill both -expand yes ;

# �եå����κ���
	frame $w.footer
	pack $w.footer -side bottom -fill x ;
	button $w.save -text "Save" -command "Capture.save $w old" ;
	button $w.new -text "Save..." -command "Capture.save $w new" ;
	button $w.clear -text "Clear" -command "Capture.clear $w" ;
	button $w.close -text "Close" -command "destroy $w" ;
	pack $w.save $w.new $w.clear $w.close -side left -fill x -expand yes ;

# ������ɥ���Ĵ��
	set_expandable $w ;

	Capture.clear $w ;
}

#
#	�ǥХå���å�����ɽ��
# 
# win	������ɥ��Υѥ�
# type	�����Default,Process,Object,Exception��
# date	������������
# time	�������λ���
# iD	������
# pid	�����ץ���
# oid	�������֥�������
#
proc	Capture.Message { win type date time id pid oid data } \
{
	global Capture Withdraw Option Exception ;

	# ������ɥ��Υѥ�̾����
	set p [string trimright $win .] ;
	if { $type == "Exception" } {
		set key $Exception ;
	} else {
		set key $type ;
	}
	if { $key == "Default" } {
		set w $win ;
		set key Default ;
	} else {
		set w $p.w$key.$id ;
		if { [winfo exist $p.w$key] == 0 } { frame $p.w$key ; }
	}

	# �ǥХå���å�������ɽ����
	if { $Capture($type) } { } else { return ; }

	# ɽ�����Ƥκ���
	set head "" ;
	if { $Option(Date,$type) } { append head "$date " ; }
	if { $Option(Time,$type) } { append head "$time " ; }
	if { $Option(Process-ID,$type) } { append head "PID:$pid " ; }
	if { $Option(Object-ID,$type) } { append head "OID:$oid " ; }

	# ������ɥ�����
	set msg "" ;
	if { $type != "Default" && [winfo exists $w] == 0 } {
		set title "Debug Message Capture: $key" ;
		append title "($id)" ;
		set iname $key ;
		append iname "($id)" ;
		Capture.window $w $type $title $iname ;
		if { $type == "Exception" } {
			set msg "Received Exception from PID:$pid OID:$oid\n";
		} else {
			set msg "Received Message from PID:$pid OID:$oid\n";
		}
		if { $Withdraw($type) } {
			Capture.message $p $msg true $w ;
		} else {
			Capture.message $p $msg ;
		}
	}
	if { $type == "Exception" } {
		if { $Withdraw($type) } { } else { Capture.message $p $msg ; }
	}

	# ��å�����ɽ��
	if { $type == "Exception" } {
		set eid [lindex $data 0] ;
		set val [lindex $data 1] ;
		set name [lindex $data 2] ;
		set msg [lrange $data 3 end] ;
		if { $name == "User" } {
			append eid "($val)" ;
			Capture.message $w "$head$msg\t$eid\n" ;
		} else {
			append name "($val)" ;
			Capture.message $w "$head$msg\t$name\n" ;
		}
	} else {
		Capture.message $w "$head$data" ;
	}
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
#	�ǥХå���å�������������롣�������Ƥ��ᤷ��
#	Ŭ�ڤʥ�å�������Ͽ�Τ���ν�����ƤӽФ���
#
#	�ǥХå���å������μ���		����
#		�ǥХå��ؤν���			 D
#		�ץ����ؤν���			 P
#		���֥������Ȥؤν���		 O
#		�ʥ������ץ�����			 N C R F n c r f
#
proc	MainLoop { } \
{
	# �ǥХå���å�������Х��ȿ��γ���
	set size [gets stdin] ;
	if { $size == "quit" } {
		exit 0 ;											# ��λ
	}
	set data [read stdin $size] ;
	if { [string length $data] < 77 } {
		return ;											# �إå��۾�
	}

	# �ǥХå���å������Υإå����
	set head [string range $data 0 77] ;					# �إå����Ф�
	set data [string range $data 78 end] ;					# �ǡ������Ф�
	set date [lrange $head 0 2] ;							# ȯ����������
	set time [lindex $head 3] ;								# ȯ����������
	set year [lindex $head 4] ;								# ȯ������ǯ
	set cf [lindex $head 5] ;								# ����
	set id [lindex $head 6] ;								# �������å�
	set pid [lindex $head 7] ;								# ȯ�������Уɣ�
	set oid [lindex $head 8] ;								# ȯ�������ϣɣ�

	# �ǥХå���å�������Ͽ
	switch [string toupper $cf] {
		D	{ Capture.Message . Default  "$date" $time $id $pid $oid $data ; }
		P	{ Capture.Message . Process   "$date" $time $id $pid $oid $data ; }
		O	{ Capture.Message . Object    "$date" $time $id $pid $oid $data ; }
		N	-	n	-
		C	-	c	-
		R	-	r	-
		F	-	f	-
		O	{ Capture.Message . Exception "$date" $time $id $pid $oid $data ; }
	default { Capture.Message . Default  "$date" $time $id $pid $oid $data ; }
	}

	# �ǥХå���å������ؤα���
	Capture.Control . ;
}

# ���������塼���ɣĤμ���
set ExecutorID [gets stdin] ;

# �ᥤ�󥦥���ɥ�����
set exid "[string range $ExecutorID 4 9]"
set title "Debug Message Capture: Executor($exid)" ;
set iname "Executor($exid)" ;
Capture.Window . $title $iname ;

# ��å������Ԥ�
addinput stdin "MainLoop" ;

# End of file: messasge.tcl
