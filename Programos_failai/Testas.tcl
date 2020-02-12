#!/usr/bin/wish
package require Tk
package require sqlite3
set ::pad5 "5 5 5 5"
set ::pad10 "10 10 10 10"
set ::pad20 "20 20 20 20"
grid [ttk::frame .testas -padding $::pad20] -column 0 -row 0 -sticky nwes
wm protocol . WM_DELETE_WINDOW { }
sqlite3 db1 /skriptai/klausimai
set ::ar_pazymiui [db1 onecolumn {SELECT reiksme FROM m_options WHERE pavadinimas="ar_pazymiui"}]
if {$::ar_pazymiui == 1} {
	wm title . "Testas"
} else {
	wm title . "Apklausa"
}
#wm geometry . +600+380
wm resizable . 0 0
ttk::setTheme clam
image create photo save -file "/skriptai/Save.png"
image create photo reload -file "/skriptai/Restart32.png"
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

ttk::style configure TLabel -background $fonas -font "ubuntu 10"
ttk::style configure bold.TLabel -font "ubuntu 10 bold"
ttk::style configure big.TLabel -font "ubuntu 13"
ttk::style configure red.TLabel -foreground "red"

ttk::style configure mazas.TCheckbutton -font "ubuntu 10"
ttk::style configure mazasspalvotas.TCheckbutton -font "ubuntu 10" -background $fonas
ttk::style configure TCheckbutton -background $fonas
ttk::style map TCheckbutton -background [list active "white"]

ttk::style configure TRadiobutton -background $fonas
ttk::style map TRadiobutton -background [list active "white"]

ttk::style configure TFrame -background $fonas

ttk::style configure TEntry -selectbackground $melyna -bordercolor $melyna

set ::pc "[exec hostname]"
set ::klausimu_skaicius [db1 eval {SELECT COUNT(*) FROM m_klausimai ORDER BY Id}]
set ::atv_kl_sk [db1 eval {SELECT COUNT(*) FROM m_klausimai WHERE tipas="atviras_kl"}]
puts $::atv_kl_sk
set ::kitu_kl_sk [db1 eval {SELECT COUNT(*) FROM m_klausimai WHERE tipas="vienas_teisingas" OR tipas="keli_teisingi"}]
puts $::kitu_kl_sk
set ::mok_id [db1 onecolumn {SELECT reiksme FROM m_options WHERE pavadinimas="mokinio id"}]
set ::mok_vardas [db1 onecolumn {SELECT reiksme FROM m_options WHERE pavadinimas="mokinio vardas"}]
set ::mok_pavarde [db1 onecolumn {SELECT reiksme FROM m_options WHERE pavadinimas="mokinio pavarde"}]
set ::mok_klase [db1 onecolumn {SELECT reiksme FROM m_options WHERE pavadinimas="mokinio klase"}]
set ::atviru_klausimu_sk 0

for {set i 1} {$i<=$::klausimu_skaicius} {incr i} {
	set klid [db1 onecolumn {SELECT klausimo_id FROM m_klausimai_testai WHERE klausimo_nr=$i}]
	set tipas [db1 onecolumn {SELECT tipas FROM m_klausimai WHERE Id=$klid}]
	if {$tipas == "atviras_kl"} {
		set ::atviru_klausimu_sk [expr $::atviru_klausimu_sk + 1]
	}
}
puts $::atviru_klausimu_sk

proc p_galunes_parinkimas {k} {
	if {$k == 1 || $k == 21} {
		return "as"
	}
	if {$k >= 2 && $k <= 9} { 
		return "ai"
	} 
	if {$k >= 22 && $k <= 29} {
		return "ai"
	}
	if {$k >= 10 && $k <= 20 || $k == 30} {
		return "ų"
	}
}

proc p_tikrinam_mok_duomenis {} {
	if {$::mok_vardas == "" || $::mok_pavarde == "" || $::mok_klase == ""} {
		Einam_rasyti_varda
		return
	} else {
		set r 0
		destroy .testas.p
		grid [ttk::frame .testas.i]
		grid [ttk::label .testas.i.irasyk -text "Tu esi:\n$::mok_vardas $::mok_pavarde, $::mok_klase klasė" -style big.TLabel] -column 0 -columnspan 2 -row $r -padx 5 -pady 5; incr r
		grid [ttk::label .testas.i.artaip -text "Ar duomenys teisingi?" -style big.TLabel] -column 0 -columnspan 2 -row $r -padx 5 -pady 5; incr r
		grid [ttk::button .testas.i.button1 -style green.TButton -text "Taip" -command "Klausimo_piesimas 1 0" -padding "5 5"] -column 0 -row $r -padx 5 -pady 5
		grid [ttk::button .testas.i.button2 -style red.TButton -text "Ne" -command "Einam_rasyti_varda" -padding "5 5"] -column 1 -row $r -padx 5 -pady 5
	}
}

