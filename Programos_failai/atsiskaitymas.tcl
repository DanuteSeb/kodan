#!/usr/bin/wish
package require Tk
package require sqlite3
set ::pad5 "5 5 5 5"
set ::pad20 "20 20 20 20"
grid [ttk::frame .atsiskaitymas -padding $::pad20] -column 0 -row 0 -sticky nwes
#kad neitų uždaryti lango (BŪTINAI ATKOMENTUOTI!!!!!!!!!!!!!!!!!!!!):
wm protocol . WM_DELETE_WINDOW { }
wm title . "Atsiskaitymas"
#wm geometry . +600+380
wm resizable . 0 0
ttk::setTheme clam
image create photo ok -file "/skriptai/correct.png"
image create photo wrong -file "/skriptai/wrong.png"
image create photo save -file "/skriptai/Save.png"
image create photo reload -file "/skriptai/Restart32.png"

set fonas "#f5f6f7"
set zalia "#aee575"
set melyna "light blue"
ttk::style configure TButton -background $melyna -font "ubuntu 11" -bordercolor $melyna -lightcolor $melyna -darkcolor $melyna
ttk::style map TButton -background [list active "white" disabled "grey"]
ttk::style map TButton -bordercolor [list active "black"]
ttk::style map TButton -lightcolor [list active "white"]
ttk::style map TButton -darkcolor [list active "white"]
ttk::style configure red.TButton -background "tomato" -font "ubuntu 11 bold" -bordercolor "tomato" -lightcolor "tomato" -darkcolor "tomato"
ttk::style configure green.TButton -font "ubuntu 11" -background $zalia -bordercolor $zalia -lightcolor $zalia -darkcolor $zalia
ttk::style configure big.TButton -font "ubuntu 13"
ttk::style configure average.TButton -font "ubuntu 11"
ttk::style configure smallred.TButton -background "tomato" -font "ubuntu 11 bold" -bordercolor "tomato" -lightcolor "tomato" -darkcolor "tomato"

ttk::style configure TLabel -background $fonas -font "ubuntu 10"
ttk::style configure bold.TLabel -font "ubuntu 10 bold"
ttk::style configure big.TLabel -font "ubuntu 13"
ttk::style configure red.TLabel -foreground "red"
ttk::style configure green.TLabel -foreground "green"
ttk::style configure biggreen.TLabel -font "ubuntu 13" -foreground "green"
ttk::style configure normal.TLabel -font "ubuntu 10" -foreground "black" -background $fonas

ttk::style configure mazas.TCheckbutton -font "ubuntu 10"
ttk::style configure mazasspalvotas.TCheckbutton -font "ubuntu 10" -background $fonas
ttk::style configure TCheckbutton -background $fonas
ttk::style map TCheckbutton -background [list active "white"]

ttk::style configure TRadiobutton -background $fonas
ttk::style map TRadiobutton -background [list active "white"]

ttk::style configure TFrame -background $fonas

ttk::style configure TEntry -selectbackground $melyna -bordercolor $melyna

proc pradinis_langas {jei_pirma_karta r} {
	set pradinis_tekstas "Užduotis įkelta. Ją rasi aplanke „Nuo_mokytojos“. \n\nKai atliksi užduotį ir savo darbą išsaugosi aplanke „Atsiskaitymai“, nuspausk mygtuką „Siųsti darbą“."
	if {$jei_pirma_karta == 1} {
		grid [ttk::frame .atsiskaitymas.pradinis] -column 0 -row $r -sticky news; incr r
		grid [ttk::label .atsiskaitymas.pradinis.tekstas -text $pradinis_tekstas -padding "10 10 10 10" -style big.TLabel -wraplength 400] -column 0 -row $r -columnspan 2; incr r
		grid [ttk::button .atsiskaitymas.pradinis.mygtukas -text "Siųsti darbą" -command "ar_tikrai $r" -image save -compound left -style green.TButton] -column 0 -row $r -pady 10 -padx 10 -columnspan 2
	} else {
		destroy .atsiskaitymas.pradinis.mygtukas1 .atsiskaitymas.pradinis.mygtukas2
		.atsiskaitymas.pradinis.tekstas configure -text $pradinis_tekstas
		grid [ttk::button .atsiskaitymas.pradinis.mygtukas -text "Siųsti darbą" -command "ar_tikrai $r" -image save -compound left -style green.TButton] -column 0 -row $r -pady 10 -padx 10 -columnspan 2
	}
	
}

pradinis_langas 1 0

proc ar_tikrai {r} {
	.atsiskaitymas.pradinis.tekstas configure -text "Ar tikrai nori išsiųsti savo darbą mokytojai? Jei paspausi „Siųsti“, tavo darbas bus išsiųstas ir pataisyti jo jau nebegalėsi."
	destroy .atsiskaitymas.pradinis.mygtukas
	grid [ttk::button .atsiskaitymas.pradinis.mygtukas1 -text "Siųsti" -image ok -compound left -command "patikrinti_ar_issaugota; if {\[ar_testi\]} {destroy .artikrai; Sunaikinti}" -padding "10 10 10 10"] -padx 1 -pady 1 -column 0 -row $r
	grid [ttk::button .atsiskaitymas.pradinis.mygtukas2 -text "Atsisakyti"  -image wrong -compound left -command "pradinis_langas 0 $r" -padding "10 10 10 10"] -padx 1 -pady 1 -column 1 -row $r; incr r
}

proc patikrinti_ar_issaugota {} {
	set kiekis [llength [glob -nocomplain /home/mokinys/Atsiskaitymai/*]]
	if {$kiekis == 0} {
		set ::testi 0
		tk_messageBox -message "Mokytojos kompiuteris nerado tavo failų!\n\nTikriausiai ne ten išsaugojai...\n\nPasitikrink, ar tavo darbas tikrai yra aplanke „Atsiskaitymai“ ir mėgink siųsti iš naujo." -parent .atsiskaitymas
	} else {
		set ::testi 1
	}
}

proc ar_testi {} {
	if {$::testi == 0} {
		return 0
	} else {
		return 1
	}
}

proc Sunaikinti {} {
	destroy .atsiskaitymas .
}
