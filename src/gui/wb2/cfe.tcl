#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a UI for CFE (Compiler Front End)
#

global cfe;

set cfe(partstr:0) public;
set cfe(partstr:1) protected;
set cfe(partstr:2) private;
set cfe(partstr:3) if;
set cfe(partstr:4) all;
set cfe(partstr:5) id;
set cfe(partstr:6) "";
set cfe(partstr:7) "";
set cfe(CSmode) 0;

# Global functions

proc SetNewVersionID {school_name class_name kind vid} {
  global wbw;

  set w $wbw($school_name:CFE);

  if {[llength $vid] == 4} {
    lappend vid "0";
  }

  puts_for_debug "$kind $vid";

  sb_update $w $school_name $class_name $kind $vid;
}

proc OpenCFE {school_name {school_file ""}} {
  cfe_new_win $school_name $school_file;
}

proc OpenCFEforCS {} {
    global wb cfe;

    set school_name "CompileServer";
    
    set cfe(CSmode) 1;
    cfe_new_win $school_name $wb(schools:$school_name);

    SendOZ "Opened:";
}

proc AddFileForCS {school_name file} {
    global wbw;

    set w [winfo toplevel $wbw($school_name:CFE)];
    set_files "file $file" $w;

    SendOZ "Added:";
}

proc CompileForCS {} {
    global wbw;

    set school_name "CompileServer";

    set w [winfo toplevel $wbw($school_name:CFE)];
    $w.f2.srcs select from 0;
    exec_compile $w one;
    $w.co.f5.id.m invoke 2;
    exec_compile $w one;
    $w.co.f5.private invoke;
}

# Local functions

proc generate_one {w} {
  global cfe env label wb;

  cfe_set_all_state $w disabled;
  
  if {[set class_name [input_name $w $label(input)]] \
	== ""} {
    cfe_set_all_state $w normal;
    return;
  }

  set cfe(generate:$w) {}
  set cfe(msg:$w) "";

  set sn $wb($w);

  addinput -read $wb(cfed:$sn) "read_from_cfed_for_generate $w %F";

  if $cfe(gagain:$w) {
    if {[string first "<" $class_name] < 0} {
      write_to_cfed_nowait $w regenerate -d $env(OZROOT)/tmp '$class_name' $cfe(gagain:$w);
    } else {
      write_to_cfed_nowait $w generate -d $env(OZROOT)/tmp '$class_name' again $cfe(gagain:$w);
    }
  } else {
    write_to_cfed_nowait $w generate -d $env(OZROOT)/tmp '$class_name';
  }
}

proc generate_all {w} {
  global cfe wb env;

  cfe_set_all_state $w disabled $w;
  
  set cfe(generate:$w) {}
  set cfe(msg:$w) {}

  set sn $wb($w);

  addinput -read $wb(cfed:$sn) "read_from_cfed_for_generate $w %F";

  write_to_cfed_nowait $w generateall -d $env(OZROOT)/tmp;
}

proc compile_one {w cpart} {
  global cfe cfek cfecl wb;

  cfe_set_all_state $w disabled $w;
 
  set p [$w.f2.srcs curselection];
  set src [$w.f2.srcs get $p];

  set part $cfe(partstr:$cpart);

  set buf [write_to_cfed $w info this $src];
  set kind [set cfek($src:$w) [lindex $buf 0]];
  set class_name [set cfecl($src:$w) [lrange $buf 1 end]];

  switch $cpart {
    0 - 3 - 4 - 5 {
      set vid [write_to_cfed $w sb '$class_name' 0];
      if {![string compare $vid "not found"]} {
	set vid "";
      }
    }
    1 - 6 {
      set vid [write_to_cfed $w sb '$class_name' 1];
    }
    2 - 7 {
      set vid [write_to_cfed $w sb '$class_name' 2];
    }
  }
  
  set sn $wb($w);

  if !$wb(boot) {
    set wb(result:$w) -1;
    
    SendOZ "CheckVersion:$sn|CFE|$class_name|$vid|$cpart|$kind";

    if {$cfe(CSmode) > 0} {
	set msg "[gets stdin]";
#	puts_for_debug "$msg";
	eval $msg;
    } else {
	tkwait variable wb(result:$w);
    }

    write_to_cfed $w save;

    if {$wb(result:$w) || $cpart > 4} {
      cfe_set_all_state $w normal;
      return $wb(result:$w);
    }
  }

  set ids {};

#  if {$wb(boot) < 2} {
    if {$cpart == 3} {
      set ids \
	"[write_to_cfed $w sb '$class_name' 0] \
	[write_to_cfed $w sb '$class_name' 1]";
    } elseif {$cpart == 4} {
      set ids "[write_to_cfed $w sb '$class_name']";
    } else {
      set ids "[write_to_cfed $w sb '$class_name' $cpart]";
    }
#  } 

#  puts_for_debug $ids;

  set cfe(msg:$w) "";

  addinput -read $wb(cfed:$sn) "read_from_cfed_for_compile_one $w %F $cpart {$ids}";
  
  if {$wb(boot) && $cfe(again:$w)} {
    write_to_cfed_nowait $w compile $src $part again;
  } else {
    write_to_cfed_nowait $w compile $src $part;
  }

  return 0;
}

