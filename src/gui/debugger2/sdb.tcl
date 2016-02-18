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
#		��������ǥ��쥯�ȥ�֥饦��
#
# �ե�����̾
#	sdb.tcl
#
# ��ǽ
#	��������ǥ��쥯�ȥ��֥饦������������������򤹤롣
#	dfe.tcl �������ळ�Ȥ�����Ȥ��롣
#
# ����
#	class	DebuggerFrontendLaunchable, GUI
#

#
# �ٹ�
#	���Υե�����ϡ����֥��ȥåפ������ϡ��ɥ��֤����ǵ��Ҥ���Ƥ��롣
#

#
# �����Х��ѿ�
#
global School ;
set School "" ;		# DFE �ȤΣɡ���

#-------------------------------------------------------------------------------
#	OZ++¦�����̿���¹Ԥ���ץ�������
#

#	Create window
proc	SDB.Main { w } \
{
#puts stderr "SDB.Main w=$w" ;
	global School ;

	# �����������򥦥���ɥ�����
	SDB.window $w ;
	$w.footer.dismiss configure -state disabled ;

	set School "" ;
}

#	Update list of current work directory
proc	SDB.Update args \
{
#puts stderr "SDB.Update args=$args" ;
	set w [lindex $args 0] ;
	set cwd [lindex $args 1] ;
	$w.cwd.path delete 0 end ;
	$w.cwd.path insert end $cwd ;
	if { [llength $args] > 2 } {
		$w.dirs.listbox delete 0 end ;
		if { $cwd != ":" } {
			$w.dirs.listbox insert end : ;
		}
		foreach e [lrange $args 2 end] {
			$w.dirs.listbox insert end $e ;
		}
	}
	$w.footer.dismiss configure -state normal ;
	update ;
}

#
#-------------------------------------------------------------------------------

#
#	�ᥤ�󥦥���ɥ��κ���
#
# w		������ɥ�
#
proc	SDB.window { w } \
{
	global OZROOT ;

	#
	# ������ɥ�����
	#
	catch { destroy $w ; }
	toplevel $w ;

	set title "School Directory" ;
	set iname "School Directory" ;
	wm title $w $title ;
	wm iconname $w $iname ;
	set pg [winfo geometry [winfo parent $w]] ;
	wm geometry $w [string trimleft $pg 0123456789x] ;

	# ʪ����������ǥ��쥯�ȥ�ΣϣɣĤȥ�������ǥ��쥯�ȥ�θ��ߤΥѥ�
	frame $w.cwd ;
	entry $w.cwd.path -relief sunken ;
	pack $w.cwd -side top -fill x ;
	pack $w.cwd.path -side top -fill x -expand yes ;
	
	# ��������ǥ��쥯�ȥ������
	frame $w.dirs -bd 1 -relief raised ;
	pack $w.dirs -side top -fill both -expand yes ;
	listbox $w.dirs.listbox -bd 1 -relief sunken \
		-yscroll "$w.dirs.scrollbar set" ;
	scrollbar $w.dirs.scrollbar -bd 1 -relief sunken \
		-command "$w.dirs.listbox yview" ;
	pack $w.dirs.listbox -side left -fill both -expand yes ;
	pack $w.dirs.scrollbar -side right -fill y ;
	tk_listboxSingleSelect $w.dirs.listbox ;

	#
	# �եå����κ���
	#
	frame $w.footer ;
	pack $w.footer -side bottom -fill x ;
	button $w.footer.dismiss -text Dismiss -command "destroy $w" ;
	pack $w.footer.dismiss -side top ;

	# ������ɥ���Ĵ��
	set_expandable $w ;

	# ���٥��ư������
	bind $w.cwd.path <Return> "SDB.chdir $w %W" ;
	bind $w.dirs.listbox <Double-1> \
		"SDB.select $w %W" ;

}

proc	SDB.chdir { w field } \
{
	set path [$field get] ;
	if { $path != "" } {
		SendOZ "SDB.Chdir:$w|$path" ;
	}
}

proc	SDB.select { w field } \
{
	global School ;

	set index [lindex [$field curselection] 0] ;
	if { $index != "" } {
		set name [$field get $index] ;
		if { $name == ":" } {
			# change to parent
			SendOZ "SDB.Chdir:$w" ;
		} elseif { [string first : $name] < 0 } {
			# selected school
			set path [string trimright [$w.cwd.path get] :]:$name ;
			set School $path ;
			destroy $w ;
		} else {
			# change to child
			SendOZ "SDB.Chdir:$w|$name" ;
		}
	}
}

# End of file: sdb.tcl
