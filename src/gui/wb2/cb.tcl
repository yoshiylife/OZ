# 
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a UI for Class Browser
#

# Global functions

# Local functions

proc cb_search_str {win} {
  set w [winfo parent $win];

  if {[set len [string length [set str [$win.f2.sstr get]]]] == 0} {
    return;
  }

  if {[set start [$w.f0.text tag ranges cur_search]] == ""} {
    set content [$w.f0.text get 1.0 end];
    set start 1.0;
  } else {
    if {[eval $w.f0.text get $start] == $str} {
      cb_go_next $w;
      return;
    }

    set start [lindex $start 0];
    set content [$w.f0.text get 1.0 end];
  }

  $w.f0.text tag delete search cur_search;
  $w.f0.text tag configure cur_search \
    -background LightBlue -relief raised;

  set cur 0;
  set pos 0;
  while {$pos > -1} {
    if {[set pos [string first "$str" [string range $content $cur end]]] > -1} {
      set pos [expr $pos + $cur];
      $w.f0.text tag add search "1.0 + $pos chars" \
	"1.0 + [expr $pos + $len] chars";
      set cur [expr $pos + $len];
    }
  }
  
  if {[set pos [$w.f0.text tag nextrange search $start]] == ""} {
    if {[set pos [$w.f0.text tag nextrange search 1.0]] == ""} {
      tk_dialog .info "Info." "Not found" info 0 "Close";
      $win.f1.next configure -state disabled;
      $win.f1.prev configure -state disabled;
    }
  }

  if {$pos != ""} {
    eval $w.f0.text tag add cur_search $pos;
    $w.f0.text yview -pickplace [lindex $pos 0];
    $win.f1.next configure -state normal;
    $win.f1.prev configure -state normal;
  }
}

proc cb_go_prev {w} {
  if {[set cur [$w.f0.text tag ranges cur_search]] == ""} {
    return;
  }
   
  eval $w.f0.text tag remove cur_search $cur;
  set range [$w.f0.text tag ranges search];
  set i [lsearch -exact $range "[lindex $cur 0]"];

  if {$i == 0} {
    set i [expr [llength $range] - 2];
  } else {
    incr i -2;
  }
  
  set pos "[lindex $range $i] [lindex $range [expr $i + 1]]";
  eval $w.f0.text tag add cur_search $pos;
  $w.f0.text yview -pickplace [lindex $pos 0];
}

proc cb_go_next {w} {
  if {[set cur [$w.f0.text tag ranges cur_search]] == ""} {
    return;
  }
   
  eval $w.f0.text tag remove cur_search $cur;
  set pos [$w.f0.text tag nextrange search "[lindex $cur 1] + 1 chars"];
  if {$pos == ""} {
    set pos [$w.f0.text tag nextrange search 1.0];
  }
  eval $w.f0.text tag add cur_search $pos;
  $w.f0.text yview -pickplace [lindex $pos 0];
}

proc cb_goto_line {w} {
  if {[set lnum [$w.f3.lnum get]] == ""} {
    return;
  }

  $w.f0.text tag delete cur_search;
  $w.f0.text tag configure cur_search -background LightBlue -relief raised;

  set width [lindex [$w.f0.text configure -width] 4];

  if [catch {$w.f0.text tag add cur_search $lnum.0 $lnum.[expr $width - 1]}] {
      tk_dialog .info "Info." "Illegal line number" error 0 "Close";
  } else {
    $w.f0.text yview -pickplace $lnum;
  }
}

