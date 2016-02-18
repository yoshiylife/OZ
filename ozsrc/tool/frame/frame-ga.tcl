#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	<<< OZ++/Frame Graphic Agent >>>
#
#	Core and Mutater modules
#
#	Akihito NAKAMURA, Electrotechnical Lab., Feb. 5, 1996
#

set Frame(version)	0.116;


########################################################################
###
###		Global variables
###
########################################################################

set Frame(standard.width)	512;
set Frame(standard.height)	342;
set Frame(tool.selected)	"";	# selected tool
set Frame(color)	{white yellow green blue red purple gray black};

# set Series(mode)	"";	# screen|slide
set Series(item.selected)	{};	# selected item IDs
set Series(item.num_att)	{ID coordx coordy width height fontsize};
set Series(item.str_att)	{type name state label text font \
				 fgcolor bgcolor \
				 activebgcolor activefgcolor justify value};

set Screen(ID)		"";
set Slide(ID)		"";
set Item(dummy)		"";
set Win(dummy)		"";

set Group(names)	{};	#--- radiobutton group names

set OpenProc(button)		openButton;
set OpenProc(checkbutton)	openCheckButton;
set OpenProc(radiobutton)	openRadioButton;
set OpenProc(field)		openField;
set OpenProc(string)		openString;

set RefleshProc(button)		refreshButton;
set RefleshProc(checkbutton)	refreshButton;
set RefleshProc(radiobutton)	refreshButton;
set RefleshProc(field)		refreshField;
set RefleshProc(string)		refreshString;

set AttProc(ID)		InfoConst;
set AttProc(type)	InfoConst;
set AttProc(name)	InfoStr;
set AttProc(label)	InfoStr;
set AttProc(state)	InfoState;	#--- normal | disabled
set AttProc(geom)	InfoGeom;	#--- x, y, width, height
set AttProc(color)	InfoColor;	#--- bg, fg, activefg, activebg
set AttProc(font)	InfoFont;	#--- font, fontsize
set AttProc(justify)	InfoJustify;	#--- left | center | right
set AttProc(value)	InfoInt;


########################################################################
###
###		Core part
###
########################################################################

#-----------------------------------------------------------------------
proc OpenSeries {name width height args} {
	global	Frame Series;

	openSeries $width $height;

	# wm protocol . WM_DELETE_WINDOW ExitFrame;

	set Series(name)	$name;
	set Series(width)	$width;
	set Series(height)	$height;
	set Series(item)	{};
	set Series(group)	{};
	set Series(sel_item)	{};
}

proc openSeries {width height} {
	.series config -width $width -height $height;
}


#	var_name index op = pseudo parameters set by TRACE
#-----------------------------------------------------------------------
proc changeTitle {var_name index op} {
	global	Frame Series;

	wm title . "OZ++/Frame($Frame(version)): $Series(name)";
}


#	args = attribute list
#		supported attributes: bgcolor
#-----------------------------------------------------------------------
proc OpenScreen {ID name args} {
	global	Screen;

	set Screen(ID)		$ID;
	set Screen(name)	$name;

	foreach att $args {
		set att_type [lindex $att 0];
		set att_val  [lindex $att 1];
		set Screen($att_type) "$att_val";
		switch $att_type {
		  bgcolor {
			.series config -bg $Screen(bgcolor);
		  }
		}
	}
}

#	args = attribute list, i.e. {number x}
#-----------------------------------------------------------------------
proc OpenSlide {ID name args} {
	global	Series Slide;

	set Slide(ID)	$ID;
	set Slide(name)	$name;

	foreach att $args {
		set att_type [lindex $att 0];
		set att_val  [lindex $att 1];
		set Slide($att_type) "$att_val";
		switch $att_type {
		  number {
			#--- set the current position
			# .navi.scroll set $att_val;
		  }
		}
	}
}


#-----------------------------------------------------------------------
proc OpenItem {type ID args} {
	global	Series Item OpenProc;

	resetItemAtt $ID;

	set Item($ID.ID)	$ID;
	set Item($ID.type)	$type;

	set geom [eval findAtt geom $args];
#	Debug "OpenItem: geom = $geom";
	if {"$geom" != ""} {
		eval $OpenProc($type) $ID $geom $args;
		lappend Series(item)	$ID;
		Debug "OpenItem: opened items are... $Series(item)";

		return $ID
	} else {
		Warning "OpenItem - geometry undefined";

		return "";
	}
}

proc OpenItemXXX {type ID coordx coordy args} {
	global	Series Item OpenProc;

	if {"[lindex $coordx 0]" != "coordx" ||
	    "[lindex $coordy 0]" != "coordy"} {
		Debug "OpenItem (ID=$ID) failed: invalid coordinate argument";
		return;
	}
	set x [lindex $coordx 1];
	set y [lindex $coordy 1];

	resetItemAtt $ID;

	set Item($ID.ID)	$ID;
	set Item($ID.type)	$type;
	set Item($ID.coordx)	$x;
	set Item($ID.coordy)	$y;

	eval $OpenProc($type) $ID $x $y $args;
	lappend Series(item)	$ID;

	Debug "OpenItem: opened items are... $Series(item)";

	return $ID
}

proc CloseItem {args} {
	global	Series Item Group;

	if {"$args" == "all"} {
		set args $Series(item);
	}

	foreach ID $args {
		set index [lsearch $Series(item) $ID];
		if {$index == -1} continue;

		.series delete item$ID;

		switch $Item($ID.type) {
		  button -
		  checkbutton -
		  radiobutton -
		  field {
			destroy .series.item$ID;
		  }
		}

		set Series(item) [lreplace $Series(item) $index $index];
		Mutate::ReleaseItem $ID;

		#--- type-dependent procedure
		switch $Item($ID.type) {
		  radiobutton {
			set g $Item($ID.group);
			Group::RemoveMember $g $ID;
		  }
		}
	}

	Debug "CloseItem: opened items are... $Series(item)";

	return $ID;
}

proc RefreshItem {ID args} {
	global	RefleshProc Item;

	eval {$RefleshProc($Item($ID.type)) $ID} $args;

	return $ID;
}

