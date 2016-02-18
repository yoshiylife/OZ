#!wish -f
#
#  Copyright (c) 1994-1997 Information-technology Promotion Agency, Japan
#
#  All rights reserved.  No guarantee.
#  This technology is a result of the Open Fundamental Software Technology
#  Project of Information-technology Promotion Agency, Japan (IPA).
#

proc set_center {w} {
  wm withdraw $w;
  update idletasks;
  if {[set parent [winfo parent $w]] != ""} {
    set x [expr [winfo rootx $parent] + [winfo reqwidth $parent] / 2 \
	   - [winfo reqwidth $w] / 2];
    set y [expr [winfo rooty $parent] + [winfo reqheight $parent] / 2 \
	   - [winfo reqheight $w] / 2];
  } else {
    set x [expr [winfo vrootwidth $w] / 2 - [winfo reqwidth $w] / 2];
    set y [expr [winfo vrootheight $w] / 2 - [winfo reqheight $w] / 2];
  }
  wm geom $w +$x+$y;
  wm deiconify $w;
  update idletasks;
}

wm title . "OZ++ Launcher"

# dcl 
frame .frame -relief raised -borderwidth 1 
frame .menu -relief raised -borderwidth 1 
label .current 
pack append . .menu {top fillx} .current {top fillx} .frame {bottom fill}

#menus
menubutton .menu.create -text "Create" -menu .menu.create.m 
menu .menu.create.m
.menu.create.m add command -label "Project" \
        -command { dialog1 "Enter new project name"
                tkwait visibility .dia1
                grab .dia1
                tkwait window .dia1
                if { $status == 1 } then {
                        puts stdout "(Create 0 (.) $answer)"
                        flush stdout  
                        gets stdin record
                        if { [ string range $record 0 0 ] == "#" } {
                                my_error [string range $record 1 end ]
                        }
                        refresh_left
                }
         }       
.menu.create.m add command -label "Object" -command { 
                dialog2 "Enter object name" "ClassID" "Name"
                tkwait visibility .dia2
                grab .dia2
                tkwait window .dia2
                if { $status == 1 } then {
                        puts stdout "(Create 1 (.) $answer)"
                        flush stdout  
                        all_disable
                }
        }
#.menu.create.m add command -label "Class"  -command { 
#                dialog2 "Enter class alias" "Class" "Name"
#                tkwait visibility .dia2
#                grab .dia2
#                tkwait window .dia2
#                if { $status == 1 } then {
#                        puts stdout "(Create 2 (.) $answer)"
#                        flush stdout  
#                        gets stdin record
#                        if { [ string range $record 0 0 ] == "#" } {
#                                my_error [string range $record 1 end ]
#                        }
#                        if { $mode == 1 } then { refresh_right }
#                }
#        }
.menu.create.m add command -label "Package" -command {
        puts stdout "(Catalog)"
        flush stdout
        gets stdin record
        refresh_right
}

pack append .menu .menu.create {left}

menubutton .menu.edit -text "Edit" -menu .menu.edit.m 
menu .menu.edit.m

.menu.edit.m add command -label "Rename" -command "CopyOrMove Move" 

.menu.edit.m add command -label "Delete" -command { 
       if { ([ .frame.left.list.list curselection ] == "" ) && 
             ( [ .frame.right.list.list curselection ] == "" ) } { 
                my_error "Please select an item!" 
        } else {
		 set answer [tk_dialog .c1 "" "Sure?" question 0 "Yes" "No"];
                 if { $answer == 0 } then { 
#                        puts stdout "( Delete [lindex [selection get] 0])"
                        puts stdout "(Delete ([join [selection get] )( ] ))"
                        flush stdout
                        gets stdin record
                        refresh_left
                        refresh_right
                }
        }
}
pack append .menu .menu.edit {left}

menubutton .menu.project -text "Project" -menu .menu.project.m 
menu .menu.project.m
.menu.project.m add command -label "Up" \
        -command { puts stdout "(Change ..)"; flush stdout;
                gets stdin record;
                refresh_current;
                refresh_left;
                refresh_right;
        }
#.menu.project.m add command -label "Jump" \
#        -command { dialog1 "Enter Project Name"
#                tkwait visibility .dia1
#                grab .dia1
#                tkwait window .dia1
#                if { $status == 1 } then {
#                        puts stdout "(Change $answer)"
#                        flush stdout  
#                        gets stdin record
#                        refresh_current
#                        refresh_left
#                        refresh_right
#                }
#        } -state disabled

.menu.project.m add command -label "Tree" -command {
        tree
#        tkwait variable status
} 