proc cb_search_win {w} {
  global label;

  if [winfo exists $w.search] {
    wm deiconify $w.search;
    raise $w.search;
    return;
  }

  set win [toplevel $w.search];

  wm title $win "Searching ...";

  frame $win.f2 -bd 2 -relief ridge;
  label $win.f2.label -textvariable "label(Search)" -anchor w;
  entry $win.f2.sstr -relief ridge;

  mybind $win.f2.sstr <Control-h> \
    "if {\[$win.f2.sstr get\] == \"\"} {\
 	$win.f1.f0.search configure -state disabled;\
 	$win.f1.clear configure -state disabled;\
 	$win.f1.next configure -state disabled;\
 	$win.f1.prev configure -state disabled;\
 	$win.f1.clear configure -state disabled;\
    }";

  mybind $win.f2.sstr <Any-KeyPress> \
    "$win.f1.f0.search configure -state normal;\
      $win.f1.clear configure -state normal;"

  bind $win.f2.sstr <Return> "$win.f1.f0.search invoke";

  bind $win.f2.sstr <Tab> \
    "if {\[$win.f2.sstr get\] != \"\"} {\
	$win.f1.prev invoke;\
    }";

  frame $win.f1;
  frame $win.f1.f0 -relief sunken -bd 1;    
  button $win.f1.f0.search -textvariable "label(Exec)" -state disabled \
    -command "cb_search_str $win";
  button $win.f1.next -textvariable "label(Next)" -state disabled \
    -command "cb_go_next $w";
  button $win.f1.prev -textvariable "label(Prev)" -state disabled \
    -command "cb_go_prev $w";
  button $win.f1.clear -textvariable "label(Clear)" -state disabled \
    -command "$win.f2.sstr delete 0 end; focus $win.f2.sstr;\
		$win.f1.f0.search configure -state disabled;\
		$win.f1.clear configure -state disabled";

  button $win.f1.cancel -textvariable "label(Close)" -bd 1 \
    -command "destroy $win";

  pack $win.f2 -fill both -padx 10 -pady 10;
  pack $win.f2.label -fill both -expand yes -padx 3 -pady 3;
  pack $win.f2.sstr -side left -fill x -expand 1 -padx 10 -pady 10 \
    -ipady 5;

  pack $win.f1 -fill x -expand yes;
  pack $win.f1.f0 -side left -ipadx 5 -padx 20 -pady 5;
  pack $win.f1.f0.search -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f1.prev $win.f1.next $win.f1.clear \
    -side left -padx 20 -ipadx 5 -ipady 5;
  pack $win.f1.cancel -side right -ipadx 5 -ipady 5 -padx 20 -pady 5;

  focus $win.f2.sstr;
}

proc cb_goto_win {w} {
  global label;

  if [winfo exists $w.goto] {
    wm deiconify $w.goto;
    raise $w.goto;
    return;
  }

  set win [toplevel $w.goto];

  wm title $win "Goto ...";

  frame $win.f3 -bd 2 -relief ridge;
  label $win.f3.label -textvariable "label(Goto)" -anchor w;
  entry $win.f3.lnum -relief ridge;

  bind $win.f3.lnum <Return> "$win.f1.f0.goto invoke";

  mybind $win.f3.lnum <Control-h> \
    "if {\[%W get\] == \"\"} {\
 	$win.f1.f0.goto configure -state disabled;\
    }";
  
  mybind $win.f3.lnum <Any-KeyPress> \
    "$win.f1.f0.goto configure -state normal;"
      
  frame $win.f1;
  frame $win.f1.f0 -relief sunken -bd 1;    
  button $win.f1.f0.goto -textvariable "label(Exec)" -state disabled \
    -command "cb_goto_line $w";
  button $win.f1.cancel -textvariable "label(Close)" -bd 1 \
    -command "destroy $win";

  pack $win.f3 -fill both -padx 10 -pady 10;
  pack $win.f3.label -fill both -expand yes -padx 3 -pady 3;
  pack $win.f3.lnum -side left -fill x -expand 1 -padx 10 -pady 10 \
    -ipady 5;

  pack $win.f1 -fill x -expand yes;
  pack $win.f1.f0 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f1.f0.goto -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f1.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;


  focus $win.f3.lnum;
}

