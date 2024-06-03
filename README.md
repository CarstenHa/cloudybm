# cloudybm

Ein kleines Linux-Tool, um Lesezeichen auf einem entfernten Rechner via SSH zu verwalten.

**Vorbereitung**

Für dieses Tool wird eine bestehende SSH-Verbindung vorausgesetzt. Für die Einrichtung von SSH gibt es sehr gute Anleitungen im Internet. Eine ist zum Beispiel:  
<https://wiki.ubuntuusers.de/SSH/>  

Außerdem wird das Installieren von *ssh-askpass* (oder einem ähnlichen Paket wie *ssh-askpass-gnome*, etc.) empfohlen.

Die folgenden Schritte sind auf dem Client-Rechner auszuführen:

Repository klonen:  
```bash
https://github.com/CarstenHa/cloudybm
```

config-Datei im Ordner `cloudybm/config` kopieren:
```bash
cp cloudybm/config/cloudybm.bsp cloudybm/config/cloudybm.cfg
```
und anschließend ausfüllen. Die folgende Installation mit install.sh funktioniert nur mit ausgefüllter cloudybm.cfg.  

Installieren:  
```bash
cd cloudybm && ./install.sh
```

Deinstallieren:  
```bash
./install.sh -u
```
Hinweis:  
Bei der Deinstallation werden nur die lokalen Symlinks auf die Repo-Dateien entfernt. Der Repository-Ordner, die ggf. bei der Installation erstellten Ordner sowie Dateien und Ordner auf dem Server werden nicht gelöscht.

Das Programm kann einfach mit:  
```bash
cd /path/to/cloudybm && git pull
```
aktualisiert werden.

**Nutzung**

Nach der Installation findet man die Programmteile in der Rubrik Zubehör.  
![Symbol Lesezeichen suchen](hicolor/32x32/apps/mybookmarks.0.svg)
![Symbol Neues Lesezeichen](hicolor/32x32/apps/bookmark_add.0.svg)

Zur Vorgehensweise:  
Das Skript *searchbookmark* ist für die Suche und das Löschen von Lesezeichen aus der Lesezeichen-Datei bookmarks.txt zuständig. Die Bearbeitung der Datei bookmarks.txt ist nur auf dem Server möglich. Das Durchsuchen ist auch von der lokalen bookmarks.txt möglich.  
Das Skript *newbookmark* leitet das Hinzufügen eines neuen Lesezeichens ein. Dabei übergibt das Skript die Daten an das Skript *cloudybm* auf dem Server. Dieses Skript ist dann für das eigentliche Hinzufügen des Lesezeichens zuständig.

Über eine Maske können entweder neue Lesezeichen hinzugefügt werden oder nach bestehenden Lesezeichen gesucht bzw. Lesezeichen gelöscht werden. Neue Lesezeichen können nur hinzugefügt werden, wenn der Server erreichbar ist.  
![Eingabemaske für neues Lesezeichen](images/neu.png)

Eine Kopie der Lesezeichen-Datei (bookmarks.txt) wird nach jeder Änderung auf den Client-Rechner kopiert. Somit sind die Bookmarks auch verfügbar, wenn mal keine Verbindung zum Server besteht.

Durch Angabe von `*` in der Suchmaske, werden alle Lesezeichen angezeigt.  
![Suchmaske mit Asterisk](images/asterisk.png)

Ob die Serverdatei oder die lokale Lesezeichen-Datei gerade durchsucht wird, kann man übrigens am Fensterkopf erkennen:  
![Lokale Suche](images/localsearch.png)

Durch Doppelklick werden Links in der Standardanwendung (i.d.R. der Browser)  geöffnet.  

Weitere Terminal-Beispiele:  
```bash
# Aufrufen der Hilfe von cloudybm auf Remote-Rechner
/path/to/cloudybm -h
# Hinzufügen eines Lesezeichens auf Remote-Rechner
/path/to/cloudybm -B "keywort1,keywort2,etc." "Hier steht die Beschreibung" "https://example.com"
# oder (ohne Schlüsselwörter und Beschreibung):
/path/to/cloudybm -B "" "" "https://example.com"

```
**Lizenzhinweise**

SVG-Icons in den Unterordnern von hicolor sind von:
Fonticons, Inc. (<https://fontawesome.com>)  
SVG-Icons are licensed CC BY 4.0 License (<https://creativecommons.org/licenses/by/4.0/>)  
Creative Commons Attribution 4.0 International License  
Modified by Carsten Jacob (<https://github.com/CarstenHa/cloudybm>)

Viel Spaß mit diesem kleinen Programm :)

<https://github.com/CarstenHa/cloudybm>