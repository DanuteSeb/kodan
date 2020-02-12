Programa „Kodan“

Ši programa yra skirta mokytojams. Su ja galima atlikti įvairius dalykus: perkrauti ar išjungti mokinių kompiuterius, nusiųsti mokiniams reikalingus failus (pvz. užduotis), atlikti mokinių apklausą ir iškart gauti jų atsakymus, duoti mokiniams testą su įvairiais klausimais (atviro tipo, su keliais variantais ir kt.) ir iškart gauti mokinių atsakymus. Su šia programa taipogi galima įvykdyti įvairias komandas mokinių kompiuteriuose, pvz. galima įdiegti kokią nors programą bei daug kitų dalykų.

REIKALAVIMAI:
GNU/Linux operacinė sistema Debian pagrindu, pvz. Ubuntu.
Mokytojo kompiuteris, kurio naudotojo vardas yra mokytoja.
Mokinių kompiuteriai, kurie turi du naudotojus: mokytoja (administratorius) ir mokinys (paprastas naudotojas).

Norint, kad programa funkcionuotų tinkamai, BŪTINAI reikia atlikti keletą veiksmų (jei bent vienas veiksmas bus praleistas ir neatliktas, programa gali visiškai arba dalinai neveikti).
Šiuos veiksmus reikės atlikti TIK VIENĄ KARTĄ. (Jeigu mokytojo kompiuterio ar mokinių kompiuterių OS įdiegsite iš naujo, tuos veiksmus ir vėl reikės pakartoti). 

Štai veiksmai, kuriuos reikia atlikti (eiliškumo tvarka YRA LABAI SVARBI!):

1. Įdiegti į MOKYTOJO IR į MOKINIŲ kompiuterius programas ssh, sqlite3, libsqlite3-tcl, wish ir sqliteman (sqliteman – TIK MOKYTOJO KOMPIUTERYJE). Kaip tai atlikti: 
1 variantas: Nueiti į aplanką Programos_failai ir paleisti ten esantį failą install.sh (atvėrus terminalą, jame parašyti sh install.sh ir spausti ENTER) – ir tai atlikti visuose kompiuteriuose.
2 variantas: VISUOSE paminėtuose kompiuteriuose su administratoriaus teisėmis (t. y. su naudotoju „mokytoja“) reikia atverti terminalą. Atsidarius terminalo langui,

MOKYTOJO kompiuteryje rašyti:

sudo apt-get install ssh sqlite3 libsqlite3-tcl wish sqliteman tcllib -y

MOKINIO kompiuteryje rašyti:

sudo apt-get install ssh sqlite3 libsqlite3-tcl wish tcllib -y

Įrašius šią komandą nuspausti klavišą ENTER.

2. Visuose MOKINIŲ (NE MOKYTOJO!) kompiuteriuose su administratoriaus teisėmis terminale parašyti:

sudo visudo

Spausti ENTER. Atsivers langas, kuriame yra parašyta kažkiek teksto. Reikia nueuti į pačią teksto pabaigą, sukurti dvi naujas eilutes ir jose parašyti:

mokytoja ALL=NOPASSWD: ALL
mokytoja ALL= (mokinys) NOPASSWD:ALL

Sukūrus šias eilutes, išsaugojame failą šitaip: spaudžiame CTRL+X, po to Y, po to ENTER. (Ši komanda padaro taip, jog kaskart atliekant ką nors su mokinių kompiuteriais (pvz. siunčiant failus) nereikėtų įvedinėti mokytojo slaptažodžio).

3. Susižinoti visų savo mokinių kompiuterių IP adresus. Tai galima sužinoti terminale įrašius komandą:

ifconfig

Spausti ENTER. Terminale parodys to kompiuterio IP adresą, kuriame ši komanda buvo įvesta. Tuos IP adresus reikės vėliau suvesti į programą.

4. MOKYTOJO kompiuteryje, kai yra ĮJUNGTI VISI mokinių kompiuteriai, terminale parašyti:

ssh-keygen

Tuomet spausti ENTER 3 kartus

ssh-copy-id -i ~/.ssh/id_rsa.pub mokytoja@mokinioIPadresas

PASTABA: vietoje "mokinioIPadresas" įrašyti bet kurio mokinio kompiuterio IP adresą.

Spausti ENTER

Atlikus šiuos veiksmus, kompiuteris Jūsų paklaus, ar tikrai norite jungtis prie mokinio kompiuterio. Terminale reikia parašyti „yes“ ir nuspausti ENTER. Nuspaudus ENTER, įvesti administratoriaus (mokytojos) slaptažodį ir vėl spausti ENTER.
 
Kiek yra kompiuterių klasėje, tiek kartų reikės pakartoti antrąją komandą (ssh-copy-id -i ~/.ssh/id_rsa.pub mokytoja@mokinioIPadresas) – tik kiekvieną kartą reikės įvesti vis kitą mokinio IP adresą. Po kiekvieno šios komandos įvykdymo reikės parašyti „yes“, paspausti ENTER, įvesti slaptažodį, paspausti ENTER).

5. Įsitikinkite, kad visi pavyksta prisijungti prie visų mokinio kompiuterių.
Atlikus 4 punktą su visais mokinių kompiuterių IP adresais, MOKYTOJO kompiuterio terminale parašyti:

ssh mokytoja@mokinioIPadresas

Spausti ENTER.

Tuomet terminalo paskutinės eilutės pradžioje turėtumėte pamatyti mokinio kompiuterio pavadinimą (pvz.: mokytoja@mokinys01). Jeigu taip yra, tuomet prisijungimas įvyko sėkmingai. Atsijunkite nuo mokinio kompiuterio terminale nuspaudę CTRL+C.

Pakartokite tuos pačius veiksmus iš naujo: išmėginkite tai su visais likusiais mokinių kompiuteriais.

Jeigu prie kurio nors mokinio kompiuterio prisijungti nepavyksta, pamėginkite atlikti 4 punktą iš naujo tiems kompiuteriams, prie kurių nepavyksta prisijungti.

6. KAIP PALEISTI PROGRAMĄ:
Šios programos paleidžiamasis failas vadinasi Kodan.tcl. Pamėginkite paleisti programą tiesiog nuspaudę ant jos du ar vieną kartą su pele. Jeigu atsiveria ne programa, o tekstų redaktorius, įsitikinkite, kad šis failas tikrai yra vykdomasis (kaip tai patiktinti – reikia nuspausti ant failo dešinįjį pelės klavišą ir, pasirinkus jo savybes (ar ypatybes) ieškoti, kur galima pažymėti paukšteliu, kad šis failas būtų vykdomasis).
Jeigu paukštelis yra pažymėtas, bet programa vis vien atidaro tik teksto redaktorių, tuomet šią programą reikia paleisti per terminalą. Kaip tai padaryti: atverkite terminalą tame aplanke, kuriame yra šis paleidžiamasis failas ir rašykite:

./Kodan.tcl

Spauskite ENTER.

Jeigu nemokate atverti terminalo būtent tame aplanke, kuriame esate, spauskite dešinįjį pelės klavišą ir pasirinkite „Atverti Terminalą čia“ (angl. „Open Terminal here“).


