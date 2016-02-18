#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	OZ++/Frame Graphic Agent
#
#	Mutater mudule	0.133

#
#	Akihito NAKAMURA, Electrotechnical Laboratory,
#

set GADIR	"$env(OZROOT)/lib/gui/frame2";
#set GADIR	"$env(HOME)/oz++/frame2/2/gui";

source $GADIR/ga-core.tcl;	#--- Loading core module

set Color(list)		{black gray white yellow orange yellowgreen \
			 green lightblue blue pink red purple}
set Color(selected)	"";
set Color(selected.r)	0;
set Color(selected.g)	0;
set Color(selected.b)	0;

set AttProc(ID)		InfoConst;
set AttProc(type)	InfoConst;
set AttProc(name)	InfoStr;
set AttProc(state)	InfoState;
set AttProc(geom)	InfoGeom;
set AttProc(size)	InfoSize;
set AttProc(label)	InfoStr;
set AttProc(fgcolor)	InfoColor;
set AttProc(bgcolor)	InfoColor;
set AttProc(activefgcolor)	InfoColor;
set AttProc(activebgcolor)	InfoColor;
set AttProc(font)	InfoFont;
set AttProc(justify)	InfoJustify;
set AttProc(text)	InfoText;
set AttProc(value)	InfoInt;
set AttProc(group)	InfoConst;
set AttProc(terminator)	InfoTerminator;



########################################################################
###
###		Mutate
###
########################################################################

proc Mutate::Init {} {
    global  Menu;

    Menu::Create Series;
    Menu::AddCommandEntry Series "Series Info..." {Mutate::ConfigSeries};
    Menu::AddSeparator    Series;
    Menu::AddCommandEntry Series "New Slide" {Mutate::NewSlide};
    Menu::AddCommandEntry Series "Delete Slide" {Mutate::DeleteSlide};

    Menu::Create Goto;
    Menu::AddCommandEntry Goto "First" {Mutate::Goto first};
    Menu::AddCommandEntry Goto "Prev"  {Mutate::Goto prev};
    Menu::AddCommandEntry Goto "Next"  {Mutate::Goto next};
    Menu::AddCommandEntry Goto "Last"  {Mutate::Goto last};

    Menu::Create Widget;
    Menu::AddCommandEntry Widget "Info..." {Tool::Select item_info};
    Menu::AddCommandEntry Widget "Delete..." {Tool::Select item_delete};
    Menu::AddSeparator    Widget;
    Menu::AddCommandEntry Widget "New Button" {Tool::Select new_button};

    Menu::Create Junkshop;
    Menu::AddCommandEntry Junkshop "Export Slide" {Mutate::ExportSlide};
    Menu::AddCommandEntry Junkshop "Import Slide" {Mutate::ImportSlide};
    Menu::AddSeparator    Junkshop;
    Menu::AddCommandEntry Junkshop "Open" {Mutate::OpenJunkshop};
    Menu::AddCommandEntry Junkshop "Close" {Mutate::CloseJunkshop};
}


#-----------------------------------------------------------------------
proc Mutate::ExportSlide {} {
    SendOZ "{ExportToJunkshop slide}";
}

#-----------------------------------------------------------------------
proc Mutate::ImportSlide {} {
    SendOZ "{ImportFromJunkshop slide}";
}

#-----------------------------------------------------------------------
proc Mutate::OpenJunkshop {} {
    SendOZ "{Junkshop open}";
}

proc Mutate::CloseJunkshop {} {
    SendOZ "{Junkshop close}";
}

#-----------------------------------------------------------------------
proc Mutate::ConfigSeries {} {
	global	Obj;

	set cp copyseries;
	set Obj($cp.name) $Obj(series.name);
	set Obj($cp.width) $Obj(series.width);
	set Obj($cp.height) $Obj(series.height);
	set result [SeriesInfoDialog];
	if {$result} {
		Mutate::SeriesAttChanged;
	}
	unset Obj($cp.name) Obj($cp.width) Obj($cp.height);
}

proc Mutate::SeriesAttChanged {} {
	global	Obj Event;

	set diff {};
	if {"$Obj(copyseries.name)" != "$Obj(series.name)"} {
		lappend diff "name \"$Obj(copyseries.name)\"";
	}
	if {$Obj(copyseries.width) != $Obj(series.width) ||
	    $Obj(copyseries.height) != $Obj(series.height)} {
		lappend diff \
		  "size $Obj(copyseries.width) $Obj(copyseries.height)";
	}

	if {"$diff" != ""} {
		eval RefreshSeries $diff;
		SendOZ "{SeriesEvent $Event(ATTRIBUTE) $diff}";
	}
}

