#!/usr/bin/wish
package require Tk
set pavad [lindex $::argv 1]
grid [ttk::frame .frame -padding "20 20 20 20"] -column 0 -row 0 -sticky nwes
wm title . "$pavad"
wm geometry . +550+300
wm resizable . 0 0
ttk::setTheme clam
ttk::style configure TButton -background "light blue" -font "ubuntu 13 bold" -bordercolor "light blue" -lightcolor "light blue" -darkcolor "light blue"
ttk::style configure TFrame -background "#f5f6f7"
ttk::style configure TLabel -background "#f5f6f7" -font "ubuntu 13"

bind . <Escape> "p_Sunaikinti"

proc p_zinute {} {
set tekstas [lindex $::argv 0]
grid [ttk::label .frame.label -text "" -width 20] -column 0 -row 0
grid [ttk::label .frame.label1 -text "$tekstas"] -pady 15 -column 0 -row 1
grid [ttk::button .frame.button1 -text "Gerai" -command "p_Sunaikinti"] -pady 10 -column 0 -row 2
focus .frame.button1
bind . <Return> ".frame.button1 invoke"
}

p_zinute

after 120000 {p_Sunaikinti}

proc p_Sunaikinti {} {
	destroy .
}	
