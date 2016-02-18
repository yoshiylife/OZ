# 
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a UI for School Browser
#

global sb;

set sb(part:4) public;
set sb(part:5) protected;
set sb(part:6) implementation;
set sb(part:7) configuration;

# Global functions

proc OpenSB {school_name {school_file ""} {temp 0}} {
  global sb;

  sb_new_win $school_name $school_file;

  if $temp {
    set sb($school_name) $school_file;
  } else {
    set sb($school_name) "";
  }
}

# Local functions

proc sb_add_entry {w list} {
  global sb;
  
  set name [lindex $list 0];
  set k [lindex $list 1];

  if {[string first "<" $name] > 0} {
    incr k 100;
  } 

  if {$sb(scanmode:$w) == $k && [lsearch -exact $sb(names:$w) "$name"] < 0} {
    set notshow 0;
    if {$k >= 100} {
      regsub "<.*" "$name" "" buf;
      set buf [lindex [write_to_cfed $w sb $buf 12] 0];
      if {[lsearch -exact $sb(names:$w) $buf] < 0} {
	set notshow 1;
      }
    }

    if !$notshow {
      set sb(names:$w) [lsort [lappend sb(names:$w) $name]];
      set p [lsearch -exact $sb(names:$w) "$name"];
      $w.f2.names insert $p $name;
    }
  }

  write_to_cfed $w sb '$name' 10 [lindex $list 1] [lrange $list 2 end];
  write_to_cfed $w save;
}

proc sb_update {w school_name name kind vid} {
  global wbw sb;

  set notshow 0;

  if ![info exist wbw($school_name:SB)] {
    set notshow 1;
  }

  if !$notshow {
    set k $kind;
    
    set w $wbw($school_name:SB);

    if {[string first "<" $name] > 0} {
      incr k 100;
    } 
    
    if {$sb(scanmode:$w) != $k || \
	  [set p [lsearch -exact $sb(names:$w) "$name"]] >= 0} {
      set notshow 1;
    }
  
    if {$k >= 100} {
      regsub "<.*" "$name" "" buf;
      
      if {[lsearch -exact $sb(names:$w) \
	   [lindex [write_to_cfed $w sb $buf 12] 0]] < 0} {
	set notshow 1;
      }
    }

    if !$notshow {
      set sb(names:$w) [lsort [lappend sb(names:$w) $name]];
      set p [lsearch -exact $sb(names:$w) "$name"];
      $w.f2.names insert $p $name;
    }
  }

#  puts_for_debug $vid;

  write_to_cfed $w sb '$name' 10 $kind $vid;

#  puts_for_debug [write_to_cfed $w sb '$name'];
}

proc sb_save {w} {
  global wb;

  set name [$w.f1.value get];
  
  switch [$w.f2.value get] {
    "class" {
      set kind 0;
    }
    "shared" {
      set kind 5;
    }
    "static class" {
      set kind 6;
      }
    "record" {
      set kind 7;
    }
    "abstract class" {
      set kind 8;
    }
  }
  set public_vid [$w.f4.value get];
  set protected_vid [$w.f5.value get];
  set private_vid [$w.f6.value get];
  set ccid [$w.f7.value get];

  set win [winfo parent $w];
  
  sb_add_entry $win [list "$name" $kind \
		     $public_vid $protected_vid $private_vid $ccid];
}

proc sb_edit_cancel {w} {
  global label wb;

  sb_set_mode [winfo parent $w] cancel;

  $w.f3.edit configure -command "sb_edit $w";
  $w.f3.f0.done configure -command "destroy $w";

  if $wb(boot) {
    $w.f1.value configure -state disabled;
    $w.f2.value configure -state disabled;
    $w.f4.value configure -state disabled;
    $w.f5.value configure -state disabled;
    $w.f6.value configure -state disabled;
  }
}

proc sb_set_mode {w {mode {}}} {
  global label sb;

  if {$mode != ""} {
    set sb(mode:$w) $mode;
  }

  set label(Edit:SB) "$label(Edit:$sb(mode:$w))";
  set label(Close:SB) "$label(Close:$sb(mode:$w))";
}

proc sb_edit {w} {
  global wb sb label;

  sb_set_mode [winfo parent $w] edit;

  $w.f3.edit configure -command "sb_save $w";
  $w.f3.f0.done configure -command "sb_edit_cancel $w";

  if [winfo exists $w.other] {
    $w.other.f2.select configure -state normal;
  }

  if !$wb(boot) {

  } else {
    $w.f1.value configure -state normal;
    $w.f2.value configure -state normal;
    $w.f4.value configure -state normal;
    $w.f5.value configure -state normal;
    $w.f6.value configure -state normal;
  }
}

proc sb_add_files {files arg} {
  global wb label;

  set win [lindex $arg 0];
  set id [lindex $arg 1];

  if [catch { exec cp $files $wb(cpath)/$id }] {
    tk_dialog $win.info "info." "$label(cannot add msg)" info 0 "$label(Close)";
     
  } else {
    if !$wb(boot) {
      foreach i $files {
	SendOZ "AddProperty:$id|[file tail $i]";
      }
    }
  }
}

proc sb_add_property {win} {
  global wb;

  set k [$win.f2.value get];

  set kind "$wb(kind:$k)"

  if {!$kind || $kind == 8} {
    set id [$win.f6.value get];
  } else {
    set id [$win.f4.value get];
  }

  my_file_selector $win.fsel sb_add_files "$win $id" $wb(pwd) file * {} 0; 
  tkwait window $win.fsel
}

