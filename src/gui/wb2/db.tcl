#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a UI for Directory Browser
#

global env db;

set db(test_mode) 0;
set db(debug_mode) 1;
     
source $env(OZROOT)/lib/gui/wb2/if-to-oz.tcl;
#source $env(OZROOT)/lib/gui/wb2/filesel.tcl	
       
# procedures called by OZ++

proc Select {mode} {
  global db;

  if {$mode == "dir"} {
    $db(win).f4.select configure -state normal;
  }

  puts stderr $mode;

  set db(select) $mode;

  set db(selecting) 1;
}
       
proc AddEntries {path entries} {
  global db;
  
  if {$path == ""} {
    set path ":";
  }

  if {$path != [current_path $db(win)]} {
    return;
  }

  set w $db(win);

  set db($w.entry) [lsort [concat $db($w.entry) $entries]];

  foreach i $entries {
    set index [lsearch -exact $db($w.entry) $i];
    $db($w.entryList) insert $index $i;
  }
}

proc Quit {} {
  quit;
}

proc Open {path dirs entries} {
  global db;

  if {$path == ""} {
    set path ":"; 
  }

  set w [change_dir "$path"];

  if {$path != ":"} {
    set db($w.dir) [concat ".." [lsort $dirs]]; 
  } else {
    set db($w.dir) [lsort $dirs]; 
  }
  set db($w.entry) [lsort $entries];

  $w.f0.f1.box delete 0 end;
  $w.f0.f2.box delete 0 end;

  foreach i $db($w.dir) {
    $db($w.dirList) insert end $i;
  }

  foreach i $db($w.entry) {
    $db($w.entryList) insert end $i;
  }
}

proc NewEntry {path name} {
  global db;

  if {$path == ""} {
    set path ":"; 
  }

  set w $db(win);
  
  set db($w.dir) [lsort [concat $db($w.dir) [list $name]]];
  set index [lsearch -exact $db($w.dir) $name];

  $db($w.dirList) insert $index $name;
}

# local procedures 

proc set_ops_state {w state {kind {}}} {
  global db;

  set entries [$db($w.entryList) curselection];
  set dirs [$db($w.dirList) curselection];

  if {$dirs == "" && [llength $entries] > 1} {
    $w.f4.open configure -state disabled;
  } else {
    $w.f4.open configure -state $state;
  }

  set sstate $state;

  if {$db(select) == "dir"} {
    set sstate normal;
  } elseif {$db(select) == "entry"} {
    if {$entries == ""} {
      set sstate disabled;
    }
  } else {
    set sstate disabled;
  } 

  $w.f4.select configure -state $sstate;

  if {$dirs != "" || $entries != ""} {
    $w.f4.del configure -state normal;
  } else {
    $w.f4.del configure -state disabled;
  } 
}

proc insert_name {w name kind} {
  global db;

  lappend db($kind) $name;
  set db($w.$kind) [lsort $db($w.$kind)];

  set index [lsearch -exact $db($w.$kind) "$name"];
  $db($w."$kind"List) insert $index $name;
}

proc current_path {w} {
  return [$w.f3.pathname get];
}

proc rescan {w} {
  set path [current_path $w];

  if {$path == ":"} {
    set path "";
  }

  SendOZ "ChangeDirectory:$path";
}

proc open {w} {
  set index [$w.f0.f1.box curselection];

  if {$index != ""} {
    set name [$w.f0.f1.box get $index];
    set path [current_path $w];

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
    } else {
      append path ":$name";
    }

    SendOZ "ChangeDirectory:$path";
    return;
  }

  preview $w;
}

proc export {w} {
  set index [$w.f0.f2.box curselection];

  set names {}

  foreach i $index {
    lappend names [$w.f0.f2.box get $i];
  }

  SendOZ "Export:[join $names |]";
}

proc preview {w} {
  set index [$w.f0.f2.box curselection];
  set name [$w.f0.f2.box get $index];

  SendOZ "OpenEntry:$name";
}