proc compile_all {w cpart} {
  global cfe cfek cfecl wb;

  cfe_set_all_state $w disabled $w;

  set part $cfe(partstr:$cpart);

  if $cfe(retry:$w) {
    write_to_cfed $w reset;
  }

  set ids {};
  set srcs {};

  set sn $wb($w);
    
#  if {$wb(boot) < 2} {

  set classes {};
  set vids {};
  set kinds {};
  
  set i 0;

  foreach src $cfe(files:$w) {

    set buf [write_to_cfed $w info this $src];
    set cfek($src:$w) [lindex $buf 0];

    if {($cfek($src:$w) >= 5 && $cfek($src:$w) <= 7 && $cpart == 2) ||
	  (!$cfe(retry:$w) &&
	   [info exist cfe(result:$cpart:$w:$src)] && \
	   ([set status [lindex $cfe(result:$cpart:$w:$src) 0]] > 2 ||
	    $status == 0))} {
      incr i;
      continue;
    } 

    set class_name [set cfecl($src:$w) [lrange $buf 1 end]];

    lappend classes $class_name;

    if !$wb(boot) {
      switch $cpart {
	0 - 3 - 4 - 5 {
	  set vid [write_to_cfed $w sb '$class_name' 0];
	  if {![string compare $vid "not found"]} {
	    set vid "";
	  }
	}
	1 - 6 {
	  set vid [write_to_cfed $w sb '$class_name' 1];
	}
	2 - 7 {
	  set vid [write_to_cfed $w sb '$class_name' 2];
	}
      }
      lappend vids $vid;
    }

    lappend srcs $src;
    lappend kinds $cfek($src:$w);
    
    incr i;
  }
    
  if !$wb(boot) {
    set wb(result:$w) -1;
      
    SendOZ \
      "CheckVersions:$sn|CFE|{$classes}|{$vids}|$cpart|{$kinds}";
      
    tkwait variable wb(result:$w);
    
    write_to_cfed $w save;
    
    if {$cpart > 4} {
      cfe_set_all_state $w normal;
      
      if {[lsearch -exact $wb(result:$w) 0] >= 0} {
	return 0;
      } else {
	return 1;
      }
    }
  }
    
  set i 0;

  set buf {};

  foreach class_name $classes {
      
    if {$wb(boot) || ![lindex $wb(result:$w) $i]} {
      lappend buf [lindex $srcs $i];
    } else {
      incr i;
      continue;
    }
    
    if {$cpart == 3} {
      lappend ids \
	"[write_to_cfed $w sb '$class_name' 0] \
		[write_to_cfed $w sb '$class_name' 1]";
    } elseif {$cpart == 4} {
      lappend ids "[write_to_cfed $w sb '$class_name']";
    } else {
      lappend ids "[write_to_cfed $w sb '$class_name' $cpart]";
    }
    
    incr i;
  }
    
  if {"$ids" == ""} {
    cfe_set_all_state $w normal;
    return 1;
  }

  set srcs $buf;
    
#    puts_for_debug $srcs;
#  }

  $w.f2.srcs select clear;
  $w.f2.srcs yview 0;
  update idletasks;

  set cfe(msg:$w) "";
  set cfe(result:$w) "";
  set cfe(config:$w) {};
  set cfe(rm:$w) {};

  addinput -read $wb(cfed:$sn) \
    "read_from_cfed_for_compile_all $w %F $cpart {$srcs} {$ids}";

  if {$wb(boot) && $cfe(again:$w)} {
    write_to_cfed_nowait $w all $part again;
  } else {
    write_to_cfed_nowait $w all $part;
  }

  return 0;
}
  
