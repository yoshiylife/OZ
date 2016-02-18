#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#  <<< Mouse Event Handlers >>>
#

set CreateProc(button) createButton;
set CreateProc(label) createLabel;
set CreateProc(rect) createRect;
set CreateProc(oval) createOval;


#-----------------------------------------------------------------------
#  cvs - target canvas widget
#  flag - with shift key
proc CanvasB1Press {cvs x y flag} {
    global mode;

    set x [$cvs canvasx $x];
    set y [$cvs canvasy $y];

    Debug "CanvasB1Press {$cvs $x $y $flag}";
    
    switch $mode {
	button - rect - oval {
	    bind $cvs <Any-Motion> "DrawArea $cvs $x $y %x %y";
	    bind $cvs <Any-ButtonRelease-1> "Area2Object $cvs $x $y %x %y";
	}

	label {
	    Point2LabelCursor $cvs $x $y;
	}
    }
}


#-----------------------------------------------------------------------
#  Remove canvas items with tag "area"
#  and then create a rectangle with "area".
proc DrawArea {cvs x1 y1 x2 y2} {
    $cvs delete area;

    set x2 [$cvs canvasx $x2];
    set y2 [$cvs canvasy $y2];
    $cvs addtag area withtag \
	[$cvs create rect $x1 $y1 $x2 $y2 -outline gray75];
}


#-----------------------------------------------------------------------
proc Area2Object {cvs x1 y1 x2 y2} {
    global mode;

    $cvs delete area;
    set x2 [$cvs canvasx $x2];
    set y2 [$cvs canvasy $y2];
    CreateObject $cvs $mode $x1 $y1 $x2 $y2;

    bind $cvs <Any-Motion> "";
    bind $cvs <Any-ButtonRelease-1> "";
}

#-----------------------------------------------------------------------
proc Point2LabelCursor {cvs x y} {
    set x [$cvs canvasx $x];
    set y [$cvs canvasy $y];
    CreateObject $cvs label $x $y;
}


#-----------------------------------------------------------------------
proc CreateObject {cvs type args} {
    global CreateProc;
    
    set id [eval $CreateProc($type) $cvs $args];
}


#-----------------------------------------------------------------------
proc createRect {cvs x1 y1 x2 y2} {
    set item [$cvs create rect $x1 $y1 $x2 $y2];

    return item;
}

#-----------------------------------------------------------------------
proc createOval {cvs x1 y1 x2 y2} {
    set item [$cvs create oval $x1 $y1 $x2 $y2];

    return item;
}


#-----------------------------------------------------------------------
proc createButton {cvs x1 y1 x2 y2} {

    Debug "createButton - $x1 $y1 $x2 $y2";

    return "";
}


#-----------------------------------------------------------------------
proc createLabel {cvs x y} {

    Debug "createLabel - $x $y";
    set item [$cvs create text $x $y -anchor nw];

    $cvs bind $item <KeyPress> "$cvs insert $item insert %A";
    $cvs bind $item <Shift-KeyPress> "$cvs insert $item insert %A";
    $cvs bind $item <Return> "$cvs insert $item insert \\n";
    $cvs bind $item <Control-h> "textBackSpace $cvs $item";
    $cvs bind $item <BackSpace> "textBackSpace $cvs $item";
    $cvs bind $item <Delete> "$cvs dchar $item insert";
    
    $cvs icursor $item 0;
    $cvs focus $item;
    focus $cvs;

    return "";
}


proc textBackSpace {cvs id} {
    set char [expr {[$cvs index $id insert] - 1}];
    if {$char >= 0} {
	$cvs dchar $id $char;
    }
}


#-----------------------------------------------------------------------
proc Debug {msg} {
    puts stderr "Debug ... $msg";
    flush stderr;
}



#=======================================================================
#  test sequence

canvas .c -bg white;
pack .c;
bind .c <ButtonPress-1> "CanvasB1Press .c %x %y 0"
set mode rect;


# EoF