proc quit {} {
  global db;

  if !$db(quit) {
    set db(quit) 1;
    SendOZ "Quit:";
  } else {
    destroy .;
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
  global db;

  set name "";

  while {$name == ""} {

    if {[set name [input_name_once $w $kind]] == ""} {
      break;
    }
    
    if {[lsearch -exact $db($w.dir) "$name"] > -1 || \
	  [lsearch -exact $db($w.entry) "$name"] > -1} {
      tk_dialog $w.caution "info." "`$name' already used" info 0 "Close";
      set name "";
    }
  }

  return $name;
}

proc input_name_once {w kind} {
  global close;

  set win [toplevel $w.input];

  if {$kind == "entry"} {
    set title "Entry";
  } else {
    set title "Directory";
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

proc change_dir {path} {
  global db;

  if ![info exists db(win)] {
    new_win $path;
  }

  set w $db(win);

  wm title $w "OZ++ `$db(name)' Browser `$path'";
  $w.f3.pathname delete 0 end;
  $w.f3.pathname insert end $path;

  return $w;
}
	
proc new_win {path} {
  global db;

  set db(win) ".s0";
  set w [toplevel $db(win)];

  frame $w.f0;
  frame $w.f0.f1;
  label $w.f0.f1.title -text "Directories" -relief ridge;
  scrollbar $w.f0.f1.sbx -orient horiz -cursor sb_h_double_arrow \
    -command "$w.f0.f1.box xview";
  
  scrollbar $w.f0.f1.sby -command "$w.f0.f1.box yview";
  listbox $w.f0.f1.box -relief flat -exportselection no \
    -xscrollcommand "$w.f0.f1.sbx set" \
      -yscrollcommand "$w.f0.f1.sby set";
  
  bind $w.f0.f1.box <1> "%W select from \[%W nearest %y\]; \
    $w.f0.f2.box select clear; \
    set_ops_state $w normal dir";
  
  bind $w.f0.f1.box <3> "%W select clear; \
    set_ops_state $w disabled dir";
  
  bind $w.f0.f1.box <Double-ButtonPress-1> "$w.f4.open invoke";
  
  bind $w.f0.f1.box <B1-Motion> {
    %W select from [%W nearest %y];
  }
  
  frame $w.f0.f2;
  label $w.f0.f2.title -text "entries" -relief ridge;
  scrollbar $w.f0.f2.sbx -orient horiz -cursor sb_h_double_arrow \
    -command "$w.f0.f2.box xview";
  
  scrollbar $w.f0.f2.sby -command "$w.f0.f2.box yview";
  listbox $w.f0.f2.box -relief flat -exportselection no \
    -xscrollcommand "$w.f0.f2.sbx set" \
      -yscrollcommand "$w.f0.f2.sby set";
  
  bind $w.f0.f2.box <1> "%W select from \[%W nearest %y\]; \
    $w.f0.f1.box select clear; \
    set_ops_state $w normal entry"
  
  bind $w.f0.f2.box <B1-Motion> "%W select to \[%W nearest %y\]; \
    set_ops_state $w normal entry"

  bind $w.f0.f2.box <Double-ButtonPress-1> "$w.f4.open invoke";
  
  bind $w.f0.f2.box <3> "%W select clear; \
    set_ops_state $w disabled entry";
  
  set db($w.dirList) $w.f0.f1.box;
  set db($w.entryList) $w.f0.f2.box;
  
  frame $w.f3 -relief raised -bd 1;
  entry $w.f3.pathname -relief ridge;

  bind $w.f3.pathname <Return> "$w.f5.rescan invoke";

  frame $w.f4 -relief raised -bd 1;
  button $w.f4.open -text "Open" -command "open $w" \
    -relief flat;
  button $w.f4.select -text "Select" -command "select_it $w" \
    -relief flat;
  button $w.f4.del -text "Delete" -command "delete_entry $w" \
    -relief flat;

  frame $w.f5 -relief raised -bd 1;
  button $w.f5.rescan -text "Rescan" -command "rescan $w" \
    -relief flat;
  button $w.f5.new -text "New" -command "new $w" \
    -relief flat;
  button $w.f5.quit -text "Quit" -command "quit" \
    -relief flat;
	  
  proc delete_entry {w} {
    global db;

    if {[set index [$db($w.dirList) curselection]] == ""} {
      set index [$db($w.entryList) curselection];
      set list $db($w.entryList);
    } else {
      set list $db($w.dirList);
    }
    
    set entries {}
    
    foreach i $index {
      lappend entries [$list get $i];
    }

    if {[set path [current_path $w]] == ":"} {
      set path "";
    }

    if {$list == $db($w.entryList)} {
      SendOZ "DeleteEntry:$path|\{$entries\}";
    } else {
      SendOZ "DeleteDirectory:$path|\{$entries\}";
    }

    foreach i [lsort -decreasing $index] {
      $list delete $i;
    }
  }

  set_ops_state $w disabled;
  
  pack $w.f3 -fill x;
  pack $w.f3.pathname -side right -fill x -expand yes; 
  
  pack $w.f0 -fill both;
  pack $w.f0.f1 $w.f0.f2 -side left -fill both -expand yes;
  pack $w.f0.f1.title -fill x;
  pack $w.f0.f1.sby -side right -fill y;
  pack $w.f0.f1.sbx -side bottom -fill x;
  pack $w.f0.f1.box -fill both -expand yes;
  
  pack $w.f0.f2.title -fill x;
  pack $w.f0.f2.sby -side right -fill y;
  pack $w.f0.f2.sbx -side bottom -fill x;
  pack $w.f0.f2.box -fill both -expand yes;

  pack $w.f4 -fill x;
  pack $w.f4.open $w.f4.del $w.f4.select \
    -side left -fill x -expand yes;

  pack $w.f5 -fill x;
  pack $w.f5.rescan $w.f5.new $w.f5.quit \
    -side left -fill x -expand yes;

  set_center $w;
  set_expandable $w;

  return $w;
}

proc select_it {w} {
  global db;

  if {[set path [current_path $w]] == ":"} {
    set path "";
  }

  set p [$w.f0.f1.box curselect];
  set name "";

  if {$p != ""} {
    set dname [$w.f0.f1.box get $p];
    if {$dname == ".."} {
      set index [expr [string last ":" $path] - 1];
      if {$index > 0} {
	set name [string range $path 0 $index];
      } else {
	set name "";
      }
    } else {
      set name "$path:$dname";
    }
  } else {
    if {$db(select) == "entry"} {
      set p [$w.f0.f2.box curselect];

      if {$p != ""} {
	set name [$w.f0.f2.box get $p];
      } 
    } else {
      set name $path;
    }
  }

  if {$db(select) == "entry"} {
    SendOZ "SelectEntry:$name";	
  } else {
      SendOZ "SelectDirectory:$name";	
  }

  if $db(selecting) quit;
}

# main part in this program

global db argc argv;

set db(quit) 0;
set db(select) entry;
set db(selecting) 0;

set i 0;

if {$argc > $i} {
  set db(name) [lindex $argv $i];
  incr i;
}

if {$argc > $i} {
  set db(select) [lindex $argv $i];
  incr i;
}

wm withdraw .;

# test 

if $db(test_mode) {
  Open {:oz++} {test} {collections mng strings etc}
}

if $db(debug_mode) {
  rename SendOZ orig_SendOZ;
  proc SendOZ {str} {
    puts stderr $str;
    orig_SendOZ $str;
  }
}

