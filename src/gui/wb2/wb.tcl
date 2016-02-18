#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# OZ++ Workbench
#

global env wb;

source $env(OZROOT)/lib/gui/wb2/if-to-oz.tcl
#source $env(OZROOT)/lib/gui/wb2/mylist.tcl
source $env(OZROOT)/lib/gui/wb2/filesel.tcl
source $env(OZROOT)/lib/gui/wb2/wb-lib.tcl

source $env(OZROOT)/lib/gui/wb2/config.tcl

source $env(OZROOT)/lib/gui/wb2/cfe.tcl
source $env(OZROOT)/lib/gui/wb2/sb.tcl
source $env(OZROOT)/lib/gui/wb2/cb.tcl

set wb(debug_mode) 1;

# Global functions

proc OpenSchools {path school_names files} {
  global sb;

  set j 0;
  foreach i $school_names {
    set i "$path:$i";
    OpenSB $i [lindex $files $j] 1;
    incr j;
  }
}

proc SetCurrent {school_name} {
  global wb wbw;

  if {$wb(current) != ""} {
    if {[set p [lsearch -exact $wb(all) "$wb(current)"]] >= 0} {
      $wbw(WB).f2.srcs delete $p;
      $wbw(WB).f2.srcs insert $p "$wb(current)";
    }
  }

  set wb(current) $school_name;

  set p [lsearch -exact $wb(all) $wb(current)];
  $wbw(WB).f2.srcs delete $p;
  $wbw(WB).f2.srcs insert $p "$wb(current) Current";

  wb_set_ops_state $wbw(WB);
}

proc Register {schools files} {
  global wb wbw;

  set j 0;
  foreach i $schools {
    if {[lsearch -exact $wb(all) $i] >= 0} continue;

    set wb(all) [lsort [lappend wb(all) "$i"]];
    $wbw(WB).f2.srcs insert [lsearch -exact $wb(all) "$i"] "$i";
    set wb(schools:$i) "[lindex $files $j]";
    incr j
  }
}

proc Quit {} {
  global wb;

  set wb(quit_from_oz) 1;

  quit;

  wb_close_all;
}

# Local functions

proc wb_unregister {schools} {
  global wb wbw;

  foreach i $schools {
    set index [lsearch -exact $wb(all) $i];
    set wb(all) [lreplace $wb(all) $index $index];
    $wbw(WB).f2.srcs delete $index;
  }
}

proc wb_set_ops_state {w} {
  global wb label;

  if $wb(boot) return;

  if {[$w.f2.srcs curselect] == ""} {
    set state disable;
  } else {
    set state enable;
  }

  $w.f3.ops.m $state "$label(Delete)";
  $w.f3.ops.m $state "$label(Rename...)";
  $w.f3.ops.m $state "$label(Duplicate...)";
  $w.f3.ops.m $state "$label(Export)";
  $w.f3.ops.m $state "$label(Current)";
  $w.f3.ops.m $state "$label(Export to Launcher)";

  if {$wb(current) != ""} {
    set state enable;
  } 

  $w.f3.wb.m $state "$label(CFE...)";
  $w.f3.wb.m $state "$label(SB...)";
}

proc wb_set_all_state {w state {grab {}}} {
  global wb;
  
  foreach i $wb(allcommands) {
    $w.f3.$i configure -state $state;
  }
  
  if {$grab != ""} {
    grab set $grab;
    catch {$w.f2.srcs configure -cursor watch};
  } else {
    grab release [grab current];
    catch {$w.f2.srcs configure -cursor top_left_arrow};
  }
}

proc wb_get_selected_school_names {w} {
  global wb;

  set names {}

  if {[set index [$w.f2.srcs curselect]] != ""} {
    foreach i $index {
      lappend names [lindex $wb(all) $i];
    }
  }

  return $names;
}

proc wb_delete {w} {
  global wb;

  set schools {};

  foreach i [wb_get_selected_school_names $w] {
    if ![info exist wb(cfed:$i)] {
      lappend schools $i;
      
      $w.f2.srcs delete [set p [lsearch -exact $wb(all) "$i"]];
      set wb(all) [lreplace $wb(all) $p $p];
    }
  }

  SendOZ "Unregister:[join $schools |]";

  wb_set_ops_state $w;
}

proc wb_input_school_name {w} {
  global wb;
  
  set school_name "";

  while {$school_name == ""} {
    if {[set school_name [wb_input_school_name_once $w]] == ""} {
      break;
    }

    if {[lsearch -exact $wb(all) "$school_name"] > -1} {
      tk_dialog $w.caution "info." \
	"`$school_name' already used" info 0 "Close";
      set school_name "";
    }
  }
  return $school_name;
}