pack append .menu .menu.project {left}

#button .menu.process -text "Process" -command { process_list } -relief flat
#pack .menu.process -side left

#menubutton .menu.find -text "Find" -menu .menu.find.m 

#menu .menu.find.m
#.menu.find.m add command -label "Find" -command {
#        dialog1 "Enter name"
#        tkwait visibility .dia1
#        grab .dia1
#        tkwait window .dia1
#        if { $status == 1 } then {
#                puts stdout "GetCurrent!."
#                flush stdout
#                gets stdin origine

#                findview $answer

#                puts stdout "Move!$origine"
#                flush stdout
#                gets stdin record
#        }
#}
#pack append .menu .menu.find {left}
#.menu.find.m add command -label "Prop" -command {
#       if { ([ .frame.left.list.list curselection ] == "" ) && \
#             ( [ .frame.right.list curselection ] == "" ) } { 
#                my_error "Please select an item!" 
#        } else {
#               puts stdout "Cid![lindex [selection get] 0]"
#                flush stdout
#                gets stdin record
#                if { $record != "0" } then {
#                        props $record
#                }
#        }
#}

menubutton .menu.help -text "Help" -menu .menu.help.m 
menu .menu.help.m
#pack append .menu .menu.help {right}

button .menu.intrrupt -text "Intrrupt" -relief flat -state disabled -command {
        puts stdout "(Create 1 (.) ***)"
        flush stdout
        all_able
}

menubutton .menu.system -text "System" -menu .menu.system.m
menu .menu.system.m
.menu.system.m add command -label "Flush" -command {
        puts stdout (Flush);
        flush stdout;
        gets stdin record;
}

.menu.system.m add command -label "Shutdown" -command { 
  set answer [tk_dialog .c1 "" "Sure?" question 0 "Yes" "No"];
  if { $answer == 0 } then { 
    puts stdout (Shutdown);  
    flush stdout;
    destroy .;
  }
}

pack .menu.system .menu.intrrupt -side right

#radio switchs
frame .frame.left -relief raised -borderwidth 1 
frame .frame.left.radio 
frame .frame.left.list 
pack append .frame.left .frame.left.radio { top fillx } .frame.left.list {top}

radiobutton .frame.left.radio.object -text "object" -width 8 \
        -command { set mode 0; refresh_right  } 
radiobutton .frame.left.radio.class -text "package" -width 8 \
        -command { set mode 1; refresh_right } 
.frame.left.radio.object select
set mode 0
pack append .frame.left.radio .frame.left.radio.object { left } \
        .frame.left.radio.class {left}

#listboxes
scrollbar .frame.left.list.scroll -relief sunken \
        -command ".frame.left.list.list yview" 
        listbox .frame.left.list.list -yscroll  ".frame.left.list.scroll set" \
        -relief sunken -setgrid 1 

bind .frame.left.list.list <Double-1> { 
        global suspend
        if { ( $suspend == 0 ) && ([.frame.left.list.list curselection] != "") } {
                puts stdout "(Change [lindex [selection get] 0])"
                flush stdout;
                gets stdin record;
                refresh_current;
                refresh_left;
                refresh_right; 
        }
}

#pack append .frame.left.list .frame.left.list.list {left filly} \
#        .frame.left.list.scroll {left filly}

pack .frame.left.list -side left -fill both -expand 1;
pack .frame.left.list.list -side left -fill both -expand 1;
pack .frame.left.list.scroll -side right -fill y;

#bind .frame.list1 <Button-2> \
#        ".menu.class.m post %X %Y"
#bind .menu.class.m <Leave> \
#        ".menu.class.m unpost"

frame .frame.right -relief raised -borderwidth 1
frame .frame.right.list -relief raised -borderwidth 1
scrollbar .frame.right.scroll -relief sunken \
        -command ".frame.right.list.list yview" 
scrollbar .frame.right.list.scroll -relief sunken -orient horiz \
        -command ".frame.right.list.list xview"
listbox .frame.right.list.list -yscroll  ".frame.right.scroll set" \
        -xscroll ".frame.right.list.scroll set" -relief sunken -setgrid 1 
pack .frame.right.list.list .frame.right.list.scroll -side top -fill x
pack append .frame.right .frame.right.list { left filly } \
        .frame.right.scroll { left filly }