proc cb_src_new_win {school_name class_name vid} {
  global wb wbw wbk label cb;

  if ![file exists $wb(cpath)/$vid/private.oz] {
    tk_dialog .info "Info." \
      "Cannot show implementation." info 0 "Close";
    return;
  }

  if [info exists wbw($vid:CB)] {
    set win $wbw($vid:CB);

    wm deiconify $win;
    raise $win;
    return;

  } else {
    set wbw($vid:CB) .s[incr wb(win)];
    lappend wb(allwin) "$vid:CB";
    set w [toplevel $wbw($vid:CB)];
    set wb($w) "$school_name";
    set wbk($w) "CB";
    set cb(kind:$w) "CB1";
    set cb(name:$w) "$class_name";
    set cb(vid:$w) "$vid";
  }

  wm title $w "source file of `$vid'";
  
  frame $w.f3 -relief raised -bd 1;
  menubutton $w.f3.cb -textvariable "label(CB)" -menu $w.f3.cb.m;
  menu $w.f3.cb.m;

  proc cb_src_cb_menu {w} {
    global label;

    delete_menu $w.f3.cb.m;

    $w.f3.cb.m add command -label "$label(Close)" -command "cb_close $w";
    $w.f3.cb.m add separator;
    $w.f3.cb.m add command -label "$label(Preference...)" \
      -command "preference $w";
    $w.f3.cb.m add separator;
    $w.f3.cb.m add command -label "$label(Quit)" -command "quit";
  }

  cb_src_cb_menu $w;

  menubutton $w.f3.ops -textvariable "label(Ops)" -menu $w.f3.ops.m;
  menu $w.f3.ops.m;

  proc cb_src_ops_menu {w} {
    global label;

    delete_menu $w.f3.ops.m;

    $w.f3.ops.m add command -label "$label(Search...)" \
      -command "cb_search_win $w";
    $w.f3.ops.m add command -label "$label(Goto...)" -command "cb_goto_win $w";
  }

  cb_src_ops_menu $w;

  menubutton $w.f3.window -textvariable "label(Window)" -menu $w.f3.window.m;
  menu $w.f3.window.m;

  tk_menuBar $w.f3 $w.f3.cb $w.f3.ops $w.f3.window;
  focus $w.f3;
  
  label $w.f3.name -text "$class_name" -relief ridge -anchor e;
  
  frame $w.f0;
  text $w.f0.text -yscrollcommand "$w.f0.sb set" -relief ridge -bd 2;
  scrollbar $w.f0.sb -command "$w.f0.text yview" -relief sunken;

  bind $w.f0.text <Control-1> \
    "if {\[%W tag ranges sel\] != {}} {\
      sb_search $wb($w) \[%W get sel.first sel.last\];\
    }";
  
  pack $w.f3 -fill x;
  pack $w.f3.cb $w.f3.ops $w.f3.window -side left -ipadx 5 -ipady 3;
  pack $w.f3.name -expand 1 -fill x -pady 3 -ipady 1 -padx 5;

  pack $w.f0 -fill both -expand 1;
  pack $w.f0.text -side left -fill both -expand 1;
  pack $w.f0.sb -fill y -side right;

  set_center $w;
  set_expandable $w;

  set_all_windows $w "$vid ($class_name)";
  
  set fid [open $wb(cpath)/$vid/private.oz];
  $w.f0.text insert end "[read $fid]";
  close $fid;

  $w.f0.text configure -state disabled;
}

proc cb_get_class_name {fid} {
  return [lrange [gets $fid] 2 end];
}

proc cb_get_parents {fid} {
  set parents {};

  gets $fid buf;
  if {[string first "parents :" $buf] > -1} {
    gets $fid buf;
  }
  
  while {[string first "members :" $buf] < 0} {
    switch [llength $buf] {
      1 {
	lappend parents "[lindex $buf 0]";
      }
      2 {
	lappend parents "[lindex $buf 0] [lindex $buf 1]";
      }
    }
    gets $fid buf;
  }

  return $parents;
}

proc cb_get_members {vid fid} {
  global cb;

  set members {};
  
  set buf [string trim [gets $fid]];

  while {![is_success $buf]} {
    lappend members [set name [lindex $buf 0]];
    set cb($vid:$name) $name;
    lappend cb($vid:$name) "[lindex $buf 2]";
    set buf [string trim [gets $fid]];
    lappend cb($vid:$name) \
      [string range $buf [expr [string first ":" $buf] + 1] end];

    if {[string first "qualifier:" $buf] > -1} {
      set buf [string trim [gets $fid]];
      lappend cb($vid:$name) \
	[string range $buf [expr [string first ":" $buf] + 1] end];
      while {[string first "#2" $buf] == -1} {
	set buf [string trim [gets $fid]];
	lappend cb($vid:$name) \
	  [string range $buf [expr [string first ":" $buf] + 1] end];
      }
    } else {
      set buf [string trim [gets $fid]];
      lappend cb($vid:$name) \
	[string range $buf [expr [string first ":" $buf] + 1] end];
    }
    set buf [string trim [gets $fid]];
  }

  return [lsort $members];
}

proc cb_search_member_by_slot {w class_name vid part num} {
  set name [write_to_cfed $w cb '$class_name' $part $num];

  if {$name != ""} {
    search_member $w $class_name $vid $name $part $path;
  } else {
    tk_dialog $w.notfound "Info." "Not found." info 0 "Close";
  }
}

proc cb_search_member {w name} {
  global cb;

  set class_name $cb(name:$w);
  set vid $cb(vid:$w);
  set part $cb(part:$w);

  if {[string index $name 0] == "#"} {
    search_member_by_slot $w $class_anme $vid $part $name;
    return;
  }

  set n [$w.f1.f2.members size];

  for {set i 0} {$i < $n} {incr i} {
    if {$name == [$w.f1.f2.members get $i]} {
      $w.f1.f2.members select from $i;
      $w.f1.f2.members yview $i;
      cb_show_member_detail $w $vid $name;
      return;
    }
  }
}