proc Einam_rasyti_varda {} {
	set r 0
	destroy .testas.p .testas.i
	grid [ttk::frame .testas.i]
	grid [ttk::label .testas.i.irasyk -text "Įrašyk savo duomenis:"] -column 0 -columnspan 2 -row $r; incr r
	grid [ttk::entry .testas.i.vardas -textvariable vardas] -column 1 -row $r
	focus .testas.i.vardas
	grid [ttk::label .testas.i.label1 -text "VARDAS:" -padding "10 10 10 10"] -column 0 -row $r -sticky w; incr r
	grid [ttk::entry .testas.i.pavarde -textvariable pavarde] -column 1 -row $r -sticky w
	grid [ttk::label .testas.i.label2 -text "PAVARDĖ:" -padding "10 10 10 10"] -column 0 -row $r -sticky w; incr r
	grid [ttk::entry .testas.i.klase -textvariable klase] -column 1 -row $r -sticky w
	grid [ttk::label .testas.i.label3 -text "KLASĖ:" -padding "10 10 10 10"] -column 0 -row $r -sticky w; incr r
	if {$::ar_pazymiui == 1} {
		set mygtuko_tekstas "Pradėti testą"
	} else {
		set mygtuko_tekstas "Toliau >"
	}
	grid [ttk::button .testas.i.button2 -style big.TButton -text $mygtuko_tekstas -command "patikrinimas $r" -padding "5 5"] -column 0 -columnspan 2 -row $r
	#bind . <Return> ".testas.i.button2 invoke"
}

