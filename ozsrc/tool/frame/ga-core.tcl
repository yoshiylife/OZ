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
#	Core mudule	0.128

#
#	Akihito NAKAMURA, Electrotechnical Lab.,
#

set Frame(GA_version)	0.128;

set Menu(menubar)	"";

set Obj(series.name)	"";
set Win(dummy)		"";
set Item(IDs)		{};
set Group(names)	{};

set Att(all)	{ID type name state coordx coordy geom width height size \
		 label text fgcolor bgcolor activebgcolor activefgcolor \
		 font fontsize justify value select group};

set Att(series)		{name size}
set Att(button)		{ID type name label geom size value state \
			 fgcolor bgcolor activebgcolor activefgcolor};
set Att(checkbutton)	{ID type name label geom size value state \
			 fgcolor bgcolor activebgcolor activefgcolor};
set Att(radiobutton)	{ID type group name label geom size value state \
			 fgcolor bgcolor activebgcolor activefgcolor};
set Att(field)		{ID type name geom size state fgcolor bgcolor};
set Att(string)		{ID type name geom justify fgcolor text};


set OpenProc(button)		OpenButton;
set OpenProc(checkbutton)	OpenCheckbutton;
set OpenProc(radiobutton)	OpenRadiobutton;
set OpenProc(field)		OpenField;
set OpenProc(string)		OpenString;

set RefreshProc(button)		RefreshWidget;
set RefreshProc(checkbutton)	RefreshWidget;
set RefreshProc(radiobutton)	RefreshWidget;
set RefreshProc(field)		RefreshWidget;
set RefreshProc(string)		RefreshCItem;


########################################################################
#
#	OZ++ I/F --- called by OZ++ Objects
#
#########################################################################

#-----------------------------------------------------------------------
proc OpenSeries {name width height args} {
	global	Series Item;

	RefreshSeries "name $name" "geom $width $height";

	set Item(IDs)		{};
	set Item(selectedIDs)	{};
	set Group(names)	{};
}

proc RefreshSeries {args} {
	global	Obj;

	foreach att $args {
		set att_name [lindex $att 0];
		set att_val [lrange $att 1 end];
		set Obj(series.$att_name) $att_val;
		switch $att_name {
		  size {
			set Obj(series.width)	[lindex $att_val 0];
			set Obj(series.height)	[lindex $att_val 1];
			.series config -width $Obj(series.width) \
			  -height $Obj(series.height);
		  }
		  name {
			set Obj(series.name) [lindex $att 1];
			ChangeTitle;
		  }
		}
	}
}

proc Quit {} {
	Debug "Quit GA";
	destroy .;
	exit;
}


#-----------------------------------------------------------------------
proc OpenItem {type ID args} {
	global	Obj OpenProc Item;

	Att::Reset $ID;

	set Obj($ID.ID)	$ID;
	set Obj($ID.type) $type;

	set geom [eval Att::LSearch geom $args];
	if {"$geom" != ""} {
		eval $OpenProc($type) $ID $geom $args;
		lappend Item(IDs) $ID;
		Debug "OpenItem: opened items are... $Item(IDs)";

		return $ID
	} else {
		Warning "OpenItem - geometry undefined";

		return "";
	}
}

proc CloseItem {args} {
	global	Obj Group Item;

	if {"$args" == "all"} {
		set args $Item(IDs);
	}

	foreach ID $args {
		set idx [lsearch $Item(IDs) $ID];
		if {$idx == -1} continue;

		#--- remove the CANVAS item
		.series delete item$ID;
		switch $Obj($ID.type) {
		  button - checkbutton - field {
			#--- remove the widget
			destroy .series.item$ID;
		  }
		  radiobutton {
			destroy .series.item$ID;
			set grp $Obj($ID.group);
			if {[lsearch $Group(names) $grp] != -1} {
				set idx [lsearch $Group($grp.IDs) $ID];
				set Group($grp.IDs) \
				  [lreplace $Group($grp.IDs) $idx $idx];
			}
		  }
		}

		set Item(IDs) [lreplace $Item(IDs) $idx $idx];
	}

	Debug "CloseItem: opened items are... $Item(IDs)";
}

