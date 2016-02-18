wm title . UnixShell ;
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
frame .cmd -bd 1 -relief raise ;
button .cmd.quit -text Quit -command "exit 0" ;
entry .cmd.entry -relief sunken -bd 1 ;
pack .cmd -side bottom -fill both -expand yes ;
pack .cmd.entry -side left -fill x -expand yes ;
pack .cmd.quit -side right -padx 5 ;
frame .main -bd 1 -relief raise ;
pack .main -side top ;
scrollbar .main.sbar -bd 1 -relief sunken \
	-command { .main.text yview } ;
text .main.text -width 80 -height 20 -bd 1 -relief sunken \
	-yscroll { .main.sbar set } -cursor hand2 ;
pack .main.text -side left ;
pack .main.sbar -side right -fill y ;
proc Loop { } { \
	set data [gets stdin] ;
	.main.text insert end "$data\n" ;
	.main.text yview -pickplace end ;
}
proc DoCur { f } { \
	set data [$f get ] ;
	puts stdout "$data" ;
	flush stdout ;
	.main.text insert end "$data\n" ;
	.main.text yview -pickplace end ;
	$f delete 0 end ;
}
proc DoSel { f } { \
	set data "" ;
	catch { set data [selection get] } ;
	if { $data == "" } return ;
	set index [string first "\n" $data] ;
	if { $index < 0 } {
		$f insert end "$data" ;
	} elseif { $index > 0 } {
		set data [string range $data 0 [expr $index-1]] ;
		$f insert end "$data" ;
		DoCur $f ;
	}
}
#bind .main.text <Return> { \
#	puts stdout [%W get "end linestart" "end lineend"] ;
#	flush stdout ;
#	%W insert end \n ;
#	.main.text yview -pickplace end ;
#}
bind .main.text <Any-KeyPress> { }
bind .main.text <FocusIn> { \
	focus .cmd.entry ;
}
bind .main.text <Enter> { \
	focus .cmd.entry ;
}
bind .main.text <Button-2> { \
	DoSel .cmd.entry ;
	selection clear %W ;
}
bind .cmd.entry <Return> { \
	DoCur %W ;
}
bind .cmd.entry <Enter> { \
	focus %W ;
}
bind .cmd.entry <Button-2> { \
	DoSel %W ;
}
focus default .cmd.entry ;
addinput stdin Loop ;