proc sb_remove_files {files arg} {
  global label;

  set win [lindex $arg 0];
  set id [lindex $arg 1];

  tk_dialog $win.info "info." \
    "$label(remove property msg)" question 1 "$label(Yes)" "$label(No)";

  set error 0;

  foreach i $files {
    if {[string first "$id" "$i"] >= 0 && [string first "private." "$i"] < 0} {
      exec rm $i;
    } else {
      set error 1;
    }
  }

  if $error {
    tk_dialog .info "info." "$label(cannot remove msg)" info 0 "$label(Close)";
  }

  scan_dir $win.fsel;
}

proc sb_show_property {win} {
  global wb fs;
  
  set k [$win.f2.value get];

  set kind "$wb(kind:$k)"

  if {!$kind || $kind == 8} {
    set id [$win.f6.value get];
  } else {
    set id [$win.f4.value get];
  }

  if [info exists fs(dir)] {
    set buf $fs(dir);
    unset fs(dir);
  }
  my_file_selector $win.fsel sb_remove_files "$win $id" \
    $wb(cpath)/$id file * {} 0; 
  tkwait window $win.fsel
  if [info exists buf] {
    set fs(dir) $buf;
  } else {
    unset fs(dir);
  }
}

proc sb_pack {win names} {
  global sb wb label;

  set w [winfo parent $win];
  set plist $names;
  set sb(plistid:$w) [write_to_cfed $w sb $plist 0];

  for {set i 0} {$i < [llength $plist]} {incr i} {
    set buf [write_to_cfed $w instantiate [lindex $plist $i]];

#    puts_for_debug $buf;

    foreach j $buf {
      if {[lsearch -exact $sb(plistid:$w) $j] >= 0} continue;

      set name [write_to_cfed $w sb $j];

      if {[lsearch -exact $plist $name] >= 0} continue;

#      puts_for_debug $name;

      lappend plist $name;
      lappend sb(plistid:$w) $j;
    }
  }

  set win [toplevel $w.pack];
  wm title $win "Package";

  frame $win.f0 -relief ridge -bd 2;
  scrollbar $win.f0.sb -relief sunken -command "$win.f0.classes yview";
  listbox $win.f0.classes -yscrollcommand "$win.f0.sb set" \
      -exportselection no -geometry 20x10;

  bind $win.f0.classes <Double-ButtonPress-1> \
    "if {\[%W curselect\] != {}} {\
      sb_search $wb($w) \[lindex \[%W get \[%W curselect\]\] 0\];\
    }";

  frame $win.f1 -relief ridge -bd 2;
  scrollbar $win.f1.sb -relief sunken -command "$win.f1.classes yview";
  listbox $win.f1.classes -yscrollcommand "$win.f1.sb set" \
      -exportselection no -geometry 20x10;

  bind $win.f1.classes <Double-ButtonPress-1> \
    "if {\[%W curselect\] != {}} {\
      sb_search $wb($w) \[lindex \[%W get \[%W curselect\]\] 0\];\
    }";


  frame $win.f2;
  button $win.f2.now -textvariable "label(Now)" -bd 1 \
    -command "sb_create_package $w $names; destroy $win";
  button $win.f2.default -textvariable "label(Default)" -bd 1 \
    -command "set sb(plistid:$w) {}; sb_create_package $w $names; destroy $win";
  button $win.f2.cancel -textvariable "label(Cancel)" -bd 1 \
    -command "destroy $win";

  pack $win.f0 -fill both -expand yes -padx 10 -pady 5;
  pack $win.f0.sb -side right -fill y;
  pack $win.f0.classes -side left -expand 1 -fill both;

  pack $win.f1 -fill both -expand yes -padx 10 -pady 5;
  pack $win.f1.sb -side right -fill y;
  pack $win.f1.classes -side left -expand 1 -fill both;

  pack $win.f2 -fill x -expand yes -pady 5;
  pack $win.f2.cancel $win.f2.default $win.f2.now \
    -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  foreach i [lsort $names] {
    $win.f0.classes insert end $i;
  }

  foreach i [lsort $plist] {
    $win.f1.classes insert end $i;
  }

  grab set $win;

  proc sb_create_package {w names} {
    global sb wbw env;

    set kinds {};
    set pvids {};

    foreach i [lsort $names] {
      lappend kinds "[write_to_cfed $w sb '$i' 8]";
      lappend pvids "[write_to_cfed $w sb '$i' 0]";
    }

    set name [wb_input_school_name_once $wbw(WB)];

    if {$name == ""} return;

    SendOZ "CreatePackage:$name|$names|$kinds|$pvids|$sb(plistid:$w)";
  }
}

proc sb_show_list {w {real 0}} {
  global sb wb;
  
  set sn $wb($w);
  
  set f $wb(cfed:$sn);

#  wm withdraw $w;
  
#  catch { removeinput $wb(cfed:$sn) }

  if {!$real || $sb(scanmode:$w) < 100} {
    set sb(names:$w) {}

    $w.f6.child configure -state disabled;

    write_to_cfed_nowait $w sb -k $sb(scanmode:$w);

    gets $f line;
    
    while {![is_success $line]} {
#    puts_for_debug $line;

      lappend sb(names:$w) $line;
      gets $f line;
    }

#  addinput -read $wb(cfed:$sn) "read_from_cfed $w %F";

    set len [llength $sb(names:$w)];
    set sb(names:$w) [lsort [lrange $sb(names:$w) 0 [expr $len - 2]]];
    
    $w.f2.names delete 0 end;
    foreach i $sb(names:$w) {
      $w.f2.names insert end $i;
    }
  } else {
    set buf [$w.f2.names get [$w.f2.names curselect]];
    regsub "<.*" "$buf" "" newbuf;
#    puts_for_debug "$buf $newbuf";
    write_to_cfed_nowait $w sb $newbuf 12;

    set reals {};

    gets $f line;
    
    while {![is_success $line]} {
#      puts_for_debug $line;

      lappend reals $line;
      gets $f line;
    }

    set reals [lsort $reals];

    if {[set p [lsearch -exact $sb(names:$w) [lindex $reals 0]]] >= 0} {
      foreach i $reals {
	set sb(names:$w) [lreplace $sb(names:$w) $p $p];
	$w.f2.names delete $p;
      }
    } else {
      set sb(names:$w) [lsort [concat $sb(names:$w) $reals]];

      set p [lsearch -exact $sb(names:$w) [lindex $reals 0]]

      foreach i $reals {
	$w.f2.names insert $p $i;
	incr p;
      }
    }
  }

#  wm deiconify $w;
  update idletasks;

  if {$sb(scanmode:$w) < 100} return;

  bind $w.f2.names <Control-Double-ButtonPress-1> \
    "%W select from \[set i \[%W nearest %y\]\]; sb_show_list $w 1"
}

