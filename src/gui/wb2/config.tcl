#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a UI for Configure
#

# Global functions

# Local functions

proc config_one {w} {
  global cfe cfecl wb label;

  cfe_set_all_state $w disabled $w;

  set p [$w.f2.srcs curselection];
  set src [$w.f2.srcs get $p];

  set buf [write_to_cfed $w info this $src];
  set cfek($src:$w) [lindex $buf 0];
  set class_name [set cfecl($src:$w) [lrange $buf 1 end]];

  if {[string first "*" $class_name] >= 0} {
    tk_dialog $w.info "info." "$label(no config msg)" info 0 "$label(Close)";
    cfe_set_all_state $w normal;
    return;
  }

  set sn $wb($w);

  if {$wb(boot) == 1} {
    set ids [write_to_cfed $w sb '$class_name'];

  } elseif !$wb(boot) {
  
    set cfe(config:$w) "";

    set public_vid [write_to_cfed $w sb '$class_name' 0];
    set ccid [write_to_cfed $w sb '$class_name' 3];

    if {[string length $ccid] < 16 || \
		[file exists $wb(cpath)/$ccid/private.r]} {

      SendOZ "GetConfiguredClassID:$sn|CFE|{$public_vid}";

      if {$cfe(CSmode) > 0} {
	  set msg "[gets stdin]";
#	  puts_for_debug "$msg";
	  eval $msg;
      } else {
	  tkwait variable wb(result:$w);
      }
      
      set ids "$public_vid [lindex $wb(result:$w) 0]";
      
#    puts_for_debug "$wb(result:$w)";

      write_to_cfed $w sb '$class_name' 9 [lindex $wb(result:$w) 0];
    } else {
      set ids "$public_vid $ccid";
    }
  } else {
    set ids {};
  }


#  puts_for_debug $ids;

  set cfe(msg:$w) "";

  addinput -read $wb(cfed:$sn) "read_from_cfed_for_config_one $w %F {$ids}";

  if {$wb(boot) && $cfe(cagain:$w)} {
    write_to_cfed_nowait $w config '$class_name' again;
  } else {
    write_to_cfed_nowait $w config '$class_name';
  }
}

proc config_all {w} {
  global cfe cfek cfecl wb;

  cfe_set_all_state $w disabled $w;

  if $cfe(cretry:$w) {
    write_to_cfed $w reset;
  }

  set ids {};
  set srcs {};

  set sn $wb($w);

  if $wb(boot) {
    foreach src $cfe(files:$w) {

      set buf [write_to_cfed $w info this $src];
      set kind [set cfek($src:$w) [lindex $buf 0]];

      if {($kind == 5 || $kind == 7) || \
	    (!$cfe(cretry:$w) && [info exist cfe(result:5:$w:$src)] && 
	     [lindex $cfe(result:5:$w:$src) 0] != 1)} continue;

      set name [set cfecl($src:$w) [lrange $buf 1 end]];

      if {[string first "*" $name] >= 0} continue;

      if {$kind == 6} {
	set id "[write_to_cfed $w sb '$name' 0]";
      } else {
	set id "[write_to_cfed $w sb '$name' 2]";
      }

      if ![file exists $wb(cpath)/$id/private.i] continue;

      lappend srcs $src;

#      if {$wb(boot) == 1} {
#	lappend ids "[write_to_cfed $w sb '$name']";
#      }
    } 
    
  } else {
    set from 0;
    set to 20;
    set len [expr [llength $cfe(files:$w)] - 1];

    set pvids {};

    while 1 {

      if {$to > $len} {
	set to $len;
      }

      set files [lrange $cfe(files:$w) $from $to];
      set getvids {};
      set alreadys {};
      set ccids {};
      
      set get_srcs {};
      set already_srcs {};

      foreach src $files {

	set buf [write_to_cfed $w info this $src];
	set kind [set cfek($src:$w) [lindex $buf 0]];

	if {($kind == 5 || $kind == 7) || \
	      (!$cfe(cretry:$w) && [info exist cfe(result:5:$w:$src)] && 
	       [lindex $cfe(result:5:$w:$src) 0] != 1)} {
#	  puts_for_debug $src;

	  continue;
	} 

	set name [set cfecl($src:$w) [lrange $buf 1 end]];

	if {[string first "*" $name] >= 0} continue;
	
	if {$kind == 6} {
	  set id "[write_to_cfed $w sb '$name' 0]";
	} else {
	  set id "[write_to_cfed $w sb '$name' 2]";
	}

#	if ![file exists $wb(cpath)/$id/private.i] continue;


	set pvid [write_to_cfed $w sb '$name' 0];
	set ccid [write_to_cfed $w sb '$name' 3];

	if {[string length $ccid] < 16 || [file exists $wb(cpath)/$ccid/private.r]} {
	  lappend getvids $pvid;
	  lappend get_srcs $src;
	} else {
	  lappend alreadys $pvid;
	  lappend ccids $ccid;
	  lappend already_srcs $src;
	}
      }

      set cfe(config:$w) "";

#      puts_for_debug "gets = $getvids";
#      puts_for_debug "already = $alreadys";
#      puts_for_debug "ccid = $ccids";

      if {!$wb(boot) && [string length $getvids] > 0} {
	SendOZ "GetConfiguredClassID:$sn|CFE|{$getvids}";
	
        if {$cfe(CSmode) > 0} {
	  set msg "[gets stdin]";
	  puts_for_debug "$msg";
	  eval $msg;
        } else {
	  tkwait variable wb(result:$w);
        }
	
	set ids [concat $ids [join $wb(result:$w)]];
	set pvids [concat $pvids $getvids];
      }

      if {$ccids != ""} {
	set ids [concat $ids $ccids];
	set pvids [concat $pvids $alreadys];
      }

      if {$get_srcs != ""} {
	set srcs [concat $srcs $get_srcs];
      }

      if {$already_srcs != ""} {
	set srcs [concat $srcs $already_srcs];
      }

      puts_for_debug "ids = $ids";
      puts_for_debug "pvids = $pvids";
      puts_for_debug "srcs = $srcs";

      if {$to == $len} {
	break;
      }

      incr from 20;
      incr to 20;
    }

    if {$srcs == ""} {
      cfe_set_all_state $w normal;
      return;
    }

    set buf [join $ids];
    set pvids [join $pvids];

    set ids {};

    set i 0;
    foreach id $buf {
      set src [lindex $srcs $i];
      write_to_cfed $w sb '$cfecl($src:$w)' 9 $id;
      lappend ids "[lindex $pvids $i] $id";
      incr i;
    }
  }

  puts_for_debug $ids;

  $w.f2.srcs select clear;
  $w.f2.srcs yview 0;
  update idletasks;

  set cfe(msg:$w) "";
  set cfe(result:$w) "";
  set cfe(rm:$w) {};

  addinput -read $wb(cfed:$sn) \
    "read_from_cfed_for_config_all $w %F {$srcs} {$ids}";

  if {$wb(boot) && $cfe(cagain:$w)} {
    write_to_cfed_nowait $w configall again;
  } else {
    write_to_cfed_nowait $w configall;
  }
}

