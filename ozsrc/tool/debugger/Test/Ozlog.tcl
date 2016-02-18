wm title . ozlog ;
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
button .quit -text Quit -command "exit 0" ;
pack .quit -side bottom -fill x ;
frame .main -bd 1 -relief raise ;
pack .main -side top -fill both -expand yes ;
scrollbar .main.sbar -bd 1 -relief sunken \
	-command { .main.text yview } ;
text .main.text -width 80 -height 20 -bd 1 -relief sunken \
	-yscroll { .main.sbar set } ;
pack .main.text -side left -fill both -expand yes ;
pack .main.sbar -side right -fill y ;
proc Loop { } { \
	set data [gets stdin] ;
	.main.text insert end "$data\n" ;
	.main.text yview -pickplace end ;
}
#bind .main.text <Return> { \
#	puts stdout [%W get "end linestart" "end lineend"] ;
#	flush stdout ;
#	%W insert end \n ;
#	.main.text yview -pickplace end ;
#}
#bind .main.text <Enter> { \
#	focus %W ;
#}
#bind .main.text <Button-2> {
#	%W insert end [selection get] 
#}
#.main.text configure -stat disabled ;
wm minsize . [winfo width .] [winfo height .] ;
wm maxsize . [winfo screenwidth .] [winfo screenheight .] ;
addinput stdin Loop ;