bind .frame.right.list.list <Double-1> { 
        global suspend
        if { ($suspend == 0) &&([.frame.right.list.list curselection] != "") } {
                if { $mode == 0 } then { 
                        puts stdout "(Launch [lindex [selection get] 0])";
                        flush stdout;
                        gets stdin record;
                } else {
                        dialog1 "Enter object name"
                        tkwait visibility .dia1
                        grab .dia1
                        tkwait window .dia1
                        if { $status == 1 } then {
#                                puts stdout "(Instanciate $answer (. [lindex [selection get] 0]))" 
                                puts stdout "(GetCid [lindex [selection get] 0])"
                                flush stdout;
                                gets stdin record
                                puts stdout "(Create 1 (.) $answer $record)"
                                flush stdout
                                all_disable
                        }
                }
        }
}
pack append .frame .frame.left {left filly} .frame.right {left filly}

proc refresh_current {} {
        puts stdout "(GetCurrent)"
        flush stdout
        gets stdin record
        .current config -text "/[join $record /]"
}

proc refresh_left {} {
        puts stdout "(GetSub 0 (.))"
        flush stdout
        gets stdin record
        .frame.left.list.list delete 0 100
#        set e [ concat { .frame.left.list.list insert 0 } [string range $record [expr [string first ( $record] + 1] [expr [string first ) $record] - 1]]]
        set e [ concat { .frame.left.list.list insert 0 } $record ]
        eval $e
}

proc refresh_right {} { 
        global mode
        if { $mode == 0 } then { puts stdout "(GetSub 1 (.))" } \
                else { puts stdout "(GetSub 2 (.))" }
        flush stdout
        gets stdin record
        .frame.right.list.list delete 0 100
#        set e [ concat { .frame.right.list.list insert 0 } [string range $record [expr [string first ( $record] + 1] [expr [string first ) $record] - 1]]]
        set e [ concat { .frame.right.list.list insert 0 } $record ]
        eval $e
}

# operation
set suspend 0
refresh_current 
refresh_left
refresh_right 

#dialog boxes

proc dialog1 { title } {
    global answer
    global status
    global suspend
    toplevel .dia1 
#    dpos $w
    wm title .dia1 "Dialog box"
    label .dia1.msg -text $title 
    frame .dia1.frame1 
    frame .dia1.frame2 
    entry .dia1.frame1.e1 -relief sunken 
    label .dia1.frame1.prompt -text "name" 
    pack append .dia1.frame1 .dia1.frame1.prompt {left} \
                .dia1.frame1.e1 {left fillx}

    button .dia1.frame2.accept -text Accept -command { 
        set answer [.dia1.frame1.e1 get]
        if { $answer != "" } then {        
                set status 1
        } else {
                set status 0
        }
        destroy .dia1 
    } 
    button .dia1.frame2.cancel -text Cancel -command {
        set status 0
        destroy .dia1
    } 

    bind .dia1.frame1.e1 <Return> { 
      if {[.dia1.frame1.e1 get] != ""} {
	.dia1.frame2.accept invoke;
      } 
    }

    focus .dia1.frame1.e1
    pack .dia1.frame2.accept .dia1.frame2.cancel -side left \
        -ipadx 2m -ipady 0.5m -expand 1

    pack .dia1.msg .dia1.frame1 .dia1.frame2 -side top -fill x \
        -ipadx 2m -ipady 1m -expand 1

    set_center .dia1
}

