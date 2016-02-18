#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a UI for CFE (Compiler FrontEnd)
#

global env cfe;

set cfe(test_mode) 0;
set cfe(debug_mode) 0;

source $env(OZROOT)/lib/gui/wb/if-to-oz.tcl
source $env(OZROOT)/lib/gui/wb/filesel.tcl
#source $env(OZROOT)/lib/gui/wb/working.tcl

# debug 

proc puts_for_debug {msg} {
  global cfe;

  if $cfe(debug_mode) {
    puts stderr $msg;
  }
}

# Global functions

proc SetNewVersionID {school_name class_name kind vid} {
  global cfe cfew;

  set w $cfew($school_name);

  eval write_to_cfed_nowait $w sb '$class_name' 10 $kind $vid;

#  puts_for_debug [write_to_cfed $w sb "$class_name"];
}

proc SetConfiguredClassID {school_name ccid} {
  global cfe cfew;

  set w $cfew($school_name);
  set cfe(config:$w) $ccid;

  puts_for_debug $cfe(config:$w);
}

proc FinishChecking {school_name status} {
  global cfe cfew;

  set w $cfew($school_name);
  set cfe(start:$w) $status;

  puts_for_debug "check result = $status";
}

proc InputClassObject {} {
  preference .;
}

proc SetClassPath {path} {
  global cfe env;

  set cfe(path) $path;

#  puts_for_debug $cfe(path);

  if $cfe(boot) {
    Open "$env(OZROOT)/etc/boot-school" etc/boot-school;
  } else {
    SendOZ "FinishSettingClassPath:";
  }
}

proc Bye {} {
  global cfe;

  close_all;

  SendOZ "Bye:$cfe(pwd)|$cfe(lang)";
  destroy .;
}

proc ShowWindow {school_name} {
  global cfe cfew;

  set school_name [lindex $school_name 0];

  if {$school_name == "CFE"} {
    set w ".";
  }  else {
    set w $cfew($school_name);
  }

  wm deiconify $w;
  raise $w;
}

proc Open {school_name school_file} {
  global cfe;

  new_win $school_name $school_file;
}

proc ShowResult {school_name msg} {
  global cfe cfew label;

  set w $cfew($school_name);

  if {$msg != ""} {
    if ![tk_dialog $w.msg "CFE info." \
	 $label(result) \
	 questhead 0 $label(Yes) $label(No)] {
      show_info $w $msg;
    }
  }
}

proc ShowShortResult {school_name msg} {
  global cfe cfew;

  set w $cfew($school_name);

  tk_dialog $w.msg "CFE info." "$msg" info 0 "Close";
}


# Local functions

proc lang_of_english {} {
  global label cfe;

  set label(Add) "Add...";
  set label(Again) "Again";
  set label(All) "All...";
  set label(Allpart) "All";
  set label(Cancel) "Cancel";
  set label(Close) "Close";
  set label(Compile) "Compile";
  set label(Configure) "Configure";
  set label(Copy) "Copy";
  set "label(Current directory)" "Current directory";
  set label(Custom) "Customize";
  set label(Cut) "Cut";
  set label(Default) "Default";
  set label(Delete) "Delete";
  set label(Done) "Done";
  set label(English) "English";
  set label(Exec) "Go";
  set label(Files) "Files";
  set label(Generic) "Generic";
  set label(ID) "New";
  set label(Implementation) "Implementation";
  set label(Japanese) "Japanese";
  set label(Language) "Language";
  set "label(Name of Class)" "Name of Class";
  set "label(New Version)" "New Version";
  set label(One) "One...";
  set label(One...) "One...";
  set label(Open) "Open";
  set label(Paste) "Paste";
  set label(Preference...) "Preference...";
  set label(Protected) "Protected";
  set "label(Public & Protected)" "Public & Protected";
  set label(Public) "Public";
  set label(Quit) "Quit";
  set label(Remove) "Remove";
  set label(Retry) "Retry";
  set label(Save) "Save";
  set label(School) "CFE";
  set label(Window) "Window";

  set label(input) "Plsease input a name of class.";
  set label(result) "Some messages were generated.\nDo you examine now ?";

  set label(Yes) "Yes";
  set label(No) "No";
}

proc lang_of_japanese {} {
  global label cfe;

  set label(Add) "追加...";
  set label(Again) "再コンパイル";
  set label(All) "すべて...";
  set label(Allpart) "すべて";
  set label(Cancel) "取消";
  set label(Close) "閉じる";
  set label(Compile) "コンパイル";
  set label(Configure) "コンフィギュア";
  set label(Copy) "コピー";
  set "label(Current directory)" "現在のディレクトリ";
  set label(Custom) "カスタマイズ";
  set label(Cut) "カット";
  set label(Default) "デフォルト";
  set label(Delete) "消去";
  set label(Done) "終了";
  set label(English) "英語";
  set label(Exec) "実行";
  set label(Files) "ソースファイル";
  set label(Generic) "ジェネリック";
  set label(ID) "新規クラス";
  set label(Implementation) "実装";
  set label(Japanese) "日本語";
  set label(Language) "言語";
  set "label(Name of Class)" "クラス名";
  set "label(New Version)" "新規バージョン";
  set label(One) "一つ...";
  set label(One...) "一つ...";
  set label(Open) "開く";
  set label(Paste) "ペースト";
  set label(Preference...) "初期設定";
  set label(Protected) "プロテクティッド";
  set "label(Public & Protected)" "パブリックとプロテクティッド";
  set label(Public) "パブリック";
  set label(Quit) "終了";
  set label(Remove) "削除";
  set label(Retry) "もう一度全部";
  set label(Save) "保存";
  set label(School) "しぃえふぃ";
  set label(Window) "ウィンドウ";

  set label(input) "クラス名を入力して下さい。";
  set label(result) "何かメッセージが出ていますよ。\nみて見ますか？";

  set label(Yes) "はい";
  set label(No) "いいえ";
}