proc DeleteItem {ID} {
	CloseItem $ID;
}

proc CheckCheckbutton {ID var} {
	global	Item;

	set Item($ID.check) $var;
}

proc SelectRadiobutton {ID} {
	global	Item Group;

	set Group($Item($ID.group).pushed) $ID;
	set Group($Item($ID.group).selected) $ID;
}

proc GetField {ID} {
	global	Item Win;

	set win $Win($Item($ID.citem).path);
	set text [$win get];
	SendOZ "\{FieldTextChanged $ID '$text'\}";
}


proc Quit {} {
	Debug "Quit GA";
	destroy .;
	exit;
}

#-----------------------------------------------------------------------
proc openButton {ID x y args} {
	eval open_button button $ID $x $y $args;
	return $ID;
}

proc openCheckButton {ID x y args} {
	eval open_button checkbutton $ID $x $y $args;
	return $ID;
}

proc openRadioButton {ID x y args} {
	eval open_button radiobutton $ID $x $y $args;
	return $ID;
}

proc open_button {type ID x y args} {
	global	Item Win;

	switch $type {
	  button {
		set btn [eval {button .series.item$ID} \
		               {-bd 1 -command "ButtonB1Press $ID"}];
	  }
	  checkbutton {
		set Item($ID.check) 0;
		set btn [eval {checkbutton .series.item$ID} \
		               {-bd 1 -command "ButtonB1Press $ID"}];
#		set btn [eval {checkbutton .series.item$ID} \
#		               {-variable Item($ID.check)} \
#		               {-bd 1 -command "ButtonB1Press $ID"}];
	  }
	  radiobutton {
		set btn [eval {radiobutton .series.item$ID} \
		               {-bd 1 -command "ButtonB1Press $ID"}];
	  }
	}

	set cid [.series create window $x $y -window $btn -anchor nw];
	set Item($ID.citem)	$cid;
	set Win($cid.path)	$btn;
	set Win($cid.ID)	$ID;

	.series addtag item	withtag $cid;
	.series addtag item$ID	withtag $cid;
	.series addtag button	withtag $cid;

	eval refreshButton $ID $args;
	correctItemSize $ID;

	return $ID;
}


#	name = attribute name
#	args = attribute list
#-----------------------------------------------------------------------
proc findAtt {name args} {
	set val "";
	foreach att $args {
		set att_name [lindex $att 0];
		if {"$att_name" == "$name"} {
			set val [lreplace $att 0 0];
		}
	}

	return "$val";
}

proc rmAtt {name args} {
	set result {};
	set idx 0;
	foreach att $args {
		set att_name [lindex $att 0];
		if {"$att_name" != "$name"} {
			lappend result $att;
		}
	}

	return $result;
}


#-----------------------------------------------------------------------
proc refreshButton {ID args} {
	global	Series Item Win Group Radiobutton;

#	Debug "configButton args = $args";
	set cid $Item($ID.citem);
	set win $Win($cid.path);
	set coords [.series coords $cid];

	foreach att $args {
		set att_type	[lindex $att 0];
		set att_val	[lreplace $att 0 0];
#		Debug "config $att_type = $att_val";
		set Item($ID.$att_type) "$att_val";

		switch $att_type {
		  geom {
			eval .series coords $cid $att_val;
			set Item($ID.coordx) [lindex $att_val 0];
			set Item($ID.coordy) [lindex $att_val 1];
		  }
		  coordx { .series coords $cid $att_val [lindex $coords 1];  }
		  coordy { .series coords $cid [lindex $coords 0] $att_val;  }
		  size {
			set Item($ID.width)  [lindex $att_val 0];
			set Item($ID.height) [lindex $att_val 1];
			.series itemconfigure $cid \
			  -width $Item($ID.width) -height $Item($ID.height);
		  }
		  width - height {
			.series itemconfigure $cid -$att_type $att_val;
		  }
		  label { eval $win config -text "$att_val"; }
		  state { $win config -state $att_val;	  }
		  bgcolor { $win config -bg $att_val;	  }
		  fgcolor { $win config -fg $att_val;	  }
		  activebgcolor { $win config -activebackground $att_val;  }
		  activefgcolor { $win config -activeforeground $att_val;  }

		  check {
			if {$att_val != 0} {
				$win select;
				set Item($ID.check) $att_val;
			}
		  }

		  #--- radiobutton
		  group {
			if {![Group::Exists $att_val]} {
				Group::Create $att_val;
			}
			Group::AddMember $att_val $ID;
			$win config -value $ID \
			  -variable Group($att_val.pushed);
		  }

		  select {
			if {"$Item($ID.type)" == "radiobutton" &&
			    $att_val != 0} {
				set group $Item($ID.group);
				set Group($group.pushed) $ID;
				set Group($group.selected) $ID;
			}
		  }
		}
	}
	if {"$Item($ID.bgcolor)" == ""} {
		set Item($ID.bgcolor) [lindex [$win config -bg] 4];
	}
	if {"$Item($ID.fgcolor)" == ""} {
		set Item($ID.fgcolor) [lindex [$win config -fg] 4];
	}
	if {"$Item($ID.activefgcolor)" == ""} {
		set Item($ID.activefgcolor) \
		  [lindex [$win config -activeforeground] 4];
	}
	if {"$Item($ID.activebgcolor)" == ""} {
		set Item($ID.activebgcolor) \
		  [lindex [$win config -activebackground] 4];
	}
	if {"$Item($ID.type)" == "radiobutton" && "$Item($ID.group)" == ""} {
		set Item($ID.group) \
		  [lindex [$win config -variable] 4];
		$win config -value $ID;
	}

	return $ID;
}


proc Group::Create {name} {
	global	Group;

	if {![Group::Exists $name]} {
		lappend Group(names) $name;
		Group::Reset $name;
	}
}

proc Group::Exists {name} {
	global	Group;

	if {[lsearch $Group(names) $name] != -1} {
		return 1;
	} else {
		return 0;
	}
}

