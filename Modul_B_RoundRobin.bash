#!/bin/bash
# shebang gibt an, welche shell das Skript bearbeiten soll
function func_SETenv() {   
	anzahlCOUNT=1
	runCOUNT=1
	debug="yes"    # Debugger um zu schauen was das Programm macht 
	neededTIMEmax=
	counter=1
	quantum2=0
	waitingtimeCOMPLETE=0
	waitingTIME=0
	neededtimeCOMPLETE=0
	neededtimeCASE=0
	test1=0
}

func_SETenv
clear

echo -e "Hier wird das Round Robin Verfahren simuliert\n\n"
# Anzahl der Prozesse definieren
read -p "Bitte geben Sie eine Ganzzahl für die Anzahl der Prozesse ein, die in der CPU abgearbeitet werden sollen: "  anz
echo -e "\nBitte Geben Sie die Laufzeit der Prozesse in ms an (Bitte nur Ganzzahlen):\n"        

# Werte in das Array einlesen
while [ ${#rtime[@]} -lt ${anz} ]   
do
	read -p "Prozess ${anzahlCOUNT}: " rtime[${anzahlCOUNT}]
	
	# Vergleicht Variable mit sich selbst, um zu schasuen ob sie ein Integer ist, ansonsten wird Eingabeaufforderung wiederholt
	# Fehlermeldung wird nicht auf dem Display angezeigt, ein auszugebender Datenstrom wird verworfen -> "&>/dev/null"
	if test "${rtime[${anzahlCOUNT}]}" -eq "${rtime[${anzahlCOUNT}]}" &>/dev/null
	then
		anzahlCOUNT=$(( ${anzahlCOUNT} + 1 ))
	else
		builtin unset rtime[${anzahlCOUNT}]
	fi
done
# Die Variablen "anz" und "anzahlCOUNT" werden gelöscht, da nicht mehr benötigt
builtin unset anz anzahlCOUNT
echo
# Zeitquantum wird einegeben -- wie viel zeit hat jeder Prozess in der CPU zu verfügung
read -p "Bitte geben Sie ein Zeitquantum in ms an (Bitte nur Ganzzahlen): " quantum

# Debugger wird nur ausgeführt, wenn er auf "yes" steht, ansonsten nicht
if [ "${debug}" = "yes" ]  
then
	echo -e "\n"
fi

for index in ${!rtime[@]}
do
	if [ "${debug}" = "yes" ]
	then
		echo "DEBUG: Laufzeit fuer Prozess ${index}: ${rtime[${index}]} ms"
		sleep 0.2
	fi
	# Die Werte werden an das Array openRuns übergeben
	openRUNS[${index}]=${rtime[${index}]}
done
# Die Variable index wird gelöscht, da nicht mehr benötigt
builtin unset index
echo
while [ "${#runcompleted[@]}" -ne "${#rtime[@]}" ]
do	
	# Es wird jeder Index im Array durchlaufen
	for index in ${!openRUNS[@]} 
	do 	
		
		# In openRUNS[${index}] wereden die neuen Laufzeiten gespeichert
		openRUNS[${index}]=$(( ${openRUNS[${index}]} - ${quantum} )) 
		
		
		if [ "${openRUNS[${index}]}" -ge ${quantum} ]
		then
			# quantum2 wird um quantum erhöht
			quantum2=$(( ${quantum} + ${quantum2}))
			
			if [ "${debug}" = "yes" ]
			then
				echo "DEBUG: openRUNS[${index}]=${openRUNS[${index}]}"
				sleep 0.1
			fi
		else	
			# Damit der Prozess terminiert
			if [[ "${openRUNS[${index}]}" -lt ${quantum} ]] && [[ ${openRUNS[${index}]} -gt 0 ]] 
			then
				
					
				quantum2=$(( ${quantum} + ${quantum2} - ${openRUNS[${index}]} ))
					        
				
				if [ "${debug}" = "yes" ]
				then
					echo "DEBUG: openRUNS[${index}]=${openRUNS[${index}]}"
					sleep 0.1
				fi
			else
				if [ "${runcompleted[${index}]}" != "yes" ]
				then	
					
					quantum2=$(( ${quantum} + ${quantum2} - ${openRUNS[${index}]} ))
					# Wie viele Zyklen braucht es, bis alle Prozesse in der CPU abgearbeitet wurden
					neededRUNS[${index}]=${runCOUNT}
					# Laufzeit der Prozesse wird berechnet
					neededTIME[${index}]=${quantum2}
					# Laufzeiten der Prozesse werden addiert 
					neededtimeCOMPLETE=$(( ${neededTIME[${index}]} + ${neededtimeCOMPLETE} ))
					# Wartezeit der Prozesse wird berechnet 
					waitingTIME[${index}]=$(( ${neededTIME[${index}]} - ${rtime[${index}]} ))
					# Wartezeiten der Prozesse werden addiert
					waitingtimeCOMPLETE=$(( ${waitingtimeCOMPLETE} + ${waitingTIME[${index}]} ))
					runcompleted[${index}]="yes"
				fi
			fi
		fi
	done
	# Nach jedem Durchlauf wird runCOUNT um 1 erhöht (counter)=$(( ${runCOUNT} + 1 ))
	runCOUNT=$(( ${runCOUNT} + 1 ))
done
echo -e "\n\nNun folgt eine tabellarische Auswertung der verabeiteten Prozesse, die zuvor eingegeben wurden:"
# Tabellarische Ausgabe der Auswertung, "printf" sorgt für eine formatierte Ausgabe
sleep 0.4
printf "\n\n%-7s\t%-17s\t%-12s\t%-17s\t%-19s\t%-14s\n" "Prozess" "CPU-Laufzeit (ms)" "Quantum (ms)" "Benoetigte Zyklen" "Gesamtlaufzeit (ms)" "Wartezeit (ms)"

for index in ${!runcompleted[@]}
do
		printf "%7d\t%17d\t%12d\t%17d\t%19d\t%14d\n" "${index}" "${rtime[${index}]}" "${quantum}" "${neededRUNS[${index}]}" "${neededTIME[${index}]}" "${waitingTIME[${index}]}"
done

# Berechnung der durchschnittlichen Laufzeit aller Prozesse
averageRUNTIME=$(( ${neededtimeCOMPLETE} / ${#rtime[@]} ))
# Berechnung der durchschnittlichen Wartezeit aller Prozesse
averageWAITINGTIME=$(( ${waitingtimeCOMPLETE} / ${#rtime[@]} ))
# Ausgabe der durchschnittlichen Laufzeit aller Prozesse
sleep 0.4
echo -e "\n\nDurchschnittliche Laufzeit der ${#rtime[@]} Prozesse: ${averageRUNTIME} ms\n\n"
# Ausgabe der durchschnittlichen Wartezeit aller Prozesse
sleep 0.4
echo -e "\nDurchschnittliche Wartezeit der ${#rtime[@]} Prozesse: ${averageWAITINGTIME} ms\n\n"
# "set +x" -> Debugger und Fehlersuche
set +x
# "exit 0" -> Code wurde erfolgreich ausgeführt
exit 0
#EOF