proc wb_input_school_name_once {w} {
  global close;

  wb_set_all_state $w disabled;

  set win [toplevel $w.input];

  wm title $win "Input a name of school...";

  frame $win.f1 -relief ridge -bd 2;
  label $win.f1.title -textvariable "label(input school)" -anchor w;
  entry $win.f1.schoolName -width 30 -relief ridge;

  mybind $win.f1.schoolName <Control-h> \
    "if {\[$win.f1.schoolName get\] == \"\"} { $win.f2.f3.done configure -state disabled; }";

  mybind $win.f1.schoolName <BackSpace> \
    "if {\[$win.f1.schoolName get\] == \"\"} { $win.f2.f3.done configure -state disabled; }";

  mybind $win.f1.schoolName <Any-KeyPress> \
    "$win.f2.f3.done configure -state normal;"

  bind $win.f1.schoolName <Return> \
    "$win.f2.f3.done invoke";

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -textvariable "label(Done)" -state disabled -bd 1 \
    -command {
      global close;
      
      set close done;
    }
  button $win.f2.cancel -textvariable "label(Cancel)" -bd 1 \
    -command {
      global close;
      
      set close cancel;
    }
  
  pack $win.f1 -fill both -padx 10 -pady 10;
  pack $win.f1.title -fill both -expand yes -padx 3 -pady 3;
  pack $win.f1.schoolName -padx 10 -pady 10 -fill x -expand yes -ipady 5;

  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $win;

  focus $win.f1.schoolName;
  tkwait variable close;

  set school_name [$win.f1.schoolName get];

  destroy $win;

  wb_set_all_state $w normal;

  if {$close == "cancel"} {
    return "";
  } 

  return $school_name;
}

proc wb_new {w} {
  if {[set school_name [wb_input_school_name $w]] == ""} {
    return;
  }
  
  SendOZ "NewSchool:$school_name";
}

proc wb_convert_school {name school_name} {
  SendOZ "ConvertSchool:$name|$school_name";
}

proc wb_new_from {w} {
  global env fs;

  if {[set school_name [wb_input_school_name $w]] == ""} {
    return;
  }

  wb_set_all_state $w disabled;
  if [info exists fs(dir)] {
    set buf $fs(dir);
    unset fs(dir);
  }
  my_file_selector $w.fsel wb_convert_school "$school_name" \
    "$env(OZROOT)/etc" file "boot-school*"; 
  tkwait window $w.fsel
  if [info exists buf] {
    set fs(dir) $buf;
  } else {
    unset fs(dir);
  }
  wb_set_all_state $w normal;
}

proc wb_export2launcher {w} {
  global wb env;

  SendOZ "GetFileName:$w|WB|[wb_get_selected_school_names $w]";

  tkwait variable wb(result:$w);

#  puts_for_debug $wb(result:$w);

  if ![file exists $env(OZROOT)/etc/boot-school.orig] {
    exec mv $env(OZROOT)/etc/boot-school $env(OZROOT)/etc/boot-school.orig;
  }
  exec cp $env(OZROOT)/$wb(result:$w) $env(OZROOT)/etc/boot-school;
}

proc wb_rename_school {w} {
  foreach i [wb_get_selected_school_names $w] {
    if {[set school_name [wb_input_school_name $w]] == ""} {
      continue;
    }

    wb_unregister "\{$i\}";
    
    SendOZ "RenameSchool:$i|$school_name";
  }
}

proc wb_duplicate {w} {
  foreach i [wb_get_selected_school_names $w] {
    if {[set school_name [wb_input_school_name $w]] == ""} {
      continue;
    }
    
    SendOZ "DuplicateSchool:$i|$school_name";
  }
}

proc wb_select {w} {
  global label wb;

  $w.f3.ops.m disable "$label(Select)";
  $w.f3.ops.m disable "$label(Cancel)";

  set wb(select) [wb_get_selected_school_names $w];
}

proc wb_cancel {w} {
  global label;

  $w.f3.ops.m disable "$label(Select)";
  $w.f3.ops.m disable "$label(Cancel)";
}

proc wb_current {w} {
  set school_name [wb_get_selected_school_names $w];
  SendOZ "SetCurrent:$school_name";
  SetCurrent $school_name;
}

proc wb_export {w} {
  SendOZ "Export:[join [wb_get_selected_school_names $w] |]";
}

