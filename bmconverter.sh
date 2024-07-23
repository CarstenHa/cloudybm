#!/bin/bash

# ** Funktionen **
sendtoserver() {
if [ -e "./config/cloudybm.cfg" ]; then

 source "./config/cloudybm.cfg"
 if [ -n "$serveruser" -a -n "$servername" -a -n "$serverport" -a -n "$serverdir" ]; then
 
  serverdir="${serverdir%/}"
  clientdir="${clientdir%/}"

  echo "Verfügbarkeit des Servers wird überprüft ..."
  ping -c 1 "${servername}" &>/dev/null
  serverreturn="$?"

  if [ "$serverreturn" == 0 ]; then
   echo "${0}: ${servername} ist erreichbar." | tee >(logger --id=$$)
   [ -z "$(ssh-add -l | grep "$(ssh-keygen -lf "$serverkey" | cut -f2 -d' ')")" -a -n "$serverkey" ] && ssh-add "$serverkey"
   echo "Überprüfung auf Server ..."
   ssh -p "$serverport" "${serveruser}@${servername}" '
                                                       [ ! -d "'"$serverdir"'" ] && mkdir -pv "'"$serverdir"'" || echo "Verzeichnis '"$serverdir"' existiert."
                                                       [ -e "'"$serverdir"'/bookmarks.txt" ] && cp -vf "'"$serverdir"'/bookmarks.txt" "'"$serverdir"'/bookmarks.bak"
                                                      '
   echo "Datei bookmarks.txt wird auf Server kopiert ..."
   scp -pP "$serverport" "./bookmarks.txt" "${serveruser}@${servername}":"\"${serverdir}\"/"
   scpexit="$?"
   if [ "$scpexit" == 0 ]; then
    echo "bookmarks.txt erfolgreich auf Server kopiert."
   else
    echo "bookmarks.txt konnte nicht auf Server kopiert werden. Skript wird abgebrochen."
    exit "$scpexit"
   fi
  else
   echo "${0}: ${servername} ist nicht erreichbar." | tee >(logger --id=$$)
  fi

 else
  echo "config-Datei unvollständig. Skript wird abgebrochen."
  exit 1
 fi

else

 echo "Datei ./config/cloudybm.cfg existiert nicht."
 echo "Programm wird abgebrochen."
 exit 1

fi
}
usage() {
cat <<EOU

Konvertiert Bookmarks aus einer .json-Datei in das cloudybm-Format.
bookmarks.txt wird erstellt und kann anschließend auf den Server kopiert
und im lokalen Bookmark-Ordner abgelegt werden.

Syntax: $0 [-h]
        $0 [-i FILE]

Optionen:

   -h

	ruft diese Hilfe auf.

   -i FILE

	Angabe von Pfad und Dateinamen der auszuwertenden .json-Datei.

Das Exportieren von Bookmarks in eine .json-Datei und das anschließende Konvertieren mit
bmconverter.sh wurde mit Dateien folgender Browser erfolgreich getestet:
Firefox

EOU
}

while getopts hi: opt; do
 case "$opt" in
  h) # Hilfe
     usage
     exit
  ;;
  i) # Inputfile
     inputfile="$OPTARG"
  ;;
 esac
done

# ** Überprüfungen **
if [ -z "$(type -p jq)" ]; then
 echo "Das Programm jq ist nicht installiert. Bitte erst installieren."
 exit 1
fi

pathtoconv="$(dirname $(readlink -f ${0}))"
cd "$pathtoconv"

if [ ! -e "${pathtoconv}/config/uriencode.cfg" ]; then
 notify-send Fehler "Datei ${pathtoconv}/config/uriencode.cfg existiert nicht.\nSkript wird abgebrochen"
 logger -s --id=$$ "Datei ${pathtoconv}/config/uriencode.cfg existiert nicht. Skript wird abgebrochen"
 exit 1
fi

[ -e ./bookmarks.txt ] && read -p "Es existiert bereits eine Datei bookmarks.txt im Erstellungsordner ${PWD}. Datei wird überschrieben. Weiter mit [ENTER]. Abbruch mit [STRG]+[C]."

while [ "$(jq . "$inputfile" &>/dev/null; echo "$?")" != 0 ]; do
 read -p "Bitte eine gültige json-Datei angeben: " inputfile
done

# ** Erstellung der Datei bookmarks.txt bei gefundenen Schlüssel(n) mit der Bezeichnung uri **
if [ -n "$(jq 'recurse | objects | has("uri")' "$inputfile" | grep true)" ]; then
 jq -r '.. | objects | select(has("uri") and .uri != null) | "\(.tags // "")\t\(.title // "")\t\(.uri // "")"' "$inputfile" >./bookmarks.txt
 keysanddesc="$(cut -f1,2 ./bookmarks.txt)"
 bmuri="$(cut -f3 ./bookmarks.txt | sed -f "${pathtoconv}/config/uriencode.cfg")"
 paste -d'\t' <(echo "$keysanddesc") <(echo "$bmuri") >./bookmarks.txt
 asksend="yes"
else
 echo "Datei ${inputfile} enthält keinen Schlüssel mit der Bezeichnung uri."
 echo "Datei bookmarks.txt konnte nicht erstellt werden."
 exit 1
fi

# ** Anlegen der Datei bookmarks.txt auf Server und im lokalen Bookmark-Ordner **
if [ "$asksend" == "yes" ]; then
 while true
  do
   echo "Die Datei bookmarks.txt kann jetzt auf den Server und im lokalen Bookmark-Ordner angelegt werden."
   read -p "Soll die Datei jetzt verteilt werden? (j/n) " gotoserver
    case "$gotoserver" in
      j) # ** Server **
         echo -e "\n*** Server ***"
         sendtoserver
         # ** Lokal **
         echo -e "\n*** Lokal ***"
         if [ ! -d "$clientdir" ]; then
          mkdir -pv "$clientdir"
          echo -e "Wichtiger Hinweis:\nDies ist eine Kopie der bookmarks.txt vom Server. Die Datei wird nur zum Auslesen genutzt und nur in der Richtung Server => Lokal synchronisiert. Bei Änderungen bitte die Datei auf dem Server modifizieren.\nManuelle Änderungen an der Datei in diesem Ordner werden nicht berücksichtigt\nund ggf. beim Hinzufügen eines neuen Lesezeichens überschrieben." >"${clientdir}/README"
         fi
         # Schreibrechte werden erteilt.
         [ -e "${clientdir}/bookmarks.txt" -a ! -w "${clientdir}/bookmarks.txt" ] && chmod -v +w "${clientdir}/bookmarks.txt"
         mv -iv ./bookmarks.txt "${clientdir}/bookmarks.txt"
         # Schreibrechte werden wieder entzogen.
         [ -w "${clientdir}/bookmarks.txt" ] && chmod -v -w "${clientdir}/bookmarks.txt"
         break
         ;;
      n) echo "Neue bookmarks.txt wurde nicht auf den Server kopiert und liegt mit Schreibrechten im lokalen Ordner ${PWD}."
         break
         ;;
      *) echo "Fehlerhafte Eingabe!"
         ;;
    esac
 done
fi

