#!/bin/bash

# Auf Abhängigkeiten prüfen
if [ -z "$(type -p jq)" ]; then
 echo "Das Programm jq ist nicht installiert. Bitte erst installieren."
 exit 1
fi

# ** Funktionen **
configcheck() {
 if [ -e "./config/cloudybm.cfg" ]; then
  source "./config/cloudybm.cfg"
 else
  echo "Datei ./config/cloudybm.cfg existiert nicht."
  echo "Programm wird abgebrochen."
  exit 1
 fi
}
servercheck() {
 configcheck
 unset serverreturn
 if [ -n "$serveruser" -a -n "$servername" -a -n "$serverport" -a -n "$serverdir" ]; then
  serverdir="${serverdir%/}"
  clientdir="${clientdir%/}"
  echo "Verfügbarkeit des Servers wird überprüft ..."
  ping -c 1 "${servername}" &>/dev/null
  serverreturn="$?"
 else
  echo "config-Datei unvollständig. Skript wird abgebrochen."
  exit 1
 fi
}
usage() {
cat <<EOU

Konvertiert Bookmarks aus einer .json-Datei in das cloudybm-Format.

Syntax: $0 [-h]
        $0 [-i FILE]
        $0 -s

Beispiele:

1. Konvertierung und anschließende Synchronisation:
   $0 -si /path/to/bmfile.json

Optionen:

   -h

	ruft diese Hilfe auf.

   -i FILE

	Mit dieser Option wird der Inhalt einer bestehenden .json-Datei konvertiert.
	Diese Option benötigt zusätzlich die Angabe von Pfad und Dateinamen der auszuwertenden
	.json-Datei.

   -I

	Fragt beim Zusammenführen von Bookmark-Dateien vor der Neuaufnahme einer URI nach.
	Benötigt die Optionen -m

   -m

	Fügt neue Lesezeichen in die bestehende bookmarks.txt ein.

   -s

	Synchronisiert die Datei ./bookmarks.txt mit Server und lokalem Verzeichnis.
	Eine eventuell bestehende bookmarks.txt wird dabei ersetzt.

Das Exportieren von Bookmarks in eine .json-Datei (mit dem Browser) und das anschließende Konvertieren
mit bmconverter.sh wurde mit Dateien folgender Browser erfolgreich getestet:
Firefox

EOU
}

pathtoconv="$(dirname $(readlink -f ${0}))"
cd "$pathtoconv"

while getopts hi:Ims opt; do
 case "$opt" in
  h) # Hilfe
     usage
     exit
  ;;
  i) # Inputfile
     inputfile="$OPTARG"
     while [ "$(jq . "$inputfile" &>/dev/null; echo "$?")" != 0 ]; do
      read -p "Bitte eine gültige json-Datei mit einen absoluten Pfad oder relativ zu ${pathtoconv} angeben: " inputfile
     done
  ;;
  I) # Interactive
     interact="yes"
  ;;
  m) # Merging bookmark files
     merging="yes"
  ;;
  s) bmsync="yes"
  ;;
 esac
done

# ** Erstellung der Datei bookmarks.txt (Option -i) **
# Mögliche Fehler führen zum Abbruch des Skriptes.
if [ -n "$inputfile" ]; then

 if [ ! -e "${pathtoconv}/config/uriencode.cfg" ]; then
  notify-send Fehler "Datei ${pathtoconv}/config/uriencode.cfg existiert nicht.\nSkript wird abgebrochen"
  logger -s --id=$$ "Datei ${pathtoconv}/config/uriencode.cfg existiert nicht. Skript wird abgebrochen"
  exit 1
 fi

 [ -e ./bookmarks.txt ] && read -p "Es existiert bereits eine Datei bookmarks.txt im Erstellungsordner ${PWD}. Datei wird überschrieben. Weiter mit [ENTER]. Abbruch mit [STRG]+[C]."
 # Erstellung nur bei mindestens einem gefundenen Schlüssel(n) mit der Bezeichnung uri
 if [ -n "$(jq 'recurse | objects | has("uri")' "$inputfile" | grep true)" ]; then
  echo "Lesezeichen werden jetzt konvertiert ..."
  jq -r '.. | objects | select(has("uri") and .uri != null) | "\(.tags // "")\t\(.title // "")\t\(.uri // "")"' "$inputfile" >./bookmarks.txt
  # URI-Encoding
  keysanddesc="$(cut -f1,2 ./bookmarks.txt)"
  bmuri="$(cut -f3 ./bookmarks.txt | sed -f "${pathtoconv}/config/uriencode.cfg")"
  paste -d'\t' <(echo "$keysanddesc") <(echo "$bmuri") >./bookmarks.txt
 else
  echo "Datei ${inputfile} enthält keinen Schlüssel mit der Bezeichnung uri."
  echo "Datei bookmarks.txt konnte nicht erstellt werden."
  exit 1
 fi

