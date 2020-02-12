#!/usr/bin/wish
package require Tk
package require sqlite3
set ::pad5 "5 5 5 5"
set ::pad20 "20 20 20 20"
grid [ttk::frame .testas -padding $::pad20] -column 0 -row 0 -sticky nwes
wm protocol . WM_DELETE_WINDOW { }
wm title . "Atsakymų peržiūra"
#wm geometry . +600+380
wm resizable . 0 0
ttk::setTheme clam
image create photo ok -file "/skriptai/correct.png"
image create photo wrong -file "/skriptai/wrong.png"
image create photo save -file "/skriptai/Save.png"
image create photo reload -file "/skriptai/Restart32.png"
image create photo bullet -file "/skriptai/bullet.png"

set fonas "#f5f6f7"
set zalia "#aee575"
set melyna "light blue"
ttk::style configure TButton -background $melyna -font "ubuntu 10" -bordercolor $melyna -lightcolor $melyna -darkcolor $melyna
ttk::style map TButton -background [list active "white" disabled "grey"]
ttk::style map TButton -bordercolor [list active "black"]
ttk::style map TButton -lightcolor [list active "white"]
ttk::style map TButton -darkcolor [list active "white"]
ttk::style configure red.TButton -background "tomato" -font "ubuntu 13 bold" -bordercolor "tomato" -lightcolor "tomato" -darkcolor "tomato"
ttk::style configure green.TButton -font "ubuntu 13" -background $zalia -bordercolor $zalia -lightcolor $zalia -darkcolor $zalia
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

sqlite3 db1 /skriptai/klausimai

set ::klausimu_skaicius [db1 eval {SELECT COUNT(*) FROM m_klausimai ORDER BY Id}]
set ::ar_pazymiui [db1 onecolumn {SELECT reiksme FROM m_options WHERE pavadinimas="ar_pazymiui"}]
set ::ar_perziurejo_atsakymus 0

proc Pradinis_langas {} {
	grid [ttk::frame .testas.pradinis]
	grid [ttk::label .testas.pradinis.tekstas -style big.TLabel -text "Tavo atsakymai įrašyti." -padding $::pad20] -column 1 -row 0 -sticky we
	grid [ttk::button .testas.pradinis.mygtukas -style green.TButton -text "Peržiūrėti teisingus atsakymus" -command "destroy .testas.pradinis .testas.pradinis.tekstas .testas.pradinis.mygtukas; Klausimo_piesimas 1 0" -padding $::pad20] -column 0 -row 1 -columnspan 2 -sticky we -pady 10 -padx 10
}

