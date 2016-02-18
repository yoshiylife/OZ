proc my_file_selector {w proc args {dir {}} \
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
			 {mode file} {pattern "*"} {newonly ""} {close 1}} {
  global fs; 			   
			   
  if [catch {toplevel $w}] {
    return "";
  }

  if [info exists fs(dir)] {
    set dir $fs(dir);
  }

  wm title $w "File Selector";

  frame $w.f0;
  entry $w.f0.dir -relief ridge;
  $w.f0.dir insert end $dir;

  frame $w.f1;
  frame $w.f1.f2l;
  scrollbar $w.f1.f2l.sbx \
    -orient horiz -cursor sb_h_double_arrow \
      -command "$w.f1.f2l.box xview" -relief sunken -bd 1;

  scrollbar $w.f1.f2l.sby \
      -command "$w.f1.f2l.box yview" -relief sunken -bd 1;
  
  listbox $w.f1.f2l.box \
    -xscrollcommand "$w.f1.f2l.sbx set" \
    -yscrollcommand "$w.f1.f2l.sby set";

#  bind $w.f1.f2l.box <3> {%W select from [%W nearest %y]};
#  bind $w.f1.f2l.box <B3-Motion> {%W select from [%W nearest %y]};
#  bind $w.f1.f2l.box <Double-ButtonPress-3> "change_dir $w";

  bind $w.f1.f2l.box <3> {%W select clear};
  bind $w.f1.f2l.box <B1-Motion> \
    {%W select to [%W nearest %y]};
  bind $w.f1.f2l.box <Double-ButtonPress-1> \
    "if {\[%W curselection\] == \[%W nearest %y\]} { change_dir $w }";

  if {$mode != "file"} {
#    bind $w.f1.f2l.box <B1-Motion> {%W select from [%W nearest %y]};
#    bind $w.f1.f2l.box <1> {%W select from [%W nearest %y]};
    bind $w.f1.f2l.box <Control-1> {%W select from [%W nearest %y]};
    bind $w.f1.f2l.box <Control-Double-ButtonPress-1> "$w.f3.select invoke";
  }

  frame $w.f1.f2r;
  scrollbar $w.f1.f2r.sbx \
    -orient horiz -cursor sb_h_double_arrow \
      -command "$w.f1.f2r.box xview" -relief sunken -bd 1;

  scrollbar $w.f1.f2r.sby \
      -command "$w.f1.f2r.box yview" -relief sunken -bd 1;
  
  listbox $w.f1.f2r.box \
    -xscrollcommand "$w.f1.f2r.sbx set" \
    -yscrollcommand "$w.f1.f2r.sby set";

  if {$mode == "dir"} {
    bind $w.f1.f2r.box <1> {%W select clear};
    bind $w.f1.f2r.box <B1-Motion> {%W select clear};
    bind $w.f1.f2r.box <Double-ButtonPress-1> {%W select clear};
  } 

  if {$mode != "dir"} {
    bind $w.f1.f2r.box <Double-ButtonPress-1> "$w.f3.select invoke";
  }

  bind $w.f1.f2r.box <3> {%W select clear};

  frame $w.f3 -relief raised -bd 1;
  button $w.f3.select -text "Select" -relief flat \
    -command "select_file $w $proc \"$args\" $close $mode";
  button $w.f3.rescan -text "Rescan" -relief flat -command "scan_dir $w";
  button $w.f3.close -text "Close" -relief flat -command "destroy $w;";

  if {$newonly == "new"} {
    $w.f3.select configure -state disabled;
  } else {
    $w.f3.select configure -state normal;
  }

  frame $w.f6 -relief raised -bd 1;
  button $w.f6.mkdir -text "Make Directory" -relief flat \
    -command "new_item $w 1 $proc \"$args\" $close";
  button $w.f6.new -text "New" -relief flat \
    -command "new_item $w 0 $proc \"$args\" $close";

  if {$proc == ""} {
    $w.f6.new configure -state disabled
  }

  frame $w.f5;
  label $w.f5.label -text "Pattern:";
  entry $w.f5.pattern -relief ridge;
  $w.f5.pattern insert insert $pattern;

  bind $w.f5.pattern <Return> "$w.f3.rescan invoke";

  bind $w.f0.dir <Return> "$w.f3.rescan invoke";

  pack $w.f0 -fill x;
  pack $w.f0.dir -fill x -ipady 5 -expand yes;
  
  pack $w.f1 -fill both -expand yes;
  pack $w.f1.f2l $w.f1.f2r -side left -expand yes -fill both;

  pack $w.f1.f2l.sby -side right -fill y;
  pack $w.f1.f2l.sbx -side bottom -fill x;
  pack $w.f1.f2l.box -fill y -fill both -expand yes;

  pack $w.f1.f2r.sby -side right -fill y;
  pack $w.f1.f2r.sbx -side bottom -fill x;
  pack $w.f1.f2r.box -fill y -fill both -expand yes;

  pack $w.f5 $w.f6 $w.f3 -fill x;

  pack $w.f5.label -side left -ipady 5;
  pack $w.f5.pattern -fill x -side left -expand yes -ipady 5;

  pack $w.f6.mkdir $w.f6.new -side left -padx 2 -ipady 3 -fill x -expand yes;

  pack $w.f3.select $w.f3.rescan $w.f3.close \
    -side left -fill x -padx 2 -ipady 3 -expand yes;

  $w.f3.rescan invoke;
  if {$newonly == "new"} {
    $w.f6.new invoke;
  }

  set_center $w;
  set_expandable $w;
  return $w;
}

