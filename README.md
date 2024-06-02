# lastmod

Ein kleines Linux-Tool, zur Suche von neuen bzw. geänderten Dateien rekursiv ab dem aktuellen Verzeichnis.

**Vorbereitung**

Repo klonen:  
```bash
git clone https://codeberg.org/CarstenHa/lastmod
```

Installieren:  
```bash
cd lastmod && ./install.sh
```

Deinstallieren:  
```bash
./install.sh -u
```

Das Programm einfach mit:  
```bash
cd /path/to/lastmod && git pull
```
aktualisieren.

**Nutzung**

Hilfe:  
```bash
lastmod -h
```

Beispiele:  
```bash
# Ausgabe auf Bildschirm.
lastmod
# Ausgabe der neuen bzw. geänderten Dateien vom Vortag (0:00 Uhr)
# bis zum aktuellen Zeitpunkt
lastmod 2
# Ausgabe auf Bildschirm und schreibt das Ergebnis zusätzlich in eine Datei.
lastmod -o path/to/file.txt
```

Beispielansicht:

![Beispielansicht](example.png)

Viel Spaß mit diesem kleinen Programm :)

<https://codeberg.org/CarstenHa/lastmod>