proc RefreshItem {ID args} {
	global	Obj RefreshProc;

	eval {$RefreshProc($Obj($ID.type)) $ID} $args;
}


#-----------------------------------------------------------------------
proc SelectRadiobutton {ID} {
	global	Obj Group;

	set Group($Obj($ID.group).pushed) $ID;
	set Group($Obj($ID.group).selected) $ID;
}

proc DeSelectRadiobutton {ID} {
	global	Obj Group;

	if {$Group($Obj($ID.group).selected) == $ID} {
		set Group($Obj($ID.group).pushed) 0;
		set Group($Obj($ID.group).selected) 0;
	}
}

proc SelectCheckbutton {ID} {
	global	Obj;

	if {$Obj($ID.select) == 0} {
		.series.item$ID select;
		set Obj($ID.select) 1;
	}
}

proc DeSelectCheckbutton {ID} {
	global	Obj;

	if {$Obj($ID.select) != 0} {
		.series.item$ID deselect;
		set Obj($ID.select) 0;
	}
}

proc GetField {ID} {
	global	Obj Win;

	set win $Win($Obj($ID.citem).path);
	set text [$win get];
	SendOZ "{FieldTextChanged $ID \"$text\"}";
}


#-----------------------------------------------------------------------
proc OpenButton {ID x y args} {
	eval Open_Button button $ID $x $y $args;
	return $ID;
}

proc OpenCheckbutton {ID x y args} {
	eval Open_Button checkbutton $ID $x $y $args;
	return $ID;
}

proc OpenRadiobutton {ID x y args} {
	eval Open_Button radiobutton $ID $x $y $args;
	return $ID;
}

proc Open_Button {type ID x y args} {
	global	Obj Win;

	set rv [catch {eval $type .series.item$ID} btn];
	if {$rv == 1} {
		Debug "Open_Button - widget creation error ($btn)";
		return "";
	}

	$btn config -bd 1 -command "ButtonB1Press $ID";

	set cid [.series create window $x $y -window $btn -anchor nw];
	set Obj($ID.citem)	$cid;
	set Win($cid.path)	$btn;
	set Win($cid.ID)	$ID;

	.series addtag item	withtag $cid;
	.series addtag item$ID	withtag $cid;
	.series addtag $type	withtag $cid;

	eval RefreshWidget $ID $args;
	Att::CorrectSize $ID;

	return $ID;
}

proc OpenField {ID x y args} {
	global	Obj Win;

	set ent [eval {entry .series.item$ID -relief sunken -bd 1}];
	bind $ent <ButtonRelease-1> "+ FieldB1Press $ID";
	bind $ent <Return> "+ FieldReturnPress $ID";

	set cid [.series create window $x $y -window $ent -anchor nw];
	set Obj($ID.citem)	$cid;
	set Win($cid.path)	$ent;
	set Win($cid.ID)	$ID;

	.series addtag item	withtag $cid;
	.series addtag item$ID	withtag $cid;
	.series addtag field	withtag $cid;

	eval RefreshWidget $ID $args;
	Att::CorrectSize $ID;

	return $ID;
}

proc OpenString {ID x y args} {
	global	Obj Win;

	set cid [.series create text $x $y -anchor nw];
	.series bind $cid <ButtonPress-1> "CItemB1Press $ID";

	set Obj($ID.citem)	$cid;
	set Win($cid.ID)	$ID;

	.series addtag item	withtag $cid;
	.series addtag item$ID	withtag $cid;
	.series addtag string	withtag $cid;

	eval RefreshCItem $ID $args;

	return $ID;
}

