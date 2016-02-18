#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
# this is a source for communictaion with OZ++
#

rename proc orig_proc;

orig_proc proc {name arg body} {
  orig_proc $name $arg "\
    if {\[catch {$body} result\] == 1} {\
      puts stderr \$result;\
    } else {\
      return \$result;\
    };\
  "
}

global win;

set win(width) [winfo vrootwidth .];
set win(height) [winfo vrootheight .];

proc SendOZ {msg} {
  puts $msg;
  flush stdout;
}

proc RecvOZ {} {
  return [gets stdin];
}

proc set_center {w} {
  global win;

  wm withdraw $w;
  update idletasks;

  set width [winfo reqwidth $w];
  set height [winfo reqheight $w];

  if {[set parent [winfo parent $w]] != ""} {
    set x [expr [winfo rootx $parent] + [winfo reqwidth $parent] / 2 \
	   - $width / 2];
    set y [expr [winfo rooty $parent] + [winfo reqheight $parent] / 2 \
	   - $height / 2];
  } else {
    set x [expr $win(width) / 2 - $width / 2];
    set y [expr $win(height) / 2 - $height / 2];
  }

  if {$x < 0} { 
    set x 10;
  } elseif {[expr $x + $width] > $win(width)} { 
    set x [expr $win(width) - $width - 40];
  }

  if {$y < 0} { 
    set y 10;
  } elseif {[expr $y + $height] > $win(height)} { 
    set y [expr $win(height) - $height - 30];
  }

  wm geom $w +$x+$y;
  wm deiconify $w;
  update idletasks;
}

proc set_right {w} {
  global win;

  wm withdraw $w;
  update idletasks;

  set width [winfo reqwidth $w];
  set height [winfo reqheight $w];
  
  if {[set parent [winfo parent $w]] != ""} {
    set x [expr [winfo rootx $parent] + [winfo reqwidth $parent] + 10];
    set y [expr [winfo rooty $parent] + 10];
  } else {
    set x [expr [winfo vrootwidth $w] / 2 - [winfo reqwidth $w] / 2];
    set y [expr [winfo vrootheight $w] / 2 - [winfo reqheight $w] / 2];
  }

  if {$x < 0} { 
    set x 10;
  } elseif {[expr $x + $width] > $win(width)} { 
    set x [expr $win(width) - $width - 40];
  }

  if {$y < 0} { 
    set y 10;
  } elseif {[expr $y + $height] > $win(height)} { 
    set y [expr $win(height) - $height - 30];
  }

  wm geom $w +$x+$y;
  wm deiconify $w;
  update idletasks;
}

proc set_left {w} {
  global win;

  wm withdraw $w;

  set width [winfo reqwidth $w];
  set height [winfo reqheight $w];
  
  update idletasks;
  if {[set parent [winfo parent $w]] != ""} {
    set x [expr [winfo rootx $parent] - [winfo reqwidth $w] - 10];
    set y [expr [winfo rooty $parent] - 10];
  } else {
    set x [expr $win(width) / 2 - $width / 2];
    set y [expr $win(height) / 2 - $height / 2];
  }

  if {$x < 0} { 
    set x 10;
  } elseif {[expr $x + $width] > $win(width)} { 
    set x [expr $win(width) - $width - 40];
  }

  if {$y < 0} { 
    set y 10;
  } elseif {[expr $y + $height] > $win(height)} { 
    set y [expr $win(height) - $height - 30];
  }

  wm geom $w +$x+$y;
  wm deiconify $w;
  update idletasks;
}

proc set_here {w x y} {
  global win;

  wm withdraw $w;

  set width [winfo reqwidth $w];
  set height [winfo reqheight $w];
  
  update idletasks;

  if {$x < 0} { 
    set x 10;
  } elseif {[expr $x + $width] > $win(width)} { 
    set x [expr $win(width) - $width - 40];
  }

  if {$y < 0} { 
    set y 10;
  } elseif {[expr $y + $height] > $win(height)} { 
    set y [expr $win(height) - $height - 30];
  }

  wm geom $w +$x+$y;
  wm deiconify $w;
  update idletasks;
}

proc mybind {w seq command {add 0}} {
  set class_command [bind [winfo class $w] $seq];

  if {$add} {
    set before_command [bind $w $seq];
  } else {
    set before_command "";
  }

  set command "$class_command; $before_command; $command";

  bind $w $seq "eval { $command }"
}

proc set_expandable {w {mode both}} {
  global win;

  if {$mode == "both"} {
    wm minsize $w [winfo reqwidth $w] [winfo reqheight $w];
    wm maxsize $w $win(width) $win(height);
  } elseif {$mode == "height"} {
    wm minsize $w [winfo reqwidth $w] [winfo reqheight $w];
    wm maxsize $w [winfo reqwidth $w] $win(height);
  } elseif {$mode == "width"} {
    wm minsize $w [winfo reqwidth $w] [winfo reqheight $w];
    wm maxsize $w $win(width) [winfo reqheight $w];
  }
}