proc sb_show_children {w} {
  global sb wb label;

  if {[set p [$w.f2.names curselect]] == ""} return;

  if [tk_dialog $w.query "Really ?" "$label(show children)" question 1 \
       "$label(Exec)" "$label(Cancel)"] {
    return;
  }

  $w.f6.names delete 0 end;

  grab set $w.f6.names;

  $w.f6.child configure -state disabled;
  update idletasks;

  set buf [lsort [write_to_cfed $w children [$w.f2.names get $p]]];

  foreach i $buf {
    $w.f6.names insert end $i;
  }

  grab release $w.f6.names;

  $w.f6.child configure -state normal;
}

proc sb_search {sn str} {
  global sb wbw;

  if [catch { set w $wbw($sn:SB) }] {
    sb_new_win $sn "";
    set w $wbw($sn:SB);
  }

  set str [string trim $str];
  
  if {![string first "0x" $str] || ![string first "0X" $str]} {

    set vid $str;

    set str [write_to_cfed $w sb '[string range $vid 2 end]'];
    
    if {$str == ""} {
      tk_dialog $w.notfound "Result" "Not found \"$vid\"" info 0 "Close";
      return;
    }
  }

  if {[set i [lsearch -exact $sb(names:$w) "$str"]] > -1} {
    $w.f2.names select from $i;
    $w.f2.names yview $i;

    sb_vids_win $w [$w.f2.names get $i];
    update idletasks;

  } elseif {[set i [lsearch -glob $sb(names:$w) "$str*"]] > -1} {
    $w.f2.names select from $i;
    $w.f2.names yview $i;

    sb_vids_win $w [$w.f2.names get $i];
    update idletasks;
    
  } else {
    tk_dialog $w.notfound "Result" "Not found \"$str\"" info 0 "Close";
  }
}

proc sb_search_win {w} {
  global label wb;

  if [winfo exists $w.search] {
    wm deiconify $w.search;
    raise $w.search;
    return;
  }

  set win [toplevel $w.search];

  wm title $win "Searching a class";

  frame $win.f1 -relief ridge -bd 2;
  label $win.f1.label -textvariable "label(Search)" -anchor w;
  entry $win.f1.sstr -relief ridge;

  mybind $win.f1.sstr <Control-h> \
    "if {\[$win.f1.sstr get\] == \"\"} \
      { $win.f2.f3.done configure -state disabled; \
	$win.f2.clear configure -state disabled }";

  mybind $win.f1.sstr <BackSpace> \
    "if {\[$win.f1.sstr get\] == \"\"} \
      { $win.f2.f3.done configure -state disabled; \
	$win.f2.clear configure -state disabled }";

  mybind $win.f1.sstr <Any-KeyPress> \
    "$win.f2.f3.done configure -state normal; \
	$win.f2.clear configure -state normal;"
  
  bind $win.f1.sstr <Return> "$win.f2.f3.done invoke";
  
  bind $win.f1.sstr <2> {
    catch { %W insert end [selection get] }; 
    set w [winfo toplevel %W];
    $w.f2.f3.done configure -state normal; 
    $w.f2.clear configure -state normal;
  }

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -textvariable "label(Exec)" -state disabled -bd 1 \
    -command "sb_search $wb($w) \[$win.f1.sstr get\]";
  button $win.f2.clear -textvariable "label(Clear)" -state disabled -bd 1 \
    -command "$win.f1.sstr delete 0 end; \
	$win.f2.f3.done configure -state disabled; \
	$win.f2.clear configure -state disabled; \
	focus $win.f1.sstr";
  button $win.f2.cancel -textvariable "label(Close)" -bd 1 \
    -command "destroy $win";

  pack $win.f1 -fill both -padx 10 -pady 10;
  pack $win.f1.label -fill both -expand yes  -padx 3 -pady 3;
  pack $win.f1.sstr -side left -expand 1 -fill x -padx 10 -pady 10 -ipady 5;

  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel $win.f2.clear \
    -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $win;
  set_expandable $win;

  focus $win.f1.sstr;
}

