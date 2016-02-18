#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	Not yes implement
#
proc	buildupNow { w id } {
	catch { destroy $w }
	toplevel $w
	wm title $w "Buildup Now $id"
	wm iconname $w "Buildup Now"
#	wm geometry $w +0+0
#	wm minsize $w 1 1
#	wm maxsize $w 695 [winfo screenheight $w]
	frame $w.ribon
	frame $w.message
	button $w.ribon.close -text Close \
		-command "destroy $w"
	label $w.message.1 -text "Now, buildup ... target: $id"
	label $w.message.2 -text "Wait a few days !!"
	pack $w.ribon.close -side right -fill x
	pack $w.ribon $w.message.1 $w.message.2 -side top -fill x
	pack $w.message -side top -fill both
}