proc Group::IsMember {name ID} {
	global	Group;

	if {[Group::Exists $name] && [lsearch $Group($name.IDs) $ID] != -1} {
		return 1;
	} else {
		return 0;
	}
}

proc Group::AddMember {name ID} {
	global	Group;

	if {[Group::Exists $name]} {
		if {[lsearch $Group($name.IDs) $ID] == -1} {
			lappend Group($name.IDs) $ID;
		}
		return $ID;

	} else {
		return "";
	}
}

proc Group::RemoveMember {name ID} {
	global	Group;

	if {[Group::IsMember $name $ID]} {
		set idx [lsearch $Group($name.IDs) $ID];
		set Group($name.IDs) [lreplace $Group($name.IDs) $idx $idx];
		if {$Group($name.pushed) == $ID} {
			set Group($name.pushed) "";
			set Group($name.selected) "";
		}
	}
}

proc Group::Reset {name} {
	global	Group;

	set Group($name.IDs) {};
	set Group($name.selected) "";
	set Group($name.pushed) "";
}


proc openField {ID x y args} {
	global	Item Win;

	set ent [eval {entry .series.item$ID -relief sunken -bd 1}];
	bind $ent <ButtonRelease-1> "+ FieldB1Press $ID";
	bind $ent <Return> "+ fieldEvent $ID TextChanged";
	bind $ent <ButtonPress-2> "+ FieldB2Press $ID";

	set cid [.series create window $x $y -window $ent -anchor nw];
	set Item($ID.citem)	$cid;
	set Win($cid.path)	$ent;
	set Win($cid.ID)	$ID;

	.series addtag item	withtag $cid;
	.series addtag item$ID	withtag $cid;
	.series addtag field	withtag $cid;

	eval refreshField $ID $args;
	correctItemSize $ID;

	return $ID;
}

proc refreshField {ID args} {
	global	Item Win;

#	Debug "refreshField args = $args";
	set cid $Item($ID.citem);
	set win $Win($cid.path);
	set coords [.series coords $cid];

	foreach att $args {
		set att_type	[lindex $att 0];
		set att_val	[lreplace $att 0 0];
#		Debug "$att_type = $att_val";
		set Item($ID.$att_type) "$att_val";
		switch $att_type {
		  geom {
			eval .series coords $cid $att_val;
			set Item($ID.coordx) [lindex $att_val 0];
			set Item($ID.coordy) [lindex $att_val 1];
		  }
		  size {
			set Item($ID.width)  [lindex $att_val 0];
			set Item($ID.height) [lindex $att_val 1];
			.series itemconfigure $cid \
			  -width $Item($ID.width) -height $Item($ID.height);
		  }
		  width - height {
			.series itemconfigure $cid -$att_type $att_val;
		  }
		  state { $win config -state $att_val; }
		  bgcolor { $win config -bg $att_val;  }
		  fgcolor { $win config -fg $att_val;  }
		  text {
			$win delete 0 end;
			eval $win insert 0 "$att_val";
		  }
		}
	}

	return $ID;
}

proc fieldEvent {ID event} {
	global	Item Win;

	set cid $Item($ID.citem);
	set win $Win($cid.path);

	switch $event {
	  TextChanged {
		set text [$win get];
		SendOZ "\{FieldTextChanged $ID '$text'\}";
		focus none;
	  }
	}
}



#-----------------------------------------------------------------------
proc openString {ID x y args} {
	global	Item Win;

	set cid [.series create text $x $y -anchor nw];
	set Item($ID.citem)	$cid;
	set Win($cid.ID)	$ID;

	.series addtag item	withtag $cid;
	.series addtag item$ID	withtag $cid;
	.series addtag string	withtag $cid;

	eval refreshString $ID $args;
	correctItemSize $ID;

	.series bind $cid <ButtonPress-1> "StringB1Press $ID";

	return $ID;
}

proc refreshString {ID args} {
	global	Item;

#	Debug "refreshString args = $args";
	set cid $Item($ID.citem);
	set coords [.series coords $cid];

	foreach att $args {
		set att_type	[lindex $att 0];
		set att_val	[lreplace $att 0 0];
#		Debug "$att_type = $att_val";
		set Item($ID.$att_type) "$att_val";
		switch $att_type {
		  geom {
			eval .series coords $cid $att_val;
			set Item($ID.coordx) [lindex $att_val 0];
			set Item($ID.coordy) [lindex $att_val 1];
		  }
		  fgcolor {
			.series itemconfigure $cid -fill $att_val;
		  }
		  text - width - justify {
			eval .series itemconfigure $cid -$att_type "$att_val";
		  }
		}
	}

	return $ID;
}


#	compute width and height
#-----------------------------------------------------------------------
proc correctItemSize {ID} {
	global	Item Win;

	if {$Item($ID.width) == 0 || $Item($ID.height) == 0} {
		set coords [.series bbox $Item($ID.citem)];
		if {"$coords" == ""} {
			Warning "correctItemSize - no such Item (ID=$ID)";
			return "";
		}

		set Item($ID.width) \
		  [expr [lindex $coords 2] - [lindex $coords 0]];
		set Item($ID.height) \
		  [expr [lindex $coords 3] - [lindex $coords 1]];

#		Debug "correctItemSize - ($Item($ID.width), $Item($ID.height))";
	}
}

#-----------------------------------------------------------------------
proc resetItemAtt {ID} {
	global	Series Item;

	foreach att $Series(item.num_att) { set Item($ID.$att) 0; }
	foreach att $Series(item.str_att) { set Item($ID.$att) ""; }
	set Item($ID.state) normal;
	set Item($ID.justify) left;
}

proc deleteItemAtt {ID} {
	global	Series Item;

	foreach att $Series(item.num_att) { unset Item($ID.$att); }
	foreach att $Series(item.str_att) { unset Item($ID.$att); }
}

proc copyItemAtt {ID copyID} {
	global	Series Item;

	foreach att $Series(item.num_att) {
		set Item($copyID.$att) $Item($ID.$att);
	}
	foreach att $Series(item.str_att) {
		set Item($copyID.$att) $Item($ID.$att);
	}
}