proc sb_other_win {w name part entry} {
  global sb wb wbk label;

  set current [$entry get];

  set wp [winfo parent $w];

  if [winfo exists $w.other] {
    set win $w.other;
  } else {
    set win [toplevel $w.other];
    wm title $win "Other versions of a class";

    frame $win.f0;
    label $win.f0.name -relief ridge -text "$name" -anchor w;
    label $win.f0.part -relief ridge -text "$part" -anchor w;

    frame $win.f1 -relief ridge -bd 2;
    scrollbar $win.f1.sb -relief sunken -command "$win.f1.vids yview";
    listbox $win.f1.vids -yscrollcommand "$win.f1.sb set" \
      -exportselection no -geometry 20x15;
    
    bind $win.f1.vids <1> \
      "%W select from \[set i \[%W nearest %y\]\];\
	sb_set_other_win_status $wp $win normal $part";
    
    bind $win.f1.vids <3> \
      "%W select clear;\
	sb_set_other_win_status $wp $win disabled $part";

    proc sb_set_other_win_status {w win mode part} {
      global sb;

      if {[set p [$win.f1.vids curselect]] == ""} {
	set mode disabled;
      } 

      $win.f2.f3.browse configure -state $mode;
      $win.f2.visible configure -state $mode;

      if {$part != "configuration" && \
	    $mode == "normal" && $sb(mode:$w) != "edit"} {
	$win.f2.select configure -state disabled;
      } else {
	$win.f2.select configure -state $mode;
      }

      set buf [$win.f1.vids get $p];

      if {$mode == "normal" && \
	    [string first "Default" $buf] >= 0} {
	$win.f2.default configure -state disabled;
      } else {
	$win.f2.default configure -state $mode;
      }


      if {$part == "configuration" || \
	    ($mode == "normal" && \
	     [llength $buf] > 1 && \
	     [string index [lindex $buf 1] 0] == "(")} {
	$win.f2.visible configure -state disabled;
      } else {
	$win.f2.visible configure -state $mode;
      }
    }
    
    bind $win.f1.vids <Double-ButtonPress-1> \
      "$win.f2.f3.browse invoke";
    
    bind $win.f1.vids <B1-Motion> {
    }
    
    frame $win.f2;
    frame $win.f2.f3 -relief sunken -bd 1;
    button $win.f2.f3.browse -textvariable "label(Browse...)" \
      -state disabled -bd 1 \
      -command \
	"cb_new_win $wb($wp) {$name} \
		\[lindex \"\[$win.f1.vids get \[$win.f1.vids curselect\]\]\" \
		0\] $part";
    button $win.f2.select -textvariable "label(Select)" \
      -state disabled -bd 1 \
	-command "sb_select $w $win $entry $part";
    button $win.f2.default -textvariable "label(Default)" \
      -state disabled -bd 1 \
	-command "sb_set_default $w $win $part";
    button $win.f2.visible -textvariable "label(Visible)" \
      -state disabled -bd 1 \
	-command "sb_set_visible $w $win";

    proc sb_set_default {w win part} {
      global sb;

      set p [$win.f1.vids curselect];

      set vid [lindex [$win.f1.vids get $p] 0];

      if {$part != "configuration"} {
	SendOZ "ChangeDefaultVersion:$vid";
      } else {
	SendOZ "ChangeDefaultConfiguration:$vid";
      }

      if [info exists sb(default:$win)] {
	set buf [$win.f1.vids get $sb(default:$win)];
	$win.f1.vids delete $sb(default:$win);
	regsub Default "$buf" "" newbuf;
	$win.f1.vids insert $sb(default:$win) $newbuf;
      }

      set sb(default:$win) $p;

      set buf [$win.f1.vids get $sb(default:$win)];
      $win.f1.vids delete $sb(default:$win);
      lappend buf "Default";
      $win.f1.vids insert $sb(default:$win) $buf;

      $win.f1.vids select from $p;
    }

    proc sb_set_visible {w win} {
      global wb;

      set wp [winfo parent $w];

      set p [$win.f1.vids curselect];

      set vid [$win.f1.vids get $p];

      SendOZ "ChangeVisible:$wb($wp)|SB|[lindex $vid 0]";

      tkwait variable wb(result:$wp);

      $win.f1.vids delete $p;
      $win.f1.vids insert $p [linsert $vid 1 "($wb(result:$wp))"];

      $win.f1.vids select from $p;
      $win.f2.visible configure -state disabled;
    }

    proc sb_select {w win entry part} {
      global wb wbk sb;

      set p [$win.f1.vids curselect];
      set vid [lindex [$win.f1.vids get $p] 0];

      $entry configure -state normal;
      $entry delete 0 end;
      $entry insert end $vid;
      $entry configure -state disabled;

      set wp [winfo parent $w];

      if {$part == "public" || $part == "protected"} {
	SendOZ "ShowDefaultVersions:$wb($wp)|$wbk($wp)|$vid";

	tkwait variable wb(result:$wp);

	set j 5;
	foreach i $wb(result:$wp) {
	  $w.f$j.value configure -state normal;
	  $w.f$j.value delete 0 end;
	  $w.f$j.value insert end [lindex $i 0];
	  $w.f$j.value configure -state disabled;
	  incr j;
	}
	
	if {$part == "public" && !$wb(boot)} {
	  SendOZ "ShowDefaultConfiguration:$wb($wp)|SB|$vid";
	  
	  tkwait variable wb(result:$wp);
	  
	  $w.f7.value configure -state normal;
	  $w.f7.value delete 0 end;
	  $w.f7.value insert end $wb(result:$wp);
	  $w.f7.value configure -state disabled;
	}

	set name [$w.f1.value get];
	set vids [write_to_cfed $wp sb '$name' 5];

	if {[llength $vids] == 4} {
	  set vids [lreplace $vids 0 0];
	}

	if {$part == "public"} {
	  set vids "$vid [lindex $vids 1] [lindex $vids 2]";
	} else {
	  set vids "[lidnex $vids 0] $vid [lindex $vids 2]";
	}

	set kind [write_to_cfed $wp sb '$name' 8];

#	puts_for_debug "$name $kind $vids";

	write_to_cfed $wp sb '$name' 10 $kind $vids;

      } elseif {$part == "implementation"} {
	set buf [lindex [$win.f1.vids get $sb(select:$win)] 0];
	set name [write_to_cfed $wp sb $buf 7];
	set kind [write_to_cfed $wp sb '$name' 8];

	set vids [write_to_cfed $wp sb '$name' 5];

	if {[llength $vids] == 4} {
	  set vids [lreplace $vids 0 0];
	}

	set vids "[lindex $vids 0] [lindex $vids 1] $vid";

#	puts_for_debug "$name $kind $vids";

	write_to_cfed $wp sb '$name' 10 $kind $vids;
	
      } elseif {$part == "configuration"} {
	SendOZ "SetConfiguration:[$w.f4.value get]|$vid";

	set name [$w.f1.value get];
	write_to_cfed $wp sb '$name' 9 $vid;
      }

      write_to_cfed $wp save;

      if [info exists sb(select:$win)] {
	set buf [$win.f1.vids get $sb(select:$win)];
	$win.f1.vids delete $sb(select:$win);
	regsub Selected "$buf" "" newbuf;
	$win.f1.vids insert $sb(select:$win) $newbuf;
      }

      set sb(select:$win) $p;

      set buf [$win.f1.vids get $sb(select:$win)];
      $win.f1.vids delete $sb(select:$win);
      lappend buf "Selected";
      $win.f1.vids insert $sb(select:$win) $buf;

      $win.f1.vids select from $p;
    }
    
    button $win.f2.cancel -textvariable "label(Close)" -bd 1 \
      -command "destroy $win";

    pack $win.f0 -fill x;
    pack $win.f0.name $win.f0.part \
      -padx 10 -pady 5 -ipadx 5 -ipady 3 -fill x -expand yes;

    pack $win.f1 -fill both -expand yes -padx 10 -pady 10;
    pack $win.f1.sb -side right -fill y;
    pack $win.f1.vids -side left -expand 1 -fill both;

    pack $win.f2 -fill x -expand yes;
    pack $win.f2.f3 -side left -ipadx 5 -padx 10 -pady 5;
    pack $win.f2.f3.browse -ipadx 15 -ipady 5 -pady 5 -anchor c;
    pack $win.f2.cancel $win.f2.default $win.f2.visible $win.f2.select \
      -side right -ipadx 5 -ipady 5 -padx 10 -pady 5;
  }

  wm withdraw $win;

  if {$part != "configuration"} {
    SendOZ "ShowOtherVersions:$wb($wp)|$wbk($wp)|$current";

  } else {
    SendOZ "ShowOtherConfigurations:$wb($wp)|$wbk($wp)|[$w.f4.value get]";
  }

  tkwait variable wb(result:$wp);

  set default [lindex $wb(result:$wp) 0];
  set vids [lrange $wb(result:$wp) 1 end];

  $win.f1.vids delete 0 end;

  if [info exists sb(default:$win)] {
    unset sb(default:$win);
  }

  set j 0;
  foreach i $vids {
    set vid [lindex $i 0];

    if {[llength $i] > 1} {
      set i "$vid ([lindex $i 1])";
    }

    if ![string compare $vid "$default"] {
      append i " Default";
      set sb(default:$win) $j;
    }

    if ![string compare $vid "$current"] {
      append i " Selected";
      set sb(select:$win) $j;
    } 

    $win.f1.vids insert end $i;
    incr j;
  }

  set_expandable $win;
  set_center $win;
  wm deiconify $w.other;
  raise $w.other;
}