proc preference {win} {
  global cfe close label;

  set lang $cfe(lang);

  set w [toplevel $win.pref];

  wm title $w "Preference";
  
  frame $w.f0 -relief ridge -bd 2;

  frame $w.f0.f1;
  label $w.f0.f1.class -text "$label(Name of Class)" -width 20 -anchor e;
  entry $w.f0.f1.class_name -relief ridge -width 40;
  $w.f0.f1.class_name insert end $cfe(class);

  bind $w.f0.f1.class_name <Return> { };
  bind $w.f0.f1.class_name <Tab> { };

  frame $w.f0.f4;
  label $w.f0.f4.pwd -text "$label(Current directory)" -width 20 -anchor e;
  entry $w.f0.f4.pwd_name -relief ridge;
  $w.f0.f4.pwd_name insert end $cfe(pwd);

  proc set_pwd {arg w} {
    global cfe;

    $w.f0.f4.pwd_name delete 0 end;
    $w.f0.f4.pwd_name insert end $arg;
  }

  bind $w.f0.f4.pwd_name <Double-ButtonPress-1> \
    "\
      $w.f3.done configure -state disabled;\
      catch {set_all_state $win disabled};\
      my_file_selector $w.fsel set_pwd $w \[$w.f0.f4.pwd_name get\] dir;\
      tkwait window $w.fsel;\
      catch {set_all_state $win normal};\
      $w.f3.done configure -state normal;\
    ";
  bind $w.f0.f4.pwd_name <Return> { };
  bind $w.f0.f4.pwd_name <Tab> { };

  frame $w.f0.f2;
  label $w.f0.f2.mode -text "$label(Language)" -width 20 -anchor e;
  radiobutton $w.f0.f2.japan -text "$label(Japanese)" -value "japanese" \
    -variable cfe(lang) -relief flat;
  radiobutton $w.f0.f2.english -text "$label(English)" -value "english" \
    -variable cfe(lang) -relief flat;

  frame $w.f3;
  button $w.f3.done -text "$label(Done)" -bd 1 \
    -command {global close; set close done}
  button $w.f3.cancel -text "$label(Cancel)" -bd 1 \
    -command {global close; set close cancel}

  pack $w.f0 -fill both -padx 10 -pady 10;
  pack $w.f0.f1 $w.f0.f4 $w.f0.f2 -fill x -expand yes -pady 10;

  pack $w.f0.f1.class -side left;
  pack $w.f0.f1.class_name -side left -padx 10 -fill x -expand yes -ipady 5;

  pack $w.f0.f4.pwd -side left;
  pack $w.f0.f4.pwd_name -side left -padx 10 -fill x -expand yes -ipady 5;

  pack $w.f0.f2.mode -side left;
  pack $w.f0.f2.japan $w.f0.f2.english -side left -padx 10 -ipady 5 -ipadx 5;

  pack $w.f3 -fill x -expand yes -pady 10;
  pack $w.f3.done -side left -ipadx 5 -ipady 5 -padx 40 -pady 5;
  pack $w.f3.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $w;
  set_expandable $w width;

  focus $w.f0.f1.class_name;
  tkwait variable close;

  set class_name [$w.f0.f1.class_name get];
  set pwd_name [$w.f0.f4.pwd_name get];

  destroy $w;
  
  if {$close != "cancel"} {
    if {$pwd_name != ""} {
      set cfe(pwd) $pwd_name;
    }
    if {$class_name != "" && "$class_name" != "$cfe(class)"} {
      set cfe(class) $class_name;
      SendOZ "SetClass:$class_name";
    }

    if {$lang != $cfe(lang)} {
      lang_of_$cfe(lang);

      foreach i $cfe(allwin) {
	new_win $i {} 1;
      }
    }
  }

  if {$cfe(boot) < 2 && $cfe(class) == ""} {
    quit;
  }
}

proc generate_one {w} {
  global cfe env label;

  set_all_state $w disabled;
  
  if {[set class_name [input_name $w $label(input)]] \
	== ""} {
    set_all_state $w normal;
    return;
  }

  set cfe(generate:$w) {}

  removeinput $cfe(cfed:$w);
  addinput -read $cfe(cfed:$w) "read_from_cfed_for_generate $w %F";

  if $cfe(gagain:$w) {
    write_to_cfed_nowait $w generate -d $cfe(pwd) $class_name again;
  } else {
    write_to_cfed_nowait $w generate -d $cfe(pwd) $class_name;
  }
}

proc generate_all {w} {
  global cfe;

  set_all_state $w disabled $w;
  
  set cfe(generate:$w) {}
  set cfe(msg:$w) {}

  removeinput $cfe(cfed:$w);
  addinput -read $cfe(cfed:$w) "read_from_cfed_for_generate $w %F";

  write_to_cfed_nowait $w generateall -d $cfe(pwd);
}

proc config_one {w} {
  global cfe cfecl;

  set_all_state $w disabled $w;

  set p [$w.f2.srcs curselection];
  set src [$w.f2.srcs get $p];
  set class_name $cfecl($src:$w);

  if {$cfe(boot) == 1} {
    set ids [eval write_to_cfed $w sb '$class_name'];
  } elseif !$cfe(boot) {
    set cfe(config:$w) "";

    set public_vid [eval write_to_cfed $w sb '$class_name' 0];
    SendOZ "GetConfiguredClassID:[this_school_name $w]|{$public_vid}";

    tkwait variable cfe(config:$w);

    set ids $cfe(config:$w);

    eval write_to_cfed $w sb '$class_name' 9 $cfe(config:$w);
  } else {
    set ids {};
  }
  
  removeinput $cfe(cfed:$w);
  addinput -read $cfe(cfed:$w) "read_from_cfed_for_config_one $w %F \"$ids\"";

  set cfe(msg:$w) "";
  
  if {$cfe(boot) && $cfe(cagain:$w)} {
    write_to_cfed_nowait $w config "$class_name" again;
  } else {
    write_to_cfed_nowait $w config "$class_name";
  }
}