########################################################################
###
###		Event Handling
###
########################################################################

proc ButtonB1Press {ID} {
	global	Frame Item Win Group;

	switch $Frame(tool.selected) {
	  browse {
		ButtonBrowseEvent $ID;
	  }
	  item_delete {
		Tool::Select browse;
		switch $Item($ID.type) {
		  checkbutton {
			set cid $Item($ID.citem);
			set win $Win($cid.path);
			$win toggle;
		  }
		  radiobutton {
			set g $Item($ID.group);
			set Group($g.pushed) $Group($g.selected);
		  }
		}
		Mutate::DeleteItem $ID;
	  }
	  item_info {
		Tool::Select browse;
		switch $Item($ID.type) {
		  checkbutton {
			set cid $Item($ID.citem);
			set win $Win($cid.path);
			$win toggle;
		  }
		  radiobutton {
			set g $Item($ID.group);
			set Group($g.pushed) $Group($g.selected);
		  }
		}
		Mutate::ConfigItem $ID;
	  }
	}
}

proc ButtonBrowseEvent {ID} {
	global	Item Group;

	switch $Item($ID.type) {
	  button {
		SendOZ "\{ButtonMouseUp $ID\}";
	  }
	  checkbutton {
		if {$Item($ID.check) == 0} {
			set Item($ID.check) 1;
			SendOZ "\{CheckButton On $ID\}";
		} else {
			set Item($ID.check) 0;
			SendOZ "\{CheckButton Off $ID\}";
		}
	  }
	  radiobutton {
		set Group($Item($ID.group).selected) $ID;
		SendOZ "\{RadioButtonSelected $ID\}"
	  }
	}
}

proc FieldB1Press {ID} {
	global	Frame Item Win;

	switch $Frame(tool.selected) {
	  browse {
		#--- do nothing
	  }
	  item_delete {
		focus none;
		$Win($Item($ID.citem).path) select clear;
		Mutate::DeleteItem $ID;
		Tool::Select browse;
	  }
	  item_info {
		focus none;
		$Win($Item($ID.citem).path) select clear;
		Mutate::ConfigItem $ID;
		Tool::Select browse;
	  }
	}
}

proc FieldB2Press {ID} {
	global	Frame;

	switch $Frame(tool.selected) {
	  browse {OpenFieldValueBox $ID;}
	}
}

proc OpenFieldValueBox {ID} {
	global	Item;

	set result [GetLine .field_value_$ID "Field Value" {} \
	  50 "$Item($ID.value)"];

	set cmd [lindex $result 0];
	set val [lindex $result 1];
	if {"$cmd" == "get"} {
		SendOZ "{ItemAttChanged $ID {value '$val'}}";
	}
}

proc StringB1Press {ID} {
	global	Frame;

	switch $Frame(tool.selected) {
	  browse {
		#--- Do nothing
	  }
	  item_delete {
		Mutate::DeleteItem $ID;
		Tool::Select browse;
	  }
	  item_info {
		Mutate::ConfigItem $ID;
		Tool::Select browse;
	  }
	}
}


########################################################################
###
###		Mutate
###
########################################################################

#-----------------------------------------------------------------------
proc ConfigSeries {} {
	global	Series;

	set Series(copyname) $Series(name);
	set Series(copywidth) $Series(width);
	set Series(copyheight) $Series(height);
	set result [OpenSeriesInfoBox];

	if {$result} {
		OzConfigSeries;
	}
	unset Series(copyname) Series(copywidth) Series(copyheight);
}

proc OpenSeriesInfoBox {} {
	global	Frame Series rOpenSeriesInfoBox;

	set rOpenSeriesInfoBox 0;

	#--- Top-level window
	set w .series_info;
	toplevel $w;
	wm positionfrom $w program;
	wm geometry $w -20+0;
	wm title $w "Series Info ($Series(name))"

	#--- Name attribute
	set name [frame $w.name];
	label $name.l -text "Name:  ";
	entry $name.e -relief sunken -bd 1 -textvariable Series(copyname);
	bind $name.e <Return> "+ focus none";
	pack $name.l $name.e -side left;

	#--- Size attribute
	set size [frame $w.size];
	set sl [label $size.l -text "Size"];
	set sw [frame $size.w];
	set sh [frame $size.h];
	set swl [label $sw.l -text "  width:  "];
	set swv [entry $sw.v -relief sunken -bd 1 -width 5 \
	        -textvariable Series(copywidth)];
	bind $swv <Return> "+ focus none";
	pack $swl $swv -side left;
	set shl [label $sh.l -text " height:  "];
	set shv [entry $sh.v -relief sunken -bd 1 -width 5 \
	        -textvariable Series(copyheight)];
	bind $shv <Return> "+ focus none";
	pack $shl $shv -side left;

	pack $sl $sw $sh -side top -anchor w;

	#--- Confirmation buttons
	set exit [frame $w.exit];
	set ok [button $exit.ok -text "OK" -relief groove -bd 5 -width 4 \
	  -command "set rOpenSeriesInfoBox 1; destroy $w"];
	set cancel [button $exit.cancel -text "Cancel" -bd 1 \
	  -command "destroy $w"];
	pack $ok $cancel -side left -expand 1 \
	  -padx 20 -pady 10 -ipadx 4 -ipady 2;

	pack $name $size $exit -side top -fill x -padx 4 -pady 2;

	update;
	grab $w;
	tkwait window $w;
	grab release $w;

	return $rOpenSeriesInfoBox;
}

proc OzConfigSeries {} {
	global	Series;

	set diff {};
	if {"$Series(copyname)" != "$Series(name)"} {
		lappend diff "name '$Series(copyname)'";
	}
	if {$Series(copywidth) != $Series(width)} {
		lappend diff "width $Series(copywidth)";
	}
	if {$Series(copyheight) != $Series(height)} {
		lappend diff "height $Series(copyheight)";
	}

	if {"$diff" != ""} {
		SendOZ "{SeriesAttChanged $diff}";
	}
}

