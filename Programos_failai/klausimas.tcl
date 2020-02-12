#!/usr/bin/wish
package require Tk
set pavad [lindex $::argv 1]
grid [ttk::frame .frame -padding "20 20 20 20"] -column 0 -row 0 -sticky nwes
wm title . "$pavad"
wm geometry . +550+300
wm resizable . 0 0
ttk::setTheme clam
ttk::style configure TButton -background "light blue" -font "ubuntu 16 bold" -bordercolor "light blue" -lightcolor "light blue" -darkcolor "light blue"
ttk::style configure raudonas.TButton -background "tomato" -font "ubuntu 16 bold" -bordercolor "tomato" -lightcolor "tomato" -darkcolor "tomato"
ttk::style map TButton -background [list active "white" disabled "light grey"]
ttk::style map TButton -lightcolor [list active "white" disabled "light grey"]
ttk::style map TButton -darkcolor [list active "white" disabled "light grey"]
ttk::style configure TFrame -background "#f5f6f7"
ttk::style configure TLabel -background "#f5f6f7" -font "ubuntu 13"

proc p_zinute {} {
set tekstas "1023"
#set tekstas [lindex $::argv 0]
grid [ttk::label .frame.label -text "" -width 20] -column 0 -row 0
grid [ttk::label .frame.label1 -text "$tekstas"] -pady 15 -column 0 -row 1 -columnspan 2
grid [ttk::button .frame.button1 -text "Taip" -command "p_Sunaikinti" -padding "40 50 50 40"] -pady 20 -padx 10 -column 0 -row 2
grid [ttk::button .frame.button2 -text "Ne" -command "p_Sunaikinti" -padding "40 50 50 40" -style raudonas.TButton] -pady 20 -padx 10 -column 1 -row 2
focus .frame.button1
}

p_zinute

after 300000 {p_Sunaikinti}

proc p_Sunaikinti {} {
	destroy .
}	