proc cb_show_member_detail {w vid name} {
  global cb;
  
  $w.f2.detail configure -state normal;
  $w.f2.detail delete 1.0 end;

#  $w.f2.detail insert end "[lindex $cb($vid:$name) 1]\n";

  if {[llength $cb($vid:$name)] == 7} {
    $w.f2.detail insert end "[lindex $cb($vid:$name) 3] ";
    $w.f2.detail insert end "[lindex $cb($vid:$name) 0] (";
    set arg [lindex $cb($vid:$name) 4];
    if {$arg != ""} {
      set j 0;
      set buf [split $arg ','];
      set len [llength $buf];
      foreach i [split $arg ','] {
	$w.f2.detail insert end "[string trim $i]";
	incr j;
	if {$j != $len} {
	  $w.f2.detail insert end ",\n\t\t";
	}
      }
      $w.f2.detail insert end ")\n";
    } else {
      $w.f2.detail insert end ")\n";
    }
    $w.f2.detail insert end "\n\t[lindex $cb($vid:$name) 5]\n";
    $w.f2.detail insert end "\tslot #2 = [lindex $cb($vid:$name) 6]\n";
  } else {
    $w.f2.detail insert end "[lindex $cb($vid:$name) 2] ";
    $w.f2.detail insert end "[lindex $cb($vid:$name) 0];\n";
    $w.f2.detail insert end "\n\t[lindex $cb($vid:$name) 3];";
  }

  $w.f2.detail configure -state disabled;
}

proc cb_search_inif_win {w} {
  global label cb;

  if [winfo exists $w.searchif] {
    wm deiconify $w.searchif;
    raise $w.search;
    return;
  }

  set win [toplevel $w.searchif];

  wm title $win "Searching ...";

  frame $win.f2 -bd 2 -relief ridge;
  label $win.f2.label -textvariable "label(Search)" -anchor w;
  entry $win.f2.sstr -relief ridge;

  mybind $win.f2.sstr <Control-h> \
    "if {\[$win.f2.sstr get\] == \"\"} {\
 	$win.f1.f0.search configure -state disabled;\
 	$win.f1.clear configure -state disabled;\
    }";

  mybind $win.f2.sstr <Any-KeyPress> \
    "$win.f1.f0.search configure -state normal; \
    	$win.f1.clear configure -state normal;"

  bind $win.f2.sstr <Return> "$win.f1.search invoke";

  frame $win.f1;
  frame $win.f1.f0 -relief sunken -bd 1;    
  button $win.f1.f0.search -textvariable "label(Exec)" -state disabled -bd 1\
    -command "cb_search_member $w \[$win.f2.sstr get\]";
  button $win.f1.clear -textvariable "label(Clear)" -state disabled -bd 1\
    -command "$win.f2.sstr delete 0 end; \
	$win.f1.f0.search configure -state disabled; \
	$win.f1.clear configure -state disabled; \
	focus $win.f2.sstr";
  button $win.f1.cancel -textvariable "label(Close)" -bd 1 \
    -command "destroy $win";

  pack $win.f2 -fill both -padx 10 -pady 10;
  pack $win.f2.label -fill both -expand yes -padx 3 -pady 3;
  pack $win.f2.sstr -side left -fill x -expand 1 -padx 10 -pady 10 \
    -ipady 5;

  pack $win.f1 -fill x -expand yes;
  pack $win.f1.f0 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f1.f0.search -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f1.cancel $win.f1.clear \
    -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  focus $win.f2.sstr;
}

proc cb_show_if {w class_name vid part} {
  global wb cb;
  
  set parents {};

  set f $wb(cfed:$wb($w));

  write_to_cfed_nowait $w cb '$class_name' $part;
  
  set class_name "[cb_get_class_name $f]";
  set parents [cb_get_parents $f]; 
  set members [cb_get_members $vid $f];

  $w.f1.f2.members select clear;
  
  if {$parents == {} && $members == {}} { 
    tk_dialog $w.notfound "Info." "This class has no etnry." info 0 "Close";
    return; 
  }
  
  foreach i $parents {
    $w.f1.f1.parents insert end $i;
  }
  
  foreach i $members {
#    $w.f1.f2.members insert end $i;
    set add "";
    
    set access [lindex $cb($vid:$i) 1];
    if {$access == "constructor"} {
#      $w.f1.f2.members itemconfigure end -foreground red;
      append add "(constructor";
    } elseif {$access == "protected"} {
#      $w.f1.f2.members itemconfigure end -foreground blue;
      append add "(protected";
    }

    if {[llength $cb($vid:$i)] < 7} {
#      $w.f1.f2.members itemconfigure end -underline yes;
      if {$add == ""} {
	set add "(variable";
      } else {
	append add " variable";
      }
    } 

    if {$add != ""} {
      $w.f1.f2.members insert end "$i    $add)";
    } else {
      $w.f1.f2.members insert end $i;
    }
  }
}