proc patikrinimas {r} {
	incr r
	destroy .testas.i.ispejimas
	set vardas "[.testas.i.vardas get]"
	set vardoilgis "[string length $vardas]"
	set pavarde "[.testas.i.pavarde get]"
	set pavardesilgis "[string length $pavarde]"
	set klase "[.testas.i.klase get]"
	set klasesilgis "[string length $klase]"
	if {$vardoilgis == 0 || $pavardesilgis == 0 || $klasesilgis == 0} {
		grid [ttk::label .testas.i.ispejimas -text {Reikia užpildyti visus laukelius.} -style red.TLabel -padding "3 3"] -column 0 -columnspan 2 -row $r
		} else {
			db1 eval {INSERT INTO m_options(pavadinimas, reiksme) VALUES("įvestas vardas", $vardas)}
			db1 eval {INSERT INTO m_options(pavadinimas, reiksme) VALUES("įvesta pavardė", $pavarde)}
			db1 eval {INSERT INTO m_options(pavadinimas, reiksme) VALUES("įvesta klasė", $klase)}
			Klausimo_piesimas 1 0
		}
}
#KLAUSIMŲ PIEŠIMAS:
proc Klausimo_piesimas {k buves_kl} {
	destroy .testas.i
	destroy .testas.t
	grid [ttk::frame .testas.t]
	set i 1
	set klid [db1 onecolumn {SELECT klausimo_id FROM m_klausimai_testai WHERE klausimo_nr=$k}]
	set klausimas [db1 onecolumn {SELECT kl FROM m_klausimai WHERE Id=$klid}]
	set tipas [db1 onecolumn {SELECT tipas FROM m_klausimai WHERE Id=$klid}]
	set visi_klausimo_variantai [db1 eval {SELECT atsakymo_var FROM m_atsakymuvariantai WHERE klausimo_id=$klid}]
	set taskai [db1 onecolumn {SELECT verte_taskais FROM m_klausimai_testai WHERE klausimo_id=$klid}]
	if {$::ar_pazymiui == 1} {
		set klausimo_tekstas "$k. $klausimas ($taskai tšk.)"
		set paskut_mygtuk_tekstas "Išsaugoti ir pateikti atsakymus"
		set paskut_mygtuk_stilius "red.TButton"
	} else {
		set klausimo_tekstas "$k. $klausimas"
		set paskut_mygtuk_tekstas "Pateikti atsakymus"
		set paskut_mygtuk_stilius "green.TButton"
	}
	if {$tipas == "vienas_teisingas"} {
		set r 0
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
		if {![info exists ::klausimoats$k]} {
			set ::klausimoats$k [db1 eval {SELECT atsakymo_var FROM m_atsakymuvariantai WHERE klausimo_id=$klid AND pasirinko = 1}]
		}
		foreach variantas $visi_klausimo_variantai {
			grid [ttk::radiobutton .testas.t.$i -text "$variantas" -variable ::klausimoats$k -value "$variantas" -padding "20 5 5 5"] -column 0 -row $r -sticky w; incr i; incr r
			#db1 eval {UPDATE m_atsakymuvariantai SET pasirinko = "0" WHERE klausimo_id=$klid AND atsakymo_var=$variantas}
		}
	}
	if {$tipas == "atviras_kl"} {
		set r 0
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
			grid [ttk::label .testas.t.r -text "Rašyti atsakymą:" -padding "10 10"] -column 0 -row $r -sticky w; incr r
		} else {
			grid [ttk::label .testas.t.klausimas -text $klausimo_tekstas -padding "10 10 10 10" -wraplength $wrap] -column 0 -row $r -sticky we; incr r
		}
		grid [tk::text .testas.t.ivesti$i -width 60 -height 6] -column 0 -row $r -padx 10 -sticky we; incr r
		.testas.t.ivesti$i insert 0.0 [db1 onecolumn {SELECT atsakymo_var FROM m_atsakymuvariantai WHERE pasirinko = 1 AND klausimo_id=$klid}]
		.testas.t.ivesti$i mark set insert 0.0
		bind .testas.t.ivesti$i <KeyRelease> "p_limit_length .testas.t.ivesti$i"
		focus .testas.t.ivesti$i
		
	}
	if {$tipas == "keli_teisingi"} {
		set r 0
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
		foreach variantas $visi_klausimo_variantai {
			if {![info exists ::klausimoats${k}_$i]} {
				set ::klausimoats${k}_$i [db1 eval {SELECT CASE(pasirinko) WHEN 1 THEN atsakymo_var ELSE "" END FROM m_atsakymuvariantai WHERE klausimo_id=$klid AND atsakymo_var=$variantas}]
			}
			grid [ttk::checkbutton .testas.t.$i -text "$variantas" -variable ::klausimoats${k}_$i -onvalue "$variantas" -offvalue 0 -padding "20 5 5 5"] -column 0 -row $r -sticky w; incr r
			incr i
			#db1 eval {UPDATE m_atsakymuvariantai SET pasirinko = "0" WHERE klausimo_id=$klid AND atsakymo_var=$variantas}
		}
	}
	if {$k <= $::klausimu_skaicius} {
		grid [ttk::frame .testas.t.f] -column 0 -row $r -sticky news
		grid columnconfigure .testas.t.f 0 -weight 1
		grid columnconfigure .testas.t.f 1 -weight 1
		if {$k == 1} {
		incr r
		grid [ttk::button .testas.t.f.kitas -style average.TButton -text "Kitas klausimas >" -command "Ats_irasymas_i_db $i {$klausimas} $tipas $klid $k; Klausimo_piesimas [expr $k+1] $k" -padding $::pad10] -column 0 -row $r -pady 10 -padx 10 -sticky e
		}
		if {$k > 1} {
			incr r
			grid [ttk::button .testas.t.f.kitas -style average.TButton -text "Kitas klausimas >" -command "Ats_irasymas_i_db $i {$klausimas} $tipas $klid $k; Klausimo_piesimas [expr $k+1] $k" -padding $::pad10] -column 1 -row $r -pady 10 -padx 10 -sticky w
			grid [ttk::button .testas.t.f.ankstesnis -style average.TButton -text "< Ankstesnis klausimas" -command "Ats_irasymas_i_db $i {$klausimas} $tipas $klid $k; Klausimo_piesimas [expr $k-1] $k" -padding $::pad10] -column 0 -row $r -pady 10 -padx 10 -sticky e
		}
	}
	if {$k > $::klausimu_skaicius || $tipas == ""} {
		set r 0
		if {$::ar_pazymiui == 1} {
			set paskutinis_sakinys "Klausimai baigėsi. Pasirink vieną iš šių veiksmų:"
		} else {
			set paskutinis_sakinys "Apklausa baigėsi. Ačiū už atsakymus!"
		}
		grid [ttk::label .testas.t.pabaiga -text $paskutinis_sakinys -padding "10 10 10 10" -style big.TLabel] -column 0 -row $r -columnspan 2; incr r
		if {$::ar_pazymiui == 1} {
			grid [ttk::button .testas.t.darkarta -style big.TButton -text "Peržiūrėti klausimus iš naujo" -image reload -compound left -command "Klausimo_piesimas 1 0" -padding $::pad20 -width 35] -column 0 -row $r -pady 10 -padx 10
		}
		incr r
		grid [ttk::button .testas.t.visiskaibaigti -style $paskut_mygtuk_stilius -text $paskut_mygtuk_tekstas -image save -compound left -command "Sunaikinti" -padding $::pad20 -width 35] -column 0 -row $r -pady 10 -padx 10
	}
}