#	Make confirmation and send a message of deletion to OZ.
#-----------------------------------------------------------------------
proc Mutate::DeleteItem {ID} {
	Mutate::SelectItem $ID;
	set result [Mutate::OpenItemDeleteBox $ID];
	if {$result} {
		#--- Sending a message of deletion to OZ
		Mutate::InvokeOzDeleteItem $ID;
	}
	Mutate::ReleaseItem $ID;
}

#-----------------------------------------------------------------------
proc Mutate::ConfigItem {ID} {
	global	Series Item;

	if {[lsearch $Series(item) $ID] == -1} {
		Debug "Mutate::ConfigItemAtt - invalid ID ($ID)";
		return error;
	}
	Mutate::SelectItem $ID;

	#--- Make a copy of attributes ---
	set copyID copy$ID;
	resetItemAtt $copyID;
	copyItemAtt $ID $copyID;

	set result [Mutate::OpenItemConfigBox $ID $copyID];
	if {$result == 1} {
		Mutate::InvokeOzMutate $ID $copyID;
	}
	Mutate::ReleaseItem $ID;

	deleteItemAtt $copyID;
}


#	path = root FRAME widget path
#-----------------------------------------------------------------------
proc Mutate::OpenItemConfigBox {ID copyID} {
	global	Frame Series Item AttProc rOpenItemConfigBox;

	#--- Create a new window ---
	set w .item_att_$ID;
	if {[winfo exists $w] != 0} {
		Waning "Mutate::OpenItemConfigBox - already exists";
		raise $w;
		return 0;
	}
	toplevel $w;
	wm positionfrom $w program;
	wm geometry $w -20+0;
#	wm geometry $w +$Frame(display_center_x)+$Frame(display_center_y);
	wm title $w "Item Att. Info ($Series(name):$ID)";
	set rOpenItemConfigBox 0;

	#--- prepare the attributes to be configured
	switch $Item($ID.type) {
	  button -
	  checkbutton -
	  radiobutton {
		set atts {ID type name label geom value state color};
	  }

	  field {
		set atts {ID type name geom state color};
	  }
	  string {
		set atts {ID type name geom justify color};
	  }
	}

	#--- Configure for each Attribute
	foreach att $atts {
		set f [eval $AttProc($att) $w $copyID $att];
		if {"$f" != ""} {
			pack $f -side top -anchor w -fill x -padx 2 -pady 4;
		}
	}

	set exit [frame $w.exit];
	set ok [button $exit.ok -text "OK" -relief groove -bd 5 -width 4 \
	  -command "set rOpenItemConfigBox 1; destroy $w"];
	set cancel [button $exit.cancel -text "Cancel" -bd 1 \
	  -command "destroy $w"];
	pack $ok $cancel -side left -expand 1 \
	  -padx 20 -pady 10 -ipadx 4 -ipady 2;
	pack $exit -side bottom -fill x;

	update;
	grab $w;
	tkwait window $w;
	grab release $w;

	return $rOpenItemConfigBox;
}


#	w = parent widget path
#-----------------------------------------------------------------------
proc InfoStr {w ID att} {
	global	Item;

	set wa $w.att_$att;
	if {[winfo exists $wa] == 1} {
		Warning "InfoStr - path already exists ($att)";
		return "";
	}

	switch $att {
	  name { set lb "Name:   "; }
	  label { set lb "Label:  "; }
	  default {
		Warning "InfoStr - unknown attribute ($att)";
		return "";
	  }
	}

	frame $wa;
	set label [label $wa.label -text $lb];
	set value [entry $wa.value -relief sunken -bd 1 -width 20 \
	           -textvariable Item($ID.$att)];
	bind $value <Return> "+ focus none";
	pack $label $value -side left -ipadx 2 -ipady 2;

	return $wa;
}


#	w = parent widget path
#-----------------------------------------------------------------------
proc InfoConst {w ID att} {
	global	Item;

	set wa $w.att_$att;
	if {[winfo exists $wa] == 1} {
		Warning "InfoStr - path already exists ($att)";
		return "";
	}

	switch $att {
	  ID { set lb "ID:   "; }
	  type { set lb "Type:  "; }
	  default {
		Warning "InfoConst - unknown attribute ($att)";
		return "";
	  }
	}

	frame $wa;
	set label [label $wa.label -text "$lb"];
	set value [label $wa.value -text "$Item($ID.$att)"];
	pack $label $value -side left -ipadx 2 -ipady 2;

	return $wa;
}


#	w = parent widget path
#-----------------------------------------------------------------------
proc InfoGeom {w ID att} {
	global	Item;

	set wa $w.att_$att;
	if {[winfo exists $wa] == 1} {
		Warning "InfoStr - path already exists ($att)";
		return "";
	}

	frame $wa;

	#--- Position
	set pos [frame $wa.pos];
	pack $pos -side left -padx 10 -pady 5;

	set l [label $pos.l -text "Position"];
	set x [frame $pos.x];
	set y [frame $pos.y];
	set xl [label $x.l -text "x:  "];
	set xv [entry $x.v -relief sunken -bd 1 -width 5 \
	        -textvariable Item($ID.coordx)];
	bind $xv <Return> "+ focus none";
	pack $xl $xv -side left;
	set yl [label $y.l -text "y:  "];
	set yv [entry $y.v -relief sunken -bd 1 -width 5 \
	        -textvariable Item($ID.coordy)];
	bind $yv <Return> "+ focus none";
	pack $yl $yv -side left;
	pack $l $x $y -side top -anchor w;

	#--- Size
	switch $Item($ID.type) {
	  button -
	  checkbutton -
	  radiobutton -
	  field {
		set size [frame $wa.size];
		pack $pos $size -side left -padx 10 -pady 5;

		set l [label $size.l -text "Size"];
		set w [frame $size.w];
		set h [frame $size.h];
		set wl [label $w.l -text "width:  "];
		set wv [entry $w.v -relief sunken -bd 1 -width 5 \
		        -textvariable Item($ID.width)];
		bind $wv <Return> "+ focus none";
		pack $wl $wv -side left;
		set hl [label $h.l -text "heught:  "];
		set hv [entry $h.v -relief sunken -bd 1 -width 5 \
		        -textvariable Item($ID.height)];
		bind $hv <Return> "+ focus none";
		pack $hl $hv -side left;
		pack $l -side top;
		pack $w $h -side top -anchor e;
	  }
	}

	return $wa;
}