proc cb_if_new_win {school_name class_name vid part} {
  global wb wbk wbw label cb;

  if ![file exists $wb(cpath)/$vid/$part.z] {
    tk_dialog .info "Info." \
      "Cannot show interface." info 0 "Close";
    return;
  }

  if [info exists wbw($vid:CB)] {
    set win $wbw($vid:CB);

    wm deiconify $win;
    raise $win;
    return;

  } else {
    set wbw($vid:CB) .s[incr wb(win)];
    lappend wb(allwin) "$vid:CB";
    set w [toplevel $wbw($vid:CB)];
    set wb($w) "$school_name";
    set wbk($w) "CB";
    set cb(kind:$w) "CB2";
    set cb(name:$w) "$class_name";
    set cb(vid:$w) "$vid";
    set cb(part:$w) "$part";
  }

  wm title $w "`$part' interface of `$class_name ($vid)'";

  frame $w.f0 -bd 1 -relief raised;

  frame $w.f3 -relief raised -bd 1;
  menubutton $w.f3.cb -textvariable "label(CB)" -menu $w.f3.cb.m;
  menu $w.f3.cb.m;

  proc cb_if_cb_menu {w} {
    global label;

    delete_menu $w.f3.cb.m;

    $w.f3.cb.m add command -label "$label(Close)" -command "cb_close $w";
    $w.f3.cb.m add separator;
    $w.f3.cb.m add command -label "$label(Preference...)" \
      -command "preference $w";
    $w.f3.cb.m add separator;
    $w.f3.cb.m add command -label "$label(Quit)" -command "quit";
  }

  cb_if_cb_menu $w;

  menubutton $w.f3.ops -textvariable "label(Ops)" -menu $w.f3.ops.m;
  menu $w.f3.ops.m;

  proc cb_if_ops_menu {w} {
    global label;

    delete_menu $w.f3.ops.m;

    $w.f3.ops.m add command -label "$label(Search...)" \
      -command "cb_search_inif_win $w";
  }

  cb_if_ops_menu $w;

  menubutton $w.f3.window -textvariable "label(Window)" -menu $w.f3.window.m;
  menu $w.f3.window.m;

  tk_menuBar $w.f3 $w.f3.cb $w.f3.ops $w.f3.window;
  focus $w.f3;
  
  label $w.f3.name -text "$class_name" -relief ridge -anchor e;
  
  frame $w.f1;
  
  frame $w.f1.f1;
  label $w.f1.f1.label -textvariable "label(Parent Classes)" -relief flat;
  scrollbar $w.f1.f1.sb -command "$w.f1.f1.parents yview" -relief sunken;
  listbox $w.f1.f1.parents -relief ridge -exportselection no \
    -yscrollcommand "$w.f1.f1.sb set" -geometry 32x20;
  
  bind $w.f1.f1.parents <Control-1> \
    "if {\[%W curselect\] != {}} {\
      sb_search $wb($w) \[lindex \[%W get \[%W curselect\]\] 0\];\
    }";
  
  bind $w.f1.f1.parents <B1-Motion> {
  }
  
  frame $w.f1.f2;
  label $w.f1.f2.label -textvariable "label(Members)" -relief flat;
  scrollbar $w.f1.f2.sb -command "$w.f1.f2.members yview" -relief sunken;
  listbox $w.f1.f2.members -relief ridge -geometry 40x20 -exportselection no \
    -yscrollcommand "$w.f1.f2.sb set" -relief ridge -bd 2;

  bind $w.f1.f2.members <B1-Motion> {
  }
  
  bind $w.f1.f2.members <1> \
    "%W select from \[set i \[%W nearest %y\]\];\ 
      cb_show_member_detail $w $vid \[lindex \[%W get \$i\] 0\]";
  
  frame $w.f2;
  scrollbar $w.f2.sb -command "$w.f2.detail yview" -relief sunken;
  text $w.f2.detail -width 60 -height 10 -yscrollcommand "$w.f2.sb set" \
    -relief ridge -bd 2 -state disabled;

  bind $w.f2.detail <Control-1> \
    "if {\[%W tag ranges sel\] != {}} {\
      sb_search $wb($w) \[%W get sel.first sel.last\];\
    }";
  
  bind $w.f2.detail <3> { %W tag remove sel sel.first sel.last }
  
  pack $w.f3 -fill x;
  pack $w.f3.cb $w.f3.ops $w.f3.window -side left -ipadx 5 -ipady 3;
  pack $w.f3.name -expand 1 -fill x -pady 3 -ipady 1 -padx 5;
  
  pack $w.f1 -fill both -expand 1;
  pack $w.f1.f1 -side left -fill both -expand 1;

#  pack $w.f1.f1.label -side top -fill x;
  pack $w.f1.f1.sb -side right -fill y;
  pack $w.f1.f1.parents -side top -expand 1 -fill both;

  pack $w.f1.f2 -side left -fill both -expand 1;
#  pack $w.f1.f2.label -side top -fill x;
  pack $w.f1.f2.sb -side right -fill y;
  pack $w.f1.f2.members -side top -expand 1 -fill both;

  pack $w.f2 -fill both -expand yes;
  pack $w.f2.sb -side right -fill y;
  pack $w.f2.detail -side top -fill both;

  set_center $w;
  set_expandable $w;

  set_all_windows $w "$vid ($class_name)";
  
  cb_show_if $w $class_name $vid $part;
}