proc dialog2 { title prompt1 prompt2 } {
    global answer
    global status
    toplevel .dia2 
#    dpos $w
    wm title .dia2 "Dialog box" 
#    message .dia2.msg -font -Adobe-times-bold-r-normal--*-140* -aspect 300 \
#	    -text $title 
    label .dia2.msg -text $title 
    frame .dia2.frame 
    frame .dia2.frame.left 
    frame .dia2.frame.right 

    label .dia2.frame.left.prompt1 -text $prompt1 
    label .dia2.frame.left.prompt2 -text $prompt2 

    entry .dia2.frame.right.e1 -relief sunken 
    entry .dia2.frame.right.e2 -relief sunken 

    frame .dia2.sb
    global sb_on
    set sb_on 0
#    radiobutton .dia2.sb.on -text "Catalog" -command {
#        set sb_on 1
#    }
#    .dia2.sb.on select
#    radiobutton .dia2.sb.off -text "Id" -command {
#        set sb_on 0
#    }
#    pack .dia2.sb.on .dia2.sb.off \
#        -side left -fill y -ipadx 2m -ipady 0.3m -expand 1

    frame .dia2.buttons 
    button .dia2.buttons.accept -text Accept -command { 
        if { ([string match [.dia2.frame.right.e1 get]  "" ]) \
                || ([.dia2.frame.right.e2 get] == "") } then {
                set status 0
        } else {
                set status 1
#                set cl [exec sb "[.dia2.frame.right.e1 get]" 0]
		set name [.dia2.frame.right.e1 get];
                if { $sb_on == 1 } {
                        puts stdout "(Import [.dia2.frame.right.e1 get])"
                        flush stdout
                        gets stdin record
                        if { $record == 0 } { 
                                my_error "Not Found."
                                set status 0
                                destroy .dia2
                                return
                        }
                        set answer "[.dia2.frame.right.e2 get] $record"
                        destroy .dia2
                } else {
                        set answer "[.dia2.frame.right.e2 get] [.dia2.frame.right.e1 get]"
                                destroy .dia2
                }

        }
#        destroy .dia2 
    } 
    button .dia2.buttons.cancel -text Cancel -command {
        set status 0
        destroy .dia2
    } 
    pack .dia2.buttons.accept .dia2.buttons.cancel \
        -side left -fill y -ipadx 2m -ipady 0.3m -expand 1
    focus .dia2.frame.right.e1
    bind .dia2.frame.right.e1 <Tab> { focus .dia2.frame.right.e2 }
    bind .dia2.frame.right.e1 <Return> { 
#	focus .dia2.frame.right.e2 
      if {[.dia2.frame.right.e2 get] != ""} {
	.dia2.buttons.accept invoke;
      } else {
	focus .dia2.frame.right.e2;
      }
    }
    bind .dia2.frame.right.e2 <Tab> { focus .dia2.frame.right.e1 }
    bind .dia2.frame.right.e2 <Return> { 
#      focus .dia2.frame.right.e1 
      if {[string match [.dia2.frame.right.e1 get] ""]} {
	focus .dia2.frame.right.e1;
      } else {
	.dia2.buttons.accept invoke;
      }
    }

    pack .dia2.frame.left.prompt1 .dia2.frame.left.prompt2 \
        -side top -fill x
    pack .dia2.frame.right.e1 .dia2.frame.right.e2 \
        -side top -fill x
    pack .dia2.frame.left .dia2.frame.right -side left -fill y
    pack .dia2.msg .dia2.frame .dia2.sb .dia2.buttons -side top -fill x

    set_center .dia2
}

proc dialog3 { title prompt1 prompt2 } {
    global answer
    global status
    toplevel .dia3 
#    dpos $w
    wm title .dia3 "Dialog box" 
#    message .dia3.msg -font -Adobe-times-bold-r-normal--*-140* -aspect 300 \
#	    -text $title 
    label .dia3.msg -text $title
    frame .dia3.frame 
    frame .dia3.frame.left 
    frame .dia3.frame.right 

    label .dia3.frame.left.prompt1 -text $prompt1 
    label .dia3.frame.left.prompt2 -text $prompt2 

    entry .dia3.frame.right.e1 -relief sunken 
#    entry .dia3.frame.right.e2 -relief sunken 

    frame .dia3.buttons 
    button .dia3.buttons.accept -text Accept -command { 
        if { [.dia3.frame.right.e1 get] == "" } then {
                set status 0
        } else {
                set status 1
                set answer [.dia3.frame.right.e1 get]
# [.dia3.frame.right.e2 get]
        }
        destroy .dia3
    } 
    button .dia3.buttons.cancel -text Cancel -command {
        set status 0
        destroy .dia3
    } 
    pack .dia3.buttons.accept .dia3.buttons.cancel \
        -side left -fill y -ipadx 2m -ipady 0.3m -expand 1
    focus .dia3.frame.right.e1
    bind .dia3.frame.right.e1 <Tab> { focus .dia3.frame.right.e2 }
    bind .dia3.frame.right.e1 <Return> { focus .dia3.frame.right.e2 }
#    bind .dia3.frame.right.e2 <Tab> { focus .dia3.frame.right.e1 }
#    bind .dia3.frame.right.e2 <Return> { focus .dia3.frame.right.e1 }

    pack .dia3.frame.left.prompt1 -side top -fill x
    pack .dia3.frame.right.e1 -side top -fill x
    pack .dia3.frame.left .dia3.frame.right -side left -fill y
    pack .dia3.msg .dia3.frame .dia3.buttons -side top -fill x

    set_center .dia3;
}

proc confirm w {
        toplevel $w 
        wm title $w "confirm"
        message $w.msg -font -Adobe-times-bold-r-normal--*-140* -aspect 300 \
	    -text "Sure?" 
        frame $w.frame 
        button $w.frame.yes -text Yes -command { set answer 1; destroy .c1 } 
        button $w.frame.no -text No -command { set answer 0; destroy .c1 } 
        pack $w.frame $w.frame.yes $w.frame.no -side left -ipadx 2m
        pack append $w $w.msg { top fillx } $w.frame {bottom fillx}
}

