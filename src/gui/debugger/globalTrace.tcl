#
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#	Global access trace
#
proc	globalTrace { w oid } {

	catch { destroy $w }
	toplevel $w
	wm title $w "Global Access Trace $oid"
	wm iconname $w "G-Trace"
	#wm geometry $w +0+0
	#wm minsize $w 460 280
	#wm maxsize $w 460 [winfo screenheight $w]

	frame $w.ribon -background LightYellow2
	frame $w.text -background LightYellow2

	set dm [unix_gstep $oid]

	button $w.ribon.clear \
		-background LightYellow2 -activebackground SkyBlue1 \
		-text Clear \
		-command "globalTrace_Clear $w"
	button $w.ribon.step \
		-background LightYellow2 -activebackground SkyBlue1 \
		-text Step \
		-command "globalTrace_Step $w $dm"
	button $w.ribon.inspect \
		-background LightYellow2 -activebackground SkyBlue1 \
		-text Inspect \
		-command "globalTrace_Inspect $w"
	button $w.ribon.close \
		-background LightYellow2 -activebackground SkyBlue1 \
		-text Close \
		-command "globalTrace_Close $w $dm"
	pack $w.ribon.clear $w.ribon.step $w.ribon.inspect -side left -fill x
	pack $w.ribon.close -side right -fill x


	frame $w.trace -background LightYellow2
	text $w.trace.text -background LightYellow2 -selectbackground SkyBlue1 \
		-relief raised \
		-font "-misc-fixed-*-*-*-*-14-*-*-*-*-*-*-*" \
		-height 25 -width 80\
		-yscrollcommand "$w.trace.scroll set"
	scrollbar $w.trace.scroll -foreground LightYellow2 -activeforeground SkyBlue1 \
		 -relief sunken \
		-command "$w.trace.text yview"
	pack $w.trace.text -side left -fill both -expand yes
	pack $w.trace.scroll -side right -fill y -expand yes

	pack $w.ribon -side top -fill x
	pack $w.trace -side top -fill x

}


proc	globalTrace_Clear { w } {
	$w.trace.text delete 0.0 end
}

proc	globalTrace_Inspect { w } {
}

proc	globalTrace_Step { w dm } {
	catch {
		puts $dm "\n"
		flush $dm
		while { [gets $dm data] > 0 } {
			set data [lindex $data 0]
			if { $data == "!CMD>>" } { break }
			if { [lindex $data 0] == "Class:" } {
				set class_name [exec sb [lindex $data 1]]
				set method_name [exec cb2 $class_name public "#[lindex $data 5]"]
			} else {
				set method_name ""
			}
			if { [lindex $data 0] != "None" } {
				$w.trace.text insert end "$data $method_name\n"
			}
		}
		after 2000 globalTrace_Step $w $dm
		$w.trace.text yview end
	}
}

proc	globalTrace_Close { w dm } {
	unix_dmclose $dm
	destroy $w
}

proc	globalTrace_Scroll { w num } {
	$w yview $num
}
