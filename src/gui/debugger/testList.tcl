#! /usr/local/tcl7.3/bin/wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#

proc	testList { { pathName .t1 } } {
	catch { destroy $pathName }
	toplevel $pathName
	wm title $pathName "Test"
	wm iconname $pathName "Test"
	wm minsize $pathName 1 1
	frame $pathName.ribon -background LightYellow2
	frame $pathName.list -background LightYellow2

	button $pathName.ribon.close -background LightYellow2 -activebackground SkyBlue1 \
		-text "Close" -command "destroy $pathName"

	listbox $pathName.list.list -relief raised \
			-yscroll "$pathName.list.scroll set" \
			-geometry 10x10 \
			-background LightYellow2 -selectbackground SkyBlue1

	scrollbar $pathName.list.scroll -relief sunken \
		-foreground LightYellow2 -activeforeground SkyBlue1 \
		-command "$pathName.list.list yview"

	pack $pathName.ribon.close -side right
	pack $pathName.list.list -expand yes -side left -fill y
	pack $pathName.list.scroll -expand yes -side right -fill y

	pack $pathName.ribon -side top -fill x
	pack $pathName.list -expand yes -side top -fill y

	set fd [open "|objlist 7" r]
	gets $fd data
	$pathName.list.list insert end $data

}
