#!/bin/bash

progname="cloudybm"
cd "$(dirname $0)"

usage() {
cat <<EOU

Installiert/Deinstalliert ${progname} 
Zielverzeichnis ist ein lokales PATH-Verzeichnis.
Ohne Angabe einer Option wird $progname installiert.

Syntax: $progname [-h] [-u]

Optionen:

   -h

	ruft diese Hilfe auf.

   -u

	Deinstalliert $progname
	Entfernt nur die Symlinks aus den Verzeichnissen.
	Das Repository wird nicht entfernt.

EOU
}

while getopts hu opt
do
   case $opt in
       h) usage
          exit
       ;;
       u) # uninstall
          find ~/.local/bin ~/bin -type l \( -name "searchbookmark" -o -name "newbookmark" \) -exec rm -vi {} \;
          find ~/.local/share/icons/hicolor -type l \( -name "mybookmarks.0.svg" -o -name "bookmark_add.0.svg" \) -exec rm -vi {} \;
          find ~/.local/share/applications -type l \( -name "searchbookmark.desktop" -o -name "newbookmark.desktop" \) -exec rm -vi {} \;
          exit
       ;;
   esac
done

# Abhängigkeiten werden ggf. installiert.
echo "Abhängigkeiten werden geprüft ..."
if [ -z "$(type -p zenity)" ]; then
 echo "Zenity wurde nicht gefunden und wird jetzt installiert ..."
 sudo apt install zenity
fi
if [ -z "$(type -p yad)" ]; then
 echo "Yad wurde nicht gefundenund wird jetzt installiert ..."
 sudo apt install yad
fi
if [ -z "$(type -p ssh-askpass)" ]; then
 echo -e "HINWEIS:\nssh-askpass ist nicht installiert. Kann installiert werden mit:\nsudo apt install ssh-askpass\noder:\nsudo apt install ssh-askpass-gnome"
fi

OLDIFS="$IFS"
IFS=':'
for dir in $PATH; do
 if [ "$dir" == "${HOME}/.local/bin" ]; then
  installdir="${HOME}/.local/bin"
  break
 elif [ "$dir" == "${HOME}/bin" ]; then
  installdir="${HOME}/bin"
  break
 fi
done
IFS="$OLDIFS"

if [ ! -d "${HOME}/.local/share/icons" ]; then
 echo "Verzeichnis ${HOME}/.local/share/icons existiert nicht. Skript wird abgebrochen."
 exit 1
fi
if [ ! -d "${HOME}/.local/share/applications" ]; then
 echo "Verzeichnis ${HOME}/.local/share/applications existiert nicht. Skript wird abgebrochen."
 exit 1
fi

echo "Dieses Skript installiert:"
echo "1. cloudybm auf Server."
echo "2. ${progname}-Programmdateien in: ${installdir}"
echo "3. Icons in Unterordner von: ${HOME}/.local/share/icons/hicolor/"
echo "4. .desktop-Dateien in: ${HOME}/.local/share/applications/"
echo "Für die Punkte 2-4 werden ausschließlich Symlinks angelegt."
read -p "Weiter mit [ENTER]. Abbruch mit [STRG]+[C]"

# cloudybm auf Server kopieren und Lesezeichen-Verzeichnis auf Server ggf. erstellen.
if [ -e "./config/cloudybm.cfg" ]; then

 source "./config/cloudybm.cfg"
 if [ -n "$serveruser" -a -n "$servername" -a -n "$serverport" -a -n "$cloudybmdir" -a -n "$serverdir" ]; then

  echo "Verfügbarkeit des Rechners wird überprüft ..."
  ping -c 1 "${servername}" &>/dev/null
  serverreturn="$?"

  if [ "$serverreturn" == 0 ]; then
   echo "${0}: ${servername} ist erreichbar." | tee >(logger --id=$$)
   [ -z "$(ssh-add -l | grep "$(ssh-keygen -lf "$serverkey" | cut -f2 -d' ')")" -a -n "$serverkey" ] && ssh-add "$serverkey"
   ssh -p "$serverport" "${serveruser}@${servername}" '[ ! -d "'"$serverdir"'" ] && mkdir -pv '"$serverdir"' || echo "Verzeichnis '"$serverdir"' existiert bereits."'
   scp -pP "$serverport" "./cloudybm/" "${serveruser}@${servername}:${cloudybmdir}/"
   scpexit="$?"
   if [ "$scpexit" == 0 ]; then
    echo "cloudybm erfolgreich auf Server kopiert."
   else
    echo "cloudybm konnte nicht auf Server kopiert werden. Skript wird abgebrochen."
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

# Symbolische Links der Skripte anlegen.
ln -vis "${PWD}/searchbookmark" "${installdir}/searchbookmark"
ln -vis "${PWD}/newbookmark" "${installdir}/newbookmark"

# Ordner für Icons ggf. anlegen.
[ ! -d "${HOME}/.local/share/icons/hicolor/16x16/apps" ] && mkdir -pv "${HOME}/.local/share/icons/hicolor/16x16/apps"
[ ! -d "${HOME}/.local/share/icons/hicolor/32x32/apps" ] && mkdir -pv "${HOME}/.local/share/icons/hicolor/32x32/apps"
[ ! -d "${HOME}/.local/share/icons/hicolor/48x48/apps" ] && mkdir -pv "${HOME}/.local/share/icons/hicolor/48x48/apps"
[ ! -d "${HOME}/.local/share/icons/hicolor/256x256/apps" ] && mkdir -pv "${HOME}/.local/share/icons/hicolor/256x256/apps"

# Symbolische Links der Icons anlegen.
find hicolor/ -type f \( -name mybookmarks.0.svg -or -name bookmark_add.0.svg \) -exec ln -vis "${PWD}/{}" "${HOME}/.local/share/icons/{}" \;

# Symbolische Links der Programmstarter anlegen.
ln -vis "${PWD}/searchbookmark.desktop" "${HOME}/.local/share/applications/searchbookmark.desktop"
ln -vis "${PWD}/newbookmark.desktop" "${HOME}/.local/share/applications/newbookmark.desktop"

# .desktop Dateien validieren.
desktop-file-validate "${HOME}/.local/share/applications/searchbookmark.desktop"
desktop-file-validate "${HOME}/.local/share/applications/newbookmark.desktop"
