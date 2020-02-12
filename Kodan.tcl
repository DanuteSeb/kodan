#!/usr/bin/wish
#sukuriame šios dienos datą, kad būtų galima pritaikyti mokinių neištaisytiems darbams, kai yra sukuriamas aplankas su šios dienos data.
set systemTime [clock seconds]
set ::siandiena "[clock format $systemTime -format {%Y-%m-%d}]"
#jeigu reiktų pakeisti dieną, pakeisti šį šiandienos kintamąjį BEI susirasti kode vietą, kur yra žodelis today ir paskaityti ten komentarą.
#----------------------------------------------------------------------------------------------------------------------------------------------
proc CONST { key } {
	array set constant {
		ACT_REBOOT  1
		ACT_SHUTDOWN  2
		ACT_BLOCK 3
		ACT_UNBLOCK 4
		ACT_BLOCKPAGE 5
		ACT_UNBLOCKPAGE 6
		ACT_GRADED 7
		ACT_KILLCHAT 8
		ACT_REMOVE 9
		ACT_KILLAPPS 10
		ACT_WALLP 11
		ACT_OPTIONS 12
		ACT_COMMAND 13
		ACT_UNMOUNT 14
		ACT_MESSAGE 15
		ACT_QUESTION 16
		ACT_ENDLESSON 17
	}
	return $constant($key)
}
package require Tk
option add *Dialog.width 500
package require struct::set
package require struct
# package require Tktable
# package require Thread
#kad renkantis failą nerodytų hidden files:
catch {tk_getOpenFile foo bar}
set ::tk::dialog::file::showHiddenVar 0
set ::tk::dialog::file::showHiddenBtn 1
package require sqlite3
wm title . "Kodan"
wm resizable . 0 0
ttk::setTheme clam
#set plotis [expr {([winfo screenwidth .]-[winfo width .])/2}]
#set aukstis [expr {([winfo screenheight .]-[winfo height .])/2}]
#wm geometry . +230+90
#tearoff komanda yra skirta lango kortelėms, kad jas nupieštų.
option add *tearOff 0
#čia pakeičia open file lango dydį - kurį rodo norint pasirinkti failą siuntimui.
rename ::tk::dialog::file::Create ::tk::dialog::file::CreateOriginal
proc ::tk::dialog::file::Create {type args} {
     eval ::tk::dialog::file::CreateOriginal $type $args
     wm geometry $type 750x500 
}
#----------------------------------------------------------------------------------------------------------------------------------------------
#čia yra visos duomenų bazės lentelės. Jeigu jos neegzistuoja (tarkim programa paleidžiama pirmą kartą), jos yra sukuriamos
sqlite3 db3 ./db
sqlite3 db1 ./nustatymai
db1 eval {CREATE TABLE if not exists kompiuteriai_check(Id integer primary key, ar_ivesta integer)}
db1 eval {CREATE TABLE if not exists klases_check(Id integer primary key, ar_ivesta integer)}
db1 eval {CREATE TABLE if not exists aplankai_check(Id integer primary key, ar_ivesta integer)}
db1 eval {CREATE TABLE if not exists mokiniai_check(Id integer primary key, ar_ivesta integer)}
db1 eval {CREATE TABLE if not exists default_aplankai_check(Id integer primary key, ar_ivesta integer)}
db3 eval {CREATE TABLE if not exists kompiuteriai(Id integer primary key autoincrement, pc text, display text)}
db3 eval {CREATE TABLE if not exists klausimai(Id integer primary key autoincrement, kl text, tipas text, pav_id integer, CONSTRAINT uniq_kl UNIQUE (kl))}
db3 eval {CREATE TABLE if not exists atsakymuvariantai(Id integer primary key autoincrement, klausimo_id integer, atsakymo_var text, ar_teisingas_var text, tsk_jei_pasirinko integer, tsk_jei_nepasirinko integer, pav_id integer)}
db3 eval {CREATE TABLE if not exists testai(Id integer primary key autoincrement, testo_pavad text unique, klase integer)}
db3 eval {CREATE TABLE if not exists klausimai_testai(testo_id integer, klausimo_id integer, klausimo_nr integer, verte_taskais integer)}
db3 eval {CREATE TABLE if not exists mokiniai(Id integer primary key autoincrement, vardas text, pavarde text, klases_id text, pc_id integer, pastabos text, esamas_ar_buves text)}
db3 eval {CREATE TABLE if not exists bandymai(Id integer primary key autoincrement, mokinio_id integer, testo_id integer, data text, ar_istaisyta integer, penalty_tsk integer, pc text, pazymys integer)}
db3 eval {CREATE TABLE if not exists bandymai_pasirinkimai(Id integer primary key autoincrement, bandymo_id integer, atsvar_id integer, atsakymo_tekstas text, tsk integer, ar_pasirinko text)}
db3 eval {CREATE TABLE if not exists bandymai_options(bandymo_id integer, pavadinimas text, reiksme text)}
db3 eval {CREATE TABLE if not exists klases(Id integer primary key autoincrement, klase text unique)}
db3 eval {CREATE TABLE if not exists destomos_klases(Id integer primary key autoincrement, klase text unique)}
db3 eval {CREATE TABLE if not exists pagrindiniai_aplankai(koksapl text unique, apl text)}
db3 eval {CREATE TABLE if not exists paveiksleliai(Id integer primary key autoincrement, pavad text, content text, md5 text)}
db3 eval {CREATE TABLE if not exists tagai(Id integer primary key autoincrement, name text, type text)}
db3 eval {CREATE TABLE if not exists tagai_klausimai(tag_id integer, klausimo_id integer)}
db3 eval {CREATE TABLE if not exists tagai_testai(tag_id integer, testo_id integer)}
db3 eval {CREATE TABLE if not exists tagai_mokiniai(tag_id integer, mokinio_id integer)}
db3 eval {CREATE TABLE if not exists current_pc_setup(pc_id integer primary key autoincrement, mok_id integer, var integer, ar_primountinta integer, testo_id integer, atsiskaitymas integer, ar_alien integer)}
db3 eval {CREATE TABLE if not exists spalvos(spalva text)}
db3 eval {CREATE TABLE if not exists options(name text, value integer)}
db3 eval {CREATE TABLE if not exists version(nr text)}
db3 eval {CREATE TABLE if not exists pamokos(Id integer primary key autoincrement, data text, nr integer, pabaigos_laikas text)}
db3 eval {CREATE TABLE if not exists tagai_pamokos(tag_id integer, pamokos_id integer)}
db3 eval {CREATE TABLE if not exists mokymosi_tagai(mokinio_id integer, pamokos_id integer, tag_id integer)}
#----------------------------------------------------------------------------------------------------------------------------------------------
#čia yra visi programos paveiksliukai.
#komanda dict padaro "dictionary", kuriame galima surašyti visus reikalingus dalykus, o po to juos iš ten "pasiimti". Čia taip yra padaryta su paveiksliukais.
set icons [dict create\
	testgraded "TestGraded.png" pc_icon_small "PC_small.png" app_icon "App_close.png" chat_icon "Chat.png" network32 "Network.png" network32close "Network_close.png" new_test_icon "Test_new.png" pc1 "PC1var.png" pc2 "PC2var.png" pc3 "PC3var.png" pc4 "PC4var.png" pcfopen "PCfopen.png" pctable "PCtable.png" pctabledone "PCtable-atlikta.png" pctest "PCtest.png" file_icon "Download_file.png" check_icon "Check.png" var1 "var1.png" var2 "var2.png" var3 "var3.png" var4 "var4.png" res32 "Restart32.png" res16 "Restart16.png" shutdown_icon "Shutdown.png" killchat_icon "Killchat.png" terminal_icon "Terminal.png" pcneutral "PCneutral.png" arrow_l "Arrow_left.png" pcunr "PCunr.png" pccheck "PCcheck.png" table "Table.png" upd32 "Update.png" wall_icon "Wallpaper.png" tool_icon "Tools.png" rem32 "Del32.png" rem16 "Del16.png" ad16 "Plus16.png" ad32 "Plus32.png" arrow_r "Arrow_right.png" ed32 "edit32.png" ed16 "edit16.png" prev32 "preview32.png" save_icon "Save.png" back_icon "Back.png" pie_icon "Pie.png" klaus32 "Question32.png" klaus24 "Question24.png" rem8 "Del8.png" gallery_icon "Gallery.png" arrowdown "Arrowdown.png" test_icon "Test.png" mailsend "MailSend.png" test_check_icon "Test_check.png" class_icon "Class.png" clock_icon "clock.png" trash_icon "Trash_file.png" testing_icon "Test_testing.png" pctestatlikta "PCtest-atlikta.png" user16 "user16.png" user32 "user32.png" upload_icon "Upload.png" hide_icon "Hide.png" downl_icon "Download.png" show_icon "Show.png" block_icon "Site_block.png" unblock_icon "Site_unblock.png" mouse "mouse.png" pcapklausa "PCapklausa.png" test_down_icon "Test_download.png" tabledown "TableDown.png" textfield "Textfield.png" vienas "VienasTeisingas.png" keli "KeliTeisingi.png" chart_icon "ChartVertical.png" tablesmall "TableSmall.png" prev16 "preview16.png" correct "correct.png" today_icon "Today.png" test_edit "Test_edit.png" palette "palette.png" create_icon "CreateFolder.png"]
dict for {var_name file_name} $icons {
	image create photo $var_name -file "icons/$file_name"
}
#--------------------------PRISIJUNGIMAS PRIE PC---------------------------------------------------
proc read_from_pc {nr} {
	if {[chan eof [set ::chan$nr]]} {
		chan close [set ::chan$nr]
		p_icon_keitimas $nr pcunr
		puts "read_from_pc closed connection to $nr"
		return
	}
	#take off newline at the end too...
	set line [string range [chan read [set ::chan$nr]] 0 end-1]
	if {[regexp {^ping[0-9]+} $line]} {
		set ::pinger$nr [string range $line 4 end]
	} elseif {$line == "task_ended"} {
		puts "Atsiskaitymo pabaiga $nr"
		p_atsiskaitymas_uzbaigtas $nr
		#@todo XXX do task ended stuff, likely call collect results
	} elseif {$line == "test_ended"} {
		puts "Testas baigtas $nr"
		p_testas_uzbaigtas $nr
	}
	set pcnr [expr $nr + 1]
	puts "PC $pcnr sako $line"
}

proc p_prisijungimas_prie_pc {nr} {
	proc read_from_pc$nr {} "read_from_pc $nr"
	set ip [db3 eval "SELECT pc FROM kompiuteriai WHERE id=[expr $nr + 1]"]
	set ::chan$nr [open |[list ssh -o ConnectTimeout=1 mokytoja@$ip sh -i] r+]
	chan configure [set ::chan$nr] -buffering line -blocking false
	chan event [set ::chan$nr] readable read_from_pc$nr
	#These are for continuing monitoring of test end in case connection was lost and program reconnects to pupils PCs. Not fool proof though... if test ended while connection is out nothing would happen (I think), and manuall collection of results might be needed
	p_send_command $nr {tail -f --pid $(pidof -x atsiskaitymas.tcl) /dev/null 2>/dev/null && echo task_ended &}
	p_send_command $nr {tail -f --pid $(pidof -x Testas.tcl) /dev/null 2>/dev/null && echo test_ended &}
	#p_pinger $nr
}

proc p_prisijungimas_prie_visu_pc {} {
	for {set nr 0} {$nr < [llength [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]]} {incr nr} {
		p_prisijungimas_prie_pc $nr
	}
}

proc p_atsijungimas_nuo_pc {} {
	set visi_ip_adresai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	for {set nr 0} {$nr < [llength $visi_ip_adresai]} {incr nr} {
		if {[info exists ::chan$nr]} {
			chan close [set ::chan$nr]
		}
	}
}

proc p_send_command {nr command} {
	if {[chan names [set ::chan$nr]] != ""} {
		chan puts [set ::chan$nr] $command
	}
}

#unused bet geriau netrinti kolkas
proc p_pinger {nr} {
	if {[chan names [set ::chan$nr]] == ""} {
		#puts "Connection ([set ::chan$nr]) to PC $nr found to be closed!"
		.kompiuteriai.c$nr configure -image pcunr
		return	
	}
	if {[info exists ::pinger$nr] && [set ::pinger$nr] != [set ::pinger_seq$nr]} {
		incr ::pinger_wait$nr
		puts "Failed to ping!"
		if {[set ::pinger_wait$nr] > 7} { #28 seconds without response
			chan close [set ::chan$nr]
			puts "pinger closed connection to $nr"
			.kompiuteriai.c$nr configure -image pcunr
		}
	} else {
		incr ::pinger_seq$nr
		set ::pinger_wait$nr 1
	}
	p_send_command $nr "echo ping[set ::pinger_seq$nr]"		
	after [expr [set ::pinger_wait$nr] * 1000] "p_pinger $nr"
}
#----------------------------------------------------------------------------------------------------------------------------------------------
#globalūs daug kur naudojami kintamieji
set ::pad20 "20 20 20 20"
set ::pad10 "10 10 10 10"
set ::pad5 "5 5 5 5"
set ::variantusk [db3 onecolumn {SELECT MAX(var) FROM current_pc_setup}]
set ::ar_ikelti_mokiniu_failus 0
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_atnaujinti_versija {} {
	#ši procedūra skirta tik tam atvejui, jeigu žmogus jau naudojo šią programą ir programa buvo drastiškai atnaujinta – pvz. pakeistos kokios nors lentelės, t.y. jeigu jose yra pridedami nauji stulpeliai ar kitokie duomenys
	set version_old [db3 onecolumn {SELECT nr FROM version}]
	set version_new 2.4
	if {$version_old == ""} {
		set version_old 2.4
		db3 eval {INSERT OR REPLACE INTO version(nr) VALUES ($version_old)}
	}
	set version_current [db3 onecolumn {SELECT nr FROM version}]
	if {$version_new > $version_old} {
		db3 eval "UPDATE version SET nr=$version_new"
	}
	if {$version_current < 2.4} {
		#čia bus pridedamas kodas, kurį bus būtina įvykdyti, atnaujinant programos versiją
		#db3 eval {DROP TABLE kompiuteriai}
		#db3 eval {DROP table current_pc_setup}
		#db3 eval {DROP TABLE display}
		#db1 eval {UPDATE kompiuteriai_check SET ar_ivesta="0"}
		tk_messageBox -message "Programos versija atnaujinama. Paleiskite ją iš naujo"
		exit
		destroy .
	}
	
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
#daug kur naudojamos procedūros, naudojamos failų siuntimams, susijungimui su mokinių kompiuteriais ir panašiai:
proc cant_ping {pc} {
#jei kompiuteris nepasiekiamas, grąžina klaidą
	return [catch {exec -ignorestderr ping -c 1 -w 1 -q $pc}]
}
proc ar_testi {} {
	if {$::testi == 0} {
		return 0
	} else {
		return 1
	}
}
proc p_ar_tikrai {klausimas pabaigos_skriptas} {
#paklausia, ar tikrai norite atlikti šį veiksmą. Jei taip, tai veiksmas vykdomas, jei ne – nevykdomas.
	p_naujas_langas .artikrai "Klausimas"
	wm attribute .artikrai -topmost 1
	wm protocol .artikrai WM_DELETE_WINDOW {
		destroy .artikrai
		set ::testi 0
	}
	grid [ttk::frame .artikrai.klausimas -padding $::pad20] -column 0 -row 0 -sticky nwes
	set r 1
	grid [ttk::label .artikrai.klausimas.txt -text "$klausimas" -padding "5 5" -style didelis.TLabel -wraplength 350] -column 0 -columnspan 2 -row $r; incr r
	grid [ttk::button .artikrai.klausimas.taip -text "Taip" -command "destroy .artikrai; $pabaigos_skriptas" -padding $::pad10 -style zalias.TButton] -padx 1 -pady 1 -column 0 -row $r
	grid [ttk::button .artikrai.klausimas.ne -text "Ne" -style raudonas.TButton -command "destroy .artikrai; set ::testi 0" -padding $::pad10] -padx 1 -pady 1 -column 1 -row $r; incr r
	tkwait window .artikrai
}
proc p_tikrinti_ivedima {kintamasis zinute} {
#tikrina, ar užpildytas laukelis. Jei taip, išveda teisingą rezultatą, jei ne – klaidingą
	if {![info exists $kintamasis]} {
		p_naujas_langas .arivesta "Įspėjimas"
		wm attribute .arivesta -topmost 1
		grid [ttk::frame .arivesta.ispejimas -padding $::pad20] -column 0 -row 0 -sticky nwes
		grid [ttk::label .arivesta.ispejimas.zinute -text "$zinute" -style didelis.TLabel] -pady 10 -column 0 -row 0
		grid [ttk::button .arivesta.ispejimas.ok -text "Gerai" -command "destroy .arivesta" -style mazas.TButton] -pady 10 -column 0 -row 1
		return 0
	} else {
		return 1
	}
}
proc p_replace_spaces {f v i t} {
#f - Field; v - Value (char being inserted); i - position/Index of edit; t - Type of edit(1 for insert)
#vietoje zmogaus parasytu tarpeliu padeda apatini bruksni, kad butu isvengta daug klaidu ivairiose vietose
#kaip naudoti: -validate key -validatecommand {p_replace_spaces %W %S %i %d}
	if {$t == 1} {
		$f insert $i [regsub { } $v {_}]
	}
	return 1
}

proc p_icon_keitimas {nr icon {force 0}} {
	#$icon == "pcunr" is there to ensure that connect binding happens/replaces any other binding
	if {$force || [.kompiuteriai.c$nr cget -image] != "pcunr" || $icon == "pcunr"} {
		.kompiuteriai.c$nr configure -image $icon
		if {$icon == "pcunr"} {
			bind .kompiuteriai.c$nr <3> "p_prisijungimas_prie_pc $nr; p_update_pc_status $nr 1"
		}
		update idletasks
	}
}

proc p_naujas_langas {w pavadinimas} {
	toplevel $w
	wm resizable $w 0 0
	wm title $w $pavadinimas
}
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_clean_string {s} {
#failų ir aplankų ar kituose pavadinimuose esančius tarpus pakeičia į _
	return [regsub -nocase -all {[^a-z0-9]} $s _]
}
# extend a command with a new subcommand
proc extend {cmd body} {
#kol kas niekur nenaudojama procedūra
    set wrapper [string map [list %C $cmd %B $body] {
        namespace eval %C {}
        rename %C %C::%C
        namespace eval %C {
            proc _unknown {junk subc args} {
                return [list %C::%C $subc]
            }
            %B
            namespace export -clear *
            namespace ensemble create -unknown %C::_unknown
        }
    }]
    uplevel \#0 $wrapper
}
#----------------------------------------------------------------------------------------------------------------------------------------------
#stiliai:
proc p_pakeisti_spalva {spalva} {
	if {$spalva == "Žalia"} {
		set s "lightgreen"
	}
	if {$spalva == "Žydra"} {
		set s "#8dd4f4"
	}
	if {$spalva == "Oranžinė"} {
		set s "#f4b186"
	}
	if {$spalva == "Pilka"} {
		set s "#c1c5bf"
	}
	if {$spalva == "Violetinė"} {
		set s "#c895c0"
	}
	if {$spalva == "Rožinė"} {
		set s "pink"
	}
	db3 eval {UPDATE spalvos SET spalva=$s}
	tk_messageBox -message "Mygtukų spalva pasikeis, kai paleisite programą iš naujo." -parent .n
	exit
}
set ::spalva [db3 onecolumn {SELECT spalva FROM spalvos}]
if {$::spalva == ""} {
	set ::spalva "light blue"
}
set fono_spalva "#f5f6f7"
set irasymo_spalva "#aee575"
ttk::style configure TButton -background $::spalva -font "ubuntu 13 bold" -bordercolor $::spalva -lightcolor $::spalva -darkcolor $::spalva
ttk::style map TButton -background [list active "white" disabled "light grey"]
ttk::style map TButton -bordercolor [list active "black" disabled "light grey"]
ttk::style map TButton -lightcolor [list active "white" disabled "light grey"]
ttk::style map TButton -darkcolor [list active "white" disabled "light grey"]
ttk::style configure raudonas.TButton -background "tomato" -bordercolor "tomato" -lightcolor "tomato" -darkcolor "tomato"
ttk::style configure mazasraudonas.TButton -font "ubuntu 10" -background "tomato" -bordercolor "tomato" -lightcolor "tomato" -darkcolor "tomato"
ttk::style configure mazas.TButton -font "ubuntu 10"
ttk::style configure permatomas.TButton -font "ubuntu 10" -background $fono_spalva -bordercolor $fono_spalva -lightcolor $fono_spalva -darkcolor $fono_spalva
ttk::style configure mazaszalias.TButton -font "ubuntu 10" -background $irasymo_spalva -bordercolor $irasymo_spalva -lightcolor $irasymo_spalva -darkcolor $irasymo_spalva
ttk::style configure zalias.TButton -background $irasymo_spalva -bordercolor $irasymo_spalva -lightcolor $irasymo_spalva -darkcolor $irasymo_spalva
ttk::style configure TLabel -background $fono_spalva -font "ubuntu 10"
ttk::style configure vidutinis.TLabel -font "ubuntu 11"
ttk::style configure didelis.TLabel -font "ubuntu 13"
ttk::style configure pilkas.TLabel -foreground "grey"
ttk::style configure baltas.TLabel -background "white"
ttk::style configure melynas.TLabel -foreground "blue"
ttk::style configure TCheckbutton -background $fono_spalva -font "ubuntu 10"
ttk::style map TCheckbutton -background [list active "white"]
ttk::style configure TRadiobutton -background $fono_spalva -font "ubuntu 10"
ttk::style configure TCombobox -bordercolor $::spalva -background $::spalva
ttk::style map TCombobox -background [list active $::spalva]
ttk::style map TCombobox -fieldbackground [list readonly $fono_spalva active $::spalva]
ttk::style map TCombobox -foreground [list readonly "black"]
option add *TCombobox*Listbox.selectBackground $::spalva
ttk::style configure TFrame -background $fono_spalva
ttk::style configure baltas.TFrame -background "white"
ttk::style configure raudonas.TFrame -background "red"
ttk::style configure melynas.TFrame -background "blue"
ttk::style configure TEntry -selectbackground $::spalva -bordercolor $::spalva
ttk::style configure TNotebook.Tab -font "ubuntu 13" -bordercolor "grey"
ttk::style configure TNotebook -background "white" -lightcolor "white" -darkcolor "white" 
ttk::style map TNotebook.Tab -background [list selected "white" active $fono_spalva disabled "grey"]
ttk::style configure TMenubutton -background "white"
. configure -background $fono_spalva
#----------------------------------------------------------------------------------------------------------------------------------------------
#grafikos nustatymai – jų reikia naudojant skirtingas grafines aplinkas, pvz.: Gnome, Kde ir kt.
#set ::grafika [db3 onecolumn {SELECT variantas FROM display}]
#----------------------------------------------------------------------------------------------------------------------------------------------
#notebook sukuria lango korteles, .n yra pagrindinis langas, kuriame bus lango kortelės.
grid [ttk::notebook .n]
ttk::frame .n.f1 -padding $::pad20 -style baltas.TFrame
ttk::frame .n.f2 -padding $::pad20 -style baltas.TFrame
ttk::frame .n.f4 -padding $::pad20 -style baltas.TFrame
ttk::frame .n.f5 -padding $::pad20 -style baltas.TFrame
ttk::frame .n.f6 -padding $::pad20 -style baltas.TFrame
.n add .n.f1 -text "Pamokos veiksmai" 
.n add .n.f2 -text "Variantai"
.n add .n.f4 -text "Kiti veiksmai"
.n add .n.f5 -text "Kompiuterių tvarkymas"
.n add .n.f6 -text "Testai"
#----------------------------------------------------------------------------------------------------------------------------------------------
#čia yra kuriamas lango meniu:
menu .n.menubar
tk_menuSetFocus .n.menubar
. configure -menu .n.menubar
set m .n.menubar
$m configure -background $fono_spalva -activebackground "lightgrey" -selectcolor "light blue" -font "TkDefaultFont 9"
option add *Menu.font fontSize 8
menu $m.file
menu $m.options
menu $m.tvarkymas
menu $m.sys
menu $m.help
#pastaba: underline reiškia, kad bus pabraukta kuri nors meniu punkto raidė. 0 - pirma raidė, 1 - antra raidė, 2 - trečia raidė ir t.t. Pabraukta reiškia ALT+raidė, kad galėtume atverti meniu.
$m add cascade -menu $m.file -label Failas -underline 0
$m add cascade -menu $m.options -label Nustatymai -underline 0
$m add cascade -menu $m.tvarkymas -label Tvarkymas -underline 1
$m add cascade -menu $m.sys -label Sistema -underline 0
$m add cascade -menu $m.help -label Žinynas -underline 1
$m.file add command -label "Užverti" -command "destroy ."
$m.help add command -label "Pagalba" -command "p_pagalba"
$m.help add command -label "Apie" -command "p_apie"
$m.sys add command -label "Administratoriui..." -command "p_admin_langas"
$m.options add command -label "Kompiuteriai ir IP adresai..." -command "p_ip_adresu_suvedimo_langas 0"
$m.options add command -label "Klasės..." -command "p_pirmuju_klasiu_ivedimas ne"
$m.options add command -label "Mokiniai..." -command "p_mokiniu_redagavimo_laukeliai \"\""
$m.options add command -label "Numatytieji aplankai..." -command "p_numatytu_aplanku_kurimo_pradzia ne"
$m.options add command -label "Kompiuterių paruošimas darbui..." -command "p_aplankai ne"
$m.options add command -label "Žymos..." -command "p_tagu_kurimas"
$m.options add command -label "Mokytojo duomenys..." -command "p_mokytojo"
$m.options add command -label "Spalvos..." -command "p_spalvos"
$m.tvarkymas add command -label "Išvalyti įsimintus veiksmus" -command "p_isvalyti_veiksmus"
$m.tvarkymas add command -label "Perkurti klasių aplankus" -command "p_klasiu_aplanku_kurimas .neegzistuoja ne"
$m.tvarkymas add command -label "Prijungti kompiuterius iš naujo" -command "p_atsijungimas_nuo_pc; after 5000; p_prisijungimas_prie_visu_pc"
#----------------------------------------------------------------------------------------------------------------------------------------------
# set pirmas_programos_paleidimas [db1 onecolumn {SELECT arpirmas FROM ar_pirma_karta}]
# set default_aplankai_check [db1 onecolumn {SELECT ar_ivesta FROM default_aplankai_check}]
#patikrinimai paleidžiant programą:
proc p_pirmas_programos_paleidimas {} {
	set kompiuteriai_check [db1 onecolumn {SELECT ar_ivesta FROM kompiuteriai_check WHERE Id=1}]
	set klases_check [db1 onecolumn {SELECT ar_ivesta FROM klases_check WHERE Id=1}]
	set aplankai_check [db1 onecolumn {SELECT ar_ivesta FROM aplankai_check WHERE Id=1}]
	set mokiniai_check [db1 onecolumn {SELECT ar_ivesta FROM mokiniai_check WHERE Id=1}]
	if {$kompiuteriai_check == "" || $klases_check == "" || $aplankai_check == "" || $mokiniai_check == "" || $kompiuteriai_check == 0 || $klases_check == 0 || $aplankai_check == 0 || $mokiniai_check == 0} {
		set w ".pirmask"
		p_naujas_langas $w "Pirmas programos paleidimas"
		wm attribute $w -topmost 1
		wm protocol .pirmask WM_DELETE_WINDOW { }
		set r 0
		set mygtukas "Tęsti"
		grid [ttk::frame $w.var -padding $::pad20] -column 0 -row 0
		grid [ttk::label $w.var.tekstas -text "Panašu, jog naudojate programą pirmą kartą arba yra dingę programai svarbūs failai. LABAI SVARBU: įsitikinkite, kad visi mokinių kompiuteriai yra įjungti ir kad yra įvykdyta viskas, kas parašyta README.txt faile. Dabar vyks programos paruošimas darbui. Spauskite mygtuką „$mygtukas“." -style didelis.TLabel -wraplength 350] -column 0 -row $r -pady 10; incr r
		grid [ttk::button $w.var.taip -text "$mygtukas >" -command "destroy $w; p_programos_paruosimas \"$kompiuteriai_check\" \"$klases_check\" \"$aplankai_check\" \"$mokiniai_check\"" -style mazaszalias.TButton] -column 0 -row $r -pady 10
	}
}

proc p_programos_paruosimas {kompiuteriai_check klases_check aplankai_check mokiniai_check} {
	set spalva "light blue"
	db3 eval {INSERT OR REPLACE INTO spalvos(spalva) VALUES ($spalva)}
	if {$kompiuteriai_check == "" || $kompiuteriai_check == 0} {
		p_komp_perziura
		return
	}
	if {$klases_check == "" || $klases_check == 0} {
		p_pirmuju_klasiu_ivedimas pirmas
		return
	}
	if {$aplankai_check == "" || $aplankai_check == 0} {
		p_aplanku_kurimas pirmas .aplanku
		return
	}
	if {$mokiniai_check == "" || $mokiniai_check == 0} {
		#p_mokiniu_redagavimo_laukeliai ""
		tk_messageBox -message "Norint, kad programa veiktų sklandžiai, kiekvienai klasei reikia priskirti mokinius ir jų sėdėjimo vietas. Tai galite atlikti nuspaudę meniu Nustatymai -> Mokiniai..."
		return
	}
}

proc p_check {} {
	set kompiuteriai_check [db1 onecolumn {SELECT ar_ivesta FROM kompiuteriai_check}]
	set klases_check [db1 onecolumn {SELECT ar_ivesta FROM klases_check}]
	set aplankai_check [db1 onecolumn {SELECT ar_ivesta FROM aplankai_check}]
	set mokiniai_check [db1 onecolumn {SELECT ar_ivesta FROM mokiniai_check}]
	p_programos_paruosimas $kompiuteriai_check $klases_check $aplankai_check $mokiniai_check
}
#sekanti procedūra patikrina dabartinę programos versiją ir, jeigu reikia, ją atnaujina. Bet pakeičiant versiją būtina į tą procedūrą įrašyti, kokia dabar bus versija ir, jei yra pakeitimų su duombaze, pridėti naują ciklą, kas keičiasi.
p_atnaujinti_versija
#sekanti procedūra paleidžiama kaskart paleidus programą. Ji patikrina, ar programa yra paleidžiama pirmą kartą ir ar visi reikalingi duomenys yra suvesti.
p_pirmas_programos_paleidimas
#sekančio kintamojo būtinai reikia, nes pagal jį yra nupiešiami visi programos kompiuteriai
set visi_ip_adresai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]

p_prisijungimas_prie_visu_pc
# after 5000 {chan puts $::chan0 w}
#----------------------------------------------------------------------------------------------------------------------------------------------
#čia procedūros, kurios susijusios tik su meniu:
proc p_apie {} {
	set w .apie
	p_naujas_langas $w "Apie programą"
	set version [db3 onecolumn {SELECT nr FROM version}]
	#set link [file link $w.programa.lbl ./licenses.txt]
	grid [ttk::frame $w.programa -padding "20 20 20 20"] -column 0 -row 0
	grid [ttk::label $w.programa.version -text "Kodan $version" -image pc_icon_small -compound top] -column 0 -row 0 -pady 10 -padx 20
	grid [ttk::label $w.programa.author -text "Sukūrė: Danutė Sebeckytė, 2014–2017\nPiktogramos paimtos iš: www.iconspedia.com, www.flaticon.com\nPiktogramų licencijas galite peržiūrėti faile licenses.txt."] -column 0 -row 1 -pady 10 -padx 20
}

proc p_pagalba {} {
	set w .pagalba
	p_naujas_langas $w "Pagalba"
	grid [ttk::frame $w.programa -padding "20 20 20 20"] -column 0 -row 0
	grid [ttk::label $w.programa.lbl -text "Piktogramų reikšmės:"] -column 0 -row 1 -pady 10 -padx 20
	grid [ttk::button $w.programa.btn -text "" -image klaus32 -command "destroy $w; p_pagalba_piktogramos"] -column 1 -row 1
}

proc p_pagalba_piktogramos {} {
	set w .pagalba
	p_naujas_langas $w "Pagalba"
	set r 0
	grid [ttk::frame $w.f -padding "20 20 20 20"] -column 0 -row $r; incr r
	grid [ttk::label $w.f.lbl -text "Piktogramų reikšmės:"] -column 0 -row $r -pady 10 -padx 20 -columnspan 2; incr r
	grid [ttk::label $w.f.unrimg -text "" -image pcunr] -column 0 -row $r -pady 10 -padx 20
	grid [ttk::label $w.f.unrlbl -text "– Rodo, kad veiksmas, kurį norėjote atlikti mokinio kompiuteriui, neįvyko, nes kompiuteris yra nepasiekiamas. Gali būti, kad mokinio kompiuteris yra išjungtas, nėra interneto ryšio arba kompiuterio IP adresas yra ne toks." -wraplength 350] -column 1 -row $r -pady 10 -padx 20; incr r
	grid [ttk::label $w.f.mouseimg -text "" -image mouse] -column 0 -row $r -pady 10 -padx 20
	grid [ttk::label $w.f.mouselbl -text "– Jeigu kompiuterio sėdėjimo vietai nėra priskirtas mokinys, jį galima laikinai priskirti nuspaudžiant dešinį pelės klavišą ant šios piktogramos. Norint mokiniui priskirti pastovią sėdėjimo vietą prie kompiuterio, tai reikia atlikti per meniu Nustatymai –> Mokiniai..." -wraplength 350] -column 1 -row $r -pady 10 -padx 20; incr r
	grid [ttk::label $w.f.mountimg -text "" -image pcfopen] -column 0 -row $r -pady 10 -padx 20
	grid [ttk::label $w.f.mountlbl -text "– Rodo, kad dabar mokinys mato savo failus, esančius aplanke „Mano_failai“. Visi failai, kuriuos mokinys išsaugos šiame aplanke, išliks mokinio kompiuteryje. Failai, kurie bus išsaugoti ne šiame aplanke, išsitrins perkrovus ar išjungus kompiuterį." -wraplength 350] -column 1 -row $r -pady 10 -padx 20; incr r
	grid [ttk::label $w.f.neutralimg -text "" -image pcneutral] -column 0 -row $r -pady 10 -padx 20
	grid [ttk::label $w.f.neutrallbl -text "– Rodo, kad dabar nevyksta joks ypatingas veiksmas. Mokinys negali išsaugoti failų, kad jie išliktų. Nevyksta nei atsiskaitymas, nei testas." -wraplength 350] -column 1 -row $r -pady 10 -padx 20; incr r
	grid [ttk::label $w.f.tableimg -text "" -image pctable] -column 0 -row $r -pady 10 -padx 20
	grid [ttk::label $w.f.tablelbl -text "– Rodo, kad dabar mokinys vykdo atsiskaitymą. Tai reiškia, kad pas mokinį yra atsiradęs aplankas „Atsiskaitymai“, į kurį mokinys turi išsaugoti savo atliktą darbą." -wraplength 350] -column 1 -row $r -pady 10 -padx 20; incr r
	grid [ttk::label $w.f.tabledoneimg -text "" -image pctabledone] -column 0 -row $r -pady 10 -padx 20
	grid [ttk::label $w.f.tabledonelbl -text "– Rodo, kad mokinys atliko atsiskaitymą, išsaugojo savo darbą aplanke „Atsiskaitymai“ ir nuspaudė mygtuką „Siųsti“. Mokinio darbas automatiškai buvo nukopijuotas į mokytojo kompiuterį. Mokinys nebemato aplanko „Atsiskaitymai“." -wraplength 350] -column 1 -row $r -pady 10 -padx 20; incr r
	grid [ttk::label $w.f.testimg -text "" -image pctest] -column 0 -row $r -pady 10 -padx 20
	grid [ttk::label $w.f.testlbl -text "– Rodo, kad dabar mokinys atlieka jam atsiųstą testą." -wraplength 350] -column 1 -row $r -pady 10 -padx 20; incr r
	grid [ttk::label $w.f.testdoneimg -text "" -image pctestatlikta] -column 0 -row $r -pady 10 -padx 20
	grid [ttk::label $w.f.testdonelbl -text "– Rodo, kad mokinys atliko testą. Testo atsakymai yra automatiškai nukopijuojami į mokytojos kompiuterį. Norint peržiūrėti atliktus testus, reikia nuspausti ant lango kortelės „Kiti veiksmai“ ir spausti mygtuką „Tikrinti mokinių testus“." -wraplength 350] -column 1 -row $r -pady 10 -padx 20; incr r
	
}

proc p_spalvos {} {
	set w .spalvos
	p_naujas_langas $w "Spalvų pasirinkimas"
	set r 0
	set spalvos "Žalia Žydra Oranžinė Pilka Violetinė Rožinė"
	set ::spalva "Žalia"
	grid [ttk::frame $w.f -padding $::pad20] -column 0 -row $r; incr r
	grid [ttk::label $w.f.lbl -text "Mygtukų spalva:" -image palette -compound top -padding "30 0 30 0"] -column 0 -row $r -padx 5 -pady 5; incr r
	grid [ttk::combobox $w.f.combo -textvariable ::spalva -width 8] -column 0 -row $r -pady 5; incr r
	$w.f.combo configure -values $spalvos
	grid [ttk::button $w.f.ok -text "Įrašyti" -image save_icon -compound left -command "destroy .spalvos; p_pakeisti_spalva \$::spalva" -style mazaszalias.TButton] -column 0 -row $r -pady 5
}

proc p_mokytojo {} {
	#čia bus apie klases kurioms dėstau
	set w .intervalas
	p_naujas_langas $w "Klasių pasirinkimas"
	set r 0
	grid [ttk::frame $w.f -padding $::pad20] -column 0 -row $r; incr r
	grid [ttk::label $w.f.lbl -text "Pažymėkite, kurioms klasėms dėstote:" ] -column 0 -row $r -padx 5 -pady 10; incr r
	for {set a 1} {$a <= 12} {incr a} {
		grid [ttk::checkbutton $w.f.kl$a -text "$a" -variable ::destoma_klase$a -onvalue $a -offvalue 0 -command ""] -column 0 -row $r; incr r
	}
	grid [ttk::button $w.f.ok -text "Įrašyti" -image save_icon -compound left -command "p_irasyti_intervala" -style mazaszalias.TButton] -column 0 -row $r -pady 5
}

proc p_irasyti_intervala {} {
	for {set a 1} {$a <= 12} {incr a} {
		if {[info exists ::destoma_klase$a] && [set ::destoma_klase$a] != 0} {
			set klase [set ::destoma_klase$a]
			db3 eval {INSERT OR REPLACE INTO destomos_klases(klase) VALUES ($klase)}
		}
		if {![info exists ::destoma_klase$a]} {
			set klase $a
			db3 eval {DELETE FROM destomos_klases WHERE klase=$klase}
		}
	}
	destroy .intervalas
}

proc p_admin_langas {} {
	set w .admin
	p_naujas_langas $w "Administratoriaus nustatymai"
	set r 0
	grid [ttk::frame $w.libre -padding $::pad20] -column 0 -row 0 -sticky news;
	grid [ttk::label $w.libre.lbl -text "Norėdami atnaujinti programos LibreOffice versiją, reikia turėti atsisiuntus naujesnės versijos archyvą. \n\nSVARBU: Pašalinkite senąją programos versiją iš mokinių kompiuterių." -style didelis.TLabel -wraplength 350] -column 0 -row $r -pady 10; incr r
	grid [ttk::button $w.libre.btn -text "Rinktis atnaujintos versijos failą..." -command "p_rinktis_libre_faila $w; p_libre_update $w"] -column 0 -row $r -pady 10
}

proc p_rinktis_libre_faila {w} {
	set librekelias [tk_getOpenFile -initialdir . -multiple false -title "Pasirinkite reikiamą archyvą" -parent $w]
	set ::librefile_with_extention [file tail $librekelias]
	set ::librefolder [file dirname $librekelias]
	set ::libretemp [file rootname $librekelias]
	set ::librefilename [file tail $::libretemp]
}

proc p_libre_update {w} {
	#TODO: DAR NEVEIKIA RODYMAS, KAIP REALIU LAIKU ĮVYKSTA LIBREOFFICE ATNAUJINIMAI!
	if {$::librefile_with_extention == "" || $::librefolder == "" || $::libretemp == "" || $::librefilename == ""} {
		return
	}
	set komandos "
	sudo mkdir -p /home/mokytoja/LibreNaujinimai/;
	sudo chown mokytoja:mokytoja -R /home/mokytoja/LibreNaujinimai/;
	sudo chmod -R g+rwx /home/mokytoja/LibreNaujinimai;
	sudo rm -rf /home/mokytoja/LibreNaujinimai/Libre*
	"
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	set pranesimas "Programa atnaujinta"
	if {$::testi == 1} {
		destroy $w
		#.informacija.atlikta configure -text "Atnaujinama LibreOffice programa... palaukite..."
		#update idletasks
		foreach pc $pasirinkti_pc {
			set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
			set nr [expr $pc_id - 1]
			set msg [cant_ping $pc]
			if {$msg == 1} {
				set pranesimas "LibreOffice atnaujinta, bet ne visiems"
				p_icon_keitimas $nr pcunr
			} else {
				p_send_command $nr $komandos
				puts "kompiuteris $pc_id pradeda programos LibreOffice atnaujinimą..."
				catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 $::librefolder/$::librefile_with_extention mokytoja@$pc:/home/mokytoja/LibreNaujinimai"}
				p_send_command $nr "cd /home/mokytoja/LibreNaujinimai/; tar -xvf $::librefile_with_extention"
				p_send_command $nr "cd /home/mokytoja/LibreNaujinimai/Libre*; cd DEBS; sudo dpkg -i *.deb &"
				p_icon_keitimas $nr pccheck
			}
		}
		#p_veiksmas_atliktas $pranesimas
	} else {
		destroy $w
		return
	}
}

proc p_numatytieji_aplankai1 {ar_pirmas_kartas} {
	set w .numatyti
	p_naujas_langas $w "Aplankų nustatymas"
	set ::paveikslelis [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="paveikslelis"}]
	set paaiskinimas1 "Pasirinkite aplanką, kuriame bus kaupiami mokinių darbai (tie, kuriuos vertinsite pažymiu). Mokiniams atlikus atsiskaitymą ir nuspaudus mygtuką „Surinkti mokinių darbus“, visi mokinių atlikti darbai atsisiųs automatiškai į parinktąjį aplanką. Mokinių darbai bus suskirstyti pagal klasę, atlikimo datą ir kompiuterio numerį."
	set paaiskinimas2 "Pasirinkite aplanką, kuriame bus kaupiami mokinių kasdien kuriami failai, įvairios atliekamos užduotys. Jie visi bus išsaugoti pasirinktame aplanke ir bus išskirstyti pagal klases. Rekomenduojama kiekvienam mokiniui savo kompiuteryje susikurti savo aplanką su savo vardu ir pavarde ir jame kurti įvairius failus – kitu atveju nežinosite, kurio mokinio kuris darbas yra. Tam, kad mokinių failai atsidurtų mokytojo kompiuteryje, reikės atlikti veiksmą „Surinkti mokinių užrašus“."
	set paaiskinimas3 "Tam, kad būtų patogiau ir greičiau nusiųsti mokiniams failus (užduotis), pasirinkite vieną aplanką, kuriame laikysite visus failus bei užduotis. Tuomet pats pirmas aplankas, nuo kurio pradėsite ieškoti užduoties, bus tas, kurį pasirinksite čia."
	set paaiskinimas4 "Pasirinkite aplanką, kuriame kaupsite ekrano paveikslėlius, jeigu norėsite juos mokiniams pakeisti."
	set paaiskinimas5 "Jei norite turėti galimybę keisti mokinių ekrano paveikslėlius, visų pirma nustatykite visiems mokinių kompiuteriams vienodus ekrano paveikslėlius. Tuomet išsaugokite mokinių kompiuterių nustatymus. Po to įveskite čia tikslų ekrano paveikslėlio pavadinimą, kurį nustatėte mokinių kompiuteriuose bei pilną kelią iki jo. \nPvz.: /home/mokinys/pav/dangus.jpg"
	set r 0
	set y 5
	grid [ttk::frame $w.f -padding $::pad10] -column 0 -row $r -sticky news; incr r
	grid [ttk::label $w.f.darbailbl -text "Mokinių darbų aplankas: \nNEPARINKTAS"] -column 0 -row $r -pady $y -padx 10 -sticky w 
	grid [ttk::button $w.f.darbaibtn -text "Pasirinkti..." -command {set ::darbu_aplankas [tk_chooseDirectory -initialdir . -parent .numatyti]}] -column 1 -row $r -pady $y -padx 10 -sticky w
	grid [ttk::button $w.f.darbaiinfo -text "" -image klaus32 -command "tk_messageBox -message \"$paaiskinimas1\" -parent $w" -style mazaszalias.TButton] -column 2 -row $r -pady $y -padx 10 -sticky w
	incr r
	grid [ttk::label $w.f.uzrasailbl -text "Aplankas mokinių užrašams: \nNEPARINKTAS"] -column 0 -row $r -pady $y -padx 10 -sticky w
	grid [ttk::button $w.f.uzrasaibtn -text "Pasirinkti..." -command {set ::uzrasu_aplankas [tk_chooseDirectory -initialdir . -parent .numatyti]}] -column 1 -row $r -pady $y -padx 10 -sticky w
	grid [ttk::button $w.f.uzrasaiinfo -text "" -image klaus32 -command "tk_messageBox -message \"$paaiskinimas2\" -parent $w" -style mazaszalias.TButton] -column 2 -row $r -pady $y -padx 10 -sticky w
	incr r
	grid [ttk::label $w.f.uzduotyslbl -text "Užduočių aplankas: \nNEPARINKTAS"] -column 0 -row $r -pady $y -padx 10 -sticky w
	grid [ttk::button $w.f.uzduotysbtn -text "Pasirinkti..." -command {set ::failu_aplankas [tk_chooseDirectory -initialdir . -parent .numatyti]}] -column 1 -row $r -pady $y -padx 10 -sticky w
	grid [ttk::button $w.f.uzduotysinfo -text "" -image klaus32 -command "tk_messageBox -message \"$paaiskinimas3\" -parent $w" -style mazaszalias.TButton] -column 2 -row $r -pady $y -padx 10 -sticky w
	incr r
	grid [ttk::label $w.f.pav1lbl -text "Ekrano paveikslėlių aplankas: \nNEPARINKTAS"] -column 0 -row $r -pady $y -padx 10 -sticky w
	grid [ttk::button $w.f.pav1btn -text "Pasirinkti..." -command {set ::pav_aplankas [tk_chooseDirectory -initialdir . -parent .numatyti]}] -column 1 -row $r -pady $y -padx 10 -sticky w
	grid [ttk::button $w.f.pav1info -text "" -image klaus32 -command "tk_messageBox -message \"$paaiskinimas4\" -parent $w" -style mazaszalias.TButton] -column 2 -row $r -pady $y -padx 10 -sticky w
	incr r
	grid [ttk::label $w.f.pavlbl -text "Kelias iki ekrano paveikslėlio:"] -column 0 -row $r -pady $y -padx 10 -sticky w
	grid [ttk::entry $w.f.paventr -textvariable ::paveikslelis -width 20] -column 1 -row $r -pady $y -padx 10
	grid [ttk::button $w.f.pavinfo -text "" -image klaus32 -command "tk_messageBox -message \"$paaiskinimas5\" -parent $w" -style mazaszalias.TButton] -column 2 -row $r -pady $y -padx 10 -sticky w
	focus $w.f.paventr
	incr r
	p_atnaujinti_numat_aplankus ".numatyti.f"
	grid [ttk::button $w.f.ok -text "Įrašyti" -image save_icon -compound right -command "destroy .numatyti; p_numatytieji_aplankai2 $ar_pirmas_kartas" -style mazaszalias.TButton] -column 0 -row $r -pady 10 -padx 10 -columnspan 3
}

proc p_numatytieji_aplankai2 {ar_pirmas_kartas} {
	if {[info exists ::darbu_aplankas]} {db3 eval {INSERT OR REPLACE INTO pagrindiniai_aplankai(koksapl, apl) VALUES ('darbu_aplankas', $::darbu_aplankas)}}
	if {[info exists ::uzrasu_aplankas]} {db3 eval {INSERT OR REPLACE INTO pagrindiniai_aplankai(koksapl, apl) VALUES ('uzrasu_aplankas', $::uzrasu_aplankas)}}
 	if {[info exists ::pav_aplankas]} {db3 eval {INSERT OR REPLACE INTO pagrindiniai_aplankai(koksapl, apl) VALUES ('pav_aplankas', $::pav_aplankas)}}
 	if {[info exists ::paveikslelis]} {db3 eval {INSERT OR REPLACE INTO pagrindiniai_aplankai(koksapl, apl) VALUES ('paveikslelis', $::paveikslelis)}}
 	if {[info exists ::failu_aplankas]} {db3 eval {INSERT OR REPLACE INTO pagrindiniai_aplankai(koksapl, apl) VALUES ('failu_aplankas', $::failu_aplankas)}}
 	if {$ar_pirmas_kartas == "pirmas"} {
		p_aplankai pirmas
 	} else {
		p_numatytieji_aplankai1 $ar_pirmas_kartas
 	}
}

proc p_atnaujinti_numat_aplankus {w} {
	set d_apl [file tail [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="darbu_aplankas"}]]
	set u_apl [file tail [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="uzrasu_aplankas"}]]
	set p_apl [file tail [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="pav_aplankas"}]]
	set f_apl [file tail [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="failu_aplankas"}]]
	if {$d_apl != ""} {
		$w.darbailbl configure -text "Mokinių darbų aplankas: \n$d_apl"
		$w.darbaibtn configure -text "Pakeisti..."
	}
	if {$u_apl != ""} {
		$w.uzrasailbl configure -text "Aplankas mokinių užrašams: \n$u_apl"
		$w.uzrasaibtn configure -text "Pakeisti..."
	}
	if {$f_apl != ""} {
		$w.uzduotyslbl configure -text "Užduočių aplankas: \n$f_apl"
		$w.uzduotysbtn configure -text "Pakeisti..."
	}
	if {$p_apl != ""} {
		$w.pav1lbl configure -text "Ekrano paveikslėlių aplankas: \n$p_apl"
		$w.pav1btn configure -text "Pakeisti..."
	}
}

proc p_numatytu_aplanku_kurimo_pradzia {ar_pirmas_kartas} {
	if {$ar_pirmas_kartas == "pirmas"} {
		set w .inf
		p_naujas_langas $w "Informacija"
		set r 0
		grid [ttk::frame $w.aplanku -padding $::pad10] -column 0 -row $r -sticky news; incr r
		grid [ttk::label $w.aplanku.lbl -text "Tam, kad darbas su mokiniais ir jų kompiuteriais vyktų greičiau, reikės pasirinkti keletą numatytųjų aplankų. Visa informacija apie juos bus kitame lange. Jei norėsite platesnių paaiškinimų, turėsite spausti ant klaustukų, kurie ten pasirodys." -wraplength 350] -column 0 -row $r -pady 5; incr r
		grid [ttk::button $w.aplanku.btn -text "Toliau >" -command "p_numatytieji_aplankai1 $ar_pirmas_kartas"] -column 0 -row $r
	} else {
		p_numatytieji_aplankai1 $ar_pirmas_kartas
	}
}
#--------------------------------------------------------------------------------------------------------------------------------------
#kompiuterių IP adresų įvedimas bei keitimas:
proc p_komp_perziura {} {
	set w .pcperziura
	p_naujas_langas $w "Kompiuterių skaičius"
	wm attribute $w -topmost 1
	wm protocol .pcperziura WM_DELETE_WINDOW { }
	set r 0
	grid [ttk::frame $w.ivesta -padding $::pad20] -column 0 -row $r -sticky news; incr r
	grid [ttk::label $w.ivesta.nera -text "Įveskite mokinių kompiuterių skaičių. Šį skaičių vėliau bus galima pakeisti." -image pc_icon_small -compound bottom -wraplength 350 -style didelis.TLabel] -column 0 -row $r -pady 10 -columnspan 2; incr r
	grid [ttk::label $w.ivesta.zinute -text "Kompiuterių skaičius:" -style didelis.TLabel] -pady 10 -column 0 -row $r -sticky w
	grid [ttk::entry $w.ivesta.skaiciaus -textvariable ::komp_sk -width 5] -column 0 -row $r -pady 10 -sticky e; incr r
	focus $w.ivesta.skaiciaus
	grid [ttk::button $w.ivesta.testi -text "Tęsti >" -command "if {\[p_tikrinti_ivedima ::komp_sk {Neužpildėte laukelio!}\]} {p_ip_adresu_suvedimo_langas 1; destroy $w}" -style mazaszalias.TButton] -column 0 -row $r -pady 10 -padx 10 -columnspan 2
}

proc p_ip_adresu_suvedimo_langas {ar_pirma_karta} {
	set ::table_lentele kompiuteriai
	set pc_ips [db3 eval {SELECT pc FROM kompiuteriai}]
	if {$ar_pirma_karta == 0} {
		if {$pc_ips == ""} {
			p_komp_perziura
			return
		}
		set nr 1
		foreach el $pc_ips {
			set ::ip$nr $el
			set ::display$nr [db3 onecolumn {SELECT display FROM kompiuteriai WHERE pc=$el}]
			#puts $el
			#puts [set ::di$nr]
			incr nr
		}
		if {![info exists ::komp_sk]} {
			set ::komp_sk [llength $pc_ips]
		}
	}
	p_naujas_langas .duomenu "Kompiuteriai ir IP adresai"
	set r 0
	set display0 "DISPLAY=:0.0"
	set display1 "DISPLAY=:1.0"
	grid [ttk::frame .duomenu.f -padding $::pad10] -column 0 -row $r -sticky news; incr r
	set w .duomenu.f
	if {$ar_pirma_karta == 1} {
		wm protocol .duomenu WM_DELETE_WINDOW { }
	}
	grid [ttk::label $w.zinute -text "" -image pc_icon_small -compound top] -column 0 -row $r -columnspan 4; incr r
	grid [ttk::label $w.komp -text "NR.:"] -column 1 -row $r -pady 5
	grid [ttk::label $w.adr -text "IP ADRESAS:"] -column 2 -row $r -pady 5; incr r
	for {set nr 1} {$nr <= $::komp_sk} {incr nr} {
		grid [ttk::label $w.eil$nr -text "$nr."] -column 1 -row $r
		grid [ttk::entry $w.irasyk$nr -textvariable ::ip$nr] -column 2 -row $r
		grid [ttk::radiobutton $w.display0$nr -text "0" -variable ::display$nr -value $display0] -column 3 -row $r
		grid [ttk::radiobutton $w.display1$nr -text "1" -variable ::display$nr -value $display1] -column 4 -row $r
		grid [ttk::button $w.rem$nr -text "" -image rem16 -command "p_pasalinti_kompiuterius $w $nr; p_ip_adresu_suvedimo_langas 0" -style permatomas.TButton] -column 5 -row $r -sticky w
		incr r
	}
	grid [ttk::button $w.plus -text "Pridėti daugiau" -image ad16 -compound right -command "set ::komp_sk [expr $::komp_sk+1]; p_atnaujinti_komp_sarasa $nr $w $r" -style mazas.TButton] -column 2 -row $r -pady 10 -padx 10; incr r
	grid [ttk::button $w.ok -text "Įrašyti" -image save_icon -compound left -command "p_ar_uzpildyti_laukeliai $w $ar_pirma_karta" -style mazaszalias.TButton] -column 0 -row $r -pady 10 -padx 10 -columnspan 4
	focus $w.eil1
}

proc p_atnaujinti_komp_sarasa {sk w r} {
	set display0 "DISPLAY=:0.0"
	set display1 "DISPLAY=:1.0"
	for {set nr $sk} {$nr <= $::komp_sk} {incr nr} {
		grid [ttk::label $w.eil$nr -text "$nr."] -column 1 -row $r
		grid [ttk::entry $w.irasyk$nr -textvariable ::ip$nr] -column 2 -row $r
		grid [ttk::radiobutton $w.display0$nr -text "0" -variable ::display$nr -value $display0] -column 3 -row $r
		grid [ttk::radiobutton $w.display1$nr -text "1" -variable ::display$nr -value $display1] -column 4 -row $r
		grid [ttk::button $w.rem$nr -text "" -image rem16 -command "p_pasalinti_kompiuterius $w $nr; if {\[ar_testi\]} {p_ip_adresu_suvedimo_langas 0}" -style permatomas.TButton] -column 5 -row $r -sticky w
		incr r
	}
	grid $w.plus -row $r; incr r
	grid $w.ok -row $r
	$w.plus configure -command "set ::komp_sk [expr $::komp_sk+1]; p_atnaujinti_komp_sarasa $nr $w $r"
}

proc p_pasalinti_kompiuterius {w nr} {
	set ip "[$w.irasyk$nr get]"
	set pc_id [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$ip}]
	db3 eval {DELETE FROM kompiuteriai WHERE pc=$ip}
	db3 eval {DELETE FROM current_pc_setup WHERE pc_id=$pc_id}
	destroy $w.irasyk$nr $w.eil$nr
	destroy $w
	set pc_ids [db3 eval {SELECT pc FROM kompiuteriai}]
	set ::komp_sk [llength $pc_ids]	
	set visi_ip_adresai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	if {$visi_ip_adresai == ""} {
		set ::testi 0
		db1 eval "UPDATE kompiuteriai_check SET ar_ivesta=0 WHERE Id=1"
		p_check
	} else {
		p_perpiesti_kompiuterius
		p_atsijungimas_nuo_pc
		after 5000
		p_prisijungimas_prie_visu_pc
		set ::testi 1
	}
}

proc p_ar_uzpildyti_laukeliai {w ar_pirma_karta} {
#tikrina, ar yra užpildyti visi ip adresų laukeliai. Jei ne, išmeta klaidos pranešimą, o jei taip, pereina prie komp. įrašymo į db procedūros.
	for {set nr 1} {$nr <= $::komp_sk} {incr nr} {
		if {[info exists ::ip$nr] && [info exists ::display$nr]} {
			continue
			set ::testi 1
		} else {
			tk_messageBox -message "Reikia užpildyti visus laukelius! PASTABA: prie kiekvieno kompiuterio adreso pažymėkite skaičių 0. \nJeigu vėliau pastebėsite, kad programa nenusiunčia žinučių mokinių kompiuteriams, pakeiskite šiuos skaičius į 1." -parent $w
			set ::testi 0
			return
		}
	}
	p_komp_irasymas_i_db $w $ar_pirma_karta
}

proc p_komp_irasymas_i_db {w ar_pirma_karta} {
	for {set nr 1} {$nr <= $::komp_sk} {incr nr} {
		set a [set ::ip$nr]
		if {[info exists ::display$nr]} {
			set b [set ::display$nr]
			puts $a
			puts $b
		}
		db3 eval "INSERT OR REPLACE INTO $::table_lentele VALUES(:nr, :a, :b)"
	}
	set visi_ip_adresai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	for {set nr 1} {$nr <= [llength $visi_ip_adresai]} {incr nr} {
		db3 eval "INSERT OR REPLACE INTO current_pc_setup (pc_id, mok_id, var, ar_primountinta, testo_id, atsiskaitymas, ar_alien) VALUES($nr, 0, 0, 0, 0, 0, 0)"
	}
	destroy .duomenu.f
	grid [ttk::frame .duomenu.palaukite -padding "50 50 50 50"] -column 0 -row 0 -sticky news
	grid [ttk::label .duomenu.palaukite.tekstas -text "Dirbama... Palaukite..." -style didelis.TLabel] -column 0 -row 0
	tk_messageBox -message "Pridedami kompiuteriai. Tai gali šiek tiek užtrukti." -parent .duomenu
	p_klasiu_aplanku_kurimas w $ar_pirma_karta
	p_perpiesti_kompiuterius
	p_atsijungimas_nuo_pc
	after 5000
	p_prisijungimas_prie_visu_pc
	destroy .duomenu
	unset ::komp_sk
	if {$ar_pirma_karta == 1} {
		db1 eval "INSERT OR REPLACE INTO kompiuteriai_check(Id, ar_ivesta) VALUES(1, 1)"
		p_check
	}
}
#--------------------------------------------------------------------------------------------------------
#Viskas, kas susiję su klasėmis:
proc p_pirmuju_klasiu_ivedimas {ar_pirmas_kartas} {
#jei neegzistuoja nė viena klasė, leidžia įvesti klasių skaičių. Jei klasės jau įvestos, pereina prie kitos procedūros.
	set pc_patikrinimas [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	if {$pc_patikrinimas == ""} {
		tk_messageBox -message "Nėra įvesta kompiuterių ir jų adresų. Visų pirma suveskite kompiuterius (Nustatymai -> Kompiuteriai ir IP adresai...), o po to klases." -parent .n
		return
	}
	if {$ar_pirmas_kartas == "pirmas"} {
		set w .pasirinkite
		p_naujas_langas $w "Klasės"
		wm protocol .pasirinkite WM_DELETE_WINDOW { }
		set tekstas1 "Įveskite klasių skaičių, kurioms dėstote. \nJį vėliau bet kada bus galima pakeisti."
		set r 0
		grid [ttk::frame $w.klases -padding $::pad20] -column 0 -row $r -sticky news -columnspan 3; incr r
		grid [ttk::label $w.klases.paaiskinimas1 -text $tekstas1 -style didelis.TLabel -width 35] -pady 10 -column 0 -row $r; incr r
		grid [ttk::frame $w.klases.l -padding $::pad20] -column 0 -row $r -sticky news; incr r
		grid [ttk::label $w.klases.l.zinute -text "Klasių skaičius:" -style didelis.TLabel] -column 0 -row $r -padx 7
		grid [ttk::entry $w.klases.l.skaicius -textvariable ::kl_sk -width 5] -column 1 -row $r -padx 7
		focus $w.klases.l.skaicius
		grid [ttk::button $w.klases.l.testi -text "Tęsti >" -command "if {\[p_tikrinti_ivedima ::kl_sk {Laukelis tuščias!}\]} {destroy $w; p_klasiu_laukeliu_piesimas $ar_pirmas_kartas}" -style mazaszalias.TButton] -column 2 -row $r -padx 7
	} else {
		p_klasiu_laukeliu_piesimas $ar_pirmas_kartas
	}
}

proc p_klasiu_laukeliu_piesimas {ar_pirmas_kartas} {
	if {$ar_pirmas_kartas != "pirmas"} {
		set ::kl_sk [db3 eval {SELECT COUNT(Id) FROM klases}]
		set tekstas_virsuje "PASIRINKITE KLASĘ:"
	} else {
		set tekstas_virsuje "ĮVESKITE KLASES \n(Pvz.: 6a, 6b...):"
	}
	set w .klasiu
	p_naujas_langas $w "Įvedimas"
	wm protocol .klasiu WM_DELETE_WINDOW {
		destroy .klasiu
		unset ::kl_sk
	}
	set r 0
	grid [ttk::frame $w.kl -padding $::pad20] -column 0 -row $r -sticky news -columnspan 5; incr r
	grid [ttk::label $w.kl.ivesk -text $tekstas_virsuje -style didelis.TLabel -justify "center"] -pady 10 -column 0 -row $r; incr r
	if {$ar_pirmas_kartas != "pirmas"} {
		set visos_klases [db3 eval {SELECT klase FROM klases WHERE klase!="Testinė_klasė" ORDER BY klase}]
		set ::parinkta_klase [lindex $visos_klases 0]
		grid [ttk::combobox $w.kl.comboklase -textvariable ::parinkta_klase -width 10] -column 0 -row $r; incr r
		$w.kl.comboklase configure -values $visos_klases
		bind $w.kl.comboklase <<ComboboxSelected>> "p_parinkti_klase_redagavimui $w"
		grid [ttk::frame $w.kl.mygtukai -padding "10 10 10 0"] -column 0 -row $r -sticky news; incr r
		set m1 "$w.kl.mygtukai.mokiniai"
		set m2 "$w.kl.mygtukai.pervadinti"
		set m3 "$w.kl.mygtukai.salinti"
		set m4 "$w.kl.mygtukai.prideti"
		set m5 "$w.kl.mygtukai.pervadintivisas"
		set m6 "$w.kl.mygtukai.paaiskinimas"
		set paaiskinimas "Atliekant bet kurį veiksmą su klasėmis, turi būti įjungti visi mokinių kompiuteriai."
		set ispejimas2 "Ar tikrai norite pervadinti visas klases iš žemesnių į aukštesnes? \n(Pvz.: klasė 5a taps 6a; klasė 7b taps 8b ir t. t.) \nAtliekant šį veiksmą, bus pervadinti ne tik klasių, bet ir mokinių \naplankų pavadinimai, todėl mokinių kompiuteriai turi būti įjungti."
		grid [ttk::button $m1 -text "" -text "" -image user32 -command "p_mokiniu_redagavimo_laukeliai \$::parinkta_klase" -width 15 -style mazas.TButton] -column 0 -row $r -pady 5 -padx 2
		setTooltip $m1 "Peržiūrėti mokinius"
		grid [ttk::button $m2 -text "" -image ed32 -command "p_veiksmas_su_klase pervadinti \$::parinkta_klase $ar_pirmas_kartas $w" -width 15 -style mazas.TButton] -column 1 -row $r -pady 5 -padx 2
		setTooltip $m2 "Pervadinti klasę"
		grid [ttk::button $m3 -text "" -image rem32 -command "p_pries_salinant_klase \$::parinkta_klase $w" -width 15 -style mazas.TButton] -column 2 -row $r -pady 5 -padx 2
		setTooltip $m3 "Šalinti klasę"
		grid [ttk::button $m4 -text "" -image ad32 -command "p_veiksmas_su_klase pridėti \$::parinkta_klase $ar_pirmas_kartas $w" -width 15 -style mazas.TButton] -column 3 -row $r -pady 5 -padx 2
		setTooltip $m4 "Pridėti klasę"
		grid [ttk::button $m5 -text "" -image res32 -command "p_ar_tikrai \"$ispejimas2\" {destroy $w; p_klasiu_pervadinimas_naujas}"  -width 15 -style mazas.TButton] -column 4 -row $r -pady 5 -padx 2
		setTooltip $m5 "Pervadinti visas klases automatiškai"
		grid [ttk::button $m6 -text "" -image klaus32 -command "tk_messageBox -message \"$paaiskinimas\" -parent $w" -width 15 -style mazas.TButton] -column 5 -row $r -pady 5 -padx 2
		setTooltip $m6 "Informacija"
	} else {
		wm protocol .klasiu WM_DELETE_WINDOW { }
		set c 0
		if {$::kl_sk <= 6} {
			set h [expr $::kl_sk*2.3]
		} else {
			set h 14
		}
		grid [text $w.kl.t -yscrollcommand "$w.kl.scrollbar set" -background "white" -state disabled -width 25 -height $h] -column 0 -row $r -sticky we
		grid [scrollbar $w.kl.scrollbar -command "$w.kl.t yview" -orient vertical] -column 1 -row $r -sticky ns
		ttk::label $w.kl.t.l -text "" -background "white"
		$w.kl.t window create 2.0 -window $w.kl.t.l
		grid [ttk::frame $w.kl.t.l.f -style baltas.TFrame] -column 0 -row $r -sticky news; incr r
		for {set i 1} {$i <= $::kl_sk} {incr i} {
			grid [ttk::label $w.kl.t.l.f.nr$i -text "$i." -background "white" -padding "20 7 5 7"] -column 0 -row $r -pady 1
			grid [ttk::entry $w.kl.t.l.f.iveskklase$i -textvariable ::kl_pavad$i -validate key -validatecommand {p_replace_spaces %W %S %i %d} -width 13 -background "white"] -column 1 -row $r -pady 1 -sticky w; incr r
			focus $w.kl.t.l.f.iveskklase1
		}
		grid [ttk::frame $w.kl.mygtukai -padding "10 10 10 0"] -column 0 -row $r -sticky news; incr r
		grid [ttk::button $w.kl.mygtukai.atsisak -text "Grįžti" -image back_icon -compound left -command "destroy $w; p_pirmuju_klasiu_ivedimas $ar_pirmas_kartas" -style mazaszalias.TButton -width 5] -pady 10 -padx 3 -column $c -row $r; incr c
		grid [ttk::button $w.kl.mygtukai.gerai -text "Įrašyti" -image save_icon -compound left -command "p_irasyti_klases_i_db $w $ar_pirmas_kartas" -style mazaszalias.TButton] -pady 10 -padx 3 -column $c -row $r
	}
}

proc p_pries_salinant_klase {klase w} {
	if {$klase == "Testinė_klasė"} {
		tk_messageBox -message "Testinės klasės pašalinti negalima" -parent $w
		return
	} else {
		set ispejimas1 "\nTuo pačiu bus pašalinti visi joje esantys \nmokiniai bei jų failai."
		p_ar_tikrai "Ar tikrai norite pašalinti klasę $klase? $ispejimas1" "p_klases_salinimas $klase"
	}
}

proc p_parinkti_klase_redagavimui {w} {
	set ::parinkta_klase "[$w.kl.comboklase get]"
}

proc p_irasyti_klases_i_db {w ar_pirmas_kartas} {
	if {$ar_pirmas_kartas == "pirmas"} {
	#Patikrina, ar klasių laukeliai užpildyti. Jei viskas gerai, sukuria naujas klases.
		set zinute "Spauskite mygtuką „OK“ ir palaukite, kol bus sukurti reikalingi aplankai mokinių kompiuteriuose. \nTai gali šiek tiek užtrukti."
		for {set i 1} {$i<=$::kl_sk} {incr i} {
			if {[winfo exists $w.kl.t.l.f.rodykklase$i] == 1} {
				set ::kl_pavad$i [db3 onecolumn {SELECT klase FROM klases WHERE Id=$i}]
			}
		}
		for {set i 1} {$i<=$::kl_sk} {incr i} {
			if {![info exists ::kl_pavad$i]} {
				tk_messageBox -message "Ne visi laukeliai užpildyti!" -parent $w
				return
			}
			if {[winfo exists $w.kl.t.l.f.rodykklase$i] != 1} {
				set kl [set ::kl_pavad$i]
				db3 eval {INSERT INTO klases(klase) VALUES($kl)}
			}
		}
		destroy $w.kl
		grid [ttk::frame $w.dirbama -padding "50 50 50 50"] -column 0 -row 0 -sticky news
		grid [ttk::label $w.dirbama.palaukite -text "Dirbama... Palaukite..." -style didelis.TLabel] -column 0 -row 0
		tk_messageBox -message $zinute -parent $w
		p_testinio_mok_ir_klases_sukurimas
		p_klasiu_aplanku_kurimas $w $ar_pirmas_kartas
	} else {
	#Sukuria naują klasę ir įrašo ją į duomenų bazę
		set w ".w"
		set klase "[.w.kl.iveskpavad get]"
		set zinute "Klasė $klase sukurta. \nSpauskite mygtuką „OK“ ir palaukite, kol bus sukurti naujos klasės mokinių aplankai mokinių kompiuteriuose."
		db3 eval {INSERT INTO klases(klase) VALUES($klase)}
		tk_messageBox -message $zinute -parent $w
	}
	destroy $w
}

proc p_klasiu_pervadinimas_naujas {} {
	set visi_kompiuteriai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	foreach pc $visi_kompiuteriai {
		set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 ./Programos_failai/class_upshift.tcl mokytoja@$pc:/home/mokytoja/"}
		p_send_command $nr "tclsh /home/mokytoja/class_upshift.tcl"
	}
	
	set visos_klases [db3 eval {SELECT klase FROM klases WHERE klase != "Testinė_klasė" ORDER BY klase DESC}]
	foreach kl $visos_klases {
		#regexp išskaido kintamąjį į norimas dalis. pvz šičia aš kintamojo varde ieškau raidžių, po to skaičių, po to vėl raidžių ir išskaidau į 3 dalis:
		regexp {([a-zA-Z]*)([0-9]+)([a-zA-Z]*)} $kl pavad raides skaicius kita
		if {[info exists pavad]} {#only if pattern matched, "Testine_klase" does not match and nothing should be changed for it
			set nskaicius [expr $skaicius+1]
			set nkl $raides$nskaicius$kita
			db3 eval {UPDATE klases SET klase=$nkl WHERE klase=$kl}
		} 	
	}
	
	set pranesimas "Klasės pervadintos."
	p_perpiesti_klasiu_laukeli 2
	p_veiksmas_atliktas $pranesimas
	

	#.informacija.atlikta configure -text "Pervadinamos klasės... palaukite..."
	#update idletasks
	#set pranesimas "Klasės pervadintos."
	#set visu_klasiu_ids [db3 eval {SELECT Id FROM klases WHERE klase != "Testinė_klasė" ORDER BY klase DESC}]
	#set visos_klases [db3 eval {SELECT klase FROM klases WHERE klase != "Testinė_klasė" ORDER BY klase DESC}]
	#set visi_kompiuteriai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	#set pc_nrs [db3 eval {SELECT Id - 1 FROM kompiuteriai ORDER BY Id}]
	
	#foreach nr $pc_nrs {
		#p_send_command $nr "mkdir -p /home/mokytoja/mokiniu_failai_back"
		#p_send_command $nr "rm -rf /home/mokytoja/mokiniu_failai_back/*"
		#p_send_command $nr "cp -r /home/mokytoja/mokiniu_failai/* /home/mokytoja/mokiniu_failai_back"
		#p_send_command $nr "rm -rf /home/mokytoja/mokiniu_failai/*"
	#}
	
	#foreach kl $visos_klases {
	##regexp išskaido kintamąjį į norimas dalis. pvz šičia aš kintamojo varde ieškau raidžių, po to skaičių, po to vėl raidžių ir išskaidau į 3 dalis:
			#regexp {([a-zA-Z]*)([0-9]+)([a-zA-Z]*)} $kl pavad raides skaicius kita 
			#set nskaicius [expr $skaicius+1]
			#set nkl $raides$nskaicius$kita
			#lappend nklases $nkl
	#}

	#foreach nr $pc_nrs {
		#set n 0
		#foreach kl $visos_klases {
				#set nkl [lindex $nklases $n]
				#p_send_command $nr "mkdir /home/mokytoja/mokiniu_failai/$nkl"
				#p_send_command $nr "cp -r /home/mokytoja/mokiniu_failai_back/$kl/* /home/mokytoja/mokiniu_failai/$nkl"
				
				#incr n
		#}
		#p_send_command $nr "sudo chown -R mokinys:mokinys /home/mokytoja/mokiniu_failai/*"
		#p_send_command $nr "sudo chmod -R a+rwx /home/mokytoja/mokiniu_failai/*"
		#p_icon_keitimas $nr pccheck
	#}
	#set n 0
	#foreach kl $visos_klases {
		#set nkl [lindex $nklases $n]
		#db3 eval {UPDATE klases SET klase=$nkl WHERE klase=$kl}
	#}
	#-------------------even older commentout!!! :) --------------
	#foreach nkl $nklases {
		#set aregzistuoja [db3 eval {SELECT EXISTS(SELECT 1 FROM klases WHERE klase=$nkl LIMIT 1)}]
		#if {$aregzistuoja == 0} {
			#db3 eval {INSERT OR REPLACE INTO klases(klase) VALUES($nkl)}
		#}
	#}
	#set nauju_kl_sk [llength $nklases]
	#set senu_kl_sk [llength $visos_klases]
	##cia persivadina mokiniu db esanciu mokiniu klases, kurioms mokiniai yra priskirti
	#for {set counter 1} {$counter<=$senu_kl_sk} {incr counter} {
		#set kl [lindex $visos_klases [expr $senu_kl_sk-$counter]]
		#set nkl [lindex $nklases [expr $nauju_kl_sk-$counter]]
		#set senos_klases_id [db3 eval {SELECT Id FROM klases WHERE klase=$kl}]
		#set senos_klases_mokiniu_ids [db3 eval {SELECT Id FROM mokiniai WHERE klases_id=$senos_klases_id}]
		#set naujosklases_id [db3 eval {SELECT Id FROM klases WHERE klase=$nkl}]
		#foreach mokid $senos_klases_mokiniu_ids {
			#db3 eval {UPDATE mokiniai SET klases_id=$naujosklases_id WHERE Id=$mokid AND klases_id=$senos_klases_id}
		#}
	#}
	#set naujos_klases [db3 eval {SELECT klase FROM klases ORDER BY Id}]
	#foreach pc $visi_kompiuteriai {
		#set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		#set msg [cant_ping $pc]
		#if {$msg != 1} {
			
			
		#} else {
			#set pranesimas "Klasės pervadintos, bet ne visiems"
			#p_icon_keitimas $nr pcunr
		#}
	#}
	#foreach pc $visi_kompiuteriai {
		#foreach kl $visos_klases {
		##senu klasiu pasalinimas, kuriose nebera ne vieno mokinio
			##if {$kl != "Testinė_klasė"} {
				#set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$kl}]
				#set mokiniu_sk_klaseje [db3 eval {SELECT COUNT(*) FROM mokiniai WHERE klases_id=$klases_id}]
				#if {$mokiniu_sk_klaseje == 0} {
					#db3 eval {DELETE FROM klases WHERE Id=$klases_id}
					#set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
					#p_send_command $nr "sudo rm -rf /home/mokytoja/mokiniu_failai/$kl/"
				#}
			##}
		#}
	#}
}

proc p_klasiu_aplanku_kurimas {w ar_pirmas_kartas} {
#sukuria mokinių kompiuteriuose klasių aplankus
	if {$ar_pirmas_kartas == "1"} {
		p_atsijungimas_nuo_pc
		after 5000
		p_prisijungimas_prie_visu_pc
		return
	}
	if {$ar_pirmas_kartas != 0} {
		.informacija.atlikta configure -text "Kuriamos klasės ir jų aplankai... palaukite..."
	}
	set pranesimas "Klasės ir jų aplankai sukurti."
	set klasiu_sarasas [db3 eval {SELECT * FROM klases ORDER BY Id}]
	if {![info exists klasiu_sarasas]} {
		tk_messageBox -message "Nėra įvesta klasių, kurioms dėstote. Nueikite į meniu Nustatymai -> Klasės..., suveskite reikalingus duomenis ir mėginkite iš naujo." -parent $w
	} else {
		set visi_kompiuteriai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
		set visos_klases [db3 eval {SELECT klase FROM klases ORDER BY klase}]
		foreach pc $visi_kompiuteriai {
			set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
			set msg [cant_ping $pc]
			if {$msg == 1} {
				set pranesimas "Klasių aplankai sukurti, bet ne visiems"
				if {$ar_pirmas_kartas != 0} {
					p_icon_keitimas $nr pcunr
				}
			} else {
				if {$ar_pirmas_kartas != 0} {
					p_icon_keitimas $nr pccheck
				}
				foreach kl $visos_klases {
					p_send_command $nr "cd /home/mokytoja/mokiniu_failai/; mkdir $kl"
					puts "kuriame aplankus dabartiniai ir seni"
					p_send_command $nr "cd /home/mokytoja/mokiniu_failai/$kl/; mkdir dabartiniai seni"
					p_send_command $nr "sudo chown -R mokinys:mokinys /home/mokytoja/mokiniu_failai/$kl/dabartiniai/"
					p_send_command $nr "sudo chmod -R a+rwx /home/mokytoja/mokiniu_failai/$kl/dabartiniai/"
					p_send_command $nr "sudo chown -R mokinys:mokinys /home/mokytoja/mokiniu_failai/$kl/seni/"
					p_send_command $nr "sudo chmod -R a+rwx /home/mokytoja/mokiniu_failai/$kl/seni/"
				}
			}
		}
	}
	if {$ar_pirmas_kartas != 0} {
		p_perpiesti_klasiu_laukeli 2
		p_veiksmas_atliktas $pranesimas
	}
	if {$ar_pirmas_kartas == "pirmas"} {
		db1 eval "INSERT OR REPLACE INTO klases_check(Id, ar_ivesta) VALUES(1, 1)"
		p_check
	}
}

proc p_veiksmas_su_klase {ka_daryti klase ar_pirmas_kartas w} {
	if {[info exists :::kl_pavad]} {
		unset ::kl_pavad
	}
	if {$ka_daryti == "pervadinti"} {
		set lango_pavad "Pervadinimas"
		set tekstas "Naujas klasės pavadinimas:"
		set komanda "if {\[p_tikrinti_ivedima ::kl_pavad {Reikia užpildyti laukelį!}\]} {destroy $w; destroy .w; p_pervadinti_klase $klase \$::kl_pavad}"
	} else {
		set lango_pavad "Klasės sukūrimas"
		set tekstas "Įveskite klasei pavadinimą"
		set komanda "if {\[p_tikrinti_ivedima ::kl_pavad {Reikia užpildyti laukelį!}\]} {destroy $w; p_irasyti_klases_i_db $w $ar_pirmas_kartas; p_klasiu_aplanku_kurimas $w $ar_pirmas_kartas}"
	}
	p_naujas_langas .w $lango_pavad
	set r 0
	grid [ttk::frame .w.kl -padding $::pad10] -column 0 -row $r -sticky news; incr r
	grid [ttk::label .w.kl.ivesk -text $tekstas -style didelis.TLabel] -pady 10 -column 0 -row $r -columnspan 2; incr r
	grid [ttk::entry .w.kl.iveskpavad -textvariable ::kl_pavad -validate key -validatecommand {p_replace_spaces %W %S %i %d} -width 10] -pady 10 -column 0 -row $r -columnspan 2; incr r
	focus .w.kl.iveskpavad
	grid [ttk::button .w.kl.save -text "Įrašyti" -image save_icon -compound left -command $komanda -style mazaszalias.TButton] -column 0 -row $r -padx 5 -pady 10
	grid [ttk::button .w.kl.back -text "Atsisakyti" -image rem32 -compound left -command "destroy .w" -style mazaszalias.TButton] -column 1 -row $r -padx 5 -pady 10
}

proc p_pervadinti_klase {senas_klases_pavad naujas_klases_pavad} {
	set kl_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$senas_klases_pavad}]
	db3 eval {UPDATE klases SET klase=$naujas_klases_pavad WHERE Id=$kl_id}
	set visi_kompiuteriai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	foreach pc $visi_kompiuteriai {
		set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		p_send_command $nr "mv /home/mokytoja/mokiniu_failai/$senas_klases_pavad /home/mokytoja/mokiniu_failai/$naujas_klases_pavad"
	}
	p_perpiesti_klasiu_laukeli 2
}

proc p_klases_salinimas {klase} {
	set visi_kompiuteriai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	foreach pc $visi_kompiuteriai {
		set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		catch {p_send_command $nr "rm -rf /home/mokytoja/mokiniu_failai/$klase"}
	}
	set kl_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$klase}]
	set mok_ids [db3 eval {SELECT Id FROM mokiniai WHERE klases_id=$kl_id}]
	db3 eval {DELETE FROM klases WHERE klase=$klase}
	foreach mokid $mok_ids {
		db3 eval {UPDATE mokiniai SET esamas_ar_buves=0 WHERE Id=$mokid}
	}
	tk_messageBox -message "Pašalinta sėkmingai." -parent .n
	destroy .klasiu
	p_perpiesti_klasiu_laukeli 2
	set visos_klases [db3 eval {SELECT Id FROM klases}]
	if {$visos_klases != ""} {
		p_klasiu_laukeliu_piesimas ne
	} else {
		if {[info exists ::kl_sk]} {
			unset ::kl_sk
		}
		db1 eval "UPDATE klases_check SET ar_ivesta=0 WHERE Id=1"
		p_check
	}
}
#------------------------------------------------------------------------------------------------------------------------------------------------
proc p_mokiniu_ivedimo_pradzia {} {
#leidžia pasirinkti klasę, kuriai pridėsime mokinius arba juos peržiūrėsime
	p_naujas_langas .mok "Mokinių įvedimas"
	wm protocol .mok WM_DELETE_WINDOW {
		destroy .mok
		if {[info exists ::mklase]} {
			unset ::mklase
		}
	}
	set r 0
	set klases [db3 eval {SELECT klase FROM klases WHERE klase!="Testinė_klasė" ORDER BY klase}]
	set mokiniai [db3 eval {SELECT Id FROM mokiniai}]
	if {$mokiniai == ""} {
		grid [ttk::frame .mok.informacija -padding "20 20 20 5"] -column 0 -row $r -sticky nwes; incr r
		grid [ttk::label .mok.informacija.lbl -text "Norint, kad darbas su programa vyktų sklandžiai, kiekvienai klasei reikia suvesti mokinius bei jų sėdėjimo vietas." -wraplength 260 -style vidutinis.TLabel] -column 0 -row $r
	}
	grid [ttk::frame .mok.pradzia -padding "20 5 20 20"] -column 0 -row $r -sticky nwes
	grid [ttk::label .mok.pradzia.klaselbl -text "KLASĖ:"] -column 0 -row $r -pady 10 -sticky w
	grid [ttk::combobox .mok.pradzia.klase -textvariable ::mklase -width 8] -column 1 -row $r -pady 1 -padx 5; incr r
	.mok.pradzia.klase configure -values $klases
	incr r
	grid [ttk::label .mok.pradzia.kiekislbl -text "MOKINIŲ SKAIČIUS:"] -column 0 -row $r -pady 10 -sticky w
	grid [ttk::entry .mok.pradzia.kiekis -textvariable ::mkiekis -width 8] -column 1 -row $r -pady 1 -padx 5; incr r
	focus .mok.pradzia.kiekis
	bind .mok.pradzia.klase <<ComboboxSelected>> {destroy .mok; p_mokiniu_ivedimo_pradzia}
	if {[info exists ::mklase]} {
		set klasesid [db3 eval {SELECT Id FROM klases WHERE klase=$::mklase}]
		set klases_mokiniu_ids [db3 eval {SELECT Id FROM mokiniai WHERE klases_id=$klasesid AND esamas_ar_buves=1 ORDER BY pc_id}]
		if {$klases_mokiniu_ids != ""} {
			destroy .mok
			p_mokiniu_redagavimo_laukeliai $::mklase
			unset ::mklase
			return
		}
	}
	grid [ttk::button .mok.pradzia.toliau -text "Toliau >" -command "if {\[p_tikrinti_ivedima ::mkiekis {Neįvestas mokinių skaičius!}\]} {if {\[p_tikrinti_ivedima ::mklase {Neparinkta klasė!}\]} {destroy .mok; p_prideti_mokinius_i_tuscia_klase \$::mkiekis \$::mklase}}" -style mazaszalias.TButton] -column 0 -row $r -pady 10 -padx 10 -columnspan 2
}

proc p_tikrinti_mokiniu_laukelius {mok_sk klase w auto_generuoti} {
#patikrina, ar yra užpildyti visi laukeliai – mokinio vardas, pavardė, klasė, kompiuterio nr.
	puts $auto_generuoti
	if {$auto_generuoti == 0} {
		for {set i 1} {$i <= $mok_sk} {incr i} {
			if {![info exists ::mokpav$i] || ![info exists ::mokvard$i] || ![info exists ::mokklase$i] || ![info exists ::mokpc$i]} {
				#tk_messageBox -message "Ne visi privalomi laukeliai užpildyti!" -parent $w
				p_naujas_langas .artikrai "Klausimas"
				wm attribute .artikrai -topmost 1
				wm protocol .artikrai WM_DELETE_WINDOW {
					destroy .artikrai
					set ::testi 0
				}
				grid [ttk::frame .artikrai.klausimas -padding $::pad20] -column 0 -row 0 -sticky nwes
				set r 1
				grid [ttk::label .artikrai.klausimas.txt -text "Ne visi privalomi laukeliai užpildyti! Ką norite daryti?" -padding "5 5" -style didelis.TLabel -wraplength 350] -column 0 -columnspan 2 -row $r; incr r
				grid [ttk::button .artikrai.klausimas.taip -text "Sugeneruoti mokinių vardus automatiškai" -command "destroy .artikrai; p_tikrinti_mokiniu_laukelius $mok_sk $klase .mok 1" -padding $::pad10 -style zalias.TButton] -padx 1 -pady 1 -column 0 -row $r
				grid [ttk::button .artikrai.klausimas.ne -text "Atšaukti" -style raudonas.TButton -command "destroy .artikrai; set ::testi 0" -padding $::pad10] -padx 1 -pady 1 -column 1 -row $r; incr r
				tkwait window .artikrai
				return 0
			}
		}
		return 1
	} else {
		for {set i 1} {$i <= $mok_sk} {incr i} {
			if {![info exists ::mokpav$i]} {
				set ::mokpav$i $i
			}
			if {![info exists ::mokvard$i]} {
				set ::mokvard$i "Mokinys"
			}
			if {![info exists ::mokklase$i]} {
				set ::mokklase$i $klase
			}
			if {![info exists ::mokpc$i]} {
				set ::mokpc$i $i
			}
		}
		return 1
	}
}

proc p_prideti_mokinius_i_tuscia_klase {mok_sk isankstine_klase} {
#klasei, kurioje dar nėra mokinių, nupiešia laukelius ir leidzia į juos įrašyti mokinių duomenis - vardą, pavardę ir kt.
	if {[info exists ::mkiekis]} {
		unset ::mkiekis
	}
	if {[info exists ::mklase]} {
		unset ::mklase
	}
	p_naujas_langas .mok "Mokinių įvedimas"
	set ::mok_trynimui $mok_sk
	wm protocol .mok WM_DELETE_WINDOW {
		for {set i 1} {$i <= $::mok_trynimui} {incr i} {
			if {[info exists ::mokpav$i]} {
				unset ::mokpav$i
			}
			if {[info exists ::mokvard$i]} {
				unset ::mokvard$i
			}
			if {[info exists ::mokpast$i]} {
				unset ::mokpast$i
			}
			if {[info exists ::mokklase$i]} {
				unset ::mokklase$i
			}
			if {[info exists ::mokpc$i]} {
				unset ::mokpc$i
			}
		}
		destroy .mok
	}
	grid [ttk::frame .mok.ived -padding $::pad20] -column 0 -row 0 -sticky nwes
	set r 1
	set c 0
	grid [ttk::label .mok.ived.nrlbl -text "NR."] -column $c -row $r -pady 2; incr c
	grid [ttk::label .mok.ived.vardaslbl -text "VARDAS:"] -column $c -row $r -pady 2; incr c
	grid [ttk::label .mok.ived.pavardelbl -text "PAVARDĖ:"] -column $c -row $r -pady 2; incr c
	grid [ttk::label .mok.ived.klaselbl -text "KLASĖ:"] -column $c -row $r -pady 2; incr c
	grid [ttk::label .mok.ived.pclbl -text "SĖDĖJIMO VIETA \n(KOMPIUTERIO NR.):"] -column $c -row $r -pady 2; incr c
	grid [ttk::label .mok.ived.pastaboslbl -text "PASTABOS (NEPRIVALOMA):"] -column $c -row $r -pady 2; incr r
	set r [p_nupiesti_laukelius_mokiniu_ivedimui $mok_sk 1 $isankstine_klase $r 0]
	grid [ttk::button .mok.ived.prideti -text "Pridėti mokinį" -image ad16 -compound right -command "p_nupiesti_laukelius_mokiniu_ivedimui $mok_sk [expr $mok_sk+1] $isankstine_klase $r 1" -style mazas.TButton] -column 0 -row $r -pady 5 -columnspan 6; incr r
	grid [ttk::button .mok.ived.ok -text "Įrašyti" -image save_icon -compound right -command "if {\[p_tikrinti_mokiniu_laukelius $mok_sk $isankstine_klase .mok 0\]} {p_irasyti_mokini_i_db $mok_sk .mok.ived $isankstine_klase}" -style mazaszalias.TButton] -column 0 -row $r -pady 5 -columnspan 6; incr r
}

proc p_nupiesti_laukelius_mokiniu_ivedimui {mok_sk i_pradine isankstine_klase r ar_paspaude_plius} {
#nupiešia laukelius, į kuriuos galima įrašyti mokinių vardus, pavardes ir kt.
	set kompiuteriai [db3 eval {SELECT Id FROM kompiuteriai ORDER BY Id}]
	if {$i_pradine != 1} {
		incr mok_sk
	}
	for {set i $i_pradine} {$i <= $mok_sk} {incr i} {
		set c 0
		set ::mokklase$i $isankstine_klase
		grid [ttk::label .mok.ived.nrlbl$i -text "$i."] -column $c -row $r -pady 2; incr c
		grid [ttk::entry .mok.ived.vardas$i -textvariable ::mokvard$i -width 20 -validate key -validatecommand {p_replace_spaces %W %S %i %d}] -column $c -row $r -pady 1 -padx 1; incr c
		grid [ttk::entry .mok.ived.pavarde$i -textvariable ::mokpav$i -width 20 -validate key -validatecommand {p_replace_spaces %W %S %i %d}] -column $c -row $r -pady 1 -padx 1; incr c
		grid [ttk::label .mok.ived.klase$i -text $isankstine_klase] -column $c -row $r -pady 1 -padx 1; incr c
		grid [ttk::combobox .mok.ived.pc$i -textvariable ::mokpc$i -width 15] -column $c -row $r -pady 1 -padx 1; incr c
		grid [ttk::entry .mok.ived.pastabos$i -textvariable ::mokpast$i -width 30] -column $c -row $r -pady 1 -padx 1; incr r
		.mok.ived.pc$i configure -values $kompiuteriai
	}
	if {$ar_paspaude_plius == 1} {
		grid .mok.ived.prideti -row $r; incr r
		grid .mok.ived.ok -row $r; incr r
		.mok.ived.prideti configure -command "p_nupiesti_laukelius_mokiniu_ivedimui $mok_sk [expr $mok_sk+1] $isankstine_klase $r 1"
	}
	return $r
}

proc p_irasyti_mokini_i_db {mok_sk w klase} {
#patikrina laukelius. Jeigu laukeliai užpildyti, įrašo naują/naujus mokinius į db, pakeičia klasės mokinių ids ir pereina prie procedūros, kuri išsaugoja padarytus mokinių pakeitimus, jei tokie yra.
	for {set i 1} {$i <= $mok_sk} {incr i} {
		if {$w == ".mokiniu.redag"} {
			set i $mok_sk
		}
		set mvardas "[$w.vardas$i get]"
		set mpavarde "[$w.pavarde$i get]"
		set mpastabos "[$w.pastabos$i get]"
		set mpc "[$w.pc$i get]"
		if {$mvardas == "" || $mpavarde == "" || $mpc == ""} {
			tk_messageBox -message "Ne visi laukeliai užpildyti!" -parent $w
			return 0
		}
	}
	for {set i 1} {$i <= $mok_sk} {incr i} {
		if {$w == ".mokiniu.redag"} {
			set i $mok_sk
		}
		set mvardas "[$w.vardas$i get]"
		set mpavarde "[$w.pavarde$i get]"
		set mpastabos "[$w.pastabos$i get]"
		set klases_id [db3 eval {SELECT Id FROM klases WHERE klase=$klase}]
		set mpc "[$w.pc$i get]"
		db3 eval {INSERT INTO mokiniai(vardas, pavarde, pastabos, klases_id, pc_id, esamas_ar_buves) VALUES($mvardas, $mpavarde, $mpastabos, $klases_id, $mpc, 1)}
		if {$w != ".mokiniu.redag"} {
			$w.vardas$i delete 0 end
			$w.pavarde$i delete 0 end
			$w.pastabos$i delete 0 end
			$w.pc$i delete 0 end
		}
	}
	if {$w == ".mokiniu.redag"} {
		set ::klases_mokiniu_ids [db3 eval {SELECT Id FROM mokiniai WHERE klases_id=$klases_id AND esamas_ar_buves=1 ORDER BY pc_id}]
	} else {
		tk_messageBox -message "Mokiniai sėkmingai sukurti." -parent $w
	}
	set mokiniai [db3 eval {SELECT Id FROM mokiniai}]
	if {$mokiniai != ""} {
		db1 eval "INSERT OR REPLACE INTO mokiniai_check(Id, ar_ivesta) VALUES(1, 1)"
	}
	destroy .mok
	return 1
}

proc p_mokiniu_redagavimo_laukeliai {klase} {
#jei klasėje yra mokinių, juos visus parodo ir leidžia juos pakeisti, o jei nėra, pereina prie kitos procedūros, kuri leidžia sukurti mokinius
	if {$klase == ""} {
		p_mokiniu_ivedimo_pradzia
		return
	}
	p_naujas_langas .mokiniu "Mokinių redagavimas"
	wm protocol .mokiniu WM_DELETE_WINDOW {
		destroy .mokiniu
		if {[info exists ::mklase]} {
			unset ::mklase
		}
		foreach mokid $::klases_mokiniu_ids {
			if {[info exists ::mokpav$mokid]} {
				unset ::mokpav$mokid
			}
			if {[info exists ::mokvard$mokid]} {
				unset ::mokvard$mokid
			}
			if {[info exists ::mokpast$mokid]} {
				unset ::mokpast$mokid
			}
			if {[info exists ::mokklase$mokid]} {
				unset ::mokklase$mokid
			}
			if {[info exists ::mokpc$mokid]} {
				unset ::mokpc$mokid
			}
		}
	}
	if {[info exists ::klases_mokiniu_ids]} {
		foreach mokid $::klases_mokiniu_ids {
			if {[info exists ::mokpav$mokid]} {
				unset ::mokpav$mokid
			}
			if {[info exists ::mokvard$mokid]} {
				unset ::mokvard$mokid
			}
			if {[info exists ::mokpast$mokid]} {
				unset ::mokpast$mokid
			}
			if {[info exists ::mokpc$mokid]} {
				unset ::mokpc$mokid
			}
		}
	}
	set ::ar_pridejo_mokini 0
	set klases [db3 eval {SELECT klase FROM klases ORDER BY klase}]
	set kompiuteriai [db3 eval {SELECT Id FROM kompiuteriai ORDER BY Id}]
	set ::mokklase $klase
	set r 0
	grid [ttk::frame .mokiniu.redag -padding "20 20 20 0"] -column 0 -row $r -sticky nwes; incr r
	grid [ttk::label .mokiniu.redag.lbl1klase -text "KLASĖ:"] -column 0 -row $r -pady 2
	grid [ttk::combobox .mokiniu.redag.irasykklase -textvariable ::mokklase -width 10] -column 1 -row $r -pady 1 -padx 1
	.mokiniu.redag.irasykklase configure -values $klases
	bind .mokiniu.redag.irasykklase <<ComboboxSelected>> {destroy .mokiniu; p_mokiniu_redagavimo_laukeliai $::mokklase}
	incr r
	set klasesid [db3 onecolumn {SELECT Id FROM klases WHERE klase=$::mokklase}]
	#kintamasis yra globalus, nes mokiniai gali būti iš įvairių klasių ir šito kintamojo reikės kitai procedūrai
	set ::klases_mokiniu_ids [db3 eval {SELECT Id FROM mokiniai WHERE klases_id=$klasesid AND esamas_ar_buves=1 ORDER BY pc_id}]
	if {$::klases_mokiniu_ids != ""} {
		set c 0
		grid [ttk::label .mokiniu.redag.lblnr -text "NR."] -column $c -row $r -pady 2; incr c
		grid [ttk::label .mokiniu.redag.lblvardas -text "VARDAS:"] -column $c -row $r -pady 2; incr c
		grid [ttk::label .mokiniu.redag.lblpavarde -text "PAVARDĖ:"] -column $c -row $r -pady 2; incr c
		grid [ttk::label .mokiniu.redag.lblpcnr -text "SĖDĖJIMO VIETA \n(KOMPIUTERIO NR.):"] -column $c -row $r -pady 2; incr c
		grid [ttk::label .mokiniu.redag.lblpastabos -text "PASTABOS (NEPRIVALOMA):"] -column $c -row $r -pady 2
		incr r
		set nr 1
		foreach mokid $::klases_mokiniu_ids {
			lassign [db3 eval {SELECT vardas, pavarde, pc_id, pastabos FROM mokiniai WHERE Id=$mokid}] ::mokvard$mokid ::mokpav$mokid ::mokpc$mokid ::past$mokid
			set c 0
			grid [ttk::label .mokiniu.redag.lblnr$mokid -text "$nr."] -column $c -row $r -pady 2; incr c
			grid [ttk::entry .mokiniu.redag.vardas$mokid -textvariable ::mokvard$mokid -width 20] -column $c -row $r -pady 1 -padx 1; incr c
			grid [ttk::entry .mokiniu.redag.pavarde$mokid -textvariable ::mokpav$mokid -width 20] -column $c -row $r -pady 1 -padx 1; incr c
			grid [ttk::combobox .mokiniu.redag.pc$mokid -textvariable ::mokpc$mokid -width 15 -state readonly] -column $c -row $r -pady 1 -padx 1; incr c
			.mokiniu.redag.pc$mokid configure -values $kompiuteriai
			grid [ttk::entry .mokiniu.redag.pastabos$mokid -textvariable ::past$mokid -width 30] -column $c -row $r -pady 1 -padx 1; incr c
			grid [ttk::button .mokiniu.redag.salint$mokid -text "" -image rem8 -command "p_ar_tikrai \"Ar tikrai norite pašalinti mokinį „[set ::mokvard$mokid] [set ::mokpav$mokid] $klase“?\" {p_padaryti_mokini_buvusiu .mokiniu $mokid $klase}" -style permatomas.TButton] -column $c -row $r -pady 1 -padx 1
			incr r; incr nr
		}
		grid [ttk::button .mokiniu.redag.prideti -text "Pridėti mokinį" -image ad16 -compound right -command "p_prideti_laukeli_mokiniui $r $nr \"$klases\" \"$kompiuteriai\" $klase" -style mazas.TButton] -column 0 -row $r -pady 5 -columnspan 6; incr r
		grid [ttk::frame .mokiniu.mygtukai -padding "20 0 20 20"] -column 0 -row $r -sticky nwes; incr r
		set paaiskinimas "Galite iš karto sukeisti visų mokinių sėdėjimo vietas (tik teks šiek tiek palaukti, kol mokinių failai kompiuteriuose susikeis)."
		grid columnconfigure .mokiniu.mygtukai 0 -weight 1
		grid columnconfigure .mokiniu.mygtukai 1 -weight 1
		grid [ttk::button .mokiniu.mygtukai.saugoti -text "Įrašyti pakeitimus" -image save_icon -compound right -command "p_pakeisti_mokinius_duombazeje $klase" -style mazaszalias.TButton] -column 0 -row $r -pady 5 -padx 5 -sticky e
		grid [ttk::button .mokiniu.mygtukai.info -text "" -image klaus32 -command "tk_messageBox -message \"$paaiskinimas\" -parent .mokiniu" -style mazaszalias.TButton] -column 1 -row $r -pady 5 -padx 5 -sticky w
	} else {
		destroy .mokiniu
		set ::mklase $klase
		p_mokiniu_ivedimo_pradzia
		return
	}
}

proc p_prideti_laukeli_mokiniui {r nr klases kompiuteriai klase} {
#nupiešia laukelius naujo mokinio duomenims įvesti
	if {$::ar_pridejo_mokini == 1} {
		tk_messageBox -message "Norint pridėti dar vieną mokinį, reikia įrašyti pakeitimus." -parent .mokiniu
		return
	}
	set i [expr [db3 onecolumn {SELECT MAX(Id) FROM mokiniai}]+1]
	set c 0
	grid [ttk::label .mokiniu.redag.lblnr$i -text "$nr." ] -column $c -row $r -pady 2; incr c
	grid [ttk::entry .mokiniu.redag.vardas$i -textvariable ::mokvard$i -width 20 -validate key -validatecommand {p_replace_spaces %W %S %i %d}] -column $c -row $r -pady 1 -padx 1; incr c
	grid [ttk::entry .mokiniu.redag.pavarde$i -textvariable ::mokpav$i -width 20 -validate key -validatecommand {p_replace_spaces %W %S %i %d}] -column $c -row $r -pady 1 -padx 1; incr c
	grid [ttk::combobox .mokiniu.redag.pc$i -textvariable ::mokpc$i -width 15 -state readonly] -column $c -row $r -pady 1 -padx 1; incr c
	grid [ttk::entry .mokiniu.redag.pastabos$i -textvariable ::past$i -width 30] -column $c -row $r -pady 1 -padx 1; incr c
	grid [ttk::button .mokiniu.redag.salint$i -text "" -image rem8 -command "p_ar_mokinys_egzistuoja $i $r $klase" -style permatomas.TButton] -column $c -row $r -pady 1 -padx 1; incr r
	.mokiniu.redag.pc$i configure -values $kompiuteriai
	grid .mokiniu.redag.prideti -row $r; incr r
	grid .mokiniu.mygtukai -row $r; incr r
	set ::ar_pridejo_mokini 1
	set ::naujo_mok_id $i
}

proc p_ar_mokinys_egzistuoja {i r klase} {
#patikrina, ar šalinamas mokinys egzistuoja ir paklausia, ar tikrai jį pašalinti
	set max_id [db3 eval {SELECT MAX(Id) FROM mokiniai}]
	if {$i == $max_id} {
		p_ar_tikrai "Ar tikrai norite pašalinti mokinį „[set ::mokvard$i] [set ::mokpav$i] $klase“?" {p_padaryti_mokini_buvusiu .mokiniu $i $klase}
	} else {
		destroy .mokiniu.redag.pavarde$i .mokiniu.redag.vardas$i .mokiniu.redag.klase$i .mokiniu.redag.pc$i .mokiniu.redag.pastabos$i .mokiniu.redag.salint$i
	}
}

proc p_padaryti_mokini_buvusiu {w mokid klase} {
#pašalina mokinį iš klasės ir padaro jį buvusiu mokiniu. Duomenų bazėje jis lieka, tačiau programoje nebesimato
	db3 eval {UPDATE mokiniai SET esamas_ar_buves=0 WHERE Id=$mokid}
	destroy $w
	p_mokiniu_redagavimo_laukeliai $klase
}

proc p_pakeisti_mokinius_duombazeje {klase} {
#suranda visus padarytus pakeitimus ir juos išsaugoja
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$klase}]
	set ivesti_kompiuteriai ""
	foreach mokid $::klases_mokiniu_ids {
		lappend ivesti_kompiuteriai "[.mokiniu.redag.pc$mokid get]"
	}
	if {$::ar_pridejo_mokini == 1} {
		lappend ivesti_kompiuteriai "[.mokiniu.redag.pc$::naujo_mok_id get]"
	}
	set ar_yra_vienodu [expr {[lsort $ivesti_kompiuteriai] eq [lsort -unique $ivesti_kompiuteriai]}]
	if {$ar_yra_vienodu == 0} {
		tk_messageBox -message "Visi kompiuterių numeriai turi būti skirtingi!" -parent .mokiniu
		return
	}
	if {$::ar_pridejo_mokini == 1} {
	#kita eilutė patikrina, ar gerai užpildyti laukeliai. Jei viskas gerai, įrašo į db naują mokinį, pakeičia klasės mokinių ids bei kintamąjį „ar_testi“ pakeičia į 1. Jei ne, „ar_testi“ pakeičia į 0 ir naujų mokinių į db neįrašo.
		set ar_testi [p_irasyti_mokini_i_db $::naujo_mok_id .mokiniu.redag $klase]
	} else {
		set ar_testi 1
	}
	if {$ar_testi == 0} {
		return
	}
	tk_messageBox -message "Išsaugomi pakeitimai... Laukite pranešimo „Pakeitimai išsaugoti“." -parent .mokiniu
	.mokiniu.mygtukai.saugoti configure -text "Dirbama..." -state disabled
	wm protocol .mokiniu WM_DELETE_WINDOW { }
	set buve_pc_ids ""
	set nauji_pc_ids ""
	foreach mokid $::klases_mokiniu_ids {
		set naujas_vardas "[.mokiniu.redag.vardas$mokid get]"
		set nauja_pavarde "[.mokiniu.redag.pavarde$mokid get]"
		set naujas_pc_id "[.mokiniu.redag.pc$mokid get]"
		set naujos_pastabos "[.mokiniu.redag.pastabos$mokid get]"
		lassign [db3 eval {SELECT vardas, pavarde, pc_id, pastabos FROM mokiniai WHERE Id=$mokid}] buves_vardas buvusi_pavarde buves_pcid buvusios_pastabos
		set pc_naujas [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$naujas_pc_id}]
		set pc_buves [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$buves_pcid}]
		set msg1 [cant_ping $pc_naujas]
		set msg2 [cant_ping $pc_buves]
		.mokiniu.redag.lblnr$mokid configure -image correct
		update idletasks
		if {$naujas_vardas != $buves_vardas} {
			db3 eval {UPDATE mokiniai SET vardas=$naujas_vardas WHERE Id=$mokid}
		}
		if {$nauja_pavarde != $buvusi_pavarde} {
			db3 eval {UPDATE mokiniai SET pavarde=$nauja_pavarde WHERE Id=$mokid}
		}
		if {$naujos_pastabos != $buvusios_pastabos} {
			db3 eval {UPDATE mokiniai SET pastabos=$naujos_pastabos WHERE Id=$mokid}
		}
		if {$naujas_pc_id != $buves_pcid} {
			if {$msg1 == 1 || $msg2 == 1} {
				tk_messageBox -message "Kompiuteriai, kurių failai sukeičiami, turi būti įjungti! Įjunkite kompiuterius ir mėginkite iš naujo." -parent .mokiniu
			return
			}
			lappend buve_pc_ids $buves_pcid
			lappend nauji_pc_ids $naujas_pc_id
			db3 eval {UPDATE mokiniai SET pc_id=$naujas_pc_id WHERE Id=$mokid}
			p_kopiju_sutvarkymas $buves_pcid $naujas_pc_id $klase
		}
	}
	destroy .mokiniu
	.informacija.atlikta configure -text "Sukeičiami failai... palaukite..."
	update idletasks
	set j 0
	foreach buves_pc_id $buve_pc_ids {
		p_mokinio_failu_isvalymas $buves_pc_id $klase dabartiniai
		p_mokinio_failu_isvalymas $buves_pc_id $klase seni
		incr j
	}
	set k 0
	foreach buves_pc_id $buve_pc_ids {
		set naujas_pc_id [lindex $nauji_pc_ids $k]
		p_nauju_mokinio_failu_ikelimas $buves_pc_id $naujas_pc_id $klase dabartiniai
		p_nauju_mokinio_failu_ikelimas $buves_pc_id $naujas_pc_id $klase seni
		incr k
		set nr [expr $buves_pc_id - 1]
		lassign [db3 eval {SELECT Id, vardas, pavarde FROM mokiniai WHERE klases_id=$klases_id AND pc_id = $buves_pc_id}] mok_id vardas pavarde
		if {$mok_id != ""} {
			.kompiuteriai.$nr configure -text "$vardas \n$pavarde"
		}
		p_icon_keitimas [expr $buves_pc_id - 1] pccheck
	}
	p_veiksmas_atliktas "Pakeitimai išsaugoti."
	exec sh -c "rm -rf ./laikini_mokiniu_failai/*"
	if {$::ar_pridejo_mokini == 1} {
		tkwait window .informacija.ok
		p_mokiniu_redagavimo_laukeliai $klase
	}
}

proc p_kopiju_sutvarkymas {buves_pc_id naujas_pc_id klase} {
	exec mkdir -p ./laikini_mokiniu_failai/$buves_pc_id
	exec mkdir -p ./laikini_mokiniu_failai/$naujas_pc_id
	p_senu_kopiju_isvalymas $buves_pc_id
	p_senu_kopiju_isvalymas $naujas_pc_id
	p_kopijos_padarymas $buves_pc_id $klase
	p_kopijos_padarymas $naujas_pc_id $klase
}

proc p_kopijos_padarymas {pc_id klase} {
	set pc [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$pc_id}]
	catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 -r mokytoja@$pc:/home/mokytoja/mokiniu_failai/$klase/* ./laikini_mokiniu_failai/$pc_id/"}
}

proc p_mokinio_failu_isvalymas {pc_id klase f} {
	set pc [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$pc_id}]
	catch {exec -ignorestderr ssh -o ConnectTimeout=1 mokytoja@$pc "sudo rm -rf /home/mokytoja/mokiniu_failai/$klase/$f/*"}
}

proc p_nauju_mokinio_failu_ikelimas {pc_id naujas_pc_id klase f} {
	set naujas_pc [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$naujas_pc_id}]
	set pc [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$pc_id}]
	catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 -r ./laikini_mokiniu_failai/$pc_id/$f/* mokytoja@$naujas_pc:/home/mokytoja/mokiniu_failai/$klase/$f"}
	set permissions "
		sudo chmod -R a+rwx /home/mokytoja/mokiniu_failai/$klase/$f;
		sudo chown -R mokinys:mokinys /home/mokytoja/mokiniu_failai/$klase/$f
	"
	catch {exec -ignorestderr ssh -o ConnectTimeout=1 mokytoja@$naujas_pc sh -c '$permissions'}
}

proc p_senu_kopiju_isvalymas {pc_id} {
	catch {exec -ignorestderr sh -c "rm -rf ./laikini_mokiniu_failai/$pc_id/*"}
}
#------------------------------------------------------------------------------------------------------------------------------------------------
proc p_aplankai {ar_pirmas_kartas} {
	set pc_patikrinimas [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	if {$pc_patikrinimas == ""} {
		tk_messageBox -message "Nėra įvesta kompiuterių ir jų adresų. Visų pirma suveskite kompiuterius (Nustatymai -> Kompiuteriai ir IP adresai...), o po to sukurkite aplankus." -parent .n
		return
	}
	set w .aplanku
	p_naujas_langas $w "Aplankų kūrimas"
	set r 0
	set paaiskinimas "Paspaudus mygtuką „Paruošti“, bus sukurti visi reikalingi aplankai mokinių kompiuteriuose, kad darbas su jais vyktų sklandžiai. Nesukūrus aplankų, ši programa bus visiškai arba iš dalies nefunkcionali. Dėl šios priežasties įsitikinkite, kad aplankų kūrimo metu visi mokinių kompiuteriai yra įjungti. Kilus kokiems nors nesklandumams, aplankus bet kada galėsite sukurti iš naujo, paspaudę meniu „Nustatymai -> Kompiuterių paruošimas darbui...“"
	grid [ttk::frame $w.kurimas -padding $::pad20] -column 0 -row $r -sticky nwes; incr r
	grid [ttk::label $w.kurimas.paaiskinimas -text "Paruošti mokinių kompiuterius:"] -pady 10 -column 0 -row $r -columnspan 2; incr r
	grid [ttk::button $w.kurimas.sukurti -text "Paruošti" -command "p_aplanku_kurimas $ar_pirmas_kartas $w" -padding "5 8 5 8"] -pady 10 -column 0 -row $r
	grid [ttk::button $w.kurimas.informacija -text "" -image klaus24 -command "tk_messageBox -message \"$paaiskinimas\" -parent $w" -style mazaszalias.TButton] -pady 10 -column 1 -row $r
	setTooltip $w.kurimas.informacija "Informacija"
}

proc p_aplanku_kurimas {ar_pirmas_kartas w} {
	if {$ar_pirmas_kartas == "pirmas"} {
		set w .aplanku
		p_naujas_langas $w "Aplankų kūrimas"
	} 
	if {$ar_pirmas_kartas  != "pirmas"} {
		tk_messageBox -message "Spauskite mygtuką „OK“ ir palaukite, kol bus sukurti reikalingi aplankai mokinių kompiuteriuose." -parent $w
	}
	destroy $w
	.informacija.atlikta configure -text "Kuriami aplankai... palaukite..."
	update idletasks
	set pranesimas "Reikalingi aplankai sukurti."
	set visi_kompiuteriai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	set komandos1 "
		sudo chmod -R a+rwx /home/mokytoja/atsiskaitymai;
		sudo chmod -R a+rwx /home/mokytoja/uzduotys;
		sudo chmod -R a+rwx /home/mokytoja/pranesimai/;
		cd /; sudo mkdir skriptai;
		sudo chmod o+w /skriptai/
		sudo chmod o+rx /skriptai/*
		sudo chmod o-w /skriptai/*
	"
	set komandos2 "
		cd /home/mokinys; sudo mkdir Nuo_mokytojos
		sudo chown mokinys:mokinys /home/mokinys/;
		sudo chmod o+rx /home/mokinys/;
		sudo chown mokytoja:mokytoja /home/mokinys/Nuo_mokytojos;
		sudo chmod +t /home/mokinys/;
		sudo chmod o-w /home/mokinys/Nuo_mokytojos;
		sudo chmod o+rx /home/mokinys/Nuo_mokytojos;
		sudo chmod +t /home/mokinys/Nuo_mokytojos;
		sudo touch /home/mokinys/Nuo_mokytojos/.keeper;
		sudo chown mokytoja:mokytoja /home/mokinys/Nuo_mokytojos/.keeper;
		sudo chattr +i /home/mokinys/Nuo_mokytojos/.keeper;
		sudo chown -R mokinys:mokinys /home/mokinys/.config/ibus/;
		cd /home/mokytoja/; mkdir Backups_mokinio;
		sudo cp -r /home/mokinys/ /home/mokytoja/Backups_mokinio;
		sudo chmod o+x /home/mokytoja/
		sudo chmod o-r /home/mokytoja/
	"
	set komandos3 "
		sudo cp /home/mokytoja/mokinio_nustatymai.sh /etc/init.d/;
		sudo chmod a+x /etc/init.d/mokinio_nustatymai.sh;
		echo \"\[Unit\]\nDescription=Settings reset\n\n\[Service\]\nType=oneshot\nExecStart=/etc/init.d/mokinio_nustatymai.sh\n\n\[Install\]\nWantedBy=multi-user.target\" > /tmp/settings_reset.service
		sudo mv /tmp/settings_reset.service /etc/systemd/system/settings_reset.service
		sudo systemctl enable settings_reset
	"
	foreach pc $visi_kompiuteriai {
		set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		set msg [cant_ping $pc]
		if {$msg == 1} {
			set pranesimas "Aplankai sukurti, bet ne visiems"
			p_icon_keitimas $nr pcunr
		} else {
			puts "nr $nr"
			p_icon_keitimas $nr pccheck
			puts "kuriami aplankai..."
			p_send_command $nr "cd /home/mokytoja/; mkdir atsiskaitymai uzduotys mokiniu_failai pranesimai"
			catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 ./Programos_failai/zinute_random.tcl mokytoja@$pc:/home/mokytoja/pranesimai/"}
			p_send_command $nr $komandos1
			catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 ./Programos_failai/Testas.tcl ./Programos_failai/atsakymai.tcl ./Programos_failai/atsiskaitymas.tcl ./icons/correct.png ./icons/wrong.png ./icons/Save.png ./icons/Restart32.png ./icons/bullet.png mokytoja@$pc:/skriptai/"}
			p_send_command $nr $komandos2
			catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 ./Programos_failai/mokinio_nustatymai.sh mokytoja@$pc:/home/mokytoja/"}
			p_send_command $nr $komandos3
		}
	}
	p_veiksmas_atliktas $pranesimas
	if {$ar_pirmas_kartas == "pirmas"} {
		db1 eval "INSERT OR REPLACE INTO aplankai_check(Id, ar_ivesta) VALUES(1, 1)"
		p_check
	}
}
#--------------------------------------------------------------------------------------------------------------------------------
proc p_tagu_kurimas {} {
	set ::tagpavad ""
	set ::tagulistas [db3 eval {SELECT name, type FROM tagai ORDER BY type}]
	p_naujas_langas .tagai "Žymų sukūrimas"
	set tagtipai "Tema Klasė \"Sunkumo lygis\" \"Klausimo tipas\" Lankomumas Klaida \"Darbo variantas\" \"Pamokos tema\""
	set r 0
	grid [ttk::frame .tagai.f -padding $::pad10] -column 0 -row $r -sticky news; incr r
	grid [ttk::label .tagai.f.combopavad -text "Žymos tipas:" -padding $::pad10] -column 0 -row $r -pady 5 -padx 5 -sticky w
	grid [ttk::combobox .tagai.f.combo -textvariable ::tagtipas -width 25] -column 1 -row $r -pady 5 -padx 5; incr r
	.tagai.f.combo configure -values $tagtipai
	grid [ttk::label .tagai.f.pavad -text "Žymos pavadinimas:" -padding $::pad10] -column 0 -row $r -pady 5 -padx 5 -sticky w
	grid [ttk::entry .tagai.f.epavad -textvariable ::tagpavad -width 27] -column 1 -row $r -pady 5 -padx 5; incr r
	focus .tagai.f.epavad
	grid [ttk::label .tagai.f.tagexists -text "Egzistuojančios žymos:" -padding $::pad10] -column 0 -row $r -pady 5 -padx 5 -columnspan 2; incr r
	grid [tk::listbox .tagai.f.tagulist -yscrollcommand ".tagai.f.s set" -height 10 -width 30 -listvariable $::tagulistas -font "ubuntu 10" -selectbackground $::spalva] -column 0 -row $r -sticky news -columnspan 2
	grid [scrollbar .tagai.f.s -command ".tagai.f.tagulist yview" -orient vertical] -column 2 -row $r -sticky ns; incr r
	grid rowconfigure .tagai.f.s 0 -weight 1
	grid columnconfigure .tagai.f.s 0 -weight 1
	for {set i 0} {$i<[llength $::tagulistas]} {incr i} {
		.tagai.f.tagulist insert end "[lindex $::tagulistas [expr $i+1]] – [lindex $::tagulistas $i]"
		incr i
	}
	grid [ttk::button .tagai.f.nbutton -text "Išsaugoti žymą" -image save_icon -compound right -command "destroy .tagai; p_tagu_pridejimas_i_db; p_tagu_kurimas" -style mazaszalias.TButton] -column 0 -row $r -pady 5 -padx 5 -columnspan 2; incr r
}

proc p_tagu_pridejimas_i_db {} {
	db3 eval {INSERT INTO tagai(name, type) VALUES($::tagpavad, $::tagtipas)}
}
#----------------------------------------------------------------------------------------------------------------------------------------------
#šios procedūros padaro, kad rodytų tekstą, užėjus su pelyte ant mygtuko
proc setTooltip {widget text} {
	if { $text != "" } {
# 2) Adjusted timings and added key and button bindings. These seem to make artifacts tolerably rare.
		bind $widget <Any-Enter>    [list after 500 [list showTooltip %W $text]]
		bind $widget <Any-Leave>    [list after 500 [list destroy %W.tooltip]]
		bind $widget <Any-KeyPress> [list after 500 [list destroy %W.tooltip]]
		bind $widget <Any-Button>   [list after 500 [list destroy %W.tooltip]]
	}
}

 proc showTooltip {widget text} {
        global tcl_platform
        if { [string match $widget* [winfo containing  [winfo pointerx .] [winfo pointery .]] ] == 0  } {
                return
        }
        catch { destroy $widget.tooltip }
        set scrh [winfo screenheight $widget]    ; # 1) flashing window fix
        set scrw [winfo screenwidth $widget]     ; # 1) flashing window fix
        set tooltip [toplevel $widget.tooltip -bd 1 -bg black]
        wm geometry $tooltip +$scrh+$scrw        ; # 1) flashing window fix
        wm overrideredirect $tooltip 1

        if {$tcl_platform(platform) == {windows}} { ; # 3) wm attributes...
                wm attributes $tooltip -topmost 1   ; # 3) assumes...
        }                                           ; # 3) Windows
        pack [label $tooltip.label -bg lightyellow -fg black -text $text -justify left]
        set width [winfo reqwidth $tooltip.label]
        set height [winfo reqheight $tooltip.label]
        set pointer_below_midline [expr [winfo pointery .] > [expr [winfo screenheight .] / 2.0]]                ; # b.) Is the pointer in the bottom half of the screen?
        set positionX [expr [winfo pointerx .] - round($width / 2.0)]    ; # c.) Tooltip is centred horizontally on pointer.
        set positionY [expr [winfo pointery .] + 35 * ($pointer_below_midline * -2 + 1) - round($height / 2.0)]  ; # b.) Tooltip is displayed above or below depending on pointer Y position.
        # a.) Ad-hockery: Set positionX so the entire tooltip widget will be displayed.
        # c.) Simplified slightly and modified to handle horizontally-centred tooltips and the left screen edge.
        if  {[expr $positionX + $width] > [winfo screenwidth .]} {
                set positionX [expr [winfo screenwidth .] - $width]
        } elseif {$positionX < 0} {
                set positionX 0
        }
        wm geometry $tooltip [join  "$width x $height + $positionX + $positionY" {}]
        raise $tooltip
        # 2) Kludge: defeat rare artifact by passing mouse over a tooltip to destroy it.
        bind $widget.tooltip <Any-Enter> {destroy %W}
        bind $widget.tooltip <Any-Leave> {destroy %W}
 }
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_f4_korteles_informacija {} {
	tk_messageBox -message "Surinkti testo, apklausų arba atsiskaitymų rezultatus reikia tik tada, kai jie automatiškai neatsisiuntė dėl kokios nors priežasties (pavyzdžiui, išsijungė kuris nors kompiuteris). O jeigu viskas vyko sklandžiai, visi atsakymai turėjo atsisiųsti automatiškai. Jeigu nėra aišku, ar testo rezultatai atsisiuntė, ar ne, galima juos pamėginti surinkti – susidubliuoti testų rezultatai neturėtų." -parent .n
}
#Lango kortelės:
set r 0
set c 0
set x 12
set y 3
set ::pcvisi 0
set ::pclyg 0
set ::pcnelyg 0
set baltasf "baltas.TFrame"
grid [ttk::frame .n.f1.veiksmai -style $baltasf] -column $c -row $r -pady 5
grid [ttk::frame .n.f2.variantai -style $baltasf] -column $c -row $r -pady 5
grid [ttk::frame .n.f4.kiti -style $baltasf] -column $c -row $r -pady 5
grid [ttk::frame .n.f5.tvarkymas -style $baltasf] -column $c -row $r -pady 5
grid [ttk::frame .n.f6.testai -style $baltasf] -column $c -row $r -pady 5
incr r
grid [ttk::button .n.f1.veiksmai.mount -text "" -image show_icon -command "p_ikelti_aplankus paprasta_pamoka"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.mount "Įkelti mokinių failus"
grid [ttk::button .n.f1.veiksmai.unmount -text "" -image hide_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_UNMOUNT]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.unmount "Paslėpti mokinių failus"
grid [ttk::button .n.f1.veiksmai.lessonend -text "" -image clock_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_ENDLESSON]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.lessonend "Užbaigti pamoką"
grid [ttk::button .n.f1.veiksmai.siustif -text "" -image mailsend -command "p_failu_siuntimo_langas siuntimas"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.siustif "Siųsti failą"
grid [ttk::button .n.f1.veiksmai.testas -text "" -image test_icon -command "p_testu_parinkimo_langas 1"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.testas "Pradėti testą"
grid [ttk::button .n.f1.veiksmai.praktinis -text "" -image table -command "p_failu_siuntimo_langas atsiskaitymas"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.praktinis "Pradėti atsiskaitymą"
grid [ttk::button .n.f1.veiksmai.istaisyti -text "" -image upload_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_GRADED]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.istaisyti "Įkelti ištaisytus darbus"
grid [ttk::button .n.f1.veiksmai.interneton -text "" -image network32 -command "p_veiksmai_su_kompiuteriais [CONST ACT_UNBLOCK]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.interneton "Atblokuoti prieigą prie naršyklių"
grid [ttk::button .n.f1.veiksmai.internetoff -text "" -image network32close -command "p_veiksmai_su_kompiuteriais [CONST ACT_BLOCK]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.internetoff "Blokuoti prieigą prie naršyklių"
grid [ttk::button .n.f1.veiksmai.apklausa -text "" -image pie_icon -command "p_testu_parinkimo_langas 0"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f1.veiksmai.apklausa "Pradėti apklausą"

set c 0
grid [ttk::button .n.f2.variantai.b1 -text "1" -command "p_priskirti_varianta 1" -image var1 -width 5] -column $c -row $r -pady $y -padx $x; incr c
grid [ttk::button .n.f2.variantai.b2 -text "2" -command "p_priskirti_varianta 2" -image var2 -width 5] -column $c -row $r -pady $y -padx $x; incr c
grid [ttk::button .n.f2.variantai.b3 -text "3" -command "p_priskirti_varianta 3" -image var3 -width 5] -column $c -row $r -pady $y -padx $x; incr c
grid [ttk::button .n.f2.variantai.b4 -text "4" -command "p_priskirti_varianta 4" -image var4 -width 5] -column $c -row $r -pady $y -padx $x; incr c
grid [ttk::button .n.f2.variantai.bisvalyti -text "" -command "p_isvalyti_variantus" -image rem32 -width 5 -style permatomas.TButton] -column $c -row $r -pady $y -padx $x
setTooltip .n.f2.variantai.bisvalyti "Išvalyti variantus"

set c 0
grid [ttk::button .n.f4.kiti.surinkti -text "" -image downl_icon -command "p_failu_surinkimas"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.surinkti "Surinkti mokinių užrašus"
grid [ttk::button .n.f4.kiti.surinktitst -text "" -image test_down_icon -command "p_surinkti_atsakymus testas"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.surinktitst "Surinkti mokinių testo atsakymus"
grid [ttk::button .n.f4.kiti.surinktiats -text "" -image tabledown -command "p_surinkti_atsakymus atsiskaitymas"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.surinktiats "Surinkti mokinių atsiskaitymus"
grid [ttk::button .n.f4.kiti.zinute -text "" -image chat_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_MESSAGE]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.zinute "Siųsti žinutę"
#grid [ttk::button .n.f4.kiti.klausimas -text "" -image chat_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_QUESTION]"] -pady $y -padx $x -column $c -row $r; incr c
#setTooltip .n.f4.kiti.klausimas "Klausimas"
grid [ttk::button .n.f4.kiti.slepti -text "" -image killchat_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_KILLCHAT]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.slepti "Paslėpti pranešimus"
grid [ttk::button .n.f4.kiti.salinti -text "" -image trash_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_REMOVE]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.salinti "Šalinti nereikalingus failus"
grid [ttk::button .n.f4.kiti.isjungti -text "" -image app_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_KILLAPPS]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.isjungti "Išjungti programas"
grid [ttk::button .n.f4.kiti.sukurtiapl -text "" -image create_icon -command "p_sukurti_aplankus_darbams"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.sukurtiapl "Sukurti ištaisytų darbų aplankus"
grid [ttk::button .n.f4.kiti.info -text "" -image klaus32 -command "p_f4_korteles_informacija"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f4.kiti.info "Informacija"

set c 0
grid [ttk::button .n.f5.tvarkymas.perkrauti -text "" -image res32 -command "p_veiksmai_su_kompiuteriais [CONST ACT_REBOOT]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f5.tvarkymas.perkrauti "Perkrauti kompiuterius"
grid [ttk::button .n.f5.tvarkymas.isjungti -text "" -image shutdown_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_SHUTDOWN]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f5.tvarkymas.isjungti "Išjungti kompiuterius"
grid [ttk::button .n.f5.tvarkymas.atnaujinti -text "" -image upd32 -command "p_updates"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f5.tvarkymas.atnaujinti "Įdiegti atnaujinimus"
grid [ttk::button .n.f5.tvarkymas.komanda -text "" -image terminal_icon -command "p_komandos_pasirinkimas"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f5.tvarkymas.komanda "Vykdyti komandą"
grid [ttk::button .n.f5.tvarkymas.atblokuoti -text "" -image unblock_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_UNBLOCKPAGE]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f5.tvarkymas.atblokuoti "Atblokuoti svetainę"
grid [ttk::button .n.f5.tvarkymas.blokuoti -text "" -image block_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_BLOCKPAGE]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f5.tvarkymas.blokuoti "Užblokuoti svetainę"
grid [ttk::button .n.f5.tvarkymas.wallpaper -text "" -image wall_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_WALLP]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f5.tvarkymas.wallpaper "Pakeisti ekrano paveikslėlį"
grid [ttk::button .n.f5.tvarkymas.nustatymai -text "" -image tool_icon -command "p_veiksmai_su_kompiuteriais [CONST ACT_OPTIONS]"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f5.tvarkymas.nustatymai "Pakeisti mokinio numatytuosius nustatymus"

set c 0
grid [ttk::button .n.f6.testai.sukurti -text "" -image new_test_icon  -command "p_testo_kurimo_pradzia 1"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f6.testai.sukurti "Sukurti naują testą"
grid [ttk::button .n.f6.testai.redaguoti -text "" -image test_edit -command "p_testo_kurimo_pradzia 0"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f6.testai.redaguoti "Redaguoti testą"
grid [ttk::button .n.f6.testai.patestuoti -text "" -image testing_icon -command "p_testo_testavimo_zinute"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f6.testai.patestuoti "Patestuoti sukurtą testą"
grid [ttk::button .n.f6.testai.klbaze -text "" -image check_icon -command "p_klausimo_tipo_parinkimas"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f6.testai.klbaze "Klausimynas"
grid [ttk::button .n.f6.testai.galerija -text "" -image gallery_icon -command "p_paveikslu_galerija joks 0"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f6.testai.galerija "Paveikslėlių galerija"
grid [ttk::button .n.f6.testai.tikrinti -text "" -image test_check_icon -command "p_tikrinti_testus"] -pady $y -padx $x -column $c -row $r; incr c
setTooltip .n.f6.testai.tikrinti "Tikrinti mokinių testus"
grid [ttk::button .n.f6.testai.rezultatai -text "" -image chart_icon -command "p_statistika"] -pady $y -padx $x -column $c -row $r
setTooltip .n.f6.testai.rezultatai "Rezultatų statistika"
incr r

proc p_perpiesti_klasiu_laukeli {r} {
	destroy .statusbar
	destroy .informacija
	set klases [db3 eval {SELECT klase FROM klases ORDER BY klase}]
	lappend klases "Įvairios"
	set ::pradine_klase [lindex $klases 0]
	grid [ttk::frame .statusbar] -column 0 -row $r -pady 5 -padx 15 -sticky w
	grid [ttk::frame .informacija] -column 0 -row $r -pady 5
	grid [ttk::label .informacija.atlikta -text ""] -column 0 -row $r -padx 3 -pady 5; incr r
	grid [ttk::label .informacija.tuscia -text "" -width 5] -column 0 -row $r -padx 3 -pady 7
	grid [ttk::label .statusbar.klase -text "KLASĖ:"] -column 0 -row $r -padx 10 -sticky w
	grid [ttk::combobox .statusbar.comboklase -textvariable ::pradine_klase -width 10] -column 1 -row $r
	.statusbar.comboklase configure -values $klases
	bind .statusbar.comboklase <<ComboboxSelected>> "p_parinkti_klase"
	return $r
}

set r [p_perpiesti_klasiu_laukeli 2]

proc p_perpiesti_kompiuterius {} {
	destroy .kompiuteriai .zymejimas
	set r 5
	grid [ttk::frame .zymejimas] -column 0 -row $r; incr r
	grid [ttk::frame .kompiuteriai -padding $::pad10] -column 0 -row $r; incr r
	grid [ttk::checkbutton .zymejimas.pazymetilyg -text "LYGINIAI:" -variable ::pclyg -onvalue 1 -offvalue 0 -command "p_pazymeti_lyginius_pc" -padding $::pad10] -column 0 -row $r -padx 15 -sticky w
	grid [ttk::checkbutton .zymejimas.pazymetivisus -text "VISI:" -variable ::pcvisi -onvalue 1 -offvalue 0 -command "p_pazymeti_visus_pc" -padding $::pad10] -column 1 -row $r -padx 15 -pady 5
	grid [ttk::checkbutton .zymejimas.pazymetinelyg -text "NELYGINIAI:" -variable ::pcnelyg -onvalue 1 -offvalue 0 -command "p_pazymeti_nelyginius_pc" -padding $::pad10] -column 2 -row $r -padx 15 -sticky e
	incr r
	set visi_ip_adresai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
	set is_viso_kompiuteriu [db3 eval {SELECT MAX(Id) FROM kompiuteriai}]
	set stulpeliai 5
	set eilutes [expr $is_viso_kompiuteriu/$stulpeliai+1]
	set komp_nr 0
	for {set i 0} {$i < $eilutes} {incr i} {
		incr r; incr r
		set c1 0
		for {set j 0} {$j < $stulpeliai} {incr j} {
			if {$i==[expr $eilutes-1]} {
				if {[expr $is_viso_kompiuteriu%$stulpeliai] == 0} {
					break
				}
			}
			grid [ttk::checkbutton .kompiuteriai.c$komp_nr -text "[expr $komp_nr+1]" -variable ::pc$komp_nr -onvalue 1 -offvalue 0 -command "" -image pcneutral -compound right] -column $c1 -row [expr $r-1]
			grid [ttk::label .kompiuteriai.$komp_nr -text "" -style pilkas.TLabel -width 13 -justify "center" -anchor center] -column $c1 -row $r -pady 0 -padx 15; incr c1; incr komp_nr
			if {$i==[expr $eilutes-1]} {
				if {[expr $j+1] == [expr $is_viso_kompiuteriu%$stulpeliai]} {
					break
				}
			}
		}
	}
}

if {$visi_ip_adresai != ""} {
	p_perpiesti_kompiuterius
}
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_update_pc_status {nr {force 0}} {
	set pc_id [expr $nr + 1]
	lassign [db3 eval {SELECT ar_alien, mok_id, ar_primountinta, atsiskaitymas, testo_id FROM current_pc_setup WHERE pc_id=$pc_id}] ar_alien mok_id mountinimo_busena atsiskaitymo_busena testo_id
	set klase [db3 onecolumn {SELECT klase FROM klases JOIN mokiniai ON klases.Id = mokiniai.klases_id WHERE mokiniai.Id = $mok_id}]
	set display [db3 onecolumn {SELECT display FROM kompiuteriai WHERE Id=$pc_id}]
	if {$atsiskaitymo_busena == 1} {
		p_icon_keitimas $nr pctable $force
		if {$force} {
			#if atsiskaitymas not running, we assumen pc has crashed/rebooted, thus mounts are lost and must also be remounted
			set atsiskaitymo_komandos "
				pidof -x atsiskaitymas.tcl > /dev/null || 
				sudo mkdir -p /home/mokinys/Atsiskaitymai &&
				sudo mount -o bind /home/mokytoja/atsiskaitymai/$klase/$::siandiena/ /home/mokinys/Atsiskaitymai &&
				sudo chown -R mokinys:mokinys /home/mokinys/Atsiskaitymai &&
				sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /skriptai/atsiskaitymas.tcl &
			"
			p_send_command $nr $atsiskaitymo_komandos
			after 5000 "chan puts \[set ::chan$nr\] {tail -f --pid \$(pidof -x atsiskaitymas.tcl) /dev/null 2>/dev/null && echo task_ended &}"
			
		}
	} elseif {$testo_id != 0} {
		bind .kompiuteriai.c$nr <3> "p_sunaikinti_testa $nr"
		p_icon_keitimas $nr pctest $force
		if {$force} {
			p_send_command $nr "pidof -x Testas.tcl > /dev/null || sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /skriptai/Testas.tcl &"
			after 3000 "chan puts \[set ::chan$nr\] {tail -f --pid \$(pidof -x Testas.tcl) /dev/null 2>/dev/null && echo test_ended &}"
		}
	} elseif {$mountinimo_busena == 1} {
		p_icon_keitimas $nr pcfopen $force
		if {$force} {
			#do mounts here, after reconnection @todo XXX
			#mounting seems to be "action dependant" what has to be mountend seems cant be determined from only current_pc_setup table for now, check if it so, possibly add more data there if needed
			#set mountinimo_komandos " 
			#	sudo mkdir -p /home/mokinys/Atsiskaitymai &&
			#	sudo mount -o bind /home/mokytoja/atsiskaitymai/$klase/$::siandiena/ /home/mokinys/Atsiskaitymai &&
			#	sudo chown -R mokinys:mokinys /home/mokinys/Atsiskaitymai &&
			#	sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /skriptai/atsiskaitymas.tcl &
			#"
			#p_send_command $nr $mountinimo_komandos
		}	
	} elseif {$mok_id == 0} {
		p_icon_keitimas $nr mouse $force
		.kompiuteriai.$nr configure -text ""
		if {[chan names [set ::chan$nr]] != ""} { #only bind choice if coputer connected, otherwise connecition bind should take priority
			bind .kompiuteriai.c$nr <3> "p_rinktis_mokini $nr \"$klase\""
		}
	} else {
		p_icon_keitimas $nr pcneutral $force
	}
	if {$mountinimo_busena == 1 || $testo_id != 0 || $atsiskaitymo_busena == 1} {
		.kompiuteriai.$nr configure -style TLabel
	} else {
		.kompiuteriai.$nr configure -style pilkas.TLabel
	}
	if {$mok_id != 0} {
		lassign [db3 eval {SELECT vardas, pavarde, klase FROM mokiniai JOIN klases ON klases.Id = mokiniai.klases_id WHERE mokiniai.Id=$mok_id}] vardas pavarde klase
		.kompiuteriai.$nr configure -text "$vardas\n$pavarde"
	}
	if {$ar_alien == 1} {
		bind .kompiuteriai.$nr <3> "p_ar_pasalinti_mokini_is_komp $nr"
		.kompiuteriai.$nr configure -style melynas.TLabel
		.kompiuteriai.$nr configure -text "$vardas\n$pavarde $klase"
	}
}

proc p_parinkti_klase {} {
	set klase "[.statusbar.comboklase get]"
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$klase}]
	set pcs_to_update [db3 eval {SELECT pc_id FROM current_pc_setup WHERE ar_primountinta = 0 AND atsiskaitymas = 0 AND testo_id = 0 AND ar_alien = 0}]
	foreach pc_id $pcs_to_update {
		set nr [expr $pc_id - 1]
		lassign [db3 eval {SELECT Id, vardas, pavarde FROM mokiniai WHERE klases_id=$klases_id AND pc_id = $pc_id AND esamas_ar_buves = 1}] mok_id vardas pavarde
		if {$mok_id != ""} {
			p_icon_keitimas $nr pcneutral
			.kompiuteriai.$nr configure -text "$vardas \n$pavarde" -style pilkas.TLabel
			bind .kompiuteriai.c$nr <3> ""
		} else {
			p_icon_keitimas $nr mouse	
			.kompiuteriai.$nr configure -text ""
			if {[chan names [set ::chan$nr]] != ""} { #only bind choice if coputer connected, otherwise connecition bind should take priority
				bind .kompiuteriai.c$nr <3> "p_rinktis_mokini $nr \"$klase\""
			}
			set mok_id 0	
		}
		db3 eval {UPDATE current_pc_setup SET mok_id = $mok_id WHERE pc_id = $pc_id}
	}
}

#set komp_sk [db3 eval {SELECT Id FROM kompiuteriai}]
#set komp_check 0
#foreach pc_id $komp_sk {
	#set nr [expr $pc_id - 1]
	#if {[winfo exists .kompiuteriai.c$nr] != 0} {
		#incr komp_check
	#}	
#}
#if {$komp_sk == $komp_check} {
	p_parinkti_klase
#}

proc p_rinktis_mokini {nr klase} {
	set mokinys ""
	set klases [db3 eval {SELECT klase FROM klases ORDER BY klase}]
	set mokiniai [db3 eval {SELECT pavarde || ' ' || vardas FROM mokiniai JOIN klases ON mokiniai.klases_id=klases.Id WHERE klases.klase=$klase AND esamas_ar_buves=1 ORDER BY pavarde}]
	set w .rinktis
	p_naujas_langas $w "Rinktis mokinį"
	set r 0
	grid [ttk::frame $w.mok -padding $::pad20] -column 0 -row 0 -sticky news; incr r
	if {$nr != -1} {
		grid [ttk::label $w.mok.kompiuteris -text "KOMPIUTERIS NR. [expr $nr+1]:"] -column 0 -row $r -padx 5 -pady 10 -columnspan 4; incr r
	}
	grid [ttk::label $w.mok.kllbl -text "KLASĖ:"] -column 0 -row $r -padx 5 -pady 10
	grid [ttk::combobox $w.mok.comboklase -textvariable ::klase -width 5] -column 1 -row $r -padx 5 -pady 10
	$w.mok.comboklase configure -values $klases
	bind $w.mok.comboklase <<ComboboxSelected>> "p_perkurti_mokinius \$klase $w"
	grid [ttk::label $w.mok.moklbl -text "MOKINYS:"] -column 2 -row $r -padx 5 -pady 10
	grid [ttk::combobox $w.mok.combomokinys -textvariable ::mokinys -width 20] -column 3 -row $r -padx 5 -pady 10; incr r
	$w.mok.combomokinys configure -values $mokiniai
	set komanda "if {\"\[$w.mok.combomokinys get\]\" == \"\"} {tk_messageBox -message \"Neparinktas mokinys.\" -parent $w} {destroy $w; p_priskirti_mokini_kompiuteriui $nr \$::mokinys \$::klase}"
	grid [ttk::button $w.mok.ok -text "Gerai" -command $komanda -style mazaszalias.TButton] -column 0 -row $r -padx 5 -pady 10 -columnspan 4
}

proc p_perkurti_mokinius {klase w} {
	set mokiniai [db3 eval {SELECT pavarde || ' ' || vardas FROM mokiniai JOIN klases ON mokiniai.klases_id=klases.Id WHERE klases.klase=$klase AND esamas_ar_buves=1 ORDER BY pavarde}]
	$w.mok.combomokinys configure -values $mokiniai
}

proc p_priskirti_mokini_kompiuteriui {nr mokinys klase} {
	set vardas [lindex $mokinys 1]
	set pavarde [lindex $mokinys 0]
	.kompiuteriai.$nr configure -text "$vardas \n$pavarde $klase"
	.kompiuteriai.$nr configure -style melynas.TLabel
	bind .kompiuteriai.c$nr <3> "p_ar_pasalinti_mokini_is_komp $nr"
	p_icon_keitimas $nr pcneutral
	set pc_id [expr $nr + 1]
	set mok_id [db3 onecolumn {SELECT mokiniai.Id FROM mokiniai JOIN klases ON klases.Id=mokiniai.klases_id WHERE vardas=$vardas AND pavarde=$pavarde AND klases.klase=$klase}]
	db3 eval "UPDATE current_pc_setup SET mok_id = $mok_id WHERE pc_id = $pc_id"
	db3 eval "UPDATE current_pc_setup SET ar_alien = 1 WHERE pc_id = $pc_id"
}

proc p_ar_pasalinti_mokini_is_komp {nr} {
	set w .salinti
	p_naujas_langas $w "Klausimas"
	set r 0
	grid [ttk::frame $w.mok -padding $::pad20] -column 0 -row 0 -sticky news; incr r
	grid [ttk::label $w.mok.klausimas -text "Ar pašalinti mokinį?"] -column 0 -row $r -padx 5 -pady 10 -columnspan 2; incr r
	grid [ttk::button $w.mok.taip -text "Taip" -command "destroy .salinti; p_pasalinti_mokini_is_komp $nr" -style mazaszalias.TButton] -column 0 -row $r -padx 5 -pady 10
	grid [ttk::button $w.mok.ne -text "Ne" -command "destroy .salinti" -style mazaszalias.TButton] -column 1 -row $r -padx 5 -pady 10
}

proc p_pasalinti_mokini_is_komp {nr} {
	set pc_id [expr $nr + 1]
	set klase "[.statusbar.comboklase get]"
	db3 eval "UPDATE current_pc_setup SET ar_alien = 0 WHERE pc_id = $pc_id"
	db3 eval "UPDATE current_pc_setup SET mok_id = 0 WHERE pc_id = $pc_id"
	.kompiuteriai.$nr configure -text ""
	p_icon_keitimas $nr mouse
	.kompiuteriai.$nr configure -style pilkas.TLabel
	bind .kompiuteriai.c$nr <3> "p_rinktis_mokini $nr \"$klase\""
}

proc p_pazymeti_visus_pc {} {
	set kompiuteriu_ids [db3 eval {SELECT Id FROM kompiuteriai ORDER BY Id}]
	for {set nr 0} {$nr < [llength $kompiuteriu_ids]} {incr nr} {
		if {$::pcvisi == 1} {
			set ::pc$nr 1
		} else {
			set ::pc$nr 0
		}
		.kompiuteriai.c$nr configure -variable ::pc$nr
	}
}

proc p_pazymeti_lyginius_pc {} {
	set kompiuteriu_ids [db3 eval {SELECT Id FROM kompiuteriai ORDER BY Id}]
	for {set nr 1} {$nr < [llength $kompiuteriu_ids]} {incr nr} {
		if {$::pclyg == 1} {
			set ::pc$nr 1
		} else {
			set ::pc$nr 0
		}
		.kompiuteriai.c$nr configure -variable ::pc$nr
		incr nr
	}
}

proc p_pazymeti_nelyginius_pc {} {
	set kompiuteriu_ids [db3 eval {SELECT Id FROM kompiuteriai ORDER BY Id}]
	for {set nr 0} {$nr < [llength $kompiuteriu_ids]} {incr nr} {
		if {$::pcnelyg == 1} {
			set ::pc$nr 1
		} else {
			set ::pc$nr 0
		}
		.kompiuteriai.c$nr configure -variable ::pc$nr
		incr nr
	}
}

proc p_kokius_pc_pasirinko {} {
	set pasirinkti_pc ""
	set visi_ip_adresai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
# 	array set ip_nr_map {}
	for {set nr 0} {$nr < [llength $visi_ip_adresai]} {incr nr} {
		if {[info exists ::pc$nr] && [set ::pc$nr] != 0} {
			lappend pasirinkti_pc "[lindex $visi_ip_adresai $nr]"
# 			set ip_nr_map([lindex $visi_ip_adresai $nr]) $nr
		}
	}
	if {$pasirinkti_pc == {} } {
		tk_messageBox -message "Nepažymėtas joks kompiuteris." -parent .n
		set ::testi 0
	} else {
		set ::testi 1
	}
# 	return [array get ip_nr_map]
        return $pasirinkti_pc
}

proc p_default_pc_state {} {
	for {set nr 0} {$nr < [db3 onecolumn {SELECT COUNT(*) FROM kompiuteriai}]} {incr nr} {
		p_update_pc_status $nr
	}
}

p_default_pc_state

proc p_veiksmas_atliktas {pranesimas} {
	#parodo pranešimą, kad veiksmas atliktas. Ir nupiešia mygtuką „Gerai“, kurį nuspaudus, kompiuterių piktogramos atsistato į pradines
	destroy .informacija.tuscia
	destroy .informacija.ok
	.informacija.atlikta configure -text $pranesimas
	set komandos "
		grid [ttk::label .informacija.tuscia -text "" -width 5] -column 0 -row 3 -padx 3 -pady 7;
		.informacija.atlikta configure -text \"\"; destroy .informacija.ok; p_default_pc_state
	"
	grid [ttk::button .informacija.ok -text "Gerai" -style mazaszalias.TButton -width 5 -command $komandos] -column 0 -row 3 -pady 1
}
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_priskirti_varianta {variantas} {
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	if {$::testi == 1} {
		foreach pc $pasirinkti_pc {
			set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
			set nr [expr $pc_id - 1]
			p_icon_keitimas $nr pc$variantas
			db3 eval "UPDATE current_pc_setup SET var = $variantas WHERE pc_id = $pc_id"
		}
	set ::variantusk [db3 onecolumn {SELECT MAX(var) FROM current_pc_setup}]
	} else {
		return
	}
}

proc p_ar_visiems_pirmas_variantas {klausimas procedura_kuria_pratesti ar_pazymiui} {
	set w .priskirti
	p_naujas_langas $w "Ar priskirti?"
	set r 0
	grid [ttk::frame $w.var -padding $::pad20] -column 0 -row 0
	grid [ttk::label $w.var.tekstas -text $klausimas -style didelis.TLabel -wraplength 310] -column 0 -row $r -pady 10 -columnspan 2; incr r
	grid [ttk::button $w.var.taip -text "Taip" -command "destroy $w; p_priskirti_visiems_pirma_var $procedura_kuria_pratesti $ar_pazymiui" -style zalias.TButton] -column 0 -row $r -pady 10
	grid [ttk::button $w.var.ne -text "Ne" -style raudonas.TButton -command "destroy $w; return"] -column 1 -row $r -pady 10	
}

proc p_priskirti_visiems_pirma_var {procedura_kuria_pratesti ar_pazymiui} {
	set visi_pc_ip [db3 eval {SELECT pc FROM kompiuteriai}]
	foreach ip $visi_pc_ip {
		set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$ip}]
		db3 eval "UPDATE current_pc_setup SET var = 1 WHERE pc_id = $pc_id"
	}
	set ::variantusk [db3 onecolumn {SELECT MAX(var) FROM current_pc_setup}]
	$procedura_kuria_pratesti $ar_pazymiui
}
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_sukurti_aplankus_darbams {} {
	set klase "[.statusbar.comboklase get]"
	p_ar_tikrai "Ar sukurti aplankus klasei $klase?" "set ::testi 1"
	if {$::testi == 0} {
		return
	}
	set kelias [db3 eval {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl='darbu_aplankas';}]
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$klase}]
	set visu_klases_mokiniu_ids [db3 eval {SELECT Id FROM mokiniai WHERE klases_id=$klases_id AND esamas_ar_buves=1}]
	foreach mokid $visu_klases_mokiniu_ids {
		lassign [db3 eval {SELECT vardas, pavarde FROM mokiniai WHERE Id=$mokid}] vardas pavarde
		exec mkdir -p $kelias/$::siandiena-$klase/$pavarde-$vardas-ID$mokid/
	}
}

proc p_siusti_testo_rezultatus {w} {
	set klase "[$w.f1.klasescombo get]"
	set pazymeti_testai [p_generuoti_testu_sarasa]
	if {$pazymeti_testai == ""} {
		tk_messageBox -message "Nepažymėtas testas." -parent $w
		return
	}
	p_ar_tikrai "Ar nusiųsti pažymius klasei $klase?" "set ::testi 1"
	if {$::testi == 0} {
		return
	}
	foreach testo_id $pazymeti_testai {
		set nenusiusta 0
		set kelias [db3 eval {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl='darbu_aplankas';}]
		set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$klase}]
		set kas_sprende_testa [db3 eval {SELECT mokinio_id FROM bandymai JOIN mokiniai ON mokiniai.Id=bandymai.mokinio_id WHERE testo_id=$testo_id AND klases_id=$klases_id}]
		foreach mokid $kas_sprende_testa {
			lassign [db3 eval {SELECT vardas, pavarde FROM mokiniai WHERE Id=$mokid}] vardas pavarde
			set bandymo_id [db3 onecolumn {SELECT Id FROM bandymai WHERE mokinio_id=$mokid AND testo_id=$testo_id}]
			set pazymys [db3 onecolumn {SELECT pazymys FROM bandymai WHERE Id=$bandymo_id}]
			set ar_rase_lt [db3 onecolumn {SELECT penalty_tsk FROM bandymai WHERE Id=$bandymo_id}]
			set kada_rase_testa [db3 onecolumn {SELECT data FROM bandymai WHERE Id=$bandymo_id}]
			set pc_id [db3 onecolumn {SELECT pc_id FROM mokiniai WHERE Id=$mokid}]
			set pc_ip [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$pc_id}]
			set nr [expr $pc_id - 1]
			set display [db3 onecolumn {SELECT display FROM kompiuteriai WHERE Id=$pc_id}]
			if {$ar_rase_lt != 0} {
				set ka_rodyti_mokiniui "Testo rašymo data: $kada_rase_testa\nTaškai už lietuviškas raides: $ar_rase_lt\nGautas pažymys: $pazymys\n"
			} else {
				set ka_rodyti_mokiniui "Testo rašymo data: $kada_rase_testa\nGautas pažymys: $pazymys\n"
			}
			exec mkdir -p $kelias/$::siandiena-$klase-testai/$pavarde-$vardas-ID$mokid/
			exec touch $kelias/$::siandiena-$klase-testai/$pavarde-$vardas-ID$mokid/$pavarde-$vardas-testo-rezultatai.txt
			exec printf "$ka_rodyti_mokiniui" > $kelias/$::siandiena-$klase-testai/$pavarde-$vardas-ID$mokid/$pavarde-$vardas-testo-rezultatai.txt
			set zinute_mokiniui "Gautą pažymį gali peržiūrėti aplanke „Nuo_mokytojos“"
			set msg [cant_ping $pc_ip]
			if {$msg == 1} {
				incr nenusiusta
			} else {
				puts "siuncia [expr $nr + 1]"
				catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 -r $kelias/$::siandiena-$klase-testai/$pavarde-$vardas-ID$mokid/* mokytoja@$pc_ip:/home/mokinys/Nuo_mokytojos/"}
				p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/zinute_random.tcl \"$zinute_mokiniui\" \"Pranešimas\" &"
			}
		}
	}
	if {$nenusiusta == 0} {
		set message "Pažymiai nusiųsti."
	} else {
		set message "Pažymiai nusiųsti visiems, išskyrus $nenusiusta mokinių(-us)."
	}
	exec sh -c "rm -rf $kelias/$::siandiena-$klase-testai/"
	tk_messageBox -message $message -parent $w
}

proc p_updates {} {
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	catch {exec -ignorestderr ./Programos_failai/updates.sh $pasirinkti_pc &}
	tk_messageBox -message "Vyksta mokinių kompiuterių atnaujinimai. Neišjunkite mokinių kompiuterių. Terminale galima matyti, ar atnaujinimai tebevyksta." -parent .n
}

proc p_interneto_komandos {zenklas} {
#sukuria kintamąjį interneto blokavimo komandoms
	set ::interneto_komandos "
	sudo chmod $zenklas /usr/lib/chromium-browser/chromium-browser;
	sudo chmod $zenklas /usr/lib/firefox/firefox;
	sudo chmod $zenklas /usr/bin/thunderbird;
	sudo chmod $zenklas /usr/bin/webbrowser-app;
	sudo chmod $zenklas /usr/bin/konqueror;
	sudo chmod $zenklas /usr/bin/firefox;
	sudo chmod $zenklas /usr/bin/chromium;
	sudo chmod $zenklas /snap/bin/chromium;
	sudo chmod $zenklas /opt/google/chrome/chrome;
	"
}

proc p_svetaines_parinkimas {act} {
	set w .svetaine
	p_naujas_langas $w "Svetainės parinkimas"
	wm protocol $w WM_DELETE_WINDOW {
		destroy .svetaine
		set ::testi 0
	}
	set r 0
	if {$act == [CONST ACT_UNBLOCKPAGE]} {
		set zodis "atblokuoti"
	} else {
		set zodis "užblokuoti"
	}
	set ::svetaine ""
	grid [ttk::frame $w.f -padding $::pad20] -column 0 -row 0 -sticky news; incr r
	grid [ttk::label $w.f.tekstas -text "Įveskite svetainės pavadinimą, kurią norite $zodis (pvz.: facebook.com):" -wraplength 300] -column 0 -row $r -pady 6; incr r
	grid [ttk::entry $w.f.ivesti -textvariable ::svetaine -width 30] -column 0 -row $r -pady 6; incr r
	focus $w.f.ivesti
	grid [ttk::button $w.f.gerai -text "Gerai" -command "destroy $w.f.gerai" -style mazaszalias.TButton] -column 0 -row $r -pady 6
	tkwait window $w.f.gerai
}

proc p_rinktis_darbu_aplanka {} {
	set w .darbuaplankas
	p_naujas_langas $w "Darbų aplanko parinkimas"
	wm protocol $w WM_DELETE_WINDOW {
		destroy .darbuaplankas
		set ::testi 0
	}
	set r 0
	grid [ttk::frame $w.f -padding "30 20 30 10"] -column 0 -row 0 -sticky news
	grid [ttk::label $w.f.aplankas -text "Ištaisytų darbų aplankas: \nNEPARINKTAS"] -column 0 -row $r -padx 5 -pady 10
	grid [ttk::button $w.f.parinkti -text "Pasirinkti..." -command "p_rinktis_darbu_aplanka2 $w $r"] -column 1 -row $r -padx 5 -pady 5; incr r
	tkwait window $w
}

proc p_rinktis_darbu_aplanka2 {w r} {
	destroy $w.m
	set paaiskinimas "Parinkite tos klasės aplanką, kuriame yra visi ištaisyti mokinių darbų aplankai su jų darbais. Aplankų pavadinimai turi būti su mokinių vardais, pavardėmis ir identifikaciniais numeriais. Įsitikinkite, kad parinkote tą pačią klasę ir prie kompiuterių paveikslėlių yra tie patys mokiniai."
	incr r
	set kelias [db3 eval {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl='darbu_aplankas';}]
	set ::darbodir [tk_chooseDirectory -initialdir $kelias -parent .darbuaplankas -title {Rinktis ištaisytų darbų aplanką}]
	if {$::darbodir != ""} {
		set f [file tail $::darbodir]
		$w.f.aplankas configure -text "Ištaisytų darbų aplankas: \n„$f“"
		$w.f.parinkti configure -text "Pakeisti..."
		grid [ttk::frame $w.m -padding "30 0 30 10"] -column 0 -row $r -sticky news -columnspan 2
		grid columnconfigure $w.m 0 -weight 1
		grid columnconfigure $w.m 1 -weight 1
		grid [ttk::button $w.m.ikelti -text "Siųsti darbus" -command "destroy $w" -style zalias.TButton -padding "5 12 5 12"] -column 0 -row $r -pady 5 -sticky e
		grid [ttk::button $w.m.info -text "" -image klaus32 -command "tk_messageBox -message \"$paaiskinimas\" -parent $w" -style zalias.TButton] -column 1 -row $r -padx 10 -pady 5 -sticky w
	}
}

proc p_pasirinkti_isjungiamas_programas {} {
	set w .programos
	p_naujas_langas $w "Programų išjungimas"
	wm protocol $w WM_DELETE_WINDOW {
		destroy .programos
		set ::testi 0
	}
	set r 0
	grid [ttk::frame $w.f -padding "30 20 30 10"] -column 0 -row 0 -sticky news
	grid [ttk::label $w.f.lbl -text "Pažymėkite programas, kurias norite išjungti:"] -column 0 -row $r -padx 5 -pady 10; incr r
	grid [ttk::checkbutton $w.f.1 -text "LibreOffice" -variable ::programa1 -onvalue 1 -offvalue 0] -column 0 -row $r -padx 10 -sticky w; incr r
	grid [ttk::checkbutton $w.f.2 -text "KolourPaint" -variable ::programa2 -onvalue 1 -offvalue 0] -column 0 -row $r -padx 10 -sticky w; incr r
	grid [ttk::checkbutton $w.f.3 -text "Gimp" -variable ::programa3 -onvalue 1 -offvalue 0] -column 0 -row $r -padx 10 -sticky w; incr r
	grid [ttk::checkbutton $w.f.4 -text "Failų tvarkyklė" -variable ::programa4 -onvalue 1 -offvalue 0] -column 0 -row $r -padx 10 -sticky w; incr r
	grid [ttk::checkbutton $w.f.5 -text "PDF failų skaityklė" -variable ::programa5 -onvalue 1 -offvalue 0] -column 0 -row $r -padx 10 -sticky w; incr r
	grid [ttk::checkbutton $w.f.6 -text "Paveikslėlių peržiūros programa" -variable ::programa6 -onvalue 1 -offvalue 0] -column 0 -row $r -padx 10 -sticky w; incr r
	grid [ttk::checkbutton $w.f.7 -text "Naršyklė Firefox" -variable ::programa7 -onvalue 1 -offvalue 0] -column 0 -row $r -padx 10 -sticky w; incr r
	grid [ttk::checkbutton $w.f.8 -text "Naršyklė Chromium" -variable ::programa8 -onvalue 1 -offvalue 0] -column 0 -row $r -padx 10 -sticky w; incr r
	grid [ttk::button $w.f.ok -text "Išjungti programas" -image app_icon -compound left -command "destroy $w" -style zalias.TButton] -column 0 -row $r -pady 10
	tkwait window $w
}

proc p_komandos_pasirinkimas {} {
	set w .komandos
	p_naujas_langas $w "Komandų vykdymas"
	set r 0
	set ::komanda_vykdymui ""
	grid [ttk::frame $w.f -padding "30 20 30 10"] -column 0 -row 0 -sticky news
	grid [ttk::label $w.f.lbl -text "Įrašykite komandą, kurią norite įvykdyti pažymėtiems kompiuteriams:"] -column 0 -row $r -padx 5 -pady 10; incr r
	grid [ttk::entry $w.f.komanda -textvariable ::komanda_vykdymui -width 60] -column 0 -row $r -pady 6; incr r
	focus $w.f.komanda
	grid [ttk::button $w.f.ok -text "Vykdyti" -command "p_veiksmai_su_kompiuteriais [CONST ACT_COMMAND]" -style zalias.TButton] -column 0 -row $r -pady 10
}

proc p_siusti_zinute {} {
	set r 0
	set ::zinutes_tekstas ""
	p_naujas_langas .zinute "Žinutė"
	wm protocol .zinute WM_DELETE_WINDOW {
		destroy .zinute
		set ::testi 0
	}
	grid [ttk::frame .zinute.mokiniui -padding $::pad20] -column 0 -row 0
	grid [ttk::label .zinute.mokiniui.tekstas -text "ĮRAŠYKITE ŽINUTĘ:"] -column 0 -row $r -pady 10; incr r
	grid [ttk::entry .zinute.mokiniui.irasyk -textvariable ::zinutes_tekstas -width 28] -column 0 -row $r -pady 5 -padx 20; incr r
	focus .zinute.mokiniui.irasyk
	grid [ttk::button .zinute.mokiniui.mygtukas -text "Siųsti" -image mailsend -compound right -style mazaszalias.TButton -command "destroy .zinute.mokiniui.mygtukas"] -column 0 -row $r -pady 10 -padx 5
	tkwait window .zinute.mokiniui.mygtukas
}

proc p_siusti_klausima {} {
	set r 0
	set ::klausimo_tekstas ""
	p_naujas_langas .zinute "Klausimas"
	wm protocol .zinute WM_DELETE_WINDOW {
		destroy .zinute
		set ::testi 0
	}
	grid [ttk::frame .zinute.mokiniui -padding $::pad20] -column 0 -row 0
	grid [ttk::label .zinute.mokiniui.tekstas -text "Klausimas:"] -column 0 -row $r -pady 10; incr r
	grid [ttk::entry .zinute.mokiniui.irasyk -textvariable ::klausimo_tekstas -width 28] -column 0 -row $r -pady 5 -padx 20; incr r
	focus .zinute.mokiniui.irasyk
	grid [ttk::button .zinute.mokiniui.mygtukas -text "Siųsti" -image mailsend -compound right -style mazaszalias.TButton -command "destroy .zinute.mokiniui.mygtukas"] -column 0 -row $r -pady 10 -padx 5
	tkwait window .zinute.mokiniui.mygtukas
}

proc p_veiksmai_su_kompiuteriais {act} {
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	if {$::testi == 0} {
		return
	}
	if {$act == [CONST ACT_ENDLESSON]} {
		#ppp
		foreach pc $pasirinkti_pc {
			set pc_id [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
			set ar_primountinta [db3 onecolumn {SELECT ar_primountinta FROM current_pc_setup WHERE pc_id = $pc_id}]
			if {$ar_primountinta == 0} {
				tk_messageBox -message "Pamoka nebuvo pradėta!" -parent .n
				return
			}
		}
		set laikas [clock seconds]
		set pabaigos_laikas "[clock format $laikas -format {%H:%M}]"
		set kiek_buvo_pamoku [db3 eval {SELECT COUNT(*) FROM pamokos WHERE data=$::siandiena}]
		puts $kiek_buvo_pamoku
		set pamokos_nr [expr $kiek_buvo_pamoku + 1]
		puts $pamokos_nr
		db3 eval {INSERT INTO pamokos (data, nr, pabaigos_laikas) VALUES($::siandiena, $pamokos_nr, $pabaigos_laikas)}
		set pamokos_id [db3 onecolumn {SELECT last_insert_rowid()}]
		puts $pamokos_id
		set tekstas "Užbaigiama pamoka... palaukite..."
		set pranesimas "Pamoka užbaigta."
		set klaidos_pranesimas "Pamoka užbaigta, bet ne visiems"
		#numountinam failus
		p_veiksmai_su_kompiuteriais [CONST ACT_UNMOUNT]
	}
	if {$act == [CONST ACT_UNMOUNT]} {
		set tekstas "Slepiami aplankai... palaukite..."
		set pranesimas "Aplankai paslėpti."
		set klaidos_pranesimas "Aplankai paslėpti, bet ne visiems"
		set zinute_mokiniui "Tavo failai pasislėpė."
		set komanda "
			sudo umount -l /home/mokinys/Mano_failai;
			sudo umount -l /home/mokinys/Seni_failai;
			sudo umount -l /home/mokinys/Atsiskaitymai
		"
	}
	if {$act == [CONST ACT_MESSAGE]} {
		p_siusti_zinute
		if {$::testi == 0} {
			return
		}
		set tekstas "Siunčiama žinutė... palaukite..."
		set zinutes_tekstas "[.zinute.mokiniui.irasyk get]"
		if {$zinutes_tekstas == ""} {
			tk_messageBox -message "Laukelis negali būti tuščias." -parent .zinute
			return
		} else {
			destroy .zinute
		}
		set pranesimas "Žinutė nusiųsta."
		set klaidos_pranesimas "Žinutė nusiųsta, bet ne visiems."
	}
	if {$act == [CONST ACT_QUESTION]} {
		p_siusti_klausima
		if {$::testi == 0} {
			return
		}
		set tekstas "Siunčiamas klausimas... palaukite..."
		set zinutes_tekstas "[.zinute.mokiniui.irasyk get]"
		if {$zinutes_tekstas == ""} {
			tk_messageBox -message "Laukelis negali būti tuščias." -parent .zinute
			return
		} else {
			destroy .zinute
		}
		set pranesimas "Klausimas nusiųstas."
		set klaidos_pranesimas "Klausimas nusiųstas, bet ne visiems."
	}
	if {$act == [CONST ACT_GRADED]} {
		set klase "[.statusbar.comboklase get]"
		if {$klase == "" || $klase == "Įvairios"} {
			tk_messageBox -message "Neparinkta klasė." -parent .n
			return
		}
		p_rinktis_darbu_aplanka
		if {$::testi == 0} {
			return
		}
		set tekstas "Darbai siunčiami... palaukite..."
		set pranesimas "Darbai nusiųsti."
		set klaidos_pranesimas "Darbai nusiųsti, bet ne visiems"
		set zinute_mokiniui "Tavo ištaisytas darbas atsirado aplanke „Nuo_mokytojos“."
	}
	if {$act == [CONST ACT_KILLCHAT]} {
		foreach pc $pasirinkti_pc {
			set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
			lassign [db3 eval {SELECT ar_primountinta, atsiskaitymas, testo_id FROM current_pc_setup WHERE pc_id=$pc_id}] mountinimo_busena atsiskaitymo_busena testo_id
			if {$atsiskaitymo_busena == 1 || $testo_id != 0} {
				tk_messageBox -message "Kol mokiniai atlieka testą arba atsiskaitymą, pranešimų pašalinti negalima." -parent .n
				return
			}
		}
		set tekstas "Pranešimai naikinami... palaukite..."
		set pranesimas "Pranešimai neberodomi."
		set klaidos_pranesimas "Pranešimai neberodomi, bet ne visiems"
		set komanda "sudo killall /usr/bin/wish"
	}
	if {$act == [CONST ACT_COMMAND]} {
		set komanda "[.komandos.f.komanda get]"
		if {$komanda == ""} {
			tk_messageBox -message "Laukelis negali būti tuščias." -parent .komandos
			return
		} else {
			destroy .komandos
		}
		set tekstas "Vykdomos komandos... palaukite..."
		set pranesimas "Komandos įvykdytos."
		set klaidos_pranesimas "Komandos įvykdytos, bet ne visiems"
	}
	if {$act == [CONST ACT_OPTIONS]} {
		set tekstas "Keičiami nustatymai... palaukite..."
		set pranesimas "Nustatymai pakeisti."
		set klaidos_pranesimas "Nustatymai pakeisti, bet ne visiems"
		set permissions "
			sudo chown mokinys:mokinys /home/mokinys/;
			sudo chmod +t /home/mokinys/;
			sudo chmod o+rx /home/mokinys/;
			sudo chown mokytoja:mokytoja /home/mokinys/Nuo_mokytojos;
			sudo chmod o-w /home/mokinys/Nuo_mokytojos;
			sudo chmod o+rx /home/mokinys/Nuo_mokytojos;
			sudo chmod +t /home/mokinys/Nuo_mokytojos;
			sudo chown -R mokinys:mokinys /home/mokinys/.config/ibus/;
			sudo chown mokytoja:mokytoja /home/mokinys/Nuo_mokytojos/.keeper;
			sudo chattr +i /home/mokinys/Nuo_mokytojos/.keeper;
		"
	}
	if {$act == [CONST ACT_WALLP]} {
		set paveikslelis [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="paveikslelis"}]
		set pav_aplankas [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="pav_aplankas"}]
		if {$paveikslelis == ""} {
			tk_messageBox -message "Nėra nustatytas paveikslėlis, kurį keisime. Nustatykite paveikslėlį per meniu Nustatymai -> Numatytieji aplankai..." -parent .n
			return
		}
		set filename [tk_getOpenFile -initialdir $pav_aplankas -title "Rinktis paveikslėlį"]
		set a [file dirname $paveikslelis]
		set komanda "sudo chmod a+rwx $a/*"
		set tekstas "Keičiami paveikslėliai... palaukite..."
		set pranesimas "Paveikslėliai pakeisti."
		set klaidos_pranesimas "Paveikslėliai pakeisti, bet ne visiems"
	}
	if {$act == [CONST ACT_REMOVE]} {
		foreach pc $pasirinkti_pc {
			set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
			lassign [db3 eval {SELECT ar_primountinta, atsiskaitymas, testo_id FROM current_pc_setup WHERE pc_id=$pc_id}] mountinimo_busena atsiskaitymo_busena testo_id
			if {$atsiskaitymo_busena == 1 || $testo_id != 0 || $mountinimo_busena == 1} {
				tk_messageBox -message "Kol mokiniai dirba su savo failais arba atlieka testą, failų pašalinti negalima." -parent .n
				return
			}
		}
		tk_messageBox -message "Nereikalingi failai mokinių kompiuteriuose bus pašalinti iš šių kompiuterio vietų: \n*Darbalaukis;\n*Nuo_mokytojos;\n*Namai -> Mokinys;\n*Atsiuntimai;\n*Šiukšliadėžė;" -parent .n
		set tekstas "Failai šalinami... palaukite..."
		set pranesimas "Failai pašalinti."
		set klaidos_pranesimas "Failai pašalinti, bet ne visiems"
		set komanda "
			sudo umount -l /home/mokinys/Mano_failai;
			sudo umount -l /home/mokinys/Seni_failai;
			sudo umount -l /home/mokinys/Atsiskaitymai;
			sudo rm -rf /skriptai/klausimai;
			sudo rm -rf /home/mokinys/Mano_failai/* /home/mokinys/Seni_failai/* /home/mokinys/Nuo_mokytojos/* /home/mokinys/Atsiskaitymai/* /home/mokinys/Atsiuntimai/*;
			sudo rm -rf /home/mokinys/*.png /home/mokinys/*.jpg /home/mokinys/*.jpeg /home/mokinys/*.odt /home/mokinys/*.doc /home/mokinys/*.docx /home/mokinys/*.txt /home/mokinys/*.bmp /home/mokinys/*.xcf /home/mokinys/*.pdf /home/mokinys/*.bat /home/mokinys/*.gif /home/mokinys/*.ods /home/mokinys/*.bak /home/mokinys/*.webp /home/mokinys/.local/share/Trash/files/;
			sudo rm -rf /home/mokinys/Darbastalis/*;
			sudo rm -rf /home/mokinys/Desktop/*;
			sudo rm -rf /home/mokinys/Darbalaukis/*;
			sudo rm -rf /home/mokinys/Ekrano_nuotraukos/*;
		"
	}
	if {$act == [CONST ACT_KILLAPPS]} {
		p_pasirinkti_isjungiamas_programas
		if {$::testi == 0} {
			return
		}
		set tekstas "Išjungiamos programos... palaukite..."
		set pranesimas "Programos išjungtos."
		set klaidos_pranesimas "Programos išjungtos, bet ne visiems"
		set programos_kilinimui "soffice.bin kolourpaint gimp-2.8 nautilus okular ristretto firefox chromium-browser konqueror"
		set kurias_kilinti ""
		for {set i 1} {$i<=8} {incr i} {
			if {[info exists ::programa$i]} {
				if {[set ::programa$i] == 1} {
					lappend kurias_kilinti [lindex $programos_kilinimui [expr $i-1]]
				}
			}
		}
		set komanda "sudo killall $kurias_kilinti"
	}
	if {$act == [CONST ACT_BLOCK]} {
		set tekstas "Naršyklės blokuojamos... palaukite..."
		set pranesimas "Naršyklės užblokuotos."
		set klaidos_pranesimas "Naršyklės užblokuotos, bet ne visiems"
		p_interneto_komandos -x
		set komanda "sudo killall firefox chrome chromium-browser thunderbird webbrowser-app firefox chromium; sudo pkill \"chromium-browser*\""
		set zinute_mokiniui "Interneto naršyklėmis naudotis nebegalima."
	} 
	if {$act == [CONST ACT_UNBLOCK]} {
		set tekstas "Naršyklės atblokuojamos... palaukite..."
		set pranesimas "Naršyklės atblokuotos."
		set klaidos_pranesimas "Naršyklės atblokuotos, bet ne visiems"
		p_interneto_komandos +x
		set zinute_mokiniui "Galima naudotis interneto naršyklėmis."
	}
	if {$act == [CONST ACT_REBOOT]} {
		p_ar_tikrai "Ar tikrai perkrauti kompiuterius?" "set ::testi 1"
		if {$::testi == 0} {
			return
		}
		set tekstas "Perkraunami kompiuteriai... palaukite..."
		set pranesimas "Kompiuteriai perkrauti."
		set klaidos_pranesimas "Kompiuteriai perkrauti, bet ne visi"
		set komanda "sudo reboot"
	}
	if {$act == [CONST ACT_SHUTDOWN]} {
		p_ar_tikrai "Ar tikrai išjungti kompiuterius?" "set ::testi 1"
		if {$::testi == 0} {
			return
		}
		set tekstas "Išjungiami kompiuteriai... palaukite..."
		set pranesimas "Kompiuteriai išjungti."
		set klaidos_pranesimas "Kompiuteriai išjungti, bet ne visi"
		set komanda "sudo shutdown now -h"
	}
	if {$act == [CONST ACT_UNBLOCKPAGE]} {
		p_svetaines_parinkimas $act
		if {$::testi == 0} {
			return
		}
		set svetaine "[.svetaine.f.ivesti get]"
		if {$svetaine == ""} {
			tk_messageBox -message "Laukelis negali būti tuščias." -parent .svetaine
			return
		} else {
			destroy .svetaine
		}
		set tekstas "Svetainės atblokuojamos... palaukite..."
		set pranesimas "Svetainės atblokuotos"
		set klaidos_pranešimas "Svetainės atblokuotos, bet ne visiems"
		set komanda "
			sudo chown mokytoja:mokytoja /etc/hosts;
			sudo sed -i '/$svetaine/d' /etc/hosts;
			sudo sed -i '/www.$svetaine/d' /etc/hosts;
			sudo chown root:root /etc/hosts
		"
	}
	if {$act == [CONST ACT_BLOCKPAGE]} {
		p_svetaines_parinkimas $act
		set svetaine "[.svetaine.f.ivesti get]"
		if {$svetaine == ""} {
			tk_messageBox -message "Laukelis negali būti tuščias." -parent .svetaine
			return
		} else {
			destroy .svetaine
		}
		set tekstas "Svetainės užblokuojamos... palaukite..."
		set pranesimas "Svetainės užblokuotos"
		set klaidos_pranešimas "Svetainės užblokuotos, bet ne visiems"
		set komanda "
		sudo chown mokytoja:mokytoja /etc/hosts;
		echo >> /etc/hosts '127.0.0.1 $svetaine';
		echo >> /etc/hosts '127.0.0.1 www.$svetaine';
		sudo chown root:root /etc/hosts
		"
	}
	.informacija.atlikta configure -text $tekstas
	update idletasks
	foreach pc $pasirinkti_pc {
		set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
		set nr [expr $pc_id - 1]
		set display [db3 onecolumn {SELECT display FROM kompiuteriai WHERE Id=$pc_id}]
		set msg [cant_ping $pc]
		if {$msg == 1} {
			set pranesimas $klaidos_pranesimas
			p_icon_keitimas $nr pcunr
		} else {
			if {$act == [CONST ACT_MESSAGE]} {
				set komanda "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/zinute_random.tcl \"$zinutes_tekstas\" \"Žinutė\" &"
				p_send_command $nr $komanda
			}
			if {$act == [CONST ACT_QUESTION]} {
				set komanda "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/klausimas.tcl \"$zinutes_tekstas\" \"Klausimas\" &"
				p_send_command $nr $komanda
			}
			if {$act == [CONST ACT_UNMOUNT]} {
				#if {[catch {exec -ignorestderr ssh -o ConnectTimeout=1 mokytoja@$pc "grep '/home/mokinys' /etc/mtab"}] == 0} {
					set ar_primountinta [db3 onecolumn {SELECT ar_primountinta FROM current_pc_setup WHERE pc_id = $pc_id}]
					if {$ar_primountinta == 1} {
						p_send_command $nr $komanda
						p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/zinute_random.tcl \"$zinute_mokiniui\" \"Pranešimas\" &"
						db3 eval "UPDATE current_pc_setup SET ar_primountinta = 0 WHERE pc_id = $pc_id"
					}
					set ar_primountinta [db3 onecolumn {SELECT ar_primountinta FROM current_pc_setup WHERE pc_id = $pc_id}]
					if {$ar_primountinta == 0} {
						p_send_command $nr "sudo rm -rf /home/mokinys/Mano_failai"
						p_send_command $nr "sudo rm -rf /home/mokinys/Seni_failai"
						p_send_command $nr "sudo rm -rf /home/mokinys/Atsiskaitymai"
						p_send_command $nr "sudo rm -rf /home/mokinys/Nuo_mokytojos/*"
					}
				#}
			}
			if {$act == [CONST ACT_ENDLESSON]} {
				#sukuriam pamokos tagus
				set mokinio_variantas [db3 onecolumn {SELECT var FROM current_pc_setup WHERE pc_id = $pc_id}]
				puts $mokinio_variantas
				#set mokinio_id [db3 onecolumn {SELECT mok_id FROM current_pc_setup WHERE pc_id = $pc_id}]
				set mokinio_id [db3 onecolumn {SELECT mok_id FROM current_pc_setup JOIN mokiniai ON mokiniai.Id=current_pc_setup.mok_id WHERE current_pc_setup.pc_id = $pc_id AND esamas_ar_buves=1}]
				puts $mokinio_id
				set buvo_pamokoj_id [db3 onecolumn {SELECT Id FROM tagai WHERE type = "Lankomumas" AND name = "buvo"}]
				puts $buvo_pamokoj_id
				set varianto_id [db3 onecolumn {SELECT Id FROM tagai WHERE type = "Darbo variantas" AND name = $mokinio_variantas}]
				puts $varianto_id
				db3 eval {INSERT INTO mokymosi_tagai (mokinio_id, pamokos_id, tag_id) VALUES($mokinio_id, $pamokos_id, $buvo_pamokoj_id)}
				db3 eval {INSERT INTO mokymosi_tagai (mokinio_id, pamokos_id, tag_id) VALUES($mokinio_id, $pamokos_id, $varianto_id)}
				#surenkam tos klasės mokinių failus, kurios pamoka pasibaigė
				set ::uzr_apl [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="uzrasu_aplankas"}]
				if {$::uzr_apl != ""} {
					set klase [db3 onecolumn {SELECT klase FROM klases JOIN mokiniai ON klases.Id=mokiniai.klases_id WHERE mokiniai.Id = $mokinio_id}]
					exec mkdir -p $::uzr_apl/Siu_metu/$klase
					p_send_command $nr "sudo chmod -R a+rwx /home/mokytoja/mokiniu_failai/$klase/dabartiniai/*"
					catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 -r mokytoja@$pc:/home/mokytoja/mokiniu_failai/$klase/dabartiniai/* $::uzr_apl/Siu_metu/$klase/"}
				}
			}
			if {$act == [CONST ACT_GRADED]} {
				set mokid [db3 onecolumn {SELECT mokiniai.Id FROM mokiniai JOIN klases ON klases.Id=mokiniai.klases_id WHERE klases.klase=$klase AND pc_id=$pc_id AND esamas_ar_buves=1}]
				lassign [db3 eval {SELECT vardas, pavarde FROM mokiniai WHERE Id=$mokid}] vardas pavarde
				set komanda "scp -o ConnectTimeout=1 -r $::darbodir/$pavarde-$vardas-ID$mokid/* mokytoja@$pc:/home/mokinys/Nuo_mokytojos/"
				catch {exec -ignorestderr sh -c $komanda}
				p_send_command $nr "sudo chown -R mokytoja:mokinys /home/mokinys/Nuo_mokytojos/*"
				p_send_command $nr "sudo chmod g+rx /home/mokinys/Nuo_mokytojos/*"
				p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/zinute_random.tcl \"$zinute_mokiniui\" \"Pranešimas\" &"
			}
			if {$act == [CONST ACT_BLOCK] || $act == [CONST ACT_UNBLOCK]} {
				p_send_command $nr $::interneto_komandos
			}
			if {$act == [CONST ACT_BLOCK] || $act == [CONST ACT_REBOOT] || $act == [CONST ACT_SHUTDOWN] || $act == [CONST ACT_BLOCKPAGE] || $act == [CONST ACT_UNBLOCKPAGE] || $act == [CONST ACT_KILLCHAT] || $act == [CONST ACT_REMOVE] || $act == [CONST ACT_KILLAPPS] || $act == [CONST ACT_WALLP] || $act == [CONST ACT_COMMAND]} {
				p_send_command $nr $komanda
				if {$act == [CONST ACT_REBOOT] || $act == [CONST ACT_SHUTDOWN]} {#try to close manually, explicitly and quickly to prevent possible hangups when read or write (maybe)? hangs... Without this sometimes shutting down some pcs hangs all other connections
					chan close [set ::chan$nr]
					p_icon_keitimas $nr pcunr
				}
			}
			if {$act == [CONST ACT_BLOCK] || $act == [CONST ACT_UNBLOCK]} {
				p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/zinute_random.tcl \"$zinute_mokiniui\" \"Pranešimas\" &"
			}
			if {$act == [CONST ACT_WALLP]} {
				catch {exec -ignorestderr scp -o ConnectTimeout=1 $filename mokytoja@$pc:$paveikslelis &}
			}
			if {$act == [CONST ACT_OPTIONS]} {
				p_send_command $nr "sudo rm -rf /home/mokytoja/Backups_mokinio/*"
				p_send_command $nr "sudo cp -r /home/mokinys/ /home/mokytoja/Backups_mokinio/"
				catch {exec -ignorestderr ssh -o ConnectTimeout=1 mokytoja@$pc sh -c '$permissions'}
			}
			p_icon_keitimas $nr pccheck
		}
	}
	p_veiksmas_atliktas $pranesimas
}
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_failu_siuntimo_langas {koks_veiksmas} {
#nupiešia langą, kuriame galima pasirinkti failus, kurie bus siunčiami mokiniams
	if {$koks_veiksmas == "atsiskaitymas"} {
		set klase "[.statusbar.comboklase get]"
		if {$klase == ""} {
			tk_messageBox -message "Neparinkta klasė" -parent .n
			return
		}
		set kelias [db3 eval {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl='darbu_aplankas';}]
		if {$kelias == ""} {
			tk_messageBox -message "Nėra nustatytas aplankas, į kurį bus atsiunčiami mokinių atlikti darbai. Nustatyti aplanką galima per meniu Nustatymai -> Numatytieji aplankai..." -parent .n
			return
		}
	}
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	if {$::testi == 0} {
		return
	}
	if {$::variantusk == 0} {
		tk_messageBox -message "Kompiuteriams nėra priskirti variantai." -parent .n
		return
	}
	if {$koks_veiksmas == "atsiskaitymas"} {
		foreach pc $pasirinkti_pc {
			set nr [expr [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
			set mokinys "[.kompiuteriai.$nr cget -text]"
			if {$mokinys == ""} {
				tk_messageBox -message "Pažymėtas kompiuteris, prie kurio niekas nesėdi." -parent .n
				return
			}
		}
	}
	foreach pc $pasirinkti_pc {
		set nr [expr [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		set variantas [db3 onecolumn {SELECT var FROM current_pc_setup JOIN kompiuteriai ON kompiuteriai.Id=current_pc_setup.pc_id WHERE kompiuteriai.pc=$pc}]
		if {$variantas == 0} {
			p_ar_visiems_pirmas_variantas "Ne visiems pažymėtiems kompiuteriams yra priskirti variantai. Ar visiems siųsti vienodus failus?" p_failu_siuntimo_langas $koks_veiksmas
			return
		} else {
			p_icon_keitimas $nr pc$variantas
		}
	}
	set w .siusti
	p_naujas_langas $w "Rinktis failą"
	wm protocol $w WM_DELETE_WINDOW {
		destroy .siusti
		p_default_pc_state
	}
	set r 0
	grid [ttk::frame $w.faila -padding $::pad10] -column 0 -row 0
	grid [ttk::label $w.faila.tekstas -text "RINKTIS FAILĄ:"] -column 0 -row $r -pady 10 -columnspan 3; incr r
	for {set var 1} {$var<=$::variantusk} {incr var} {
		grid [ttk::label $w.faila.tekstas$var -text "VARIANTUI NR $var.:"] -column 0 -row $r -columnspan 3 -pady 2; incr r
		listbox $w.faila.lb$var -selectmode extended -listvariable ::failuvardai$var -height 4 -exportselection 0 -width 25 -selectbackground $::spalva
		scrollbar $w.faila.sb$var -command [list $w.faila.lb$var yview]
		$w.faila.lb$var configure -yscrollcommand [list $w.faila.sb$var set]
		grid [ttk::button $w.faila.prideti$var -text "" -image ad16 -command "p_prideti_faila $var $w" -style permatomas.TButton] -column 3 -row $r -sticky n
		grid [ttk::button $w.faila.isvalyti$var -text "" -image rem16 -command "set ::failusarasas$var {}; set ::parinktifailai$var {}; set ::failuvardai$var {}" -style permatomas.TButton] -column 3 -row $r -sticky s
		grid $w.faila.lb$var -column 0 -row $r -sticky nwes -columnspan 2
		grid $w.faila.sb$var -column 2 -row $r -sticky ns; incr r
		incr r
	}
	if {$koks_veiksmas == "atsiskaitymas"} {
		set siuntimo_komanda "p_siusti_faila {$pasirinkti_pc} $w $koks_veiksmas; if {\[ar_testi\]} {p_ar_ikelti_mokiniams_failus; p_ikelti_aplankus atsiskaitymas}"
	} else {
		set siuntimo_komanda "p_siusti_faila {$pasirinkti_pc} $w $koks_veiksmas"
	}
	grid [ttk::button $w.faila.siusti -text "Siųsti" -style mazaszalias.TButton -image mailsend -compound right -command $siuntimo_komanda] -column 0 -row $r -columnspan 3 -pady 10
}

proc p_siusti_faila {pasirinkti_pc w koks_veiksmas} {
#siunčia mokiniams parinktus failus
	for {set i 1} {$i<=$::variantusk} {incr i} {
		if {![info exists ::failusarasas$i] || [set ::failusarasas$i] == {}} {
			tk_messageBox -message "Kuriam nors variantui neparinktas failas, nėra ką siųsti!" -parent $w
			#sustabdo procedura ir jos nebevykdo
			set ::testi 0
			return
		} else {
			set ::testi 1
		}
	}
	if {$koks_veiksmas != "atsiskaitymas"} {
		.informacija.atlikta configure -text "Siunčiami failai... palaukite..."
		update idletasks
	}
	set pranesimas "Failai nusiųsti."
	destroy $w
	for {set i 1} {$i<=$::variantusk} {incr i} {
		catch {exec -ignorestderr sh -c "rm ./Siunciami_failai/*"}
		foreach failas [set ::failusarasas$i] {
			exec ln -s $failas ./Siunciami_failai/
		}
		foreach pc $pasirinkti_pc {
			set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
			set nr [expr $pc_id - 1]
			set display [db3 onecolumn {SELECT display FROM kompiuteriai WHERE Id=$pc_id}]
			set msg [cant_ping $pc]
			if {$msg == 1} {
				set pranesimas "Failai nusiųsti, bet ne visiems"
				p_icon_keitimas $nr pcunr
			} else {
				set variantas [db3 onecolumn {SELECT var FROM current_pc_setup WHERE pc_id=$pc_id}]
				if {$variantas == $i} {
					#p_send_command $nr "sudo chown mokytoja:mokytoja /home/mokinys/Nuo_mokytojos/"
					catch {exec -ignorestderr sh -c "scp ./Siunciami_failai/* mokytoja@$pc:/home/mokinys/Nuo_mokytojos/"}
					p_send_command $nr "sudo chown -R mokytoja:mokinys /home/mokinys/Nuo_mokytojos/*"
					p_send_command $nr "sudo chmod g+rx /home/mokinys/Nuo_mokytojos/*"
					if {$koks_veiksmas != "atsiskaitymas"} {
						#p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/zinute_random.tcl \"Aplanke „Nuo_mokytojos“ atsirado kažkas naujo.\" \"Pranešimas\" &"
						p_icon_keitimas $nr pccheck
					}
				}
			}
		}
	}
	if {$koks_veiksmas != "atsiskaitymas"} {
		p_veiksmas_atliktas $pranesimas
	}
}

proc p_prideti_faila {variantas w} {
#atveria langą, kuriame galima naršyti po kompiuterį ir pasirinkti failus, kurie bus siunčiami mokiniams
	set types {
		{{All Files} *}
		{{PDF and Office files} {.odt .doc .docx .pdf} TEXT}
		{{PDF Files} {.pdf}}
		{{Office files} {.odt .doc .docx} TEXT}
		{{Images} {.gif .png .bmp .xcf .jpg .jpeg}}
	}
	set failu_aplankas [db3 eval {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl='failu_aplankas'}]
	set parinktifailai$variantas [tk_getOpenFile -initialdir $failu_aplankas -multiple true -title Atverti -parent $w -filetypes $types]
	for {set j 1} {$j<=$::variantusk} {incr j} {
		if {![info exists ::failusarasas$j]} {
			set ::failusarasas$j ""
		}
		if {![info exists parinktifailai$j]} {
			set parinktifailai$j ""
		}
		set ::failusarasas$j [list {*}[set parinktifailai$j] {*}[set ::failusarasas$j]]
		set ::failuvardai$j ""
		foreach elementas [set ::failusarasas$j] {
			set last [string last "/" $elementas]
			incr last
			if {$last != [string length $elementas]} {
				lappend ::failuvardai$j [string range $elementas $last end]
			}
		}
	}
	return [set parinktifailai$variantas]
}
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_failu_surinkimas {} {
#leidžia mokytojai pasirinkti, kurių klasių ir kokie failai bus perkopijuoti į mokytojos kompiuterio numatytąjį aplanką
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	if {$::testi == 0} {
		return
	}
	set w .surinkimas
	p_naujas_langas $w "Mokinių failų surinkimas"
	set klase "[.statusbar.comboklase get]"
	set r 0
	set ::uzr_apl [db3 onecolumn {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl="uzrasu_aplankas"}]
	grid [ttk::frame $w.f -padding $::pad20 -relief groove -style baltas.TFrame] -column 0 -row 0 -sticky nwes -columnspan 3
	grid [ttk::label $w.f.lbl -text "Surinkti mokinių failus:" -style baltas.TLabel -justify center] -column 0 -row $r; incr r
	grid [ttk::frame $w.f1 -padding $::pad10] -column 0 -row $r -sticky nwes
	grid [ttk::frame $w.f2 -padding $::pad10] -column 1 -row $r -sticky nwes
	grid [ttk::frame $w.f3 -padding $::pad10] -column 2 -row $r -sticky nwes
	grid columnconfigure $w.f 0 -weight 1
	grid columnconfigure $w.f1 0 -weight 1
	grid columnconfigure $w.f1 1 -weight 1
	grid columnconfigure $w.f2 0 -weight 1
	grid columnconfigure $w.f2 1 -weight 1
	grid columnconfigure $w.f3 0 -weight 1
	grid [ttk::label $w.f1.siu -text "Šių metų:"] -column 0 -row $r -columnspan 2 -pady 10 -padx 10; incr r
	grid [ttk::button $w.f1.nvisus -text "" -image class_icon -command "p_mokiniu_failu_surinkimas $w \"$pasirinkti_pc\" dabartiniu visu"] -column 0 -row $r -padx 5 -pady 5
	setTooltip $w.f1.nvisus "Visų klasių"
	grid [ttk::button $w.f1.nvienoskl -text "" -image file_icon -command "p_mokiniu_failu_surinkimas $w \"$pasirinkti_pc\" dabartiniu vienos"] -column 1 -row $r -padx 5 -pady 5; incr r
	setTooltip $w.f1.nvienoskl "$klase klasės"
	grid [ttk::label $w.f2.praejusiu -text "Praėjusių metų:"] -column 0 -row $r -columnspan 2 -pady 10 -padx 10; incr r
	grid [ttk::button $w.f2.svisus -text "" -image class_icon -command "p_mokiniu_failu_surinkimas $w \"$pasirinkti_pc\" senu visu"] -column 0 -row $r -padx 5 -pady 5
	setTooltip $w.f2.svisus "Visų klasių"
	grid [ttk::button $w.f2.svienoskl -text "" -image file_icon -command "p_mokiniu_failu_surinkimas $w \"$pasirinkti_pc\" senu vienos"] -column 1 -row $r -padx 5 -pady 5
	setTooltip $w.f2.svienoskl "$klase klasės"
	grid [ttk::label $w.f3.vsiandlbl -text "Šiandienos:"] -column 0 -row $r -columnspan 2 -pady 10 -padx 10; incr r
	grid [ttk::button $w.f3.vsiand -text "" -image today_icon -command "p_mokiniu_failu_surinkimas $w \"$pasirinkti_pc\" siandienos visu"] -column 0 -row $r -padx 5 -pady 5
}

proc p_mokiniu_failu_surinkimas {w pasirinkti_pc kokiu_failu kokiu_klasiu} {
	if {$::uzr_apl == ""} {
		tk_messageBox -message "Jei norite surinkti mokinių failus, turite nustatyti aplanką, kuriame jie turės atsirasti. Tai galima padaryti per meniu Nustatymai -> Numatytieji aplankai..." -parent $w
		return
	}
	destroy $w
	set pranesimas "Mokinių failai surinkti."
	.informacija.atlikta configure -text "Surenkami mokinių failai... palaukite..."
	update idletasks
	if {$kokiu_failu == "senu"} {
		set aplankas "seni"
		set aplankas_mokytojui "Praejusiu_metu"
		exec mkdir -p $::uzr_apl/$aplankas_mokytojui
	}
	if {$kokiu_failu == "dabartiniu"} {
		set aplankas "dabartiniai"
		set aplankas_mokytojui "Siu_metu"
		puts "kuriam direktorija $::uzr_apl/$aplankas_mokytojui"
		exec mkdir -p $::uzr_apl/$aplankas_mokytojui
	}
	if {$kokiu_klasiu == "visu"} {
		set klases [db3 eval {SELECT klase FROM klases ORDER BY klase}]
	} else {
		set klases "[.statusbar.comboklase get]"
	}
	foreach pc $pasirinkti_pc {
		foreach klase $klases {
			if {$klase != "Testinė_klasė"} {
				if {$kokiu_failu != "siandienos"} {
					exec mkdir -p $::uzr_apl/$aplankas_mokytojui/$klase
				}
				set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
				set nr [expr $pc_id - 1]
				set msg [cant_ping $pc]
				if {$msg == 1} {
					set pranesimas "Mokinių failai surinkti, bet ne visi."
					p_icon_keitimas $nr pcunr
				} else {
					p_send_command $nr "sudo chmod -R o+r /home/mokytoja/mokiniu_failai/"
					if {$kokiu_failu == "siandienos"} {
						set mokid [db3 onecolumn {SELECT mokiniai.Id FROM mokiniai JOIN klases ON klases.Id=mokiniai.klases_id WHERE pc_id=$pc_id AND klases.klase=$klase AND esamas_ar_buves=1}]
						lassign [db3 eval {SELECT vardas, pavarde FROM mokiniai WHERE Id=$mokid}] vardas pavarde
						catch {
							exec -ignorestderr ssh -o ConnectTimeout=1 mokytoja@$pc "cd /home/mokytoja/mokiniu_failai/$klase/dabartiniai/; find . -type f,d -newermt \$(date +%Y-%m-%d -d 'today') -print0 | xargs -0 tar --no-recursion -cjvf  /home/mokytoja/siandienos.tbz2"
							#exec -ignorestderr ssh -o ConnectTimeout=1 mokytoja@$pc "cd /home/mokytoja/mokiniu_failai/$klase/dabartiniai/; find . -type f,d -newermt \$(date  +%Y-%m-%d -d '-2 days') -print0 | xargs -0 tar --no-recursion -cjvf  /home/mokytoja/siandienos.tbz2"
							#jeigu reiktų pakeisti dieną, galima rašyti visaip, pvz.:  date -d '-5 days + 2 weeks -9001 seconds'
							exec mkdir -p $::uzr_apl/$::siandiena-$klase/$pavarde-$vardas-ID$mokid
							exec -ignorestderr sh -c "cd '$::uzr_apl/$::siandiena-$klase/$pavarde-$vardas-ID$mokid'; ssh -o ConnectTimeout=1 'mokytoja@$pc' cat /home/mokytoja/siandienos.tbz2 | tar xj"
						}
						#set siandienosf [split $siandienosf "\n"]
						#set len [string length /home/mokytoja/mokiniu_failai/$klase/dabartiniai]
						#foreach failas $siandienosf {
							##set failas [regsub -all { } $failas {\\ }]
							#set destination [file dirname [string replace $failas 0 $len]]
							#if {$destination == ""} {
								#continue
							#}
							#exec mkdir -p $::uzr_apl/$::siandiena-$klase/$vardas-$pavarde-ID$mokid/$destination
							#catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 -r 'mokytoja@$pc:$failas' '$::uzr_apl/$::siandiena-$klase/$vardas-$pavarde-ID$mokid/$destination'"}
						#}
					} else {
						p_send_command $nr "sudo chmod -R a+rwx /home/mokytoja/mokiniu_failai/$klase/$aplankas/*"
						catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 -r mokytoja@$pc:/home/mokytoja/mokiniu_failai/$klase/$aplankas/* $::uzr_apl/$aplankas_mokytojui/$klase/"}
					}
					p_icon_keitimas $nr pccheck
				}
			}
		}
	}
	p_veiksmas_atliktas $pranesimas
}
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_testu_parinkimo_langas {ar_pazymiui} {
#parodo langą, kuriame galima parinkti, kuriems kompiuteriams koks testas bus vykdomas
	set klase "[.statusbar.comboklase get]"
	if {$klase == ""} {
		tk_messageBox -message "Neparinkta klasė." -parent .n
		return
	}
	if {$ar_pazymiui == 1} {
		set mygtuko_tekstas "Pradėti testą"
		set mygtuko_pav "test_icon"
		set rinkimosi_tekstas "RINKTIS TESTĄ:"
		set lango_pavadinimas "Testo parinkimas"
		set klausimas "Ne visiems pažymėtiems kompiuteriams yra priskirti variantai. Ar visiems duoti vienodą testą?"
		set kas_toks "TESTAS"
	} else {
		set mygtuko_tekstas "Pradėti apklausą"
		set mygtuko_pav "pie_icon"
		set rinkimosi_tekstas "RINKTIS APKLAUSĄ:"
		set lango_pavadinimas "Apklausos parinkimas"
		set klausimas "Ne visiems pažymėtiems kompiuteriams yra priskirti variantai. Ar visiems duoti vienodą apklausą?"
		set kas_toks "APKLAUSA"
	}
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	if {$::testi == 0} {
		return
	}
	if {$::variantusk == 0} {
		tk_messageBox -message "Kompiuteriams nėra priskirti variantai." -parent .n
		return
	}
	set ar_tusti_pc ""
	foreach pc $pasirinkti_pc {
		set nr [expr [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		set mokinys "[.kompiuteriai.$nr cget -text]"
		if {$mokinys == ""} {
			lappend ar_tusti_pc 1
		}
	}
	if {$ar_tusti_pc != ""} {
		p_ar_tikrai "Pažymėtas kompiuteris, prie kurio niekas nesėdi. Ar tikrai tęsti?" "set ::testi 1"
		if {$::testi == 0} {
			return
		}
	}
	foreach pc $pasirinkti_pc {
		set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
		set nr [expr $pc_id - 1]
		set variantas [db3 eval {SELECT var FROM current_pc_setup WHERE pc_id=$pc_id}]
		if {$variantas == 0} {
			p_ar_visiems_pirmas_variantas $klausimas p_testu_parinkimo_langas $ar_pazymiui
			return
		} else {
			p_icon_keitimas $nr pc$variantas
		}
	}
	set testai [db3 eval {SELECT testo_pavad FROM testai ORDER BY Id DESC}]
	set w .testai
	p_naujas_langas $w $lango_pavadinimas
	wm protocol $w WM_DELETE_WINDOW {
		destroy .testai
		p_default_pc_state
	}
	set r 0
	set testoklases [db3 eval {SELECT klase FROM destomos_klases ORDER BY klase ASC}]
	set ::testoklase ""
	grid [ttk::frame $w.testai -padding $::pad20] -column 0 -row 0
	grid [ttk::label $w.testai.klasetxt -text "KLASĖ:"] -column 0 -row $r -pady 10
	grid [ttk::combobox $w.testai.klasecombo -textvariable ::testoklase -width 7] -column 1 -row $r -padx 15 -sticky w; incr r
	$w.testai.klasecombo configure -values $testoklases
	for {set var 1} {$var<=$::variantusk} {incr var} {
		grid [ttk::label $w.testai.tekstas$var -text "$kas_toks VARIANTUI NR $var.:"] -column 0 -row $r -pady 5 -columnspan 2 -padx 15; incr r
		grid [ttk::combobox $w.testai.variantai$var -textvariable ::testas$var -width 18] -column 0 -row $r -columnspan 2 -padx 15; incr r
		$w.testai.variantai$var configure -values $testai
		bind $w.testai.klasecombo <<ComboboxSelected>> "p_perpiesti_testu_laukeli \$::testoklase $w $var"
	}
	grid [ttk::button $w.testai.pradeti -text $mygtuko_tekstas -style mazaszalias.TButton -image $mygtuko_pav -compound right -command "p_generuoti_testo_laikina_db \"$pasirinkti_pc\" $ar_pazymiui $klase $w"] -column 0 -row $r -pady 15 -columnspan 2
}

proc p_perpiesti_testu_laukeli {testoklase w var} {
	set testai [db3 eval {SELECT testo_pavad FROM testai WHERE klase=$testoklase ORDER BY Id DESC}]
	for {set var 1} {$var<=$::variantusk} {incr var} {
		$w.testai.variantai$var configure -values $testai
	}
}

proc p_generuoti_testo_laikina_db {pasirinkti_pc ar_pazymiui klase w} {
#sugeneruoja laikiną testo duomenų bazę ir išsiunčia ją pasirinktiems kompiuteriams.
	set testu_pavadinimai ""
	foreach pc $pasirinkti_pc {
	#šis ciklas yra skirtas tam, kad kuo greičiau nusikratyti langu $w, kad būtų aišku, kad testai yra siunčiami. Jeigu būtų atsikratoma langu vėliau, vartotojui nebūtų aišku.
		set pc_id [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
		set nr [expr $pc_id - 1]
		set parinktas_variantas [db3 onecolumn {SELECT var FROM current_pc_setup WHERE pc_id=$pc_id}]
		set testo_pavadinimas "[$w.testai.variantai$parinktas_variantas get]"
		if {$testo_pavadinimas == ""} {
			tk_messageBox -message "Ne visiems variantams parinktas testas." -parent $w
			return
		}
		lappend testu_pavadinimai $testo_pavadinimas
	}
	p_ar_mokinys_negaus_to_paties_testo $pasirinkti_pc $klase $testu_pavadinimai $w
	if {$::testi == 0} {
		return
	}
	destroy $w
	if {$ar_pazymiui == 1} {
		set komp_pav "pctest"
		set zinutes_tekstas "Siunčiami testai... palaukite..."
		set pranesimas "Testai nusiųsti."
	} else {
		set komp_pav "pcapklausa"
		set zinutes_tekstas "Siunčiamos apklausos... palaukite..."
		set pranesimas "Apklausos nusiųstos."
	}
	.informacija.atlikta configure -text $zinutes_tekstas
	update idletasks
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$klase}]
	set i 0
	foreach pc $pasirinkti_pc {
		set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		set pc_id [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
		set display [db3 onecolumn {SELECT display FROM kompiuteriai WHERE Id=$pc_id}]
		set ar_alien [db3 onecolumn {SELECT ar_alien FROM current_pc_setup WHERE pc_id=$pc_id}]
		if {$ar_alien == 0} {
			set mokid [db3 onecolumn {SELECT Id FROM mokiniai WHERE klases_id=$klases_id AND pc_id=$pc_id AND esamas_ar_buves=1}]
		} else {
			set mokid [db3 onecolumn {SELECT mok_id FROM current_pc_setup WHERE pc_id=$pc_id}]
			set klase [db3 onecolumn {SELECT klase FROM klases JOIN mokiniai ON klases.Id=mokiniai.klases_id WHERE mokiniai.Id=$mokid}]
		}
		lassign [db3 eval {SELECT vardas, pavarde FROM mokiniai WHERE Id=$mokid}] vardas pavarde
		set testo_pavadinimas [lindex $testu_pavadinimai $i]
		if {$mokid == ""} {
			set mokid 0
		}
		incr i
		set msg [cant_ping $pc]
		if {$msg == 1} {
			set pranesimas "Nusiųsta, bet ne visiems"
			p_icon_keitimas $nr pcunr
		} else {
			exec rm ./klausimai
			sqlite3 db2 ./klausimai
			db3 eval {ATTACH DATABASE './klausimai' as 'tst'}
			db2 eval {CREATE TABLE if not exists m_paveiksleliai(Id integer primary key autoincrement, pavad text, content text)}
			db2 eval {CREATE TABLE if not exists m_testai(Id integer primary key autoincrement, testo_pavad text unique)}
			db2 eval {CREATE TABLE if not exists m_klausimai_testai(testo_id integer, klausimo_id integer, klausimo_nr integer, verte_taskais integer)}
			db2 eval {CREATE TABLE if not exists m_klausimai(Id integer primary key autoincrement, kl text, tipas text, pav_id text)}
			db2 eval {CREATE TABLE if not exists m_atsakymuvariantai(Id integer primary key autoincrement, klausimo_id integer, atsakymo_var text, ar_teisingas_var text, pasirinko integer, tsk_jei_pasirinko integer, tsk_jei_nepasirinko integer)}
			db2 eval {CREATE TABLE if not exists m_options(pavadinimas text, reiksme text)}
			db3 eval {INSERT INTO m_testai (Id, testo_pavad) SELECT Id, testo_pavad FROM testai WHERE testo_pavad=$testo_pavadinimas}
			set testoid [db3 eval {SELECT Id FROM m_testai}]
			db3 eval {INSERT INTO m_klausimai_testai (testo_id, klausimo_id, klausimo_nr, verte_taskais) 
				SELECT testo_id, klausimo_id, klausimo_nr, verte_taskais FROM klausimai_testai WHERE testo_id=$testoid}
			set kl_ids [db3 eval {SELECT klausimo_id FROM m_klausimai_testai}]
			
			db3 eval {INSERT INTO m_klausimai (Id, kl, tipas, pav_id) 
				SELECT Id, kl, tipas, pav_id FROM klausimai WHERE Id IN(SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$testoid)}
			
			db3 eval {INSERT INTO m_atsakymuvariantai 
				(Id, klausimo_id, atsakymo_var, ar_teisingas_var, tsk_jei_pasirinko, tsk_jei_nepasirinko) 
				SELECT Id, klausimo_id, atsakymo_var, ar_teisingas_var, tsk_jei_pasirinko, tsk_jei_nepasirinko 
				FROM atsakymuvariantai 
				WHERE Id IN(
					SELECT Id FROM atsakymuvariantai WHERE klausimo_id IN (SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$testoid)
				)}
			db3 eval {INSERT INTO m_paveiksleliai (Id, pavad, content) SELECT Id, pavad, content FROM paveiksleliai WHERE Id IN (SELECT DISTINCT pav_id FROM m_klausimai)}
			db3 eval {INSERT INTO m_options (pavadinimas, reiksme) VALUES("mokinio id", $mokid)}
			db3 eval {INSERT INTO m_options (pavadinimas, reiksme) VALUES("mokinio vardas", $vardas)}
			db3 eval {INSERT INTO m_options (pavadinimas, reiksme) VALUES("mokinio pavarde", $pavarde)}
			db3 eval {INSERT INTO m_options (pavadinimas, reiksme) VALUES("mokinio klase", $klase)}
			
			if {$ar_pazymiui==1} {
				db3 eval {INSERT INTO m_options (pavadinimas, reiksme) VALUES("ar_pazymiui", 1)}
			} else {
				db3 eval {INSERT INTO m_options (pavadinimas, reiksme) VALUES("ar_pazymiui", 0)}
			}
			db3 eval {DETACH DATABASE 'tst'}
			db2 close
			p_send_command $nr "sudo rm /skriptai/klausimai"
			catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 ./klausimai mokytoja@$pc:/skriptai/"}
			p_send_command $nr "sudo chmod a+rwx /skriptai/klausimai"
			set aplankas $::siandiena-$klase
			catch {exec -ignorestderr sh -c "mkdir -p './Testai/$aplankas'"}
			p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /skriptai/Testas.tcl &"
			p_icon_keitimas $nr $komp_pav
			incr r
			bind .kompiuteriai.c$nr <3> "p_sunaikinti_testa $nr"
			db3 eval "UPDATE current_pc_setup SET testo_id=$testoid WHERE pc_id=$pc_id"
			db3 eval "UPDATE current_pc_setup SET mok_id=$mokid WHERE pc_id=$pc_id"
			after 3000 "chan puts \[set ::chan$nr\] {tail -f --pid \$(pidof -x Testas.tcl) /dev/null 2>/dev/null && echo test_ended &}"
		}
	}
	p_veiksmas_atliktas $pranesimas
}

proc p_sunaikinti_testa {nr} {
	set pc_nr [expr $nr + 1]
	p_ar_tikrai "Ar tikrai norite sunaikinti testą kompiuteriui $pc_nr?" "set ::testi 1"
	if {$::testi == 0} {
		return
	}
	#clear test id, so that p_testas_uzbaigtas knows that nothing needs to be collected
	db3 eval "UPDATE current_pc_setup SET testo_id=0 WHERE pc_id=$nr + 1"
	p_send_command $nr "sudo killall /usr/bin/wish"
	p_icon_keitimas $nr "pcneutral"
	.kompiuteriai.$nr configure -style pilkas.TLabel
	bind .kompiuteriai.c$nr <3> ""
}

proc p_ar_mokinys_negaus_to_paties_testo {pasirinkti_pc klase testu_pavadinimai w} {
	set i 0
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$klase}]
	foreach pc $pasirinkti_pc {
		set pc_id [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
		set ar_alien [db3 onecolumn {SELECT ar_alien FROM current_pc_setup WHERE pc_id=$pc_id}]
		if {$ar_alien == 0} {
			set mokid [db3 onecolumn {SELECT Id FROM mokiniai WHERE klases_id=$klases_id AND pc_id=$pc_id AND esamas_ar_buves=1}]
		} else {
			set mokid [db3 onecolumn {SELECT mok_id FROM current_pc_setup WHERE pc_id=$pc_id}]
			set klase [db3 onecolumn {SELECT klase FROM klases JOIN mokiniai ON klases.Id=mokiniai.klases_id WHERE mokiniai.Id=$mokid}]
		}
		lassign [db3 eval {SELECT vardas, pavarde FROM mokiniai WHERE Id=$mokid}] vardas pavarde
		set testo_pavadinimas [lindex $testu_pavadinimai $i]
		set testo_id [db3 onecolumn {SELECT Id FROM testai WHERE testo_pavad=$testo_pavadinimas}]
		set bandymo_id [db3 onecolumn {SELECT Id FROM bandymai WHERE mokinio_id=$mokid AND testo_id=$testo_id}]
		if {$bandymo_id != ""} {
			set ::testi 0
			tk_messageBox -message "$vardas $pavarde jau atliko „$testo_pavadinimas“." -parent $w
			return
			#p_ar_tikrai "$vardas $pavarde jau atliko „$testo_pavadinimas“. Ar tikrai duoti tą patį testą?" {set ::testi 1}
			#return
		}
		incr i
	}
	set ::testi 1
}

proc p_testas_uzbaigtas {nr} {
	#kai mokinys užbaigia testą, atsiunčia testo atsakymus į mokytojo kompiuterį automatiškai. Taip pat pakeičia kompiuterių piktogramas.
	set pc_id [expr $nr + 1]
	if {[db3 onecolumn {SELECT testo_id FROM current_pc_setup WHERE pc_id=$pc_id}] == 0} {
		return
		#test was terminated by the teacher, do not collect anything
	}
	set pc [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$pc_id}]
	set mokid [db3 onecolumn {SELECT mok_id FROM current_pc_setup WHERE pc_id=$pc_id}]
	set klase [db3 onecolumn {SELECT klase FROM klases JOIN mokiniai ON klases.Id=mokiniai.klases_id WHERE mokiniai.Id=$mokid}]
	set aplankas $::siandiena-$klase
	catch {exec -ignorestderr sh -c "mkdir -p './Testai/$aplankas'"}
	exec -ignorestderr sh -c "scp -o ConnectTimeout=1 mokytoja@$pc:/skriptai/klausimai './Testai/$aplankas/klausimai$pc'"
	set datab "./Testai/$aplankas/klausimai$pc"
	db3 eval {ATTACH DATABASE $datab as 'laikinas$pc'}
	set testoid [db3 eval {SELECT Id FROM laikinas$pc.m_testai}]
	
	set testo_klausimu_ids [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$testoid}]
	set testo_klausimu_skaicius [db3 eval {SELECT COUNT(*) FROM klausimai_testai WHERE testo_id=$testoid}]
	set atviru_klausimu_sk 0
	for {set i 0} {$i<=$testo_klausimu_skaicius} {incr i} {
		set klid [lindex $testo_klausimu_ids $i]
		set tipas [db3 onecolumn {SELECT tipas FROM klausimai WHERE Id=$klid}]
		if {$tipas == "atviras_kl"} {
			set atviru_klausimu_sk [expr $atviru_klausimu_sk + 1]
		}
	}
	if {$atviru_klausimu_sk == 0 && $mokid != 0} {
		set ar_istaisyta 1
	} else {
		set ar_istaisyta 0
	}
	
	set ar_jau_yra_tokie_atsakymai [db3 onecolumn {SELECT Id FROM bandymai WHERE testo_id=$testoid AND mokinio_id=$mokid}]
	if {$ar_jau_yra_tokie_atsakymai == "" || $mokid == 0} {
		db3 eval {INSERT INTO bandymai (mokinio_id, testo_id, data, ar_istaisyta, penalty_tsk, pc) VALUES ($mokid, $testoid, $::siandiena, $ar_istaisyta, 0, $pc)}
		set bandymo_id [db3 onecolumn {SELECT last_insert_rowid()}]
		db3 eval {INSERT INTO bandymai_pasirinkimai (bandymo_id, atsvar_id, atsakymo_tekstas, ar_pasirinko) 
			SELECT $bandymo_id, Id, atsakymo_var, pasirinko FROM laikinas$pc.m_atsakymuvariantai}
		db3 eval {INSERT INTO bandymai_options (bandymo_id, pavadinimas, reiksme) SELECT $bandymo_id, pavadinimas, reiksme FROM laikinas$pc.m_options}
		set kl_ids [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$testoid}]
		foreach kl_id $kl_ids {
			set verte [format "%.2f" [db3 eval {SELECT verte_taskais FROM klausimai_testai WHERE klausimo_id=$kl_id AND testo_id=$testoid}]]
			set kl_var_ids [db3 eval {SELECT atsvar_id FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id 
				WHERE bandymo_id=$bandymo_id AND klausimo_id=$kl_id}]
			foreach at $kl_var_ids {
				db3 eval {UPDATE bandymai_pasirinkimai 
					SET tsk=$verte*(SELECT CASE(ar_pasirinko) WHEN 1 THEN tsk_jei_pasirinko ELSE tsk_jei_nepasirinko END FROM atsakymuvariantai WHERE atsakymuvariantai.Id=atsvar_id) 
					WHERE bandymo_id=$bandymo_id AND atsvar_id=$at}
			}
		}
		if {$ar_istaisyta == 1} {
			set pazymys [p_calculate_grade $testoid $bandymo_id]
			db3 eval {UPDATE bandymai SET pazymys=$pazymys WHERE Id=$bandymo_id}
		}
	}
	set ar_pazymiui [db3 onecolumn {SELECT reiksme FROM laikinas$pc.m_options WHERE pavadinimas="ar_pazymiui"}]	
	db3 eval {DETACH DATABASE 'laikinas$pc'}
	db3 eval "UPDATE current_pc_setup SET testo_id = 0 WHERE pc_id = $pc_id"
	if {$ar_pazymiui == 1} {
		set ka_baige "testą"
		p_icon_keitimas $nr pctestatlikta
	} else {
		set ka_baige "apklausą"
		p_icon_keitimas $nr pccheck
	}
	p_tikrinti_ar_visi_baige $ka_baige
}

proc p_surinkti_atsakymus {kas} {
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	if {$::testi == 0} {
		return
	}
	foreach pc $pasirinkti_pc {
		set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
		if {$kas == "testas"} {
			set ar_pradeta [db3 onecolumn {SELECT testo_id FROM current_pc_setup WHERE pc_id = $pc_id}]
		} else {
			set ar_pradeta [db3 onecolumn {SELECT atsiskaitymas FROM current_pc_setup WHERE pc_id = $pc_id}]
		}
		if {$ar_pradeta == 0} {
			break
		}
	}
	if {$ar_pradeta == 0} {
		p_ar_tikrai "Panašu, kad pažymėtuose kompiuteriuose nėra pradėtas $kas. Ar vis tiek mėginti surinkti rezultatus?" "set ::testi 1"
	}
	if {$::testi == 0} {
		return
	}
	if {$kas == "testas"} {
		set pranesimas "Testo atsakymai surinkti"
		.informacija.atlikta configure -text "Surenkami testo atsakymai... palaukite..."
	} else {
		set pranesimas "Atsiskaitymai surinkti"
		.informacija.atlikta configure -text "Surenkami atsiskaitymai... palaukite..."
	}
	update idletasks
	foreach pc $pasirinkti_pc {
		set nr [expr [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}] - 1]
		set msg [cant_ping $pc]
		if {$msg == 1} {
			set pranesimas "Surinkta, bet ne iš visų"
			p_icon_keitimas $nr pcunr
		} else {
			if {$kas == "testas"} {
				p_testas_uzbaigtas $nr
			} else {
				p_atsiskaitymas_uzbaigtas $nr
			}
		}
	}
	p_veiksmas_atliktas $pranesimas
}

proc p_tikrinti_ar_visi_baige {ka_baige} {
	set visi_kompiuteriai [db3 eval {SELECT pc FROM kompiuteriai}]
	if {$ka_baige == "testą" || $ka_baige == "apklausą"} {
		set atlikti_testai ""
		foreach pc $visi_kompiuteriai {
			set nr [expr [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
			set testo_busena [db3 onecolumn {SELECT testo_id FROM current_pc_setup JOIN kompiuteriai ON current_pc_setup.pc_id=kompiuteriai.Id WHERE kompiuteriai.pc=$pc}]
			if {$testo_busena != 0} {
				return
			}
		}
		p_veiksmas_atliktas "Visi mokiniai baigė $ka_baige"
	} else {
		set atlikti_atsiskaitymai ""
		foreach pc $visi_kompiuteriai {
			set nr [expr [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
			set atsiskaitymo_busena [db3 onecolumn {SELECT atsiskaitymas FROM current_pc_setup JOIN kompiuteriai ON current_pc_setup.pc_id=kompiuteriai.Id WHERE kompiuteriai.pc=$pc}]
			if {$atsiskaitymo_busena == 1} {
				return
			}
		}
		p_veiksmas_atliktas "Visi mokiniai baigė atsiskaitymą"
	}
}
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_ikelti_aplankus {koks_veiksmas} {
	set klase "[.statusbar.comboklase get]"
	if {$klase == ""} {
		tk_messageBox -message "Neparinkta klasė." -parent .n
		return
	}
	set pasirinkti_pc [p_kokius_pc_pasirinko]
	if {$::testi == 0} {
		return
	}
	if {$koks_veiksmas == "atsiskaitymas"} {
		set kas_vyksta "Siunčiamos užduotys... palaukite..."
		set pranesimas "Užduotys įkeltos"
		set komp_pav "pctable"
		set klaida "Atsiskaitymas jau buvo pradėtas!"
		set pam_pradzios_komandos "
			sudo mkdir -p /home/mokinys/Mano_failai
			sudo mount -o bind /home/mokytoja/mokiniu_failai/$klase/dabartiniai /home/mokinys/Mano_failai;
			sudo chown -R mokinys:mokinys /home/mokinys/Mano_failai
		"
	} else {
		set kas_vyksta "Įkeliami mokinių failai... palaukite..."
		set pranesimas "Mokinių failai įkelti"
		set zinute_mokiniui "Tavo failai atsirado aplanke „Mano_failai“."
		set komp_pav "pcfopen"
		set klaida "Mokinių aplankai jau buvo įkelti!"
		set pam_pradzios_komandos "
			sudo mkdir -p /home/mokinys/Mano_failai
			sudo mkdir -p /home/mokinys/Seni_failai
			sudo mount -o bind /home/mokytoja/mokiniu_failai/$klase/dabartiniai /home/mokinys/Mano_failai;
			sudo mount -o bind /home/mokytoja/mokiniu_failai/$klase/seni /home/mokinys/Seni_failai;
			sudo chown -R mokinys:mokinys /home/mokinys/Mano_failai
			sudo chown -R mokinys:mokinys /home/mokinys/Seni_failai
		"
	}
	set ::ar_siusti_pranesima 0
	if {$koks_veiksmas != "atsiskaitymas"} {
		p_naujas_langas .ar_pranesimas "Klausimas"
		wm attribute .ar_pranesimas -topmost 1
		wm protocol .ar_pranesimas WM_DELETE_WINDOW {
			set ::ar_siusti_pranesima 2
			destroy .ar_pranesimas
		}
		grid [ttk::frame .ar_pranesimas.klausimas -padding $::pad20] -column 0 -row 0 -sticky nwes
		grid [ttk::label .ar_pranesimas.klausimas.txt -text "Ar įkeliant failus siųsti pranešimą?" -padding "5 5" -style didelis.TLabel -wraplength 350] -column 0 -columnspan 2 -row 0
		grid [ttk::button .ar_pranesimas.klausimas.taip -text "Taip" -command "set ::ar_siusti_pranesima 1; destroy .ar_pranesimas" -padding $::pad10 -style zalias.TButton] -padx 1 -pady 1 -column 0 -row 1
		grid [ttk::button .ar_pranesimas.klausimas.ne -text "Ne" -style raudonas.TButton -command "destroy .ar_pranesimas" -padding $::pad10] -padx 1 -pady 1 -column 1 -row 1
		tkwait window .ar_pranesimas
	}
	if {$::ar_siusti_pranesima == 2} {
		return
	}
	
	foreach pc $pasirinkti_pc {
		set pc_id [db3 onecolumn {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
		set ar_primountinta [db3 onecolumn {SELECT ar_primountinta FROM current_pc_setup WHERE pc_id = $pc_id}]
		if {$ar_primountinta == 1} {
		#if {[catch {exec -ignorestderr ssh -o ConnectTimeout=1 mokytoja@$pc "grep '/home/mokinys' /etc/mtab"}] == 0} {
			tk_messageBox -message $klaida -parent .n
			return
		}
		#}
	}
	.informacija.atlikta configure -text $kas_vyksta
	update idletasks
	foreach pc $pasirinkti_pc {
		set nr [expr [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]-1]
		set pc_id [expr $nr+1]
		set display [db3 onecolumn {SELECT display FROM kompiuteriai WHERE Id=$pc_id}]
		set msg [cant_ping $pc]
		if {$msg == 1} {
			set pranesimas "Failai įkelti, bet ne visiems"
			p_icon_keitimas $nr pcunr
		} else {
			set ar_alien [db3 onecolumn {SELECT ar_alien FROM current_pc_setup WHERE pc_id=$pc_id}]
			if {$ar_alien == 1} {
				set mok_id [db3 onecolumn {SELECT mok_id FROM current_pc_setup WHERE pc_id=$pc_id AND ar_alien=1}]
				set vardas [db3 onecolumn {SELECT vardas FROM mokiniai WHERE Id=$mok_id}]
				set pavarde [db3 onecolumn {SELECT pavarde FROM mokiniai WHERE Id=$mok_id}]
				set klases_id [db3 onecolumn {SELECT klases_id FROM mokiniai WHERE Id=$mok_id}]
				set klase [db3 onecolumn {SELECT klase FROM klases WHERE Id=$klases_id}]
			} else {
				set klases_id [db3 eval {SELECT Id FROM klases WHERE klase=$klase}]		
				set vardas [db3 onecolumn {SELECT vardas FROM mokiniai WHERE klases_id=$klases_id AND pc_id=$pc_id AND esamas_ar_buves=1}]
				set pavarde [db3 onecolumn {SELECT pavarde FROM mokiniai WHERE klases_id=$klases_id AND pc_id=$pc_id AND esamas_ar_buves=1}]
				set mok_id [db3 onecolumn {SELECT Id FROM mokiniai WHERE klases_id=$klases_id AND vardas=$vardas AND pavarde=$pavarde AND esamas_ar_buves=1}]
			}
			if {$mok_id != {}} {
				if {$koks_veiksmas == "atsiskaitymas"} {
					#set data [p_parinkti_data]
					#čia nebaigiau dar su datos parinkimu, kad būtų vietoj kintamojo siandiena
					set atsiskaitymo_komandos "
						sudo mkdir /home/mokytoja/atsiskaitymai/$klase/;
						sudo mkdir /home/mokytoja/atsiskaitymai/$klase/$::siandiena/;
						sudo chown -R mokinys:mokinys /home/mokytoja/atsiskaitymai/*;
						sudo mkdir -p /home/mokinys/Atsiskaitymai;
						sudo mount -o bind /home/mokytoja/atsiskaitymai/$klase/$::siandiena/ /home/mokinys/Atsiskaitymai;
						sudo chown -R mokinys:mokinys /home/mokinys/Atsiskaitymai;
					"
					p_send_command $nr $atsiskaitymo_komandos
					if {$::ar_ikelti_mokiniu_failus == 1} {
						p_send_command $nr $pam_pradzios_komandos
					}
					db3 eval "UPDATE current_pc_setup SET atsiskaitymas = 1 WHERE pc_id = $pc_id"
					p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /skriptai/atsiskaitymas.tcl &"
					after 3000 "chan puts \[set ::chan$nr\] {tail -f --pid \$(pidof -x atsiskaitymas.tcl) /dev/null 2>/dev/null && echo task_ended &}"
				} else {
					p_send_command $nr $pam_pradzios_komandos
					if {$::ar_siusti_pranesima == 1} {
						p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/zinute_random.tcl \"$zinute_mokiniui\" \"Pranešimas\" &"
					}
				}
				p_icon_keitimas $nr $komp_pav
				db3 eval "UPDATE current_pc_setup SET mok_id = $mok_id WHERE pc_id = $pc_id"
				db3 eval "UPDATE current_pc_setup SET ar_primountinta = 1 WHERE pc_id = $pc_id"
			}
		}
	}
	p_veiksmas_atliktas $pranesimas
}

proc p_ar_ikelti_mokiniams_failus {} {
	p_naujas_langas .artikrai "Klausimas"
	wm attribute .artikrai -topmost 1
	grid [ttk::frame .artikrai.klausimas -padding $::pad20] -column 0 -row 0 -sticky nwes
	set r 1
	grid [ttk::label .artikrai.klausimas.lbl -text "Ar įkelti mokiniams jų užrašus?" -padding "5 5"] -column 0 -columnspan 2 -row $r; incr r
	grid [ttk::button .artikrai.klausimas.taip -text "Taip" -style zalias.TButton -command "set ::ar_ikelti_mokiniu_failus 1; destroy .artikrai" -padding $::pad10] -padx 1 -pady 1 -column 0 -row $r
	grid [ttk::button .artikrai.klausimas.ne -text "Ne" -style raudonas.TButton -command "set ::ar_ikelti_mokiniu_failus 0; destroy .artikrai" -padding $::pad10] -padx 1 -pady 1 -column 1 -row $r; incr r
	tkwait window .artikrai
}

proc p_parinkti_data {} {
	#nebaigta procedura @TODO
	set w .data
	p_naujas_langas $w "Parinkite datą"
	set r 0
	set metai ""
	grid [ttk::frame $w.f -padding $::pad20] -column 0 -row 0 -sticky nwes
	grid [ttk::label $w.f.lbl -text "Pasirinkite atsiskaitymo datą:" -padding "5 5"] -column 0 -columnspan 2 -row $r; incr r
	grid [ttk::combobox $w.f.metai -textvariable ::metai -width 15] -column 0 -row $r -padx 10 -sticky w; incr r
	$w.f.metai configure -values $metai
	grid [ttk::button $w.f.ok -text "Gerai" -style zalias.TButton -command "" -padding $::pad10] -padx 1 -pady 1 -column 0 -row $r
}

proc p_atsiskaitymas_uzbaigtas {nr} {
	set pc_id [expr $nr + 1]
	set display [db3 onecolumn {SELECT display FROM kompiuteriai WHERE Id=$pc_id}]
	set pc [db3 onecolumn {SELECT pc FROM kompiuteriai WHERE Id=$pc_id}]
	set mokid [db3 onecolumn {SELECT mok_id FROM current_pc_setup JOIN kompiuteriai ON kompiuteriai.Id=current_pc_setup.pc_id WHERE kompiuteriai.pc=$pc}]
	set klase [db3 onecolumn {SELECT klase FROM klases JOIN mokiniai ON klases.Id=mokiniai.klases_id WHERE mokiniai.Id=$mokid}]
	lassign [db3 eval {SELECT vardas, pavarde FROM mokiniai WHERE Id=$mokid}] vardas pavarde
	set ats_pab_komandos1 "
		sudo umount -l /home/mokinys/Atsiskaitymai;
		sudo umount -l /home/mokinys/Mano_failai/;
		sudo umount -l /home/mokinys/Seni_failai;
	"
	set ats_pab_komandos2 "
		sudo rm -rf /home/mokinys/Nuo_mokytojos/* /home/mokinys/*.png /home/mokinys/*.jpg /home/mokinys/*.odt /home/mokinys/*.doc /home/mokinys/*.docx /home/mokinys/*.txt /home/mokinys/*.bmp /home/mokinys/*.xcf /home/mokinys/*.pdf /home/mokinys/Darbastalis/* /home/mokinys/.local/share/Trash/files/
		sudo rm -rf /home/mokinys/Atsiskaitymai
		sudo rm -rf /home/mokinys/Mano_failai
		sudo rm -rf /home/mokinys/Seni_failai
	"
	#set pam_pabaigos_komandos "
		#sudo umount -l /home/mokinys/Mano_failai;
		#sleep 1;
		#sudo rm -rf /home/mokinys/Mano_failai
	#"
	
	set kelias [db3 eval {SELECT apl FROM pagrindiniai_aplankai WHERE koksapl='darbu_aplankas';}]
	exec mkdir -p $kelias/$::siandiena-$klase/$pavarde-$vardas-ID$mokid/
	p_send_command $nr "sudo chmod -R o+r /home/mokytoja/atsiskaitymai/"
	p_send_command $nr "sudo chmod a+rwx /home/mokinys/Atsiskaitymai"
	catch {exec -ignorestderr sh -c "scp -o ConnectTimeout=1 -r mokytoja@$pc:/home/mokytoja/atsiskaitymai/$klase/$::siandiena/* $kelias/$::siandiena-$klase/$pavarde-$vardas-ID$mokid/"}
	set ar_vyksta_atsiskaitymas [db3 onecolumn {SELECT atsiskaitymas FROM current_pc_setup WHERE pc_id=$pc_id}]
	if {$ar_vyksta_atsiskaitymas == 1} {
		p_send_command $nr $ats_pab_komandos1
		db3 eval "UPDATE current_pc_setup SET atsiskaitymas = 0 WHERE pc_id = $pc_id"
	}
	set ar_primountinta [db3 onecolumn {SELECT ar_primountinta FROM current_pc_setup WHERE pc_id=$pc_id}]
	if {$ar_primountinta == 1} {
		#p_send_command $nr $pam_pabaigos_komandos
		p_send_command $nr "sudo umount -l /home/mokinys/Mano_failai"
		db3 eval "UPDATE current_pc_setup SET ar_primountinta = 0 WHERE pc_id = $pc_id"
	}
	set ar_primountinta [db3 onecolumn {SELECT ar_primountinta FROM current_pc_setup WHERE pc_id=$pc_id}]
	if {$ar_primountinta == 0} {
		p_send_command $nr "sudo rm -rf /home/mokinys/Mano_failai"
	}
	set ar_vyksta_atsiskaitymas [db3 onecolumn {SELECT atsiskaitymas FROM current_pc_setup WHERE pc_id=$pc_id}]
	if {$ar_vyksta_atsiskaitymas == 0} {
		p_send_command $nr $ats_pab_komandos2	
	}
	p_icon_keitimas $nr pctabledone
	p_send_command $nr "sudo -u mokinys $display XAUTHORITY=/home/mokinys/.Xauthority /home/mokytoja/pranesimai/zinute_random.tcl \"Tavo darbas sėkmingai išsiųstas.\" \"Pranešimas\""
	p_tikrinti_ar_visi_baige atsiskaityma
}
#--------------------------------------------------------------------------------------------------------------------------------------
proc p_isvalyti_variantus {} {
	set visi_kompiuteriu_ip [db3 eval {SELECT pc FROM kompiuteriai}]
	foreach pc $visi_kompiuteriu_ip {
		set pc_id [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc}]
		set nr [expr $pc_id - 1]
		db3 eval "UPDATE current_pc_setup SET var = 0 WHERE pc_id = $pc_id"
		p_icon_keitimas $nr pcneutral
	}
}

proc p_isvalyti_veiksmus {} {
	p_ar_tikrai "Ar tikrai norite išvalyti įsimintus veiksmus?" "set ::testi 1"
	if {$::testi == 0} {
		return
	}
	set visi_kompiuteriu_ip [db3 eval {SELECT pc FROM kompiuteriai}]
	foreach pc_ip $visi_kompiuteriu_ip {
		set nr [expr [db3 eval {SELECT Id FROM kompiuteriai WHERE pc=$pc_ip}]-1]
		set pc_id [expr $nr + 1]
		db3 eval "UPDATE current_pc_setup SET mok_id = 0, ar_primountinta = 0, testo_id = 0, atsiskaitymas = 0, ar_alien = 0 WHERE pc_id = $pc_id"
		p_icon_keitimas $nr pcneutral
		.kompiuteriai.$nr configure -style pilkas.TLabel
	}
	tk_messageBox -message "Išvalyta." -parent .
}
#----------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------SITO DAR NETRINTI---------------------------------------------------
# wm protocol . WM_DELETE_WINDOW {
# 	set visi_ip_adresai [db3 eval {SELECT pc FROM kompiuteriai ORDER BY Id}]
# 	for {set nr 0} {$nr < [llength $visi_ip_adresai]} {incr nr} {
# 		chan close [set ::chan$nr]
# 	}
# }
#----------------------------------------------------------------------------------------------------------------------------------------------
proc p_klausimo_tipo_parinkimas {} {
#leidžia žmogui pasirinkti, koks klausimas bus pridedamas prie duomenų bazės
	set w .klausimu
	p_naujas_langas $w "Veiksmai su klausimais"
	set r 0
	grid [ttk::frame $w.tipai -padding "30 20 30 20" -style baltas.TFrame -relief groove] -column 0 -row $r -sticky news
	grid [ttk::label $w.tipai.sukurtilbl -text "SUKURTI KLAUSIMUS:" -style baltas.TLabel] -column 0 -row $r -pady 5 -columnspan 3; incr r
	grid [ttk::button $w.tipai.atviras -text "" -image textfield -command "destroy $w; p_atviro_klausimo_kurimas 0 0"] -column 0 -row $r -pady 1 -padx 10
	setTooltip $w.tipai.atviras "Atvirą, be variantų"
	grid [ttk::button $w.tipai.teisingas1 -text "" -image vienas -command "destroy $w; p_klausimo_su_variantais_kurimas 0 1 vienas_teisingas 0"] -column 1 -row $r -pady 1 -padx 10
	setTooltip $w.tipai.teisingas1 "Su 1 teisingu variantu"
	grid [ttk::button $w.tipai.teisingikeli -text "" -image keli -command "destroy $w; p_klausimo_su_variantais_kurimas 0 1 keli_teisingi 0"] -column 2 -row $r -pady 1 -padx 10; incr r
	setTooltip $w.tipai.teisingikeli "Su keliais teisingais variantais"
	grid [ttk::frame $w.redaguoti -padding "30 20 30 20"] -column 0 -row $r -sticky news
	grid [ttk::label $w.redaguoti.redaguotlbl -text "REDAGUOTI KLAUSIMUS:" -padding "30 0 0 0"] -column 0 -row $r -pady 5 -columnspan 3; incr r
	grid [ttk::button $w.redaguoti.salintredaguot -image check_icon -command "destroy $w; p_klausimu_perziura 0 0"] -column 1 -row $r -pady 5 -padx 15 -columnspan 3 -sticky w
	setTooltip $w.redaguoti.salintredaguot "Peržiūrėti/redaguoti"
}

proc p_atviro_klausimo_kurimas {tid klid} {
#sukuria/redaguoja atvirą klausimą
	set w .atviras
	p_naujas_langas $w "Atviras klausimas"
	wm protocol $w WM_DELETE_WINDOW {
		destroy .atviras
		set ::atgal 0
		set ::atv_klausimas ""
		set ::atv_atsakymas ""
	}
	set r 0
	set kltipas "atviras_kl"
	if {[info exists ::atgal] == 0} {
		set ::atv_klausimas ""
		set ::atv_atsakymas ""
	}
	if {$klid != 0} {
		set ::atv_klausimas [db3 onecolumn {SELECT kl FROM klausimai WHERE Id=$::pazymeto_klausimo_id}]
		set ::atv_atsakymas [lindex $::ats_variantai 0]
		set klid $::pazymeto_klausimo_id
		set ka_veikti "redaguoti"
		set grizimo_komanda "set ::atv_klausimas \"\"; set ::atv_atsakymas \"\"; destroy .atviras; p_klausimu_perziura $tid 0"
	} else {
		set ka_veikti "saugoti"
		set ::pav 0
		set grizimo_komanda "set ::atv_klausimas \"\"; set ::atv_atsakymas \"\"; destroy .atviras; p_klausimo_tipo_parinkimas"
	}
	if {$tid != 0} {
		incr r
		set testopavad [db3 eval {SELECT testo_pavad FROM testai WHERE Id=$tid}]
		grid [ttk::frame $w.kl -padding $::pad20] -column 0 -row $r -sticky news; incr r
		grid [ttk::label $w.kl.pavadinimas -text "Testas „$testopavad“" -padding "5 5"] -column 0 -row $r -pady 10 -sticky we; incr r
	}
	grid [ttk::frame $w.irasyk -padding $::pad20] -column 0 -row $r -sticky news; incr r
	grid [ttk::frame $w.pav -padding $::pad20 -relief groove -style baltas.TFrame] -column 0 -row $r -sticky news
	grid [ttk::label $w.irasyk.kllbl -text "KLAUSIMAS:"] -column 0 -row $r -padx 15 -sticky we; incr r
	grid [ttk::entry $w.irasyk.kl -textvariable ::atv_klausimas -width 50] -column 0 -row $r -pady 5 -padx 15 -sticky w; incr r
	focus $w.irasyk.kl
	grid [ttk::label $w.irasyk.atslbl -text "TEISINGAS ATSAKYMAS:"] -column 0 -row $r -padx 15 -sticky we; incr r
	grid [ttk::entry $w.irasyk.ats -textvariable ::atv_atsakymas -width 50] -column 0 -row $r -pady 5 -padx 15 -sticky w
	set paaiskinimas "Paveikslėlio formatas turi būti .png; Paveikslėlio dydis – ne didesnis nei 700x300!"
	if {$::pav==0} {
		set c 0
		grid [ttk::label $w.pav.pridetilbl -text "PRIDĖTI PAVEIKSLĖLĮ:" -style baltas.TLabel] -column $c -row $r -padx 5; incr c
		grid [ttk::button $w.pav.klpav -text "" -image pc_icon_small -command {set ::pav [p_pav_ikelimas_idb .atviras]; if {$::pav!=0} {p_pridejus_pav .atviras $r}}] -column $c -row $r -pady 5 -padx 5 -sticky w; incr c
		setTooltip $w.pav.klpav "Iš kompiuterio"
		grid [ttk::button $w.pav.gal -text "" -image gallery_icon -command "p_paveikslu_galerija .atviras $r"] -column $c -row $r -pady 5 -padx 5 -sticky w; incr c
		setTooltip $w.pav.gal "Iš galerijos"
		grid [ttk::button $w.pav.informacija -text "" -command "tk_messageBox -message \"$paaiskinimas\" -parent $w" -image klaus32] -column $c -row $r -pady 5 -padx 5; incr r
		setTooltip $w.pav.informacija "Informacija"
	} else {
		set c 0
		grid [ttk::label $w.pav.pridetilbl -text "PAŠALINTI PAVEIKSLĖLĮ:" -style baltas.TLabel] -column $c -row $r; incr c
		grid [ttk::button $w.pav.klpav -text "" -image rem32 -compound right -command "set ::pav 0; destroy $w.pav.rodopav $w.pav.miniat; p_pasalinus_pav $w $r"] -column $c -row $r -pady 5 -padx 5 -sticky w; incr r
		grid [ttk::label $w.pav.miniat -text "Paveikslėlis:" -style baltas.TLabel] -column 0 -row $r -padx 15 -sticky we; incr r
		set pav_prev [db3 onecolumn {SELECT content FROM paveiksleliai WHERE md5=$::pav}]
		image create photo p -data $pav_prev
		image create photo scaled
		scaled copy p -subsample 3
		grid [ttk::label $w.pav.rodopav -text "" -image scaled -compound left] -column 0 -row $r -padx 15 -sticky we; incr r
	}
	set komanda "p_ar_geras_klausimas $w $kltipas 0; if {\[ar_testi\]} {destroy .atviras; p_prideti_zymas_prie_kl $ka_veikti $klid $tid $kltipas \$::pav \$::atv_klausimas \$::atv_atsakymas 0}"
	grid [ttk::frame $w.mygtukai -padding "0 20 0 20"] -column 0 -row $r -sticky news -columnspan 4; incr r
	grid columnconfigure $w.mygtukai 0 -weight 1
	grid columnconfigure $w.mygtukai 1 -weight 1
	grid [ttk::button $w.mygtukai.atgal -text "< Atgal" -command $grizimo_komanda -style mazaszalias.TButton] -column 0 -row $r -padx 10 -pady 10 -sticky e
	grid [ttk::button $w.mygtukai.toliau -text "Toliau >" -command $komanda -style mazaszalias.TButton] -column 1 -row $r -pady 10 -padx 10 -sticky w
}

proc disable_all {w} {
    catch {$w configure -state disabled}
    foreach child [winfo children $w] {
        disable_all $child
    }
}

proc enable_all {w} {
    catch {$w configure -state normal}
    foreach child [winfo children $w] {
        enable_all $child
    }
}

proc p_prideti_zymas_prie_kl {ka_darom_su_kl klid tid kltipas pav klausimas atsakymas var_sk} {
	set ::parinktos_zymos ""
	set ::r 5
	set zymutipai [db3 eval {SELECT DISTINCT type FROM tagai}]
	set ::zyma [lindex $zymutipai 0]
	set ::zturinys ""
	set ::atgal 0
	set r 0
	if {$kltipas == "atviras_kl"} {
		set w .atviras
		set grizimo_komandos "destroy $w; set ::atgal 1; set ::parinktos_zymos \"\"; set ::zyma \"[lindex $zymutipai 0]\"; p_atviro_klausimo_kurimas $tid $klid"
	}
	if {$kltipas == "keli_teisingi" || $kltipas == "vienas_teisingas"} {
		set w .vienas
		set grizimo_komandos "destroy $w; set ::atgal 1; set ::parinktos_zymos \"\"; set ::zyma \"[lindex $zymutipai 0]\"; p_klausimo_su_variantais_kurimas $tid $var_sk $kltipas $klid"
	}
	p_naujas_langas $w "Žymų pasirinkimas"
	wm protocol $w WM_DELETE_WINDOW {
		destroy .vienas .atviras
		set ::parinktos_zymos ""
		if {[info exists zymutipai]} {
			set ::zyma [lindex $zymutipai 0]
		}
	}
	set irasymo_komandos "p_ar_pridetos_zymos $w \$::parinktos_zymos; if {\[ar_testi\]} {p_irasyti_klausima_ir_zymas_i_db $ka_darom_su_kl $w $klid $tid $kltipas $var_sk $pav \$::parinktos_zymos \"$klausimas\" \"$atsakymas\"}"
	#lango kairė pusė
	grid [ttk::frame $w.k] -column 0 -row $r -sticky news; incr r
	grid [ttk::label $w.k.zymalbl -text "PRIDĖTI ŽYMĄ:"] -column 0 -row $r -padx 10 -pady 5 -sticky w; incr r
	grid [ttk::frame $w.d] -column 1 -row 0 -sticky news
	grid [ttk::label $w.d.lala -text "PRIDĖTOS ŽYMOS:"] -column 1 -row 0 -padx 10 -pady 5 -sticky w
	grid [ttk::combobox $w.k.zymacombo -textvariable ::zyma -width 15] -column 0 -row $r -padx 10 -sticky w; incr r
	$w.k.zymacombo configure -values $zymutipai
	bind $w.k.zymacombo <<ComboboxSelected>> "p_atnaujinti_zymu_sarasa \$::zyma $w"
	grid [ttk::frame $w.zymosk -padding $::pad5] -column 0 -row 4 -sticky news
	#lango dešinė pusė
	grid [ttk::frame $w.zymosd -padding $::pad5] -column 1 -row 4 -sticky news
	set ::parinktos_zymos [db3 eval {SELECT tag_id FROM tagai_klausimai WHERE klausimo_id=$klid}]
	#jeigu jau buvo parinktos žymos, tai nupieš mygtukus. Jei ne, šis ciklas net nevyks.
	foreach tagid $::parinktos_zymos {
		set tagpavad [db3 onecolumn {SELECT name FROM tagai WHERE Id=$tagid}]
		set komanda "set idx \[lsearch \$::parinktos_zymos $tagid\]; set ::parinktos_zymos \[lreplace \$::parinktos_zymos \$idx \$idx\]; destroy $w.zymosd.parinktos$tagid; p_atnaujinti_zymu_sarasa \$::zyma $w"
		grid [ttk::button $w.zymosd.parinktos$tagid -text "$tagpavad" -image rem16 -compound right -command $komanda -style mazas.TButton] -column 0 -row $::r -padx 10 -pady 1; incr ::r
	}
	p_atnaujinti_zymu_sarasa $::zyma $w
	p_piesti_zymu_sarasa $w 3 0
	grid [ttk::frame $w.mygtukai -padding $::pad10] -column 0 -row $::r -sticky news -columnspan 2; incr r
	grid [ttk::button $w.mygtukai.irasyti -text "Įrašyti" -image save_icon -compound left -command $irasymo_komandos -style mazaszalias.TButton] -column 1 -row $r -padx 10 -pady 10
	grid [ttk::button $w.mygtukai.atgal -text "< Atgal" -command $grizimo_komandos -style mazaszalias.TButton -padding "0 14 0 14" -width 17] -column 0 -row $r -padx 10 -pady 10
}

proc p_pridejus_pav {w r} {
	$w.pav.pridetilbl configure -text "PAŠALINTI PAVEIKSLĖLĮ:"
	$w.pav.klpav configure -text "" -image rem32 -command "set ::pav 0; destroy $w.pav.rodopav $w.pav.miniat; p_pasalinus_pav $w $r"
	setTooltip $w.pav.klpav "Iš klausimo"
	destroy $w.pav.gal $w.pav.informacija
}

proc p_pasalinus_pav {w r} {
	$w.pav.pridetilbl configure -text "PRIDĖTI PAVEIKSLĖLĮ:"
	$w.pav.klpav configure -image pc_icon_small -text "" -command "set ::pav \[p_pav_ikelimas_idb $w\]; if {\$::pav!=0} {p_pridejus_pav $w $r}"
	setTooltip $w.pav.klpav "Iš kompiuterio"
	if {[winfo exists $w.pav.gal] != 1} {
		grid [ttk::button $w.pav.gal -text "" -image gallery_icon -command "p_paveikslu_galerija $w $r; tkwait window .galerija; if {\$::pav!=0} {p_pridejus_pav $w $r}"] -column 2 -row $r -pady 5 -padx 5 -sticky w
		setTooltip $w.pav.gal "Iš galerijos"
	}
	if {[winfo exists $w.pav.informacija] != 1} {
		set paaiskinimas "Paveikslėlio formatas turi būti .png; Paveikslėlio dydis – ne didesnis nei 700x300!"
		grid [ttk::button $w.pav.informacija -text "" -command "tk_messageBox -message \"$paaiskinimas\" -parent $w" -image klaus32] -column 3 -row $r -pady 5 -padx 5
		setTooltip $w.pav.informacija "Informacija"
	}
}

proc p_ar_geras_klausimas {w kltipas var_sk} {
	set visi_klausimai [db3 eval {SELECT kl FROM klausimai}]
	if {$kltipas == "atviras_kl"} {
		if {"[$w.irasyk.kl get]" == "" || "[$w.irasyk.ats get]" == ""} {
			tk_messageBox -message "Abu laukeliai turi būti užpildyti." -parent $w
			set ::testi 0
			return
		}
		foreach klausimas $visi_klausimai {
			if {$::atv_klausimas == $klausimas} {
				tk_messageBox -message "Vienodų klausimų būti negali. Pakeiskite ką nors klausimo formuluotėje." -parent $w
				set ::testi 0
				return
			}
		}
	}
	if {$kltipas == "vienas_teisingas" || $kltipas == "keli_teisingi"} {
		if {"[$w.irasyk.kl get]" == ""} {
			tk_messageBox -message "Klausimo laukelis turi būti užpildytas." -parent $w
			set ::testi 0
			return
		}
		for {set i 1} {$i <= $var_sk} {incr i} {
			if {"[$w.variantai.irasykkl$i get]" == ""} {
				tk_messageBox -message "Visi atsakymų laukeliai turi būti užpildyti." -parent $w
				set ::testi 0
				return
			}
		}
		foreach klausimas $visi_klausimai {
			if {$::vien_t_klausimas == $klausimas} {
				tk_messageBox -message "Vienodų klausimų būti negali. Pakeiskite ką nors klausimo formuluotėje." -parent $w
				set ::testi 0
				return
			}
		}
		for {set i 1} {$i <= $var_sk} {incr i} {	
			if {"[$w.variantai.irasykverte0$i get]" == "" || "[$w.variantai.irasykverte00$i get]" == ""} {
				tk_messageBox -message "Ne visiems atsakymų variantams priskirti taškai." -parent $w
				set ::testi 0
				return
			}
		}
		set teigiami_tsk 0
		for {set i 1} {$i <= $var_sk} {incr i} {
			set kiek_verta "[$w.variantai.irasykverte0$i get]"
			if {$kiek_verta > 0} {
				set teigiami_tsk [expr $kiek_verta+$teigiami_tsk]
			}
		}
		if {$teigiami_tsk != 1} {
			tk_messageBox -message "Teisingų atsakymų suma turi būti lygi 1." -parent $w
			set ::testi 0
			return
		}
	}
	if {$kltipas == "vienas_teisingas"} {
		if {![info exists ::arteisingas]} {
			tk_messageBox -message "Nepažymėtas teisingas atsakymas." -parent $w
			set ::testi 0
			return
		}
	}
	if {$kltipas == "keli_teisingi"} {
		for {set i 1} {$i <= $var_sk} {incr i} {
			if {![info exists ::arteisingas$i]} {
				set ::arteisingas$i 0
			}
			lappend variantai [set ::arteisingas$i]
		}
		if {[p_ladd $variantai] == 0} {
			tk_messageBox -message "Nepažymėti teisingi atsakymai." -parent $w
			set ::testi 0
			return
		}
	}
	set ::testi 1
}

proc p_piesti_zymu_sarasa {w r tid} {
	if {$w == ".perziura" || $w == ".perziura.z"} {
		p_atnaujinti_zymu_sarasa $::zyma_perziurai $w
	} else {
		p_atnaujinti_zymu_sarasa $::zyma $w
	}
	if {[winfo exists $w.zymosd] != 1} {
		grid [ttk::frame $w.zymosd -padding $::pad5] -column 1 -row $r -sticky news

	}
	if {[winfo exists $w.zymosk] != 1} {
		grid [ttk::frame $w.zymosk -padding $::pad5] -column 0 -row $r -sticky news
	}
	incr r
	if {$w == ".perziura" || $w == ".perziura.z"} {
		grid [tk::listbox $w.zymosk.l -yscrollcommand "$w.zymosk.ss set" -xscrollcommand "$w.zymosk.ssx set" -height 6 -width 19 -listvariable ::zturinys_perziurai -font "ubuntu 10" -selectbackground $::spalva] -column 0 -row $r -padx 2 -sticky news
	} else {
		grid [tk::listbox $w.zymosk.l -yscrollcommand "$w.zymosk.ss set" -xscrollcommand "$w.zymosk.ssx set" -height 6 -width 19 -listvariable ::zturinys -font "ubuntu 10" -selectbackground $::spalva] -column 0 -row $r -padx 2 -sticky news
	}
	grid [scrollbar $w.zymosk.ss -command "$w.zymosk.l yview" -orient vertical] -column 1 -row $r -sticky ns; incr r
	grid [scrollbar $w.zymosk.ssx -command "$w.zymosk.l xview" -orient horizontal] -column 0 -row $r -sticky we -padx 2; incr r
	if {$w == ".atviras"} {
		bind $w.zymosk.l <<ListboxSelect>> {set parinktas_taglist_elementas [p_kuri_zyma_pazymeta .atviras.zymosk.l]}
	}
	if {$w == ".vienas"} {
		bind $w.zymosk.l <<ListboxSelect>> {set parinktas_taglist_elementas [p_kuri_zyma_pazymeta .vienas.zymosk.l]}
	}
	if {$w == ".perziura.z"} {
		bind $w.zymosk.l <<ListboxSelect>> {set parinktas_taglist_elementas [p_kuri_zyma_pazymeta .perziura.z.zymosk.l]}
	}
	grid [ttk::button $w.zymosk.pridetiz -text "Pridėti žymą >" -command "p_parinktu_zymu_mygtuku_piesimas \$parinktas_taglist_elementas $tid $w \[$w.zymosk.l get \[$w.zymosk.l curselection\]\]" -style mazas.TButton] -column 0 -row $r
}

proc p_kuri_zyma_pazymeta {zymu_listbox} {
#aptinka, kuri zyma yra pazymeta iš zymu saraso
	set pazymetas_elementas [$zymu_listbox curselection]
	return $pazymetas_elementas
}

proc p_atnaujinti_zymu_sarasa {zymos_tipas w} {
#pakeicia, ka rodo listboxe pagal tai, kuris zymu tipas is triju tipu yra parinktas
	if {$w == ".perziura" || $w == ".perziura.z"} {
		set p $::selected_tags
	} else {
		set p $::parinktos_zymos
	}
	if {$p == "" && $w == ".perziura" || $w == ".perziura.z"} {
		set ::tagids [db3 eval {SELECT Id FROM tagai WHERE type=$zymos_tipas ORDER BY name}]
		set ::zturinys_perziurai [db3 eval {SELECT name FROM tagai WHERE type=$zymos_tipas ORDER BY name}]
	}
	if {$p == "" && $w != ".perziura" && $w != ".perziura.z"} {
		set ::tagids [db3 eval {SELECT Id FROM tagai WHERE type=$zymos_tipas ORDER BY name}]
		set ::zturinys [db3 eval {SELECT name FROM tagai WHERE type=$zymos_tipas ORDER BY name}]
	}
	if {$p != "" && $w == ".perziura" || $w == ".perziura.z"} {
		set parinktos [join $p ","]
		set ::tagids [db3 eval "SELECT Id FROM tagai WHERE type=\$zymos_tipas AND Id NOT IN ($parinktos) ORDER BY name"]
		set ::zturinys_perziurai [db3 eval "SELECT name FROM tagai WHERE type=\$zymos_tipas AND Id NOT IN ($parinktos) ORDER BY name"]
	}
	if {$p != "" && $w != ".perziura" || $w != ".perziura.z"} {
		set parinktos [join $p ","]
		set ::tagids [db3 eval "SELECT Id FROM tagai WHERE type=\$zymos_tipas AND Id NOT IN ($parinktos) ORDER BY name"]
		set ::zturinys [db3 eval "SELECT name FROM tagai WHERE type=\$zymos_tipas AND Id NOT IN ($parinktos) ORDER BY name"]
	}
}

proc p_parinktu_zymu_mygtuku_piesimas {parinktas_taglist_elementas tid w zymospavad} {
#nupiesia parinktu tagu mygtukus salia tagu listo
	if {$w != "perziura.z" && [info exists ::parinktos_zymos]} {
		foreach tagid $::parinktos_zymos {
			destroy $w.zymosd.parinktos$tagid
		}
	}
	set parinkti_tagai [db3 onecolumn {SELECT Id FROM tagai WHERE name=$zymospavad}]
	if {$w == ".perziura.z"} {
		lappend ::selected_tags $parinkti_tagai
		set p $::selected_tags
		p_atnaujinti_zymu_sarasa $::zyma_perziurai $w
		set ::klids [p_get_questions $tid "$::selected_tags"]
	} else {
		#klausimo kurimo metu:
		lappend ::parinktos_zymos $parinkti_tagai
		set p $::parinktos_zymos
		p_atnaujinti_zymu_sarasa $::zyma $w
		set ::klids [p_get_questions $tid "$::parinktos_zymos"]
	}
	set ::klausimai_is_duombazes [db3 eval "SELECT kl FROM klausimai WHERE Id IN ([join $::klids {,}])"]
	foreach tagid $p {
		set tagpavad [db3 onecolumn {SELECT name FROM tagai WHERE Id=$tagid}]
		if {$w == ".perziura.z"} {
			#testo klausimu pridejimo metu ar klausimu perziuros metu
			set komanda "set idx \[lsearch \$::selected_tags $tagid\]; set ::selected_tags \[lreplace \$::selected_tags \$idx \$idx\]; destroy $w.zymosd.parinktos$tagid; p_atnaujinti_zymu_sarasa \$::zyma_perziurai $w; set ::klids \[p_get_questions $tid \"\$::selected_tags\"\]; set ::klausimai_is_duombazes \[db3 eval \"SELECT kl FROM klausimai WHERE Id IN (\[join \$::klids {,}\])\"\]"
			if {[winfo exists $w.zymosd.parinktos$tagid] != 1} {
				grid [ttk::button $w.zymosd.parinktos$tagid -text "$tagpavad" -image rem16 -compound right -command $komanda -style mazas.TButton] -column 0 -row $::r -sticky w -pady 1; incr ::r
			}
		} else {
			#klausimo kurimo metu:
			grid [ttk::button $w.zymosd.parinktos$tagid -text "$tagpavad" -image rem16 -compound right -command "set idx \[lsearch \$::parinktos_zymos $tagid\]; set ::parinktos_zymos \[lreplace \$::parinktos_zymos \$idx \$idx\]; destroy $w.zymosd.parinktos$tagid; p_atnaujinti_zymu_sarasa \$::zyma $w" -style mazas.TButton] -column 0 -row $::r -padx 15 -pady 1 -sticky w; incr ::r
		}
	}
}

proc p_ar_pridetos_zymos {w parinktos_zymos} {
	if {$parinktos_zymos == ""} {
		set ar_egzistuoja_zymos [db3 eval {SELECT Id FROM tagai}]
		if {$ar_egzistuoja_zymos == ""} {
			tk_messageBox -message "Dar nėra sukurtos nė vienos žymos, pagal kurias būtų galima lengviau surasti klausimus. Dabar būsite perkeltas į žymų kūrimo langą." -parent $w
			p_tagu_kurimas
			tkwait window .tagai
			set ::testi 0
		} else {
			tk_messageBox -message "Pridėkite klausimui bent vieną žymą. Jos yra skirtos tam, kad testo kūrimo metu klausimą būtų lengviau surasti." -parent $w
			set ::testi 0
		}
	} else {
		set ::testi 1
	}
}

proc p_irasyti_klausima_ir_zymas_i_db {ka_darom_su_kl w klid tid kltipas var_sk pav parinkti_tagai klausimas atsakymas} {
	set naujas_klid [p_klausimo_irasymas_i_db $klid $kltipas $w $var_sk $pav $klausimas $atsakymas]
	foreach tagid $parinkti_tagai {
		db3 eval {DELETE FROM tagai_klausimai WHERE klausimo_id=$naujas_klid}
	}
	foreach tagid $parinkti_tagai {	
		db3 eval {INSERT INTO tagai_klausimai(tag_id, klausimo_id) VALUES($tagid, $naujas_klid)}
	}
	set ::parinktos_zymos ""
	set ::selected_tags ""
	set ::zturinys ""
	set ::atv_klausimas ""
	if {$w == ".perziura"} {
		p_atnaujinti_klausimu_sarasa .perziura $tid n
	}
	destroy $w
}

proc p_klausimo_su_variantais_kurimas {tid variantusk kltipas klid} {
#sukuria/redaguoja klausimą su variantais (teisingas gali būti arba vienas variantas, arba keli)
	set w .vienas
	p_naujas_langas $w "Klausimas su variantais"
	wm protocol $w WM_DELETE_WINDOW {
		destroy .vienas
		p_isvalyti_laukelius $variantusk
	}
	set r 0
	if {[info exists ::atgal] == 0} {
		set ::vien_t_klausimas ""
	}
	if {$klid != 0} {
		set ka_veikti "redaguoti"
		set ::vien_t_klausimas [db3 onecolumn {SELECT kl FROM klausimai WHERE Id=$::pazymeto_klausimo_id}]
		set i 1
		foreach el $::ats_variantai {
			set ::variantas$i $el
			set ::verte0$i [db3 onecolumn {SELECT tsk_jei_pasirinko FROM atsakymuvariantai WHERE atsakymo_var=$el AND klausimo_id=$klid}]
			set ::verte00$i [db3 onecolumn {SELECT tsk_jei_nepasirinko FROM atsakymuvariantai WHERE atsakymo_var=$el AND klausimo_id=$klid}]
			incr i
		}
		set klid $::pazymeto_klausimo_id
		if {$kltipas == "keli_teisingi"} {
			set j 1
			foreach el $::ar_teisingi_var {
				set ::arteisingas$j $el
				incr j
			}
		} else {
			set ::arteisingas 1
			foreach el $::ar_teisingi_var {
				if {$el == 1} {
					break
				}
				incr ::arteisingas
			}
		}
	} else {
		set ka_veikti "saugoti"
		set ::pav 0
		for {set i 1} {$i <= 10} {incr i} {
			set ::verte0$i 0
			set ::verte00$i 0
		}
	}
	set vertes "1 0.5 0.25 0 -0.25 -0.5 -1"
	if {$tid != "0"} {
		set testopavad [db3 eval {SELECT testo_pavad FROM testai WHERE Id=$tid}]
		grid [ttk::frame $w.kl -padding $::pad20] -column 0 -row $r -sticky news; incr r
		grid [ttk::label $w.kl.pavadinimas -text "TESTAS „$testopavad“" -padding "5 5"] -column 0 -row $r -pady 10 -sticky we -columnspan 2; incr r
	}
	grid [ttk::frame $w.irasyk -padding $::pad10] -column 0 -row $r -sticky news; incr r
	
	grid [ttk::label $w.irasyk.kllbl -text "KLAUSIMAS:"] -column 0 -row $r -pady 2 -sticky w; incr r
	grid [ttk::entry $w.irasyk.kl -textvariable ::vien_t_klausimas -width 60] -column 0 -row $r -pady 2 -sticky we -columnspan 2; incr r
	focus $w.irasyk.kl
	p_variantu_piesimas $w 1 $variantusk $kltipas $vertes 0
	grid [ttk::frame $w.pav -padding "10 10 10 10" -style baltas.TFrame -relief groove] -column 0 -row $r -sticky news
	set paaiskinimas "Paveikslėlio formatas turi būti .png; Paveikslėlio dydis – ne didesnis nei 700x300!"
	if {$::pav==0} {
		set c 0
		grid [ttk::label $w.pav.pridetilbl -text "PRIDĖTI PAVEIKSLĖLĮ:" -style baltas.TLabel] -column $c -row $r; incr c
		grid [ttk::button $w.pav.klpav -text "" -image pc_icon_small -command {set ::pav [p_pav_ikelimas_idb .vienas]; if {$::pav!=0} {p_pridejus_pav .vienas $r}}] -column $c -row $r -pady 5 -padx 5 -sticky w; incr c
		setTooltip $w.pav.klpav "Iš kompiuterio"
		grid [ttk::button $w.pav.gal -text "" -image gallery_icon -command {p_paveikslu_galerija .vienas $r}] -column $c -row $r -pady 5 -padx 5 -sticky w; incr c
		setTooltip $w.pav.gal "Iš galerijos"
		grid [ttk::button $w.pav.informacija -text "" -command "tk_messageBox -message \"$paaiskinimas\" -parent $w" -image klaus32] -column $c -row $r -pady 5 -padx 5; incr r
		setTooltip $w.pav.informacija "Informacija"
	} else {
		set c 0
		grid [ttk::label $w.pav.pridetilbl -text "PAŠALINTI PAVEIKSLĖLĮ:" -style baltas.TLabel] -column $c -row $r; incr c
		grid [ttk::button $w.pav.klpav -text "" -image rem32 -compound right -command "set ::pav 0; destroy $w.kl.rodopav $w.kl.miniat; p_pasalinus_pav $w $r" -style mazas.TButton] -column $c -row $r -pady 5 -padx 5 -sticky w; incr r
		grid [ttk::label $w.pav.miniat -text "Paveikslėlis:" -style baltas.TLabel] -column 0 -row $r -padx 15 -sticky we; incr r
		set pav_prev [db3 onecolumn {SELECT content FROM paveiksleliai WHERE md5=$::pav}]
		image create photo p -data $pav_prev
		image create photo scaled
		scaled copy p -subsample 3
		grid [ttk::label $w.pav.rodopav -text "" -image scaled -compound left] -column 0 -row $r -padx 15 -sticky we; incr r
	}
	set komanda "set variantusk \$::sk; p_ar_geras_klausimas $w $kltipas \$::sk; if {\[ar_testi\]} {p_gauti_atsakymu_variantus $w \$::sk; destroy .vienas; p_prideti_zymas_prie_kl $ka_veikti $klid $tid $kltipas  \$::pav \$::vien_t_klausimas \"\" \$::sk}"
	grid [ttk::frame $w.mygtukas -padding "0 20 0 20"] -column 0 -row $r -sticky news -columnspan 5; incr r
#šitų columnconfigure reikia tam, kad mygtukai nebūtų prie krašto, o būtų išdėlioti gražiai per vidurį. Kiek yra šitame frame stulpelių, tiek reikia columnconfigure eilučių parašyti su stulpelių numeriais. Weight visada bus 1.
	grid columnconfigure $w.mygtukas 0 -weight 1
	grid columnconfigure $w.mygtukas 1 -weight 1
	if {$klid == 0} {
		grid [ttk::button $w.mygtukas.atgal -text "< Atgal" -command "destroy .vienas; p_klausimo_tipo_parinkimas" -style mazaszalias.TButton] -column 0 -row $r -padx 10 -pady 10 -sticky e
	}
	grid [ttk::button $w.mygtukas.prideti -text "Toliau >" -command $komanda -style mazaszalias.TButton] -column 1 -row $r -sticky w
}

proc p_variantu_piesimas {w r variantusk kltipas vertes ar_nuspaude_plius} {
	if {$ar_nuspaude_plius == 1} {
		incr variantusk
	}
	if {$ar_nuspaude_plius == -1} {
		set variantusk [expr $variantusk-1]
	}
	destroy $w.variantai
	grid [ttk::frame $w.variantai] -column 0 -row $r -sticky news; incr r
	grid [ttk::label $w.variantai.irasyk1 -text "ATSAKYMŲ VARIANTAI:"] -column 0 -row $r -padx 10 -pady 5 -sticky w
	grid [ttk::label $w.variantai.arteisingas -text "AR TEISINGAS:"] -column 1 -row $r -sticky w -padx 10
	grid [ttk::label $w.variantai.tskjeipasirinko -text "Vertė taškais, \njei pasirinko:"] -column 2 -row $r -padx 10 -pady 5
	grid [ttk::label $w.variantai.tskjeinepasirinko -text "Vertė taškais, \njei nepasirinko:"] -column 3 -row $r -padx 10 -pady 5; incr r
	for {set i 1} {$i <= $variantusk} {incr i} {
		if {![info exists ::verte0$i]} {
			set ::verte0$i 0
		}
		if {![info exists ::verte00$i]} {
			set ::verte00$i 0
		}
		if {$kltipas == "keli_teisingi"} {
			if {![info exists ::arteisingas$i]} {
				set ::arteisingas$i 0
			}
			grid [ttk::checkbutton $w.variantai.$i -text "" -variable ::arteisingas$i -onvalue 1 -offvalue 0] -column 1 -row $r -padx 10
		} else {
			if {![info exists ::arteisingas]} {
				set ::arteisingas 0
			}
			grid [ttk::radiobutton $w.variantai.$i -text "" -variable ::arteisingas -value "$i"] -column 1 -row $r -padx 10
		}
		grid [ttk::combobox $w.variantai.irasykverte0$i -textvariable ::verte0$i -width 10] -column 2 -row $r -padx 10
		$w.variantai.irasykverte0$i configure -values $vertes
		grid [ttk::combobox $w.variantai.irasykverte00$i -textvariable ::verte00$i -width 10] -column 3 -row $r -padx 10
		$w.variantai.irasykverte00$i configure -values $vertes
		grid [ttk::entry $w.variantai.irasykkl$i -textvariable ::variantas$i -width 40] -column 0 -row $r -pady 1 -padx 10 -sticky w; incr r
	}
	grid [ttk::button $w.variantai.plusats -text "" -image ad16 -command "p_variantu_piesimas $w 1 $variantusk $kltipas \"$vertes\" 1" -style permatomas.TButton] -column 0 -row $r -pady 3 -padx 10 -sticky w
	grid [ttk::button $w.variantai.naikinti -text "" -image rem16 -command "p_variantu_piesimas $w 1 $variantusk $kltipas \"$vertes\" -1" -style permatomas.TButton] -column 0 -row $r
	grid [ttk::button $w.variantai.taskuspriskirt -text "Automatiškai priskirti taškus" -command "p_auto_taskai $variantusk $kltipas" -style mazas.TButton] -column 2 -row $r -columnspan 2; incr r
	if {$ar_nuspaude_plius == 1 || $ar_nuspaude_plius == -1} {
		grid $w.variantai.plusats -column 0 -row $r -pady 3 -padx 10 -sticky w
		grid $w.variantai.naikinti -column 0 -row $r -pady 3 -padx 10
		grid $w.variantai.taskuspriskirt -column 2 -row $r
		grid $w.variantai.plusats -column 0 -row $r -pady 3 -columnspan 4; incr r
	}
	set ::sk $variantusk
}

proc p_gauti_atsakymu_variantus {w var_sk} {
	set ::atsakymu_variantai ""
	set ::sarasas_jei_pasirinko ""
	set ::sarasas_jei_nepasirinko ""
	for {set i 1} {$i <= $var_sk} {incr i} {
		set atsvar "[$w.variantai.irasykkl$i get]"
		set jeipasirinko "[$w.variantai.irasykverte0$i get]"
		set jeinepasirinko "[$w.variantai.irasykverte00$i get]"
		lappend ::atsakymu_variantai $atsvar
		lappend ::sarasas_jei_pasirinko $jeipasirinko
		lappend ::sarasas_jei_nepasirinko $jeinepasirinko
	}
}

proc p_auto_taskai {variantusk kltipas} {
	if {$kltipas != "keli_teisingi"} {
		for {set i 1} {$i <= $variantusk} {incr i} {
			if {$::arteisingas == $i} {
				set ::verte0$i 1
			} else {
				set ::verte0$i 0
			}
		}
		return
	}
	set num_correct 0
	for {set i 1} {$i <= $variantusk} {incr i} {
		if {[set ::arteisingas$i]} {
			incr num_correct
		}
	}
	set taskai [expr 1.0/$num_correct]
	set neig_taskai [expr -1.0/($variantusk - $num_correct)]
	for {set i 1} {$i <= $variantusk} {incr i} {
		if {[set ::arteisingas$i]} {
			set ::verte0$i $taskai
		} else {
			set ::verte0$i $neig_taskai
		}
	}
}

proc p_pav_ikelimas_idb {w} {
#paveiksleliu ikelimas i duombaze
	set failas [lindex [p_prideti_faila 1 $w] 0]
	if {$failas == ""} {
		return 0
	}
	set fileID [open $failas RDONLY]
	fconfigure $fileID -translation binary
	set content [read $fileID]
	image create photo p -data $content
	set h [image height p]
	set wi [image width p]
	if {$wi > 700 || $h > 300} {
		tk_messageBox -message "Paveikslėlis per didelis." -parent $w
		close $fileID
		return 0
	}
	close $fileID
	set pavadinimas [file tail $failas]
	set md5_ir_failas [exec -ignorestderr md5sum $failas]
	set md5 [lindex $md5_ir_failas 0]
	set ar_yra_paveikslelis [db3 eval {SELECT Id FROM paveiksleliai WHERE md5=$md5 AND pavad=$pavadinimas}]
	if {$ar_yra_paveikslelis == ""} {
		db3 eval {INSERT INTO paveiksleliai(pavad, content, md5) VALUES ($pavadinimas, $content, $md5)}
	} else {
		tk_messageBox -message "Paveikslėlis tokiu pavadinimu jau yra. Jei norite naudoti naująjį paveikslėlį, pervadinkite jį kitu pavadinimu arba pasirinkite paveikslėlį iš galerijos." -parent $w
		return 0
	}
	image create photo scaled
	scaled copy p -subsample 3
	image create photo p -data $content
	if {[winfo exists $w.pav.miniat] != 1} {
		grid [ttk::label $w.pav.miniat -text ""] -column 0 -row 7 -padx 5 -sticky we
	}
	if {[winfo exists $w.pav.rodopav] != 1} {
		grid [ttk::label $w.pav.rodopav -text ""] -column 0 -row 7 -padx 5 -sticky we
	}
	$w.pav.miniat configure -text "Paveikslėlis:"
	$w.pav.rodopav configure -image scaled -compound left
	return $md5
}

proc p_paveikslu_galerija {koks_kl r_is_kl} {
#atidaro paveikslėlių galeriją
	if {$koks_kl == "joks"} {
		set koks_kl .n
	}
	set visu_pav_ids [db3 eval {SELECT Id FROM paveiksleliai ORDER BY pavad}]
	if {$visu_pav_ids == ""} {
		tk_messageBox -message "Galerijoje dar nėra paveikslėlių. Paveikslėliai yra pridedami sukuriant klausimus ir pridedant prie jų paveikslėlius iš kompiuterio." -parent $koks_kl
		return
	}
	p_pav_piesimas $visu_pav_ids 0 1 $koks_kl $r_is_kl
}

proc p_pav_piesimas {visu_pav_ids i r koks_kl r_is_kl} {
#nupiešia paveikslėlių galerijos langą, paieškos laukelį ir apatinius mygtukus
	set ::galerijos_komandos ""
	set w .galerija
	p_naujas_langas $w "Paveikslėlių galerija"
	wm protocol .galerija WM_DELETE_WINDOW {
		destroy .galerija
		set i 0
		if {[info exists ::pavsearch]} {
			unset ::pavsearch
		}
		if {[info exists ::galerijos_komandos]} {
			unset ::galerijos_komandos
		}
	}
	grid [ttk::frame $w.f -padding $::pad20] -column 0 -row $r -sticky news; incr r
	grid columnconfigure $w.f 0 -weight 1
	grid columnconfigure $w.f 1 -weight 1
	grid [ttk::label $w.f.paieskalbl -text "IEŠKOTI PAGAL PAVADINIMĄ:" -style mazas.TLabel] -column 0 -row $r -pady 5 -padx 5 -columnspan 2; incr r
	grid [ttk::entry $w.f.paieska -textvariable ::pavsearch -width 20] -column 0 -row $r -pady 10 -padx 10 -sticky e
	focus $w.f.paieska
	#1 – parodo kad galerijoje ieškant paveiksliukų rodytų patį pirmą paveiksliuką.
	grid [ttk::button $w.f.paieskabtn -text "IEŠKOTI" -command "set ::pavsearch; p_paveikslo_rodymas_galerijoje $w \"$visu_pav_ids\" 1 4 $koks_kl $r_is_kl" -style mazas.TButton] -column 1 -row $r -padx 10 -pady 10 -sticky w; incr r
	p_paveikslo_rodymas_galerijoje $w $visu_pav_ids $i $r $koks_kl $r_is_kl
	set r 6
	if {$koks_kl == ".atviras" || $koks_kl == ".vienas"} {
		grid [ttk::frame $w.m -padding "0 0 0 20"] -column 0 -row $r -sticky news; incr r
		grid columnconfigure $w.m 0 -weight 1
		grid columnconfigure $w.m 1 -weight 1
		#eval yra naudojamas tam, kad vykdytų kintamojo ::galerijos_komandos kodą, net kai tas kodas pasikeičia. Jei eval nebūtų, tai būtų vykdomas kodas, kuris niekada nekinta.
		grid [ttk::button $w.m.prideti -text "Pridėti" -image ad16 -compound left -command "eval \$::galerijos_komandos" -style mazas.TButton -width 15] -column 0 -row $r -pady 10 -padx 5 -sticky e
		grid [ttk::button $w.m.atgal -text "Atsisakyti" -image rem16 -compound left -command "destroy $w; if {\[info exists ::pavsearch\]} {unset ::pavsearch}; set i 0" -style mazaszalias.TButton -width 15] -column 1 -row $r -sticky w; incr r
	}
}

proc p_paveikslo_rodymas_galerijoje {w visu_pav_ids i r koks_kl r_is_kl} {
#nupiešia paveikslėlį ir rodo jį galerijoje kartu su mygtukais pirmyn ir atgal
	if {![info exists ::pavsearch]} {
		set pav_id [lindex $visu_pav_ids $i]
		set md5 [db3 onecolumn {SELECT md5 FROM paveiksleliai WHERE Id=$pav_id}]
	} else {
		set pav_id [db3 onecolumn {SELECT Id FROM paveiksleliai WHERE pavad=$::pavsearch}]
		set md5 [db3 onecolumn {SELECT md5 FROM paveiksleliai WHERE Id=$pav_id}]
		if {$pav_id == ""} {
			tk_messageBox -message "Paveikslėlio tokiu pavadinimu nėra.\nIeškant reikia įvesti pilną paveikslėlio pavadinimą su prievardžiu." -parent $w
			unset ::pavsearch
			set i 0
			set pav_id [lindex $visu_pav_ids $i]
		}
	}
	destroy $w.p
	set pav_prev [db3 onecolumn {SELECT content FROM paveiksleliai WHERE Id=$pav_id}]
	set pav_pavad [db3 onecolumn {SELECT pavad FROM paveiksleliai WHERE Id=$pav_id}]
	image create photo p -data $pav_prev
	image create photo scaled
	scaled copy p -subsample 3
	grid [ttk::frame $w.p -padding $::pad20] -column 0 -row $r -sticky news; incr r
	grid columnconfigure $w.p 0 -weight 1
	grid columnconfigure $w.p 1 -weight 1
	grid columnconfigure $w.p 2 -weight 1
	grid [ttk::label $w.p.rodo -image p -compound left -text ""] -column 1 -row $r -padx 10
	grid [ttk::button $w.p.kitas -text ">" -command "p_paveikslo_rodymas_galerijoje $w \"$visu_pav_ids\" [expr $i+1] 4 $koks_kl $r_is_kl" -style mazaszalias.TButton -width 4] -column 2 -row $r -padx 10 -pady 10 -rowspan 2
	$w.p.kitas configure -state disabled
	grid [ttk::button $w.p.ankstesnis -text "<" -command "p_paveikslo_rodymas_galerijoje $w \"$visu_pav_ids\" [expr $i-1] 4 $koks_kl $r_is_kl" -style mazaszalias.TButton -width 4] -column 0 -row $r -padx 10 -pady 10 -rowspan 2
	$w.p.ankstesnis configure -state disabled
	incr r
	if {$i <[expr [llength $visu_pav_ids]-1] && ![info exists ::pavsearch]} {
		$w.p.kitas configure -state normal
	}
	if {$i > 0 && ![info exists ::pavsearch]} {
		$w.p.ankstesnis configure -state normal
	}
	grid [ttk::label $w.p.pavpavad -text "$pav_pavad" -style mazas.TLabel] -column 1 -row $r -padx 10
	set ::galerijos_komandos "p_pav_miniaturos_laukeliu_piesimas $koks_kl $r_is_kl; destroy $w; set ::pav $md5; $koks_kl.pav.rodopav configure -image scaled -compound left; $koks_kl.pav.miniat configure -text \"Paveikslėlis:\""
}

proc p_pav_miniaturos_laukeliu_piesimas {koks_kl r_is_kl} {
	if {[winfo exists $koks_kl.pav.miniat] != 1 && $koks_kl != ".n"} {
		grid [ttk::label $koks_kl.pav.miniat -text "" -style baltas.TLabel] -column 0 -row [expr $r_is_kl + 2] -padx 5 -sticky we
	}
	if {[winfo exists $koks_kl.pav.rodopav] != 1 && $koks_kl != ".n"} {
		grid [ttk::label $koks_kl.pav.rodopav -text "" -style baltas.TLabel] -column 0 -row [expr $r_is_kl + 2] -padx 5 -sticky we
	}
	p_pridejus_pav $koks_kl $r_is_kl
}

proc p_klausimo_irasymas_i_db {klid tipas w var_sk pav klausimas atsakymas} {
#įrašo naujai sukurtą/paredaguotą klausimą į klausimų duomenų bazę
	set pav_id [db3 onecolumn {SELECT Id FROM paveiksleliai WHERE md5=$pav}]
	if {$tipas == "atviras_kl"} {
		if {$klid != 0} {
			db3 eval {UPDATE klausimai SET kl=$klausimas, pav_id=$pav_id WHERE Id=$klid}
			db3 eval {UPDATE atsakymuvariantai SET atsakymo_var=$atsakymas WHERE klausimo_id=$klid AND ar_teisingas_var=1}
		} else {
			db3 eval {INSERT INTO klausimai(kl, tipas, pav_id) VALUES($klausimas, $tipas, $pav_id)}
			set naujas_klid [db3 onecolumn {SELECT last_insert_rowid()}]
			db3 eval {INSERT INTO atsakymuvariantai(klausimo_id, atsakymo_var, ar_teisingas_var) VALUES($naujas_klid, $atsakymas, 1)}
			db3 eval {INSERT INTO atsakymuvariantai(klausimo_id, ar_teisingas_var) VALUES($naujas_klid, 0)}
		}
	}
	if {$tipas == "vienas_teisingas" || $tipas == "keli_teisingi"} {
		set atsvarids [db3 eval {SELECT Id FROM atsakymuvariantai WHERE klausimo_id=$klid}]
		if {$klid == 0} {
			db3 eval {INSERT INTO klausimai(kl, tipas, pav_id) VALUES($klausimas, $tipas, $pav_id)}
			set naujas_klid [db3 onecolumn {SELECT last_insert_rowid()}]
			set l 0
			for {set i 1} {$i <= $var_sk} {incr i} {
				set atsvar [lindex $::atsakymu_variantai $l]
				set jeipasirinko [lindex $::sarasas_jei_pasirinko $l]
				set jeinepasirinko [lindex $::sarasas_jei_nepasirinko $l]
				incr l
				if {$tipas == "vienas_teisingas"} {
					set arteisingas [expr $::arteisingas == $i]
				} else {
					if {![info exists ::arteisingas$i]} {
						set ::arteisingas$i 0
					}
					set arteisingas [set ::arteisingas$i]
				}
				db3 eval {INSERT INTO atsakymuvariantai(klausimo_id, atsakymo_var, ar_teisingas_var, tsk_jei_pasirinko, tsk_jei_nepasirinko) 
					VALUES($naujas_klid, $atsvar, $arteisingas, $jeipasirinko, $jeinepasirinko)}
			}
		}
		if {$klid != 0} {
			db3 eval {UPDATE klausimai SET kl=$klausimas, pav_id=$pav_id WHERE Id = $klid}
			set i 1
			set l 0
			foreach el $atsvarids {
				set atsvar [lindex $::atsakymu_variantai $l]
				set jeipasirinko [lindex $::sarasas_jei_pasirinko $l]
				set jeinepasirinko [lindex $::sarasas_jei_nepasirinko $l]
				incr l
				if {$tipas == "vienas_teisingas"} {
					set arteisingas [expr $::arteisingas == $i]
				} else {
					if {![info exists ::arteisingas$i]} {
						set ::arteisingas$i 0
					}
					set arteisingas [set ::arteisingas$i]
				}
				db3 eval {UPDATE atsakymuvariantai SET atsakymo_var=$atsvar WHERE Id=$el}
				db3 eval {UPDATE atsakymuvariantai SET ar_teisingas_var=$arteisingas WHERE Id=$el}
				db3 eval {UPDATE atsakymuvariantai SET tsk_jei_pasirinko=$jeipasirinko WHERE Id=$el}
				db3 eval {UPDATE atsakymuvariantai SET tsk_jei_nepasirinko=$jeinepasirinko WHERE Id=$el}
				incr i
			}
		} 
		p_isvalyti_laukelius $var_sk
	}
	if {$klid == 0} {
		return $naujas_klid
	} else {
		return $klid
	}
}
	
proc p_isvalyti_laukelius {var_sk} {
#išvalo laukelius iš klausimų kūrimo
	for {set i 1} {$i <= $var_sk} {incr i} {
		if {[info exists ::arteisingas$i]} {
			unset ::arteisingas$i
		}
		if {[info exists ::verte0$i]} {
			unset ::verte0$i
		}
		if {[info exists ::verte00$i]} {
			unset ::verte00$i
		}
		if {[info exists ::variantas$i]} {
			unset ::variantas$i
		}
	}
	if {[info exists ::arteisingas]} {
		unset ::arteisingas
	}
	if {[info exists ::atsakymu_variantai]} {
		unset ::atsakymu_variantai
	}
	if {[info exists ::sarasas_jei_pasirinko]} {
		unset ::sarasas_jei_pasirinko
	}
	if {[info exists ::sarasas_jei_nepasirinko]} {
		unset ::sarasas_jei_nepasirinko
	}
	set ::vien_t_klausimas ""
	set ::atv_klausimas ""
	set ::atv_atsakymas ""
	set ::atgal 0
}
#----------------------------------------------------------------------------------------------------------------
proc p_testo_kurimo_pradzia {ar_kursim_nauja} {
#sukuria arba redaguoja testą arba apklausą
	set ::apkl_pavadinimas ""
	if {$ar_kursim_nauja == 1} {
		set zodis "kūrimas"
	}
	if {$ar_kursim_nauja == 0} {
		set zodis "redagavimas"
	}
	set w .testu
	p_naujas_langas $w "Testo $zodis"
	set r 0
	set testo_klases [db3 eval {SELECT klase FROM destomos_klases ORDER BY klase ASC}]
	set ::testoklase ""
	grid [ttk::frame $w.k -padding "30 20 30 20"] -column 0 -row 1 -sticky news -columnspan 2
	grid [ttk::frame $w.f -style baltas.TFrame -relief groove -padding "30 20 30 20"] -column 0 -row 0 -sticky news -columnspan 2
	if {$ar_kursim_nauja == 1} {
		grid [ttk::label $w.f.paaiskinimas -text "TESTO PAVADINIMAS:" -style baltas.TLabel -padding "20 0 20 0"] -column 0 -row $r -pady 5 -padx 10 -sticky we; incr r
		grid [ttk::entry $w.f.iveskpav -textvariable ::apkl_pavadinimas -validate key -validatecommand {p_replace_spaces %W %S %i %d} -width 20] -column 0 -row $r -pady 5 -padx 1 -columnspan 2; incr r
		focus $w.f.iveskpav
		grid [ttk::label $w.k.klase -text "KLASĖ:" -padding "20 0 0 0"] -column 0 -row $r -pady 5 -padx 10 -sticky w
		grid [ttk::combobox $w.k.klasecombo -textvariable ::testoklase -width 7] -column 1 -row $r -padx 5 -sticky w; incr r
		$w.k.klasecombo configure -values $testo_klases
		grid [ttk::button $w.k.toliau -text "Toliau >" -command "p_naujo_testo_pavadinimo_sukurimas \$::apkl_pavadinimas \$::testoklase $w; if {\[ar_testi\]} {destroy .testu; p_klausimu_perziura 0 1; destroy $w}" -style mazaszalias.TButton] -column 0 -row $r -pady 15 -padx 25 -columnspan 4 -sticky e
	} else {
		grid [ttk::label $w.f.klase -text "FILTRUOTI PAGAL KLASĘ:" -style baltas.TLabel -padding "0 10 0 10"] -column 0 -row $r -pady 5
		grid [ttk::combobox $w.f.klasecombo -textvariable ::testoklase -width 7] -column 1 -row $r -sticky w -padx 5; incr r
		$w.f.klasecombo configure -values $testo_klases
		bind $w.f.klasecombo <<ComboboxSelected>> "p_perpiesti_testus $w"
		grid [ttk::label $w.k.rinktistesta -text "TESTAI/APKLAUSOS:"] -column 0 -row $r -pady 5; incr r
		set ::testu_sarasas [db3 eval {SELECT testo_pavad FROM testai ORDER BY testo_pavad}]
		grid [tk::listbox $w.k.l -yscrollcommand "$w.k.s set" -height 8 -width 30 -listvariable $::testu_sarasas -selectbackground $::spalva] -column 0 -row $r -sticky news
		grid [scrollbar $w.k.s -command "$w.k.l yview" -orient vertical] -column 1 -row $r -sticky ns; incr r
		grid rowconfigure $w.k.s 0 -weight 1
		grid columnconfigure $w.k.s 0 -weight 1
		$w.k.l delete 0 end
		for {set a 0} {$a<[llength $::testu_sarasas]} {incr a} {
			$w.k.l insert end "[lindex $::testu_sarasas $a]"
		}
		grid [ttk::button $w.k.redaguot -text "Redaguoti" -image ed32 -compound left -command "set tid \[p_pazymeti_testa\]; p_ar_pazymetas_testas $w \$tid; if {\[ar_testi\]} {destroy .testu; p_klausimu_perziura \$tid 1; destroy $w}" -width 13 -style mazaszalias.TButton] -column 0 -row $r -pady 6 -columnspan 2; incr r
		grid [ttk::button $w.k.salint -text "Pašalinti" -image rem32 -compound left -command "set tid \[p_pazymeti_testa\]; p_ar_pazymetas_testas $w \$tid; if {\[ar_testi\]} {p_ar_tikrai {Ar tikrai pašalinti pažymėtą testą?} {p_pasalinti_testa_is_db \$tid $w}; destroy .testu; p_testo_kurimo_pradzia $ar_kursim_nauja}" -width 13 -style mazaszalias.TButton] -column 0 -row $r -pady 5 -columnspan 2
	}
}

proc p_perpiesti_testus {w} {
	set ::testu_sarasas [db3 eval {SELECT testo_pavad FROM testai WHERE klase=$::testoklase ORDER BY testo_pavad}]
	$w.k.l delete 0 end
	for {set a 0} {$a<[llength $::testu_sarasas]} {incr a} {
		$w.k.l insert end "[lindex $::testu_sarasas $a]"
	}
}

proc p_ar_pazymetas_testas {w tid} {
	if {$tid == ""} {
		tk_messageBox -message "Nepasirinktas testas." -parent $w
		set ::testi 0
	} else {
		set ::testi 1
	}
}

proc p_pazymeti_testa {} {
#aptinka, kuris testas/apklausa yra pažymėta
	set pazymetas_elementas [.testu.k.l curselection]
	set pazymeta_apklausa [lindex $::testu_sarasas $pazymetas_elementas]
	set tid [db3 eval {SELECT Id FROM testai WHERE testo_pavad=$pazymeta_apklausa}]
	return $tid
}

proc p_pasalinti_testa_is_db {tid w} {
#pašalina pasirinktą testą/apklausą iš duomenu bazes
	set ar_jau_sprestas [db3 onecolumn {SELECT Id FROM bandymai WHERE testo_id=$tid}]
	if {$ar_jau_sprestas == ""} {
		db3 eval {DELETE FROM klausimai_testai WHERE testo_id=$tid}
		db3 eval {DELETE FROM testai WHERE Id=$tid}
	} else {
		tk_messageBox -message "Šio testo pašalinti negalima, nes jį mokinys(-iai) jau sprendė." -parent $w
	}
}
	
proc p_naujo_testo_pavadinimo_sukurimas {pavadinimas testo_klase w} {
#prideda naują testą į lentelę testai
	if {$pavadinimas == ""} {
		tk_messageBox -message "Neįvestas testo pavadinimas." -parent $w
		set ::testi 0
		return
	}
	if {$testo_klase == ""} {
		set ar_ivestos_destomos_klases [db3 eval {SELECT Id FROM destomos_klases}]
		if {$ar_ivestos_destomos_klases == ""} {
			tk_messageBox -message "Nėra parinktos klasės, kurioms dėstote. Būsite perkeltas į langą, kuriame tai reikės atlikti." -parent $w
			p_mokytojo
			tkwait window .intervalas
			set ::testi 0
			destroy $w
			p_testo_kurimo_pradzia 1
			return
		} else {
			tk_messageBox -message "Neparinkta klasė." -parent $w
			set ::testi 0
			return
		}
	}
	set tid [db3 eval {SELECT Id FROM testai WHERE testo_pavad=$pavadinimas}]
	if {$tid != ""} {
		tk_messageBox -message "Testas pavadinimu „$pavadinimas“ jau yra.\nĮveskite kitą pavadinimą." -parent $w
		set ::testi 0
	} else {
		db3 eval {INSERT INTO testai(testo_pavad, klase) VALUES($pavadinimas, $testo_klase)}
		set ::testi 1
	}
}

proc p_pervadinti_testadb {tid klase} {
	db3 eval {UPDATE testai SET testo_pavad=$::test_name WHERE Id=$tid}
	db3 eval {UPDATE testai SET klase=$klase WHERE Id=$tid}
}

proc p_tikrinti_arivesti_taskai {w tid} {
	set taskai [db3 eval {SELECT verte_taskais FROM klausimai_testai WHERE testo_id=$tid}]
	set klausimu_sk [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$tid}]
	if {$taskai == ""} {
		set taskai_suvesti 0
	} else {
		foreach t $taskai {
			if {$t == ""} {
				set taskai_suvesti 0
				break
			} else {
				set taskai_suvesti 1
			}
		}
	}
	if {$taskai_suvesti == 1 && $klausimu_sk != ""} {
		destroy $w
	}
	if {$klausimu_sk == ""} {
		tk_messageBox -message "Testas/apklausa privalo turėti bent vieną klausimą." -parent $w
		return
	}
	if {$taskai_suvesti != 1} {
		tk_messageBox -message "Kiekvienas klausimas privalo turėti taškų vertę." -parent $w
		return
	}
}

proc p_get_questions {test_id tag_ids} {
	set test_part [expr $test_id == 0 ? {{}} : {"WHERE k.Id NOT IN (SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$test_id)"}]
	set tag_count [llength $tag_ids]
	set tags [join $tag_ids ","]
	set sum_part "CASE WHEN t.tag_id IN ($tags) THEN 1 ELSE 0 END"
	return [db3 eval "SELECT k.Id FROM klausimai k LEFT JOIN tagai_klausimai t ON k.Id=klausimo_id $test_part GROUP BY k.Id HAVING SUM($sum_part) = $tag_count ORDER BY k.Id"]
}

proc p_klausimu_perziura {tid ar_desim_itesta} {
#prieš leidžiant žmogui peržiūrėti klausimus, patikrina, ar klausimai iš viso egzistuoja duomenų bazėje arba pasirinktame teste/apklausoje
	if {$tid == 0} {
		set visi_klausimai [db3 eval {SELECT kl FROM klausimai ORDER BY Id}]
		if {$visi_klausimai == ""} {
			tk_messageBox -message "Dar nėra sukurta klausimų." -parent .n
			return
		} else {
			p_visu_klausimu_piesimas $tid $ar_desim_itesta
		}
	} else {
		p_visu_klausimu_piesimas $tid $ar_desim_itesta
	}
}

proc p_visu_klausimu_piesimas {tid ar_desim_itesta} {
#rodo visus klausimus, esančius klausimų duomenų bazėje arba pasirinktame teste/apklausoje bei gali įkelti klausimus į pasirinktą testą
	if {[info exists ::klausimai_is_duombazes]} {
		unset ::klausimai_is_duombazes
	}
	if {[info exists ::klids]} {
		unset ::klids
	}
	if {$tid == ""} {
		set tid [db3 onecolumn {SELECT Id FROM testai WHERE testo_pavad=$::apkl_pavadinimas}]
	}
	set ::pazymeto_klausimo_id ""
	set naujo_testo_id ""
	set kl_tipai [db3 eval {SELECT tipas FROM klausimai ORDER BY Id}]
	set r 1
	set c 0
	destroy .perziura .vienas .atviras
	set langas ".perziura"
	p_naujas_langas $langas "Klausimų peržiūra"
	wm protocol $langas WM_DELETE_WINDOW {
		destroy .perziura
		set ::selected_tags ""
		set zymutipai [db3 eval {SELECT DISTINCT type FROM tagai}]
		set ::zyma_perziurai [lindex $zymutipai 0]
	}
	set ::selected_tags ""
	set zymutipai [db3 eval {SELECT DISTINCT type FROM tagai}]
	set ::zyma_perziurai [lindex $zymutipai 0]
	set ::zturinys_perziurai ""
	p_atnaujinti_zymu_sarasa $::zyma_perziurai $langas
	set ::klids [p_get_questions $tid ""]
	set ::klausimai_is_duombazes [db3 eval "SELECT kl FROM klausimai WHERE Id IN ([join $::klids {,}])"]
	if {$ar_desim_itesta == 1} {
		grid [ttk::frame $langas.balta_juosta -style baltas.TFrame -relief groove -padding "5 10 5 10"] -column 0 -row $r -sticky news
		grid [ttk::frame $langas.balta_juosta.top_section -padding "350 0 0 0" -style baltas.TFrame] -column 0 -row $r; incr r
		grid columnconfigure $langas.balta_juosta.top_section 0 -weight 1
		grid columnconfigure $langas.balta_juosta.top_section 1 -weight 1
		grid columnconfigure $langas.balta_juosta.top_section 2 -weight 1
		grid columnconfigure $langas.balta_juosta.top_section 3 -weight 1
		if {$tid == 0} {
			set naujo_testo_id [db3 onecolumn {SELECT MAX(Id) FROM testai}]
			set tid $naujo_testo_id
		}
		set ::klase [db3 onecolumn {SELECT klase FROM testai WHERE Id=$tid}]
		set klases_testui [db3 eval {SELECT klase FROM destomos_klases ORDER BY klase ASC}]
		set ::test_name [db3 onecolumn {SELECT testo_pavad FROM testai WHERE Id=$tid}]
		grid [ttk::label $langas.balta_juosta.top_section.testas -text "TESTAS" -style baltas.TLabel] -column 0 -row $r -padx 5
		grid [ttk::combobox $langas.balta_juosta.top_section.klase -textvariable ::klase -width 4] -column 1 -row $r -padx 5
		$langas.balta_juosta.top_section.klase configure -values $klases_testui
		grid [ttk::label $langas.balta_juosta.top_section.klasei -text "klasei:" -style baltas.TLabel] -column 2 -row $r -padx 5
		grid [ttk::entry $langas.balta_juosta.top_section.test_name -textvariable ::test_name -validate key -validatecommand {p_replace_spaces %W %S %i %d} -width 20] -padx 5 -pady 5 -column 3 -row $r -padx 5
	}
	grid [ttk::frame $langas.z] -column 0 -row $r -sticky nwes -columnspan 5
	grid [ttk::label $langas.z.zymalbl -text "FILTRUOTI KLAUSIMUS:"] -column 0 -row $r -padx 10 -sticky w
	grid [ttk::label $langas.z.parinktos -text "PASIRINKTI FILTRAI:"] -column 1 -row $r -pady 5 -padx 10 -sticky w; incr r
	grid [ttk::combobox $langas.z.zymacombo -textvariable ::zyma_perziurai -width 15] -column 0 -row $r -padx 10 -sticky w; incr r
	$langas.z.zymacombo configure -values $zymutipai
	p_piesti_zymu_sarasa $langas.z $r $tid
	bind $langas.z.zymacombo <<ComboboxSelected>> "p_atnaujinti_zymu_sarasa \$::zyma_perziurai $langas"
	incr r
	grid [ttk::frame $langas.kl -style baltas.TFrame -relief groove -padding "5 5 5 5"] -column 0 -row $r -sticky nwes
	grid [ttk::label $langas.kl.visi -text "VISI KLAUSIMAI:" -padding "5 5" -style baltas.TLabel] -column 0 -row $r -pady 10; incr r
	grid [tk::listbox $langas.kl.l -yscrollcommand "$langas.kl.ss set" -xscrollcommand "$langas.kl.ssx set" -height 20 -width 53 -listvariable ::klausimai_is_duombazes -font "ubuntu 10" -selectbackground $::spalva] -column $c -row $r -padx 2 -sticky news
	$langas.kl.l delete 0 end
	grid [scrollbar $langas.kl.ss -command "$langas.kl.l yview" -orient vertical] -column 1 -row $r -sticky ns; incr r
	grid [scrollbar $langas.kl.ssx -command "$langas.kl.l xview" -orient horizontal] -column 0 -row $r -sticky we; incr r

	set a 1
	foreach klid $::klids {
		set kl [db3 onecolumn {SELECT kl FROM klausimai WHERE Id=$klid}]
		$langas.kl.l insert end "$kl"
		incr a
	}
	if {$ar_desim_itesta == 1} {
		set c 3
		set r 5
		set ::testo_klids [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$tid ORDER BY klausimo_nr ASC}]
		set ::klausimai ""
		set ::decs ""
		set ::incs ""
		set ::values ""
		foreach el $::testo_klids {
			lappend ::klausimai [db3 eval {SELECT kl, tipas FROM klausimai WHERE Id=$el}]
			lappend ::decs " -"
			lappend ::incs " +"
			lappend ::values [db3 onecolumn {SELECT verte_taskais FROM klausimai_testai WHERE testo_id = $tid AND klausimo_id = $el}]
		}
		grid [ttk::label $langas.kl.tsk -text "TŠK:" -style baltas.TLabel] -column [expr $c+1] -row $r -padx 2 -sticky nswe
		grid [ttk::label $langas.kl.pavad -text "TESTO KLAUSIMAI:" -padding "50 0 0 0" -style baltas.TLabel] -column $c -row $r -columnspan 5; incr r
		grid [tk::listbox $langas.kl.dec -yscrollcommand yset -height 5 -width 2 -listvariable ::decs -font "ubuntu 10" -selectmode single -foreground "red"] -column $c -row $r -padx 2 -sticky news; incr c
		grid [tk::listbox $langas.kl.value -yscrollcommand yset -height 5 -width 4 -listvariable ::values -font "ubuntu 10" -selectmode single -state disabled] -column $c -row $r -padx 2 -sticky news; incr c
		grid [tk::listbox $langas.kl.inc -yscrollcommand yset -height 5 -width 2 -listvariable ::incs -font "ubuntu 10" -selectmode single -foreground "green"] -column $c -row $r -padx 2 -sticky news; incr c
		bind $langas.kl.dec <<ListboxSelect>> "update_value $tid $langas.kl.dec -0.5 $ar_desim_itesta"
		bind $langas.kl.inc <<ListboxSelect>> "update_value $tid $langas.kl.inc 0.5 $ar_desim_itesta"

		grid [tk::listbox $langas.kl.li -yscrollcommand yset -xscrollcommand "$langas.kl.sx set" -height 5 -width 53 -listvariable $::klausimai -font "ubuntu 10" -selectmode single -selectbackground $::spalva] -column $c -row $r -padx 2 -sticky news
		bind $langas.kl.li <Key> "if {{%K} == {Up}} {renumber_questions $tid .perziura.kl.li -1 $ar_desim_itesta} elseif {{%K} == {Down}} {renumber_questions $tid .perziura.kl.li 1 $ar_desim_itesta}"
		$langas.kl.li delete 0 end
		grid [scrollbar $langas.kl.s -command yview -orient vertical] -column [expr $c+1] -row $r -sticky ns; incr r
		grid [scrollbar $langas.kl.sx -command "$langas.kl.li xview" -orient horizontal] -column 6 -row $r -sticky we; incr r
	}
	if {$ar_desim_itesta == 1 && $::klausimai != ""} {
		for {set a 0} {$a < [llength $::testo_klids]} {incr a} {
			$langas.kl.li insert end "[expr $a+1]. [lindex [lindex $::klausimai $a] 0]"
		}
	}
	if {$ar_desim_itesta == 1 && $::klausimai == ""} {
		$langas.kl.li insert end ""
	}
	if {$ar_desim_itesta == 1} {
		bind $langas.kl.li <<ListboxSelect>> {set testo_klausimo_id [p_kuris_testo_kl_pazymetas ".perziura.kl.li"]}
	} 
	bind $langas.kl.l <<ListboxSelect>> {set pazymeto_klausimo_id [p_kuris_klausimas_pazymetas ".perziura.kl.l"]}
	if {$ar_desim_itesta == 1} {
		set ar_jau_sprestas [db3 onecolumn {SELECT Id FROM bandymai WHERE testo_id=$tid}]
		if {$ar_jau_sprestas == ""} {
			set busena "normal"
		} else {
			set busena "disabled"
			tk_messageBox -message "Kadangi šį testą mokiniai jau sprendė, klausimų pridėti ar ištrinti nebegalima." -parent .perziura
		}
		set r 6
		grid [ttk::button $langas.kl.prideti -text "" -image arrow_r -command "p_prideti_klausima $tid plius $langas \$pazymeto_klausimo_id; p_atnaujinti_klausimu_sarasa $langas $tid $ar_desim_itesta" -state $busena] -column 2 -row $r -pady 10 -padx 10 -sticky n
		grid [ttk::button $langas.kl.salint -text "" -image arrow_l -command "p_ar_tikrai {Ar tikrai pašalinti klausimą iš testo?} {p_pasalinti_pazymeta_kl $tid $langas \$testo_klausimo_id; p_atnaujinti_klausimu_sarasa $langas $tid $ar_desim_itesta}" -state $busena] -column 2 -row $r -pady 10 -padx 10 -sticky s; incr r; incr r
	}
	grid [ttk::frame $langas.mygtukai -padding $::pad5] -column 0 -row $r -sticky news;
	grid columnconfigure $langas.mygtukai 0 -weight 1
	if {$tid == 0} {
		#čia vyksta, kai yra peržiūrimi/redaguojami klausimai
		grid columnconfigure $langas.mygtukai 1 -weight 1
		# XXX this works by magic, if it does work (seems to work! wth?!), must be corrected to normal code!!! XXX @todo
		grid [ttk::button $langas.mygtukai.redag -text "Redaguoti" -image ed32 -compound left -command "destroy $langas; p_redaguoti_pazymeta_kl $tid \$pazymeto_klausimo_id" -style mazaszalias.TButton] -column 0 -row 0 -pady 10 -padx 10 -sticky e
		grid [ttk::button $langas.mygtukai.atgal -text "Atsisakyti" -image rem32 -compound left -command "set ::selected_tags \"\"; set ::zyma_perziurai \"\"; destroy $langas; p_klausimo_tipo_parinkimas" -style mazaszalias.TButton] -column 1 -row 0 -pady 10 -padx 10 -sticky w
	} else {
		#čia vyksta, kai saugojame/redaguojame testą
		#mygtukas išsaugoja tik testo pavadinimą; visi kiti pakeitimai yra įvykdomi „gyvai“.
		grid [ttk::button $langas.mygtukai.saugoti -text "Išsaugoti" -image save_icon -compound left -command "p_tikrinti_arivesti_taskai $langas $tid; p_pervadinti_testadb $tid \$::klase" -style mazaszalias.TButton] -column 0 -row $r -pady 10
	}
}

proc renumber_questions {tid box change ar_desim_itesta} {
	set current_number [$box curselection]
	set top_element [expr round([lindex [$box yview] 0] * [$box size])]
	set questions [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$tid ORDER BY klausimo_nr ASC}]
	set range "[expr min($current_number, $current_number + $change)] [expr max($current_number, $current_number + $change)]"
	lassign [lrange $questions {*}$range] first second
	set questions [lreplace $questions {*}$range $second $first]
	set i 1
	set sql {}
	foreach qid $questions {
		lappend sql "UPDATE klausimai_testai SET klausimo_nr = $i WHERE testo_id = $tid AND klausimo_id = $qid"
		incr i
	}
	db3 eval [join $sql {;}]
	p_atnaujinti_klausimu_sarasa .perziura $tid $ar_desim_itesta
	$box selection set [expr $current_number + $change]
	yview [lindex $top_element 0]
}

proc update_value {tid box change ar_desim_itesta} {
	set top_element [expr round([lindex [$box yview] 0] * [$box size])]
	set selected [$box curselection]
	#as there are two boxes, and event triggers even on deselect, this gets executed for both (increment and decrement boxes)
	#when user first has clicked in one, and then in another (first one loses select, triggers with empty selection, second one triggers normally)
	if {$selected == ""}  {
		return
	}
	puts [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$tid ORDER BY klausimo_nr ASC}] 
	set question_id [lindex [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$tid ORDER BY klausimo_nr ASC}] $selected]
	db3 eval "UPDATE klausimai_testai SET verte_taskais = CASE WHEN verte_taskais IS NULL THEN $change ELSE verte_taskais + \($change\) END WHERE testo_id=$tid AND klausimo_id = $question_id"
	p_atnaujinti_klausimu_sarasa .perziura $tid $ar_desim_itesta
	yview [lindex $top_element 0]
}

proc yset {args}  {
	eval [linsert $args 0 .perziura.kl.s set]
	yview moveto [lindex [.perziura.kl.s get] 0]
}
proc yview {args}  {
	eval [linsert $args 0 .perziura.kl.dec yview]
	eval [linsert $args 0 .perziura.kl.value yview]
	eval [linsert $args 0 .perziura.kl.inc yview]
	eval [linsert $args 0 .perziura.kl.li yview]
}

proc p_atnaujinti_klausimu_sarasa {w tid ar_desim_itesta} {
	set ::klids [p_get_questions $tid "$::selected_tags"]
	set ::klausimai_is_duombazes [db3 eval "SELECT kl FROM klausimai WHERE Id IN ([join $::klids {,}])"]
	$w.kl.l delete 0 end
	set a 1
	foreach klid $::klids {
		set kl [db3 onecolumn {SELECT kl FROM klausimai WHERE Id=$klid}]
		$w.kl.l insert end "$kl"
		incr a
	}
	if {$ar_desim_itesta == 1} {
		p_atnaujinti_testo_kl_sarasa $w $tid
	}
}

proc p_atnaujinti_testo_kl_sarasa {w tid} {
	set ::testo_klids [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$tid ORDER BY klausimo_nr ASC}]
	set ::klausimai ""
	set ::decs ""
	set ::incs ""
	set ::values ""
	foreach el $::testo_klids {
		lappend ::klausimai [db3 eval {SELECT kl, tipas FROM klausimai WHERE Id=$el}]
		lappend ::decs "-"
		lappend ::incs "+"
		lappend ::values [db3 onecolumn {SELECT verte_taskais FROM klausimai_testai WHERE testo_id = $tid AND klausimo_id = $el}]
	}

	$w.kl.li delete 0 end
	for {set a 0} {$a < [llength $::testo_klids]} {incr a} {
		$w.kl.li insert end "[expr $a+1]. [lindex [lindex $::klausimai $a] 0]"
	}
}

proc p_kuris_klausimas_pazymetas {klausimu_listbox} {
#aptinka, kuris klausimas yra pažymėtas iš klausimų sąrašo
	set pazymetas_elementas [$klausimu_listbox curselection]
	return [lindex $::klids $pazymetas_elementas]
}

proc p_kuris_testo_kl_pazymetas {testo_klausimu_listbox} {
#aptinka, kuris klausimas yra pažymėtas iš testo klausimų sąrašo
	set pazymetas_elementas [$testo_klausimu_listbox curselection]
	return [lindex $::testo_klids $pazymetas_elementas]
}
        
proc p_pasalinti_pazymeta_kl {tid w testo_klausimo_id} {
#pašalina pažymėtą klausimą iš testo
	if {$testo_klausimo_id == ""} {
		tk_messageBox -message "Nepažymėtas klausimas." -parent $w
		return
	}
	db3 eval {DELETE FROM klausimai_testai WHERE klausimo_id=$testo_klausimo_id AND testo_id=$tid}
	p_prideti_klausima $tid minus $w $testo_klausimo_id
}
	
proc p_redaguoti_pazymeta_kl {tid pazymeto_klausimo_id} {
	set pazymetas_tipas [db3 onecolumn {SELECT tipas FROM klausimai WHERE Id=$pazymeto_klausimo_id}]
	set ::ats_variantai [db3 eval {SELECT atsakymo_var FROM atsakymuvariantai WHERE klausimo_id=$pazymeto_klausimo_id ORDER BY Id}]
	set ::ar_teisingi_var [db3 eval {SELECT ar_teisingas_var FROM atsakymuvariantai WHERE klausimo_id=$pazymeto_klausimo_id ORDER BY Id}] 
	set var_kiekis [llength $::ats_variantai]
	set ::pav [db3 onecolumn {SELECT md5 FROM paveiksleliai JOIN klausimai ON klausimai.pav_id=paveiksleliai.Id WHERE klausimai.Id=$pazymeto_klausimo_id}]
	if {$::pav == ""} {
		set ::pav 0
	}
	if {$pazymetas_tipas == "atviras_kl"} {
		p_atviro_klausimo_kurimas $tid $pazymeto_klausimo_id
	}
	if {$pazymetas_tipas == "vienas_teisingas"} {
		p_klausimo_su_variantais_kurimas $tid $var_kiekis vienas_teisingas $pazymeto_klausimo_id
	}
	if {$pazymetas_tipas == "keli_teisingi"} {
		p_klausimo_su_variantais_kurimas $tid $var_kiekis keli_teisingi $pazymeto_klausimo_id
	}
}

proc p_prideti_klausima {tid arprideti w pazymeto_klausimo_id} {
#prideda klausimą iš klausimų duomenų bazės į pasirinktą testą
	if {$pazymeto_klausimo_id == ""} {
		tk_messageBox -message "Nepažymėtas klausimas." -parent $w
		return
	}
	if {$arprideti == "plius"} {
		db3 eval {INSERT INTO klausimai_testai(testo_id, klausimo_id) VALUES($tid, $pazymeto_klausimo_id)}
	}
	set visi_testo_klausimai [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$tid}]
	for {set i 0} {$i<=[llength $visi_testo_klausimai]} {incr i} {
		set klid [lindex $visi_testo_klausimai $i]
		set nr [expr $i+1]
		db3 eval {UPDATE klausimai_testai SET klausimo_nr=$nr WHERE testo_id=$tid AND klausimo_id=$klid}
	}
}

proc p_testinio_mok_ir_klases_sukurimas {} {
	set komp_sk [db3 eval {SELECT Id FROM kompiuteriai}]
	set ar_yra_klase [db3 eval {SELECT Id FROM klases WHERE klase="Testinė_klasė"}]
	if {$ar_yra_klase == ""} {
		db3 eval {INSERT INTO klases(klase) VALUES("Testinė_klasė")}
	}
	set ar_yra_mok [db3 eval {SELECT Id FROM mokiniai WHERE vardas="testinis"}]
	if {$ar_yra_mok == ""} {
		set klases_id [db3 eval {SELECT Id FROM klases WHERE klase="Testinė_klasė"}]
		foreach pc $komp_sk {
			db3 eval {INSERT INTO mokiniai(vardas, pavarde, klases_id, pc_id, esamas_ar_buves) VALUES("testinis", $pc, $klases_id, $pc, 1)}
		}
	}
}

proc p_testo_testavimo_zinute {} {
	tk_messageBox -message "Norėdami patestuoti savo testą, pasirinkite testinę klasę iš klasių sąrašo ir paleiskite testą pažymėtiems kompiuteriams. Testavimas nuo tikro testo skiriasi tuo, kad testavimo metu gautus testinių mokinių atsakymus bus galima ištrinti." -parent .n
}
#----------------------------------------------------------------------------------------------------------------------------
proc p_tikrinti_testus {} {
#leidzia pasirinkti, kuri testa tikrinsime, ar perziuresime jau istaisytus testus.
	set ar_yra_sprendimu [db3 eval {SELECT Id FROM bandymai}]
	if {$ar_yra_sprendimu == ""} {
		tk_messageBox -message "Dar nėra išspręstas nė vienas testas ar apklausa." -parent .n
		return
	}
	set ::rodyti_sprendima 0
	destroy .taisymas
	set w .taisymas
	p_naujas_langas $w "Testų apžvalga"
	wm protocol .taisymas WM_DELETE_WINDOW {
		destroy .taisymas
		if {[info exists ::pazymetas_testas]} {
			unset ::pazymetas_testas
		}
	}
	set r 0
	grid [ttk::frame $w.data -padding $::pad10 -relief groove -style baltas.TFrame] -column 0 -row $r -sticky news; incr r
	grid [ttk::frame $w.f -padding $::pad10] -column 0 -row $r -sticky news
	set metai [db3 eval {SELECT "" UNION SELECT DISTINCT STRFTIME('%Y', data) AS year FROM bandymai}]
	set menuo [db3 eval {SELECT "" UNION SELECT DISTINCT STRFTIME('%m', data) AS month FROM bandymai}]
	set diena [db3 eval {SELECT "" UNION SELECT DISTINCT STRFTIME('%d', data) AS day FROM bandymai}]
	set ::metai [db3 eval {SELECT MAX(STRFTIME('%Y', data)) AS year FROM bandymai}]
	set ::menuo ""
	set ::diena ""
	grid [ttk::label $w.data.lbl -text "FILTRUOTI PAGAL DATĄ:" -style baltas.TLabel] -column 0 -row $r -pady 5 -padx 40 -rowspan 2
	grid [ttk::label $w.data.lblm -text "Metai:" -style baltas.TLabel] -column 1 -row $r -pady 5 -padx 10
	grid [ttk::label $w.data.lblmen -text "Mėnuo:" -style baltas.TLabel] -column 2 -row $r -pady 5 -padx 10
	grid [ttk::label $w.data.lbld -text "Diena:" -style baltas.TLabel] -column 3 -row $r -pady 5 -padx 10
	incr r
	grid [ttk::combobox $w.data.metai -textvariable ::metai -width 5] -column 1 -row $r -padx 1
	$w.data.metai configure -values $metai
	bind $w.data.metai <<ComboboxSelected>> "p_piesti_testus_tikrinimui \"\$::metai\" \"\$::menuo\" \"\$::diena\" $w"
	grid [ttk::combobox $w.data.menuo -textvariable ::menuo -width 5] -column 2 -row $r -padx 1
	$w.data.menuo configure -values $menuo
	bind $w.data.menuo <<ComboboxSelected>> "p_piesti_testus_tikrinimui \"\$::metai\" \"\$::menuo\" \"\$::diena\" $w"
	grid [ttk::combobox $w.data.diena -textvariable ::diena -width 5] -column 3 -row $r -padx 1
	$w.data.diena configure -values $diena
	bind $w.data.diena <<ComboboxSelected>> "p_piesti_testus_tikrinimui \"\$::metai\" \"\$::menuo\" \"\$::diena\" $w"
	grid [ttk::label $w.f.lbl1 -text "NEIŠTAISYTI TESTAI:"] -column 0 -row $r -pady 3 -padx 10
	grid [ttk::label $w.f.lbl2 -text "IŠTAISYTI TESTAI:"] -column 2 -row $r -pady 3 -padx 10
	grid [ttk::label $w.f.lbl3 -text "APKLAUSOS:"] -column 4 -row $r -pady 3 -padx 10; incr r
	grid [tk::listbox $w.f.lst -yscrollcommand "$w.f.scrl set" -height 12 -width 30 -font "ubuntu 10" -activestyle none -selectbackground $::spalva] -column 0 -row $r -sticky news -pady 10
	grid [scrollbar $w.f.scrl -command "$w.f.lst yview" -orient vertical] -column 1 -row $r -sticky ns -pady 10; incr r
	grid rowconfigure $w.f.scrl 0 -weight 1
	grid columnconfigure $w.f.scrl 0 -weight 1
	set ::lango_listbox1 "$w.f.lst"
	#bind $w.f.lst <<ListboxSelect>> p_pazymeti_neistaisyta_testa
	grid [ttk::button $w.f.tikrinti -text "Tikrinti testą" -image test_check_icon -compound right -command "p_tikrinti_pazymeta_testa \[get_selected_test_try_id $w\] ungraded" -style mazas.TButton -width 18] -column 0 -row $r -pady 1 -padx 1
	
	grid [tk::listbox $w.f.lsti -yscrollcommand "$w.f.scrli set" -height 12 -width 30 -font "ubuntu 10" -activestyle none -selectbackground $::spalva] -column 2 -row [expr $r-1] -sticky news -pady 10
	grid [scrollbar $w.f.scrli -command "$w.f.lsti yview" -orient vertical] -column 3 -row [expr $r-1] -sticky ns -pady 10
	grid rowconfigure $w.f.scrli 0 -weight 1
	grid columnconfigure $w.f.scrli 0 -weight 1
	set ::lango_listbox2 "$w.f.lsti"
	#bind $w.f.lsti <<ListboxSelect>> p_pazymeti_istaisyta_testa
	grid [ttk::button $w.f.tikrintiisnaujo -text "Dar kartą peržiūrėti" -image prev32 -compound right -command "p_tikrinti_pazymeta_testa \[get_selected_test_try_id $w\] graded" -style mazas.TButton -width 18] -column 2 -row $r -pady 1 -padx 1; incr r
	incr r
	grid [tk::listbox $w.f.alst -yscrollcommand "$w.f.ascrl set" -height 12 -width 30 -font "ubuntu 10" -activestyle none -selectbackground $::spalva] -column 4 -row [expr $r-3] -sticky news -pady 10
	grid [scrollbar $w.f.ascrl -command "$w.f.alst yview" -orient vertical] -column 5 -row [expr $r-3] -sticky ns -pady 10; incr r
	grid rowconfigure $w.f.ascrl 0 -weight 1
	grid columnconfigure $w.f.ascrl 0 -weight 1
	set ::lango_listbox3 "$w.f.alst"
	#bind $w.f.alst <<ListboxSelect>> p_pazymeti_apklausa
	grid [ttk::button $w.f.atikrinti -text "Peržiūrėti" -image prev32 -compound right -command "p_tikrinti_pazymeta_testa \[get_selected_test_try_id $w\] survey" -style mazas.TButton -width 18] -column 4 -row [expr $r-3] -pady 1 -padx 1
	p_piesti_testus_tikrinimui "$::metai" "$::menuo" "$::diena" $w
}

proc get_selected_test_try_id {w} {
	set selection [$w.f.lst curselection]
	set test_id 0
	if {$selection  != ""} {
		set test_id [lindex $::neistaisytu_testu_ids $selection]
		set try_id [db3 eval {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND pavadinimas="ar_pazymiui" AND reiksme=1 AND ar_istaisyta=0 LIMIT 1}]
	}
	set selection [$w.f.lsti curselection]
	if {$selection  != ""} {
		set test_id [lindex $::istaisytu_testu_ids $selection]
		set try_id [db3 eval {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND pavadinimas="ar_pazymiui" AND reiksme=1 AND ar_istaisyta=1 LIMIT 1}]
	}
	set selection [$w.f.alst curselection]
	if {$selection  != ""} {
		set test_id [lindex $::apklausos $selection]
		set try_id [db3 eval {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND pavadinimas="ar_pazymiui" AND reiksme=0 LIMIT 1}]
	}
	if {$try_id == 0 || $try_id == ""} {
		puts "NOT RIGHT!"
		return 0
	}
	#not funny! there has to be better way, some time in a future
	destroy $w
	return $try_id
}

proc p_piesti_testus_tikrinimui {metai menuo diena w} {
	$w.f.lst delete 0 end
	$w.f.lsti delete 0 end
	$w.f.alst delete 0 end
	set date_format ""
	set date ""
	if {$metai != ""} {
		set date_format "%Y"
		set date $metai
	}
	if {$menuo != ""} {
		set date_format "$date_format-%m"
		set date "$date-$menuo"
	}
	if {$diena != ""} {
		set date_format "$date_format-%d"
		set date "$date-$diena"
	}
	set date_cond ""
	if {$date != ""} {
		set date_cond " AND STRFTIME('$date_format', data) = '$date'"
	}
	set ::neistaisytu_testu_ids [db3 eval "SELECT DISTINCT testo_id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id AND pavadinimas='ar_pazymiui' AND reiksme=1 WHERE ar_istaisyta=0 $date_cond"]
	set ::istaisytu_testu_ids [db3 eval "SELECT DISTINCT testo_id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE pavadinimas='ar_pazymiui' AND reiksme=1 AND ar_istaisyta=1 $date_cond"]
	set ::apklausos [db3 eval "SELECT DISTINCT testo_id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE pavadinimas='ar_pazymiui' AND reiksme=0 $date_cond"]
	for {set a 0} {$a < [llength $::neistaisytu_testu_ids]} {incr a} {
		set ntst_id [lindex $::neistaisytu_testu_ids $a]
		set kiek_mokiniu_atliko_n [db3 eval "SELECT COUNT(*) FROM bandymai JOIN bandymai_options on bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$ntst_id AND ar_istaisyta=0 AND pavadinimas='ar_pazymiui' AND reiksme=1 $date_cond"]
		set ntst [db3 onecolumn {SELECT testo_pavad FROM testai WHERE Id=$ntst_id}]
		$w.f.lst insert end "$ntst (sprendimų: $kiek_mokiniu_atliko_n)"
	}
	for {set a 0} {$a < [llength $::istaisytu_testu_ids]} {incr a} {
		set itst_id [lindex $::istaisytu_testu_ids $a]
		set kiek_mokiniu_atliko_i [db3 eval "SELECT COUNT(*) FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$itst_id AND ar_istaisyta=1 AND pavadinimas='ar_pazymiui' AND reiksme=1 $date_cond"]
		set itst [db3 onecolumn {SELECT testo_pavad FROM testai WHERE Id=$itst_id}]
		$w.f.lsti insert end "$itst (sprendimų: $kiek_mokiniu_atliko_i)"
		
	}
	for {set a 0} {$a < [llength $::apklausos]} {incr a} {
		set ntst_id [lindex $::apklausos $a]
		set kiek_mokiniu_atliko_a [db3 eval "SELECT COUNT(*) FROM bandymai JOIN bandymai_options on bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$ntst_id AND pavadinimas='ar_pazymiui' AND reiksme=0 $date_cond"]
		set ntst [db3 onecolumn {SELECT testo_pavad FROM testai WHERE Id=$ntst_id}]
		$w.f.alst insert end "$ntst (sprendimų: $kiek_mokiniu_atliko_a)"
	}
}

proc p_ar_pazymetas_istaisytas_testas {w} {
	if {![info exists ::pazymetas_testas_i]} {
		tk_messageBox -message "Nepasirinktas testas." -parent $w
		set ::testi 0
	} else {
		set ::pazymetas_testas $::pazymetas_testas_i
		set ::testi 1
	}
}

proc p_ar_pazymetas_neistaisytas_testas {w} {
	if {![info exists ::pazymetas_testas_n]} {
		tk_messageBox -message "Nepasirinktas testas." -parent $w
		set ::testi 0
	} else {
		set ::pazymetas_testas $::pazymetas_testas_n
		set ::testi 1
	}
}

proc p_ar_pazymeta_apklausa {w} {
	if {![info exists ::pazymeta_apklausa]} {
		tk_messageBox -message "Nepasirinkta apklausa." -parent $w
		set ::testi 0
	} else {
		set ::pazymetas_testas $::pazymeta_apklausa
		set ::testi 1
	}
}

proc p_next_try_id {current_id test_id what} {
	if {$what == "graded"} {
		return [db3 eval {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND ar_istaisyta=1 AND pavadinimas="ar_pazymiui" AND reiksme=1 AND Id > $current_id ORDER BY Id ASC LIMIT 1}]
	} 
	if {$what == "ungraded"} {
		return [db3 eval {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND ar_istaisyta=0 AND pavadinimas="ar_pazymiui" AND reiksme=1 AND Id > $current_id ORDER BY Id ASC LIMIT 1}]
	}
	if {$what == "survey"} {
		return [db3 eval {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND pavadinimas="ar_pazymiui" AND reiksme=0 AND Id > $current_id ORDER BY Id ASC LIMIT 1}]
	}
}

proc p_previous_try_id {current_id test_id what} {
	if {$what == "graded"} {
		return [db3 eval {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND ar_istaisyta=1 AND pavadinimas="ar_pazymiui" AND reiksme=1 AND Id < $current_id ORDER BY Id DESC LIMIT 1}]
	}
	if {$what == "ungraded"} {
		return [db3 onecolumn {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND ar_istaisyta=0 AND pavadinimas="ar_pazymiui" AND reiksme=1 AND Id < $current_id ORDER BY Id DESC LIMIT 1}]
	}
	if {$what == "survey"} {
		return [db3 eval {SELECT Id FROM bandymai JOIN bandymai_options ON bandymai_options.bandymo_id=bandymai.Id WHERE testo_id=$test_id AND pavadinimas="ar_pazymiui" AND reiksme=0 AND Id < $current_id ORDER BY Id ASC LIMIT 1}]
	}
}

proc p_pazymeti_neistaisyta_testa {} {
	set ::pazymetas_el [$::lango_listbox1 curselection]
	set ::pazymetas_testas_n [lindex $::neistaisytu_testu_ids $::pazymetas_el]
}

proc p_pazymeti_istaisyta_testa {} {
	set ::pazymetas_el [$::lango_listbox2 curselection]
	set ::pazymetas_testas_i [lindex $::istaisytu_testu_ids $::pazymetas_el]
}

proc p_pazymeti_apklausa {} {
	set ::pazymetas_el [$::lango_listbox3 curselection]
	set ::pazymeta_apklausa [lindex $::apklausos $::pazymetas_el]
}

proc p_pakeisti_testuids_statistikai {w r parinktaklase metai} {
	set testu_ids ""
	set testai $::testai_statistikai
	if {$testai == 0} {
		set testu_ids [db3 eval {SELECT DISTINCT testo_id FROM bandymai JOIN bandymai_options ON bandymai.Id=bandymai_options.bandymo_id JOIN mokiniai ON bandymai.mokinio_id=mokiniai.Id JOIN klases ON klases.Id=mokiniai.klases_id WHERE klases.klase=$parinktaklase AND pavadinimas="ar_pazymiui" AND reiksme=1 AND ar_istaisyta=1 AND STRFTIME('%Y', data) = $metai ORDER BY data DESC}]
	} else {
		set testu_ids [db3 eval {SELECT DISTINCT testo_id FROM bandymai JOIN bandymai_options ON bandymai.Id=bandymai_options.bandymo_id JOIN mokiniai ON bandymai.mokinio_id=mokiniai.Id JOIN klases ON klases.Id=mokiniai.klases_id WHERE klases.klase=$parinktaklase AND pavadinimas="ar_pazymiui" AND reiksme=0 AND STRFTIME('%Y', data) = $metai ORDER BY data DESC}]
	}
	if {$parinktaklase == "" && $testai == 0} {
		set testu_ids [db3 eval {SELECT DISTINCT testo_id FROM bandymai JOIN bandymai_options ON bandymai.Id=bandymai_options.bandymo_id WHERE pavadinimas="ar_pazymiui" AND reiksme=1 AND ar_istaisyta=1 AND STRFTIME('%Y', data) = $metai}]
	}
	if {$parinktaklase == "" && $testai == 1} {
		set testu_ids [db3 eval {SELECT DISTINCT testo_id FROM bandymai JOIN bandymai_options ON bandymai.Id=bandymai_options.bandymo_id WHERE pavadinimas="ar_pazymiui" AND reiksme=0 AND STRFTIME('%Y', data) = $metai}]
	}
	return $testu_ids
}

proc p_generuoti_testu_sarasa {} {
	set pazymeti_testai ""
	set testu_ids [db3 eval {SELECT Id FROM testai}] 
	foreach testo_id $testu_ids {
		if {[info exists ::tst$testo_id]} {
			if {[set ::tst$testo_id] == 1} {
				lappend pazymeti_testai $testo_id
			}
		}
	}
	return $pazymeti_testai
	
}

proc p_nuzymeti_testus_statistikai {} {
	set testu_ids [db3 eval {SELECT Id FROM testai}]
	foreach testo_id $testu_ids {
		if {[info exists ::tst$testo_id]} {
			unset ::tst$testo_id
		}
	}
}

proc p_piesti_testus_statistikai {r w} {
	destroy $w.f1.txt
	set pazymeti_testai [p_generuoti_testu_sarasa]
	set parinktaklase "[$w.f1.klasescombo get]"
	set parinktimetai "[$w.f1.metai get]"
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$parinktaklase}]
	set testu_ids [p_pakeisti_testuids_statistikai $w $r $parinktaklase $parinktimetai]
	set duomenys [question_statistics $klases_id $pazymeti_testai $parinktimetai]
	grid [ttk::frame $w.f1.txt] -column 0 -row $r -sticky news -columnspan 2
	grid [text $w.f1.txt.t -yscrollcommand {.sta.f1.txt.scrollbar set} -background "white" -state disabled -width 35 -height 10] -column 0 -row $r -sticky news
	grid [scrollbar $w.f1.txt.scrollbar -command {.sta.f1.txt.t yview} -orient vertical] -column 1 -row $r -sticky nws; incr r
	ttk::label $w.f1.txt.t.l -text "" -background "white"
	$w.f1.txt.t window create 2.0 -window $w.f1.txt.t.l
	foreach testo_id $testu_ids {
		set testo_pavad [db3 onecolumn {SELECT testo_pavad FROM testai WHERE Id=$testo_id}]
		grid [checkbutton $w.f1.txt.t.l.tst$testo_id -text "$testo_pavad" -onvalue 1 -offvalue 0 -variable ::tst$testo_id -background "white"] -column 0 -row $r -pady 1 -padx 5 -sticky w; incr r
	}
	return $duomenys $klases_id $testu_ids $parinktaklase $parinktimetai
}

proc p_piesti_atsakymu_statistika {w r wbg gbg} {
	set pazymeti_testai [p_generuoti_testu_sarasa]
	set parinktimetai "[$w.f1.metai get]"
	set parinktaklase "[$w.f1.klasescombo get]"
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$parinktaklase}]
	set duomenys [question_statistics $klases_id $pazymeti_testai $parinktimetai]
	set i 1
	if {$::testai_statistikai == 0} {
		if {$duomenys != ""} {
			destroy $w.f2.t1.l.f3
			destroy $w.f2.t1.l.lt
			grid [ttk::frame $w.f2.t1.l.f3 -style baltas.TFrame] -column 1 -row $r -sticky news
			grid [ttk::label $w.f2.t1.l.f3.pradinislbl -text "KLAUSIMAI:" -padding "5 5" -background "white"] -column 0 -row $r -pady 1 -padx 1 -columnspan 3; incr r
			foreach d $duomenys {
				set kl_id [lindex $d 0]
				lassign [db3 eval {SELECT tipas, kl FROM klausimai WHERE Id=$kl_id}] tipas klausimo_tekstas
				set sprendimu_sk [lindex $d 1]
				set teisingu_sk [lindex $d 2]
				if {$teisingu_sk < [expr ($sprendimu_sk*60.0)/100]} {
					set spalva "red3"
				}
				if {$teisingu_sk >= [expr ($sprendimu_sk*60.0)/100]} {
					set spalva "orange red"
				}
				if {$teisingu_sk >= [expr ($sprendimu_sk*80.0)/100]} {
					set spalva "RoyalBlue1"
				}
				if {$teisingu_sk >= $sprendimu_sk} {
					set spalva "green2"
				}
				set plotis [expr round(1.0 * $teisingu_sk / $sprendimu_sk * 20) + 3]
				if {$tipas == "atviras_kl"} {
					set komandos_issamiau "set ::atsakymu_duomenys \"\[p_open_question_statistics $kl_id \"$pazymeti_testai\" \"$klases_id\"\ $parinktimetai]\"; p_piesti_atsakymu_statistika $w $r $wbg $gbg; p_klausimo_statistika_issamiau $w $kl_id $wbg $gbg"
				} else {
					set komandos_issamiau "set ::atsakymu_duomenys \"\[p_answer_choice_statistics $kl_id \"$pazymeti_testai\" \"$klases_id\"\ $parinktimetai]\"; p_piesti_atsakymu_statistika $w $r $wbg $gbg; p_klausimo_statistika_issamiau $w $kl_id $wbg $gbg"
				}
				grid [ttk::button $w.f2.t1.l.f3.klbutton$kl_id -text "" -image prev16 -command $komandos_issamiau -style mazas.TButton] -column 0 -row $r -pady 1 -padx 5 -sticky w
				setTooltip $w.f2.t1.l.f3.klbutton$kl_id "Išsamiau"
				grid [ttk::label $w.f2.t1.l.f3.kl$kl_id -text "$i. $klausimo_tekstas" -padding "5 6 5 6" -wraplength 340 -background $gbg] -column 1 -row $r -pady 1 -padx 1 -sticky we
				grid [ttk::label $w.f2.t1.l.f3.kl$kl_id$i -text "$teisingu_sk/$sprendimu_sk" -padding "5 5 5 5" -width $plotis -background $spalva] -column 2 -row $r -pady 1 -padx 1 -sticky w; incr r
				incr i
			}
		} else {
			tk_messageBox -message "Nepažymėtas testas/apklausa." -parent $w
			return
		}
		grid [ttk::frame $w.f2.t1.l.lt -style baltas.TFrame] -column 1 -row $r -sticky news
		grid [ttk::label $w.f2.t1.l.lt.ltlbl -text "KIEK MOKINIŲ NAUDOJA LIETUVIŠKAS RAIDES:" -padding "5 5" -background "white"] -column 0 -row $r -pady 1 -padx 1 -columnspan 3; incr r
		grid [ttk::label $w.f2.t1.l.lt.naudoja -text "Naudoja" -padding "5 5"] -column 1 -row $r -pady 1 -padx 1 -sticky we; incr r
		grid [ttk::label $w.f2.t1.l.lt.isdalies -text "Naudoja iš dalies" -padding "5 5"] -column 1 -row $r -pady 1 -padx 1 -sticky we; incr r
		grid [ttk::label $w.f2.t1.l.lt.nenaudoja -text "Nenaudoja" -padding "5 5"] -column 1 -row $r -pady 1 -padx 1 -sticky we
		set duomenyslt [p_lt_statistics $klases_id $pazymeti_testai $parinktimetai]
		set viso_bandymu [expr [lindex $duomenyslt 0] + [lindex $duomenyslt 2] + [lindex $duomenyslt 4]]
		set r [expr $r-2]
		set spalvos {green2 RoyalBlue1 red3}
		for {set j 0} {$j<3} {incr j} {
			set plotis [expr round(1.0 * [lindex $duomenyslt [expr $j * 2]] / $viso_bandymu * 22) + 3]
			grid [ttk::label $w.f2.t1.l.lt.ltstats$j -text "[lindex $duomenyslt [expr $j * 2]] / $viso_bandymu" -padding "5 5" -width $plotis -background [lindex $spalvos $j]] -column 2 -row $r -pady 1 -padx 1 -sticky w; incr r
			setTooltip $w.f2.t1.l.lt.ltstats$j [lindex $duomenyslt [expr $j * 2 + 1]]
			
		}
	} else {
		destroy $w.f2.t1.l.f3
		destroy $w.f2.t1.l.lt
		grid [ttk::frame $w.f2.t1.l.f3 -style baltas.TFrame] -column 1 -row $r -sticky news
		grid columnconfigure $w.f2.t1.l.f3 0 -weight 1
		grid columnconfigure $w.f2.t1.l.f3 1 -weight 1
		set klausimai [questionnaire_summary $pazymeti_testai $klases_id]
		set i 0
		set current_question_id -1
		#klausimo id; klausimo tipas; klausimo tekstas; atsakymo var id; atsakymo tekstas; atsakymo kartai (visada 1 jei atviras kl); pasirinkeju sarasas; klausimo rodymo/sprendimo kartai
		foreach {kid kl_tipas kl_text av_id a_text n choosers k_n_a} $klausimai {
			if {$current_question_id != $kid} {
				grid [ttk::label $w.f2.t1.l.f3.kl$i -text "$kl_text" -padding "5 6 5 6" -background $gbg -wraplength 680] -column 0 -columnspan 2 -row $r -pady 1 -padx 1 -sticky we; incr i
				incr r
			}
			
			grid [ttk::label $w.f2.t1.l.f3.av$i -text "$a_text" -padding "5 6 5 6" -wraplength 500] -column 0 -row $r -pady 1 -padx 1 -sticky we
			setTooltip $w.f2.t1.l.f3.av$i $choosers
			incr i
			
			if {$kl_tipas != "atviras_kl"} {
				set plotis [expr round(1.0 * $n / $k_n_a * 20) + 3]
				if {$n == $k_n_a} {
					set spalva "green2"
				}
				if {$n < $k_n_a} {
					set spalva "RoyalBlue1"
				}
				if {$n == 0} {
					set spalva "red3"
				}
				grid [ttk::label $w.f2.t1.l.f3.avl$i -text "$n/$k_n_a" -padding "5 5 5 5" -width $plotis -background $spalva] -column 1 -row $r -pady 1 -padx 1 -sticky w; incr i
			}

			set current_question_id $kid
			incr r
		}
	}
}

proc p_klausimo_statistika_issamiau {w kl_id wbg gbg} {
	set pazymeti_testai [p_generuoti_testu_sarasa]
	destroy $w.f2.t1.l.f3
	destroy $w.f2.t1.l.lt
	set r 0
	grid [ttk::frame $w.f2.t1.l.f3 -style baltas.TFrame] -column 1 -row $r -sticky news; incr r
	set kl_r $r
	incr r
	set tipas [db3 onecolumn {SELECT tipas FROM klausimai WHERE Id=$kl_id}]
	set klausimas [db3 onecolumn {SELECT kl FROM klausimai WHERE Id=$kl_id}]
	set pav_id [db3 onecolumn {SELECT pav_id FROM klausimai WHERE Id=$kl_id}]
	set parinktaklase "[$w.f1.klasescombo get]"
	set parinktimetai "[$w.f1.metai get]"
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$parinktaklase}]
	set i 1
	if {$pav_id != ""} {
		set paveiksliukas [db3 onecolumn {SELECT content FROM paveiksleliai WHERE Id=$pav_id}]
		image create photo p -data $paveiksliukas
		grid [ttk::label $w.f2.t1.l.f3.pav -text "" -image p -padding "10 10" -compound left] -column 1  -columnspan 2 -row $r; incr r
	}
	foreach d $::atsakymu_duomenys {
		set ats_id [lindex $d 0]
		set atsakymas [db3 onecolumn {SELECT atsakymo_var FROM atsakymuvariantai WHERE Id=$ats_id}]
		set sprendimu_sk [lindex $d 1]
		set pasirinkimu_sk [lindex $d 2]
		if {$pasirinkimu_sk < [expr ($sprendimu_sk*60.0)/100]} {
			set spalva "red3"
		}
		if {$pasirinkimu_sk >= [expr ($sprendimu_sk*60.0)/100]} {
			set spalva "orange red"
		}
		if {$pasirinkimu_sk >= [expr ($sprendimu_sk*80.0)/100]} {
			set spalva "RoyalBlue1"
		}
		if {$pasirinkimu_sk >= $sprendimu_sk} {
			set spalva "green2"
		}
		set plotis [expr round(1.0 * $pasirinkimu_sk / $sprendimu_sk * 20) + 3]
		if  {$tipas == "vienas_teisingas" || $tipas == "keli_teisingi"} {
			grid [ttk::label $w.f2.t1.l.f3.kl$ats_id -text "$i. $atsakymas" -padding "5 5" -wraplength 550] -column 1 -row $r -pady 1 -padx 1 -sticky we
			grid [ttk::label $w.f2.t1.l.f3.kl$ats_id$i -text "$pasirinkimu_sk/$sprendimu_sk" -padding "5 5" -width $plotis -background $spalva] -column 2 -row $r -pady 1 -padx 1 -sticky w; incr r
		} else {
			set correctness_text_map {0 {Atsakė visiškai teisingai} 1 {Atsakė iš dalies teisingai} 2 {Atsakė klaidingai}}
			set atsakymas [dict get $correctness_text_map $ats_id]
			grid [ttk::label $w.f2.t1.l.f3.kl$ats_id -text "$atsakymas" -padding "10 5 5 5" -wraplength 550 -width 15 -background $gbg] -column 1 -row $r -pady 1 -padx 1 -sticky we
			grid [ttk::label $w.f2.t1.l.f3.kl$ats_id$i -text "$pasirinkimu_sk/$sprendimu_sk" -padding "5 5" -width $plotis -background $spalva] -column 2 -row $r -pady 1 -padx 1 -sticky w; incr r
		}
		incr i
	}
	if {$tipas == "atviras_kl"} {
		grid [ttk::label $w.f2.t1.l.f3.mokatslbl -text "Mokinių atsakymai:" -padding "5 5" -background "white"] -column 0 -row $r -pady 1 -padx 1 -columnspan 4; incr r
		set atsakymai [p_all_open_answers $kl_id $pazymeti_testai $klases_id $parinktimetai]
		set test_ids_prepared [join $pazymeti_testai {, }]
		foreach ats $atsakymai {
			set mokids [db3 eval "SELECT mokinio_id FROM bandymai JOIN bandymai_pasirinkimai ON bandymai_pasirinkimai.bandymo_id=bandymai.Id WHERE testo_id IN ($test_ids_prepared) AND atsakymo_tekstas='$ats'"]
			foreach mokid $mokids {
				set mokinys [db3 eval {SELECT vardas, pavarde FROM mokiniai WHERE Id=$mokid}]
				grid [ttk::label $w.f2.t1.l.f3.mokats$r -text $ats -wraplength 550 -padding "5 1 5 1" -width 80] -column 1 -row $r -pady 1 -padx 1 -columnspan 3
				setTooltip $w.f2.t1.l.f3.mokats$r "$mokinys"
				incr r
			}
		}
	}
	grid [ttk::label $w.f2.t1.l.f3.klausimaslbl -text "Klausimas: „$klausimas“" -padding "5 5" -background "white" -wraplength 670] -column 0 -row $kl_r -pady 1 -padx 1 -columnspan 4
}

proc p_statistika {{kl_id 0}} {
	set ar_yra_sprendimu [db3 eval {SELECT Id FROM bandymai}]
	if {$ar_yra_sprendimu == ""} {
		tk_messageBox -message "Dar nėra išspręstas nė vienas testas ar apklausa." -parent .n
		return
	}
	set w .sta
	p_naujas_langas $w "Rezultatų statistika"
	wm protocol .sta WM_DELETE_WINDOW {
		destroy .sta
		if {[info exists ::pazymetas_testas]} {
			unset ::pazymetas_testas
		}
		if {[info exists ::pazymetas_testas_i]} {
			unset ::pazymetas_testas_i
		}
		if {[info exists ::pazymetas_testas_n]} {
			unset ::pazymetas_testas_n
		}
		if {[info exists ::pazymeta_apklausa]} {
			unset ::pazymeta_apklausa
		}
		if {[info exists ::rikiuoti_pagal_ka]} {
			unset ::rikiuoti_pagal_ka
		}
		if {[info exists ::atsakymu_duomenys]} {
			set ::atsakymu_duomenys ""
		}
		set parinktaklase ""
		set parinktimetai ""
	}
	if {![info exists ::atsakymu_duomenys]} {
		set ::atsakymu_duomenys ""
	}
	if {![info exists ::testai_statistikai]} {
		set ::testai_statistikai 0
	}
	set wbg "gray90"
	set gbg "seashell3"
	set pazymeti_testai ""
	set r 0
	set klases [db3 eval {SELECT DISTINCT klase FROM klases JOIN mokiniai ON mokiniai.klases_id=klases.Id JOIN bandymai ON bandymai.mokinio_id=mokiniai.Id WHERE bandymai.Id != 0 ORDER BY klase}]
	if {![info exists ::klases]} {
		set ::klases [db3 eval {SELECT MIN(klase) FROM klases JOIN mokiniai ON mokiniai.klases_id=klases.Id JOIN bandymai ON bandymai.mokinio_id=mokiniai.Id WHERE bandymai.Id != 0 ORDER BY klase}]
	}
	grid [ttk::frame $w.f1] -column 0 -row $r -sticky news
	grid [ttk::frame $w.f2] -column 1 -row $r -sticky news
	grid [ttk::label $w.f1.klaselbl -text "KLASĖ:" -padding "5 5"] -column 0 -row $r -pady 1 -padx 1
	grid [ttk::combobox $w.f1.klasescombo -textvariable ::klases -width 7] -column 1 -row $r -pady 1 -padx 1 -sticky w; incr r
	$w.f1.klasescombo configure -values $klases
	set parinktaklase "[$w.f1.klasescombo get]"
	bind $w.f1.klasescombo <<ComboboxSelected>> {lassign [p_piesti_testus_statistikai 3 .sta] duomenys klases_id testu_ids parinktaklase parinktimetai; p_nuzymeti_testus_statistikai}
	set metai [db3 eval {SELECT DISTINCT STRFTIME('%Y', data) AS year FROM bandymai ORDER BY data ASC}]
	if {![info exists ::metai]} {
		set ::metai [db3 eval {SELECT MAX(STRFTIME('%Y', data)) AS year FROM bandymai}]
	}
	grid [ttk::label $w.f1.lblm -text "METAI:"] -column 0 -row $r -pady 1 -padx 1
	grid [ttk::combobox $w.f1.metai -textvariable ::metai -width 7] -column 1 -row $r -pady 1 -padx 1 -sticky w; incr r
	$w.f1.metai configure -values $metai
	set parinktimetai "[$w.f1.metai get]"
	bind $w.f1.metai <<ComboboxSelected>> {lassign [p_piesti_testus_statistikai 3 .sta] duomenys klases_id testu_ids parinktaklase parinktimetai; p_nuzymeti_testus_statistikai}
	grid [ttk::radiobutton $w.f1.testai -text "Testai" -variable ::testai_statistikai -value "0" -command {p_nuzymeti_testus_statistikai; set testu_ids [p_pakeisti_testuids_statistikai .sta 3 \$parinktaklase \$parinktimetai]; lassign [p_piesti_testus_statistikai 3 .sta] duomenys klases_id testu_ids parinktaklase parinktimetai; .sta.f1.mygtukai.rodytipazymius configure -state normal}] -column 0 -row $r
	grid [ttk::radiobutton $w.f1.apklausos -text "Apklausos" -variable ::testai_statistikai -value "1" -command {p_nuzymeti_testus_statistikai; set testu_ids [p_pakeisti_testuids_statistikai .sta 3 \$parinktaklase \$parinktimetai]; lassign [p_piesti_testus_statistikai 3 .sta] duomenys klases_id testu_ids parinktaklase parinktimetai; .sta.f1.mygtukai.rodytipazymius configure -state disabled}] -column 1 -row $r; incr r
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$parinktaklase}]
	set testu_ids [p_pakeisti_testuids_statistikai $w $r $parinktaklase $parinktimetai]
	set duomenys [question_statistics $klases_id $pazymeti_testai $parinktimetai]
	grid [ttk::frame $w.f1.txt] -column 0 -row $r -sticky news -columnspan 2
	grid [text $w.f1.txt.t -yscrollcommand {.sta.f1.txt.scrollbar set} -background "white" -state disabled -width 35 -height 10] -column 0 -row $r -sticky news
	grid [scrollbar $w.f1.txt.scrollbar -command {.sta.f1.txt.t yview} -orient vertical] -column 1 -row $r -sticky nws; incr r
	ttk::label $w.f1.txt.t.l -text "" -background "white"
	$w.f1.txt.t window create 2.0 -window $w.f1.txt.t.l
	foreach testo_id $testu_ids {
		set testo_pavad [db3 onecolumn {SELECT testo_pavad FROM testai WHERE Id=$testo_id}]
		grid [checkbutton $w.f1.txt.t.l.tst$testo_id -text "$testo_pavad" -onvalue 1 -offvalue 0 -variable ::tst$testo_id -background "white"] -column 0 -row $r -pady 1 -padx 5 -sticky w; incr r
	}
	grid [ttk::frame $w.f1.mygtukai] -column 0 -row $r -sticky news -columnspan 2
	grid columnconfigure $w.f1.mygtukai 0 -weight 1
	grid columnconfigure $w.f1.mygtukai 1 -weight 1
	set komandos_statistikai "set ::atsakymu_duomenys \"\"; p_piesti_atsakymu_statistika $w 2 $wbg $gbg"
	set komandos_pazymiams "set ::atsakymu_duomenys \"\"; p_perziureti_pazymius $w \"$parinktaklase\" graded"
	grid [ttk::button $w.f1.mygtukai.rodytirezultatus -text "" -image chart_icon -command $komandos_statistikai -style mazas.TButton] -column 0 -row $r -pady 1 -padx 5 -sticky w
	setTooltip $w.f1.mygtukai.rodytirezultatus "Rodyti statistiką"
	grid [ttk::button $w.f1.mygtukai.rodytipazymius -text "" -image tablesmall -command $komandos_pazymiams -style mazas.TButton] -column 0 -row $r -pady 1 -padx 5 -sticky e
	setTooltip $w.f1.mygtukai.rodytipazymius "Rodyti pažymius"
	grid [ttk::button $w.f1.mygtukai.siustipazymius -text "" -image testgraded -command "set ::atsakymu_duomenys \"\"; p_siusti_testo_rezultatus $w" -style mazas.TButton] -column 1 -row $r -pady 1 -padx 20 -sticky w
	setTooltip $w.f1.mygtukai.siustipazymius "Siųsti pažymius"
	if {$::testai_statistikai == 0} {
		$w.f1.mygtukai.rodytipazymius configure -state normal
	} else {
		$w.f1.mygtukai.rodytipazymius configure -state disabled
	}
	set r 0
	grid [ttk::label $w.f2.geriausilbl -text "REZULTATAI:" -padding "5 5"] -column 0 -row $r -pady 1 -padx 1; incr r
	grid [text $w.f2.t1 -yscrollcommand {.sta.f2.scrollbar1 set} -background "white" -state disabled -width 98 -height 35] -column 0 -row $r -sticky news
	grid [scrollbar $w.f2.scrollbar1 -command {.sta.f2.t1 yview} -orient vertical] -column 1 -row $r -sticky nws; incr r
	ttk::label $w.f2.t1.l -text "" -background "white"
	$w.f2.t1 window create 2.0 -window $w.f2.t1.l
}

proc p_all_open_answers {question_id test_ids class_id year} {
	set test_ids_prepared [join $test_ids {, }]
	set class_cond [expr {$class_id} == {""} ? {"1"} : {"klases_id = $class_id"}]
	set year_cond [expr {$year} == {""} ? {""} : {"STRFTIME('%Y', data) = '$year' AND "}]
	
	return [db3 eval "
		SELECT atsakymo_tekstas
		FROM 
			bandymai_pasirinkimai bp
			JOIN
			bandymai b ON b.Id = bp.bandymo_id
			JOIN
			klausimai_testai kt ON kt.testo_id = b.testo_id
		WHERE 
			$year_cond
			b.testo_id IN ($test_ids_prepared) AND 
			mokinio_id IN (SELECT Id FROM mokiniai WHERE $class_cond) AND 
			atsvar_id = (SELECT id FROM atsakymuvariantai WHERE klausimo_id = $question_id AND ar_teisingas_var = 0) AND
			klausimo_id = $question_id	
	"]
}

proc ymd_to_date {y {m 0} {d 0}} {
	return [format "%04d-%02d-%02d" [expr {$y} == {""} ? {0} : {$y}] [expr {$m} == {""} ? {0} : {$m}] [expr {$d} == {""} ? {0} : {$d}]]
}

#returns a list of lists (rows), each row describes question in one of tests, by one of class in given date range (all conditions must be met)
#row contents: <text of question (at current time)>, <all answers concatenated, for non free questions count/(question attempts) for each variant selected is returned>
proc questionnaire_summary {test_ids class_ids {date_from "0000-00-00"} {date_to "9999-99-99"}} {
	set test_ids_prepared [join $test_ids {, }]
	set test_cond [expr {$test_ids_prepared} == {""} ? {"AND 1"} : {"AND b.testo_id IN($test_ids_prepared)"}]
	set class_ids_prepared [join $class_ids {, }]
	set class_cond [expr {$class_ids_prepared} == {""} ? {"AND 1"} : {"AND klases_id IN($class_ids_prepared)"}]
	
	set date_cond "STRFTIME('%Y-%m-%d', data) BETWEEN '$date_from' AND '$date_to'"
	
	set attempts [db3 eval "SELECT b.Id FROM bandymai b JOIN mokiniai m ON b.mokinio_id = m.Id WHERE  $date_cond $test_cond $class_cond"]
	set count [llength $attempts]
	
	set attempt_ids_prepared [join $attempts {, }]
	
	return [db3 eval "SELECT DISTINCT tbl.*, k_n_a FROM 
		(
			SELECT k.Id AS kid, k.tipas, k.kl, av.Id AS avid, atsakymo_tekstas,
				CASE k.tipas 
					WHEN 'atviras_kl' THEN 1
					ELSE COUNT(DISTINCT bp.Id)
				END AS n,
				GROUP_CONCAT(vardas || ' ' || pavarde, '; ') AS choosers
			FROM 
				bandymai_pasirinkimai bp 
				JOIN atsakymuvariantai av ON bp.atsvar_id = av.Id  
				JOIN klausimai k ON k.Id = av.klausimo_id
				JOIN bandymai b ON bp.bandymo_id = b.Id
				JOIN mokiniai m ON m.Id = b.mokinio_id
			WHERE bp.bandymo_id IN ($attempt_ids_prepared) AND ar_pasirinko = 1
			GROUP BY av.Id || atsakymo_tekstas || (CASE k.tipas WHEN 'atviras_kl' THEN bp.rowid ELSE '' END)
		) AS tbl
		JOIN (
			SELECT kt.klausimo_id AS kid, COUNT(*) k_n_a
			FROM
				bandymai b
				JOIN klausimai_testai kt ON b.testo_id = kt.testo_id
			WHERE
				b.Id IN ($attempt_ids_prepared) $test_cond
			GROUP BY kt.klausimo_id
		) AS kl_counts ON kl_counts.kid = tbl.kid
		JOIN klausimai_testai kt ON kl_counts.kid = klausimo_id
		ORDER BY klausimo_nr, avid
	"]
}

#returns list with 3 elements, each element is list like {<"correctness"> <num_attempts> <num_correctness>}, num_attempts is just total number of times given question was attempted
#num_correctness is number of times given "correctness" was achieved; 
#"correctness" is just a number, one of 3: 0 - totally correct/full points, 1 - partially correct/half points, 2 - totally incorrect/0 points
proc p_open_question_statistics {question_id test_ids class_id year} {
	set test_ids_prepared [join $test_ids {, }]
	set class_cond [expr {$class_id} == {""} ? {"1"} : {"klases_id = $class_id"}]
	set year_cond [expr {$year} == {""} ? {""} : {"STRFTIME('%Y', data) = '$year' AND "}]
	set result ""

	db3 eval "
		SELECT correctness, num_attempts, num_correctness
		FROM
			(SELECT atsvar_id, COALESCE(COUNT(*), 0) AS num_correctness, (CASE WHEN tsk = verte_taskais THEN 0 WHEN tsk > 0 THEN 1 ELSE 2 END) AS correctness
				FROM 
					bandymai_pasirinkimai bp
					JOIN
					bandymai b ON b.Id = bp.bandymo_id
					JOIN
					klausimai_testai kt ON kt.testo_id = b.testo_id
				WHERE 
					$year_cond
					b.testo_id IN ($test_ids_prepared) AND 
					mokinio_id IN (SELECT Id FROM mokiniai WHERE $class_cond) AND 
					atsvar_id = (SELECT id FROM atsakymuvariantai WHERE klausimo_id = $question_id AND ar_teisingas_var = 0) AND
					klausimo_id = $question_id
				GROUP BY atsvar_id, correctness
				ORDER BY correctness
			) AS correctness_info
		JOIN
			(SELECT atsvar_id, COUNT(*) num_attempts
			FROM bandymai_pasirinkimai bp JOIN bandymai b ON bp.bandymo_id = b.Id
			WHERE
				$year_cond
				atsvar_id = (SELECT id FROM atsakymuvariantai WHERE klausimo_id = $question_id AND ar_teisingas_var = 0) AND
				mokinio_id IN (SELECT Id FROM mokiniai WHERE $class_cond) AND
				testo_id IN ($test_ids_prepared)
			) AS total
		ON correctness_info.atsvar_id = total.atsvar_id
		ORDER BY correctness;
			
	" {
		lappend result "$correctness $num_attempts $num_correctness"
	}
	return $result
}

proc p_answer_choice_statistics {question_id test_ids class_id year} {
	set test_ids_prepared [join $test_ids {, }]
	set class_cond [expr {$class_id} == {""} ? {"1"} : {"klases_id = $class_id"}]
	set year_cond [expr {$year} == {""} ? {""} : {"STRFTIME('%Y', data) = '$year' AND "}]
	set result ""
	
	db3 eval "
		SELECT atsvar_id ans_id, COUNT(*) num_attempts, SUM(ar_pasirinko) num_selects
		FROM bandymai_pasirinkimai bp JOIN bandymai b ON bp.bandymo_id = b.Id
		WHERE
			$year_cond
			atsvar_id IN (SELECT id FROM atsakymuvariantai WHERE klausimo_id = $question_id) AND
			mokinio_id IN (SELECT Id FROM mokiniai WHERE $class_cond) AND
			testo_id IN ($test_ids_prepared)
		GROUP BY atsvar_id
			
	" {
		lappend result "$ans_id $num_attempts $num_selects"
	}
	return $result
}
#rename to questions_statistics
proc question_statistics {class_id test_ids year} {
	set test_ids_prepared [join $test_ids {, }]
	set class_cond [expr {$class_id} == {""} ? {"1"} : {"klases_id = $class_id"}]
	set year_cond [expr {$year} == {""} ? {""} : {"STRFTIME('%Y', data) = '$year' AND "}]
	
	set result ""
	db3 eval "
		SELECT total.klausimo_id, num_attempts, num_correct FROM
			(SELECT klausimo_id, COALESCE(SUM(points_collected>=verte_taskais), 0) AS num_correct FROM 

				(SELECT b.Id, kt.klausimo_id, kt.verte_taskais, SUM(tsk) AS points_collected
					FROM 
						atsakymuvariantai av
						JOIN 
						bandymai_pasirinkimai bp ON av.Id = bp.atsvar_id
						JOIN
						bandymai b ON b.Id = bp.bandymo_id
						JOIN
						klausimai_testai kt ON kt.klausimo_id = av.klausimo_id AND kt.testo_id = b.testo_id
					WHERE $year_cond b.testo_id IN ($test_ids_prepared) AND mokinio_id IN (SELECT Id FROM mokiniai WHERE $class_cond)
					GROUP BY b.Id, kt.klausimo_id
					ORDER BY kt.klausimo_id
				) AS points_per_question_try
		
			GROUP BY klausimo_id) AS correct
		JOIN
			(SELECT klausimo_id, COUNT(*) AS num_attempts
			FROM klausimai_testai kt JOIN bandymai b ON b.testo_id = kt.testo_id
			WHERE $year_cond b.testo_id IN ($test_ids_prepared) AND mokinio_id IN (SELECT Id FROM mokiniai WHERE $class_cond)
			GROUP BY klausimo_id) AS total
		ON correct.klausimo_id = total.klausimo_id
		ORDER BY 1.0 * num_correct / num_attempts DESC;
	" {
		lappend result "$klausimo_id $num_attempts $num_correct"
	}
	return $result
}

proc p_lt_statistics {class_id test_ids year} {
	set test_ids_prepared [join $test_ids {, }]
	set class_cond [expr {$class_id} == {""} ? {"1"} : {"klases_id = $class_id"}]
	set year_cond [expr {$year} == {""} ? {""} : {"STRFTIME('%Y', data) = '$year' AND "}]
	
	return [db3 eval "
		SELECT COUNT(*), GROUP_CONCAT(vardas || ' ' || pavarde, '; ') FROM bandymai JOIN mokiniai ON bandymai.mokinio_id = mokiniai.Id 
		WHERE $year_cond penalty_tsk = 1 AND $class_cond AND testo_id IN ($test_ids_prepared)
		UNION ALL
		SELECT COUNT(*), GROUP_CONCAT(vardas || ' ' || pavarde, '; ') FROM bandymai JOIN mokiniai ON bandymai.mokinio_id = mokiniai.Id 
		WHERE $year_cond penalty_tsk = 0 AND $class_cond AND testo_id IN ($test_ids_prepared)
		UNION ALL
		SELECT COUNT(*), GROUP_CONCAT(vardas || ' ' || pavarde, '; ') FROM bandymai JOIN mokiniai ON bandymai.mokinio_id = mokiniai.Id 
		WHERE $year_cond penalty_tsk = -1 AND $class_cond AND testo_id IN ($test_ids_prepared)
	"]
}

proc p_perziureti_pazymius {w parinktaklase what} {
	set metai "[$w.f1.metai get]"
	set parinktaklase "[$w.f1.klasescombo get]"
	if {[winfo exists $w.f2.t1.l] == 0} {
		ttk::label $w.f2.t1.l -text "" -background "white"
		$w.f2.t1 window create 2.0 -window $w.f2.t1.l
	}
	destroy $w.f2.t1.l.f3
	destroy $w.f2.t1.l.lt
	set ::pazymetas_testas_i ""
	if {![info exists ::rikiuoti_pagal_ka]} {
		set ::rikiuoti_pagal_ka "pavarde"
	}
	set pazymeti_testai [p_generuoti_testu_sarasa]
	set test_ids_prepared [join $pazymeti_testai {, }]
	if {$test_ids_prepared == ""} {
		tk_messageBox -message "Nepažymėtas testas." -parent $w
		return
	}
	set wbg "gray90"
	set gbg "seashell3"
	set r 0
	grid [ttk::frame $w.f2.t1.l.f3 -style baltas.TFrame] -column 1 -row $r -sticky news; incr r
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$parinktaklase}]
	if {$::rikiuoti_pagal_ka == "pavarde"} {
		set rikiuoti "mokiniai.pavarde ASC"
	}
	if {$::rikiuoti_pagal_ka == "pazymys"} {
		set rikiuoti "bandymai.pazymys DESC"
	}
	if {$::rikiuoti_pagal_ka == "klase"} {
		set rikiuoti "mokiniai.klases_id ASC"
	}
	if {$parinktaklase == ""} {
		set bandymoids [db3 eval "SELECT bandymai.Id FROM bandymai JOIN mokiniai ON mokiniai.Id=bandymai.mokinio_id JOIN klases ON mokiniai.klases_id=klases.Id
			WHERE bandymai.testo_id IN($test_ids_prepared) AND bandymai.ar_istaisyta=1 AND STRFTIME('%Y', data) = '$metai' ORDER BY $rikiuoti"]
		set rik_pav "p_rikiuoti_pagal_pavardes $w \"\" $what"
		set rik_kl "p_rikiuoti_pagal_klase $w \"\" $what"
		set rik_paz "p_rikiuoti_pagal_pazymius $w \"\" $what"
	} else {
		set bandymoids [db3 eval "SELECT bandymai.Id FROM bandymai JOIN mokiniai ON mokiniai.Id=bandymai.mokinio_id JOIN klases ON mokiniai.klases_id=klases.Id
			WHERE bandymai.testo_id IN($test_ids_prepared) AND bandymai.ar_istaisyta=1 AND klases.Id=$klases_id AND STRFTIME('%Y', data) = '$metai' ORDER BY $rikiuoti"]
		set rik_pav "p_rikiuoti_pagal_pavardes $w $parinktaklase $what"
		set rik_kl "p_rikiuoti_pagal_klase $w $parinktaklase $what"
		set rik_paz "p_rikiuoti_pagal_pazymius $w $parinktaklase $what"
	}
	set c 0
	grid [ttk::label $w.f2.t1.l.f3.nr -text "EIL. NR.:" -padding "5 5" -background white] -column $c -row $r -pady 1 -padx 1; incr c
	grid [ttk::label $w.f2.t1.l.f3.vardas -text "PAVARDĖ, VARDAS:" -padding "5 5" -background white] -column $c -row $r -pady 1 -padx 1; incr c
	grid [ttk::button $w.f2.t1.l.f3.btnrikpav -text "" -image arrowdown -command $rik_pav] -column $c -row $r -pady 1 -padx 1 -sticky w; incr c
	grid [ttk::label $w.f2.t1.l.f3.klase -text "KLASĖ:" -padding "5 5" -background white] -column $c -row $r -pady 1 -padx 1; incr c
	grid [ttk::button $w.f2.t1.l.f3.btnrikklase -text "" -image arrowdown -command $rik_kl] -column $c -row $r -pady 1 -padx 1 -sticky w; incr c
	grid [ttk::label $w.f2.t1.l.f3.paz -text "PAŽYMYS:" -padding "5 5" -background white] -column $c -row $r -pady 1 -padx 1; incr c
	grid [ttk::button $w.f2.t1.l.f3.btnrik -text "" -image arrowdown -command $rik_paz] -column $c -row $r -pady 1 -padx 1 -sticky w; incr c
	grid [ttk::label $w.f2.t1.l.f3.variantas -text "VARIANTAS:" -padding "5 5" -background white] -column $c -row $r -pady 1 -padx 1; incr c; incr r

	set i 1
	foreach bandymoid $bandymoids {
		set c 0
		set mokid [db3 eval {SELECT mokinio_id FROM bandymai WHERE Id=$bandymoid}]
		#šio kodo REIKIA kad rodytų mokinio įvestą vardą, kad matyčiau, kiek mokinių nemoka rašyti lietuviškai ar nemoka parašyti didžiųjų/mažųjų raidžių (naudinga 5 kl pradžioje)
		set paties_ivestas_vardas [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymoid AND pavadinimas="įvestas vardas"}]
		if {$paties_ivestas_vardas != ""} {
			set pavarde [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymoid AND pavadinimas="įvesta pavardė"}]
			set mokinys "$pavarde $paties_ivestas_vardas"
			set klase [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymoid AND pavadinimas="įvesta klasė"}]
		} else {
			set mokinys [db3 eval {SELECT pavarde, vardas FROM mokiniai JOIN bandymai ON bandymai.mokinio_id=mokiniai.Id WHERE bandymai.Id=$bandymoid}]
			set klase [db3 onecolumn {SELECT klase FROM klases JOIN mokiniai ON mokiniai.klases_id=klases.Id WHERE mokiniai.Id=$mokid}]
		}
		set pazymys [db3 eval {SELECT pazymys FROM bandymai WHERE Id=$bandymoid AND mokinio_id=$mokid}]
		grid [ttk::label $w.f2.t1.l.f3.moknr$i -text "$i. " -background [expr $r % 2 == 0 ? {$wbg} : {$gbg}] -padding "5 6 5 6"] -column $c -row $r -padx 1 -sticky we; incr c
		grid [ttk::label $w.f2.t1.l.f3.mok$i -text "$mokinys" -background [expr $r % 2 == 0 ? {$wbg} : {$gbg}] -padding "5 6 5 6"] -column $c -row $r -padx 1 -sticky we -columnspan 2; incr c; incr c
		if {$pazymys < 4} {
			set fg "red"
		} else {
			set fg ""
		}
		set variantas [db3 onecolumn {SELECT testo_pavad FROM testai JOIN bandymai ON bandymai.testo_id=testai.Id WHERE bandymai.Id=$bandymoid}]
		grid [ttk::label $w.f2.t1.l.f3.klase$i -text "$klase" -background [expr $r % 2 == 0 ? {$wbg} : {$gbg}] -padding "5 6 5 6"] -column $c -row $r -padx 1 -sticky we -columnspan 2; incr c; incr c
		grid [ttk::label $w.f2.t1.l.f3.paz$i -text "$pazymys" -background [expr $r % 2 == 0 ? {$wbg} : {$gbg}] -foreground $fg -padding "5 6 5 6"] -column $c -row $r -padx 1 -sticky we -columnspan 2; incr c; incr c
		grid [ttk::label $w.f2.t1.l.f3.var$i -text "$variantas" -background [expr $r % 2 == 0 ? {$wbg} : {$gbg}] -padding "5 6 5 6"] -column $c -row $r -padx 1 -sticky we; incr c
		grid [ttk::button $w.f2.t1.l.f3.rez$i -text "Rodyti sprendimą" -image prev16 -compound left -command "set ::pazymetas_testas [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymoid}]; set ::rodyti_sprendima 1; p_tikrinti_pazymeta_testa $bandymoid $what" -padding "5 5" -style mazas.TButton] -column $c -row $r -pady 1 -padx 1; incr r
		incr i
	}
	grid [ttk::button $w.f2.t1.l.f3.slepti -text "Slėpti pažymius" -command "p_slepti_pazymius $w [expr $i-1] {$bandymoids}" -padding "5 5" -style mazas.TButton -width 15] -column 5 -row $r -pady 1 -padx 1 -columnspan 2
}

proc p_rikiuoti_pagal_pazymius {w parinktaklase what} {
	set ::rikiuoti_pagal_ka "pazymys"
	destroy $w.f2.t1.l
	p_perziureti_pazymius $w $parinktaklase $what
}

proc p_rikiuoti_pagal_pavardes {w parinktaklase what} {
	set ::rikiuoti_pagal_ka "pavarde"
	destroy $w.f2.t1.l
	p_perziureti_pazymius $w $parinktaklase $what
}

proc p_rikiuoti_pagal_klase {w parinktaklase what} {
	set ::rikiuoti_pagal_ka "klase"
	destroy $w.f2.t1.l
	p_perziureti_pazymius $w $parinktaklase $what
}

proc p_generuoti_pazymius {bandymoids w} {
	set i 1
	foreach bandymoid $bandymoids {
		set mokid [db3 eval {SELECT mokinio_id FROM bandymai WHERE Id=$bandymoid}]
		set pazymys [db3 eval {SELECT pazymys FROM bandymai WHERE Id=$bandymoid AND mokinio_id=$mokid}]
		$w.f2.t1.l.f3.paz$i configure -text "$pazymys"
		incr i
	}
	$w.f2.t1.l.f3.slepti configure -text "Slėpti pažymius" -command "p_slepti_pazymius $w [expr $i-1] {$bandymoids}"
}

proc p_slepti_pazymius {w idkiekis bandymoids} {
	for {set i 1} {$i<=$idkiekis} {incr i} {
		$w.f2.t1.l.f3.paz$i configure -text ""
	}
	$w.f2.t1.l.f3.slepti configure -text "Rodyti pažymius" -command "p_generuoti_pazymius {$bandymoids} $w"
}

proc p_suteikti_taskus {w r verte color2 color1 color ats bandymo_id} {
#suteikia taskus uz atvirus klausimus
	set pazymetas_testas [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymo_id}]
	set ::atvpazymiodalis 0
	if {[info exists ::pazymetas_testas_i]} {
		set kiek_gavo [db3 eval {SELECT tsk FROM bandymai_pasirinkimai WHERE bandymo_id=$bandymo_id AND atsvar_id=$ats}]
	}
	if {[set ::arteisingas$r] == "Taip"} {
		set kiek_gavo [format "%.2f" $verte]
		db3 eval {UPDATE bandymai_pasirinkimai SET tsk=$kiek_gavo WHERE bandymo_id=$bandymo_id AND atsvar_id=$ats}
	}
	if {[set ::arteisingas$r] == "Ne"} {
		set kiek_gavo [format "%.2f" 0]
		db3 eval {UPDATE bandymai_pasirinkimai SET tsk=$kiek_gavo WHERE bandymo_id=$bandymo_id AND atsvar_id=$ats}
	}
	if {[set ::arteisingas$r] == "Iš dalies"} {
		set kiek_gavo [format "%.2f" [expr $verte/2]]
		db3 eval {UPDATE bandymai_pasirinkimai SET tsk=$kiek_gavo WHERE bandymo_id=$bandymo_id AND atsvar_id=$ats}
	}
	$w.g$r configure -text $kiek_gavo -background [expr $r % 2 == 0 ? {$color2} : {$color1}]
	if {[lsearch -exact $::atvirukl_eilutes $r] < 0} {
		lappend ::atvirukl_eilutes $r
	}
	set ::atvira_verte$r $kiek_gavo
	foreach r $::atvirukl_eilutes {
		set ::atvpazymiodalis [expr [set ::atvira_verte$r] + $::atvpazymiodalis]
	}
	set ::surinko_tsk [expr [p_ladd [lsearch -all -inline -not -exact $::gautitaskai {}]] + $::atvpazymiodalis]
	set ::roundpazymys [p_calculate_grade $pazymetas_testas $bandymo_id]
	$w.viso6 configure -text $::surinko_tsk -background $color
	$w.galut6 configure -text $::roundpazymys -background $color
	#tikrinam, ar visi klausimai ištaisyti:
	set taisytini_klausimai [db3 eval {SELECT atsvar_id FROM bandymai_pasirinkimai WHERE bandymo_id=$bandymo_id AND ar_pasirinko=1 AND tsk IS NULL}]
	if {$taisytini_klausimai == ""} {
		.t.t.l.f1.save configure -state normal
	}
}

proc p_atimti_suteiktus_taskus {bandymo_id} {
	#jeigu testą betaisant jis buvo uždarytas neišsaugojus pažymio, grąžinam taškus į pradinę būseną, kad gražiai papilkėtų išsaugojimo mygtukas; kadangi nemoku padaryti, kad programa prisimintų, kas buvo ištaisyta ir kad būtų nustatyta atitinkamai combobox pasirinkimai.
	set ar_istaisyta [db3 eval {SELECT ar_istaisyta FROM bandymai WHERE Id=$bandymo_id}]
	if {$ar_istaisyta == 0} {
		puts "atimam taškus"
		set visi_atviri_klausimai [db3 eval {SELECT atsvar_id FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id JOIN klausimai ON klausimai.Id=atsakymuvariantai.klausimo_id WHERE bandymo_id=$bandymo_id AND ar_pasirinko=1 AND tipas="atviras_kl"}]
		foreach atviras_kl $visi_atviri_klausimai {
			db3 eval {UPDATE bandymai_pasirinkimai SET tsk=NULL WHERE bandymo_id=$bandymo_id AND atsvar_id=$atviras_kl}
		}
	}
	unset ::laikinas_bandymo_id
}

proc p_tasku_priskyrimas_uz_lt {w color2 color1 r color bandymo_id} {
#prie pazymio prideda arba atima taskus pagal tai, ar mokinys rase lietuviskai ar ne
	set pazymetas_testas [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymo_id}]
	if {$::arlt == "Taip"} {
		set ::balu_uz_lt 1
		db3 eval {UPDATE bandymai SET penalty_tsk=$::balu_uz_lt WHERE Id=$bandymo_id}
	}
	if {$::arlt == "Ne"} {
		set ::balu_uz_lt -1
		db3 eval {UPDATE bandymai SET penalty_tsk=$::balu_uz_lt WHERE Id=$bandymo_id}
	}
	if {$::arlt == "Iš dalies"} {
		set ::balu_uz_lt 0
		db3 eval {UPDATE bandymai SET penalty_tsk=$::balu_uz_lt WHERE Id=$bandymo_id}
	}
	if {[info exists ::pazymetas_testas_i]} {
		set ::surinko_tsk [expr [p_ladd [lsearch -all -inline -not -exact $::gautitaskai {}]] + [p_ladd $::atvpazymiodalis]]
	} 
	if {[info exists ::pazymetas_testas_n]} {
		set ::surinko_tsk [expr [p_ladd [lsearch -all -inline -not -exact $::gautitaskai {}]] + $::atvpazymiodalis]
	}
	if {![info exists ::pazymeta_apklausa]} {
		set ::roundpazymys [p_calculate_grade $pazymetas_testas $bandymo_id]
	}
	$w.balu_uz_lt configure -text $::balu_uz_lt -background [expr $r % 2 == 0 ? {$color2} : {$color1}]
	$w.viso6 configure -text $::surinko_tsk -background $color
	$w.galut6 configure -text $::roundpazymys -background $color
	.t.t.l.f1.save configure -state normal
}

proc p_ladd {l} {
#sudeda listo elementų reikšmes
	::tcl::mathop::+ {*}$l
}

proc p_issaugoti_pazymius {w mokid bandymo_id what} {
	#issaugoja pazymi patikrinus testa.
	set ::arlt ""
	set pazymetas_testas [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymo_id}]
	set testopavad [db3 onecolumn {SELECT testo_pavad FROM testai WHERE Id=$pazymetas_testas}]
	if {$::balu_uz_lt == ""} {
		tk_messageBox -message "Negalima išsaugoti pažymio, kol neparinkti taškai už lietuviškas raides." -parent .t
		return
	}
	db3 eval {UPDATE bandymai SET pazymys=$::roundpazymys, ar_istaisyta=1 WHERE Id=$bandymo_id}
	if {[winfo exists $w.saved5] == 1} {
		$w.saved5 configure -text $::roundpazymys
	}
	.t.t.l.f1.save configure -state disabled
	set kitas_id [p_next_try_id $bandymo_id $pazymetas_testas $what]
	if {$kitas_id == ""} {
		tk_messageBox -message "Testas „$testopavad“ ištaisytas." -parent .t
		destroy .t
		p_isvalyti_kintamuosius_patikrinus_testa
		return
	}
	p_isvalyti_kintamuosius_patikrinus_testa
}

proc p_isvalyti_kintamuosius_patikrinus_testa {} {
	set ::parodyti 0
	set ::surinko_tsk 0
	set ::roundpazymys 0
	set ::atvpazymiodalis 0
	set ::balu_uz_lt ""
	set ::arlt ""
	set ::gautitaskai ""
	if {[info exists ::atvirukl_eilutes]} {
		unset ::atvirukl_eilutes
	}
	if {[info exists ::pazymetas_testas]} {
		unset ::pazymetas_testas
	}
	if {[info exists ::pazymetas_testas_n]} {
		unset ::pazymetas_testas_n
	}
	if {[info exists ::pazymetas_testas_i]} {
		unset ::pazymetas_testas_i
	}
	if {[info exists ::pazymeta_apklausa]} {
		unset ::pazymeta_apklausa
	}
}

proc p_apklausos_atsakymu_lentele {w bandymo_id} {
	set color1 "gray90"
	set color2 "seashell3"
	set color3 $::spalva
	wm protocol .t WM_DELETE_WINDOW {
		destroy .t
		if {[info exists ::pazymeta_apklausa]} {
			unset ::pazymeta_apklausa
		}
	}
	set mokid [db3 eval {SELECT mokinio_id FROM bandymai WHERE Id=$bandymo_id}]
	set pazymetas_testas [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymo_id}]
	set r 2
	set stulpeliai "KLAUSIMAS \"MOKINIO ATSAKYMAI\""
	foreach s $stulpeliai {
		lappend stulp_pavad [label $w.$r -text $s -background $color3 -font "ubuntu 10" -justify center]
		incr r
	}
	grid {*}$stulp_pavad -sticky news -padx 1 -pady 1 -row 0
	set testo_klausimu_ids [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$pazymetas_testas}]
	set r 1
	foreach klid $testo_klausimu_ids {
		set cell_color [expr $r % 2 == 0 ? {$color2} : {$color1}]
		set mokatsakymai {}
		set testo_klausimas [db3 onecolumn {SELECT kl FROM klausimai WHERE Id=$klid}]
		grid [ttk::label $w.l$r -text $testo_klausimas -wraplength 230 -justify left -background $cell_color] -sticky news -padx 1 -pady 1 -column 0 -row $r
		set klausimo_pasirinktiats [db3 eval {SELECT atsakymo_tekstas FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id 
			WHERE bandymo_id=$bandymo_id AND klausimo_id=$klid AND ar_pasirinko=1}]
		set klausimo_pasirinktuats_ids [db3 eval {SELECT atsvar_id FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id 
			WHERE bandymo_id=$bandymo_id AND klausimo_id=$klid AND ar_pasirinko=1}]
		lappend mokatsakymai [ttk::label $w.m$r -text "[join $klausimo_pasirinktiats]" -wraplength 250 -justify left -background $cell_color]
		grid {*}$mokatsakymai -sticky news -padx 1 -pady 1 -column 1 -row $r
		incr r
	}
	grid [frame .t.t.l.f -background "white"] -column 0 -row $r -sticky news -columnspan 2
	grid [frame .t.t.l.f1 -background "white"] -column 5 -row $r -pady 5 -sticky news
	set what survey
	set kitas_id [p_next_try_id $bandymo_id $pazymetas_testas $what]
	set buves_id [p_previous_try_id $bandymo_id $pazymetas_testas $what]
	if {$buves_id == ""} {
		set ankstesnis_state "disabled"
	} else {
		set ankstesnis_state "normal"
	}
	if {$kitas_id == ""} {
		set kitas_state "disabled"
	} else {
		set kitas_state "normal"
	}
	grid [ttk::button .t.t.l.f.buves -text "< ANKSTESNIS" -command "p_rodyti_kita_darba ankstesnis $bandymo_id surevey" -state $ankstesnis_state -style mazaszalias.TButton -padding "5 12 5 12"] -column 0 -row $r -padx 1 -sticky e
	grid [ttk::button .t.t.l.f.kitas -text "KITAS >" -command "p_rodyti_kita_darba kitas $bandymo_id surevey" -state $kitas_state -style mazaszalias.TButton -padding "5 12 5 12"] -column 1 -row $r -sticky w
	lassign [p_mokinio_informacija $mokid] vardas pavarde klase
	set data [db3 eval {SELECT data FROM bandymai WHERE Id=$bandymo_id}]
	set irasytas_vardas [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymo_id AND pavadinimas="įvestas vardas"}]
	set irasyta_pavarde [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymo_id AND pavadinimas="įvesta pavardė"}]
	set irasyta_klase [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymo_id AND pavadinimas="įvesta klasė"}]
	set komanda_parodyt_mokiniui "set ::parodyti 1; p_parodyti_mokini $mokid $data [expr $r+1] \"$irasytas_vardas\" \"$irasyta_pavarde\" \"$irasyta_klase\" $bandymo_id"
	eval $komanda_parodyt_mokiniui
	if {$vardas == "testinis"} {
		grid [ttk::button .t.t.l.f1.b1 -text "IŠTRINTI VISUS TESTINIUS SPRENDIMUS" -command "p_istrinti_testini_bandyma; destroy .t" -style mazaszalias.TButton -padding "5 5 5 5"] -column 0 -row [expr $r+1]
	}
}

proc p_calculate_grade {test_id try_id} {
	set collectable_points [db3 onecolumn {SELECT SUM(verte_taskais) FROM klausimai_testai WHERE testo_id=$test_id}]
	set collected_points [db3 onecolumn {SELECT CASE WHEN SUM(tsk) IS NULL THEN 0 ELSE SUM(tsk) END FROM bandymai_pasirinkimai WHERE bandymo_id=$try_id}]
	set grade_without_bonus [expr round($collected_points / $collectable_points * 10)]
	set bonus [db3 onecolumn {SELECT penalty_tsk FROM bandymai WHERE Id=$try_id}]
	set bonus [expr {$bonus} == {""} ? 0 : {$bonus}]
	return [expr $bonus > 0 ? min(10, $grade_without_bonus + $bonus) : max(1, $grade_without_bonus + $bonus)]
}

proc p_rodyti_kita_darba {kitas bandymo_id what} {
	destroy .t
	set pazymetas_testas [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymo_id}]
	if {$kitas == "kitas"} {
		set bandymo_id [p_next_try_id $bandymo_id $pazymetas_testas $what]
	} 
	if {$kitas == "ankstesnis"} {
		set bandymo_id [p_previous_try_id $bandymo_id $pazymetas_testas $what]
	}
	if {![info exists ::pazymeta_apklausa]} {
		set ::parodyti 0
		set ::gautitaskai ""
		set ::balu_uz_lt ""
		if {[info exists ::atvirukl_eilutes]} {
			unset ::atvirukl_eilutes
		}
		unset ::arlt
	}	
	p_tikrinti_pazymeta_testa $bandymo_id $what
}

#what = ungraded, graded, survey
proc p_tikrinti_pazymeta_testa {bandymo_id what} {
	if {$bandymo_id == 0} {
		return
	}
	#nustato testo tikrinimo lenteles pradzios duomenis, ploti, auksti ir kt.
	set pazymetas_testas [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymo_id}]
	set testopavad [db3 onecolumn {SELECT testo_pavad FROM testai WHERE Id=$pazymetas_testas}]
	if {![info exists ::parodyti]} {
		set ::parodyti 0
	}
	if {[info exists ::pazymeta_apklausa]} {
		set tekstas "Apklausos „$testopavad“ peržiūra"
	} else {
		set tekstas "Testo „$testopavad“ taisymas"
	}
	p_naujas_langas .t "Testų taisymas"
	grid propagate .t 1
	grid columnconfigure .t 0 -weight 98
	grid rowconfigure .t 1 -weight 96
	wm minsize .t 1100 670
	grid [ttk::label .t.pavad -text $tekstas] -column 0 -row 0 -sticky news
	grid [text .t.t -yscrollcommand {.t.scrollbar set} -xscrollcommand {.t.scrollx set} -background "white" -state disabled] -column 0 -row 1 -sticky news
	grid [scrollbar .t.scrollbar -command {.t.t yview} -orient vertical] -column 6 -row 1 -sticky news 
	grid [scrollbar .t.scrollx -command {.t.t xview} -orient horizontal] -column 0 -row 2 -sticky snwe
	ttk::label .t.t.l -text "" -background "white"
	.t.t window create 2.0 -window .t.t.l
	if {![info exists ::pazymeta_apklausa]} {
		p_taisymo_lentele .t.t.l $bandymo_id $what
	} else {
		p_apklausos_atsakymu_lentele .t.t.l $bandymo_id
	}
}

proc p_rodyti_pav {pav_id klausimas} {
	destroy .pav
	set paveiksliukas [db3 onecolumn {SELECT content FROM paveiksleliai WHERE Id=$pav_id}]
	image create photo p -data $paveiksliukas
	p_naujas_langas .pav "\"$klausimas\""
	grid [ttk::label .pav.pav -text "" -image p -padding "10 10" -compound left] -column 0 -row 0
}

#what = ungraded, graded, survey
proc p_taisymo_lentele {w bandymo_id what} {
#piesia testu tikrinimo lentele su visais klausimais, atsakymais ir kt.
	set maincolor "LightBlue2"
	set color1 "gray90"
	set color2 "seashell3"
	set color "LightSkyBlue1"
	set color3 "$::spalva"
	set wrap "240"
	set ::mokytojas_priskyre_mokinio_varda 0
	set ::laikinas_bandymo_id $bandymo_id
	if {![info exists ::arlt]} {
		set ::arlt ""
	}
	if {![info exists ::balu_uz_lt]} {
		set ::balu_uz_lt ""
	}
	if {![info exists ::tsk]} {
		set ::tsk ""
	}
	if {![info exists ::surinko_tsk]} {
		set ::surinko_tsk 0
	}
	if {![info exists ::roundpazymys]} {
		set ::roundpazymys 0
	}
	if {![info exists ::atvirukl_eilutes]} {
		set ::atvirukl_eilutes ""
	}
	if {![info exists ::atvpazymiodalis]} {
		set ::atvpazymiodalis 0
	}
	set ::atvpazymiodalis 0
	wm protocol .t WM_DELETE_WINDOW {
		destroy .t
		set ::parodyti 0
		set ::surinko_tsk 0
		set ::roundpazymys 0
		set ::atvpazymiodalis 0
		set ::balu_uz_lt ""
		set ::arlt ""
		set ::gautitaskai ""
		if {[info exists ::atvirukl_eilutes]} {
			unset ::atvirukl_eilutes
		}
		if {[info exists ::pazymetas_testas_n]} {
			unset ::pazymetas_testas_n
		}
		if {[info exists ::pazymetas_testas_i]} {
			unset ::pazymetas_testas_i
		}
		if {[info exists ::pazymeta_apklausa]} {
			unset ::pazymeta_apklausa
		}
		if {[info exists ::pazymetas_testas]} {
			unset ::pazymetas_testas
		}
		p_atimti_suteiktus_taskus $::laikinas_bandymo_id
	}
	set pazymetas_testas [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymo_id}]
	set mokid [db3 eval {SELECT mokinio_id FROM bandymai WHERE Id=$bandymo_id}]
	set ar_istaisyta [db3 eval {SELECT ar_istaisyta FROM bandymai WHERE Id=$bandymo_id}]
	set r 2
	set stulpeliai "KLAUSIMAS PAV \"MOKINIO ATSAKYMAI\" \"NEPARINKTI ATSAKYMAI\" \"AR TEISINGAI\" \"VERTĖ TAŠKAIS\" \"GAUTA TAŠKŲ\""
	foreach s $stulpeliai {
		lappend stulp_pavad [label $w.$r -text $s -background $color3 -font "ubuntu 10" -justify center]
		incr r
	}
	grid {*}$stulp_pavad -sticky news -padx 1 -pady 1 -row 0
	set pasirinkimai "Taip Ne \"Iš dalies\""
	set testo_klausimu_ids [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$pazymetas_testas}]
	set testo_klausimu_skaicius [db3 eval {SELECT COUNT(*) FROM klausimai_testai WHERE testo_id=$pazymetas_testas}]
	set atviru_klausimu_sk 0
	for {set i 0} {$i<=$testo_klausimu_skaicius} {incr i} {
		set klid [lindex $testo_klausimu_ids $i]
		set tipas [db3 onecolumn {SELECT tipas FROM klausimai WHERE Id=$klid}]
		if {$tipas == "atviras_kl"} {
			set atviru_klausimu_sk [expr $atviru_klausimu_sk + 1]
		}
	}
	set r 1
	set galimasurinkti ""
	#klausimų ir atsakymų piešimas į lentelę:
	foreach klid $testo_klausimu_ids {
		set cell_color [expr $r % 2 == 0 ? {$color2} : {$color1}]
		set mokatsakymai {}
		set nepatsakymai {}
		set taipne {}
		set ar {}
		set tverte {}
		set gauta {}
		set ::arteisingas$r ""
		set testo_klausimas [db3 onecolumn {SELECT kl FROM klausimai WHERE Id=$klid}]
		set pav_id [db3 onecolumn {SELECT pav_id FROM klausimai WHERE Id=$klid}]
		
		grid [ttk::label $w.l$r -text $testo_klausimas -wraplength $wrap -justify left -background $cell_color] -sticky news -padx 1 -pady 1 -column 0 -row $r
		set kltipas [db3 onecolumn {SELECT tipas FROM klausimai WHERE Id=$klid}]
		set verte [format "%.2f" [db3 eval {SELECT verte_taskais FROM klausimai_testai WHERE klausimo_id=$klid AND testo_id=$pazymetas_testas}]]
		
		set klausimo_pasirinktiats [db3 eval {SELECT atsakymo_tekstas FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id 
			WHERE bandymo_id=$bandymo_id AND klausimo_id=$klid AND ar_pasirinko=1}]
		set klausimo_pasirinktuats_ids [db3 eval {SELECT atsvar_id FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id 
			WHERE bandymo_id=$bandymo_id AND klausimo_id=$klid AND ar_pasirinko=1}]
		set klausimo_nepasirinktiats [db3 eval {SELECT atsakymo_tekstas FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id 
			WHERE bandymo_id=$bandymo_id AND klausimo_id=$klid AND ar_pasirinko=0}]
		set klausimo_nepasirinktuats_ids [db3 eval {SELECT atsvar_id FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id 
			WHERE bandymo_id=$bandymo_id AND klausimo_id=$klid AND ar_pasirinko=0}]

		if {$pav_id != ""} {
			grid [ttk::button $w.p$r -text "" -image prev16 -command "p_rodyti_pav $pav_id \"$testo_klausimas\""] -sticky news -padx 1 -pady 1 -column 1 -row $r
		} else {
			grid [ttk::label $w.p$r -text "" -background $cell_color] -sticky news -padx 1 -pady 1 -column 1 -row $r
		}
		if {$kltipas == "vienas_teisingas"} {
			set kiek_gavo [db3 onecolumn {SELECT SUM(tsk)
				FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id WHERE bandymo_id=$bandymo_id AND klausimo_id=$klid}]
			if {$kiek_gavo == ""} {
			    set kiek_gavo 0
			}
			set kiek_gavo [format "%.2f" $kiek_gavo]
			foreach at $klausimo_pasirinktuats_ids {
				set teisingas_ar_ne [db3 eval {SELECT CASE(ar_teisingas_var) WHEN 1 THEN "Taip" ELSE "Ne" END FROM atsakymuvariantai WHERE Id=$at}]
			}
			if {![info exists teisingas_ar_ne]} {
				set teisingas_ar_ne "Ne***"
			}
			lappend ar [ttk::label $w.a$r -text "$teisingas_ar_ne" -background $cell_color]
			lappend tverte [label $w.v$r -text "$verte" -background $cell_color -font "ubuntu 10"]
			lappend gauta [label $w.g$r -text "$kiek_gavo" -background $cell_color -font "ubuntu 10"]
			grid {*}$ar -padx 1 -pady 1 -column 4 -row $r -sticky news
			grid {*}$tverte -sticky news -padx 1 -pady 1 -column 5 -row $r
			grid {*}$gauta -sticky news -padx 1 -pady 1 -column 6 -row $r
			lappend ::gautitaskai $kiek_gavo
			lappend galimasurinkti $verte
		}
		
		if {$kltipas == "keli_teisingi"} {
			set kiek_gavo [db3 onecolumn {SELECT SUM(tsk)
				FROM bandymai_pasirinkimai JOIN atsakymuvariantai ON atsakymuvariantai.Id=bandymai_pasirinkimai.atsvar_id WHERE bandymo_id=$bandymo_id AND klausimo_id=$klid}]
			if {$kiek_gavo == ""} {
			    set kiek_gavo 0
			}
			set kiek_gavo [format "%.2f" $kiek_gavo]
			set arteisingi ""
			foreach at $klausimo_pasirinktuats_ids {
				lappend arteisingi [db3 eval {SELECT CASE(ar_teisingas_var) WHEN 1 THEN "Taip*" ELSE "Ne*" END FROM atsakymuvariantai WHERE Id=$at}]
			}
			lappend ar [ttk::label $w.a$r -text "$arteisingi" -background $cell_color]
			lappend tverte [label $w.v$r -text "$verte" -background $cell_color -font "ubuntu 10"]
			lappend gauta [label $w.g$r -text "$kiek_gavo" -background $cell_color -font "ubuntu 10"]
			grid {*}$ar -sticky news -padx 1 -pady 1 -column 4 -row $r
			grid {*}$tverte -sticky news -padx 1 -pady 1 -column 5 -row $r
			grid {*}$gauta -sticky news -padx 1 -pady 1 -column 6 -row $r
			lappend ::gautitaskai $kiek_gavo
			lappend galimasurinkti $verte
		}
		
		if {$kltipas == "atviras_kl"} {
			if {$ar_istaisyta == 1} {
				set kiek_gavo [format "%.2f" [db3 onecolumn {SELECT tsk FROM bandymai_pasirinkimai WHERE bandymo_id=$bandymo_id AND atsvar_id=$klausimo_pasirinktuats_ids}]]
				lappend ::atvpazymiodalis $kiek_gavo
				if {$kiek_gavo == $verte} {
					set ::arteisingas$r "Taip"
				}
				if {$kiek_gavo < $verte} {
					set ::arteisingas$r "Ne"
				}
				if {$kiek_gavo == [expr $verte/2]} {
					set ::arteisingas$r "Iš dalies"
				}
			} else {
				set kiek_gavo ""
			}
			lappend mokatsakymai [ttk::label $w.m$r -text "[join $klausimo_pasirinktiats]" -wraplength $wrap -justify left -background $cell_color]
			lappend nepatsakymai [ttk::label $w.n$r -text "-" -justify left -background $cell_color -style pilkas.TLabel]
			lappend tverte [label $w.v$r -text "$verte" -background $cell_color -font "ubuntu 10"]
			set bgc [expr {$kiek_gavo} == {""} ? {"salmon"} : {$cell_color}]
			lappend gauta [label $w.g$r -text "$kiek_gavo" -background $bgc -font "ubuntu 10"]
			lappend taipne [ttk::combobox $w.c$r -textvariable ::arteisingas$r -values $pasirinkimai -width 8]
			grid {*}$taipne -sticky news -padx 1 -pady 1 -column 4 -row $r
			grid {*}$tverte -sticky news -padx 1 -pady 1 -column 5 -row $r
			grid {*}$gauta -sticky news -padx 1 -pady 1 -column 6 -row $r
			bind $w.c$r <<ComboboxSelected>> "p_suteikti_taskus $w $r $verte $color2 $color1 $color $klausimo_pasirinktuats_ids $bandymo_id"
			lappend galimasurinkti $verte
		}
		
		if {$kltipas == "vienas_teisingas" || $kltipas == "keli_teisingi"} {
			lappend mokatsakymai [ttk::label $w.m$r -text "[join $klausimo_pasirinktiats {; }]" -wraplength $wrap -justify left -background $cell_color]
			lappend nepatsakymai [ttk::label $w.n$r -text "[join $klausimo_nepasirinktiats {; }]" -wraplength $wrap -justify left -background $cell_color -style pilkas.TLabel]
		}
		grid {*}$mokatsakymai -sticky news -padx 1 -pady 1 -column 2 -row $r
		grid {*}$nepatsakymai -sticky news -padx 1 -pady 1 -column 3 -row $r
		incr r
	}
	#pažymio skaičiavimas:
	set galimasurinkti [p_ladd $galimasurinkti]
	if {![info exists ::gautitaskai]} {
		set ::gautitaskai 0
	}
	if {$ar_istaisyta == 1} {
		set ::surinko_tsk [expr [p_ladd [lsearch -all -inline -not -exact $::gautitaskai {}]] + [p_ladd $::atvpazymiodalis]]
	} else {
		set ::surinko_tsk [p_ladd [lsearch -all -inline -not -exact $::gautitaskai {}]]
	}
	set ::roundpazymys [p_calculate_grade $pazymetas_testas $bandymo_id]
	#pazymio piešimas:
	set viso_tasku_eilutes_tekstas "\"\" \"\" \"\" \"\" \"VISO:\" \"$galimasurinkti\" \"$::surinko_tsk\""
	set i 0
	foreach v_tekstas $viso_tasku_eilutes_tekstas {
		lappend viso_eilute [label $w.viso$i -background $color -text $v_tekstas -font "ubuntu 10"]
		incr i
	}
	grid {*}$viso_eilute -sticky news -pady 1 -padx 1 -row $r
	incr r
	#lietuviskos raides:
	#tasku eilutes tekstas uzrasomas sitaip, kad visi langeliai toje eiluteje butu melyni
	
	if {$atviru_klausimu_sk == 0} {
		set ::balu_uz_lt 0
	} else {
		set lt_tasku_eilutes_tekstas "\"\" \"\" \"\" \"\" \"AR RAŠĖ \nLIETUVIŠKAI?\""
		set i 0
		foreach lt_tekstas $lt_tasku_eilutes_tekstas {
			lappend lt_tasku_eilute [ttk::label $w.lt$i -text $lt_tekstas -background $color]
			incr i
		}
		grid {*}$lt_tasku_eilute -sticky news -pady 1 -padx 1 -row $r
		if {$ar_istaisyta == 1 && $::arlt == ""} {
			set ::balu_uz_lt [db3 onecolumn {SELECT penalty_tsk FROM bandymai WHERE Id=$bandymo_id AND mokinio_id=$mokid}]
			set bgc $color
			if {$::balu_uz_lt == 1} {
				set ::arlt "Taip"
			}
			if {$::balu_uz_lt == 0} {
				set ::arlt "Iš dalies"
			}
			if {$::balu_uz_lt == -1} {
				set ::arlt "Ne"
			}
		} else {
			set bgc "salmon"
		}
		grid [ttk::combobox $w.tnlt -textvariable ::arlt -values $pasirinkimai -width 8] -sticky news -pady 1 -padx 1 -column 5 -row $r
		grid [label $w.balu_uz_lt -text $::balu_uz_lt -background $bgc -font "ubuntu 10"] -sticky news -pady 1 -padx 1 -column 6 -row $r
		bind $w.tnlt <<ComboboxSelected>> "p_tasku_priskyrimas_uz_lt $w $color2 $color1 $r $color $bandymo_id"
		incr r
	}
	set pazymio_eilutes_tekstas "\"\" \"\" \"\" \"\" \"\" \"PAŽYMYS:\" \"$::roundpazymys\""
	set i 0
	foreach p $pazymio_eilutes_tekstas {
		lappend pazymio_eilute [label $w.galut$i -background $color -text $p -font "ubuntu 10"]
		incr i
	}
	grid {*}$pazymio_eilute -sticky news -pady 1 -padx 1 -row $r
	incr r
	if {$ar_istaisyta == 1} {
		set issaugotas_pazymys [db3 eval {SELECT pazymys FROM bandymai WHERE Id=$bandymo_id AND mokinio_id=$mokid}]
		set issaugoto_pazymio_eilutes_tekstas "\"\" \"\" \"\" \"\" \"\" \"IŠSAUGOTAS \nPAŽYMYS:\" \"$issaugotas_pazymys\""
		set i 0
		foreach s $issaugoto_pazymio_eilutes_tekstas {
			lappend issaugoto_pazymio_eilute [label $w.saved$i -background $color3 -text $s -font "ubuntu 12 bold"]
		incr i
		}
		grid {*}$issaugoto_pazymio_eilute -sticky news -pady 1 -padx 1 -row $r
		incr r	
	}
	#mygtukai:
	grid [frame .t.t.l.f -background "white"] -column 0 -row $r -sticky news -columnspan 4 -pady 10
	grid [frame .t.t.l.f1 -background "white"] -column 4 -row $r -pady 10 -sticky news -rowspan 2 -columnspan 2
	set kitas_id [p_next_try_id $bandymo_id $pazymetas_testas $what]
	set buves_id [p_previous_try_id $bandymo_id $pazymetas_testas $what]
	if {$buves_id == ""} {
		set ankstesnis_state "disabled"
	} else {
		set ankstesnis_state "normal"
	}
	if {$kitas_id == ""} {
		set kitas_state "disabled"
	} else {
		set kitas_state "normal"
	}
	grid [ttk::button .t.t.l.f.buves -text "< ANKSTESNIS" -command "p_rodyti_kita_darba ankstesnis $bandymo_id $what" -state $ankstesnis_state -style mazaszalias.TButton -padding "5 12 5 12"] -column 0 -row $r -padx 1 -sticky e
	grid [ttk::button .t.t.l.f.kitas -text "KITAS >" -command "p_rodyti_kita_darba kitas $bandymo_id $what" -state $kitas_state -style mazaszalias.TButton -padding "5 12 5 12"] -column 1 -row $r -sticky w
	grid [ttk::button .t.t.l.f.kitakl -text "KITA KLASĖ" -command "p_rinktis_kita_klase_taisymui $pazymetas_testas $ar_istaisyta $what $bandymo_id" -style mazasraudonas.TButton -padding "5 12 5 12"] -column 2 -row $r -padx 1 -sticky e; incr r
	lassign [p_mokinio_informacija $mokid] vardas pavarde klase
	set data [db3 eval {SELECT data FROM bandymai WHERE Id=$bandymo_id}]
	set irasytas_vardas [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymo_id AND pavadinimas="įvestas vardas"}]
	set irasyta_pavarde [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymo_id AND pavadinimas="įvesta pavardė"}]
	set irasyta_klase [db3 onecolumn {SELECT reiksme FROM bandymai_options WHERE bandymo_id=$bandymo_id AND pavadinimas="įvesta klasė"}]
	set komanda_parodyt_mokiniui "set ::parodyti 1; p_parodyti_mokini $mokid $data [expr $r+1] \"$irasytas_vardas\" \"$irasyta_pavarde\" \"$irasyta_klase\" $bandymo_id"
	if {$ar_istaisyta == 1} {
		eval $komanda_parodyt_mokiniui
	} else {
		grid [ttk::button .t.t.l.f.kassprende -text "KAS SPRENDĖ TESTĄ?" -command $komanda_parodyt_mokiniui -style mazaszalias.TButton -padding "5 12 5 12"] -column 0 -row $r -pady 5 -columnspan 2
	}
	if {$vardas == "testinis"} {
		grid [ttk::button .t.t.l.f1.b1 -text "IŠTRINTI VISUS TESTINIUS SPRENDIMUS" -command "p_istrinti_testini_bandyma; destroy .t" -style mazaszalias.TButton -padding "5 5 5 5"] -column 0 -row [expr $r+1]
	}
	grid [ttk::button .t.t.l.f1.save -text "IŠSAUGOTI" -state disabled -image save_icon -compound right -command "p_ar_galima_saugoti_pazymi $mokid \"$irasytas_vardas\" \"$irasyta_pavarde\" $w $bandymo_id $what" -style mazaszalias.TButton -width 9] -column 0 -row [expr $r - 1]
}

proc p_rinktis_kita_klase_taisymui {pazymetas_testas ar_istaisyta what bandymo_id} {
	set klases [db3 eval {SELECT DISTINCT klase FROM klases JOIN mokiniai ON klases.Id=mokiniai.klases_id JOIN bandymai ON bandymai.mokinio_id=mokiniai.Id WHERE bandymai.testo_id=$pazymetas_testas AND bandymai.ar_istaisyta=$ar_istaisyta}]
	foreach klase $klases {
		lappend datos [db3 onecolumn {SELECT data FROM bandymai JOIN mokiniai ON bandymai.mokinio_id=mokiniai.Id JOIN klases ON klases.Id=mokiniai.klases_id WHERE bandymai.testo_id=$pazymetas_testas AND bandymai.ar_istaisyta=$ar_istaisyta AND klases.klase=$klase}]
	}
	set ::klase_taisymui ""
	p_naujas_langas .klase "Klasės"
	grid [ttk::frame .klase.kita -padding $::pad20 -style baltas.TFrame] -column 0 -row 0 -sticky news
	grid [ttk::combobox .klase.kita.c -textvariable ::klase_taisymui -values $klases -width 8] -pady 10 -padx 10 -column 0 -row 1
	grid [ttk::button .klase.kita.ok -text "Rinktis klasę" -command "p_pereiti_prie_klases_sprendimu .klase $bandymo_id $what \$::klase_taisymui $pazymetas_testas $ar_istaisyta" -style mazaszalias.TButton -padding "5 12 5 12"] -column 0 -row 2 -padx 10 -pady 10
}

proc p_pereiti_prie_klases_sprendimu {w bandymo_id what klase pazymetas_testas ar_istaisyta} {
	if {$::klase_taisymui == ""} {
		tk_messageBox -message "Neparinkta klasė." -parent $w
		return
	}
	destroy $w
	set klases_id [db3 onecolumn {SELECT Id FROM klases WHERE klase=$klase}]
	set bandymo_data [db3 onecolumn {SELECT data FROM bandymai JOIN mokiniai ON bandymai.mokinio_id=mokiniai.Id JOIN klases ON klases.Id=mokiniai.klases_id WHERE bandymai.testo_id=$pazymetas_testas AND bandymai.ar_istaisyta=$ar_istaisyta AND klases.klase=$klase}]
	set klases_sprendusiu_mokiniu_ids [db3 eval {SELECT mokinio_id FROM bandymai JOIN mokiniai ON mokiniai.Id=bandymai.mokinio_id WHERE testo_id=$pazymetas_testas AND ar_istaisyta=0 AND klases_id=$klases_id}]
	set pirmasis_mokinys_klaseje [lindex $klases_sprendusiu_mokiniu_ids 0]
	set kitas_id [db3 onecolumn {SELECT Id FROM bandymai WHERE mokinio_id=$pirmasis_mokinys_klaseje AND ar_istaisyta=0 AND testo_id=$pazymetas_testas}]
	if {$kitas_id == ""} {
		set band_id [db3 onecolumn {SELECT bandymai.Id FROM bandymai JOIN mokiniai ON bandymai.mokinio_id=mokiniai.Id WHERE data=$bandymo_data AND klases_id=$klases_id}]
		p_ar_tikrai "Šioje klasėje nėra neištaisytų darbų. Ar rodyti ištaisytus darbus?" "p_rodyti_kita_darba nekeisti $band_id $what"
	} else {
		p_rodyti_kita_darba nekeisti $kitas_id $what
	}
}

proc p_parodyti_mokini {mokid data r mvardas mpavarde mklase bandymo_id} {
#parodo, koks mokinys sprende dabar tikrinama testa
	lassign [p_mokinio_informacija $mokid] vardas pavarde klase
	set row [expr $r+2]
	if {$::parodyti == 1} {
		if {$mvardas == ""} {
			set tekstas "Sprendė: $vardas $pavarde, $klase klasė, $data"
		} else {
			if {$mvardas == $vardas && $mpavarde == $pavarde} {
				set tekstas "Sprendė: $vardas $pavarde, $klase klasė, $data"
			} else {
				set tekstas "Sprendė: $vardas $pavarde, $klase klasė, $data \nPasirašė kaip: $mvardas $mpavarde, $mklase klasė, $data"
				set w ".t.t.l"
				set mokinys ""
				set klases [db3 eval {SELECT klase FROM klases ORDER BY klase}]
				set mokiniai [db3 eval {SELECT pavarde || ' ' || vardas FROM mokiniai JOIN klases ON mokiniai.klases_id=klases.Id WHERE klases.klase=$klase AND esamas_ar_buves=1 ORDER BY pavarde}]
				grid [ttk::frame $w.mok -style baltas.TFrame] -column 0 -row $row -sticky news -columnspan 4; incr row
				grid [ttk::label $w.mok.kllbl -text "KLASĖ:" -style baltas.TLabel] -column 0 -row $row -pady 10
				grid [ttk::combobox $w.mok.comboklase -textvariable ::klase -width 5] -column 1 -row $row -padx 5 -pady 10
				$w.mok.comboklase configure -values $klases
				bind $w.mok.comboklase <<ComboboxSelected>> "p_perkurti_mokinius \$klase $w"
				grid [ttk::label $w.mok.moklbl -text "MOKINYS:" -style baltas.TLabel] -column 2 -row $row -pady 10
				grid [ttk::combobox $w.mok.combomokinys -textvariable ::mokinys -width 20] -column 3 -row $row -padx 5 -pady 10
				$w.mok.combomokinys configure -values $mokiniai
				bind $w.mok.combomokinys <<ComboboxSelected>> ""
				grid [ttk::button $w.mok.pakeisti -text "Pakeisti" -command "p_pakeisti_mokinio_id_teste \$klase \$mokinys $bandymo_id \"$mvardas\" \"$mpavarde\" \"$mklase\" $data" -style mazaszalias.TButton -padding "5 10 5 10"] -column 5 -row $row -pady 5
				set paaiskinimas "Kadangi mokinys įsirašė kitokį vardą pavardę nei jam pasiūlė kompiuteris testo atlikimo metu, parinkite tokį mokinį ir klasę, kaip mokinys pats pasirašė ir paspauskite mygtuką „Pakeisti“."
				grid [ttk::button $w.mok.info -text "" -image klaus24 -command "tk_messageBox -message \"$paaiskinimas\" -parent $w.mok" -style mazaszalias.TButton] -column 4 -row $row -pady 5 -padx 5; incr row
				grid [ttk::label $w.mok.tuscias -text "" -style baltas.TLabel -padding "0 0 0 30"] -column 0 -row $row
				setTooltip $w.mok.info "Informacija"
			}
		}
		grid [ttk::frame .t.t.l.txt -style baltas.TFrame] -column 0 -row $r -sticky news -columnspan 4; incr r
		grid [ttk::label .t.t.l.txt.l -text $tekstas -background "white" -wraplength 400] -column 0 -row $r -sticky w; incr r
		destroy .t.t.l.f.kassprende
	}
}

proc p_pakeisti_mokinio_id_teste {klase mokinys bandymo_id mvardas mpavarde mklase data} {
	set vardas [lindex $mokinys 1]
	set pavarde [lindex $mokinys 0]
	set mokid [db3 onecolumn {SELECT mokiniai.Id FROM mokiniai JOIN klases ON klases.Id=mokiniai.klases_id WHERE vardas=$vardas AND pavarde=$pavarde AND klase=$klase}]
	db3 eval "UPDATE bandymai_options SET reiksme='$klase' WHERE bandymo_id=$bandymo_id AND pavadinimas='mokinio klase'"
	db3 eval "UPDATE bandymai_options SET reiksme=$mokid WHERE bandymo_id=$bandymo_id AND pavadinimas='mokinio id'"
	db3 eval "UPDATE bandymai_options SET reiksme='$vardas' WHERE bandymo_id=$bandymo_id AND pavadinimas='mokinio vardas'"
	db3 eval "UPDATE bandymai_options SET reiksme='$pavarde' WHERE bandymo_id=$bandymo_id AND pavadinimas='mokinio pavarde'"
	db3 eval "UPDATE bandymai SET mokinio_id=$mokid WHERE Id=$bandymo_id"
	.t.t.l.txt.l configure -text "Sprendė: $vardas $pavarde, $klase klasė \nPasirašė kaip: $mvardas $mpavarde, $mklase klasė, $data"
	set ::klase ""
	set ::mokinys ""
	set ::mokytojas_priskyre_mokinio_varda 1
	set testoid [db3 onecolumn {SELECT testo_id FROM bandymai WHERE Id=$bandymo_id}]
	set testo_klausimu_ids [db3 eval {SELECT klausimo_id FROM klausimai_testai WHERE testo_id=$testoid}]
	set testo_klausimu_skaicius [db3 eval {SELECT COUNT(*) FROM klausimai_testai WHERE testo_id=$testoid}]
	set atviru_klausimu_sk 0
	for {set i 0} {$i<=$testo_klausimu_skaicius} {incr i} {
		set klid [lindex $testo_klausimu_ids $i]
		set tipas [db3 onecolumn {SELECT tipas FROM klausimai WHERE Id=$klid}]
		if {$tipas == "atviras_kl"} {
			set atviru_klausimu_sk [expr $atviru_klausimu_sk + 1]
		}
	}
	if {$atviru_klausimu_sk == 0 && $mokid != 0} {
		db3 eval {UPDATE bandymai SET pazymys=$::roundpazymys, ar_istaisyta=1 WHERE Id=$bandymo_id}
		tk_messageBox -message "Testas ištaisytas." -parent .t
	}
}

proc p_mokinio_informacija {mok_id} {
	return [db3 eval {SELECT vardas, pavarde, klase, klases_id, pc_id FROM mokiniai JOIN klases ON mokiniai.klases_id = klases.Id WHERE mokiniai.Id=$mok_id}]
}

proc p_ar_galima_saugoti_pazymi {mokid mvardas mpavarde w bandymo_id what} {
	lassign [p_mokinio_informacija $mokid] vardas pavarde klase
	if {$::mokytojas_priskyre_mokinio_varda == 1 || $mvardas == ""} {
		set ::mokytojas_priskyre_mokinio_varda 0
		p_issaugoti_pazymius $w $mokid $bandymo_id $what
		return
	}
	if {$mvardas == $vardas && $mpavarde == $pavarde} {
		p_issaugoti_pazymius $w $mokid $bandymo_id $what
		return
	}
	if {$vardas == "" || $pavarde == ""} {
		tk_messageBox -message "Nėra mokinio vardo ir pavardės. Priskirkite mokiniui vardą ir pavardę, o tuomet išsaugokite pažymį." -parent $w
		return
	}
	if {$mvardas != $vardas && $mpavarde != $pavarde} {
		tk_messageBox -message "Tikriausiai mokinys, sprendęs testą, sėdėjo ne prie savo kompiuterio. Pasitikrinkite jo vardą ir pavardę, o tuomet išsaugokite pažymį." -parent $w
	}
}

proc p_istrinti_testini_bandyma {} {
	set testiniu_mok_ids [db3 eval {SELECT Id FROM mokiniai WHERE vardas="testinis"}]
	foreach test_mok_id $testiniu_mok_ids {
		set b_id [db3 onecolumn {SELECT Id FROM bandymai WHERE mokinio_id=$test_mok_id}]
		if {$b_id != ""}  {
			lappend bandymo_ids $b_id
		}
	}
	foreach bandymo_id $bandymo_ids {
		db3 eval {DELETE FROM bandymai_options WHERE bandymo_id=$bandymo_id}
		db3 eval {DELETE FROM bandymai_pasirinkimai WHERE bandymo_id=$bandymo_id}
		db3 eval {DELETE FROM bandymai WHERE Id=$bandymo_id}
	}
}