proc SeriesInfoDialog {} {
	global	Frame Obj rSeriesInfoDialog;

	set rSeriesInfoDialog 0;

	#--- Top-level window
	set w .info_series;
	toplevel $w;
	wm positionfrom $w program;
	wm geometry $w -20+0;
	wm title $w "Series Info ($Obj(series.name))"

	#--- Name attribute
	set name [frame $w.name];
	label $name.l -text "Name:  ";
	entry $name.e -relief sunken -bd 1 -textvariable Obj(copyseries.name);
	bind $name.e <Return> "+ focus none";
	pack $name.l $name.e -side left;

	#--- Size attribute
	set size [frame $w.size];
	set sl [label $size.l -text "Size"];
	set sw [frame $size.w];
	set sh [frame $size.h];
	set swl [label $sw.l -text "  width:  "];
	set swv [entry $sw.v -relief sunken -bd 1 -width 5 \
	        -textvariable Obj(copyseries.width)];
	bind $swv <Return> "+ focus none";
	pack $swl $swv -side left;
	set shl [label $sh.l -text " height:  "];
	set shv [entry $sh.v -relief sunken -bd 1 -width 5 \
	        -textvariable Obj(copyseries.height)];
	bind $shv <Return> "+ focus none";
	pack $shl $shv -side left;

	pack $sl $sw $sh -side top -anchor w;

	#--- Confirmation buttons
	set conf [frame $w.conf];
	set ok [button $conf.ok -text "OK" -relief groove -bd 5 -width 4 \
	  -command "set rSeriesInfoDialog 1; destroy $w"];
	set cancel [button $conf.cancel -text "Cancel" -bd 1 \
	  -command "destroy $w"];
	pack $ok $cancel -side left -expand 1 \
	  -padx 20 -pady 10 -ipadx 4 -ipady 2;

	pack $name $size $conf -side top -fill x -padx 4 -pady 2;

	update idletasks;
	set old_focus [focus];
	set old_grab [grab current];
	grab $w;
	focus $w;
	tkwait window $w;
	grab release $w;
	catch {grab $old_grab; focus $old_focus};

	return $rSeriesInfoDialog;
}

#-----------------------------------------------------------------------
proc Mutate::NewSlide {} {
    global  Event;
    
    SendOZ "{SeriesEvent $Event(NEW_SLIDE)}";
}

#-----------------------------------------------------------------------
proc Mutate::DeleteSlide {} {
    global  Event;
    
    set rv [tk_dialog .mut_delete_slide "Frame: Delete Slide" \
		"Do you really want to delete the current Slide ?" \
		question 0 {Delete} {Cancel}];

    if {$rv == 0} {
	# SendOZ "{SeriesEvent $Event(DELETE_SLIDE)}";
    }
}

proc Mutate::Goto {pos} {
    global  Event;
    
    SendOZ "{SeriesEvent $Event(GOTO_SLIDE) $pos}";
}


#	Make confirmation and send a message of deletion to OZ.
#-----------------------------------------------------------------------
proc Mutate::DeleteItem {ID} {
	Mutate::SelectItem $ID;
	set result [ItemDeleteDialog $ID];
	if {$result} {
		#--- Sending a message of deletion to OZ
		Mutate::ItemDeleted $ID;
	}
	Mutate::ReleaseItem $ID;
}

proc ItemDeleteDialog {ID} {
	global	Obj;

	set result \
	  [tk_dialog .delete_item$ID "Item Deletion $ID" \
	   "Do you really want to delete the Item ?" \
	   question 0 {Delete} {Cancel}];

	if {$result == 0} {
		return 1;
	} else {
		return 0;
	}
}

proc Mutate::ItemDeleted {ID} {
    global  Obj Item Event;

    if {[lsearch $Item(IDs) $ID] != -1} {
	CloseItem $ID;
	SendOZ "{SeriesEvent $Event(DELETE_ITEM) $ID}"
    }
}

