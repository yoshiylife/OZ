#!/usr/local/bin/wish -f
#
#  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	Class Object Activity Indicator
#
#		Ver. 2.1 "GuruGuru"
#
#		Akihito NAKAMURA <akihito@etl.go.jp>
#
#	Notice!  We assume "wish" with "addinput" facility.
######################################################################

### OZ++ GUI colors
global	oz_color_bg oz_color_bg_list oz_color_fg_list
set	oz_color_bg		lightyellow
set	oz_color_bg_list	lavenderblush1
set	oz_color_fg_list	honeydew


##  Global variables
##
global  ai_state;		#  ACTIVE or IDLE
global  ai_blink_interval;	# in milliseconds
global  ai_num_IDs
global  ai_h_width ai_h_height;	# in #chars
global  kuru_width kuru_height;	# in pixcel
global  center_x center_y loc1 loc2
global  radius1
global  num_tick tick_curr
global  plus1 plus2
global  tick_interval;	# in milliseconds

## Initial values
##
set ai_state		IDLE
set ai_blink_interval	100
set tick_interval	20
set ai_num_IDs		0

set ai_h_width		39
set ai_h_height		3

set kuru_width	120
set kuru_height	120
set radius1	32
set radius2	50
set pai		3.1415927
set num_tick	40
set tick_curr	0

set font_ascii -adobe-times-medium-r-normal--20-140-100-100-p-96-iso8859-1
set font_ascii_l -adobe-times-medium-r-normal--34-240-100-100-p-170-iso8859-1


##
##	guru {}
######################################################################
proc guru {} {
	global tick_curr num_tick loc1 loc2 plus1 plus2

#	puts stderr "DEBUG: guru $tick_curr"

	set tick_old $tick_curr
	incr tick_curr
	if {$tick_curr == $num_tick} {
		set tick_curr 0
	}

	.kuru.animation move $plus1 \
	  [expr $loc1(x,$tick_curr) - $loc1(x,$tick_old)] \
	  [expr $loc1(y,$tick_curr) - $loc1(y,$tick_old)]
	.kuru.animation move $plus2 \
	  [expr $loc2(x,$tick_curr) - $loc2(x,$tick_old)] \
	  [expr $loc2(y,$tick_curr) - $loc2(y,$tick_old)]
}

##
##	guruguru {}
######################################################################
proc guruguru {} {
	global num_tick loc1 loc2 plus1 plus2 tick_interval

#	puts stderr "DEBUG: guruguru"

	for {set i 0} {$i < $num_tick} {incr i} {
		guru
		update
		if {$tick_interval > 0} {
			after $tick_interval
		}
	}
}


######################################################################
proc guruguruWithBlink {} {
	global  ai_state ai_blink_interval

	if {"$ai_state" == "ACTIVE"} {
		guruguru
	}

	after $ai_blink_interval guruguruWithBlink
}


##
##	getCmdFromClassObject  --- Reading the commands from stdin.
######################################################################
proc getCmdFromClassObject {token file_id events hBox} {
	global	ai_state ai_num_IDs ai_h_height

	if {"$events" != "READ"} {
		error "Unexpected events: $events, going to shutdown..."
		aiQuit

	} else {
		if {[gets stdin line] < 0} {
			removeinput stdin
#			puts stderr "Read EOF, going to shutdown..."
			aiQuit
		}

		if {$line == "mawaru"} {
			set ai_state ACTIVE
#			puts stderr "DEBUG: state = ACTIVE"

		} elseif {$line == "tomaru"} {
			set ai_state IDLE
#			puts stderr "DEBUG: state = IDLE"
			set tmp_line [$hBox get end]
			set tmp_line "$tmp_line done"
			$hBox delete end
			$hBox insert end $tmp_line
			$hBox select clear

		} elseif {$line == "quit"} {
			aiQuit

		} elseif {[string first "ID " $line] == 0} {
			if {$ai_num_IDs < $ai_h_height} {
				incr ai_num_IDs
			} else {
				$hBox delete 0
			}

			set id [string range $line 3 end]
			$hBox insert end \
			  "Transferring $id ..."
			$hBox select from end
		}
	}
}


##
##	Quit normaly
######################################################################
proc aiQuit {} {
#	puts stdout "@q"
#	flush stdout
	destroy .
}


######################################################################
#
#  main
#
######################################################################


##
##  Main Window
##
######################################################################

wm title . "OZ++ Class"
. configure -bg black


##
##  Animation Window
#######################################################################
frame  .kuru -bg black;	#$oz_color_bg

canvas .kuru.animation \
  -width ${kuru_width} -height ${kuru_height} \
  -bg black
pack   .kuru.animation

set center_x [expr $kuru_width  / 2]
set center_y [expr $kuru_height / 2]

set tic [expr $pai * 2 / $num_tick]
for {set i 0} {$i < $num_tick} {incr i} {
	set radian [expr $tic * $i]
	set loc1(x,$i) [expr cos([expr $radian * 2]) * $radius1 + $center_x]
	set loc1(y,$i) [expr sin([expr $radian * 2]) * $radius1 + $center_y]

	set loc2(x,$i) [expr cos($radian) * $radius2 + $center_x]
	set loc2(y,$i) [expr sin($radian) * $radius2 + $center_y]

#	puts stderr "DEBUG: $i ($loc1(x,$i),$loc1(y,$i))"
#	puts stderr "DEBUG: $i ($loc2(x,$i),$loc2(y,$i))"
}

#.kuru.animation create text $center_x $center_y \
#  -text O -font $font_ascii_l -anchor center -fill deepskyblue1
#.kuru.animation create text $center_x [expr $center_y - 2] \
#  -text z -font $font_ascii -anchor center -fill green
.kuru.animation create text $center_x $center_y \
  -text OZ -font $font_ascii_l -anchor center -fill green

set plus1 [.kuru.animation create text \
  $loc1(x,$tick_curr) $loc1(y,$tick_curr) \
  -text "+" -font $font_ascii_l -anchor center -fill yellow]
set plus2 [.kuru.animation create text \
  $loc2(x,$tick_curr) $loc2(y,$tick_curr) \
  -text "+" -font $font_ascii_l -anchor center -fill red]


##
##	Class transmission History Box
######################################################################
frame .historyBox \
  -borderwidth 10 -bg black;	#$oz_color_bg

listbox .historyBox.list \
  -relief sunken \
  -geometry ${ai_h_width}x${ai_h_height} \
  -bg $oz_color_bg

pack .historyBox.list \
  -side left -fill y


###
###	Allocation of the widgets
######################################################################
pack .kuru       -side top -fill x
pack .historyBox -side bottom;# -fill x


##
##	Main Procedure
######################################################################


guruguruWithBlink
#puts stderr "DEBUG: running Activity Indicator in background..."

#update

# getCmdFromClassObject
addinput stdin "getCmdFromClassObject %% %F %E .historyBox.list"
#puts stderr "DEBUG: Setting Asynchronous I/O mode on \"stdin\""


#
# EoF
#
