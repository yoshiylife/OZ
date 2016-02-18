#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a UI for Entry Browser of Directory Browser
#

global env eb;

set eb(test_mode) 0;
set eb(debug_mode) 1;

source $env(OZROOT)/lib/gui/wb2/if-to-oz.tcl

# procedures called by OZ++

proc Open {title entries} {
  set w [new_win];

  wm title $w "$title";
  $w.f1.title configure -text "$title";

  $w.f1.box delete 0 end;

  update idletasks;

  foreach i [lsort $entries] {
    $w.f1.box insert end $i;
  }
}

proc Quit {} {
  destroy .;
}

# local procedures 

proc close {w} {
  wm withdraw $w;
}

proc new_win {} {
  set w ".w";

  if [winfo exists $w] {
    wm deiconify $w;
    raise $w;
    return $w;
  }

  set w [toplevel $w];
  
  frame $w.f1;
  label $w.f1.title -text "" -relief ridge -anchor w;
  scrollbar $w.f1.sbx -orient horiz -cursor sb_h_double_arrow \
    -command "$w.f1.box xview";
  scrollbar $w.f1.sby -command "$w.f1.box yview";
  listbox $w.f1.box -relief flat -exportselection no -geometry 40x15 \
    -xscrollcommand "$w.f1.sbx set" \
      -yscrollcommand "$w.f1.sby set";

  frame $w.f2;
  button $w.f2.close -text "Close" -relief flat -command "close $w";

  pack $w.f1 -fill both -expand yes;
  pack $w.f1.title -fill x;
  pack $w.f1.sby -side right -fill y;
  pack $w.f1.sbx -side bottom -fill x;
  pack $w.f1.box -fill both -expand yes;

  pack $w.f2 -fill x;
  pack $w.f2.close -fill x -expand yes;

  return $w;
}

# main part in this program

global eb;

wm withdraw .;

# test

if $eb(test_mode) {
  Open test {a b c}
}

if $eb(debug_mode) {
  rename SendOZ orig_SendOZ;
  proc SendOZ {str} {
    puts stderr $str;
    orig_SendOZ $str;
  }
}