#-----------------------------------------------------------------------
proc Mutate::ConfigItem {ID} {
	global	Series Obj;

	Mutate::SelectItem $ID;

	#--- Make a copy of attributes ---
	set copyID copy$ID;
	Att::Reset $copyID;
	Att::Copy $ID $copyID;

	set result [ItemInfoDialog $ID $copyID];
	if {$result == 1} {
		Mutate::ItemAttChanged $ID $copyID;
	}

	Mutate::ReleaseItem $ID;
	Att::Delete $copyID;
}

proc Mutate::ItemAttChanged {ID copyID} {
    global  Obj Item Att Event;

    set diff {};
    foreach att $Att($Obj($ID.type)) {
	switch $att {
	    geom - size {continue;}
	    fgcolor - bgcolor - activefgcolor - activebgcolor {
		if {"$Obj($ID.$att)" != "$Obj($copyID.$att)"} {
		    lappend diff \
			"color $att {$Obj($copyID.$att.r) $Obj($copyID.$att.g) $Obj($copyID.$att.b)}";
		}
	    }
	    default {
		if {"$Obj($ID.$att)" != "$Obj($copyID.$att)"} {
		    if {[Att::IsStr $att]} {
			lappend diff "$att \"$Obj($copyID.$att)\"";
		    } else {
			lappend diff "$att $Obj($copyID.$att)";
		    }
		}
	    }
	}
    }

    if {[lsearch $Att($Obj($ID.type)) geom] != -1} {
	if {$Obj($copyID.coordx) != $Obj($ID.coordx) ||
	    $Obj($copyID.coordy) != $Obj($ID.coordy)} {
	    lappend diff "geom $Obj($copyID.coordx) $Obj($copyID.coordy)";
	}
    }

    if {[lsearch $Att($Obj($ID.type)) size] != -1} {
	if {$Obj($copyID.width) != $Obj($ID.width) ||
	    $Obj($copyID.height) != $Obj($ID.height)} {
	    lappend diff "size $Obj($copyID.width) $Obj($copyID.height)";
	}
    }

    # Debug "Mutate::InvokeOzMutate - diff = $diff";

    if {"$diff" != ""} {
	eval RefreshItem $ID $diff;
	SendOZ "{ItemEvent $Event(ATTRIBUTE) $ID $diff}";
    } else {
	# Debug "Mutate::InvokeOzMutate - no change";
    }
}

proc Mutate::SelectItem {args} {
	global	Item;

	foreach ID $args {
		if {[lsearch $Item(selectedIDs) $ID] == -1} {
			lappend Item(selectedIDs) $ID;
			Mutate::ShowKnob $ID;
		}
	}
}

proc Mutate::ReleaseItem {args} {
	global	Item;

	foreach ID $args {
		set idx [lsearch $Item(selectedIDs) $ID];
		if {$idx != -1} {
			set Item(selectedIDs) \
			  [lreplace $Item(selectedIDs) $idx $idx];
			Mutate::HideKnob $ID;
		}
	}
}

proc Mutate::IsSelected {ID} {
	global	Item;

	if {[lsearch $Item(selectedIDs) $ID] == -1} {
		return 0;
	} else {
		return 1;
	}
}

proc Mutate::ShowKnob {args} {
	global	Obj;

	foreach ID $args {
		switch $Obj($ID.type) {
		  button -
		  checkbutton -
		  radiobutton -
		  field {set coords [.series bbox item$ID]; }

		  string {set coords [.series coords item$ID]; }
		}

		set length [llength $coords];
		for {set i 0} {$i < $length} {incr i} {
			set x [lindex $coords $i];
			incr i;
			set y [lindex $coords $i];
			set cid [.series create rect \
			  [expr $x - 4] [expr $y - 4] \
			  [expr $x + 4] [expr $y + 4] \
			  -fill gray75 -outline gray75];

			.series addtag knob$ID withtag $cid;
		}
	}
}

proc Mutate::HideKnob {args} {
	foreach ID $args {
		.series delete knob$ID;
	}
}