proc sb_vids_win {w {name {}}} {
  global label wb sb;

  if [winfo exists $w.vids] {
    set win $w.vids;
    wm deiconify $w.vids;
    raise $w.vids;
  } else {
    set win [toplevel $w.vids];
    wm title $win "Versions of a class";

    if {$wb(lang) == "english"} {
      set len [string length $label(Implementation)];
    } else {
      set len 20;
    }

    frame $win.f4 -relief ridge -bd 2;
    button $win.f4.vid -textvariable "label(Public)" -width $len -anchor e \
      -relief flat -command \
	"cb_new_win $wb($w) \
		\[$w.f2.names get \[$w.f2.names curselect\]\] \
		\[$win.f4.value get\] public";
    entry $win.f4.value -state disabled -cursor top_left_arrow;
    button $win.f4.other -textvariable "label(Other...)" -relief flat \
      -command "sb_other_win $win {$name} public $win.f4.value";

    frame $win.f5 -relief ridge -bd 2;
    button $win.f5.vid -textvariable "label(Protected)" -width $len -anchor e \
      -relief flat -command \
	"cb_new_win $wb($w) \
		\[$w.f2.names get \[$w.f2.names curselect\]\] \
		\[$win.f5.value get\] protected";
    entry $win.f5.value -state disabled -cursor top_left_arrow;
    button $win.f5.other -textvariable "label(Other...)" -relief flat \
      -command "sb_other_win $win {$name} protected $win.f5.value";

    bind $win.f5.value <2> {
      catch { %W insert insert [selection get]; }
    }
    
    frame $win.f6 -relief ridge -bd 2
    button $win.f6.vid -textvariable "label(Implementation)" \
      -width $len -anchor e -relief flat -command \
	"cb_new_win $wb($w) \
		\[$w.f2.names get \[$w.f2.names curselect\]\] \
		\[$win.f6.value get\] implementation";

    entry $win.f6.value -state disabled -cursor top_left_arrow;
    button $win.f6.other -textvariable "label(Other...)" -relief flat \
      -command "sb_other_win $win {$name} implementation $win.f6.value";

    bind $win.f6.value <2> {
      catch { %W insert insert [selection get]; }
    }
    
    frame $win.f7 -relief ridge -bd 2;
    button $win.f7.vid -textvariable "label(Configuration)" \
      -width $len -anchor e -relief flat -command \
	"cb_new_win $wb($w) \
		\[$w.f2.names get \[$w.f2.names curselect\]\] \
		\[$win.f7.value get\] configuration";
    entry $win.f7.value -state disabled -cursor top_left_arrow;
    button $win.f7.other -textvariable "label(Other...)" -relief flat \
      -command "sb_other_win $win {$name} configuration $win.f7.value";

    bind $win.f7.value <2> {
      catch { %W insert insert [selection get]; }
    }

    if $wb(boot) {
      $win.f4.other configure -state disabled;
      $win.f5.other configure -state disabled;
      $win.f6.other configure -state disabled;
      $win.f7.other configure -state disabled;
    }

    frame $win.f1 -relief ridge -bd 2;
    label $win.f1.name -textvariable "label(Classname)" -width $len -anchor e;
    entry $win.f1.value -state disabled -cursor top_left_arrow;

    bind $win.f1.value <2> {
      catch { %W insert insert [selection get]; }
    }

    frame $win.f2 -relief ridge -bd 2;
    label $win.f2.kind -textvariable "label(Kind)" -width $len -anchor e;
    entry $win.f2.value -state disabled -cursor top_left_arrow;

    bind $win.f2.value <2> {
      catch { %W insert insert [selection get]; }
    }

    frame $win.f3;
    frame $win.f3.f0 -relief sunken -bd 1;
    button $win.f3.f0.done -textvariable label(Close:SB) \
      -bd 1 -command "destroy $win";
    button $win.f3.edit -textvariable label(Edit:SB) \
      -bd 1 -command "sb_edit $win";
    button $win.f3.pack -textvariable label(Pack) \
      -bd 1 -command "sb_pack $win \[$win.f1.value get\]";
    menubutton $win.f3.property -textvariable label(Property) \
      -bd 1 -menu $win.f3.property.m -relief raised;


    menu $win.f3.property.m;
    $win.f3.property.m add command -label "$label(Add Property)" \
      -command "sb_add_property $win";
    $win.f3.property.m add command -label "$label(Show Property)" \
      -command "sb_show_property $win";
    
    pack $win.f1 $win.f2 $win.f4 $win.f5 $win.f6 $win.f7 \
      -padx 5 -pady 5 -fill x;
    pack $win.f1.name $win.f2.kind \
      $win.f4.vid $win.f5.vid $win.f6.vid $win.f7.vid -side left \
      -ipadx 5 -ipady 3 -pady 3 -padx 5;
    pack $win.f1.value $win.f2.value \
      $win.f4.value $win.f5.value $win.f6.value $win.f7.value -side left \
      -fill x -expand yes -ipadx 5 -ipady 3 -pady 3 -padx 5;
    pack $win.f4.other $win.f5.other $win.f6.other $win.f7.other -side left \
      -ipadx 5 -ipady 3 -pady 3 -padx 5;
    
    pack $win.f3 -fill x -expand yes;
    pack $win.f3.f0 -side right -ipadx 5 -pady 5 -padx 20;
    pack $win.f3.f0.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
    pack $win.f3.edit $win.f3.property $win.f3.pack \
      -side left -ipadx 5 -ipady 5 -padx 20 -pady 5;

    set_center $win;
  }

  if {$name == ""} {
    $win.f3.edit invoke;
    focus $win.f1.value;
    return;
  }
   
  set f $wb(cfed:$wb($w));

  set k [write_to_cfed $w sb '$name' 8];

#  puts_for_debug "$name $k";
  
  if [catch { set kind "$wb(kind:$k)" }] {
    return;
  }
  
  $win.f1.value configure -state normal;
  $win.f1.value delete 0 end;
  $win.f1.value insert end "$name";
  $win.f1.value configure -state disabled;
  
  $win.f2.value configure -state normal;
  $win.f2.value delete 0 end;
  $win.f2.value insert end "$kind";
  $win.f2.value configure -state disabled;
  
  bind $win.f4.value <2> {
    catch { %W insert insert [selection get]; }
  }
  
  if {$k == 0 || $k == 8} {
    $win.f5.vid configure -state normal;
    $win.f6.vid configure -state normal;
  } else {
    $win.f5.vid configure -state disabled;
    $win.f6.vid configure -state disabled;
  }
  

  if {$k != 5 && $k != 7} {
    $win.f7.vid configure -state normal;
  } else {
    $win.f7.vid configure -state disabled;
  }
  
  set j 0;
  set i 4;
  
  set vids "[write_to_cfed $w sb '$name']";
  
  if ![string compare [lindex $vids 0] "0"] {
    tk_dialog $w.caution Caution "Don't click twice !" info 0 Close;
    return;
  }
  
  $win.f$i.value configure -state normal;
  $win.f$i.value delete 0 end;
  $win.f$i.value insert end [lindex $vids $j];
  $win.f$i.value configure -state disabled;
  incr j;
  
  if {$k == 0 || $k == 8} {
    for {incr i} {$i < 7} {incr i} {
      $win.f$i.value configure -state normal;
      $win.f$i.value delete 0 end;
      $win.f$i.value insert end [lindex $vids $j];
      $win.f$i.value configure -state disabled;
      incr j;
    }
  }
  
  if {$k != 5 && $k != 7} {
    if $wb(boot) {
      set ccid "[write_to_cfed $w sb '$name' 3]";
    } else {
      set ccid "[write_to_cfed $w sb '$name' 3]";

#      puts_for_debug $ccid;

      if ![string length $ccid] {
	SendOZ "ShowDefaultConfiguration:$wb($w)|SB|[lindex $vids 0]";
	
	tkwait variable wb(result:$w);
      
	set ccid $wb(result:$w);
      }
    }
    $win.f7.value configure -state normal;
    $win.f7.value delete 0 end;
    $win.f7.value insert end [lindex $ccid 0];
    $win.f7.value configure -state disabled;

    if ![string length $ccid] {
      $win.f7.vid configure -state disabled;
    }
  }
}