proc props { cid } {
        toplevel .props 
        wm title .props "Class ID"
        button .props.ok -text OK -command "destroy .props" 
        label .props.msg -relief sunken -text "Class ID: $cid" 
        pack .props.msg -side top -fill x
        pack .props.ok -side bottom
}
        
proc tree {} {
        toplevel .tree 
        grab .tree
        wm title .tree "Tree Project"
        button .tree.ok -text OK -command "destroy .tree" 
        text .tree.msg -relief raised 

        .tree.msg insert 0.0 [prj_print ~ 0]
        pack .tree.msg .tree.ok -fill x -side top
        grab release .tree
}

proc prj_print { name level } {
        set text ""
        set brank ""
        for { set i 0 } { $i < $level } { incr i } {
                set brank "$brank   "
        }
        puts stdout "( GetSub 0 ( $name ) )"
        flush stdout
        gets stdin subp
        foreach p $subp {
                set text "$text$brank$p\n[prj_print [concat $name $p] [expr $level +1] ]"
        }
        return $text
}

proc viewlist { str } {
        toplevel .view
        set msg [join [split $str !] \n]
        text .view.msg 
        .view.msg insert 0.0 $msg
        button .view.ok -text OK -command "destroy .view"
        pack .view.msg -side top -fill x
        pack .view.ok -side top
}

proc CopyOrMove { com } {
        if { ([ .frame.left.list.list curselection ] == "" ) && \
             ( [ .frame.right.list.list curselection ] == "" ) } { 
                my_error "Please select an item!" 
        } else {
                global status
                global answer
                set cur [lindex [selection get] 0 ]
                dialog3 "Enter New" "name" "Name"
                tkwait visibility .dia3
                grab .dia3
                tkwait window .dia3
                if { $status == 1 } then {
                        puts stdout "( Move ($cur) $answer )"
                        flush stdout
                        gets stdin record
                        refresh_left
                        refresh_right
                }
        }
}

proc my_error { msg } {
	tk_dialog .conf "OZ++" $msg error 0 "OK";
        all_able
#        toplevel .conf 
#        wm title .conf "OZ++"
#        label .conf.msg  -text $msg 
#        button .conf.ok -text OK -command "destroy .conf" 
#        pack .conf.msg .conf.ok -side top 
}

proc refresh_process {} {
        .process.frame.list delete 0 end
        puts stdout "Process"
        flush stdout
        gets stdin record
        set e [ concat { .process.frame.list insert 0 } [split $record /]]
        eval $e
}

proc process_list {} {
        toplevel .process
        wm title .process "Process List"

        frame .process.frame

        listbox .process.frame.list -yscroll ".process.frame.scroll set" \
                -relief sunken -setgrid 1
        scrollbar .process.frame.scroll -relief sunken \
                -command ".process.frame.list yview"
        pack .process.frame.list .process.frame.scroll -side left -fill y

        frame .process.buttons
        button .process.buttons.refresh -text "Refresh" -command { 
                refresh_process }
        button .process.buttons.close -text "Close" -command "destroy .process"
        pack .process.buttons.refresh .process.buttons.close -side left -padx 20

        pack .process.frame .process.buttons -side top -fill x

        refresh_process 
}

proc all_disable {} {
        global suspend
        .menu.create configure -state disabled
        .menu.edit configure -state disabled
        .menu.project configure -state disabled
#        .menu.process configure -state disabled
        .menu.system configure -state disabled
        .frame.left.radio.object configure -state disabled
        .frame.left.radio.class configure -state disabled
        .menu.intrrupt configure -state normal
        set suspend 1
}

proc all_able {} {
        global suspend
        global mode

        .menu.create configure -state normal
        .menu.edit configure -state normal
        .menu.project configure -state normal
#        .menu.process configure -state normal
        .menu.system configure -state normal
        .frame.left.radio.object configure -state normal
        .frame.left.radio.class configure -state normal
        .menu.intrrupt configure -state disabled
        if { $mode == 0 } then {
                .frame.left.radio.object select
        } else {
                .frame.left.radio.class select
        }                
       set suspend 0
}

proc done {} {
        global mode
 #       gets stdin record
 #       if { [string range $record 0 0] == "#" } {
  #              my_error [ string range $record 1 end]; 
   #     }
    #    if { $mode == 0 } then { refresh_right }
      refresh_right
        all_able
}