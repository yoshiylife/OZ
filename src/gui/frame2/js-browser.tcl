#  <<< Junkshop >>>
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#  Browser GUI
#
set JSB(version) 0.2;

set DEBUG 1;

set LIB_DIR	$env(OZROOT)/lib/gui/frame2;
source $LIB_DIR/misc.tcl;

set JSB(delimiter)	":";

set JSB(size.icon)	[expr 32 + 2];  # icon size in bixel
set JSB(size.ncol)	3;   # 1行に何個のiconを並べるか
set JSB(size.wcol)	150; # iconの幅
set JSB(size.hrow)	60;  # iconの高さ
set JSB(size.nhistory)	10;

set JSB(kinds)          {slide screen button field label};
set JSB(icon.dir)	@$LIB_DIR/icon/dir32.xpm;
set JSB(icon.slide)	@$LIB_DIR/icon/slide32.xpm;
set JSB(icon.unknown)	@$LIB_DIR/icon/unknown32.xpm;

set NextID	1;


#######################################################################
#	OZ++ I/F Procedures
#######################################################################


#-----------------------------------------------------------------------
#  print the message in a error dialog.
proc Error {msg} {
    tk_dialog .jsb_error \
	"Junkshop Browser: Error" "$msg" error 0 "OK";
}

#-----------------------------------------------------------------------
proc Exit {} {
    destroy .;
    exit;
}

#-----------------------------------------------------------------------
#  dirs = {name1 name2 ...}
#  ents = {{name1 kind1} {name2 kind2} ...}
proc List {path dirs ents} {
    global  JSB;

    Debug "List $dirs $ents";

    if {"$path" == ""} {
	set path $JSB(delimiter);
    }
    JSB::SetCurrentPath $path;

    set JSB(list.dirs) $dirs;
    set JSB(list.ents) $ents;
    set JSB(list.selected) {};
    JSB::RefreshList;
}


#-----------------------------------------------------------------------
#  type = dir, if needed to select a directory
proc SelectPath {{type "any"}} {
    global  JSB;

    Debug "SelectPath $type";
    wm deiconify .;
    raise .;
    JSB::SelectionClear;

    if {"$JSB(notify.selected)" != "$type"} {
	set JSB(notify.selected) "$type";
    }
}

proc SelectPathXXX {{type "any"}} {
    global  JSB;

    Debug "SelectPath $type";
    wm deiconify .;
    raise .;
    JSB::SelectionClear;
    # trace variable JSB(list.selected) w JSB::CheckSelectedPath;

    if {"$JSB(notify.selected)" != "$type"} {
	set JSB(notify.selected) "$type";
    }
}

########################################################################
#  Private Procedures
########################################################################

#-----------------------------------------------------------------------
proc JSB::ChangeDirectory {path {flag 0}} {
    global  JSB;

    if {$flag} {
	if {"$path" == "root"} {
	    set path ":";
	}
    }
    
    SendOZ "{ChangeDirectory $path}";
}