proc ItemInfoDialog {ID copyID} {
    global  Obj Att AttProc rItemInfoDialog ItemInfoDialog_TextProc;

    #--- Create a new window
    set w .info_item$ID;
    if {[winfo exists $w] != 0} {
	Warning "Mutate::ItemInfoDialog - window already exists";
	return 0;
    }
    toplevel $w;
    wm positionfrom $w program;
    wm geometry $w -20+0;
    wm title $w "Item Info ($Obj(series.name):$ID)";
    set rItemInfoDialog 0;

    #--- Configure for each Attribute
    set ItemInfoDialog_TextProc "";
    foreach att $Att($Obj($ID.type)) {
	set f [eval $AttProc($att) $w $copyID $att];
	if {"$f" != ""} {
	    pack $f -side top -anchor w -fill x -padx 4 -pady 4;
	    if {"$att" == "text"} {
		#--- Gettting text attribute value
		lappend ItemInfoDialog_TextProc \
		    "InfoTextSet $copyID text $f.value; ";
	    }
	}
    }

    set conf [frame $w.exit];
    set ok [button $conf.ok -text "OK" -relief groove -bd 5 -width 4 \
		-command "catch {eval $ItemInfoDialog_TextProc}; \
	  set rItemInfoDialog 1; destroy $w"];
    set cancel [button $conf.cancel -text "Cancel" -bd 1 \
		    -command "destroy $w"];
    pack $ok $cancel -side left -expand 1 \
	-padx 20 -pady 10 -ipadx 4 -ipady 2;
    pack $conf -side bottom -fill x;

    update idletasks;
    set old_focus [focus];
    set old_grab [grab current];
    grab $w;
    focus $w;
    tkwait window $w;
    grab release $w;
    catch {grab $old_grab; focus $old_focus};

    return $rItemInfoDialog;
}


#	w = parent widget path
#-----------------------------------------------------------------------
proc InfoStr {w ID att} {
	global	Obj;

	switch $att {
	  name {set lb "Name:   ";}
	  label {set lb "Label:  ";}
	  default {
		Warning "InfoStr - unknown attribute ($att)";
		return "";
	  }
	}

	set wa $w.att_$att;
	frame $wa;
	set label [label $wa.label -text $lb];
	set value [entry $wa.value -relief sunken -bd 1 -width 20 \
	           -textvariable Obj($ID.$att)];
	bind $value <Return> "+ focus none";
	pack $label $value -side left;
#	pack $label $value -side left -ipadx 2 -ipady 2;

	return $wa;
}

proc InfoText {w ID att} {
    global  Obj;

    set wa $w.att_$att;
    frame $wa;
    set label [label $wa.label -text "Text:  "];
    set value [text $wa.value -relief sunken -bd 1 -width 20 -height 5 \
		   -wrap char -yscrollcommand "$wa.yscroll set"];
    set yscroll [scrollbar $wa.yscroll -relief sunken -bd 1 \
		     -command "$wa.value yview"];

    $value insert 0.0 $Obj($ID.$att);

    #	bind $value <Return> "+ InfoTextSet $ID $att $value";
    pack $label -side top -anchor w;
    pack $yscroll $value -side right -fill y -padx 1;

    return $wa;
}

proc InfoTextSet {ID att text_w} {
	global	Obj;

	focus none;
	set Obj($ID.$att) "[$text_w get 0.0 end]";
}

proc InfoConst {w ID att} {
	global	Obj;

	switch $att {
	  ID {set lb "ID:    ";}
	  type {set lb "Type:  ";}
	  group {set lb "Group:  ";}
	  default {
		Warning "InfoConst - unknown attribute ($att)";
		return "";
	  }
	}

	set wa $w.att_$att;
	frame $wa;
	set label [label $wa.label -text "$lb"];
	set value [label $wa.value -text "$Obj($ID.$att)"];
	pack $label $value -side left;
#	pack $label $value -side left -ipadx 2 -ipady 2;

	return $wa;
}

proc InfoGeom {w ID att} {
	global	Obj;

	set wa $w.att_$att;
	frame $wa;

	set l [label $wa.l -text "Geometry  "];
	set r [frame $wa.r];
	pack $l $r -side left;

	set x [frame $r.x];
	set y [frame $r.y];
	pack $x $y -side top -anchor w;

	set xl [label $x.l -text " x:  "];
	set xv [entry $x.v -relief sunken -bd 1 -width 5 \
	        -textvariable Obj($ID.coordx)];
	bind $xv <Return> "+ focus none";
	pack $xl $xv -side left;
	set yl [label $y.l -text " y:  "];
	set yv [entry $y.v -relief sunken -bd 1 -width 5 \
	        -textvariable Obj($ID.coordy)];
	bind $yv <Return> "+ focus none";
	pack $yl $yv -side left;

	return $wa;
}