proc wb_open_tools {w kind} {
  global wb env;

  if {$kind == "CB"} {
    SendOZ "LaunchCB:";
    return;
  }

  set schools [wb_get_selected_school_names $w];

  if {$schools == ""} {
    set schools "$wb(current)";
  }

  if !$wb(boot) {
    foreach i $schools {
#      puts_for_debug "$i $wb(schools:$i)";
      Open$kind "$i" $wb(schools:$i);
    }
  } else {
    Open$kind "$schools" $schools;
  }
}

proc wb_create {} {
  global wb wbw label env wbk;

  if [info exists wbw(WB)] {
    set win $wbw(WB)
    wm deiconify $win;
    raise $win;
    return;

  } else {
    set wbw(WB) .s[incr wb(win)];
    lappend wb(allwin) "WB";
    set w [toplevel $wbw(WB)];
    set wbk($w) "WB";
  }

  wm title $w "$wb(title:WB)";

  frame $w.f3 -relief raised -bd 1;
  menubutton $w.f3.wb -textvariable "label(WB)" -menu $w.f3.wb.m;
  menu $w.f3.wb.m;

  proc wb_wb_menu {w} {
    global label wb;

    delete_menu $w.f3.wb.m;

    $w.f3.wb.m add command -label "$label(CFE...)" \
      -command "wb_open_tools $w CFE";
    $w.f3.wb.m add command -label "$label(SB...)" \
      -command "wb_open_tools $w SB";
    if {$wb(boot) < 2} {
      $w.f3.wb.m add command -label "$label(CB...)" \
	-command "wb_open_tools $w CB";
    }
    $w.f3.wb.m add separator;
    $w.f3.wb.m add command -label "$label(Preference...)" \
      -command "preference $w";
    $w.f3.wb.m add separator;
    $w.f3.wb.m add command -label "$label(Quit)" -command "quit";
  }

  wb_wb_menu $w;

  menubutton $w.f3.ops -textvariable "label(Ops)" -menu $w.f3.ops.m;
  menu $w.f3.ops.m;

  proc wb_ops_menu {w} {
    global label;

    delete_menu $w.f3.ops.m;

    $w.f3.ops.m add command -label "$label(Select)" -command "wb_select $w" \
      -state disabled;
    $w.f3.ops.m add command -label "$label(Cancel)" -command "wb_cancel $w" \
      -state disabled;
    $w.f3.ops.m add separator;
    $w.f3.ops.m add command -label "$label(Current)" -command "wb_current $w";
    $w.f3.ops.m add command -label "$label(Export)" -command "wb_export $w";
    $w.f3.ops.m add separator;
    $w.f3.ops.m add command -label "$label(Delete)" -command "wb_delete $w";
    $w.f3.ops.m add command -label "$label(Rename...)" \
      -command "wb_rename_school $w";
    $w.f3.ops.m add command -label "$label(Duplicate...)" \
      -command "wb_duplicate $w";
    $w.f3.ops.m add separator;
    $w.f3.ops.m add command -label "$label(New...)" -command "wb_new $w";
    $w.f3.ops.m add command -label "$label(New from a file...)" \
      -command "wb_new_from $w";
    $w.f3.ops.m add separator;
    $w.f3.ops.m add command -label "$label(Export to Launcher)" \
      -command "wb_export2launcher $w";
  }

  wb_ops_menu $w;

  menubutton $w.f3.window -textvariable "label(Window)" -menu $w.f3.window.m;
  menu $w.f3.window.m;

  tk_menuBar $w.f3 $w.f3.wb $w.f3.window;
  focus $w.f3;

  if $wb(boot) {
    set wb(allcommands) {wb ops window}
    $w.f3.ops configure -state disabled;
  } else {
    set wb(allcommands) {wb window}
  }

  frame $w.f2;
  scrollbar $w.f2.sbx -orient horiz -cursor sb_h_double_arrow \
    -command "$w.f2.srcs xview" -relief sunken -bd 1;
  scrollbar $w.f2.sby -command "$w.f2.srcs yview" -relief sunken -bd 1;
  listbox $w.f2.srcs -geometry 40x15 -exportselection no \
    -xscrollcommand "$w.f2.sbx set" \
      -yscrollcommand "$w.f2.sby set";
  
  menu $w.f2.srcs.m;

  proc wb_srcs_menu {w} {
    global label;

    delete_menu $w.f2.srcs.m;

    $w.f2.srcs.m add command -label "$label(CFE...)" \
      -command "wb_open_tools $w CFE";
    $w.f2.srcs.m add command -label "$label(SB...)" \
      -command "wb_open_tools $w SB";
  }

  wb_srcs_menu $w;
  
  bind $w.f2.srcs.m <ButtonRelease-1> "%W unpost; tk_invokeMenu %W";
  bind $w.f2.srcs.m <3> "%W unpost";

  bind $w.f2.srcs <Double-ButtonPress-1> "$w.f2.srcs.m post %X %Y";

  bind $w.f2.srcs <1> \
    "%W select from \[%W nearest %y\];\
    $w.f2.srcs.m unpost;\
    wb_set_ops_state $w";

  mybind $w.f2.srcs <B1-Motion> \
    "if {\[llength \[%W curselect\]\] == 1} {\
      $w.f3.ops.m enable \"$label(Current)\";\
     } else {\
      $w.f3.ops.m disable \"$label(Current)\";\
     }";

  bind $w.f2.srcs <3> \
    "$w.f2.srcs.m unpost;\
      %W select clear;\
      wb_set_ops_state $w";

  pack $w.f3 -fill x;
  pack $w.f3.wb $w.f3.ops $w.f3.window -side left -ipadx 5 -ipady 3;

  pack $w.f2 -side left -fill both -expand yes;
  pack $w.f2.sbx -side bottom -fill x;
  pack $w.f2.sby -side right -fill y;
  pack $w.f2.srcs -side top -fill both -expand yes;

  wb_set_ops_state $w;

  set_center $w;

  set_all_windows $w "Workbench";
  
  update idletasks;
}

