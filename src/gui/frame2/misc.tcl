proc SelectNext {lb} {
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
	set size [$lb size];
	if {$size == 0} {
		return;
	}

	set idx [$lb curselect];
	if {[llength $idx] == 0} {
		set idx [expr $size - 1];
	} else {
		set idx [lindex $idx 0];
	}
	$lb select from $idx;
	$lb select to $idx;

	set next [expr $idx + 1];
	if {$size <= $next} {
		set next 0;
	}

	$lb select from $next;
	$lb select to $next;
}


#	Get one-line string using a pop-up window
#-----------------------------------------------------------------------
proc GetLine {w title {prompt ""} {width 20}} {
	global	rGetLine;

	set rGetLine "";
	catch {destroy $w};
	toplevel $w -class GetLine;
	wm title $w $title;
	wm iconname $w GetLine;
	set f_top [frame $w.top -relief raised -bd 1];
	set f_bot [frame $w.bot -relief raised -bd 1];
	pack $f_top $f_bot -side top -fill both;

	#--- One-line entry
	if {"$prompt" != ""} {
		set top_l [label $f_top.l -text "$prompt"];
		pack $top_l -side left -padx 4 -pady 4;
	}
	set top_e [entry $f_top.e -relief sunken -bd 2 -width $width];
	pack $top_e -side left -padx 4 -pady 4;

	set bot_ok [frame $f_bot.ok -relief sunken -bd 1];
	set bot_ok_b [button $f_bot.ok.b -text "OK" -width 4 \
	  -command "set rGetLine ok"];
	set bot_cancel [button $f_bot.cancel -text "Cancel" -bd 1 \
	  -command "set rGetLine cancel"];
	pack $bot_ok -side left -expand 1 -padx 4 -pady 4;
	pack $bot_ok_b -padx 2 -pady 2 -ipadx 2 -ipady 2;
	pack $bot_cancel -side left -expand 1 \
	  -padx 4 -pady 4 -ipadx 4 -ipady 2;

	bind $top_e <Return> "$bot_ok_b flash; set rGetLine ok";

	#--- make the window appeared
	wm withdraw $w;
	update idletasks;
	set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
	   - [winfo vrootx [winfo parent $w]]];
	set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
	   - [winfo vrooty [winfo parent $w]]];
	wm geom $w +$x+$y;
	wm deiconify $w;

	set oldFocus [focus];
	grab $w;
	focus $top_e;

	tkwait variable rGetLine;
	if {"$rGetLine" == "ok"} {
		set rGetLine [$top_e get];
	} else {
		set rGetLine "";
	}
	destroy $w;
	catch {focus $oldFocus};
	return $rGetLine;
}


#	Listbox with Vertical and horizontal scrollbars
#-----------------------------------------------------------------------
proc ScrolledListBox {parent title args} {

	if {[winfo exists $parent]} {
		Debug "ScrolledListBox - widget alredy exists";
		return "";
	}

	frame $parent;
	if {"$title" != ""} {
		set lbl [label $parent.lable -text "$title"];
		pack $lbl -side top -anchor w;
	}
	set lb [listbox $parent.lb -relief sunken -bd 2 -setgrid 1 \
	  -yscrollcommand [list $parent.sy set] \
	  -xscrollcommand [list $parent.padx.sx set]];
	set sy [scrollbar $parent.sy -orient vertical \
	  -command [list $parent.lb yview] -relief sunken -bd 2];

	set padx [frame $parent.padx];
	set sx [scrollbar $parent.padx.sx -orient horizontal \
	  -command [list $parent.lb xview] -relief sunken -bd 2];

	set pad_sz [expr [lindex [$sy config -width] 4] \
	  + 2 * [lindex [$sy config -bd] 4]];
	set pad_f [frame $parent.padx.f -width $pad_sz -height $pad_sz];

	pack $padx -side bottom -fill x;
	pack $pad_f -side right;
	pack $sx -side bottom -fill x;
	pack $sy -side right -fill y;
	pack $lb -side left -fill both -expand 1;

	return $lb;
}


#	Change Cursor
#-----------------------------------------------------------------------
proc ChangeCursor {csr args} {
	foreach w $args {
		catch {$w config -cursor $csr};
	}
}


#	Send a message to OZ++ Object via STDOUT
#-----------------------------------------------------------------------
proc SendOZ {msg} {
	puts stdout "$msg";
	flush stdout;
}


#	Debug message printer
#-----------------------------------------------------------------------
proc Debug {msg} {
	global	DEBUG;

	if {$DEBUG} {
		puts stderr "Debug ... $msg";
		flush stderr;
	}
}