proc Ats_irasymas_i_db {i klausimas tipas nr k} {
	db1 onecolumn {UPDATE m_atsakymuvariantai SET pasirinko=0 WHERE klausimo_id=$nr}
	if {$tipas == "atviras_kl"} {
		set atsakymas "[.testas.t.ivesti$i get 1.0 end]"
		db1 onecolumn {UPDATE m_atsakymuvariantai SET atsakymo_var=$atsakymas WHERE klausimo_id=$nr AND ar_teisingas_var=0}
		db1 onecolumn {UPDATE m_atsakymuvariantai SET pasirinko=1 WHERE klausimo_id=$nr AND ar_teisingas_var=0}
		}
	if {$tipas == "vienas_teisingas"} {
		if {[info exists ::klausimoats$k]} {
			set atsakymas [set ::klausimoats$k]
			db1 eval {UPDATE m_atsakymuvariantai SET pasirinko = "1" WHERE klausimo_id=$nr AND atsakymo_var=$atsakymas}
		}
	}
		
	if {$tipas == "keli_teisingi"} {
		for {set j 1} {$j < $i} {incr j} {
			if {![info exists ::klausimoats${k}_$j]} {
				set ::klausimoats${k}_$j ""
			}
			set atsvar [set ::klausimoats${k}_$j]
			db1 eval {UPDATE m_atsakymuvariantai SET pasirinko = "1" WHERE klausimo_id=$nr AND atsakymo_var=$atsvar}
		}
	}
}

proc p_limit_length {text_field} {
	set text [string range [$text_field get 1.0 {end -1 chars}] 0 300]
	$text_field replace 0.0 end $text
}

proc Sunaikinti {} {
	catch {
		puts "$::pc baigė testą"
	}
	destroy .testas.pabaiga .
	if {$::ar_pazymiui == 1} {
		exec /skriptai/atsakymai.tcl
	}
}

if {[db1 onecolumn {SELECT COUNT(*) FROM m_atsakymuvariantai WHERE pasirinko = "1"}]} {
	Klausimo_piesimas 1 0
} else {
	if {$::ar_pazymiui == 1} {
		set galune [p_galunes_parinkimas $::klausimu_skaicius]
		if {$::atviru_klausimu_sk == 0} {
			set tekstas "Dėmesio, testas prasideda! \n\nTestą sudaro $::klausimu_skaicius klausim$galune."
		} else {
			set tekstas "Dėmesio, testas prasideda! \n\nTestą sudaro $::klausimu_skaicius klausim$galune.\n \n Jei rašysi su LIETUVIŠKOMIS RAIDĖMIS, \n prie gauto pažymio bus pridėtas 1 balas.\n Jei lietuviškų raidžių nenaudosi, \nnuo gauto pažymio bus nuimtas 1 balas."
		}
		grid [ttk::frame .testas.p]
		grid [ttk::label .testas.p.ispejimas -style big.TLabel -text $tekstas -padding "20 20"] -column 0 -row 0
		grid [ttk::button .testas.p.testi -text "Tęsti" -style big.TButton -command "p_tikrinam_mok_duomenis" -padding "5 5"] -column 0 -row 1
		#bind . <Return> ".testas.p.testi invoke"
	} else {
		p_tikrinam_mok_duomenis
	}
}