#-----------------------------------------------------------------------
proc RefreshWidget {ID args} {
	global	Obj Win Group;

	set cid $Obj($ID.citem);
	set win $Win($cid.path);

	foreach att $args {
		set att_type	[lindex $att 0];
		set att_val	[lrange $att 1 end];
#		Debug "refresh $att_type = $att_val";
		set Obj($ID.$att_type) "$att_val";

		switch $att_type {
		  geom {
			set Obj($ID.coordx) [lindex $att_val 0];
			set Obj($ID.coordy) [lindex $att_val 1];
			eval .series coords $cid $att_val;
		  }
		  size {
			set Obj($ID.width)  [lindex $att_val 0];
			set Obj($ID.height) [lindex $att_val 1];
			.series itemconfigure $cid \
			  -width $Obj($ID.width) -height $Obj($ID.height);
		  }
		  name {
			set Obj($ID.$att_type) [lindex $att 1];
		  }
		  label {
			set Obj($ID.$att_type) [lindex $att 1];
			eval $win config -text "$att_val";
		  }
		  state {
			$win config -state $att_val;
			if {"$Obj($ID.type)" == "field" && 
			    "$att_val" == "normal"} {
				#--- The text might be changed while
				#    the state was disabled.
				$win delete 0 end;
				eval $win insert 0 $Obj($ID.text);
			}
		  }
		  color {
			#--- {color (bg|fg|activebg|activebg)color {r g b}}
			set att_type [lindex $att_val 0];
			set rgb  [lindex $att_val 1];
			set Obj($ID.$att_type) [eval Color::Deci2Str $rgb];
			if {"$Obj($ID.$att_type)" != ""} {
				set Obj($ID.$att_type.r) [lindex $rgb 0];
				set Obj($ID.$att_type.g) [lindex $rgb 1];
				set Obj($ID.$att_type.b) [lindex $rgb 2];
				if {"$att_type" == "bgcolor"} {
					set att_opt bg;
				} elseif {"$att_type" == "fgcolor"} {
					set att_opt fg;
				} elseif {"$att_type" == "activebgcolor"} {
					set att_opt activebackground;
				} else {
					set att_opt activeforeground;
				}
				$win config -$att_opt $Obj($ID.$att_type);
			}
		  }

		  #--- checkbutton & radiobutton
		  select {
			if {"$Obj($ID.type)" == "checkbutton" &&
			    $att_val != 0} {
				$win select;
			} elseif {"$Obj($ID.type)" == "radiobutton" &&
			    $att_val != 0} {
				set group $Obj($ID.group);
				if {"$group" != ""} {
					set Group($group.pushed) $ID;
					set Group($group.selected) $ID;
				}
			}
		  }

		  #--- radiobutton
		  group {
			if {[lsearch $Group(names) $att_val] == -1} {
				lappend Group(names) $att_val;
				set Group($att_val.IDs) {};
				set Group($att_val.selected) "";
				set Group($att_val.pushed) "";
			}
			if {[lsearch $Group($att_val.IDs) $ID] == -1} {
				lappend Group($att_val.IDs) $ID;
			}
			$win config -value $ID \
			  -variable Group($att_val.pushed);
			if {$Obj($ID.select) != 0} {
				set Group($att_val.pushed) $ID;
				set Group($att_val.selected) $ID;
			}
		  }

		  #--- filed
		  text {
			set Obj($ID.$att_type) [lindex $att 1];
			if {"$Obj($ID.type)" == "field"} {
				$win delete 0 end;
				eval $win insert 0 $att_val;
			}
		  }
		}
	}

	Att::CorrectWidgetDefaultAtt $ID;

	return $ID;
}

