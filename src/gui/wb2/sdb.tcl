#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a UI for School Directory Browser
#

global env sdb;

set sdb(test_mode) 0;
set sdb(debug_mode) 1;

source $env(OZROOT)/lib/gui/wb2/if-to-oz.tcl
source $env(OZROOT)/lib/gui/wb2/filesel.tcl

# procedures called by OZ++

proc ShowSchools {path schools} {
  global sdb sdbw;

  if {$path == ""} {
    set path ":";
  }

  if ![info exists sdbw($path)] {
    return;
  }

  set w $sdbw($path);

  set sdb($w.school) [lsort [concat $sdb($w.school) $schools]];

  foreach i $schools {
    set index [lsearch -exact $sdb($w.school) $i];
    $sdb($w.schoolList) insert $index $i;
  }
}

proc Quit {} {
  quit;

  close_all;

  destroy .;
}

proc SetCurrent {path} {
  global sdb;

  if {$path == ""} {
    set path ":"; 
  }

  set sdb(current) $path;
}

proc Open {path dirs schools} {
  global sdb sdbw;

  if {$path == ""} {
    set path ":"; 
  }

  set w [new_win "$path"];

  if {$path != ":"} {
    set sdb($w.dir) [concat ".." [lsort $dirs]]; 
  } else {
    set sdb($w.dir) [lsort $dirs]; 
  }
  set sdb($w.school) [lsort $schools];

  $w.f1.box delete 0 end;
  $w.f2.box delete 0 end;

  foreach i $sdb($w.dir) {
    $sdb($w.dirList) insert end $i;
  }

  foreach i $sdb($w.school) {
    $sdb($w.schoolList) insert end $i;
  }
}

proc NewEntry {path name} {
  global sdb sdbw;

  if {$path == ""} {
    set path ":"; 
  }

  set w $sdbw($path);
  
  set sdb($w.dir) [lsort [concat $sdb($w.dir) [list $name]]];
  set index [lsearch -exact $sdb($w.dir) $name];

  $sdb($w.dirList) insert $index $name;
}

# local procedures 

proc set_ops_state {w state {kind {}}} {
  global sdb sdbw

  $w.f3.sdb.m $state "Open";
  if {$kind != "school"} {
    set state disable;
  }
  $w.f3.ops.m $state "Export";
  
  if {[$sdb($w.dirList) curselection] != "" || \
	[$sdb($w.schoolList) curselection] != ""} {
    set state enable;
  } else {
    set state disable;
  }
  
  $w.f3.ops.m $state "Delete";
}

proc insert_name {w name kind} {
  global sdb sdbw;

  lappend sdb($kind) $name;
  set sdb($w.$kind) [lsort $sdb($w.$kind)];

  set index [lsearch -exact $sdb($w.$kind) "$name"];
  $sdb($w."$kind"List) insert $index $name;
}

proc current_path {w} {
  return [lindex [$w.f3.pathname configure -text] 4];
}

proc open {w} {
  set index [$w.f1.box curselection];

  if {$index != ""} {
    set name [$w.f1.box get $index];
    set path [current_path $w];

    if {[info exists sdbw($path)] && [winfo exists $sdbw($path)]} {
      wm deiconify $sdbw($path);
      raise $sdbw($path);
      return;
    }

    if {$path == ":"} {
      set path "";
    }

    if {$name == ".."} {
      set index [expr [string last ":" $path] - 1];
      if {$index > 0} {
	set path [string range $path 0 $index];
      } else {
	set path "";
      }
      set name "";
    }

    SendOZ "ChangeDirectory:$path|$name";
    return;
  }

  set index [$w.f2.box curselection];

  if {$index != ""} {
    set names {}
    foreach i $index {
      lappend names [$w.f2.box get $i];
    }

    set path [current_path $w];
    if {$path == ":"} {
      set path "";
    }

    SendOZ "OpenSchools:$path|[join $names |]";
  }
}

proc export {w} {
  set index [$w.f2.box curselection];

  set names {}

  foreach i $index {
    lappend names [$w.f2.box get $i];
  }

  if {[set path [current_path $w]] == ":"} {
    set path "";
  }

  SendOZ "Export:$path|[join $names |]";
}

proc quit {} {
  global sdb;

  if !$sdb(quit) {
    set sdb(quit) 1;
    SendOZ "Quit:";
  }
}

proc new {w} {
  if {[set dir_name [input_name $w dir]] == ""} {
    return;
  }

  if {[set path [current_path $w]] == ":"} {
    set path "";
  }

  SendOZ "NewDirectory:$path|$dir_name"
}