proc cb_get_content {w class_name vid} {
  global cb wb;

  write_to_cfed $w sb '$class_name' 9 $vid;

  write_to_cfed_nowait $w cb '$class_name' private;
  set fid $wb(cfed:$wb($w));
  
  gets $fid buf;

  if {[string first "not defined" $buf] >= 0} {
    gets $fid buf;
  }

#  puts_for_debug $buf;
  
  if {[is_success $buf] || [scan $buf "no parts = %d" no_parts] < 1} {
    tk_dialog $w.info "Info." \
      "Cannot show configuration." info 0 "Close";
    return 1;
  }

  set cb($vid:parents) {};
  set cb($vid:methods) {};
  set cb($vid:cid) {};
  set cb($vid:cvid) {};
  set cb($vid:alloc) {};

  for {set i 0} {$i < $no_parts} {incr i} {
    gets $fid; # skip;
    gets $fid buf;
    set id [lindex $buf 2];
    set name [lrange $buf 3 end];
    lappend cb($vid:parents) "$id $name";
    lappend cb($vid:cid) $id;

    scan [gets $fid] "%s = %s" junk id;
    lappend cb($vid:cvid) $id;

    gets $fid; #skip

    set alloc {};
    for {set j 0} {$j < 6} {incr j} {
      scan [gets $fid] "%s = %d" junk data;
      lappend alloc $data;
    }
    lappend cb($vid:alloc) $alloc;

    gets $fid; #skip

    set methods {};
    scan [gets $fid] "\tno entries = %d" no_methods;
    lappend methods $no_methods;

    for {set j 0} {$j < $no_methods} {incr j} {
      set method {};
      scan [gets $fid] "\tslot = %d" num;
      lappend method $num;

      gets $fid buf;
      if {[scan $buf "%s = %s func no = %d" junk id num] == 2} {
	set num [lindex $buf [expr [llength $buf] - 1]];
      }
      lappend method $id $num;
      lappend methods $method;

      gets $fid; #skip
    }
    lappend cb($vid:methods) $methods;
  }

  set buf [gets $fid];

#  puts_for_debug $buf;

  return 0;
} 

proc cb_set_data {w data} {
  $w configure -state normal;
  $w delete 0 end;
  $w insert end $data;
  $w configure -state disabled;
}

proc cb_show_content {w vid num} {
  global cb;

  set methods [lindex $cb($vid:methods) $num];
  set alloc [lindex $cb($vid:alloc) $num];

  set j 4;
  cb_set_data $w.f$j.entry $num;
  cb_set_data $w.f[incr j].entry [lindex $cb($vid:parents) $num];
  set cid [lindex $cb($vid:cid) $num];
  cb_set_data $w.f[incr j].entry [lindex $cb($vid:cvid) $num];
  incr j;
  for {set i 0} {$i < 6} {incr i} {
    incr j;
    cb_set_data $w.f$j.entry0 [lindex $alloc $i];
    cb_set_data $w.f$j.entry1 [lindex $alloc [incr i]];
  }
  cb_set_data $w.f[incr j].entry [set no_methods [lindex $methods 0]];

  incr j;
  foreach i "slot vid func" {
    $w.f$j.$i delete 0 end;
  }

  for {set i 1} {$i <= $no_methods} {incr i} {
    set method [lindex $methods $i];
    $w.f$j.slot insert end [lindex $method 0];
    $w.f$j.vid insert end [set id [lindex $method 1]];
    $w.f$j.func insert end [lindex $method 2];
    if [string compare $id $cid] {
#      $w.f$j.slot itemconfigure end -foreground red;
#      $w.f$j.vid itemconfigure end -foreground red;
#      $w.f$j.func itemconfigure end -foreground red;
    }
#    update;
  }
}