proc sb_add_suffix {w name} {
  global sb;

  set i 0;

  while {1} {
    set buf [format "%s_%s" "$name" $i];
    
    if {[lsearch -exact $sb(names:$w) "$buf"] < 0} {
      return $buf;
    }
    incr i;
  }
}

proc sb_new_win {school_name school_file} {
  global wb wbw label env wbk sb;

  if [info exists wbw($school_name:SB)] {
    set win $wbw($school_name:SB);
    wm deiconify $win;
    raise $win;
    return;

  } else {
    set wbw($school_name:SB) .s[incr wb(win)];
    lappend wb(allwin) "$school_name:SB";
    set w [toplevel $wbw($school_name:SB)];
    set wb($w) "$school_name";
    set wbk($w) "SB";
    sb_set_mode $w cancel;
  }

  wm title $w "OZ++ School Browser : $school_name";

  frame $w.f3 -relief raised -bd 1;

  menubutton $w.f3.school -textvariable "label(SB)" -menu $w.f3.school.m;
  menu $w.f3.school.m;

  proc sb_school_menu {w} {
    global wb label sb;

    delete_menu $w.f3.school.m;

    if !$wb(boot) {
      $w.f3.school.m add command -label "$label(Open)" -command "wb_open SB";
    }

    $w.f3.school.m add command -label "$label(Close)" -command "wb_close $w";
    $w.f3.school.m add separator;
    $w.f3.school.m add command -label "$label(Preference...)" \
      -command "preference $w";
    $w.f3.school.m add separator;
    $w.f3.school.m add command -label "$label(Quit)" -command "quit";
  }

  sb_school_menu $w;

  menubutton $w.f3.ops -textvariable "label(Ops)" -menu $w.f3.ops.m;
  menu $w.f3.ops.m;

  proc sb_ops_menu {w} {
    global label sb;

    delete_menu $w.f3.ops.m;

    $w.f3.ops.m add command -label "$label(Cut)" \
      -command "sb_cut $w" -state disabled;
    $w.f3.ops.m add command -label "$label(Copy)" \
      -command "sb_copy $w" -state disabled;
    $w.f3.ops.m add command -label "$label(Paste)" \
      -command "sb_paste $w";
#    $w.f3.ops.m add command -label "$label(Delete)" \
#      -command "sb_delete $w" -state disabled;
#    $w.f3.ops.m add separator;
#    $w.f3.ops.m add command -label "$label(New...)" \
#      -command "sb_vids_win $w";
    $w.f3.ops.m add separator;
    $w.f3.ops.m add command -label "$label(Search...)" \
      -command "sb_search_win $w";
#    $w.f3.ops.m add command -label "$label(Versions...)" \
#      -command "sb_vids_win $w";

    if ![info exists sb(select)] {
      $w.f3.ops.m disable $label(Paste);
    }
  }

  sb_ops_menu $w;

  proc sb_copy {w} {
    global sb label;

    set sb(select) {};

    foreach i [$w.f2.names curselect] {
      set buf [$w.f2.names get $i];
      lappend sb(select) "{$buf} [write_to_cfed $w sb '$buf' 8] \
	[join [write_to_cfed $w sb '$buf']]";
    }

    $w.f3.ops.m enable $label(Paste);
  }

  proc sb_delete {w} {
    global wb sb;

    set p [$w.f2.names curselect];
    set from [lindex $p 0];
    set to [lindex $p [expr [llength $p] - 1]];
    $w.f2.names delete $from $to;
    set buf [lrange $sb(names:$w) $from $to];
    set sb(names:$w) [lreplace $sb(names:$w) $from $to];

    foreach i $buf {
      write_to_cfed $w sb '$i' 11;
    }

    write_to_cfed $w save;
  }

  proc sb_cut {w} {
    sb_copy $w;
    sb_delete $w;
  }

  proc sb_input_class_name {w old} {
    global close;

    sb_set_ops_state $w disable;

    set win [toplevel $w.input];

    wm title $win "Input a name of class...";

    frame $win.f1 -relief ridge -bd 2;
    label $win.f1.old -text "$old" -anchor w;
    label $win.f1.title -textvariable "label(New Classname)" -anchor w;
    entry $win.f1.className -width 30 -relief ridge;

    mybind $win.f1.className <Control-h> \
      "if {\[$win.f1.className get\] == \"\"} { $win.f2.f3.done configure -state disabled; }";
    
    mybind $win.f1.className <BackSpace> \
      "if {\[$win.f1.className get\] == \"\"} { $win.f2.f3.done configure -state disabled; }";

    mybind $win.f1.className <Any-KeyPress> \
      "$win.f2.f3.done configure -state normal;"
	
	bind $win.f1.className <Return> \
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
      
	set close 0;
      }
    button $win.f2.overwrite -textvariable "label(Overwrite)" -bd 1 \
      -command {
	global close;
      
	set close 1;
      }
    
    pack $win.f1 -fill both -padx 10 -pady 10;
    pack $win.f1.old -fill both -expand yes -padx 3 -pady 3;
    pack $win.f1.title -fill both -expand yes -padx 3 -pady 3;
    pack $win.f1.className -padx 10 -pady 10 -fill x -expand yes -ipady 5;
    
    pack $win.f2 -fill x -expand yes;
    pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
    pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
    pack $win.f2.overwrite -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;
    pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;
    
    set_center $win;
    
    focus $win.f1.className;
    tkwait variable close;
    
    set class_name [$win.f1.className get];
    
    destroy $win;
    
    sb_set_ops_state $w enable;
    
    if {$close != "done"} {
      return $close;
    }
    
    return $class_name;
  }

  proc sb_paste {w} {
    global sb wb;

    sb_set_ops_state $w disable;

    set selects {};
    foreach i $sb(select) {
      set name [lindex $i 0];
      set orig $name
      while {[write_to_cfed $w sb $name] != "not found"} {
	set name [sb_input_class_name $w $orig];

	if {$name == "0"} {
	  sb_set_ops_state $w enable
	  return;
	} elseif {$name == "1"} {
	  break;
	}
      }
      if {$name != "1"} {
	set i [lreplace $i 0 0 "$name"];
	puts_for_debug $i;
      }
      lappend selects $i;
    }

    $w.f2.names select clear;

    foreach i $selects {
      sb_add_entry $w $i;
    }

    sb_set_ops_state $w enable
  }
    
  menubutton $w.f3.window -textvariable "label(Window)" -menu $w.f3.window.m;
  menu $w.f3.window.m;

  tk_menuBar $w.f3 $w.f3.school $w.f3.ops $w.f3.window;
  focus $w.f3;

  frame $w.f4;
  label $w.f4.title -text "Normal" -width 10;
  radiobutton $w.f4.class -text "class" -value 0 -variable sb(scanmode:$w) \
    -relief flat -command "sb_show_list $w";
  radiobutton $w.f4.shared -text "shared" -value 5 -variable sb(scanmode:$w) \
    -relief flat -command "sb_show_list $w";
  radiobutton $w.f4.static -text "static class" -value 6 \
    -variable sb(scanmode:$w) -relief flat -command "sb_show_list $w";
  radiobutton $w.f4.record -text "record" -value 7 -variable sb(scanmode:$w) \
    -relief flat -command "sb_show_list $w";
  radiobutton $w.f4.abstract -text "abstract class" -value 8 \
    -variable sb(scanmode:$w) -relief flat -command "sb_show_list $w";

  frame $w.f5;
  label $w.f5.title -text "Generic" -width 10;
  radiobutton $w.f5.class -text "class" -value 100 -variable sb(scanmode:$w) \
    -relief flat -command "sb_show_list $w";
  radiobutton $w.f5.shared -text "shared" -value 105 -variable sb(scanmode:$w) \
    -relief flat -command "sb_show_list $w";
  radiobutton $w.f5.static -text "static class" -value 106 \
    -variable sb(scanmode:$w) -relief flat -command "sb_show_list $w";
  radiobutton $w.f5.record -text "record" -value 107 -variable sb(scanmode:$w) \
    -relief flat -command "sb_show_list $w";
  radiobutton $w.f5.abstract -text "abstract class" -value 108 \
    -variable sb(scanmode:$w) -relief flat -command "sb_show_list $w";

  set sb(scanmode:$w) 0;

  frame $w.f2;
  scrollbar $w.f2.sb -relief sunken -command "$w.f2.names yview";
  listbox $w.f2.names -yscrollcommand "$w.f2.sb set" -relief ridge \
    -exportselection no -geometry 80x25;

  bind $w.f2.names <1> \
    "%W select from \[set i \[%W nearest %y\]\]; sb_set_ops_state $w enable"

  bind $w.f2.names <Double-ButtonPress-1> \
    "%W select from \[set i \[%W nearest %y\]\];\
      sb_vids_win $w \[%W get \$i\]";