proc input_name {w kind} {
  global sdb sdbw;

  set name "";

  while {$name == ""} {

    if {[set name [input_name_once $w $kind]] == ""} {
      break;
    }
    
    if {[lsearch -exact $sdb($w.dir) "$name"] > -1 || \
	  [lsearch -exact $sdb($w.school) "$name"] > -1} {
      tk_dialog $w.caution "info." "`$name' already used" info 0 "Close";
      set name "";
    }
  }

  return $name;
}

proc input_name_once {w kind} {
  global close;

  set win [toplevel $w.input];

  if {$kind == "school"} {
    set title "School";
  } else {
    set title "School Directory";
  }

  frame $win.f1 -relief ridge -bd 2;
  label $win.f1.title -text "Please input a `$title' name" \
    -anchor w;
  entry $win.f1.dirName -width 30 -relief ridge;

  mybind $win.f1.dirName <Control-h> \
    "if {\[$win.f1.dirName get\] == \"\"} { $win.f2.f3.done configure -state disabled; }";

  mybind $win.f1.dirName <Any-KeyPress> \
    "$win.f2.f3.done configure -state normal;"

  bind $win.f1.dirName <Return> \
    "$win.f2.f3.done invoke";

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -text "Done" -state disabled -bd 1 \
    -command {
      global close;

      set close done;
    }
  button $win.f2.cancel -text "Cancel" -bd 1 \
    -command {
      global close;

      set close cancel;
    }
  
  pack $win.f1 -fill both -padx 10 -pady 10;
  pack $win.f1.title -fill both -expand yes -padx 3 -pady 3;
  pack $win.f1.dirName -padx 10 -ipady 5 -pady 10 -fill x -expand yes;

  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $win;

  focus $win.f1.dirName;
  tkwait variable close;

  set dir_name [$win.f1.dirName get];

  destroy $win;

  if {$close == "cancel" || $dir_name == ""} {
    return "";
  }

  return $dir_name;
}

