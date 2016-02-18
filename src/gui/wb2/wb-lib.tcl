#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# Library for Workbench, CFE, School browser, ...
#

# debug 

proc puts_for_debug {msg} {
  global wb;

  if 1 {
    puts stderr $msg;
  }
}

# Global functions

proc SetResult {school_name kind result} {
  global wbw wb;

  if {$kind == "WB"} {
    set w $wbw($kind);
  } else {
    set w $wbw($school_name:$kind);
  }

#  puts_for_debug $result;

  set wb(result:$w) $result;
}

proc InputClassObject {} {
  preference .;
}

proc SetClassPath {path} {
  global wb;

  set wb(path) $path;
  
#  puts_for_debug $wb(path);
  
#  if {$wb(boot) < 2} {
#    SendOZ "FinishSettingClassPath:";
#  }
}

proc ShowResult {school_name kind msg} {
  global wbw label;
  
  set w $wbw($school_name:$kind);
  
  if {$msg != ""} {
    if ![tk_dialog $w.msg "$kind info." $label(result) \
	 questhead 0 $label(Yes) $label(No)] {
      show_info $w $msg;
    }
  }
}

proc ShowShortResult {school_name kind msg} {
  global wbw;
  
  set w $wbw($school_name:$kind);
  tk_dialog $w.msg "$kind info." "$msg" info 0 "Close";
}

# Local functions

proc lang_of_english {} {
  global label;

  set label(Add) "Add...";
  set "label(Add Property)" "Add Property...";
  set label(Again) "Again";
  set label(All) "All...";
  set "label(Allocation Info.)" "Allocation Info. (protected / private)";
  set label(Allpart) "All";
  set label(Browse...) "Browse...";
  set label(CB) "CB";
  set label(Cancel) "Cancel";
  set label(Children) "Show Children";
  set label(Classname) "Name";
  set label(Clear) "Clear";
  set label(Close) "Close";
  set label(Compile) "Compile";
  set label(Configuration) "Configuration";
  set label(Configure) "Configure";
  set label(Copy) "Copy";
  set "label(Current)" "Set Current";
  set "label(Current directory)" "Current directory";
  set label(Custom) "Customize";
  set label(Cut) "Cut";
  set label(Data) "Data";
  set label(Default) "Default";
  set label(Delete) "Delete";
  set label(Detail) "Detail";
  set "label(Discard Classes)" "Discard Classes";
  set "label(Discard Files)" "Discard Files";
  set label(Done) "Done";
  set label(Duplicate...) "Duplicate...";
  set label(Edit) "Edit";
  set label(English) "English";
  set label(Exec) "Go";
  set label(Export) "Export";
  set "label(Export to Launcher)" "Export to Launcher";
  set label(Files) "Files";
  set label(Generic) "Generic";
  set label(Generate) "Generate";
  set label(Goto) "Please input a line-number";
  set label(Goto...) "Goto...";
  set label(ID) "New";
  set label(Implementation) "Implementation";
  set label(Japanese) "Japanese";
  set label(Kind) "Kind";
  set label(Language) "Language";
  set label(Members) "Member";
  set label(Methods) "Methods";
  set "label(New...)" "New...";
  set "label(New Classname)" "Please input a new class name.";
  set "label(New from a file...)" "Add...";
  set "label(Name of Class)" "Name of Class";
  set "label(New Version)" "New Version";
  set label(Next) "Next";
  set label(Now) "Now";
  set label(One) "One...";
  set label(One...) "One...";
  set label(Open) "Open";
  set label(Ops) "Operation";
  set label(Other...) "Other...";
  set label(Overwrite) "Overwrite";
  set "label(Parent Classes)" "Parent Classes";
  set label(Pack) "Package";
  set label(Parts) "Parts";
  set "label(Part #)" "Part #";
  set label(Paste) "Paste";
  set label(Pointer) "Pointer";
  set label(Preference...) "Preference...";
  set label(Prev) "Previous";
  set label(Property) "Property";
  set label(Protected) "Protected";
  set "label(Public & Protected)" "Public & Protected";
  set label(Public) "Public";
  set label(Quit) "Quit";
  set label(Remove) "Remove";
  set label(Rename...) "Rename...";
  set label(Retry) "Retry";
  set label(SB) "School browser";
  set label(SB...) "School browser...";
  set label(CB...) "Catalog browser...";
  set label(Save) "Save";
  set "label(Show Property)" "Show Property...";
  set label(CFE) "Compiler";
  set label(CFE...) "Compiler...";
  set label(Search) "Please input a keyword";
  set label(Search...) "Search...";
  set label(Select) "Select";
  set label(Versions...) "Versions...";
  set label(Visible) "Visible";
  set label(WB) "Workbench";
  set label(Window) "Window";
  set label(Zero) "Zero";

  set "label(from Public)" "from Public";
  set "label(from Protected)" "from Protected";
  set "label(from Implementation)" "only Implementation";

  set label(input) "Plsease input a name of class.";
  set "label(input school)" "Please input a name of school.";
  set label(result) "Some messages were generated.\nDo you examine now ?";
  set "label(show children)" "This operation takes some time...";
  set "label(quit msg)" "Really stop this Workbench ?";
  set "label(real msg)" "Some messages were generated.";
  set "label(no config msg)" "Cannot configure formal generic class.";
  set "label(remove property msg)" "Remove these selected properties ?";
  set "label(cannot remove msg)" "Cannot remove any properties.";
  set "label(cannot add msg)" "Cannot add these properties.";

  set label(Yes) "Yes";
  set label(No) "No";

  set label(Close:edit) "$label(Done)";
  set label(Edit:edit) "$label(Save)";
  set label(Close:cancel) "$label(Close)";
  set label(Edit:cancel) "$label(Edit)";
}