proc config_all {w} {
  global cfe cfek cfecl;

  set_all_state $w disabled $w;

  if $cfe(cretry:$w) {
    write_to_cfed $w reset;
  }

  set ids {};
  set srcs {};

  if {$cfe(boot) == 1} {
    set i 0;

    foreach src $cfe(files:$w) {
      set kind $cfek($src:$w);
      if {($kind == 5 || $kind == 7) || \
	    (!$cfe(cretry:$w) && [info exist cfe(result:5:$w:$src)] && 
	     [lindex $cfe(result:5:$w:$src) 0] != 1)} {
	incr i;
	continue;
      } 

      set name $cfecl($src:$w);
      lappend srcs $src;
      lappend ids "[eval write_to_cfed $w sb '$name']";

      incr i;
    } 
  } elseif !$cfe(boot) {
    set from 0;
    set to 20;
    set len [llength $cfe(files:$w)];

    set school_name [this_school_name $w];

    while {$to != "end"} {
      if {$to >= $len} {
	set to end;
      }

      set files [lrange $cfe(files:$w) $from $to];
      set public_vid {};

      set i 0;
      foreach src $files {

	if {!$cfe(cretry:$w) && [info exist cfe(result:5:$w:$src)] && \
	      [lindex $cfe(result:5:$w:$src) 0] != 1} {
	  continue;
	} 

	set name $cfecl($src:$w)
	lappend srcs $src;
	lappend public_vid "[eval write_to_cfed $w sb '$name' 0]";

	incr i;
      }

      set cfe(config:$w) "";
      
      if !$cfe(boot) {
	SendOZ "GetConfiguredClassID:$school_name|{$public_vid}";
    
	tkwait variable cfe(config:$w);
	
	lappend ids $cfe(config:$w);
      }
    }
	
    set i 0;
    foreach id $ids {
      set src [lindex $cfe(files:$w) $i];
      eval write_to_cfed $w sb '$cfecl($src:$w)' 9 $id;
      incr i;
    }
  }

  removeinput $cfe(cfed:$w);
  addinput -read $cfe(cfed:$w) \
    "read_from_cfed_for_config_all $w %F \"$srcs\" \"$ids\"";

  $w.f2.srcs select clear;
  $w.f2.srcs yview 0;
  update idletasks;

  set cfe(msg:$w) "";
  set cfe(result:$w) "";

  if {$cfe(boot) && $cfe(cagain:$w)} {
    write_to_cfed_nowait $w configall again;
  } else {
    write_to_cfed_nowait $w configall;
  }
}

proc compile_one {w cpart} {
  global cfe cfek cfecl;

  set_all_state $w disabled $w;
 
  set p [$w.f2.srcs curselection];
  set src [$w.f2.srcs get $p];

  set part $cfe(partstr:$cpart);
  set kind $cfek($src:$w);
  set class_name $cfecl($src:$w);

  if !$cfe(boot) {
    set cfe(start:$w) -1;
    
    if {$cfe(new:$w) && $cpart} {
      set part_no [expr $cpart + 6];
    } else {
      set part_no [expr $cpart + 1];
    }
    
    if {$part_no == 10} {
      set part_no ":";
    }
    
    SendOZ "CheckVersion:[this_school_name $w]|$part_no|$class_name|$kind";
    
    tkwait variable cfe(start:$w);
    
    if {$cfe(start:$w) || $cpart < 0} {
      set_all_state $w normal;
      return;
    }
  }

  set ids {};

  if {$cfe(boot) < 2} {
    if {$cpart == 3} {
      set ids \
	"[eval write_to_cfed $w sb '$class_name' 0] \
	[eval write_to_cfed $w sb '$class_name' 1]";
    } elseif {$cpart == 4} {
      set ids "[eval write_to_cfed $w sb '$class_name']";
    } elseif {$cpart >= 0} {
      set ids "[eval write_to_cfed $w sb '$class_name' $cpart]";
    }
  } 

  
  puts_for_debug $ids;

  set cfe(msg:$w) "";

  removeinput $cfe(cfed:$w);
  addinput -read $cfe(cfed:$w) "read_from_cfed_for_compile_one $w %F \"$ids\"";
  
  if {$cfe(boot) && $cfe(again:$w)} {
    write_to_cfed_nowait $w compile $src $part again;
  } else {
    write_to_cfed_nowait $w compile $src $part;
  }
}

proc compile_all {w cpart} {
  global cfe cfek cfecl;

  set_all_state $w disabled $w;

  set part $cfe(partstr:$cpart);

  if $cfe(retry:$w) {
    write_to_cfed $w reset;
  }

  set ids {};
  set srcs {};

  if {$cfe(boot) < 2} {

    set classes {};
    set kinds {};
    
    set i 0;
    foreach src $cfe(files:$w) {

      if {!$cfe(retry:$w) &&
	    [info exist cfe(result:$cpart:$w:$src)] && \
	      [lindex $cfe(result:$cpart:$w:$src) 0] != 1} {
	incr i;
	continue;
      } 

      set class_name $cfecl($src:$w);
      
      lappend classes $class_name;
      lappend srcs $src;
      lappend kinds $cfek($src:$w);
      
      incr i;
    }
    
    if !$cfe(boot) {
      set cfe(start:$w) -1;
      
      if {$cfe(new:$w) && $cpart} {
	set part_no [expr $cpart + 6];
      } else {
	set part_no [expr $cpart + 1];
      }
      
      if {$part_no == 10} {
	set part_no ":";
      }
      
      SendOZ \
	"CheckVersions:[this_school_name $w]|$part_no|{$classes}|{$kinds}";
      
      tkwait variable cfe(start:$w);
      
      if {$cpart < 0} {
	set_all_state $w normal;
	return;
      }
    }
    
    set i 0;
    foreach class_name $classes {
      
      if {!$cfe(boot) && [lindex $cfe(start:$w) $i]} {
	set srcs [lreplace $scrs $i $i];
	incr i;
	continue;
      }

      if {$cpart == 3} {
	lappend ids \
	  "[eval write_to_cfed $w sb '$class_name' 0] \
		[eval write_to_cfed $w sb '$class_name' 1]";
      } elseif {$cpart == 4} {
	lappend ids "[eval write_to_cfed $w sb '$class_name']";
      } elseif {$cpart >= 0} {
	lappend ids "[eval write_to_cfed $w sb '$class_name' $cpart]";
      }
      
      incr i;
    }
    
    if {$cpart >= 0 && $ids == ""} {
      set_all_state $w normal;
      return;
    }
    
#    puts_for_debug $ids;
  }
    
  removeinput $cfe(cfed:$w);
  addinput -read $cfe(cfed:$w) \
    "read_from_cfed_for_compile_all $w %F $cpart \"$srcs\" \"$ids\"";
    
  $w.f2.srcs select clear;
  $w.f2.srcs yview 0;
  update idletasks;

  set cfe(msg:$w) "";
  set cfe(result:$w) "";

  if {$cfe(boot) && $cfe(again:$w)} {
    write_to_cfed_nowait $w all $part again;
  } else {
    write_to_cfed_nowait $w all $part;
  }
}
  