proc new_win {path} {
  global sdb sdbw;

  if {[info exists sdbw($path)] && [winfo exists $sdbw($path)]} {
    wm deiconify $sdbw($path);
    raise $sdbw($path);
    return $sdbw($path);
  } else {
    set sdbw($path) .s[incr sdb(win)];
    lappend sdb(allwin) $path;
    set w [toplevel $sdbw($path)];
  }
  
  wm title $w "OZ++ SDB `$path'";

  frame $w.f1;
  label $w.f1.title -text "School Directories" -relief ridge;
  scrollbar $w.f1.sbx -orient horiz -cursor sb_h_double_arrow \
    -command "$w.f1.box xview";
  
  scrollbar $w.f1.sby -command "$w.f1.box yview";
  listbox $w.f1.box -relief flat -exportselection no \
    -xscrollcommand "$w.f1.sbx set" \
      -yscrollcommand "$w.f1.sby set";
  
  bind $w.f1.box <1> "%W select from \[%W nearest %y\]; \
    $w.f2.box select clear; \
    set_ops_state $w enable dir;";
  
  bind $w.f1.box <3> "%W select clear; \
    set_ops_state $w disable dir";
  
  bind $w.f1.box <Double-ButtonPress-1> "$w.f3.sdb.m invoke {Open}";
  
  bind $w.f1.box <B1-Motion> {
    %W select from [%W nearest %y];
  }
  
  frame $w.f2;
  label $w.f2.title -text "Schools" -relief ridge;
  scrollbar $w.f2.sbx -orient horiz -cursor sb_h_double_arrow \
    -command "$w.f2.box xview";
  
  scrollbar $w.f2.sby -command "$w.f2.box yview";
  listbox $w.f2.box -relief flat -exportselection no \
    -xscrollcommand "$w.f2.sbx set" \
      -yscrollcommand "$w.f2.sby set";
  
  bind $w.f2.box <1> "%W select from \[%W nearest %y\]; \
    $w.f1.box select clear; \
    set_ops_state $w enable school; \
    $w.f2.box.m unpost";
  
  bind $w.f2.box <3> "%W select clear; \
    set_ops_state $w disable school; $w.f2.box.m unpost";
  
  menu $w.f2.box.m;
  $w.f2.box.m add command -label "Open" -command "open $w";
  $w.f2.box.m add command -label "Export" -command "export $w";
  
  bind $w.f2.box.m <1> "$w.f2.box.m invoke @%y; $w.f2.box.m unpost";
  
  bind $w.f2.box <Double-ButtonPress-1> "$w.f2.box.m post %X %Y";

  set sdb($w.dirList) $w.f1.box;
  set sdb($w.schoolList) $w.f2.box;
  
  frame $w.f3 -relief raised -bd 1;
  label $w.f3.pathname -text "$path" -anchor e -relief ridge;
  menubutton $w.f3.sdb -text "School directory browser" \
    -anchor w -relief flat -menu $w.f3.sdb.m;
  menu $w.f3.sdb.m;
  $w.f3.sdb.m add command -label "New" -command "new $w";
  $w.f3.sdb.m add command -label "Open" -state disabled -command "open $w";
  $w.f3.sdb.m add command -label "Close" -command "close $w"
  $w.f3.sdb.m add separator;
  $w.f3.sdb.m add command -label "Quit" -command "quit";
  menubutton $w.f3.ops -text "Operation" -anchor w -menu $w.f3.ops.m;
  menu $w.f3.ops.m;
  $w.f3.ops.m add command -label "Set Current" -command "set_current_this $w"
  $w.f3.ops.m add command -label "Delete" -command "delete_entry $w";
  $w.f3.ops.m add separator;
  $w.f3.ops.m add command -label "Export" \
    -state disabled -command "export $w";
  
  proc delete_entry {w} {
    global sdb sdbw;

    if {[set index [$sdb($w.dirList) curselection]] == ""} {
      set index [$sdb($w.schoolList) curselection];
      set list $sdb($w.schoolList);
    } else {
      set list $sdb($w.dirList);
    }
    
    set entries {}
    
    foreach i $index {
      lappend entries [$list get $i];
    }

    if {[set path [current_path $w]] == ":"} {
      set path "";
    }

    if {$list == $sdb($w.schoolList)} {
      SendOZ "DeleteSchool:$path|\{$entries\}";
    } else {
      SendOZ "DeleteDirectory:$path|\{$entries\}";
    }

    foreach i [lsort -decreasing $index] {
      $list delete $i;
    }
  }

  menubutton $w.f3.window -text "Window" -menu $w.f3.window.m;
  menu $w.f3.window.m;
  
  set_ops_state $w disable;
  
  pack $w.f3 -fill x;
  pack $w.f3.sdb $w.f3.ops $w.f3.window -side left -ipadx 5 -fill x; 
  pack $w.f3.pathname -side right -fill x -expand yes; 
  
  pack $w.f1 $w.f2 -side left -fill both -expand yes;
  pack $w.f1.title -fill x;
  pack $w.f1.sby -side right -fill y;
  pack $w.f1.sbx -side bottom -fill x;
  pack $w.f1.box -fill both -expand yes;
  
  pack $w.f2.title -fill x;
  pack $w.f2.sby -side right -fill y;
  pack $w.f2.sbx -side bottom -fill x;
  pack $w.f2.box -fill both -expand yes;

  set_all_windows $w;
  
  set_center $w;
  set_expandable $w;

  return $w;
}

proc delete_from_windows {name} {
  global sdb sdbw;

  foreach i $sdb(allwin) {
    if {$i != $name} {
      $sdbw($i).f3.window.m delete "$name";
    }
  }
}

proc set_all_windows {w} {
  global sdb sdbw;

  set this [current_path $w];

  foreach i $sdb(allwin) {
    if {$i == $this} {
      set state disabled;
    } else {
      set state normal;
    }
    $w.f3.window.m add command -label $i -state $state \
      -command "wm deiconify $sdbw($i); raise $sdbw($i)";
  }

  foreach i $sdb(allwin) {
    if {$i != $this} {
      $sdbw($i).f3.window.m add command -label $this \
	-command "wm deiconify $sdbw($this); raise $sdbw($this)";
    }
  }
}

proc close {w} {
  global sdb sdbw;

  if {[set path [current_path $w]] == ""} {
    set path ":";
  }

  delete_from_windows $path;

  set p [lsearch -exact $sdb(allwin) "$path"];
  set sdb(allwin) [lreplace $sdb(allwin) $p $p];

  unset sdbw($path);

  destroy $w;
}

proc close_all {} {
  global sdb sdbw;

  foreach i $sdb(allwin) {
    close $sdbw($i);
  }
}

proc set_current_this {w} {
  if {[set path [current_path $w]] == ":"} {
    set path "";
  }
  SendOZ "SetCurrent:$path";
}

# main part in this program

global sdb;

set sdb(allwin) {};
set sdb(win) 0;
set sdb(current) "";
set sdb(quit) 0;

wm withdraw .;

# test 

if $sdb(test_mode) {
  Open {:oz++} {test} {collections mng strings etc}
}

if $sdb(debug_mode) {
  rename SendOZ orig_SendOZ;
  proc SendOZ {str} {
    puts stderr $str;
    orig_SendOZ $str;
  }
}