proc read_from_cfed_for_compile_all {w f cpart {srcs {}} {ids {}}} {
  global cfe label wb env cfecl cfek;

  gets $f line;

#  puts_for_debug $line;

  if [is_success $line] {
    set sn $wb($w);

    removeinput $f;

    cfe_set_all_state $w normal;
    
    if {$cfe(result:$w) != ""} {
      ShowResult $sn CFE $cfe(result:$w);
    }

    if {$cfe(config:$w) != ""} {
      exec_config_all $w;
    }

    foreach i $cfe(rm:$w) {
      remove_files $w $i;	      
    }

    if {$cfe(msg:$w) != ""} {
      set cfe(generic:$w) "$cfe(msg:$w)";
      cfe_show_wanted $w;
    }

    $w.f2.srcs select clear;

    if {$cpart == 3} {
      exec_compile $w all 3;
    }

  } elseif {[set i [lsearch -exact $cfe(files:$w) $line]] >= 0} {
    $w.f2.srcs select from $i;
    $w.f2.srcs yview $i;
    update idletasks;

  } elseif ![string first "done" $line] {
    set status [string index $line 5];
    set src [string range $line 7 end];

    set_status_of_all $w $src $status "$cfe(msg:$w)" $cpart;

    if {[set i [lsearch -exact $srcs $src]] < 0} {
      return;
    }

    if {$cfe(msg:$w) != ""} {
      append cfe(result:$w) "$src\n$cfe(msg:$w)";
    }

    set cfe(msg:$w) "";
    
# for synchronize
#    write_to_cfed_nowait $w "continue";

    if {$ids == ""} {
      return;
    }

    foreach id [lindex $ids $i] {
      if !$wb(boot) {
	if {[set buf [glob -nocomplain $wb(cpath)/$id/*]] != ""} {
	  SendOZ "RegisterClass:$id";
	}
      } else {
#	  if {[glob -nocomplain $env(OZROOT)/$wb(boot-path)/$id/private.cl] != ""} {
#	    SendOZ "Install:$wb(boot-path)/$id/private.cl";
#	  }
      }
    }

#      puts_for_debug $id;

    if !$status {
      if {[string first "*" $cfecl($src:$w)] < 0 && \
	    [file exists $wb(cpath)/$id/private.i]} {
	lappend cfe(config:$w) $id;
      }
      
      if {[string first "/.generate" $src] >= 0 && \
	    [string first "*" $cfecl($src:$w)] > 0} {
	      
	if {$cfek($src:$w) != 5} {
	  if {[glob -nocomplain $wb(cpath)/$id/private.o] != ""} {
	    lappend cfe(rm:$w) $src;
	  }
	} else {
	  if {[glob -nocomplain $wb(cpath)/$id/*] != ""} {
	    lappend cfe(rm:$w) $src;
	  }
	}
      }
    }
	
  } elseif {[string first "you need to generate" $line] >= 0} {
    set_generic_state $w enable;
    set cfe(msg:$w) "$line\n";
  } elseif {[string first "searchclass" $line] >= 0} {
    set sn $wb($w);
    SendOZ "SearchClass:$sn|CFE|[lindex $line 1]";
    tkwait variable wb(result:$w);

    if $wb(result:$w) {
      write_to_cfed_nowait $w "stop";
    } else {
      write_to_cfed_nowait $w "continue";
    }
  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc read_from_cfed_for_compile_one {w f cpart {ids {}}} {
  global cfe label wb env cfecl cfek;

  gets $f line;

#  puts_for_debug $line;

  if [is_success $line] {
    set sn $wb($w);

    removeinput $f;

    set p [$w.f2.srcs curselection];
    set src [$w.f2.srcs get $p];
    set class_name $cfecl($src:$w);
	
    foreach id $ids {
      if !$wb(boot) {
	if {[glob -nocomplain $wb(cpath)/$id/*] != ""} {
	  SendOZ "RegisterClass:$id";
	}
      } else {
#	  if {[glob -nocomplain $env(OZROOT)/$wb(boot-path)/$id/private.cl] \
#		!= ""} {
#	    SendOZ "Install:$wb(boot-path)/$id/private.cl";
#	  }
      }
    }

    cfe_set_all_state $w normal;

    if ![get_status $line] {
      if {[string first "*" $class_name] < 0 && \
	    [file exists $wb(cpath)/$id/private.i]} {
	exec_config_one $w;
      }

#      puts_for_debug $id;

      if {[string first "/.generate" $src] >= 0 && \
	  [string first "*" $class_name] > 0} {

	if {$cfek($src:$w) != 5} {
   	  if {[glob -nocomplain $wb(cpath)/$id/private.o] != ""} {
  	    remove_files $w $src;	      
          }
	} else {
   	  if {[glob -nocomplain $wb(cpath)/$id/*] != ""} {
  	    remove_files $w $src;	      
          }
	}
      }
    } else {
	if {$cfe(CSmode) > 0} {
	    SendOZ "CompilationFailed:";
	    $w.f3.school.m invoke 1;
	}
    }

    if {$cfe(msg:$w) != ""} {
      set p [string first "you need to generate" $cfe(msg:$w)];

      if {$p > 0} {
	set msg [string range $cfe(msg:$w) 0 [expr $p - 1]];
      } elseif {$p == 0} {
	set msg "";
      } else {
	set msg [string range $cfe(msg:$w) 0 end];
      }
	  
      set school_name $sn;

      if {$msg != ""} {
	ShowResult $school_name CFE $msg;
      }

      if {$p >= 0} {
	set msg [string range $cfe(msg:$w) $p end];
	set cfe(generic:$w) "$msg";
	set_generic_state $w enable;
	cfe_show_wanted $w;
      }
    }

    if {!$cfek($src:$w) || $cfek($src:$w) == 8} {
      switch $cpart {
	0 {
	  exec_compile $w one 2;
	}
	1 - 3 {
	  exec_compile $w one 3;
	}
      }
    }

  } elseif {[string first "searchclass" $line] >= 0} {
    set sn $wb($w);
    SendOZ "SearchClass:$sn|CFE|[lindex $line 1]";
    tkwait variable wb(result:$w);

    if $wb(result:$w) {
      write_to_cfed_nowait $w "stop";
    } else {
      write_to_cfed_nowait $w "continue";
    }
  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc read_from_cfed_for_generate {w f} {
  global cfe wb env;

  gets $f line;
 
#  puts_for_debug $line;

  if [is_success $line] {
    set sn $wb($w);

    removeinput $f;

    if {$wb(boot) < 2} {
      foreach gclass $cfe(generate:$w) {
	set vids [write_to_cfed $w sb '$gclass' 6];

	if {[llength $vids] == 5} {
	  set pvid [lindex $vids 2];
	  if $cfe(gagain:$w) {
	    set vid [lreplace $vids 1 $cfe(gagain:$w)];
	  } else {
	    set vid [lreplace $vids 1 1];
	  }
	} else {
	  set pvid [lindex $vids 1];
	  if {$cfe(gagain:$w) > 1} {
	    set vid [lreplace $vids 1 [expr $cfe(gagain:$w) - 1]];
	  } else {
	    set vid $vids;
	  }
	}

	foreach id $vid {
	  if !$wb(boot) {
	    if {[glob -nocomplain $wb(cpath)/$id/*] != ""} {
	      SendOZ "RegisterClass:$id";
	    }
	  } else {
#	    if {[glob -nocomplain $env(OZROOT)/$wb(boot-path)/$id/private.cl] != ""} {
#	      SendOZ "Install:$wb(boot-path)/$id/private.cl";
#	    }
	  }
	}

	set ccid [lindex $vid 0];

	if !$wb(boot) {
	  if [file exists $wb(cpath)/$ccid/private.r] {
	    SendOZ "SetConfiguration:$pvid|$ccid";
	  }
	}
      }
    }
    
    if [info exists cfe(gdir:$w)] {
      global label;

      set_files "dir [join $cfe(gdir:$w)]" $w disabled;
	
      tk_dialog $w.info "info." \
	"some files in `$cfe(gdir:$w)' cannot compiled" info 0 "$label(Close)";

      $w.f3.generic.m enable "$label(Discard Files)";

      unset cfe(gdir:$w);
    }

#    ShowResult $sn CFE $cfe(msg:$w);

    set cfe(generic:$w) [write_to_cfed $w wanted];
    set_generic_state $w;

    cfe_set_all_state $w normal;

  } elseif ![string first "checkversion" $line] {
    if [check_version_for_generate $w [string range $line 13 end]] {
      write_to_cfed_nowait $w stop;
    } else {
      write_to_cfed_nowait $w "continue$wb(boot)";
    }
    addinput -read $f "read_from_cfed_for_generate $w %F";
  } elseif ![string first "dir:" $line] {
    lappend cfe(gdir:$w) [lindex $line 1];
  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc check_version_for_generate {w buf} {
  global cfe wb;

  set again [lindex $buf 0];
	# again may be 1, 2 or 3 (public, protected, implementation)
  set kind [lindex $buf 1];
  set class_name [lrange $buf 2 end];

  if $wb(boot) {
    lappend cfe(generate:$w) $class_name;
    return 0;
  }

  if $again {
    set prev [write_to_cfed $w sb '$class_name' [expr $again - 1]];

    if ![string compare $prev "not found"] {
      return 1;
    }

    incr again 4;
  } else {
    set prev "";
    set again 5;
  }

  set wb(result:$w) -1;

  SendOZ "CheckVersion:$wb($w)|CFE|$class_name|$prev|$again|$kind";
  
  tkwait variable wb(result:$w);

  if $wb(result:$w) {
    return 1;
  }

  set public_vid [write_to_cfed $w sb '$class_name' 0];

  SendOZ "GetConfiguredClassID:$wb($w)|CFE|{$public_vid}";

  tkwait variable wb(result:$w);

#  puts_for_debug "$wb(result:$w)";

  write_to_cfed $w sb '$class_name' 9 [lindex $wb(result:$w) 0];

  lappend cfe(generate:$w) $class_name;
  return 0;
}

proc cfe_show_wanted {w} {
  global cfe wb label;

  set buf [tk_dialog $w.info "info." \
	   "$label(real msg)" info \
	   3 "$label(Detail)" "$label(Generate)" \
	   "$label(Discard Classes)" "$label(Close)"];

  switch $buf {
    0 {
      cfe_show_wanted_info $w;
    }
    1 {
      exec_generate_all $w;
    }
    2 {
      cfe_generic_discard $w class;
    }
    3 {
      return;
    }
  }
}

proc cfe_show_wanted_info {w} {
  global cfe;

  show_info $w $cfe(generic:$w);
}

proc cfe_generic_discard {w mode} {
  global cfe label;

  if {$mode == "class"} {
    write_to_cfed $w wanted discard $mode;

    set cfe(generic:$w) "";
    set_generic_state $w disable;
  } else {
    set buf [write_to_cfed $w wanted dir];
    
    foreach i $buf {
      foreach j [glob -nocomplain $i/.generate*.oz] {
	remove_files $w $j;
      }
    }

    $w.f3.generic.m disable "$label(Discard Files)";
    write_to_cfed $w wanted discard $mode;
  }
}

proc set_generic_state {w {state {}}} {
  global label cfe;

  if {$state == ""} {
    if {$cfe(generic:$w) == ""} {
      set state disable;
    } else {
      set state enable;
    }
  }

  $w.f3.generic.m $state "$label(All)";
  $w.f3.generic.m $state "$label(Discard Classes)";
  $w.f3.generic.m $state "$label(Detail)";
}

proc set_status_of_all {w src status msg cpart} {
  global cfe;
  
  set cfe(result:$cpart:$w:$src) [list $status "$msg"];
  
  if {$cpart > 2} {
    set cfe(result:0:$w:$src) [list $status {}];
    set cfe(result:1:$w:$src) [list $status {}];
    
    if {$cpart == 4} {
      set cfe(result:2:$w:$src) [list $status {}];
    }
  }
}

proc input_name {w msg} {
  global close cfe label;

  set win [toplevel $w.input];
  set cfe(gagain:$w) 0;

  wm title $win "Input a generic class name";

  frame $win.f1 -relief ridge -bd 2;
  label $win.f1.title -text $msg -anchor w;
  entry $win.f1.className -width 30 -relief ridge;

  mybind $win.f1.className <Control-h> \
    "if {\[$win.f1.className get\] == \"\"} { $win.f2.f3.done configure -state disabled; }";

  mybind $win.f1.className <Any-KeyPress> \
    "$win.f2.f3.done configure -state normal;"

  bind $win.f1.className <Return> \
    "$win.f2.f3.done invoke";

#  checkbutton $win.f1.again -textvariable "label(Again)" \
#    -onvalue "1" -offvalue "0" -variable cfe(gagain:$w) -relief flat;


  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -textvariable "label(Exec)" -state disabled -bd 1 \
    -command {
      global close;
      
      set close done;
    }
  menubutton $win.f2.again -textvariable "label(Again)" \
    -relief raised -menu $win.f2.again.m -bd 1;
  menu $win.f2.again.m;
  $win.f2.again.m add command -label "$label(from Public)" \
    -command "set cfe(gagain:$w) 1; $win.f2.f3.done invoke";
  $win.f2.again.m add command -label "$label(from Protected)" \
    -command "set cfe(gagain:$w) 2; $win.f2.f3.done invoke";
  $win.f2.again.m add command -label "$label(from Implementation)" \
    -command "set cfe(gagain:$w) 3; $win.f2.f3.done invoke";
  button $win.f2.cancel -textvariable "label(Cancel)" -bd 1 \
    -command {
      global close;
      
      set close cancel;
    }

  pack $win.f1 -fill both -padx 10 -pady 10;
  pack $win.f1.title -fill both -expand yes -padx 3 -pady 3;
  pack $win.f1.className -padx 10 -pady 10 -fill x -expand yes -ipady 5;
#  pack $win.f1.again -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;

  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel $win.f2.again \
    -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $win;

  focus $win.f1.className;
  tkwait variable close;

  set class_name [$win.f1.className get];

  destroy $win;

  if {$close == "cancel" || $class_name == ""} {
    return "";
  }  else {
    return $class_name;
  }
}

proc set_files {name w {state normal}} {
  global cfe label cfek cfecl;

  if {[lindex $name 0] == "dir"} {
    foreach j [lrange $name 1 end] {
      write_to_cfed $w add $j;
    }
    set files [write_to_cfed $w ls];
  } else {
    set files [lrange $name 1 end];
    write_to_cfed $w add $files;
  }

  if {$files == ""} {
    $w.f3.compile.m disable "$label(All)";
    return;
  }

  foreach j $files {
    file stat $j s;

    if {[lsearch -exact $cfe(files_ino:$w) $s(ino)] < 0} {
      set cfe(files:$w) [lsort [lappend cfe(files:$w) $j]];
      set i [lsearch -exact $cfe(files:$w) $j];
      $w.f2.srcs insert $i $j;

      set cfe(files_ino:$w) [linsert $cfe(files_ino:$w) $i $s(ino)];

#      set buf [write_to_cfed $w info this $j];
#      set cfek($j:$w) [lindex $buf 0];
#      set cfecl($j:$w) [lrange $buf 1 end];
    }
  }

  $w.f3.compile.m enable "$label(All)";
  $w.f3.config.m enable "$label(All)";

  cfe_set_all_state $w $state;
}

proc remove_files {w {gen ""}} {
  global cfe label;

  if {$gen != ""} {
#    puts_for_debug $gen;
#    puts_for_debug $cfe(files:$w);

    set p [lsearch -exact $cfe(files:$w) $gen];
    set range $p;
    exec rm -f $gen;
    set dir [file dirname $gen];
    if {[glob -nocomplain $dir/.generate*.oz] == ""} {
      exec rm -rf $dir;
      write_to_cfed $w wanted remove $dir;
      if {[write_to_cfed $w wanted dir] == ""} {
	$w.f3.generic.m disable "$label(Discard Files)";
      }
    }
  } else {
    set range [$w.f2.srcs curselect];
  }

  set from [lindex $range 0];

  foreach i $range {
    $w.f2.srcs delete $from;
  }

  set srcs [lrange $cfe(files:$w) $from $i];

  foreach src $srcs {
    catch {
      unset cfe(result:0:$w:$src);
      unset cfe(result:1:$w:$src);
      unset cfe(result:2:$w:$src);
      unset cfe(result:3:$w:$src);
      unset cfe(result:4:$w:$src);
      unset cfe(result:5:$w:$src);
    }
  }

  write_to_cfed $w remove $srcs
  set cfe(files:$w) [lreplace $cfe(files:$w) $from $i];
  set cfe(files_ino:$w) [lreplace $cfe(files_ino:$w) $from $i];

  if {$cfe(files:$w) == ""} {
    $w.f3.compile.m disable "$label(All)";
    $w.f3.config.m disable "$label(All)";
  }

  $w.f2.srcs select clear;
  $w.f3.school.m disable "$label(Remove)";
}

proc set_commands_state_for_one {w state} {
  global cfe cfek label;

  foreach i $cfe(commands) {
    $w.f3.[lindex $i 0].m $state [lindex $i 1];
  }

  if {$state == "enable"} {
    set src [$w.f2.srcs get [$w.f2.srcs curselect]];

    set cfek($src:$w) [lindex [write_to_cfed $w info this $src] 0];
    
    if {$cfek($src:$w) == 5 || $cfek($src:$w) == 7} {
      $w.f3.config.m disable $label(One);
    } else {
      $w.f3.config.m enable $label(One);
    }

    if [winfo exists $w.ones] {
      if {$cfek($src:$w) == 5 || $cfek($src:$w) == 7} {
	$w.ones disable $label(Configure);
      } else {
	$w.ones enable $label(Configure);
      }
    }
  }

}

proc exec_compile {w mode {again 0}} {
  global label cfe wb;

  cfe_set_all_state $w disabled;

  set win [toplevel $w.co];

  wm title $win "Compile";

  frame $win.f5 -relief ridge -bd 2;

  if 0 {
    radiobutton $win.f5.id -textvariable "label(ID)" -value "-1" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.if -textvariable "label(Public & Protected)" -value "3" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.private -textvariable "label(Implementation)" -value "2" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.all -textvariable "label(Allpart)" -value "4" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.public -textvariable "label(Public)" -value "0" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.protected -textvariable "label(Protected)" -value "1" \
      -variable cfe(part:$w) -relief flat;
  }

  menubutton $win.f5.id -textvariable "label(ID)" -bd 1 -menu $win.f5.id.m \
    -relief raised;
  menu $win.f5.id.m;
  $win.f5.id.m add command -label "$label(Public)" \
    -command "destroy $win; \
	if !\[compile_$mode $w 5\] { \
	  exec_compile $w $mode 1; \
        }";
  $win.f5.id.m add command -label "$label(Protected)" \
    -command "destroy $win; \
	if !\[compile_$mode $w 6\] { \
	  exec_compile $w $mode 2; \
        }";
  $win.f5.id.m add command -label "$label(Implementation)" \
    -command "destroy $win; \
	if !\[compile_$mode $w 7\] { \
	  exec_compile $w $mode 3; \
        }";
  button $win.f5.if -textvariable "label(Public & Protected)" -bd 1 \
    -command "destroy $win; compile_$mode $w 3";
  button $win.f5.private -textvariable "label(Implementation)" -bd 1 \
    -command "destroy $win; compile_$mode $w 2";
  button $win.f5.all -textvariable "label(Allpart)" -bd 1 \
    -command "destroy $win; compile_$mode $w 4";
  button $win.f5.public -textvariable "label(Public)" -bd 1 \
    -command "destroy $win; compile_$mode $w 0";
  button $win.f5.protected -textvariable "label(Protected)" -bd 1 \
    -command "destroy $win; compile_$mode $w 1";

#  checkbutton $win.f5.new -textvariable "label(New Version)" \
#    -onvalue "1" -offvalue "0" -variable cfe(new:$w) -relief flat;
  checkbutton $win.f5.again -textvariable "label(Again)" \
    -onvalue "1" -offvalue "0" -variable cfe(again:$w) -relief flat;
  checkbutton $win.f5.retry -textvariable "label(Retry)" \
    -onvalue "1" -offvalue "0" -variable cfe(retry:$w) -relief flat;

  frame $win.f2;
#  frame $win.f2.f3 -relief sunken -bd 1;
#  button $win.f2.f3.done -textvariable "label(Exec)" -bd 1 \
#    -command "destroy $win; compile_$mode $w";
  button $win.f2.cancel -textvariable "label(Cancel)" -bd 1 \
    -command "destroy $win; cfe_set_all_state $w normal";

  switch $again {
    1 {
      $win.f5.id configure -state disabled;
    } 
    2 {
      $win.f5.id configure -state disabled;
      $win.f5.public configure -state disabled;
    } 
    3 {
      $win.f5.id configure -state disabled;
      $win.f5.public configure -state disabled;
      $win.f5.protected configure -state disabled;
      $win.f5.if configure -state disabled;
    }
  }

  pack $win.f5 -fill both -padx 10 -pady 10;
  if !$wb(boot) {
    if {$mode == "one"} {
      pack $win.f5.id $win.f5.public $win.f5.protected $win.f5.if \
	$win.f5.private $win.f5.all \
	  -side top -ipadx 5 -ipady 5 -padx 5 -pady 5 -anchor nw -fill x;
#      pack $win.f5.new \
#	  -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
    } else {
      pack $win.f5.id $win.f5.if $win.f5.private \
	  -side top -ipadx 5 -ipady 5 -padx 5 -pady 5 -anchor nw -fill x;
#      pack $win.f5.new $win.f5.retry \
#	  -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
      pack $win.f5.retry \
	  -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
    }
  } else {
    if {$mode == "one"} {
      pack $win.f5.id $win.f5.public $win.f5.protected $win.f5.if \
	$win.f5.private $win.f5.all \
	  -side top -ipadx 5 -ipady 5 -padx 5 -pady 5 -anchor nw -fill x;
      pack $win.f5.again \
	  -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
    } else {
      pack $win.f5.id $win.f5.if $win.f5.private \
	  -side top -ipadx 5 -ipady 5 -padx 5 -pady 5 -anchor nw -fill x;
      pack $win.f5.again $win.f5.retry \
	  -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
    }
  }

  pack $win.f2 -fill x;
#  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
#  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel -side top -ipadx 5 -ipady 5 -padx 10 -pady 5 -fill x;

  set_center $win;

  wm transient $w $win;

  if {$cfe(CSmode) == 0} {
      tkwait window $win;
  }
}

proc exec_generate_all {w} {
  global label cfe;

  set cfe(gagain:$w) 0;

  set win [toplevel $w.co];

  cfe_set_all_state $w disabled $win;

  wm title $win "Generate";

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -textvariable "label(Exec)" -bd 1 \
    -command "destroy $win; generate_all $w";
  button $win.f2.cancel -textvariable "label(Cancel)" -bd 1 \
    -command "destroy $win; cfe_set_all_state $w normal";
  
  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $win;

  tkwait window $win;
}

proc cfe_prepare_for_set_status {} {
  global cfe label;
    
  set cfe(commands) {};
  lappend cfe(commands) [list school "$label(Remove)"];
  lappend cfe(commands) [list compile "$label(One)"];
  lappend cfe(commands) [list config "$label(One)"];
}

proc cfe_new_win {school_name school_file} {
  global wbw cfe label env wb wbk;

  if [info exists wbw($school_name:CFE)] {
    set win $wbw($school_name:CFE)

    wm deiconify $win;
    raise $win;
    return;

  } else {
    set wbw($school_name:CFE) .s[incr wb(win)];
    lappend wb(allwin) "$school_name:CFE";
    set w [toplevel $wbw($school_name:CFE)];
    set wb($w) "$school_name";
    set wbk($w) "CFE";
    set cfe(files:$w) {};
    set cfe(files_ino:$w) {};
    set cfe(success:$w) 1;
  }
  
  wm title $w "OZ++ CFE ($school_name)";

  frame $w.f3 -relief raised -bd 1;
  menubutton $w.f3.school -textvariable "label(CFE)" -menu $w.f3.school.m;
  menu $w.f3.school.m;

  proc cfe_school_menu {w} {
    global wb label;
    
    delete_menu $w.f3.school.m;

    if !$wb(boot) {
      $w.f3.school.m add command -label "$label(Open)" -command "wb_open CFE";
    }

    $w.f3.school.m add command -label "$label(Close)" -command "wb_close $w";
    $w.f3.school.m add separator;
    $w.f3.school.m add command -label "$label(Add)" \
      -command "add_files $w";
    $w.f3.school.m add command -label "$label(Remove)" -state disabled \
    -command "remove_files $w";
    $w.f3.school.m add separator;
    $w.f3.school.m add command -label "$label(Preference...)" \
      -command "preference $w";
    $w.f3.school.m add separator;
    $w.f3.school.m add command -label "$label(Quit)" -command "quit";
  }

  cfe_school_menu $w;
    
  proc add_files {w} {
    global wb;

    cfe_set_all_state $w disabled;
    my_file_selector $w.fsel set_files $w $wb(pwd) any *.oz {} 0; 
    tkwait window $w.fsel;
    cfe_set_all_state $w normal;
  }

  proc cfe_set_all_state {w state {grab {}}} {
    global cfe;

    foreach i $cfe(allcommands) {
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

  menubutton $w.f3.compile -textvariable "label(Compile)" \
    -menu $w.f3.compile.m;
  menu $w.f3.compile.m;

  proc cfe_compile_menu {w} {
    global label;

    delete_menu $w.f3.compile.m;

    if {[$w.f2.srcs curselect] != ""} {
      set status normal;
    } else {
      set status disabled;
    }

    $w.f3.compile.m add command -label "$label(One)" -state $status \
      -command "exec_compile $w one";

    if [$w.f2.srcs size] {
      set status normal;
    } else {
      set status disabled;
    }

    $w.f3.compile.m add command -label "$label(All)" -state $status \
      -command "exec_compile $w all";
  }

  menubutton $w.f3.config -textvariable "label(Configure)" \
    -menu $w.f3.config.m;
  menu $w.f3.config.m;

  proc cfe_config_menu {w} {
    global label;

    delete_menu $w.f3.config.m;

    if {[$w.f2.srcs curselect] != ""} {
      set status normal;
    } else {
      set status disabled;
    }

    $w.f3.config.m add command -label "$label(One)" -state $status \
      -command "exec_config_one $w";

    if [$w.f2.srcs size] {
      set status normal;
    } else {
      set status disabled;
    }

    $w.f3.config.m add command -label "$label(All)" -state $status \
      -command "exec_config_all $w";
  }

  menubutton $w.f3.generic -textvariable "label(Generic)" \
    -menu $w.f3.generic.m;
  menu $w.f3.generic.m;

  proc cfe_generic_menu {w} {
    global label cfe;

    delete_menu $w.f3.generic.m;

    $w.f3.generic.m add command -label "$label(One...)" \
      -command "generate_one $w";

    if {$cfe(generic:$w) != ""} {
      set status normal;
    } else {
      set status disabled;
    }

    $w.f3.generic.m add command -label "$label(All)" -state $status \
      -command "exec_generate_all $w";

    $w.f3.generic.m add separator;
    $w.f3.generic.m add command -label "$label(Detail)" -state $status\
      -command "cfe_show_wanted_info $w";

    $w.f3.generic.m add separator;
    $w.f3.generic.m add command -label "$label(Discard Classes)" \
      -state $status -command "cfe_generic_discard $w class";

    $w.f3.generic.m add command -label "$label(Discard Files)" -state disabled\
      -command "cfe_generic_discard $w file";
  }

  menubutton $w.f3.window -textvariable "label(Window)" -menu $w.f3.window.m;
  menu $w.f3.window.m;

  set cfe(allcommands) {school compile config generic window}

  tk_menuBar $w.f3 $w.f3.school $w.f3.compile \
    $w.f3.config $w.f3.generic $w.f3.window;
  focus $w.f3;

  frame $w.f2 -bd 2;
  label $w.f2.src -textvariable "label(Files)" -width 10 -anchor c \
    -relief raised -bd 1;
  scrollbar $w.f2.sbx -orient horiz -cursor sb_h_double_arrow \
    -command "$w.f2.srcs xview" -relief sunken -bd 1;
  scrollbar $w.f2.sby -command "$w.f2.srcs yview" -relief sunken -bd 1;
  listbox $w.f2.srcs -geometry 50x15 -exportselection no \
    -xscrollcommand "$w.f2.sbx set" \
      -yscrollcommand "$w.f2.sby set";

  menu $w.ones;

  proc cfe_ones_menu {w} {
    global label;

    delete_menu $w.ones;
  
    $w.ones add command -label "$label(Compile)" \
      -command "exec_compile $w one";
    $w.ones add command -label "$label(Configure)" \
      -command "exec_config_one $w";
  }

  cfe_ones_menu $w;

  bind $w.ones <ButtonRelease-1> "%W unpost; tk_invokeMenu %W;";
  bind $w.ones <3> "%W unpost";

  bind $w.f2.srcs <Double-ButtonPress-1> "$w.ones post %X %Y";

  mybind $w.f2.srcs <1> \
    "if {\[%W curselect\] != {}} { set_commands_state_for_one $w enable }";

  bind $w.f2.srcs <3> \
    "%W select clear; set_commands_state_for_one $w disable; $w.ones unpost";

  if 0 {
    frame $w.f6;
    checkbutton $w.f6.verbose -text "Verbose" -onvalue "-v" -offvalue "" \
      -variable cfe(verbose) -relief flat;
    checkbutton $w.f6.nolink -text "No Link" -onvalue "-z" -offvalue "" \
      -variable cfe(nolink) -relief flat -state disabled;
    checkbutton $w.f6.nog -text "No `-g'" -onvalue "" -offvalue "-g" \
      -variable cfe(nog) -relief flat;
  }

  set cfe(generic:$w) "";

  cfe_compile_menu $w;
  cfe_config_menu $w;
  cfe_generic_menu $w;

  pack $w.f3 -fill x;
  pack $w.f3.school $w.f3.compile $w.f3.config \
    $w.f3.generic $w.f3.window -side left -ipadx 5 -ipady 3;

  pack $w.f2 -side left -fill both -expand yes;
#  pack $w.f2.src -side top -fill x -ipady 2;
  pack $w.f2.sbx -side bottom -fill x;
  pack $w.f2.sby -side right -fill y;
  pack $w.f2.srcs -side top -fill both -expand yes;

  if 0 {
    pack $w.f6 -fill x;
    pack $w.f6.verbose $w.f6.nolink $w.f6.nog -side left -padx 5 -pady 5;
  }

  set_all_windows $w "$school_name (CFE)";
  
  set_center $w;
  set_expandable $w;

  if ![info exist wb(cfed:$school_name)] {
    set wb(cfed:$school_name) \
      [open "| $wb(cfed) -c $wb(path) -s $school_file" r+];

    write_to_cfed $w cd $env(OZROOT)/tmp;

    set wb(cpath) $env(OZROOT)/$wb(path);
  }

  set buf [write_to_cfed $w wanted];

  if {[string first "you need to generate" $buf] >= 0} {
    set cfe(generic:$w) "$buf";

    set_generic_state $w enable;
    
    cfe_show_wanted $w;
  } 

  set buf [write_to_cfed $w wanted dir];
  
  if {$buf != ""} {
    set_files "dir $buf" $w;
    $w.f3.generic.m enable "$label(Discard Files)";
  }

  cfe_prepare_for_set_status;

  if {$cfe(CSmode) == 0} {
      $w.f3.school.m invoke $label(Add);
  }
}
      