proc change_dir {w} {
  if {[set index [$w.f1.f2l.box curselection]] == ""} { return; }

#  set now_dir [pwd];
  set dir [$w.f0.dir get]/[$w.f1.f2l.box get $index];
  
  if [cd_dir $w $dir] return;
  
  $w.f0.dir delete 0 end;
  $w.f0.dir insert 0 [pwd];

  scan_dir $w;

#  cd $now_dir;
}

proc select_file {w {proc {}} {args {}} close mode} {
  if {[set sel [$w.f1.f2r.box curselection]] == ""} {
    if {[set sel [$w.f1.f2l.box curselection]] == ""} {
      return;
    } else {
      set box $w.f1.f2l.box;
      set files dir;
    }
  } else {
    set box $w.f1.f2r.box;
    set files file;
  }

  set_all_state_fsel $w disabled $w;

  set dir [$w.f0.dir get];

  if {$dir != "[file dirname $dir]/"} {
    set dir "$dir/";
  }

  if {$mode != "any"} {
    set files {};
  }
  foreach i $sel {
    set buf [$box get $i];

    if {$buf == "."} {
      set buf ""; 
      set dir [string range $dir 0 [expr [string length $dir] - 2]];
    } 

    lappend files "$dir$buf";
  }

  eval {$proc $files "$args"};

  set_all_state_fsel $w normal;

  if {$close} {
    destroy $w;
  }
}

proc set_all_state_fsel {w state {grab {}}} {
  foreach i "select rescan close" {
    $w.f3.$i configure -state $state;
  }

  foreach i "mkdir new" {
    $w.f6.$i configure -state $state;
  }

  if {$grab != ""} {
    grab set $grab;
    $w.f1.f2r.box configure -cursor watch;
  } else {
    grab release [grab current];
    $w.f1.f2r.box configure -cursor top_left_arrow;
  }
}

proc cd_dir {w dir} {
  global fs;

  if [catch { cd $dir } msg] {
    tk_dialog $w.info "info." \
	"`$dir'\nno such directory" info 0 "Close";
    $w.f0.dir delete 0 end;
    $w.f0.dir insert end $fs(dir);
    return 1;
  }

  return 0;
}


proc scan_dir {w} {
  global fs;

#  set now_dir [pwd];
  set dir [$w.f0.dir get];

  if [cd_dir $w $dir] return;

  $w.f1.f2r.box delete 0 end;
  $w.f1.f2r.box select clear;
  $w.f1.f2l.box delete 0 end;
  $w.f1.f2l.box select clear;

  set list [lsort [glob -nocomplain {.*} {*}]];

  foreach i $list {
    if {[file isdirectory $i]} {
      $w.f1.f2l.box insert end $i;
    }
  }

  set list [lsort [glob -nocomplain "[$w.f5.pattern get]"]];

  foreach i $list {
    if {![file isdirectory $i]} {
      $w.f1.f2r.box insert end $i;
    }
  }

  set fs(dir) $dir;

#  cd $now_dir;
}

proc new_item {w mkdir {proc {}} {args {}} this_close} {
  global close;

  set win [toplevel $w.input];

  frame $win.fn1;
  label $win.fn1.msg -text "Please input a name ..." -anchor w;
  entry $win.fn1.name -width 20 -relief sunken -bd 1;

  mybind $win.fn1.name <Control-h> \
    "if {\[$win.fn1.name get\] == \"\"} { \
	$win.fn2.f3.done configure -state disabled; }";

  mybind $win.fn1.name <Any-KeyPress> \
    "$win.fn2.f3.done configure -state normal;"

  bind $win.fn1.name <Return> \
    "$win.fn2.f3.done invoke";

  frame $win.fn2;
  frame $win.fn2.f3 -relief sunken -bd 1;
  button $win.fn2.f3.done -text "Done" -state disabled -bd 1 \
    -command {
      global close;

      set close done;
    }
  button $win.fn2.cancel -text "Cancel" -bd 1 \
    -command {
      global close;

      set close cancel;
    }

  pack $win.fn1 -fill both;
  pack $win.fn1.msg -fill both -expand yes -padx 3 -pady 3;
  pack $win.fn1.name -padx 10 -ipady 3 -pady 10 -fill x -expand yes;

  pack $win.fn2 -fill x -expand yes;
  pack $win.fn2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.fn2.f3.done -pady 5 -anchor c -ipadx 5 -ipady 5;
  pack $win.fn2.cancel -side right -padx 40 -pady 5 -ipadx 5 -ipady 5;

  set_center $win;

  focus $win.fn1.name;
  tkwait variable close;

  set dir [$w.f0.dir get];
  set name [$win.fn1.name get];

  destroy $win;

  if {$close == "cancel" || $name == ""} {
    return;
  }

  if {![catch {glob $dir/$name}]} {
    tkerror "This name exits.";
    return;
  }

  if {$mkdir} {
    exec mkdir $dir/$name;
    scan_dir $w;
  } else {
    eval $proc $dir/$name "$args";
    if {$this_close} {
      destroy $w;
    }
  }
}