# Main part

wm withdraw .;

global wb argc argv;
				     
set wb(all) {}
set wb(win) 0;
set wb(allwin) {};
set wb(alltitle) {};
set wb(class) "";
set wb(boot-path) "lib/boot-class";
set wb(path) "";
set wb(current) "";
set wb(boot) 2;
set wb(lang) "english";
set wb(pwd) [pwd];
set wb(cfed) "$env(OZROOT)/bin/cfed -at";
set wb(quit) 0;
     
set wb(title:WB) "OZ++ Workbench";

set wb(kind:0) "class";
set wb(kind:5) "shared";
set wb(kind:6) "static class";
set wb(kind:7) "record";
set wb(kind:8) "abstract class";

set "wb(kind:class)" 0;
set "wb(kind:shared)" 5;
set "wb(kind:static class)" 6;
set "wb(kind:record)" 7;
set "wb(kind:abstract class)" 8;

set i 0;

if [file exist $env(HOME)/.oz++wbrc] {
  set f [open $env(HOME)/.oz++wbrc r];
  set wb(pwd) [gets $f];
  set wb(lang) [gets $f];
  close $f;
}

if {$argc > $i} {
  set wb(pwd) [lindex $argv $i];
  incr i;
}

if ![file isdirectory $wb(pwd)] {
  set wb(pwd) [pwd];
}

cd $wb(pwd);
				     
if {$argc > $i} {
  set buf [lindex $argv $i];
  incr i;

  if {$buf == "english" || $buf == "japanese"} {
    set wb(lang) $buf;
  }
}

if {$argc > $i} {
  set buf [lindex $argv $i];
  incr i;
  if {$buf == "boot"} {
    set wb(boot) 1;
  } elseif {$buf == "unix"} {
    set wb(boot) 2;
  } else {
    set wb(boot) 0;
  }
}

if {$argc > $i} {
  set wb(path) [lindex $argv $i];
  incr i;
} 

if {$argc > $i} {
  set wb(class) [lindex $argv $i];
} 

lang_of_$wb(lang);

if {$wb(boot) < 2 && $wb(debug_mode)} {
  rename SendOZ orig_SendOZ;
  proc SendOZ {str} {
    puts_for_debug $str;
    orig_SendOZ $str;
  }
}

if {$wb(boot) < 2} {
  if {$wb(class) == ""} {
    InputClassObject;
  }
} else {
  set wb(path) lib/boot-class;
}

if $wb(boot) {
  set wb(cfed) "$env(OZROOT)/bin/cfed -t";
  set wb(current) "etc/boot-school";
  wb_create;
  Register "etc/boot-school" etc/boot-school;

} else {
  wb_create;
}


# For Unix 

if {$wb(boot) == 2} {
  rename RecvOZ junky_RecvOZ;
  proc RecvOZ {} {}

  if !$wb(debug_mode) {
    rename SendOZ junky_SendOZ;
    proc SendOZ {str} {}
  }
} 