#	w = parent widget path
#-----------------------------------------------------------------------
proc InfoState {w ID att} {
	global	Item;

	set wa $w.att_$att;
	if {[winfo exists $wa] == 1} {
		Warning "InfoState - path already exists ($att)";
		return "";
	}

	frame $wa;
	set r [frame $wa.r];
	set label [label $wa.label -text "State:  "];
	set s1 [radiobutton $r.s1 -text "normal" -width 10 -relief flat \
	        -variable Item($ID.$att) -value normal -anchor w];
	set s2 [radiobutton $r.s2 -text "disabled" -width 10 -relief flat \
	        -variable Item($ID.$att) -value disabled -anchor w];
	pack $s1 $s2 -side top;
	pack $label $r -side left -ipadx 2 -ipady 2;

	return $wa;
}


#-----------------------------------------------------------------------
proc InfoJustify {w ID att} {
	global	Item;

	set wa $w.att_$att;
	if {[winfo exists $wa] == 1} {
		Warning "InfoJustify - path already exists ($att)";
		return "";
	}

	frame $wa;
	set label [label $wa.label -text "Justify:  "];
	set left [radiobutton $wa.l -text "L" -relief flat \
	        -variable Item($ID.$att) -value left];
	set center [radiobutton $wa.c -text "C" -relief flat \
	        -variable Item($ID.$att) -value center];
	set right [radiobutton $wa.r -text "R" -relief flat \
	        -variable Item($ID.$att) -value right];
	pack $label -side left;
	pack $left $center $right -side left -padx 2;

	return $wa;
}


#	w = parent widget path
#-----------------------------------------------------------------------
proc InfoInt {w ID att} {
	global	Item;

	set wa $w.att_$att;
	if {[winfo exists $wa] == 1} {
		Warning "InfoInt - path already exists ($att)";
		return "";
	}

	frame $wa;
	set label [label $wa.label -text "Value:  "];
	set value [entry $wa.value -relief sunken -bd 1 -width 5 \
	           -textvariable Item($ID.$att)];
	pack $label $value -side left -ipadx 2 -ipady 2;

	return $wa;
}


proc InfoColor {w ID att} {
	global	Frame Item;

	set wa $w.att_$att;
	if {[winfo exists $wa] == 1} {
		Warning "InfoColor - path already exists ($att)";
		return "";
	}

	switch $Item($ID.type) {
	  button -
	  checkbutton -
	  radiobutton {
		#--- bg, fg, activefg, activebg
		set atts {bgcolor fgcolor activebgcolor activefgcolor};
	  }
	  field {
		#--- bg, fg
		set atts {bgcolor fgcolor};
	  }
	  string {
		#--- fg
		set atts {fgcolor};
	  }
	}

	set w [frame $wa];
	set wl [label $w.l -text "Color"];
	foreach att $atts {
		set wc [frame $w.$att];
		pack $wc -side top -fill x;
		set wcl [label $wc.l -text "$att:  "];
		set wcf [frame $wc.f];
		pack $wcl $wcf -side left;
		menubutton $wcf.btn \
		  -relief raised -bd 1 -width 4 -menu $wcf.btn.m;
		catch {$wcf.btn config -activebackground $Item($ID.$att) \
		  -background $Item($ID.$att)};
		pack $wcf.btn;
		tk_menuBar $wcf $wcf.btn;

		set m [menu $wcf.btn.m -bd 1];
		set idx 0;
		foreach color $Frame(color) {
			$m add command -label "    " \
			  -command "set Item($ID.$att) $color; \
			  catch {$wcf.btn config -activebackground $color \
			  -background $color}";
			catch {$m entryconfigure $idx \
			       -activebackground $color -background $color};
			incr idx;
		}
	}

	return $wa;
}


#	Find the difference between original attributes and copy ones.
#-----------------------------------------------------------------------
proc Mutate::InvokeOzMutate {ID copyID} {
	global	Series Item;

	set diff {};
	set atts [concat $Series(item.num_att) $Series(item.str_att)];
	foreach att $atts {
		if {"$Item($ID.$att)" != "$Item($copyID.$att)"} {
			set isStr [lsearch $Series(item.str_att) $att];
			if {$isStr == -1} {
				lappend diff "$att $Item($copyID.$att)";
			} else {
				lappend diff "$att '$Item($copyID.$att)'";
			}
		}
	}

	set x [eval findAtt coordx $diff];
	set y [eval findAtt coordy $diff];
	set geom "";
	if {"$x" != "" || "$y" != ""} {
		if {"$x" == ""} {set x $Item($copyID.coordx);}
		if {"$y" == ""} {set y $Item($copyID.coordy);}
		set diff [eval rmAtt coordx $diff];
		set diff [eval rmAtt coordy $diff];
		lappend diff "geom $x $y";
	}

	set w [eval findAtt width $diff];
	set h [eval findAtt height $diff];
	set size "";
	if {"$w" != "" || "$h" != ""} {
		if {"$w" == ""} {set w $Item($copyID.width);}
		if {"$h" == ""} {set h $Item($copyID.height);}
		set diff [eval rmAtt width $diff];
		set diff [eval rmAtt height $diff];
		lappend diff "size $w $h";
	}

#	Debug "Mutate::InvokeOzMutate - diff = $diff";

	if {"$diff" != ""} {
		SendOZ "{ItemAttChanged $ID $diff}";
	} else {
#		Debug "Mutate::InvokeOzMutate - no change";
	}
}


proc Mutate::OpenItemDeleteBox {ID} {
	global	Item;

	set result \
	  [tk_dialog .item_delete_$ID "DeleteItem $ID" \
	   "Do you really want to delete the Item ?" \
	   question 0 {Delete} {Cancel}];

	if {$result == 0} {
		return 1;
	} else {
		return 0;
	}
}