#-----------------------------------------------------------------------
# 選択されている element が選択したい種類のものか確認する。
#  種類が正しければ、OZ++ に通知、
#   異なれば dialog を出す
#  複数が選択されていたら dialog を出して selection をクリア、
#  選択がなかったら dialog をだして選択をキャンセルするか続けるか確認する
#   キャンセルだったら、"" を OZ++ に送る。
#
proc JSB::CheckSelectedPath {} {
    global  JSB;

    set size [llength $JSB(list.selected)];
    Debug "JSB::CheckSelectedPath - list($size)=$JSB(list.selected)";
    if {$size == 1} {
	set e [lindex $JSB(list.selected) 0];
	set name [lindex $e 0];
	set type [lindex $e 1];
	JSB::SelectionClear;  #--- clear the selection

	if {"$JSB(notify.selected)" == "$type"} {
	    if {"$JSB(path.current)" == ":"} {
		set path "$JSB(delimiter)$name";
	    } else {
		set path "$JSB(path.current)$JSB(delimiter)$name";
	    }

	    #--- ask to user
	    set ans [tk_dialog .jsb_checkselected \
			 "Junkshop Browser: SelectPath" \
			 "You selected ``$path''." \
			 questhead 0 "OK" "Cancel"];
	    if {$ans == 0} {
		JSB::NotifySelectedPath "$path"
		set JSB(notify.selected) "";
	    }

	} else {
	    #--- 要求されている種類と異なるものが選択されている
	    tk_dialog .jsb_checkselected "Junkshop Browser: SelectPath" \
		"Your selection is not a requested type.
Select ``$JSB(notify.selected)''." \
		warning 0 "OK";
	}

    } elseif {$size == 0} {
	    #--- 選択されていない
	set ans [tk_dialog .jsb_checkselected \
		     "Junkshop Browser: SelectPath" \
		     "You have not selected any.
Retry to select ``$JSB(notify.selected)''?" \
		     warning 0 "Retry" "Cancel to select"];
	if {$ans == 1} {
	    JSB::NotifySelectedPath "";
	}
	
    } else {
	tk_dialog .jsb_checkselected "Junkshop Browser: SelectPath" \
	    "Select one element !" \
	    warning 0 "OK";
	JSB::SelectionClear;
    }
}

#-----------------------------------------------------------------------
proc JSB::ConfigListRegion {} {
    global  JSB;

    set width [expr $JSB(size.ncol) * $JSB(size.wcol)];
    set geom [$JSB(win.list.canvas) bbox all];
    if {"$geom" != ""} {
	set height [lindex $geom 3];
    } else {
	set height 0;
    }

    $JSB(win.list.canvas) config -scrollregion "0 0 $width $height";
}

#-----------------------------------------------------------------------
proc JSB::Delete {} {
    global  JSB;

    set elms $JSB(list.selected);
    if {[llength $elms] > 0} {
	set names {};  #--- list of names
	foreach e $elms {
	    lappend names [lindex $e 0];
	}
	set answer [tk_dialog .jsb_delete1 \
			"Junkshop Browser: Delete" \
			"Do you want to delete the following elements ?

$names" \
			questhead 1 "Yes" "No"];
	if {$answer == 0} {
	    SendOZ "{Delete $JSB(path.current) $JSB(list.selected)}";
	}
    } else {
	tk_dialog .jsb_delete2 "Junkshop Browser: Delete" \
	    "No element is selected." \
	    warning 0 "OK";
    }
}

#-----------------------------------------------------------------------
# Select the elements whose names matche the given regular expression.
proc JSB::Find {} {
    global  JSB;

    set pat [GetLine .db_find "Junkshop Browser: Find" "Pattern to find:"];
    if {"$pat" != ""} {
	foreach name $JSB(list.dirs) {
	    if {[regexp -- $pat $name]} {
		JSB::SelectElement $name dir 0;
	    }
	}

	foreach ent $JSB(list.ents) {
	    set name [lindex $ent 0];
	    set type [lindex $ent 1];
	    if {[regexp -- $pat $name]} {
		JSB::SelectElement $name $type 0;
	    }
	}
    }
}

#-----------------------------------------------------------------------
proc JSB::ElementB1Pressed {path name type flag} {
    global  JSB;

#     Debug "JSB::ElementB1Pressed ($type, $path, $name, $flag)";
    JSB::SelectElement $name $type $flag;
}

#-----------------------------------------------------------------------
proc JSB::ElementDoubleB1Pressed {path name type} {
    global  JSB;

    foreach elm $JSB(list.selected) {
	eval {JSB::ElementDeselected} $elm;
    }
    set JSB(list.selected) {};

    if {"$type" == "dir"} {
	if {"$path" == "$JSB(delimiter)"} {
	    set path "";
	}
	JSB::ChangeDirectory $path$JSB(delimiter)$name;
    }
}

#-----------------------------------------------------------------------
proc JSB::ElementDeselected {name type} {
    global  JSB;

    $JSB(win.list.canvas) itemconfig elm_namebox_$name -fill {};
}

#-----------------------------------------------------------------------
proc JSB::ElementSelected {name type} {
    global  JSB;

    $JSB(win.list.canvas) itemconfig elm_namebox_$name -fill gray;
}

#-----------------------------------------------------------------------
proc JSB::Exit {} {
    set answer [tk_dialog .db_exit "Junkshop Browser: Exit" \
		    "Do you really want to exit ?" question 1 "Yes" "No"];
    if {$answer == 0} {
	SendOZ "{Exit}";
	Exit;
    }
}

#-----------------------------------------------------------------------
#  Draw an element (icon and name) on the canvas
proc JSB::MkElement {cvs x y path name type} {
    global  JSB;

    Debug "JSB::MkElement ($cvs, $x, $y, $path, $name, $type)";

    if {[info exists JSB(icon.$type)] == 1} {
	set icon_type $JSB(icon.$type);
    } else {
	set icon_type $JSB(icon.unknown);
    }
    set icon [$cvs create bitmap $x $y -anchor s -bitmap $icon_type];
    set text [$cvs create text $x $y -anchor n -text "$name"];
    set geom [$cvs bbox $text];
    set textbox [eval {$cvs create rect} $geom {-fill {} -outline {}}];
    $cvs lower $textbox;

    $cvs addtag elm_$name          withtag $icon;
    $cvs addtag elm_$name          withtag $text;
    $cvs addtag elm_$name          withtag $textbox;
    $cvs addtag elm_icon_$name     withtag $icon;
    $cvs addtag elm_name_$name     withtag $text;
    $cvs addtag elm_namebox_$name  withtag $textbox;

    $JSB(win.list.canvas) bind elm_$name \
	<1> "JSB::ElementB1Pressed $path $name $type 0"
    $JSB(win.list.canvas) bind elm_$name \
	<Shift-ButtonPress-1> "JSB::ElementB1Pressed $path $name $type 1"
    $JSB(win.list.canvas) bind elm_$name \
	<Double-ButtonPress-1> \
	"JSB::ElementDoubleB1Pressed $path $name $type"
}

#-----------------------------------------------------------------------
proc JSB::NotifySelectedPath {path} {
    SendOZ "{PathSelected $path}";
    set JSB(notify.selected) "";
}

#-----------------------------------------------------------------------
proc JSB::NewDirectory {} {
    global  JSB;

    set new_name [GetLine .db_newdir1 \
		      "Junkshop Browser: NewDirectory" \
		      "Name of new directory:"];
    if {"$new_name" != ""} {
	set idx [lsearch $JSB(list.dirs) $new_name];
	if {$idx == -1} {
	    foreach e $JSB(list.ents) {
		set name [lindex $e 0];
		if {"$new_name" == "$name"} {
		    set idx 0;
		    break;
		}
	    }
	}

	if {$idx == -1} {
	    SendOZ "{NewDirectory $JSB(path.current) $new_name}";
	} else {
	    #--- the name already exists
	    tk_dialog .db_newdir2 \
		"Junkshop Browser: NewDirectory" \
		"Name ``$new_name'' already used." \
		warning 0 "OK";
	}
    }
}

#-----------------------------------------------------------------------
proc JSB::PathEntryReturnEntered {} {
    global  JSB;

    set path [$JSB(win.path.current) get];
    set prev [lindex $JSB(path.history) 0];
    if {"$path" != "" && "$path" != "$prev"} {
	JSB::ChangeDirectory $path;
    }

    $JSB(win.path.current) select clear;
    focus none;
}

#-----------------------------------------------------------------------
#  clear the canvas, sort directory and entry lists, and
#  draw them on the canvas.
proc JSB::RefreshList {} {
    global  JSB;

    set path $JSB(path.current);

    #--- clear the canvas
    $JSB(win.list.canvas) delete all;
    set row 0;

    #--- sort the names in alphabetical order
    set JSB(list.dirs) [lsort $JSB(list.dirs)];
    set num [llength $JSB(list.dirs)];
    set col 0;
    for {set idx 0} {$idx < $num} {} {
	for {set col 0} {$col < $JSB(size.ncol) && $idx < $num} {incr col; incr idx} {
	    set name [lindex $JSB(list.dirs) $idx];
	    set x [expr ($col + 0.5) * $JSB(size.wcol) ];
	    set y [expr $row * $JSB(size.hrow) + $JSB(size.icon)];
	    JSB::MkElement $JSB(win.list.canvas) $x $y $path $name dir;
	}
	if {$col == $JSB(size.ncol)} {
	    incr row;
	}
    }
    if {$col == $JSB(size.ncol)} {
	set col 0;
    }

    set JSB(list.ents) [lsort $JSB(list.ents)];
    set num [llength $JSB(list.ents)];
    for {set idx 0} {$idx < $num} {} {
	for {} {$col < $JSB(size.ncol) && $idx < $num} {incr col; incr idx} {
	    set elm [lindex $JSB(list.ents) $idx];
	    set name [lindex $elm 0];
	    set type [lindex $elm 1];
	    set x [expr ($col + 0.5) * $JSB(size.wcol) ];
	    set y [expr $row * $JSB(size.hrow) + $JSB(size.icon)];
	    JSB::MkElement $JSB(win.list.canvas) $x $y $path $name $type;
	}
	set col 0;
	incr row;
    }

    foreach e $JSB(list.selected) {
	set name [lindex $e 0];
	set type [lindex $e 1];
	JSB::ElementSelected $name $type;
    }

    JSB::ConfigListRegion;
}

#-----------------------------------------------------------------------
proc JSB::Rename {} {
    global  JSB;

    set len [llength $JSB(list.selected)];
    if {$len == 1} {
	set elm [lindex $JSB(list.selected) 0];
	set type [lindex $elm 1];
	set old_name [lindex $elm 0];
	set new_name [GetLine .db_rename1 \
			  "Junkshop Browser: Rename" \
			  "New name of $type ``$old_name'':"];
	if {"$old_name" != "$new_name" && "$new_name" != ""} {
	    set answer [tk_dialog .db_rename2 \
			    "Junkshop Browser: Rename" \
			    "Do you want to rename ?

``$old_name''  to  ``$new_name''" \
			    questhead 1 "Yes" "No"];
	    if {$answer == 0} {
		SendOZ "{Rename $JSB(path.current) $old_name $new_name}";
	    }
	}

    } elseif {$len > 1} {
	tk_dialog .db_rename3 "Junkshop Browser: Rename" \
	    "Multiple elements are selected.
Select one at a time !" \
	    warning 0 "OK";
    } else {
	tk_dialog .db_rename4 "Junkshop Browser: Rename" \
	    "No element is selected." \
	    warning 0 "OK";
    }
}

#-----------------------------------------------------------------------
#  Select the element if it is not selected, otherwise (i.e. selected),
# it is deselected.
#
#   flag = 1, additional selection, i.e. appended to the current list
#          0, exclusive selection
proc JSB::SelectElement {name type flag} {
    global  JSB;

    set idx [lsearch $JSB(list.selected) "$name $type"];
    if {"$idx" == -1} {
	if {!$flag} {
	    #--- de-select the elements in the current list
	    foreach elm $JSB(list.selected) {
		eval {JSB::ElementDeselected} $elm;
	    }
	    set JSB(list.selected) {};
	}
	lappend JSB(list.selected) "$name $type";
	JSB::ElementSelected $name $type;
    } else {
	set JSB(list.selected) [lreplace $JSB(list.selected) $idx $idx];
	JSB::ElementDeselected $name $type;
    }
}

#-----------------------------------------------------------------------
proc JSB::SelectionClear {} {
    global  JSB;

    foreach ent $JSB(list.selected) {
	set name [lindex $ent 0];
	set type [lindex $ent 1];
	JSB::SelectElement $name $type 0;
    }
}

#-----------------------------------------------------------------------
proc JSB::SetCurrentPath {path} {
    global  JSB;

    $JSB(win.path.current) delete 0 end;
    $JSB(win.path.current) insert 0 "$path";

    set JSB(path.current) "$path";
}





########################################################################
########################################################################
########################################################################
########################################################################
########################################################################

proc AddList {path dirs ents} {
	global	JSB;

	if {"$path" == ""} {
		set parent $JSB(delimiter);
	} else {
		set parent $path;
	}
	if {"$parent" == "$JSB(path.current)"} {
		eval {lappend JSB(list.dirs)} $dirs;
		eval {lappend JSB(list.ents)} $ents;
		JSB::RefreshList;
	}
}


proc ClientIsReady {} {
	global	JSB;

	#--- [Trading]
	set f $JSB(win.menu);
	set mb_t [menubutton $f.trading -text "Trading" \
	  -menu $f.trading.menu -bd 1];
	set menu_t [menu $f.trading.menu -bd 1];
	$menu_t add command -label "Export to Client";
	$menu_t add command -label "Import to Junkshop";

	pack $mb_t -side left -padx 2;
}

proc SetDelimiter {c} {
    global  JSB;

    set JSB(delimiter) $c;
}


#######################################################################
#	Internal Procedures
#######################################################################

#	flag = 0, if path is a directory path.
#	flag = 1, if path is special word "back", "root", or ...
#-----------------------------------------------------------------------
proc JSB::OzChangeDirectoryXXX {path {flag 0}} {
    global  JSB;

    if {$flag} {
	if {"$path" == "back"} {
	    set len [llength $JSB(path.history)];
	    if {$len < 2} {
		return;
	    }
	    set path [lindex $JSB(path.history) [expr $len - 2]];
	    if {"$path" == "$JSB(delimiter)"} {
		set path "";
	    }
	} elseif {"$path" == "root"} {
	    set path "";
	}
    }
    SendOZ "{ChangeDirectory $path}";
}


########################################################################
#	Drawing
########################################################################


proc JSB::UpdateHistory {path} {
    global  JSB;

    lappend JSB(path.history) $path;
    if {[llength $JSB(path.history)] > $JSB(size.nhistory)} {
	set removed [lindex $JSB(path.history) 0];
	$JSB(win.menu.go) delete $removed;
	set JSB(path.history) [lreplace $JSB(path.history) 0 0];
    }
    $JSB(win.menu.go) add command -label "$path";
}




########################################################################
#	Event Handling
########################################################################


########################################################################
#	Misc.
########################################################################

#-----------------------------------------------------------------------
proc JSB::MkAncestorList {path} {
	global	JSB;

	set list $JSB(delimiter);
	set len [string length $path];
	for {set i [expr $len - 1]} {$i > 2} {incr i -1} {
		if {"[string index $path $i]" == "$JSB(delimiter)"} {
			lappend list [string range $path 0 [expr $i - 1]];
		}
	}

	return $list;
}


#######################################################################
#	Initialization Procedures
#######################################################################


#-----------------------------------------------------------------------
proc JSB::MkMenuWindow {win} {
    global  JSB;

    set f [frame $win -relief raised -bd 1];

    #--- [System]
    set mb_s [menubutton $f.system -text "System" \
		  -menu $f.system.menu -bd 1];
    set menu_s [menu $f.system.menu -bd 1];
    $menu_s add command -label "Close" -command "wm iconify .";
    $menu_s add separator;
    $menu_s add command -label "Exit" -command "JSB::Exit";

    #--- [Edit]
    set mb_e [menubutton $f.edit -text "Edit" -menu $f.edit.menu -bd 1];
    set menu_e [menu $f.edit.menu -bd 1];
    $menu_e add command -label "Rename...(*)" -command "JSB::Rename";
    $menu_e add command -label "Delete..." -command "JSB::Delete";
    $menu_e add separator;
    $menu_e add command -label "New Directory..." \
	-command "JSB::NewDirectory";
    $menu_e add separator;
    $menu_e add command -label "Find..." -command "JSB::Find";
    $menu_e add command -label "Selection Clear" \
	-command "JSB::SelectionClear";

    #--- [Go]
    set mb_g [menubutton $f.go -text "Go" -menu $f.go.menu -bd 1];
    set menu_g [menu $f.go.menu -bd 1];
    $menu_g add command -label "Root" \
	-command "JSB::ChangeDirectory root 1";
    $menu_g add command -label "Back" \
	-command "JSB::ChangeDirectory back 1" -state disabled;
    $menu_g add separator;
    set JSB(win.menu.go) $menu_g;
    # $mb_g config -state disabled;   # not debugged !

    #--- selected
    set mb_select [button $f.selected -text "Select" \
		   -command "JSB::CheckSelectedPath" -bd 0];

    pack $mb_s $mb_e $mb_g $mb_select -side left -padx 2;
    tk_menuBar $f $mb_s $mb_e $mb_g;

    return $f;
}

proc JSB::MkControlWindow {win} {
	global	JSB;

	set f [frame $win -relief raised -bd 1];
	return $f;
}

#-----------------------------------------------------------------------
proc JSB::MkPathWindow {win} {
    global  JSB;

    set f [frame $win -relief raised -bd 1];
    set f_label [label $f.l -text "Path:"];
    set f_entry [entry $f.e -relief sunken -bd 2];
    set JSB(win.path.current) $f_entry;

    bind $f_entry <Return> "JSB::PathEntryReturnEntered";

    pack $f_label -side left;
    pack $f_entry -side left -fill x -expand 1 -padx 4 -pady 4 -ipady 2;

    return $f;
}

#-----------------------------------------------------------------------
proc JSB::MkListWindow {win width height} {
    global  JSB;
    
    set f [frame $win -relief raised -bd 1];
    set vs [scrollbar $f.vs -relief sunken -orient vertical \
		-command "$f.c yview"];
    set c [canvas $f.c -width $width -height $height \
	       -yscrollcommand "$vs set" -scrollregion "0 0 $width $height" \
	       -relief sunken -bd 2];
    set JSB(win.list.canvas) $c;

    pack $vs -side right -fill y -pady 2;
    pack $c;

    return $f;
}

#-----------------------------------------------------------------------
proc JSB::SetOptions {} {
#	option add *Font -misc-fixed-bold-r-normal--14-*-*-*-*-*-iso8859-1;
	option add *Label.Font \
	  -misc-fixed-bold-r-normal--14-*-*-*-*-*-iso8859-1;
	option add *foreground			White;
	option add *background			#8C8CBF;
	option add *activeBackground		Pink;
	option add *activeForeground		LightYellow;
	option add *Menu.background		White;
	option add *Menu.foreground		Black;
	option add *Menu.activeForeground	Black;
	option add *Entry.background		#6C6C9F;
	option add *Entry.insertBackground	Pink;
	option add *Canvas.background		White;
	option add *Scrollbar.background	#6C6C9F;
	option add *Scrollbar.foreground	LightYellow;
	option add *Scrollbar.activeForeground	Pink;
}

#-----------------------------------------------------------------------
proc JSB::Init {} {
    global  JSB;

    wm title . "OZ++ Junkshop Browser ($JSB(version))";
    wm iconname . "OZ++ Junkshop Browser";

    set JSB(path.history) {};

    #--- define under-toplevel window names
    set JSB(win.menu) .menu;
    set JSB(win.path) .path;
    set JSB(win.list) .list;

    #--- create under-toplevel windows
    JSB::MkMenuWindow $JSB(win.menu);
    JSB::MkPathWindow $JSB(win.path);

    set width [expr $JSB(size.ncol) * $JSB(size.wcol)];
    set height [expr $JSB(size.hrow) * 3];
    JSB::MkListWindow $JSB(win.list) $width $height;

    pack $JSB(win.menu) $JSB(win.path) $JSB(win.list) -side top -fill x;

    set JSB(list.dirs)     {};
    set JSB(list.ents)     {};
    set JSB(list.selected) {};
    set JSB(path.current)  "";
    set JSB(notify.selected) "";
}


#######################################################################
#	Main
#######################################################################

JSB::SetOptions;

#--- Init. toplevel
JSB::Init;


# EoF