proc lang_of_japanese {} {
  global label;

  set label(Add) "追加...";
  set "label(Add Property)" "プロパティの追加...";
  set label(Again) "再コンパイル";
  set label(All) "すべて...";
  set "label(Allocation Info.)" "アロケーション情報 (プロテクティッド / プライベート)";
  set label(Allpart) "すべて";
  set label(Browse...) "ブラウズ...";
  set label(CB) "しぃびぃ";
  set label(Cancel) "取消";
  set label(Children) "子孫クラスを表示";
  set label(Classname) "クラス名";
  set label(Clear) "消去";
  set label(Close) "閉じる";
  set label(Compile) "コンパイル";
  set label(Configuration) "コンフィギュレーション";
  set label(Configure) "コンフィギュア";
  set label(Copy) "コピー";
  set "label(Current)" "カレントスクールに設定";
  set "label(Current directory)" "現在のディレクトリ";
  set label(Custom) "カスタマイズ";
  set label(Cut) "カット";
  set label(Data) "データ";
  set label(Default) "デフォルト";
  set label(Delete) "消去";
  set label(Detail) "詳細を見る";
  set "label(Discard Classes)" "クラスを無視する";
  set "label(Discard Files)" "ファイルを無視する";
  set label(Done) "終了";
  set label(Duplicate...) "複製...";
  set label(Edit) "編集";
  set label(English) "英語";
  set label(Exec) "実行";
  set label(Export) "スクールディレクトリへ";
  set "label(Export to Launcher)" "ラウンチャへ";
  set label(Files) "ソースファイル";
  set label(Generic) "ジェネリック";
  set label(Generate) "生成";
  set label(Goto) "移動する行番号を入力して下さい。";
  set label(Goto...) "行の移動...";
  set label(ID) "新規クラス";
  set label(Implementation) "実装";
  set label(Japanese) "日本語";
  set label(Kind) "種類";
  set label(Language) "言語";
  set label(Members) "メンバ";
  set label(Methods) "メソッド";
  set "label(New...)" "新規スクール...";
  set "label(New Classname)" "新しいクラス名を入力して下さい";
  set "label(New from a file...)" "登録...";
  set "label(Name of Class)" "クラス名";
  set "label(New Version)" "新規バージョン";
  set label(Next) "次へ";
  set label(Now) "今の";
  set label(One) "一つ...";
  set label(One...) "一つ...";
  set label(Open) "開く";
  set label(Ops) "操作";
  set label(Other...) "他の...";
  set label(Overwrite) "上書き";
  set label(Pack) "パッケージ...";
  set "label(Parent Classes)" "親クラス";
  set label(Parts) "パート";
  set "label(Part #)" "パート番号";
  set label(Paste) "ペースト";
  set label(Pointer) "ポインタ";
  set label(Preference...) "初期設定";
  set label(Prev) "前へ";
  set label(Property) "プロパティ";
  set label(Protected) "プロテクティッド";
  set "label(Public & Protected)" "パブリックとプロテクティッド";
  set label(Public) "パブリック";
  set label(Quit) "終了";
  set label(Remove) "削除";
  set label(Rename...) "改名...";
  set label(Retry) "もう一度全部";
  set label(SB) "スクールブラウザ";
  set label(SB...) "スクールブラウザ...";
  set label(CB...) "カタログブラウザ...";
  set label(Save) "保存";
  set "label(Show Property)" "プロパティのブラウズ...";
  set label(CFE) "コンパイラ";
  set label(CFE...) "コンパイラ...";
  set label(Search) "検索するものを入力して下さい。"
  set label(Search...) "検索...";
  set label(Select) "選択";
  set label(Versions...) "バージョン...";
  set label(Visible) "公開";
  set label(WB) "ワークベンチ";
  set label(Window) "ウィンドウ";
  set label(Zero) "ゼロ";

  set "label(from Public)" "パブリックから";
  set "label(from Protected)" "プロテクティッドから";
  set "label(from Implementation)" "実装だけ";

  set label(input) "クラス名を入力して下さい。";
  set "label(input school)" "スクールの名前を入力して下さい。";
  set label(result) "何かメッセージが出ていますよ。\nみて見ますか？";
  set "label(show children)" "子孫クラスの表示は少々時間がかかりますが？";
  set "label(quit msg)" "本当にこのワークベンチを終了させますか ?"
  set "label(real msg)" \
    "何かメッセージが出ていますよ。"

  set "label(no config msg)" \
    "フォーマルジェネリッククラスはコンフィギュアできません";
  set "label(remove property msg)" \
    "本当にこれらのプロパティを削除しますか";
  set "label(cannot remove msg)" \
    "いくつかのプロパティは削除できません";
  set "label(cannot add msg)" \
    "プロパティを追加できません";

  set label(Yes) "はい";
  set label(No) "いいえ";

  set label(Close:edit) "$label(Done)";
  set label(Edit:edit) "$label(Save)";
  set label(Close:cancel) "$label(Close)";
  set label(Edit:cancel) "$label(Edit)";
}