proc Klausimo_piesimas {k buves_kl} {
	destroy .testas.t
	grid [ttk::frame .testas.t]
	set i 1
	set klid [db1 eval {SELECT klausimo_id FROM m_klausimai_testai WHERE klausimo_nr=$k}]
	set klausimas [db1 onecolumn {SELECT kl FROM m_klausimai WHERE Id=$klid}]
	set tipas [db1 eval {SELECT tipas FROM m_klausimai WHERE Id=$klid}]
	set visi_klausimo_variantai [db1 eval {SELECT atsakymo_var FROM m_atsakymuvariantai WHERE klausimo_id=$klid}]
	set taskai [format "%.1f" [db1 eval {SELECT verte_taskais FROM m_klausimai_testai WHERE klausimo_id=$klid}]]
	set surinko_tsk 0
	if {$::ar_pazymiui == 1} {
		set klausimo_tekstas "$k. $klausimas ($taskai tšk.)"
	} else {
		set klausimo_tekstas "$k. $klausimas"
	}
	if {$tipas == "atviras_kl"} {
		set wrap 520
		set r 0
		set mokinioats [db1 onecolumn {SELECT atsakymo_var FROM m_atsakymuvariantai WHERE klausimo_id=$klid AND ar_teisingas_var=0}]
		set teisingasats [db1 onecolumn {SELECT atsakymo_var FROM m_atsakymuvariantai WHERE klausimo_id = $klid AND ar_teisingas_var=1}]
		set pav_id [db1 onecolumn {SELECT pav_id FROM m_klausimai WHERE Id=$klid}]
		if {$pav_id != ""} {
			set paveiksliukas [db1 onecolumn {SELECT content FROM m_paveiksleliai WHERE Id=$pav_id LIMIT 1}]
			image create photo p -data $paveiksliukas
			set wi [image width p]
			if {$wi > $wrap} {
				set wrap $wi
			}
			grid [ttk::label .testas.t.klausimas -text $klausimo_tekstas -padding "10 10 10 10" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
			grid [ttk::label .testas.t.p -text "" -image p -padding "10 10" -compound left] -column 0 -row $r; incr r
		} else {
			grid [ttk::label .testas.t.klausimas -text $klausimo_tekstas -padding "10 10 10 10" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
		}
		#rodo, ką atvirame klausime parase mokinys bei koks yra teisingas atsakymas:
		grid [ttk::label .testas.t.mokinio -style big.TLabel -text "Tu parašei:"] -column 0 -row $r -sticky we; incr r
		grid [ttk::label .testas.t.atsakymas -text "$mokinioats" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
		grid [ttk::label .testas.t.teisingas -style big.TLabel -text "Teisingas atsakymas:"] -column 0 -row $r -sticky we; incr r
		grid [ttk::label .testas.t.atsakymast -text "$teisingasats" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
		grid [ttk::label .testas.t.info -style big.TLabel -text "Pastaba: ar teisingai atsakei į klausimą, pamėgink įsivertinti pats(-i). Kiek tiksliai už jį gausi taškų, sužinosi vėliau (kai testą patikrins mokytoja)." -wraplength $wrap -padding "20 5 5 5"] -column 0 -row $r -sticky w; incr r
	} else {
		#rodo mokiniui klausimu teksta (su variantais – kai 1 ar keli teisingi):
		if {$tipas == "keli_teisingi"} {
			set teisingi_tekstas "Teisingi atsakymai:"
			set mokinioatsakymai [db1 eval {SELECT pasirinko FROM m_atsakymuvariantai WHERE klausimo_id=$klid}]
			for {set i 0} {$i < [llength $mokinioatsakymai]} {incr i} {
				set mokinioats$i [lindex $mokinioatsakymai $i] 
			}
			set r 0
			set j 0
			set wrap 520
			set pav_id [db1 onecolumn {SELECT pav_id FROM m_klausimai WHERE Id=$klid}]
			if {$pav_id != ""} {
				set paveiksliukas [db1 onecolumn {SELECT content FROM m_paveiksleliai WHERE Id=$pav_id LIMIT 1}]
				image create photo p -data $paveiksliukas
				set wi [image width p]
				if {$wi > $wrap} {
					set wrap $wi
				}
				grid [ttk::label .testas.t.klausimas -text $klausimo_tekstas -padding "10 10 10 10" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
				grid [ttk::label .testas.t.p -text "" -image p -padding "10 10" -compound left] -column 0 -row $r; incr r
			} else {
				grid [ttk::label .testas.t.klausimas -text $klausimo_tekstas -padding "10 10 10 10" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
			}
		}
		if {$tipas == "vienas_teisingas"} {
			set teisingi_tekstas "Teisingas atsakymas:"
			set mokinioats [db1 eval {SELECT pasirinko FROM m_atsakymuvariantai WHERE klausimo_id=$klid}]
			for {set i 0} {$i < [llength $mokinioats]} {incr i} {
				set mokinioats$i [lindex $mokinioats $i]
			}
			set r 0
			set j 0
			set wrap 520
			set pav_id [db1 onecolumn {SELECT pav_id FROM m_klausimai WHERE Id=$klid}]
			if {$pav_id != ""} {
				set paveiksliukas [db1 onecolumn {SELECT content FROM m_paveiksleliai WHERE Id=$pav_id LIMIT 1}]
				image create photo p -data $paveiksliukas
				set wi [image width p]
				if {$wi > $wrap} {
					set wrap $wi
				}
				grid [ttk::label .testas.t.klausimas -text $klausimo_tekstas -padding "10 10 10 10" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
				grid [ttk::label .testas.t.p -text "" -image p -padding "10 10" -compound left] -column 0 -row $r; incr r
			} else {
				grid [ttk::label .testas.t.klausimas -text $klausimo_tekstas -padding "10 10 10 10" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
			}
		}
		#piesia teisingu ir klaidingu variantu rodyma klausimams su variantais:
		grid [ttk::label .testas.t.pasirinkai -style big.TLabel -compound left -text "Tu pažymėjai:" -wraplength $wrap -padding "20 5 5 5"] -column 0 -row $r -sticky w; incr r	
		foreach variantas $visi_klausimo_variantai {
			set arteisingasats [db1 eval {SELECT ar_teisingas_var FROM m_atsakymuvariantai WHERE klausimo_id=$klid AND atsakymo_var=$variantas}]
			if {$arteisingasats == 1} {
					set stilius green.TLabel
					set icon ok
				} else {
					set stilius red.TLabel
					set icon wrong
				}
				
			if {[set mokinioats$j] == "1"} {
				grid [ttk::label .testas.t.$j -style $stilius -image $icon -compound left -text "$variantas" -wraplength $wrap -padding "20 5 5 5"] -column 0 -row $r -sticky w; incr r 
				if {$::ar_pazymiui == 1} {
					set tsk_jei_pasirinko [db1 onecolumn {SELECT tsk_jei_pasirinko FROM m_atsakymuvariantai WHERE klausimo_id=$klid AND atsakymo_var=$variantas}]
					set surinko_tsk [expr $tsk_jei_pasirinko + $surinko_tsk]
				}
			} else {
				if {$::ar_pazymiui == 1} {
					set tsk_jei_nepasirinko [db1 onecolumn {SELECT tsk_jei_nepasirinko FROM m_atsakymuvariantai WHERE klausimo_id=$klid AND atsakymo_var=$variantas}]
					set surinko_tsk [expr $surinko_tsk + $tsk_jei_nepasirinko]
				}
			}
			incr j
		}
		
		set surinko_tsk [format "%.1f" [expr $surinko_tsk * $taskai]]
		
		grid [ttk::label .testas.t.teisingi -style big.TLabel -compound left -text $teisingi_tekstas -wraplength $wrap -padding "20 5 5 5"] -column 0 -row $r -sticky w; incr r
		foreach variantas $visi_klausimo_variantai {
			set arteisingasats [db1 eval {SELECT ar_teisingas_var FROM m_atsakymuvariantai WHERE klausimo_id=$klid AND atsakymo_var=$variantas}]
			if {$arteisingasats == 1} {
				grid [ttk::label .testas.t.teisingas$i -style normal.TLabel -image bullet -compound left -text "$variantas" -wraplength $wrap -padding "20 5 5 5"] -column 0 -row $r -sticky w; incr r
			}
			incr i
		}
		
		if {$::ar_pazymiui == 1} {
			if {$surinko_tsk == "0.0"} {
				set surinko_tsk 0
			}
			grid [ttk::label .testas.t.info -style big.TLabel -text "Gavai taškų: $surinko_tsk iš $taskai" -wraplength $wrap -padding "20 5 5 5"] -column 0 -row $r -sticky w; incr r
		}
	}
	if {$k <= $::klausimu_skaicius} {
		grid [ttk::frame .testas.t.f -padding $::pad5] -column 0 -row $r -sticky news
		grid columnconfigure .testas.t.f 0 -weight 1
		grid columnconfigure .testas.t.f 1 -weight 1
		grid columnconfigure .testas.t.f 2 -weight 1
		if {$k == 1} {
		incr r
		grid [ttk::button .testas.t.f.kitas -style average.TButton -text "Kitas >" -command "Klausimo_piesimas [expr $k+1] $k" -padding $::pad5] -column 0 -row $r -pady 10 -padx 10 -sticky e
			if {$::ar_perziurejo_atsakymus == 1} {
				grid [ttk::button .testas.t.f.paskutinis -style average.TButton -text "Paskutinis >>" -command "Klausimo_piesimas $::klausimu_skaicius $::klausimu_skaicius" -padding $::pad5 -style smallred.TButton] -column 2 -row $r -pady 10 -padx 10 -sticky w
			}
		}
		if {$k > 1 && $k != $::klausimu_skaicius} {
			incr r
			grid [ttk::button .testas.t.f.pirmas -style average.TButton -text "<< Pirmas" -command "Klausimo_piesimas 1 0" -padding $::pad5 -style smallred.TButton] -column 0 -row $r -pady 10 -padx 10 -sticky w
			grid [ttk::button .testas.t.f.kitas -style average.TButton -text "Kitas >" -command "Klausimo_piesimas [expr $k+1] $k" -padding $::pad5] -column 2 -row $r -pady 10 -padx 10 -sticky w
			grid [ttk::button .testas.t.f.ankstesnis -style average.TButton -text "< Ankstesnis" -command "Klausimo_piesimas [expr $k-1] $k" -padding $::pad5] -column 1 -row $r -pady 10 -padx 10 -sticky e
			if {$::ar_perziurejo_atsakymus == 1} {
				grid [ttk::button .testas.t.f.paskutinis -style average.TButton -text "Paskutinis >>" -command "Klausimo_piesimas $::klausimu_skaicius $::klausimu_skaicius" -padding $::pad5 -style smallred.TButton] -column 3 -row $r -pady 10 -padx 10 -sticky we
			}
		}
		if {$k == $::klausimu_skaicius} {
			incr r
			grid [ttk::button .testas.t.f.pirmas -style average.TButton -text "<< Pirmas" -command "Klausimo_piesimas 1 0" -padding $::pad5 -style smallred.TButton] -column 0 -row $r -pady 10 -padx 10 -sticky w
			grid [ttk::button .testas.t.f.kitas -style average.TButton -text "Toliau >" -command "Informacinis_langas" -padding $::pad5] -column 2 -row $r -pady 10 -padx 10 -sticky w
			grid [ttk::button .testas.t.f.ankstesnis -style average.TButton -text "< Ankstesnis" -command "Klausimo_piesimas [expr $k-1] $k" -padding $::pad5] -column 1 -row $r -pady 10 -padx 10 -sticky e
		}
	}
	if {$k > $::klausimu_skaicius || $tipas == ""} {
		Informacinis_langas
	}
}

Pradinis_langas

proc Informacinis_langas {} {
	set ::ar_perziurejo_atsakymus 1
	destroy .testas.t
	grid [ttk::frame .testas.t]
	set r 0
	grid [ttk::label .testas.t.informacija -style normal.TLabel -text "Pasirink veiksmą:" -padding "10 10 10 10" -style big.TLabel] -column 0 -row $r -columnspan 2; incr r
	grid [ttk::button .testas.t.darkarta -style big.TButton -text "Dar kartą peržiūrėti atsakymus" -image reload -compound left -command "Klausimo_piesimas 1 0" -padding $::pad20] -column 0 -row $r -sticky we -pady 10 -padx 10; incr r
	grid [ttk::button .testas.t.visiskaibaigti -style red.TButton -text "Baigti testą" -image save -compound left -command "Sunaikinti" -padding $::pad20] -column 0 -row $r -sticky we -pady 10 -padx 10
}


proc Sunaikinti {} {
	destroy .testas.pabaiga .
}