proc cb_conf_show_parents {w class_name vid} {
  global cb;

  foreach i $cb($vid:parents) {
    $w.f2.parents insert end $i;
  }

  $w.f2.parents select clear;
}

proc cb_conf_new_win {school_name class_name vid} {
  global wb wbk wbw label cb;

  if ![file exists $wb(cpath)/$vid/private.r] {
    tk_dialog .info "Info." \
      "Cannot show configuration." info 0 "Close";
    return;
  }


  if [info exists wbw($vid:CB)] {
    set win $wbw($vid:CB);

    wm deiconify $win;
    raise $win;
    return;

  } else {
    set wbw($vid:CB) .s[incr wb(win)];
    set w [toplevel $wbw($vid:CB)];
    set wb($w) "$school_name";
    set wbk($w) "CB";
    set cb(name:$w) "$class_name";
    set cb(vid:$w) "$vid";
    set cb(kind:$w) "CB3";

    if [cb_get_content $w $class_name $vid] {
      cb_close $w 1;
      return;
    }

    lappend wb(allwin) "$vid:CB";
  }

  wm title $w "configuration of `$vid'";

  frame $w.f2;
  label $w.f2.title -textvariable "label(Parts)" -anchor c -relief flat;
  listbox $w.f2.parents -relief ridge -yscrollcommand "$w.f2.sb set" \
    -geometry 40x25;
  scrollbar $w.f2.sb -command "$w.f2.parents yview" -relief sunken;

  bind $w.f2.parents <1> \
    "%W select from \[set index \[%W nearest %y\]\];\
     cb_show_content $w $vid \$index";
  
  bind $w.f2.parents <Control-1> \
    "if {\[%W curselect\] != {}} {\
      sb_search $wb($w) \[lindex \[%W get \[%W curselect\]\] 0\];\
    }";
  
  bind $w.f2.parents <B1-Motion> {
  }

  frame $w.f3 -relief raised -bd 1;
  menubutton $w.f3.cb -textvariable "label(CB)" -menu $w.f3.cb.m;
  menu $w.f3.cb.m;

  proc cb_conf_cb_menu {w} {
    global label;

    delete_menu $w.f3.cb.m;

    $w.f3.cb.m add command -label "$label(Close)" -command "cb_close $w";
    $w.f3.cb.m add separator;
    $w.f3.cb.m add command -label "$label(Preference...)" \
      -command "preference $w";
    $w.f3.cb.m add separator;
    $w.f3.cb.m add command -label "$label(Quit)" -command "quit";
  }

  cb_conf_cb_menu $w;

  menubutton $w.f3.window -textvariable "label(Window)" -menu $w.f3.window.m;
  menu $w.f3.window.m;

  tk_menuBar $w.f3 $w.f3.cb $w.f3.window;
  focus $w.f3;
  
  label $w.f3.name -text "$class_name" -relief ridge -anchor e;
  
  set i 4;
  foreach title {"Part #" "Implementation" "Public"} {
    frame $w.f$i -bd 1 -relief flat;
    label $w.f$i.title -textvariable "label($title)" \
	-anchor e -relief flat -width 15;
    entry $w.f$i.entry -state disabled -relief flat -cursor hand2;
    
    bind $w.f$i.entry <1> " ";
    bind $w.f$i.entry <B1-Motion> " ";

    incr i;
  }

  frame $w.f$i -bd 2 -relief ridge;
  label $w.f$i.title -textvariable "label(Allocation Info.)" -relief flat;
  incr i;

  foreach title {"Data" "Pointer" "Zero"} {
    frame $w.f$i -bd 1 -relief flat;
    label $w.f$i.title0 -textvariable "label($title)" -anchor e \
      -width 10 -relief flat;
    entry $w.f$i.entry0 -state disabled -relief flat -cursor hand2;
    label $w.f$i.title1 -text "/" -anchor c -relief flat;
    entry $w.f$i.entry1 -state disabled -relief flat -cursor hand2;

    bind $w.f$i.entry0 <1> " ";
    bind $w.f$i.entry0 <B1-Motion> " ";

    bind $w.f$i.entry1 <1> " ";
    bind $w.f$i.entry1 <B1-Motion> " ";

    incr i;
  }

  frame $w.f$i -bd 2 -relief ridge;
  label $w.f$i.title -textvariable "label(Methods)" \
	-anchor e -relief flat -width 10;
  entry $w.f$i.entry -state disabled -relief flat -cursor hand2;

  bind $w.f$i.entry <1> " ";
  bind $w.f$i.entry <B1-Motion> " ";

  incr i;

  frame $w.f$i;
  listbox $w.f$i.slot -relief flat -geometry 3x20 \
    -exportselection no -bd 0;
  listbox $w.f$i.vid -relief flat -geometry 18x20 \
    -exportselection no -yscrollcommand "scroll_set slot func" -bd 0;
  listbox $w.f$i.func -relief flat -geometry 3x20 \
    -exportselection no -bd 0;

  foreach item "slot vid func" {
    bind $w.f$i.$item <B1-Motion> " ";

    bind $w.f$i.$item <1> \
      "set index \[%W nearest %y\];\
       foreach item {slot vid func} {\
	 $w.f$i.\$item select from \$index;\
       }";
  }

  proc scroll_methods {index} \
    "$w.f$i.slot yview \$index;\
       $w.f$i.vid yview \$index;\
       $w.f$i.func yview \$index";
  
  scrollbar $w.f$i.sb -command "scroll_methods" -relief sunken;

  bind $w.f$i.slot <B2-Motion> " ";
  bind $w.f$i.func <B2-Motion> " ";

  proc scroll_set {o1 o2 a1 a2 a3 a4} \
    "eval $w.f$i.sb set \$a1 \$a2 \$a3 \$a4;\
       eval $w.f$i.\$o1 yview \$a3;\
       eval $w.f$i.\$o2 yview \$a3;";

  pack $w.f3 -fill x;
  pack $w.f3.cb $w.f3.window -side left -ipadx 5 -ipady 3;
  pack $w.f3.name -expand 1 -fill x -pady 3 -ipady 1 -padx 5;

  pack $w.f2 -side left -fill both -expand yes;
#  pack $w.f2.title -side top -fill x;
  pack $w.f2.sb -side right -fill y;
  pack $w.f2.parents -side top -fill both -expand 1;

  for {set i 4} {$i < 7} {incr i} {
    pack $w.f$i -fill x;
    pack $w.f$i.title -side left;
    pack $w.f$i.entry -side left -fill x -expand yes -padx 3;
  }

  pack $w.f$i -fill x -pady 3 -ipady 3 -padx 5;
  pack $w.f$i.title -fill both;
  incr i;

  for {} {$i < 11} {incr i} {
    pack $w.f$i -fill x;
    pack $w.f$i.title0 -side left;
    pack $w.f$i.entry0 -side left -fill both -expand 1 -padx 3;
    pack $w.f$i.title1 -side left;
    pack $w.f$i.entry1 -side left -fill both -expand 1 -padx 3;
  }

  pack $w.f$i -fill x  -pady 3 -ipady 3 -padx 5;
  pack $w.f$i.title -side left -fill y;
  pack $w.f$i.entry -side left -fill both -expand 1 -padx 3;
  incr i;

  pack $w.f$i -fill both -expand 1;
  pack $w.f$i.slot -side left -fill y;
  pack $w.f$i.vid -side left -fill both -expand 1;
  pack $w.f$i.func -side left -fill y;
  pack $w.f$i.sb -side right -fill y;

  set_center $w;
  set_expandable $w;

  set_all_windows $w "$vid ($class_name)";

  cb_conf_show_parents $w $class_name $vid;
}