proc preference {win} {
  global wb close label wbw wbk;

  set lang $wb(lang);

  set w [toplevel $win.pref];

  wm title $w "Preference";
  
  frame $w.f0 -relief ridge -bd 2;

  frame $w.f0.f1;
  label $w.f0.f1.class -text "$label(Name of Class)" -width 20 -anchor e;
  entry $w.f0.f1.class_name -relief ridge -width 40;
  $w.f0.f1.class_name insert end $wb(class);

  bind $w.f0.f1.class_name <Return> { };
  bind $w.f0.f1.class_name <Tab> { };

  frame $w.f0.f4;
  label $w.f0.f4.pwd -text "$label(Current directory)" -width 20 -anchor e;
  entry $w.f0.f4.pwd_name -relief ridge;
  $w.f0.f4.pwd_name insert end $wb(pwd);

  proc set_pwd {arg w} {
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
    -variable wb(lang) -relief flat;
  radiobutton $w.f0.f2.english -text "$label(English)" -value "english" \
    -variable wb(lang) -relief flat;

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
    if {$pwd_name != "" && $pwd_name != $wb(pwd)} {
      set wb(pwd) $pwd_name;
      cd $wb(pwd);

#      foreach i $wb(all) {
#	if [info exists wb(cfed:$i)] {
#	  if [info exists wbw($i:CFE)] {
#	    write_to_cfed $wbw($i:CFE) cd $wb(pwd);
#	  } else {
#	    write_to_cfed $wbw($i:SB) cd $wb(pwd);
#	  }
#	}
#      }
    }
    if {$class_name != "" && "$class_name" != "$wb(class)"} {
      set wb(class) $class_name;
      SendOZ "SetClass:$class_name";
    }

    if {$lang != $wb(lang)} {
      lang_of_$wb(lang);

      foreach i $wb(allwin) {
	set w2 $wbw($i)
	switch $wbk($w2) {
	  "CFE" {
	    cfe_school_menu $w2;
	    cfe_compile_menu $w2
	    cfe_config_menu $w2;
	    cfe_generic_menu $w2;
	    cfe_prepare_for_set_status;
	  }
	  "SB" {
	    sb_school_menu $w2;
	    sb_ops_menu $w2;
	    sb_set_mode $w2;
	  }
	  "CB" {
	    global cb;

	    switch $cb(kind:$w2) {
	      CB1 {
		cb_src_cb_menu $w2;
		cb_src_ops_menu $w2;
	      }
	      "CB2" {
		cb_if_cb_menu $w2;
		cb_if_ops_menu $w2;
	      }
	      "CB3" {
		cb_conf_cb_menu $w2;
	      }
	    }
	  }
	  "WB" {
	    wb_wb_menu $w2;
	    wb_ops_menu $w2;
	    wb_srcs_menu $w2;
	  }
	}
      }
    }
  }

  if {$wb(boot) < 2 && $wb(class) == ""} {
    quit;
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

proc read_from_cfed {w f} {
  global wb;

  gets $f line;

#  puts_for_debug $line;

  if [is_success $line] {
    set wb(success:$w) 1;
  } else {
    append wb(buffer:$w) "$line\n";
  }
}

proc write_to_cfed {args} {
  global wb;

#  puts_for_debug $args;

  set w [lindex $args 0];
  set sn $wb($w);

  set wb(success:$w) 0;
  set wb(buffer:$w) "";

  addinput -read $wb(cfed:$sn) "read_from_cfed $w %F";

  puts $wb(cfed:$sn) "[lrange $args 1 end]" 
  flush $wb(cfed:$sn);

  tkwait variable wb(success:$w);

#  removeinput $wb(cfed:$sn);

  return [string trim $wb(buffer:$w)];
}

proc write_to_cfed_nowait {args} {
  global wb;

  set w [lindex $args 0];
  set sn $wb($w);

#  puts_for_debug $args;

  puts $wb(cfed:$sn) "[lrange $args 1 end]"; 
  flush $wb(cfed:$sn);
}

proc show_info {w msg {title {Info.}}} {
  global label wb;

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
      my_file_selector $win.fsel save_log $w {} file;\
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

proc delete_from_windows {w name} {
  global wb wbw;
  
  foreach i $wb(allwin) {
    if {$wbw($i) != $w} {
      $wbw($i).f3.window.m delete "$name";
    }
  }

  set p [lsearch -exact $wb(alltitle) "$name"];
  set wb(allwin) [lreplace $wb(allwin) $p $p];
  set wb(alltitle) [lreplace $wb(alltitle) $p $p];
}

proc set_all_windows {w title} {
  global wb wbw;

  set j 0;
  foreach i $wb(allwin) {
    if {$wbw($i) == $w} {
      set state disabled;
      set wb(alltitle) [linsert $wb(alltitle) $j $title];
    } else {
      set state normal;
    }
    $w.f3.window.m add command \
      -label "[lindex $wb(alltitle) $j]" -state $state \
      -command "wm deiconify $wbw($i); raise $wbw($i)";
    incr j;
  }

  foreach i $wb(allwin) {
    if {$wbw($i) != $w} {
      $wbw($i).f3.window.m add command -label "$title" \
	-command "wm deiconify $w; raise $w";
    }
  }
}

proc wb_close {w {all 1}} {
  global wb wbw wbk;

  set kind $wbk($w);

  switch -regexp $kind {
    CFE {
      set k1 "SB";
      set k2 "CB";
    }
    SB {
      global sb env;

      set k1 "CFE";
      set k2 "CB";

#      puts_for_debug $sb($wb($w));

      if {[info exists sb($wb($w))] && $sb($wb($w)) != ""} {
	SendOZ "CloseSchool:$wb($w)";
	unset sb($wb($w));
      }
    }
    CB {
      set k1 "CFE";
      set k2 "SB";
    } 
    default {
      return;
    }
  }

  set sn $wb($w);

  if {$kind == "CFE" || $kind == "SB"} {

    if $all {
      delete_from_windows wbw($sn:$kind) "$sn ($kind)";
    }

    if !$wb(boot) {
#      SendOZ "Close$kind:$sn";
#      RecvOZ;
    }

    destroy $w;
  }

  if [info exists wbw($sn:$kind)] {
    if {![info exists wbw($sn:$k1)] && ![info exists wbw($sn:$k2)]} {
      write_to_cfed_nowait $w quit;
      
      catch { removeinput $wb(cfed:$sn) };
      close $wb(cfed:$sn);
      unset wb(cfed:$sn);
    }
  
    unset wbw($sn:$kind);
  }
}

proc wb_close_all {} {
  global wb wbw;
  
  foreach i $wb(allwin) {
    wb_close $wbw($i) 1;
  }

  exit 0;
}

proc wb_open {kind} {
  global wb wbw;

  set wb(select) {};

  wb_select_schools;

  tkwait variable wb(select);

  wb_open_tools $wbw(WB) $kind;
}

proc wb_select_schools {} {
  global wb wbw label;

  set w $wbw(WB);

  if {[$w.f2.srcs curselection] != ""} {
    $w.f3.ops.m enable "$label(Select)";
  }
  $w.f3.ops.m enable "$label(Cancel)";

  raise $w;
}


proc quit {} {
  global wb env wbw label;
 
  if {!$wb(quit) && ![info exists wb(quit_from_oz)]} {
    if [tk_dialog $wbw(WB).quit "Really ?" "$label(quit msg)" question 0 "$label(Yes)" "$label(No)"] {
      return;
    }
  }

  switch $wb(boot) {
    0 -
    1 {
      if !$wb(quit) {
	set wb(quit) 1;
	SendOZ "Quit:$wb(pwd)|$wb(lang)";
      }
    }
    2 {
      set f [open $env(HOME)/.oz++wbrc w];
      puts $f "$wb(pwd)";
      puts $f "$wb(lang)";
      close $f;
      wb_close_all;
    }
  }
}

proc delete_menu {m} {
  $m delete 0 last;
}