#	Notify the deletion of the Item to OZ
#-----------------------------------------------------------------------
proc Mutate::InvokeOzDeleteItem {ID} {
	global	Series Item;

	set idx [lsearch $Series(item) $ID];
	if {$idx != -1} {
		SendOZ "{ItemDeleted $ID}"
	}
}


#-----------------------------------------------------------------------
#  Append the ID of Item to the selected Item-ID list and show knobs
#  of each selected Items.
#	args = Item IDs
#-----------------------------------------------------------------------
proc Mutate::SelectItem {args} {
	global	Series;

	foreach ID $args {
		if {[lsearch $Series(item.selected) $ID] == -1} {
			lappend Series(item.selected) $ID;
			Mutate::ShowKnob $ID;
		}
	}
}

proc Mutate::ReleaseItem {args} {
	global	Series;

	foreach ID $args {
		set idx [lsearch $Series(item.selected) $ID];
		if {$idx != -1} {
			set Series(item.selected) \
			  [lreplace $Series(item.selected) $idx $idx];
			Mutate::HideKnob $ID;
		}
	}
}

proc Mutate::IsSelected {ID} {
	global	Series;

	if {[lsearch $Series(item.selected) $ID] == -1} {
		return 0;
	} else {
		return 1;
	}
}

proc Mutate::ShowKnob {args} {
	global	Item;

	foreach ID $args {
		switch $Item($ID.type) {
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

#-----------------------------------------------------------------------
proc Mutate::BasicInfoInit {path} {
	global	Frame;

	#--- Screen small info.
	frame $path.scr_info;
	set scr $path.scr_info;

	label $scr.name_l -text "Screen:";
	entry $scr.name -width 10 -relief sunken;
	entry $scr.id -width 4 -relief sunken;
	pack $scr.name_l $scr.name $scr.id -side left;


	#--- Slide small info.
	frame $path.sld_info;
	set sld $path.sld_info;

	label $sld.name_l -text "Slide:";
	entry $sld.name -width 10 -relief sunken;
	entry $sld.id -width 4 -relief sunken;
	pack $sld.name_l $sld.name $sld.id -side left;

	#--- packing
	pack $scr $sld -side left;

	return $path;
}


########################################################################
###
###		Menu part
###
########################################################################

#-----------------------------------------------------------------------
proc Menu::Init {path} {
	global	Frame;

	frame $path -relief raised -bd 1;

	set Frame(win.menu.frame) \
	  [menubutton $path.frame -text "Frame" -menu $path.frame.m -bd 1];
	set Frame(win.menu.series) \
	  [menubutton $path.series -text "Series" -menu $path.series.m -bd 1];
	set Frame(win.menu.item) \
	  [menubutton $path.item -text "Item" -menu $path.item.m -bd 1];
	set Frame(win.menu.goto) \
	  [menubutton $path.goto -text "Goto" -menu $path.goto.m -bd 1];
	pack $Frame(win.menu.frame) $Frame(win.menu.series) \
	  $Frame(win.menu.item) $Frame(win.menu.goto) -side left -padx 4;

	tk_menuBar $path $Frame(win.menu.frame) $Frame(win.menu.series) \
	  $Frame(win.menu.item) $Frame(win.menu.goto);

	#--- [Frame]
	set m [menu $path.frame.m -bd 1];
	$m add command -label "Recycle (Junk) Shop" \
	  -command Menu::FrameRecycleShop -state disabled;
	$m add command -label "Quit" -command Menu::FrameQuit;

	#--- [Series]
	set m [menu $path.series.m -bd 1];
	$m add command -label "Series Info..." -command Menu::SeriesSeriesInfo;
	$m add command -label "Screen Info..." \
	  -command Menu::SeriesScreenInfo -state disabled;
	$m add command -label "Slide Info..." \
	  -command Menu::SeriesSlideInfo -state disabled;
	$m add separator;
	$m add command -label "New Slide..." \
	  -command Menu::SeriesNewSlide -state disabled;
	$m add command -label "Delete Slide..." \
	  -command Menu::SeriesDeleteSlide;

	#--- [Item]
	set m [menu $path.item.m -bd 1];
	$m add command -label "Info..." -command Menu::ItemInfo;
	$m add command -label "Delete..." -command Menu::ItemDelete;

	#--- [Goto]
	set m [menu $path.goto.m -bd 1];
	$m add command -label "First" -command "Menu::Goto first";
	$m add command -label "Prev" -command "Menu::Goto prev";
	$m add command -label "Next" -command "Menu::Goto next";
	$m add command -label "Last" -command "Menu::Goto last";

	return $path;
}

#	Menu [Frame]
#-----------------------------------------------------------------------
proc Menu::FrameRecycleShop {} {
	SendOZ "\{OpenJunkShop\}";
}

proc Menu::FrameQuit {} {
	set result [tk_dialog .quit "Quit Frame" \
	  "Do you really want to quit ?" question 0 {Quit} {Cancel}];
	if {$result == 0} {
		SendOZ "\{Quit\}";
		destroy .;
		exit;
	}
}

#	Menu [Series]
#-----------------------------------------------------------------------
proc Menu::SeriesSeriesInfo {} {
	ConfigSeries;
}

proc Menu::SeriesDeleteSlide {} {
	set result [OpenSlideDeleteBox];
	if {$result} {
		#--- Sending a message of deletion to OZ
		OzDeleteSlide;
	}
}

proc OpenSlideDeleteBox {} {
	set rv [tk_dialog .slide_delete "Slide-Deletion Confirm" \
	   "Do you really want to delete the current Slide ?" \
	   question 0 {Delete} {Cancel}];

	if {$rv == 0} {
		return 1;
	} else {
		return 0;
	}
}

#	Menu [Item]
#-----------------------------------------------------------------------
proc Menu::ItemInfo {} {
	Tool::Select item_info;
}

proc Menu::ItemDelete {} {
	Tool::Select item_delete;
}

#  Menu [Goto]
#-----------------------------------------------------------------------

#	pos = first | prev | next | last | int
proc Menu::Goto {pos} {
	OzGoto $pos;
}


########################################################################
###
###		Send a message to OZ
###
########################################################################

proc OzDeleteSlide {} {
	SendOZ "{SlideDeleted}";
}

proc OzGoto {pos} {
	SendOZ "{Goto $pos}";
}


########################################################################
###
###		Tool part
###
########################################################################

#-----------------------------------------------------------------------
proc Tool::Init {path args} {
	global	Frame;

	frame $path -relief raised -bd 1;

	set tool_btn "";
	foreach tool $args {
		set Frame(win.tool.$tool) \
		  [button $path.$tool -text "$tool" \
		   -bd 1 -command "Tool::Select $tool"];
		pack $Frame(win.tool.$tool) -side top -fill x;
	}

#	Debug "Install Tool: $args";

	return $path;
}


# manage tool-selection
#-----------------------------------------------------------------------
proc Tool::Select {new_tool} {
	global	Frame;

	set Frame(tool.selected) $new_tool;
#	Debug "Tool::Select - $Frame(tool.selected)";
	switch $new_tool {
	  browse {
		ChangeCursor hand2 .series;
	  }
	  item_info {
		ChangeCursor question_arrow .series;
	  }
	  item_delete {
		ChangeCursor pirate .series;
	  }
	}
}


# manage tool-selection
#-----------------------------------------------------------------------
proc Tool::SelectXXX {new_tool} {
	global	Frame Series;

	if {$Frame(tool.selected) != ""} {
		$Frame(win.tool.$Series(tool)) config \
		  -state normal -relief raised -bd 1;
	}

	$Frame(win.tool.$new_tool) config \
	  -state disabled -relief sunken -bd 2;
	set Frame(tool.selected) $new_tool;
}


########################################################################
###
###		Misc.
###
########################################################################

#	args = widgets
proc ChangeCursor {csr args} {
	foreach w $args {
		catch {$w config -cursor $csr};
	}
}

proc ExchangeEntry {e str} {
	$e delete 0 end;
	$e insert 0 $str;
}

proc SendOZ {msg} {
	puts stdout $msg;
	flush stdout;
}

proc Debug {msg} {
	puts stderr "Debug ... $msg";
	flush stderr;
}

proc Warning {msg} {
	puts stderr "Warning ... $msg";
	flush stderr;
}


# return: {result "line"}
#	result = get | unget
#	Result is "get" if key "Return" is entered, otherwise it is "unget".
#-----------------------------------------------------------------------
proc GetLine {w title prompt width {value ""}} {
	global	rGetLine rGetLineCommand Frame;

	set oldFocus [focus];

	#--- Top level window
	toplevel $w -class GetLine;
	wm title $w $title;
	wm iconname $w GetLine;
	wm positionfrom $w program;
	wm geometry $w +$Frame(display_center_x)+$Frame(display_center_y);

	#--- 1-line input entry
	frame $w.top -relief raised -bd 1;
	label $w.top.l -text $prompt;
	set rGetLine $value;
	entry $w.top.ent -relief sunken -bd 1 -width $width \
	  -textvariable rGetLine;
	pack $w.top.l $w.top.ent -side left -padx 4 -pady 4;

	#--- confirmation buttons
	frame $w.bot -relief raised -bd 1;
	button $w.bot.ok -text "OK" -width 4 -relief groove -bd 5 \
	  -command "destroy $w";
	button $w.bot.cancel -text "Cancel" -bd 1 \
	  -command "destroy $w";
	pack $w.bot.ok $w.bot.cancel -side left -expand 1 \
	  -padx 5 -ipadx 4 -ipady 2;

	pack $w.top -side top -fill both;
#	pack $w.bot -side bottom -fill both -ipady 10;

	bind $w <Return> "set rGetLineCommand get; destroy $w";
	bind $w.top.ent <Return> \
	  "set rGetLineCommand get; destroy $w";

	bind $w <Escape> "set rGetLineCommand unget; destroy $w";
	bind $w.top.ent <Escape> "set rGetLineCommand unget; destroy $w";

	update;
	grab set $w;
	focus $w.top.ent;
	tkwait window $w;
	focus $oldFocus;

	return "$rGetLineCommand \"$rGetLine\"";
}


########################################################################
###
###		Frame Fundamental part
###
########################################################################

#-----------------------------------------------------------------------
proc Frame::Init {} {
	global	Frame Series;

	#--- window title
	wm title . "OZ++/Frame($Frame(version)):";
	trace variable Series(name) w "changeTitle"

	#--- Menu
	set menu [Menu::Init .menu];

	#--- Tool
	set tools [Tool::Init .tools browse];
	Tool::Select browse;

	#--- Slide Navigator
	set navi [Frame::InitNavi .navi];

	#--- Series
	set Series(win.series) \
	  [canvas .series \
	   -width $Frame(standard.width) -height $Frame(standard.height) \
	   -bg white \
	   -relief ridge];
	bind .series <Double-ButtonPress-1> \
	  "Tool::Select browse; focus none";

	#--- packing the top levels
	pack $menu -side top -fill x;
#	pack $tools -side left -fill y;
	pack $navi -side bottom -fill x -ipady 2;
	pack $Series(win.series) -fill both;

	set Frame(display_center_x) [expr [winfo screenwidth .] / 2]
	set Frame(display_center_y) [expr [winfo screenheight .] / 2];
}


#-----------------------------------------------------------------------
proc Frame::InitNavi {w} {
	frame $w -relief raised -bd 1;
	button $w.first -text "|<<" -width 4 -bd 1 -command "OzGoto first";
	button $w.prev -text "<"   -width 4 -bd 1 -command "OzGoto prev";
	button $w.next -text ">"   -width 4 -bd 1 -command "OzGoto next";
	button $w.last -text ">>|" -width 4 -bd 1 -command "OzGoto last";
	pack $w.first $w.prev $w.next $w.last -side left;

	return $w;
}


########################################################################
###
###	Start Up
###
########################################################################

Frame::Init;

# EoF