proc InfoSize {w ID att} {
	global	Obj;

	set wa $w.att_$att;
	frame $wa;

	set l [label $wa.l -text "Size  "];
	set r [frame $wa.r];
	pack $l $r -side left;

	set w [frame $r.x];
	set h [frame $r.y];
	pack $w $h -side top -anchor w;

	set wl [label $w.l -text " width:  "];
	set wv [entry $w.v -relief sunken -bd 1 -width 5 \
	        -textvariable Obj($ID.width)];
	bind $wv <Return> "+ focus none";
	pack $wl $wv -side left;
	set hl [label $h.l -text "height:  "];
	set hv [entry $h.v -relief sunken -bd 1 -width 5 \
	        -textvariable Obj($ID.height)];
	bind $hv <Return> "+ focus none";
	pack $hl $hv -side left;

	return $wa;
}

proc InfoState {w ID att} {
	global	Obj;

	set wa $w.att_$att;
	frame $wa;
	set r [frame $wa.r];
	set label [label $wa.label -text "State:  "];
	set s1 [radiobutton $r.s1 -text "normal" -relief flat \
	        -variable Obj($ID.$att) -value normal -anchor w];
	set s2 [radiobutton $r.s2 -text "disabled" -relief flat \
	        -variable Obj($ID.$att) -value disabled -anchor w];
	pack $s1 $s2 -side left;
	pack $label $r -side left;

	return $wa;
}

proc InfoJustify {w ID att} {
	global	Obj;

	set wa $w.att_$att;
	frame $wa;
	set label [label $wa.label -text "Justify:  "];
	set left [radiobutton $wa.l -text "L" -relief flat \
	        -variable Obj($ID.$att) -value left];
	set center [radiobutton $wa.c -text "C" -relief flat \
	        -variable Obj($ID.$att) -value center];
	set right [radiobutton $wa.r -text "R" -relief flat \
	        -variable Obj($ID.$att) -value right];
	pack $label -side left;
	pack $left $center $right -side left -padx 2;

	return $wa;
}

proc InfoInt {w ID att} {
	global	Obj;

	set wa $w.att_$att;
	frame $wa;
	switch $att {
	  value {set lb "Value:  ";}
	}
	set label [label $wa.label -text "$lb"];
	set value [entry $wa.value -relief sunken -bd 1 -width 5 \
	           -textvariable Obj($ID.$att)];
	pack $label $value -side left;
#	pack $label $value -side left -ipadx 2 -ipady 2;

	return $wa;
}

proc InfoColor {w ID att} {
	global  Obj;

	set wa $w.att_$att;
	frame $wa;
	switch $att {
	  fgcolor {set lb "Foreground:        ";}
	  bgcolor {set lb "Background:        ";}
	  activefgcolor {set lb "ActiveForeground:  ";}
	  activebgcolor {set lb "ActiveBackground:  ";}
	  default {
		Warning "InfoColor - unknown attribute ($att)";
		return "";
	  }
 	}
	set label [label $wa.label -text "$lb"];
	set value [button $wa.value -bd 1 -text "   >" \
	  -bg $Obj($ID.$att) -activebackground $Obj($ID.$att) \
	  -command "ColorMixer $ID $att $wa.value"];
	pack $label $value -side left;

	return $wa;
}

proc InfoTerminator {w ID att} {
	global	Obj;

	set wa $w.att_$att;
	frame $wa;
	set label [label $wa.label -text "Terminator:  "];
	set off [radiobutton $wa.off -text "Off" -relief flat \
	        -variable Obj($ID.$att) -value 0];
	set on [radiobutton $wa.on -text "On" -relief flat \
	        -variable Obj($ID.$att) -value 1];
	pack $label -side left;
	pack $off $on -side left -padx 2;

	return $wa;
}



#-----------------------------------------------------------------------
proc ColorMixer {ID att conf_w} {
	global	Color Obj;

	set rv [Color::MixerPalette $att $Obj($ID.$att.r) $Obj($ID.$att.g) \
	  $Obj($ID.$att.b)];

	if {$rv == 1} {
		set Obj($ID.$att) $Color(selected);
		set Obj($ID.$att.r) $Color(selected.r);
		set Obj($ID.$att.g) $Color(selected.g);
		set Obj($ID.$att.b) $Color(selected.b);
		$conf_w config -bg $Obj($ID.$att) \
		  -activebackground $Obj($ID.$att);
	}
}