proc RefreshCItem {ID args} {
	global	Obj;

	set cid $Obj($ID.citem);

	foreach att $args {
		set att_type	[lindex $att 0];
		set att_val	[lrange $att 1 end];
#		Debug "$att_type = $att_val";
		set Obj($ID.$att_type) "$att_val";
		switch $att_type {
		  geom {
			set Obj($ID.coordx) [lindex $att_val 0];
			set Obj($ID.coordy) [lindex $att_val 1];
			eval .series coords $cid $att_val;
		  }
		  color {
			#--- {color (bg|fg|activebg|activebg)color {r g b}}
			set att_type [lindex $att_val 0];
			set rgb  [lindex $att_val 1];
			set Obj($ID.$att_type) [eval Color::Deci2Str $rgb];
			if {"$Obj($ID.$att_type)" != ""} {
				set Obj($ID.$att_type.r) [lindex $rgb 0];
				set Obj($ID.$att_type.g) [lindex $rgb 1];
				set Obj($ID.$att_type.b) [lindex $rgb 2];
				if {"$att_type" == "bgcolor"} {
					set att_opt bg;
				} elseif {"$att_type" == "fgcolor"} {
					set att_opt fg;
				} elseif {"$att_type" == "activebgcolor"} {
					set att_opt activebackground;
				} else {
					set att_opt activeforeground;
				}
				.series itemconfigure $cid -fill $Obj($ID.$att_type);
			}
		  }

		  text - width - justify {
			set Obj($ID.$att_type) [lindex $att 1];
			eval .series itemconfigure $cid -$att_type "$att_val";
		  }
		}
	}

	Att::CorrectCItemDefaultAtt $ID;

	return $ID;
}


#-----------------------------------------------------------------------
#	compute width and height
proc Att::CorrectSize {ID} {
	global	Obj Win;

	if {$Obj($ID.size) == ""} {
		set coords [.series bbox $Obj($ID.citem)];
		if {"$coords" == ""} {
			Warning "Att::CorrectSize - no such Item (ID=$ID)";
			return "";
		}

		set Obj($ID.width) \
		  [expr [lindex $coords 2] - [lindex $coords 0]];
		set Obj($ID.height) \
		  [expr [lindex $coords 3] - [lindex $coords 1]];
	}
}

proc Att::CorrectCItemDefaultAtt {ID} {
	global	Obj Win;

	if {"$Obj($ID.type)" != "string"} {
		Warning "Att::CorrectCItemDefaultAtt - invalid type";
		return;
	}
	set cid $Obj($ID.citem);

	if {"$Obj($ID.fgcolor)" == ""} {
		set Obj($ID.fgcolor) [lindex [.series itemconfig $cid -fill] 4];
	}
}