fi

# ** Neue Lesezeichen werden einer bestehenden bookmarks.txt hinzugefügt (Option -m) **
# Mögliche Fehler führen nicht zum Abbruch des Skriptes sondern werden später ausgewertet (mergeproc).
if [ "$merging" == "yes" ]; then

 servercheck
 if [ "$serverreturn" == 0 ]; then
  echo "${servername} ist erreichbar."
  echo "Bookmark-Dateien werden zusammengeführt ..."
  bmorig=$(mktemp)
  [ "$interact" == "yes" ] && term=$(tty)
  scp -pP "$serverport" "${serveruser}@${servername}":"\"${serverdir}\"/bookmarks.txt" "$bmorig"
  scpdownexit="$?"
  if [ "$scpdownexit" == 0 ]; then
   echo "bookmarks.txt erfolgreich heruntergeladen."
   while IFS='\n' read -r bmline; do
    newlink="$(echo "$bmline" | cut -f3)"
    checklink="$(grep -P '\t'"${newlink}"'($|\t)' "$bmorig")"
    if [ -n "$checklink" ]; then
     echo "URI ${newlink} vorhanden."
    else
     if [ "$interact" == "yes" ]; then
      while true
       do
        read -p "Soll die URI ${newlink} neu aufgenommen werden? (j/n) " askfornewlink <"$term"
        case "$askfornewlink" in
      j|J|"") echo "$bmline" >>"$bmorig"
              echo "URI wurde neu aufgenommen."
            break
           ;;
         n|N) echo "URI wurde nicht aufgenommen."
            break
           ;;
           *) echo "Fehlerhafte Eingabe!"
           ;;
        esac
      done
     else
      echo "$bmline" >>"$bmorig"
      echo "URI ${newlink} neu aufgenommen."
     fi
    fi
   done <./bookmarks.txt
   cp -f "$bmorig" ./bookmarks.txt && mergeproc="0"
  else
   mergeproc="$scpdownexit"
   echo "bookmarks.txt konnte nicht vom Server heruntergeladen werden (${mergeproc}). Zusammenführen der Dateien nicht möglich."
  fi
 else
  mergeproc="$serverreturn"
  echo "${servername} ist nicht erreichbar (${mergeproc}). Zusammenführen der Dateien nicht möglich."
 fi
fi

# ** Anlegen der Datei bookmarks.txt auf Server und im lokalen Bookmark-Ordner (Option -s) **
if [ "$bmsync" == "yes" ]; then

 if [ "$merging" == "yes" -a "$mergeproc" != "0" ]; then

  echo "Es gab einen Fehler bei bei einem vorherigen Prozess."
  echo "Datei wird nicht mit dem Server synchronisiert."

 else

  if [ -e ./bookmarks.txt ]; then

   echo "Die Datei bookmarks.txt wird jetzt auf den Server kopiert und im lokalen Bookmark-Ordner angelegt ..."

   # ** Server **
   echo "* Server *"
   servercheck
   if [ "$serverreturn" == 0 ]; then
    echo "${servername} ist erreichbar."
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
    echo "${servername} ist nicht erreichbar."
   fi

   # ** Lokal **
   echo "* Lokal *"
   if [ ! -d "$clientdir" ]; then
    mkdir -pv "$clientdir"
    echo -e "Wichtiger Hinweis:\nDies ist eine Kopie der bookmarks.txt vom Server. Die Datei wird nur zum Auslesen genutzt und nur in der Richtung Server => Lokal synchronisiert. Bei Änderungen bitte die Datei auf dem Server modifizieren.\nManuelle Änderungen an der Datei in diesem Ordner werden nicht berücksichtigt\nund ggf. beim Hinzufügen eines neuen Lesezeichens überschrieben." >"${clientdir}/README"
   fi
   # Schreibrechte werden erteilt.
   [ -e "${clientdir}/bookmarks.txt" -a ! -w "${clientdir}/bookmarks.txt" ] && chmod -v +w "${clientdir}/bookmarks.txt"
   mv -v ./bookmarks.txt "${clientdir}/bookmarks.txt"
   # Schreibrechte werden wieder entzogen.
   [ -w "${clientdir}/bookmarks.txt" ] && chmod -v -w "${clientdir}/bookmarks.txt"

  else

   echo "Keine bookmarks.txt zum Synchronisieren in ${PWD} gefunden."

  fi

 fi

fi

# Ggf. befindet sich die Datei bookmarks.txt ohne Synchronisation noch im cloudybm-Verzeichnis.
[ -e ./bookmarks.txt ] && echo "bookmarks.txt befindet sich zur weiteren manuellen Bearbeitung im lokalen Ordner ${PWD}."
