#!/usr/local/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	�ǥХå��ե��ȥ���ɡ��桼���ɡ���
#
# �ե�����̾
#	olist.tcl
#
# ��ǽ
#	�����Х륪�֥������Ȥΰ�����ɽ�����롣
#
# ����
#	class	TestListObject, GUI
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

#
#	�Ķ��ѿ��Υ����å�
#
if { [catch { set OZROOT $env(OZROOT) ; }] } {
	puts stderr "olist.tcl: You must be setenv OZROOT" ;
	flush stderr ;
	exit 1 ;
}

#
#	������ʬ�μ�����
#
set path $OZROOT/lib/gui ;
set auto_index(set_expandable) "source $path/wb2/if-to-oz.tcl" ;

#-------------------------------------------------------------------------------
#	OZ++¦�����̿���¹Ԥ���ץ�������
#

proc	OLS.Start { w exid } \
{
	global ExecutorID ;

	# ���������塼���ɣĤμ���
	set ExecutorID $exid ;

	# �ᥤ�󥦥���ɥ�����
	set exid "[string range $ExecutorID 4 9]"
	set title "OZ++ Debugger Object List: Executor($exid)" ;
	set iname "List($exid)" ;
	OLS.Window $w $title $iname ;

	OLS.disabled $w ;
	update ;
	SendOZ "OLS.Update:$w" ;
}

proc	OLS.Update { w } \
{
	OLS.disbled $w ;
	update ;
	SendOZ "OLS.Update:$w" ;
}

proc	OLS.Append { w oid status } \
{
	$w.list.oid insert end $oid ;
	$w.list.status insert end $status ;
	update ;
}

proc	OLS.Normal { w } \
{
	$w.mb.file configure -state normal ;
	$w.mb.update configure -state normal ;
	update ;
}

proc	OLS.Clear { w } \
{
	$w.list.oid delete 0 end ;
	$w.list.status delete 0 end ;
	update ;
}

# Destory window
proc	OLS.Destroy { w } \
{
	destroy $w ;
}

# Tcl/Tk exit
proc	Exit { status } \
{
	exit $status ;
}

# Print status message
proc	OLS.Print { w msg {mode false} } \
{
	if { $mode } {
		set pre [lindex [$w.footer.msg configure -text] 4] ;
		$w.footer.msg configure -text $pre$msg ;
	} else {
		$w.footer.msg configure -text $msg ;
	}
	update ;
}

#
#-------------------------------------------------------------------------------

#
#	�ᥤ�󥦥���ɥ��κ���
#
# w		������ɥ�
# title	������ɥ��Υ����ȥ�
# iname	��������Υ����ȥ�
#
proc	OLS.Window { w title iname } \
{
	global OZROOT ;

	#
	# ������ɥ�����
	#
	catch { destroy $w ; }
	toplevel $w ;
	wm title $w $title ;
	wm iconname $w $iname ;

	#
	# ��˥塼�С��κ���
	#
	frame $w.mb -bd 1 -relief raise ;
	pack $w.mb -side top -fill x;

	# Object List
	set menu $w.mb.file.m ;
	menubutton $w.mb.file -text File -width 10 -menu $menu ;
	menu $menu ;
	pack $w.mb.file -side left ;
	$menu add command -label Suspend -command "OLS.suspend $w" ;
	$menu add command -label Resume -command "OLS.resume $w" ;
	$menu add separator ;
	$menu add command -label Quit -command "OLS.quit $w" ;

	# Update
	button $w.mb.update -text Update -width 10 -relief flat \
		-state disabled -command "OLS.update $w" ;
	pack $w.mb.update -side right ;

	#
	# �ꥹ��ɽ��
	#
	frame $w.list -bd 1 -relief raised ;
	pack $w.list -side top -fill both -expand yes ;
	listbox $w.list.oid -bd 1 -relief sunken \
		-yscroll "$w.list.scrollbar set" ;
	listbox $w.list.status -bd 1 -relief sunken ;
	scrollbar $w.list.scrollbar -bd 1 -relief sunken \
		-command "OLS.scroll {$w.list.oid $w.list.status}" ;
	pack $w.list.oid -side left -fill both -expand yes ;
	pack $w.list.status -side left -fill both ;
	pack $w.list.scrollbar -side right -fill y ;
	tk_listboxSingleSelect $w.list.oid ;
	proc	nop { } { }
	bind $w.list.status <1> nop ;
	bind $w.list.status <2> nop ;
	bind $w.list.status <3> nop ;
	bind $w.list.status <B1-Motion> nop ;
	bind $w.list.status <B2-Motion> nop ;
	bind $w.list.status <B3-Motion> nop ;
	bind $w.list.status <Double-1> nop ;
	bind $w.list.status <Double-2> nop ;
	bind $w.list.status <Double-3> nop ;

	#
	# �եå����κ���
	#
	frame $w.footer -bd 1 -relief raised ;
	pack $w.footer -side bottom -fill x ;
	label $w.footer.msg -bd 1 -relief sunken -anchor nw ;
	pack $w.footer.msg -side left -fill x -expand yes ;

	# ������ɥ���Ĵ��
	set_expandable $w ;

	update ;
}

proc	OLS.quit { w } \
{
	destroy $w ;
	SendOZ "OLS.Quit:$w" ;
}

proc	OLS.scroll { wins pos } \
{
	foreach w $wins {
		$w yview $pos ;
	}
}

proc	OLS.update { w } \
{
	OLS.disabled $w ;
	SendOZ "OLS.Update:$w" ;
}

proc	OLS.suspend { w } \
{
	set i [lindex [$w.list.oid curselection] 0] ;
	if { $i == "" } { return ; }
	set oid [$w.list.oid get $i] ;
	OLS.Print $w "Suspend $oid..." ;
	SendOZ "OLS.Suspend:$w|$oid" ;
}

proc	OLS.resume { w } \
{
	set i [lindex [$w.list.oid curselection] 0] ;
	if { $i == "" } { return ; }
	set oid [$w.list.oid get $i] ;
	OLS.Print $w "Resume $oid..." ;
	SendOZ "OLS.Resume:$w|$oid" ;
}

proc	OLS.disabled { w } \
{
	$w.mb.file configure -state disabled ;
	$w.mb.update configure -state disabled ;
	update ;
}


wm withdraw . ;

# End of file: dfe.tcl
