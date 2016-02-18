#	<<<  Junkshop  >>>
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#
#
#	Junkshop Tool GUI
#


#--- Loading misc. procedures
source $env(OZROOT)/lib/gui/frame2/misc.tcl;


set JST(version)  0.9;
set JST(lockset)  {};


########################################################################
#	OZ++ I/F
########################################################################

#
#-----------------------------------------------------------------------
proc Replace {} {
    JST::LockControl;
    set flag [tk_dialog .replace "Replace Object" \
		  "Junkshop alredy exists.\nReplce it by new Junkshop ?" \
		  questhead 1 "Yes" "No"];

    if {$flag == 0} {
	JST::CmdStart 1;
    } else {
	JST::UnlockControl;
    }
}

proc Ack {{msg ""}} {
    if {"$msg" != ""} {
	tk_dialog .jst_ack \
	    "JSS Acknowledgment" "$msg" info 0 "OK";
    }
    JST::UnlockControl;
}

proc Error {msg} {
    JST::LockControl;
    tk_dialog .jst_error \
	"Error message" "$msg" error 0 "OK";
    JST::UnlockControl;
}

proc Exit {} {
    destroy .;
    exit;
}


########################################################################
###	User Command Handler
########################################################################

proc JST::CmdStart {interactive} {
    JST::LockControl;
    SendOZ "{StartJunkshop $interactive}";
}

proc JST::CmdPing {} {
    JST::LockControl;
    SendOZ "{PingJunkshop}";
}

proc JST::CmdRemove {} {
    JST::LockControl;
    SendOZ "{RemoveJunkshop}";
}

proc JST::CmdExit {} {
    JST::LockControl;
    SendOZ "{Exit}"
    Exit;
}


proc JST::LockControl {} {
    global  JST;

    foreach w $JST(lockset) {
	$w config -state disabled;
    }
}

proc JST::UnlockControl {} {
    global  JST;

    foreach w $JST(lockset) {
	$w config -state normal;
    }
}


proc JST::Init {} {
    global  JST;

    wm title . "JunkShop Tool ($JST(version))";
    wm iconname . "JunkShop Tool";

    set f_top [frame .top -relief raised -bd 1];
    set f_bot [frame .bot -relief raised -bd 1];
    pack $f_top $f_bot -side top -fill both;

    #--- Title
    catch {option add *Label.font -Adobe-Times-Bold-r-Normal-*-140-*};
    catch {option add *Label.font -misc-fixed-bold-r-normal--14-*};
    set title [label  $f_top.title -text "Junkshop Tool"];
    pack $title -ipadx 10 -ipady 5 -fill both -expand 1;

    #--- Start button
    set btn_start_f [frame $f_bot.f_start -relief sunken -bd 1];
    set btn_start [button $f_bot.start -text "Start" -bd 2 \
		       -command "JST::CmdStart 0"];
    #--- Remove button
    set btn_remove  [button $f_bot.remove -text "Remove" -bd 1 \
		       -command "JST::CmdRemove"];
    #--- Ping button
    set btn_ping  [button $f_bot.ping -text "Ping" -bd 1 \
		       -command "JST::CmdPing"];
    #--- Exit button
    set btn_exit  [button $f_bot.exit  -text "Exit" -bd 1 \
		       -command "JST::CmdExit"];

    raise $btn_start $btn_start_f;
    pack $btn_start_f -side left -expand 1 -padx 4 -pady 6;
    pack $btn_start -in $btn_start_f -padx 4 -pady 4 -ipadx 4 -ipady 2;
    pack $btn_remove $btn_ping $btn_exit \
	-side left -expand 1 -padx 6 -pady 10 -ipadx 4 -ipady 2;

    lappend JST(lockset) $btn_start $btn_remove $btn_ping;
}


#-----------------------------------------------------------------------
option add *background White;
option add *activeBackground Pink;

JST::Init;


# EoF