proc Color::MixerPalette {title {r 0} {g 0} {b 0}} {
	global	Color rMixerPalette;

	set w .color_palette;
	if {[winfo exists $w] != 0} {
		Warning "Color::MixPalette - window already exists";
		return "";
	}

	toplevel $w;
	wm positionfrom $w program;
	wm title $w "$title";
	set rMixerPalette 0;

	set up [frame $w.up];
	#--- mixed color
	set color [frame $up.color -relief groove -bd 3 -width 50 -height 50];

	#--- color mixer
	set rgb [frame $up.rgb -relief sunken -bd 1];
	set r_scl [scale $rgb.r -length 200 -from 0 -to 255 \
	  -sliderforeground red -activeforeground red \
	  -orient horizontal -command "Color::Select $color r"];
	set g_scl [scale $rgb.g -length 200 -from 0 -to 255 \
	  -sliderforeground green -activeforeground green \
	  -orient horizontal -command "Color::Select $color g"];
	set b_scl [scale $rgb.b -length 200 -from 0 -to 255 \
	  -sliderforeground blue -activeforeground blue \
	  -orient horizontal -command "Color::Select $color b"];
	pack $r_scl $g_scl $b_scl -side top;
	$r_scl set $r;
	$g_scl set $g;
	$b_scl set $b;
	Color::Select $color r $r;
	Color::Select $color g $g;
	Color::Select $color b $b;

	pack $color $rgb -side left -padx 2;

	set mid [frame $w.mid -relief sunken -bd 2];
	set unit 20;	#--- unit of width and height of color list
	set n_colors [llength $Color(list)];
	set c_list [canvas $mid.list -height $unit];
	if {$n_colors > 10} {
		set hsc [scrollbar $mid.hsc -relief flat \
		  -orient horizontal -command "$c_list xview"];
		$c_list config -width [expr $unit * 10] \
		  -scrollregion "0 0 [expr $unit * $n_colors] $unit" \
		  -xscrollcommand "$hsc set";
	} else {
		$c_list config -width [expr $unit * $n_colors];
	}
	pack $c_list -side top;
	catch {pack $hsc -side bottom -fill x};
	set idx 0;
	foreach col $Color(list) {
		set btn [button $c_list.col_$col \
		  -bg $col -activebackground $col -relief groove \
		  -command "eval Color::SelectAll $color \
		  [Color::Name2Deci $col] $r_scl $g_scl $b_scl"];
		$c_list create window [expr $unit * $idx] 0 -window $btn \
		  -anchor nw -width $unit -height $unit;
		incr idx;
	}

	#--- confirmation buttons
	set conf [frame $w.conf];
	set ok [button $conf.ok -text "OK" -relief groove -bd 5 -width 4 \
	  -command "set rMixerPalette 1; destroy $w"];
	set cancel [button $conf.cancel -text "Cancel" -bd 1 \
	  -command "destroy $w"];
	pack $ok $cancel -side left -expand 1 \
	  -padx 20 -pady 10;

	pack $up -side top -padx 5 -pady 5;
	pack $mid -side top -padx 5 -pady 5 -anchor e;
	pack $conf -side bottom -padx 5 -pady 5;

	#--- center the window
	set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
	  - [winfo vrootx [winfo parent $w]]]
	set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
	  - [winfo vrooty [winfo parent $w]]]
	wm geometry $w +$x+$y;
	wm deiconify $w;

	update idletasks;
	set old_focus [focus];
	set old_grab [grab current];
	grab $w;
	focus $w;
	tkwait window $w;
	grab release $w;
	catch {grab $old_grab; focus $old_focus};

	if {$rMixerPalette} {
		set Color(selected) [Color::Deci2Str $Color(selected.r) \
		  $Color(selected.g) $Color(selected.b)];
	} else {
		set Color(selected) "";
	}

	return $rMixerPalette;
}

proc Color::Select {w color value} {
	global	Color;

	set Color(selected.$color) $value;
	set col [Color::Deci2Str \
	  $Color(selected.r) $Color(selected.g) $Color(selected.b)];

	$w config -bg $col;
}


proc Color::SelectAll {w r g b r_scl g_scl b_scl} {
	global	Color;

	set Color(selected.r) $r;
	set Color(selected.g) $g;
	set Color(selected.b) $b;
	set col [Color::Deci2Str \
	  $Color(selected.r) $Color(selected.g) $Color(selected.b)];
	$r_scl set $Color(selected.r);
	$g_scl set $Color(selected.g);
	$b_scl set $Color(selected.b);

	$w config -bg $col;
}


########################################################################
#
#	Start Up
#
########################################################################

Mutate::Init;


# EoF
