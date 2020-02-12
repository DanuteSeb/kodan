#!/usr/bin/tclsh
set dabar [clock format [clock seconds] -format {%Y-%m-%d_%H:%M:%S}]

exec sh -c "mv /home/mokytoja/mokiniu_failai /home/mokytoja/mokiniu_failai_back_$dabar"
exec sh -c "mkdir -p /home/mokytoja/mokiniu_failai"
cd "/home/mokytoja/mokiniu_failai_back_$dabar"
set klases [exec ls -r]

foreach kl $klases {
	#regexp išskaido kintamąjį į norimas dalis. pvz šičia aš kintamojo varde ieškau raidžių, po to skaičių, po to vėl raidžių ir išskaidau į 3 dalis:
	regexp {([a-zA-Z]*)([0-9]+)([a-zA-Z]*)} $kl pavad raides skaicius kita
	if {![info exists pavad]} {
		set nkl $kl
	} else {
		set nskaicius [expr $skaicius+1]
		set nkl $raides$nskaicius$kita
	} 
	
	exec cp -r $kl "/home/mokytoja/mokiniu_failai/$nkl"
	#puts "$kl -> $nkl"
}