proc cb_new_win {school_name class_name vid part} {
  global wb wbw cb wbk;

  if ![info exists wbw($school_name:CB)] {
    set w [set wbw($school_name:CB) .s[incr wb(win)]];
    set wb($w) "$school_name";
    set wbk($w) "CB";
    set cb($school_name) 0;
  } else {
    set w $wbw($school_name:CB);
  }

  incr cb($school_name);

  if ![info exists wbw($school_name:SB)] {
    sb_new_win $school_name "";
  }

  set k [write_to_cfed $w sb '$class_name' 8];

  puts_for_debug $k;

  if {$k && $k != 8 && $part != "configuration"} {
    set part "implementation";
  }

  if !$wb(boot) {
    set wb(result:$w) -1;
    SendOZ "SearchClass:$school_name|CB|$vid";
    tkwait variable wb(result:$w);

    if $wb(result:$w) return;
  }

  switch $part {
    implementation {
      cb_src_new_win $school_name $class_name $vid;
    }
    configuration {
      cb_conf_new_win $school_name $class_name $vid;
    }
    default {
      cb_if_new_win $school_name $class_name $vid $part;
    }
  }
}

proc cb_close {w {nomenu 0}} {
  global wb cb wbw wbk;

  set sn $wb($w);

  if {[incr cb($sn) -1] < 1} {
    wb_close $wbw($sn:CB);
  }

  set kind $wbk($w);
  set vid $cb(vid:$w);
  set name "$cb(name:$w)";

  if !$nomenu {
    delete_from_windows $wbw($vid:$kind) "$vid ($name)";
  }

  destroy $w;
  unset wbw($vid:$kind);
}