proc read_from_cfed_for_config_one {w f {ids {}}} {
  global cfe wb env;

  gets $f line;

#  puts_for_debug $line;

  if [is_success $line] {
    set sn $wb($w);

    removeinput $f;

    if ![get_status $line] {
      if $wb(boot) {
	foreach id $ids {
	  if {[glob -nocomplain $env(OZROOT)/$wb(boot-path)/$id/private.cl] != ""} {
	    SendOZ "Install:$wb(boot-path)/$id/private.cl";
	  }
	}
      } else {
	set ccid [lindex $ids 1];
	if {[glob -nocomplain $wb(cpath)/$ccid/*] != ""} {
	  SendOZ "RegisterClass:$ccid";
	  SendOZ "SetConfiguration:[lindex $ids 0]|$ccid";

	  set src [$w.f2.srcs get [$w.f2.srcs curselection]];
          if {[string first "/.generate" $src] >= 0} {
  	    remove_files $w $src;	      
          }
	}

	if {$cfe(CSmode) > 0} {
	    SendOZ "CompilationDone:";
	}
      }
    }

    if {$cfe(msg:$w) != ""} {
      ShowShortResult $sn CFE $cfe(msg:$w);
    }

    cfe_set_all_state $w normal;

    if {$cfe(CSmode) > 0} {
	$w.f3.school.m invoke 1;
    }

  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc read_from_cfed_for_config_all {w f {srcs {}} {ids {}}} {
  global cfe wb env;

  gets $f line;

#  puts_for_debug $line;
  
  if [is_success $line] {
    set sn $wb($w);

    removeinput $f;

    if {$cfe(result:$w) != ""} {
      ShowResult $sn CFE $cfe(result:$w);
    }

    foreach i $cfe(rm:$w) {
      remove_files $w $i;
    }

    $w.f2.srcs select clear;
    cfe_set_all_state $w normal;

  } elseif {[set i [lsearch -exact $cfe(files:$w) $line]] >= 0} {
    $w.f2.srcs select from $i;
    $w.f2.srcs yview $i;
    update idletasks;
  } elseif ![string first "done" $line] {
    
    set status [string index $line 5];
    set src [string range $line 7 end];

    set i [lsearch -exact $srcs $src];

    set cfe(result:5:$w:$src) [list $status "$cfe(msg:$w)"];

    if {$cfe(msg:$w) != ""} {
      append cfe(result:$w) "$src\n$cfe(msg:$w)";
    }
    set cfe(msg:$w) "";
    
# for synchronize
#    write_to_cfed_nowait $w "continue";
    
    if !$status {
      set id [lindex $ids $i];
      if $wb(boot) {
	foreach i $id {
	  if {[glob -nocomplain $env(OZROOT)/$wb(boot-path)/$i/private.cl] != ""} {
	    SendOZ "Install:$wb(boot-path)/$i/private.cl";
	  }
	}
      } else {
	set ccid [lindex $id 1];
	if {[glob -nocomplain $wb(cpath)/$ccid/*] != ""} {
	  SendOZ "RegisterClass:$ccid";
	  SendOZ "SetConfiguration:[lindex $id 0]|$ccid";

          if {[string first "/.generate" $src] >= 0} {
  	    lappend cfe(rm:$w) $src;
          }
	}
      }
    }
  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc exec_config_all {w} {
  global label cfe wb;

  cfe_set_all_state $w disabled;

  set win [toplevel $w.co];

  wm title $win "Configure";

  frame $win.f5 -relief ridge -bd 2;
  checkbutton $win.f5.retry -textvariable "label(Retry)" \
    -onvalue "1" -offvalue "0" -variable cfe(cretry:$w) -relief flat;
  checkbutton $win.f5.again -textvariable "label(Again)" \
    -onvalue "1" -offvalue "0" -variable cfe(cagain:$w) -relief flat;

  pack $win.f5 -fill both -padx 10 -pady 10;
  pack $win.f5.retry -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
  if $wb(boot) {
    pack $win.f5.again -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
  }

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -textvariable "label(Exec)" -bd 1 \
    -command "destroy $win; config_all $w";
  button $win.f2.cancel -textvariable "label(Cancel)" -bd 1 \
    -command "destroy $win; cfe_set_all_state $w normal";
  
  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $win;

  tkwait window $win;
}

proc exec_config_one {w} {
  global label cfe wb cfecl wbw sb;

  set p [$w.f2.srcs curselection];
  set src [$w.f2.srcs get $p];

  set buf [write_to_cfed $w info this $src];
  set cfek($src:$w) [lindex $buf 0];
  set class_name [set cfecl($src:$w) [lrange $buf 1 end]];

  set vid [write_to_cfed $w sb '$class_name' 0];

  if ![string compare $vid "not found"] {
    tk_dialog $w.info Info "Not found in school." info 0 Close;
    return;
  }

  set parts "[write_to_cfed $w parents $vid] $vid]";

  if {[string first "cannot open file:" $parts] >= 0} {
    tk_dialog $w.info Info "not compiled." info 0 Close;
    return;
  }

  set sb(mode:$w) edit;
  
  cfe_set_all_state $w disabled;

  set win [toplevel $w.co];

  wm title $win "Configure";

  wm withdraw $win;

  frame $win.f5 -relief ridge -bd 2;
  pack $win.f5 -padx 10 -pady 10;

  set j 0;
  foreach i $parts {
    frame $win.f5.f$j;
    button $win.f5.f$j.name -text [set name [write_to_cfed $w sb '$i']] \
      -anchor w -relief flat -command "sb_search $wb($w) $name";
    entry $win.f5.f$j.part
    $win.f5.f$j.part insert end [write_to_cfed $w sb '$i' 2];
    $win.f5.f$j.part configure -state disabled;
    button $win.f5.f$j.other -textvariable "label(Other...)" \
      -relief flat \
	-command "sb_other_win $win {$name} implementation $win.f5.f$j.part";

    if $wb(boot) {
      $win.f5.f$j.other configure -state disabled;
    }

    pack $win.f5.f$j -fill x -expand yes -side top;
    pack $win.f5.f$j.name -side left -fill x -expand yes \
      -padx 5 -pady 5 -ipady 5;
    pack $win.f5.f$j.part -side left -padx 5 -pady 5;

    pack $win.f5.f$j.other -side left -padx 5 -pady 5 -ipady 5;
    incr j;
  }

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -textvariable "label(Exec)" -bd 1 \
    -command "destroy $win; config_one $w";
  button $win.f2.cancel -textvariable "label(Cancel)" -bd 1 \
    -command "destroy $win; cfe_set_all_state $w normal";

  checkbutton $win.f2.again -textvariable "label(Again)" \
    -onvalue "1" -offvalue "0" -variable cfe(cagain:$w) -relief flat;

  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  if $wb(boot) {
    pack $win.f2.again -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;
    pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -pady 5 -fill x;
  } else {
    pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -pady 5 -padx 40;
  }

  set_center $win;
  wm deiconify $win;

  if {$cfe(CSmode) > 0} {
      $win.f2.f3.done invoke;
  } else {
      tkwait window $win;
  }

  set sb(mode:$w) cancel;
}