#    "tk_dialog $w.caution Caution \"Don't click twice !\" info 0 Close";

  bind $w.f2.names <3> \
    "%W select clear; sb_set_ops_state $w disable";

  frame $w.f6;
  scrollbar $w.f6.sb -relief sunken -command "$w.f6.names yview";
  listbox $w.f6.names -yscrollcommand "$w.f6.sb set" -relief ridge \
    -exportselection no -geometry 80x8;

  bind $w.f6.names <Double-ButtonPress-1> \
    "%W select from \[set i \[%W nearest %y\]\];\
      sb_vids_win $w \[%W get \$i\]";

  bind $w.f6.names <3> "%W select clear;";

  button $w.f6.child -textvariable "label(Children)" \
    -relief flat -state disabled -command "sb_show_children $w";

  proc sb_set_ops_state {w status} {
    global label sb;

    $w.f3.ops.m $status $label(Copy);
    $w.f3.ops.m $status $label(Cut);

    if {$status == "enable" && \
	  (![set m [expr $sb(scanmode:$w) % 100]] || $m == 8)} {
      $w.f6.child configure -state normal;
    } 
  }
  
  pack $w.f3 -fill x;
  pack $w.f3.school $w.f3.ops $w.f3.window -side left -ipadx 5 -ipady 3;
  pack $w.f4 -fill x -expand 1;
  pack $w.f4.title $w.f4.class $w.f4.shared $w.f4.static $w.f4.record \
    $w.f4.abstract -side left -ipadx 5 -ipady 3;
  pack $w.f5 -fill x -expand 1;
  pack $w.f5.title $w.f5.class $w.f5.shared $w.f5.static $w.f5.record \
    $w.f5.abstract -side left -ipadx 5 -ipady 3;
  pack $w.f2 -fill both -expand 1;
  pack $w.f2.sb -side right -fill y;
  pack $w.f2.names -side left -expand 1 -fill both;
  pack $w.f6 -fill both -expand 1;
  pack $w.f6.child -side top -fill x;
  pack $w.f6.sb -side right -fill y;
  pack $w.f6.names -side left -expand 1 -fill both;

  set_expandable $w;

  set_all_windows $w "$school_name (SB)";
  
  if ![info exist wb(cfed:$school_name)] {
    set wb(cfed:$school_name) \
      [open "| $wb(cfed) -c $wb(path) -s $school_file" r+];

    write_to_cfed $w cd $env(OZROOT)/tmp;

    set wb(cpath) $env(OZROOT)/$wb(path);
  }

  sb_show_list $w;
}
  