proc Att::CorrectWidgetDefaultAtt {ID} {
	global	Obj Win;

	set cid $Obj($ID.citem);
	set win $Win($cid.path);

	switch $Obj($ID.type) {
	  button - checkbutton - radiobutton {
		set col_atts {bgcolor fgcolor activebgcolor activefgcolor};
	  }
	  field {
		set col_atts {bgcolor fgcolor};
	  }
	  default {
		Warning "Att::CorrectWidgetDefaultAtt - unknown type (ID=$ID)";
		return;
	  }
	}
	foreach att $col_atts {
		if {"$Obj($ID.$att)" == ""} {
			if {"$att" == "bgcolor"} {
				set att_opt bg;
			} elseif {"$att" == "fgcolor"} {
				set att_opt fg;
			} elseif {"$att" == "activebgcolor"} {
				set att_opt activebackground;
			} else {
				set att_opt activeforeground;
			}
			set Obj($ID.$att) [lindex [$win config -$att_opt] 4];
			if {[regexp #.* Obj($ID.$att)]} {
				set rgb [Color::Str2Deci $Obj($ID.$att)];
			} else {
				set rgb [Color::Name2Deci $Obj($ID.$att)]
			}
			if {"$rgb" == ""} {
				Warning "Att::CorrectWidgetDefaultAtt - $att";
				set rgb "0 0 0";
			}
			set Obj($ID.$att.r) [lindex $rgb 0];
			set Obj($ID.$att.g) [lindex $rgb 1];
			set Obj($ID.$att.b) [lindex $rgb 2];
		}
	}

	if {"$Obj($ID.type)" == "radiobutton" && "$Obj($ID.group)" == ""} {
		$win config -variable $ID;
		$win config -value $ID;
	}
}

proc Att::Reset {ID} {
	global	Obj Att;

	foreach att $Att(all) {
		switch $att {
		  ID - coordx - coordy - width - height - fontsize - select {
			set Obj($ID.$att) 0;
		  }

		  type - name - geom - size - label - text - value - group -
		  font {
			set Obj($ID.$att) "";
		  }

		  fgcolor - bgcolor - activebgcolor - activefgcolor {
			set Obj($ID.$att) "";
			set Obj($ID.$att.r) 0;
			set Obj($ID.$att.g) 0;
			set Obj($ID.$att.b) 0;
		  }

		  state {set Obj($ID.state) normal;}
		  justify {set Obj($ID.justify) left;}
		}
	}
}

proc Att::Delete {ID} {
	global	Obj Att;

	foreach att $Att(all) {
		unset Obj($ID.$att);
	}
}

proc Att::Copy {ID copyID} {
	global	Obj Att;

	foreach att $Att(all) {
		set Obj($copyID.$att) $Obj($ID.$att);
		switch $att {
		  fgcolor - bgcolor - activefgcolor - activebgcolor {
			set Obj($copyID.$att.r) $Obj($ID.$att.r);
			set Obj($copyID.$att.g) $Obj($ID.$att.g);
			set Obj($copyID.$att.b) $Obj($ID.$att.b);
		  }
		}
	}
}

proc Att::LSearch {name args} {
	set val "";
	foreach att $args {
		set att_name [lindex $att 0];
		if {"$att_name" == "$name"} {
			set val [lrange $att 1 end];
		}
	}

	return "$val";
}

proc Att::IsStr {att} {
	switch $att {
	  name - label - text {return 1;}
	  default {return 0;}
	}
}


#	Color Handling:		using 8 bits color model
#-----------------------------------------------------------------------
proc Color::Deci2Str {r g b} {

	set hex [Color::Deci2Hex $r $g $b];
	if {"$hex" != ""} {
		return "[lindex $hex 0][lindex $hex 1][lindex $hex 2]";
	} else {
		return "";
	}
}

proc Color::Str2Deci {str} {
	set hex_str [string range $str 1 end];
	if {"[string index $str 0]" != "#" ||
	    [string length $hex_str] < 3 ||
	    [expr [string length $hex_str] % 3] != 0} {
		Warning "Color::Str2Deci - invalid color string ($str)";
		return "";
	}
	set len [expr [string length $hex_str] / 3];
	set r [string range $hex_str 0 [expr $len - 1]];
	set g [string range $hex_str $len [expr $len * 2 - 1]];
	set b [string range $hex_str [expr $len * 2] end];

	return [Color::Hex2Deci $r $g $b];
}

proc Color::Name2Deci {name} {
	set hex [Color::Name2Hex $name];
	if {"$hex" == ""} {
#		Warning "Color::Name2Deci - invalid color name ($name)";
		return "";
	}
	return [eval Color::Hex2Deci $hex];
}

proc Color::Deci2Hex {r g b} {

	set hex "";
	if {$r < 0 || $r > 100 || $g < 0 || $g > 100 || $b < 0 || $b > 100} {
		Warning "invalid color value ($r $g $b)";
		return $hex;
	}

	set r [expr $r * 255 / 100];
	set g [expr $g * 255 / 100];
	set b [expr $b * 255 / 100];
	set rv [catch {set hex [format "#%02X%02X%02X" $r $g $b]} msg];
	if {$rv == 1} {
		Warning "Color::RGB2Hex - $msg";
		set hex "";
	}

	return $hex;
}

proc Color::Hex2Deci {r g b} {

	set rv_r [catch {set r [format "%d" 0x$r]} msg_r];
	set rv_g [catch {set g [format "%d" 0x$g]} msg_g];
	set rv_b [catch {set b [format "%d" 0x$b]} msg_b];
	if {$rv_r == 1 || $rv_g == 1 || $rv_b == 1} {
		Warning "Color::Hex2Deci - $msg_r, $msg_g, $msg_b";
		return "";
	}

	while {$r > 255 || $g > 255 || $b > 255} {
		set r [expr $r >> 4];
		set g [expr $g >> 4];
		set b [expr $b >> 4];
	}

	set r [expr $r * 100 / 255];
	set g [expr $g * 100 / 255];
	set b [expr $b * 100 / 255];

	return "$r $g $b";
}

proc Color::Name2Hex {name} {

	set rv [catch {set rgb [winfo rgb . $name]} msg];
	if {$rv == 1} {
		Warning "Color::Name2Hex - $msg";
		return "";
	}

	set r [lindex $rgb 0];
	set g [lindex $rgb 1];
	set b [lindex $rgb 2];
	while {$r > 255 || $g > 255 || $b > 255} {
		set r [expr $r >> 4];
		set g [expr $g >> 4];
		set b [expr $b >> 4];
	}

	set r [format "%02X" $r];
	set g [format "%02X" $g];
	set b [format "%02X" $b];

	return "$r $g $b";
}


########################################################################
###
###		Event Handling
###
########################################################################

proc ButtonB1Press {ID} {
	global	Frame Obj Group;

	switch $Frame(tool.selected) {
	  browse {
		ButtonBrowseEvent $ID;
	  }
	  item_info - item_delete {
		switch $Obj($ID.type) {
		  checkbutton {
			.series.item$ID toggle;
		  }
		  radiobutton {
			set grp $Obj($ID.group);
			set Group($grp.pushed) $Group($grp.selected);
		  }
		}
		if {"$Frame(tool.selected)" == "item_info"} {
			Tool::Select browse;
			Mutate::ConfigItem $ID;
		} else {
			Tool::Select browse;
			Mutate::DeleteItem $ID;
		}
	  }
	}
}

proc ButtonBrowseEvent {ID} {
	global	Obj Group;

	switch $Obj($ID.type) {
	  button {
		SendOZ "{ButtonMouseUp $ID}";
	  }
	  checkbutton {
		if {$Obj($ID.select) == 0} {
			set Obj($ID.select) 1;
			SendOZ "{CheckButton On $ID}";
		} else {
			set Obj($ID.select) 0;
			SendOZ "{CheckButton Off $ID}";
		}
	  }
	  radiobutton {
		set Group($Obj($ID.group).selected) $ID;
		SendOZ "{RadioButtonSelected $ID}"
	  }
	}
}

proc FieldB1Press {ID} {
	global	Frame Obj Win;

	switch $Frame(tool.selected) {
	  browse {
		#--- do nothing
	  }
	  item_info - item_delete {
		focus none;
		$Win($Obj($ID.citem).path) select clear;
		if {"$Frame(tool.selected)" == "item_info"} {
			Tool::Select browse;
			Mutate::ConfigItem $ID;
		} else {
			Tool::Select browse;
			Mutate::DeleteItem $ID;
		}
	  }
	}
}

proc FieldReturnPress {ID} {
	global	Obj Win;

	set text [$Win($Obj($ID.citem).path) get];
	SendOZ "{FieldTextChanged $ID \"$text\"}";

#	if {"$text" != "$Obj($ID.text)"} {
#		SendOZ "{FieldTextChanged $ID \"$text\"}";
#	}

	focus none;
}

proc CItemB1Press {ID} {
	global	Frame;

	switch $Frame(tool.selected) {
	  browse {
		#--- Do nothing
	  }
	  item_info {
		Tool::Select browse;
		Mutate::ConfigItem $ID;
	  }
	  item_delete {
		Tool::Select browse;
		Mutate::DeleteItem $ID;
	  }
	}
}


########################################################################
###
###		Menu
###
########################################################################

proc Menu::Init {{w .menubar}} {
	global	Menu;

	frame $w;
	set Menu(menubar) $w;
	set Menu(ID) 0;

	return $w;
}

proc Menu::Create {label} {
	global	Menu;

	if [info exists Menu(menu,$label)] {
		Warning "Menu::Create - Menu $label already defined";
		return;
	}
	set name $Menu(menubar).mb$Menu(ID);
	set menu_name $name.menu;
	incr Menu(ID);
	set mb [menubutton $name -text $label -menu $menu_name -bd 1];
	pack $mb -side left -padx 4;
	set menu [menu $menu_name -bd 1];
    
	# Remember the widget name under a variable derived from the label.
	# This allows mxMenuBind to be passed the label instead of the widget.
	set Menu(menu,$label) $menu;

	return $menu;
}

proc Menu::AddCommandEntry {menu_name label command} {
	global	Menu;

	if [catch {set Menu(menu,$menu_name)} menu] {
		Warning "Menu::AddCommandEntry - No such menu: $menu_name";
		return;
	}
	$menu add command -label $label -command $command;
}

proc Menu::AddSeparator {menu_name} {
	global	Menu;

	if [catch {set Menu(menu,$menu_name)} menu] {
		error "Menu::AddSeparator - No such menu: $menu_name";
		return;
	}
	$menu add separator;
}


########################################################################
###
###		Frame Fundamental part
###
########################################################################

#-----------------------------------------------------------------------
proc Core::Start {} {
	global	Frame Series Obj;

	#--- window title
	wm title . "OZ++/Frame(GA:$Frame(GA_version)):";
	wm protocol . WM_DELETE_WINDOW {SendOZ "{Quit}";};
#	trace variable Obj(series.name) w "ChangeTitleXXX"

	#--- Menu
	set menu [Menu::Init];
	Menu::Create Frame;
	Menu::AddCommandEntry Frame Quit {Core::Quit};

	#--- Tool
	Tool::Select browse;

	#--- Series
	set series [InitSeries];

	#--- packing the top levels
	pack $menu -side top -fill x;
	pack $series -fill both;
}

proc Core::Quit {} {
	set result [tk_dialog .quit "Quit Frame" \
	  "Do you really want to quit ?" question 0 {Quit} {Cancel}];
	if {$result == 0} {
		SendOZ "{Quit}";
		destroy .;
		exit;
	}
}


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


#-----------------------------------------------------------------------
proc InitSeries {} {
	global	Frame Series Obj Item Group;

	set Obj(series.name)	"";
	set Obj(series.width)	512;
	set Obj(series.height)	342;
	set series [canvas .series \
	  -width $Obj(series.width) -height $Obj(series.height) \
	  -bg white -relief ridge];
	bind .series <Double-ButtonPress-1> \
	  "Tool::Select browse; focus none";

	set Item(IDs)		{};
	set Item(selectedIDs)	{};
	set Group(names)	{};

	return $series;
}

#	var_name index op = pseudo parameters set by TRACE
#-----------------------------------------------------------------------
proc ChangeTitleXXX {var_name index op} {
	global	Frame Obj;

	wm title . "OZ++/Frame(GA:$Frame(GA_version)): $Obj(series.name)";
}

proc ChangeTitle {} {
	global	Frame Obj;

	wm title . "OZ++/Frame(GA:$Frame(GA_version)): $Obj(series.name)";
}


#	args = widgets
#-----------------------------------------------------------------------
proc ChangeCursor {csr args} {
	foreach w $args {
		catch {$w config -cursor $csr};
	}
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


########################################################################
###
###	Start Up
###
########################################################################

Core::Start;


# EoF