proc read_from_cfed_for_compile_all {w f cpart {srcs {}} {ids {}}} {
  global cfe label;

  gets $f line;

  puts_for_debug $line;

  if [is_success $line] {
    removeinput $cfe(cfed:$w);
    addinput -read $cfe(cfed:$w) "read_from_cfed $w %F";

    if {$cfe(msg:$w) != ""} {
      set cfe(generic:$w) "$cfe(msg:$w)";
      ShowResult [this_school_name $w] $cfe(msg:$w);
    }

    if {$cfe(result:$w) != ""} {
      ShowResult [this_school_name $w] $cfe(result:$w);
    }

    set_all_state $w normal;
    
  } elseif {[set i [lsearch -exact $cfe(files:$w) $line]] >= 0} {
    $w.f2.srcs select from $i;
    $w.f2.srcs yview $i;
    update idletasks;

  } elseif ![string first "done" $line] {
    set status [string index $line 5];
    set src [string range $line 7 end];

    set i [lsearch -exact $srcs $src];

    set_status_of_all $w $src $status "$cfe(msg:$w)" $cpart;

    if {$cfe(msg:$w) != ""} {
      append cfe(result:$w) "$src\n$cfe(msg:$w)";
    }

    set cfe(msg:$w) "";
    
# for synchronize
#    write_to_cfed_nowait $w "continue";

    if {$ids == ""} {
      return;
    }

    if !$status {
      foreach id [lindex $ids $i] {
	puts_for_debug $id;
	if $cfe(boot) {
	  if {[glob -nocomplain $cfe(boot-path)/$id/private.cl] != ""} {
	    SendOZ "Install:$cfe(boot-path)/$id/private.cl";
	  }
	} else {
	  if {[glob -nocomplain $cfe(path)/$id/*] != ""} {
	    SendOZ "RegisterClass:$id";
	  }
	}
      }
    }
	
  } elseif {[string first "you need to generate" $line] >= 0} {
    $w.f3.generic.m enable $label(All);
    set cfe(msg:$w) "$line\n";
  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc read_from_cfed_for_compile_one {w f {ids {}}} {
  global cfe label;

  gets $f line;

  puts_for_debug $line;

  if [is_success $line] {
    removeinput $cfe(cfed:$w);
    addinput -read $cfe(cfed:$w) "read_from_cfed $w %F";

    if ![get_status $line] {
      foreach id $ids {
	if $cfe(boot) {
	  if {[glob -nocomplain $cfe(boot-path)/$id/private.cl] != ""} {
	    SendOZ "Install:$cfe(boot-path)/$id/private.cl";
	  }
	} else {
	  if {[glob -nocomplain $cfe(path)/$id/*] != ""} {
	    SendOZ "RegisterClass:$id";
	  }
	}
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
	  
      set school_name [this_school_name $w];

      if {$msg != ""} {
	ShowResult $school_name $msg;
      }

      if {$p >= 0} {
	set msg [string range $cfe(msg:$w) $p end];
	set cfe(generic:$w) "$msg";
	ShowResult $school_name $msg;
	$w.f3.generic.m enable $label(All);
      }
    }

    set_all_state $w normal;

  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc read_from_cfed_for_config_one {w f {ids {}}} {
  global cfe;

  gets $f line;

#  puts_for_debug $line;

  if [is_success $line] {
    removeinput $cfe(cfed:$w);
    addinput -read $cfe(cfed:$w) "read_from_cfed $w %F";
    
    if ![get_status $line] {
      if $cfe(boot) {
	foreach id $ids {
	  if {[glob -nocomplain $cfe(boot-path)/$id/private.cl] != ""} {
	    SendOZ "Install:$cfe(boot-path)/$id/private.cl";
	  }
	}
      } else {
	if {[glob -nocomplain $cfe(path)/$ids/*] != ""} {
	  SendOZ "RegisterClass:$id";
	}
      }
    }

    if {$cfe(msg:$w) != ""} {
      ShowShortResult [this_school_name $w] $cfe(msg:$w);
    }

    set_all_state $w normal;

  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc read_from_cfed_for_config_all {w f {srcs {}} {ids {}}} {
  global cfe;

  gets $f line;

#  puts_for_debug $line;
  
  if [is_success $line] {
    removeinput $cfe(cfed:$w);
    addinput -read $cfe(cfed:$w) "read_from_cfed $w %F";

    if {$cfe(msg:$w) != ""} {
      ShowShortResult [this_school_name $w] $cfe(msg:$w);
    }

    set_all_state $w normal;

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
      if $cfe(boot) {
	foreach i $id {
	  if {[glob -nocomplain $cfe(boot-path)/$i/private.cl] != ""} {
	    SendOZ "Install:$cfe(boot-path)/$i/private.cl";
	  }
	}
      } else {
	if {[glob -nocomplain $cfe(path)/$id/*] != ""} {
	  SendOZ "RegisterClass:$id";
	}
      }
    }
  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc set_status_of_all {w src status msg cpart} {
  global cfe;
  
  set cfe(result:$cpart:$w:$src) [list $status "$msg"];
  
  if {$cpart > 2} {
    set cfe(result:0:$w:$src) [list $status {}];
    set cfe(result:1:$w:$src) [list $status {}];
    
    if {$cpart == 4} {
      set cfe(result:1:$w:$src) [list $status {}];
    }
  }
}

proc is_success {buf} {
  if ![string first "TCL:Success" $buf] {
    return 1;
  } else {
    return 0;
  }
}

proc get_status {buf} {
  return [string index $buf [expr [string length $buf] - 1]];
}

proc read_from_cfed_for_generate {w f} {
  global cfe;

  gets $f line;
  
  puts_for_debug $line;

  if [is_success $line] {
    removeinput $cfe(cfed:$w);
    addinput -read $cfe(cfed:$w) "read_from_cfed $w %F";

    if {$cfe(boot) < 2 && ![get_status $line]}  {
      foreach gclass $cfe(generate:$w) {
	set vid [eval write_to_cfed $w sb '$gclass'];

	foreach id $vid {
	  if $cfe(boot) {
	    if {[glob -nocomplain $cfe(boot-path)/$id/private.cl] != ""} {
	      SendOZ "Install:$cfe(boot-path)/$id/private.cl";
	    }
	  } else {
	    if {[glob -nocomplain $cfe(path)/$id/*] != ""} {
	      SendOZ "RegisterClass:$id";
	    }
	  }
	}
      }
    }

    ShowResult [this_school_name $w] $cfe(msg:$w);

    set_all_state $w normal;

  } elseif ![string first "checkversion" $line] {
    if [check_version_for_generate $w [string range $line 13 end]] {
      write_to_cfed_nowait $w stop;
    } else {
      write_to_cfed_nowait $w "continue$cfe(boot)";
    }
    return;
  } else {
    append cfe(msg:$w) "$line\n";
  }
}

proc check_version_for_generate {w buf} {
  global cfe;

  set kind [lindex $buf 0];
  set class_name [lrange $buf 1 end];

  if $cfe(boot) {
    lappend cfe(generate:$w) $class_name;
    return 0;
  }

  set cfe(start:$w) -1;
     
  SendOZ "CheckVersion:[this_school_name $w]|0|$class_name|$kind";
  
  tkwait variable cfe(start:$w);

  if $cfe(start:$w) {
    return 1;
  }

  lappend cfe(generate:$w) $class_name;
  return 0;
}


proc read_from_cfed {w f} {
  global cfe;

  gets $f line;

#  puts_for_debug $line;

  if [is_success $line] {
    set cfe(success:$w) 1;
  } else {
    append cfe(buffer:$w) "$line$cfe(delim:$w)";
  }
}

proc write_to_cfed {args} {
  global cfe;

#  puts_for_debug $args;

  set w [lindex $args 0];

  set cfe(success:$w) 0;
  set cfe(buffer:$w) "";

  puts $cfe(cfed:$w) "[lrange $args 1 end]" 
  flush $cfe(cfed:$w);

  tkwait variable cfe(success:$w);

  return $cfe(buffer:$w);
}

proc write_to_cfed_nowait {args} {
  global cfe;

  set w [lindex $args 0];

  puts_for_debug $args;

  puts $cfe(cfed:$w) "[lrange $args 1 end]"; 
  flush $cfe(cfed:$w);
}

proc show_info {w msg {title {Info.}}} {
  global label cfe;

  set win [toplevel $w.info];
  wm title $win $title;

  frame $win.f1;
  scrollbar $win.f1.sb -command "$win.f1.msgs yview" -relief sunken -bd 1;
  text $win.f1.msgs -width 80 -height 25 -relief ridge -bd 2 \
    -yscrollcommand "$win.f1.sb set";
  
  frame $win.f2;
  button $win.f2.save -text "$label(Save)" \
    -relief flat -bd 1 -state disabled -command \
    "\
      $win.f2.save configure -state disabled;\
      my_file_selector $win.fsel save_log $w $cfe(pwd) file;\
      tkwait window $win.fsel;\
      $win.f2.save configure -state normal;\
    ";

  proc save_log {arg w} {
    set fid [open "$arg" w];
    puts $fid [$w.info.f1.msgs get 1.0 end];
    close $fid;
  }

  button $win.f2.close -text "$label(Close)" -state disabled -bd 1 \
    -relief flat -command "destroy $win";
  
  pack $win.f1 -fill both -expand yes;
  pack $win.f1.sb -side right -fill y;
  pack $win.f1.msgs -side left -fill both -expand yes;
  pack $win.f2 -fill x;
  pack $win.f2.save -side left -ipadx 15 -ipady 3;
  pack $win.f2.close -side left -expand yes -fill x -ipady 3;

  $win.f1.msgs insert end $msg;

  set_center $win;
  set_expandable $win;

  $win.f2.save configure -state normal;
  $win.f2.close configure -state normal;

  update idletasks;
  
  tkwait window $win;
}

proc this_school_name {w} {
  return [lindex [$w.f3.schoolName configure -text] 4];
}

proc input_name {w msg} {
  global close cfe label;

  set win [toplevel $w.input];

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

  checkbutton $win.f1.again -text "$label(Again)" \
    -onvalue "1" -offvalue "0" -variable cfe(gagain:$w) -relief flat;

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -text "$label(Exec)" -state disabled -bd 1 \
    -command {
      global close;
      
      set close done;
    }
  button $win.f2.cancel -text "$label(Cancel)" -bd 1 \
    -command {
      global close;
      
      set close cancel;
    }

  pack $win.f1 -fill both -padx 10 -pady 10;
  pack $win.f1.title -fill both -expand yes -padx 3 -pady 3;
  pack $win.f1.className -padx 10 -pady 10 -fill x -expand yes -ipady 5;
  pack $win.f1.again -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;

  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

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

proc cfe_open {} {
  global cfe;

  SendOZ "LaunchSP:";
}

proc cfe_close {w} {
  global cfe cfew;

  set school_name [this_school_name $w];

  write_to_cfed_nowait $w quit;

  removeinput $cfe(cfed:$w);
  close $cfe(cfed:$w);

  if !$cfe(boot) {
    SendOZ "Close:$school_name";
    RecvOZ;

    delete_from_windows $school_name;
  }

  destroy $w;
}

proc close_all {} {
  global cfe cfew;
  
  foreach i $cfe(allwin) {
    cfe_close $cfew($i);
  }
}

proc quit {} {
  global cfe env;
  
  switch $cfe(boot) {
    0 {
      SendOZ "Quit:";
    }
    1 {
      SendOZ "Quit:$cfe(pwd)|$cfe(lang)";
    }
    2 {
      close_all;
      set f [open $env(HOME)/.oz++cferc w ];
      puts $f "$cfe(pwd)";
      puts $f "$cfe(lang)";
      close $f;
      exit;
    }
  }
}

proc set_files {name w} {
  global cfe label cfek cfecl;

  if {[lindex $name 0] == "dir"} {
    foreach j [lrange $name 1 end] {
      write_to_cfed $w add $j;
      set files [write_to_cfed $w ls $j];
    }
  } else {
    set files [lrange $name 1 end];
    eval write_to_cfed $w add $files;
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

      set buf [write_to_cfed $w info this $j];
      set cfek($j:$w) [lindex $buf 0];
      set cfecl($j:$w) [lindex $buf 1];
    }
  }

  $w.f3.compile.m enable "$label(All)";
  $w.f3.config.m enable "$label(All)";

  set_all_state $w normal;
}

proc remove_files {w} {
  global cfe label;

  set range [$w.f2.srcs curselect];
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

  eval write_to_cfed $w remove $srcs
  set cfe(files:$w) [lreplace $cfe(files:$w) $from $i];
  set cfe(files_ino:$w) [lreplace $cfe(files_ino:$w) $from $i];

  if {$cfe(files:$w) == ""} {
    $w.f3.compile.m disable "$label(All)";
    $w.f3.config.m disable "$label(All)";
  }

  $w.f2.srcs select clear;
  $w.f3.school.m disable "$label(Remove)";
}

proc delete_from_windows {school_name} {
  global cfe cfew;

  foreach i $cfe(allwin) {
    if {$i != $school_name} {
      $cfew($i).f3.window.m delete "$school_name";
    }
  }
}

proc set_all_windows {w again} {
  global cfe cfew;

  set this [this_school_name $w];

  foreach i $cfe(allwin) {
    if {$i == $this} {
      set state disabled;
    } else {
      set state normal;
    }
    $w.f3.window.m add command -label $i -state $state \
      -command "wm deiconify $cfew($i); raise $cfew($i)";
  }

  if $again {
    return;
  }

  foreach i $cfe(allwin) {
    if {$i != $this} {
      $cfew($i).f3.window.m add command -label $this \
	-command "wm deiconify $cfew($this); raise $cfew($this)";
    }
  }

  if !$cfe(boot) {
    SendOZ "AddWindow:$this|$w";
  }
}

proc set_commands_state_for_one {w state} {
  global cfe;

  foreach i $cfe(commands) {
    $w.f3.[lindex $i 0].m $state [lindex $i 1];
  }
}

proc exec_compile {w mode} {
  global label cfe;

  set_all_state $w disabled;

  set win [toplevel $w.co];

  wm title $win "Compile";

  frame $win.f5 -relief ridge -bd 2;

  if 0 {
    radiobutton $win.f5.id -text "$label(ID)" -value "-1" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.if -text "$label(Public & Protected)" -value "3" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.private -text "$label(Implementation)" -value "2" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.all -text "$label(Allpart)" -value "4" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.public -text "$label(Public)" -value "0" \
      -variable cfe(part:$w) -relief flat;
    radiobutton $win.f5.protected -text "$label(Protected)" -value "1" \
      -variable cfe(part:$w) -relief flat;
  }

  button $win.f5.id -text "$label(ID)" -bd 1 \
    -command "destroy $win; compile_$mode $w -1";
  button $win.f5.if -text "$label(Public & Protected)" -bd 1 \
    -command "destroy $win; compile_$mode $w 3";
  button $win.f5.private -text "$label(Implementation)" -bd 1 \
    -command "destroy $win; compile_$mode $w 2";
  button $win.f5.all -text "$label(Allpart)" -bd 1 \
    -command "destroy $win; compile_$mode $w 4";
  button $win.f5.public -text "$label(Public)" -bd 1 \
    -command "destroy $win; compile_$mode $w 0";
  button $win.f5.protected -text "$label(Protected)" -bd 1 \
    -command "destroy $win; compile_$mode $w 1";

  checkbutton $win.f5.new -text "$label(New Version)" \
    -onvalue "1" -offvalue "0" -variable cfe(new:$w) -relief flat;
  checkbutton $win.f5.again -text "$label(Again)" \
    -onvalue "1" -offvalue "0" -variable cfe(again:$w) -relief flat;
  checkbutton $win.f5.retry -text "$label(Retry)" \
    -onvalue "1" -offvalue "0" -variable cfe(retry:$w) -relief flat;

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -text "$label(Exec)" -bd 1 \
    -command "destroy $win; compile_$mode $w";
  button $win.f2.cancel -text "$label(Cancel)" -bd 1 \
    -command "destroy $win; set_all_state $w normal";

  pack $win.f5 -fill both -padx 10 -pady 10;
  if !$cfe(boot) {
    if {$mode == "one"} {
      pack $win.f5.id $win.f5.public $win.f5.protected $win.f5.if \
	$win.f5.private $win.f5.all \
	  -side top -ipadx 5 -ipady 5 -padx 5 -pady 5 -anchor nw -fill x;
      pack $win.f5.new \
	  -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
    } else {
      pack $win.f5.id $win.f5.if $win.f5.private $win.f5.all \
	  -side top -ipadx 5 -ipady 5 -padx 5 -pady 5 -anchor nw -fill x;
      pack $win.f5.new $win.f5.retry \
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
      pack $win.f5.id $win.f5.if $win.f5.private $win.f5.all \
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

  tkwait window $win;
}

proc exec_config {w mode} {
  global label cfe;

  set_all_state $w disabled;

  set win [toplevel $w.co];

  wm title $win "Configure";

  frame $win.f5 -relief ridge -bd 2;
  checkbutton $win.f5.retry -text "$label(Retry)" \
    -onvalue "1" -offvalue "0" -variable cfe(cretry:$w) -relief flat;
  checkbutton $win.f5.again -text "$label(Again)" \
    -onvalue "1" -offvalue "0" -variable cfe(cagain:$w) -relief flat;

  if {$cfe(boot) || $mode != "one"} {
    pack $win.f5 -fill both -padx 10 -pady 10;

    if {$mode != "one"} {
      pack $win.f5.retry -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
    }

    if $cfe(boot) {
      pack $win.f5.again -side left -ipady 5 -padx 5 -pady 5 -anchor w -fill x;
    }
  }

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -text "$label(Default)" -bd 1 \
    -command "destroy $win; config_$mode $w";
  if {!$cfe(boot) && $mode == "one"} {
    button $win.f2.custom -text "$label(Custom)" -state disabled -bd 1 \
      -command "destroy $win; config_$mode $w";
  }
  button $win.f2.cancel -text "$label(Cancel)" -bd 1 \
    -command "destroy $win; set_all_state $w normal";
  
  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 5 -ipady 5 -pady 5 -anchor c;
  if {!$cfe(boot) && $mode == "one"} {
    pack $win.f2.custom -side left -ipadx 5 -ipady 5 -padx 40 -pady 5;
  }
  pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $win;

  tkwait window $win;
}

proc exec_generate_all {w} {
  global label cfe;

  set win [toplevel $w.co];

  set_all_state $w disabled $win;

  wm title $win "Generate";

  frame $win.f2;
  frame $win.f2.f3 -relief sunken -bd 1;
  button $win.f2.f3.done -text "$label(Exec)" -bd 1 \
    -command "destroy $win; generate_all $w";
  button $win.f2.cancel -text "$label(Cancel)" -bd 1 \
    -command "destroy $win; set_all_state $w normal";
  
  pack $win.f2 -fill x -expand yes;
  pack $win.f2.f3 -side left -ipadx 5 -padx 40 -pady 5;
  pack $win.f2.f3.done -ipadx 15 -ipady 5 -pady 5 -anchor c;
  pack $win.f2.cancel -side right -ipadx 5 -ipady 5 -padx 40 -pady 5;

  set_center $win;

  tkwait window $win;
}

proc new_win {school_name school_file {again 0}} {
  global cfew cfe label env;

  if $again {
    destroy $cfew($school_name);
    set w [toplevel $cfew($school_name)];
  } elseif {[info exists cfew($school_name)] && \
	      [winfo exists $cfew($school_name)]} {
    wm deiconify $cfew($school_name);
    raise $cfew($school_name);
    return;
  } else {
    set cfew($school_name) .s[incr cfe(win)];
    lappend cfe(allwin) $school_name;
    set w [toplevel $cfew($school_name)];
    set cfe(files:$w) {};
    set cfe(files_ino:$w) {};
    set cfe(success:$w) 1;
    set cfe(delim:$w) " ";
  }
  
  wm title $w "OZ++ CFE ($school_name)";

  set cfe(commands) {};
  set cfe(commands) {};

  frame $w.f3 -relief raised -bd 1;
  menubutton $w.f3.school -text "$label(School)" -menu $w.f3.school.m;
  menu $w.f3.school.m;
  if !$cfe(boot) {
    $w.f3.school.m add command -label "$label(Open)" -command "cfe_open";
    $w.f3.school.m add command -label "$label(Close)" -command "cfe_close $w";
    $w.f3.school.m add separator;
  }
  $w.f3.school.m add command -label "$label(Add)" \
    -command "add_files $w";
  $w.f3.school.m add command -label "$label(Remove)" -state disabled \
    -command "remove_files $w";
  $w.f3.school.m add separator;
  $w.f3.school.m add command -label "$label(Preference...)" \
    -command "preference $w";
  $w.f3.school.m add separator;
  $w.f3.school.m add command -label "$label(Quit)" -command "quit";

  label $w.f3.schoolName -text "$school_name" \
    -relief ridge -anchor e;

  proc add_files {w} {
    global cfe;

    set_all_state $w disabled;
    my_file_selector $w.fsel set_files $w $cfe(pwd) any *.oz {} 0; 
    tkwait window $w.fsel;
    set_all_state $w normal;
  }

  proc set_all_state {w state {grab {}}} {
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

  lappend cfe(commands) [list school "$label(Remove)"];
  
  menubutton $w.f3.compile -text "$label(Compile)" -menu $w.f3.compile.m;
  menu $w.f3.compile.m;
  $w.f3.compile.m add command -label "$label(One)" -state disabled \
    -command "exec_compile $w one";
  $w.f3.compile.m add command -label "$label(All)" -state disabled \
    -command "exec_compile $w all";

  lappend cfe(commands) [list compile "$label(One)"];

  menubutton $w.f3.config -text "$label(Configure)" -menu $w.f3.config.m;
  menu $w.f3.config.m;
  $w.f3.config.m add command -label "$label(One)" -state disabled \
    -command "exec_config $w one";
  $w.f3.config.m add command -label "$label(All)" -state disabled \
    -command "exec_config $w all";

  lappend cfe(commands) [list config "$label(One)"];

  menubutton $w.f3.generic -text "$label(Generic)" -menu $w.f3.generic.m;
  menu $w.f3.generic.m;
  $w.f3.generic.m add command -label "$label(One...)" \
    -command "generate_one $w";
  $w.f3.generic.m add command -label "$label(All)" -state disabled \
    -command "exec_generate_all $w";

  menubutton $w.f3.window -text "$label(Window)" -menu $w.f3.window.m;
  menu $w.f3.window.m;

  set cfe(allcommands) {school compile config generic window}

  tk_menuBar $w.f3 $w.f3.school $w.f3.compile \
    $w.f3.config $w.f3.generic $w.f3.window;
  focus $w.f3;

  frame $w.f2 -bd 2;
  label $w.f2.src -text "$label(Files)" -width 10 -anchor c \
    -relief raised -bd 1;
  scrollbar $w.f2.sbx -orient horiz -cursor sb_h_double_arrow \
    -command "$w.f2.srcs xview" -relief sunken -bd 1;
  scrollbar $w.f2.sby -command "$w.f2.srcs yview" -relief sunken -bd 1;
  listbox $w.f2.srcs -geometry 50x15 -exportselection no \
    -xscrollcommand "$w.f2.sbx set" \
      -yscrollcommand "$w.f2.sby set";

  if $again {
    foreach i $cfe(files:$w) {
      $w.f2.srcs insert end $i;
    }
  }
  
  menu $w.ones;
  $w.ones add command -label "$label(Compile)" \
    -command "exec_compile $w one";
  $w.ones add command -label "$label(Configure)" \
    -command "exec_config $w one";

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

  pack $w.f3 -fill x;

  if $cfe(boot) {
    pack $w.f3.school $w.f3.compile $w.f3.config \
      $w.f3.generic -side left -ipadx 5 -ipady 3  ;
  } else {
    pack $w.f3.school $w.f3.compile $w.f3.config \
      $w.f3.generic $w.f3.window -side left -ipadx 5;
  }

  pack $w.f3.schoolName -side right -expand yes -fill x \
    -pady 3 -ipady 1 -padx 5;

  pack $w.f2 -side left -fill both -expand yes;
#  pack $w.f2.src -side top -fill x -ipady 2;
  pack $w.f2.sbx -side bottom -fill x;
  pack $w.f2.sby -side right -fill y;
  pack $w.f2.srcs -side top -fill both -expand yes;


  if 0 {
    pack $w.f6 -fill x;
    pack $w.f6.verbose $w.f6.nolink $w.f6.nog -side left -padx 5 -pady 5;
  }

  set_all_windows $w $again;
  
  set_center $w;
  set_expandable $w;

  if !$again {
    set cfe(cfed:$w) [open "| $cfe(cfed) -c $cfe(path) -s $school_file" r+];
    set cfe(path) $env(OZROOT)/$cfe(path);
    set cfe(delim:$w) "\n";
    addinput -read $cfe(cfed:$w) "read_from_cfed $w %F";
    set buf [write_to_cfed $w wanted];
    set cfe(delim:$w) " ";

    if {[string first "you need to generate" $buf] >= 0} {
      set cfe(generic:$w) "$buf";
      $w.f3.generic.m enable $label(All);
      ShowResult $school_name $buf;
    }

    $w.f3.school.m invoke $label(Add);
  }
}

# Main part

wm withdraw .;

global cfe argc argv;
				     
set cfe(win) 0;
set cfe(allwin) {};
set cfe(class) "";
set cfe(boot-path) "$env(OZROOT)/lib/boot-class";
set cfe(path) "";
set cfe(boot) 2;
set cfe(lang) "english";
set cfe(pwd) [pwd];
set cfe(cfed) "$env(OZROOT)/bin/cfed.sh -at";

set cfe(partstr:-1) id;
set cfe(partstr:0) public;
set cfe(partstr:1) protected;
set cfe(partstr:2) private;
set cfe(partstr:3) if;
set cfe(partstr:4) all;

set i 0;

if [file exist $env(HOME)/.oz++cferc] {
  set f [open $env(HOME)/.oz++cferc r];
  set cfe(pwd) [gets $f];
  set cfe(lang) [gets $f];
  close $f;
}
				     
if {$argc > $i} {
  set cfe(pwd) [lindex $argv $i];
  incr i;
}

if ![file isdirectory $cfe(pwd)] {
  set cfe(pwd) [pwd];
}

				     
if {$argc > $i} {
  set buf [lindex $argv $i];
  incr i;

  if {$buf == "english" || $buf == "japanese"} {
    set cfe(lang) $buf;
  }
}

if {$argc > $i} {
  set buf [lindex $argv $i];
  incr i;
  if {$buf == "boot"} {
    set cfe(boot) 1;
  } elseif {$buf == "unix"} {
    set cfe(boot) 2;
  } else {
    set cfe(boot) 0;
  }
}

if {$argc > $i} {
  set cfe(path) [lindex $argv $i];
  incr i;
} 

if {$argc > $i} {
  set cfe(class) [lindex $argv $i];
} 

lang_of_$cfe(lang);

if {$cfe(boot) < 2 && $cfe(debug_mode)} {
  rename SendOZ orig_SendOZ;
  proc SendOZ {str} {
    puts_for_debug $str;
    orig_SendOZ $str;
  }
}

if {$cfe(boot) < 2} {
  if {$cfe(class) == ""} {
    InputClassObject;
  }
} else {
  set cfe(path) lib/boot-class;
}

if $cfe(boot) {
  set cfe(cfed) "$env(OZROOT)/bin/cfed.sh -bt";
  if {$cfe(path) != ""} {
    Open "$env(OZROOT)/etc/boot-school" etc/boot-school;
  }
}

# For Unix 

if {$cfe(boot) == 2} {
  rename SendOZ junky_SendOZ;
  rename RecvOZ junky_RecvOZ;
  proc SendOZ {str} {}
  proc RecvOZ {} {}
} 

# For testing

if {!$cfe(boot) && $cfe(test_mode)} {
  Open "test" $env(OZROOT)/etc/boot-school;
}


