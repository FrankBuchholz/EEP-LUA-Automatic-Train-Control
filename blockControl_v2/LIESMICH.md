# EEP-Lua-Automatic-Train-Control

## Dokumentation

Eine Erklärung, wie es funktioniert und wie man die Lua-Tabellen mit Daten füllt, die das eigene Layout definieren, liegt hier:

- Englisch: [`EEP_Lua_Automatic_Train_Control_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatic_Train_Control_v2.pdf)
- Deutsch: [`EEP_Lua_Automatische_Zugsteuerung_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatische_Zugsteuerung_v2.pdf)

## Dateien

Sie können die aktuelle Version des EEP Lua Automatic Traffic Control Projekts hier herunterladen:
[`EEP_blockControl.zip`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/releases/latest)

Der EEP-Ordner enthält mehrere funktionierende EEP-Demo-Layouts mit dem Lua-Code und der Layoutdefinition.

Der `LUA`-Ordner enthält das `blockControl` Modul sowie Template-Dateien, die als Ausgangspunkt für die Entwicklung eigener Lua-ATC-Skripte verwendet werden können.

Der `GBS`-Ordner enthält Dateien mit den Gleisbildstellpulten, die auch in die Anlagen eingefügt sind.
In der Näher des Start/Stopp-Signals befinden sich die Zugsignale. Diese Signale können auch im automatischen Betrieb betätigt werden.
Die Block-Signale sowie die Weichen dürfen im automatischen Betrieb nicht verstellt werden.

## Online-Tools

Die Tabelle `routes` im Lua-Konfigurationsabschnitt beschreibt die verfügbaren Strecken von einem Block zum nächsten, indem sie die Zustände "Haupt" / "Abzweig" der Weichen zwischen den beiden Blöcken definiert. Diese Tabelle kann von Hand erstellt werden, aber das erfordert große Aufmerksamkeit ... ein kleiner Fehler bei einem Weichenstatus kann dazu führen, dass ein Zug zu einem unerwarteten Block fährt, was zu unberechenbarem automatischen Verkehr führt.

Folgende Online-Tools helfen hier weiter:

- Als ersten Schritt können Sie das [Gleisplan-Program](https://frankbuchholz.github.io/EEP_convert_anl3_file/EEP_Gleisplan.html) nutzen. Es zeigt den EEP-Gleisplan in Ihrem Browser-Fenster einschließlich der Signale und Weichennummern in einem leicht lesbaren Format.
- Ein zweites Werkzeug geht einen großen Schritt weiter: Es kann einen Vorschlag für alle Lua-Konfigurationstabellen mit Ausnahme der Pfade-Tabelle erstellen. Öffnen Sie zunächst den Gleisplan in der Gleisplan-Programm. Öffnen Sie nun das [Generierungsprogramm](https://frankbuchholz.github.io/EEP_convert_anl3_file/EEP_blockControl.html) in einer anderen Registerkarte desselben Browsers und klicken Sie auf die Schaltfläche "Generieren".
- Schließlich können Sie das [Inventar-Programm](https://frankbuchholz.github.io/EEP_convert_anl3_file/EEP_Inventar.html) nutzen, um die Einstellungen der Kontakte einschließlich der Lua-Funktion in den Kontakten zu überprüfen.

## Videos

Eine Reihe von YouTube-Videos finden Sie hier:

- [Automatic Train Traffic on any EEP Layout v2 - 01](https://www.youtube.com/watch?v=6X1fmBAHgpY&ab_channel=Rudysmodelrailway)  
Dies ist das erste Video einer Serie, in der gezeigt wird, wie mit Hilfe eines Lua-Skripts automatischer Zugverkehr auf jeder beliebigen Anlage des EEP (Modellbahn)-Simulators erzeugt werden kann. Der Benutzer muss keinen Code (neu) schreiben, sondern lediglich die Anlage definieren, indem er Daten über Züge, Signale und Strecken in eine Reihe von Tabellen eingibt.

- [Automatic Train Traffic on any EEP Layout v2 - 02](https://www.youtube.com/watch?v=qEFNnP-s14c&ab_channel=Rudysmodelrailway)  
In Demo 2 fügen wir einen zweiten Zug hinzu. Sie fahren, von Lua gesteuert, herum, ohne jemals zusammenzustoßen. Lua erlaubt einem Zug nur dann zu fahren, wenn der Zielblock und alle benötigten Weichen auf dem Weg frei sind. Wenn ein Zug losfahren darf, reserviert Lua die Weichen und den Zielblock; diese sind nun für andere Züge nicht mehr verfügbar, bis sie wieder freigegeben werden, wenn der Zug an seinem Zielblock ankommt, der über den Blockeingangssensor erkannt wird.

- [Automatic Train Traffic on any EEP Layout v2 - 03](https://www.youtube.com/watch?v=YouDOfVNHgk&ab_channel=Rudysmodelrailway)  
Nehmen wir ein Zwei-Wege-Gleis in die Anlage auf und sehen wir uns an, wie dieses konfiguriert werden kann.
Ein Zwei-Wege-Gleis wird als zwei separate Einbahnstraßenblöcke auf demselben Gleis behandelt. Beide Blöcke haben ihr eigenes Blocksignal und ihren eigenen Einfahrsensor. Wenn Lua einen der beiden Blöcke für einen Zug reserviert, muss auch der andere Block reserviert werden. Ebenso muss der Zwillingsblock bei Freigabe freigegeben werden. Wir müssen Lua mitteilen, welche Blöcke "Zweiweg-Zwillingsblöcke" sind, damit diese zusätzliche Reservierung und Freigabe stattfinden kann.

- [Automatic Train Traffic on any EEP Layout v2 - 04](https://www.youtube.com/watch?v=x8MSMDGuqrM&ab_channel=Rudysmodelrailway)  
Basierend auf der Demo 3 Anlage fügen wir nun zwei Sackgassengleise im Bahnhof Nord hinzu. Zunächst werden die beiden Möglichkeiten, ein Sackgassengleis in EEP zu erstellen, erläutert. Dann wird die Lua-Konfiguration für diese Anlage Schritt für Schritt untersucht. Die Sackgassen erfordern keine spezielle Konfiguration, sie werden wie jeder andere Block behandelt.

- [Automatic Train Traffic on any EEP Layout v2 - 04B](https://www.youtube.com/watch?v=4VcZgUUgHy0&ab_channel=Rudysmodelrailway)  
Im vorherigen Video auf der Demo 4 Anlage haben wir jeden Zug auf jedem Block zugelassen. Dies hatte den Effekt, dass Personenzüge rückwärts fuhren, wenn sie aus den Sackgassenblöcken herausfuhren, was unrealistisch ist. Durch einfaches Ändern der zulässigen Blocktabellen fahren der orangefarbene Personenzug im Uhrzeigersinn, der Dampfzug gegen den Uhrzeigersinn und der Güterzug ist der einzige, der in die Sackgassen hineinfährt. Alle drei Züge können den mittleren Block des Bahnhofs Süd benutzen, der ein Zweiwege-Block ist, durch den sie fahren, wenn sie können.

- [Automatic Train Traffic on any EEP Layout v2 - 05](https://www.youtube.com/watch?v=qjrlIr_JMXY&ab_channel=Rudysmodelrailway)  
Demo 5 ist eine etwas größere Modellbahnanlage mit 27 Blöcken und 7 Zügen. Zwei Züge fahren vom/zum Bahnhof gegen den Uhrzeigersinn, 2 Züge fahren im Uhrzeigersinn und 3 Güterzüge pendeln zwischen den 4 Gruppen von Sackgassengleisen, die Industriegebieten ähneln.  
Über die Tabellen "Erlaubte Blöcke" legen wir fest, welche Züge wo fahren dürfen.  
Die Zugtabelle enthält die Zugnamen, ihre Start-/Stoppschalter und die Tabelle der erlaubten Blöcke.  
Die Streckentabelle spezifiziert jede mögliche Route von Block A nach Block B und welche Weichen zu stellen sind, um dorthin zu gelangen.  
Wir werfen auch einen Blick auf den Abschnitt, in dem die Parameter eingestellt werden können, um die Anzahl der Meldungen auf dem Lua-Bildschirm zu ändern, ob die Tooltips angezeigt werden oder nicht, ob der Hauptschalter ein- oder ausgeschaltet ist und ob alle Zugschalter beim Starten ein- oder ausgeschaltet sind.

- [Automatic Train Traffic on any EEP Layout v2 - 06](https://www.youtube.com/watch?v=xxssAIgqxk0&ab_channel=Rudyshobbychannel)  
Der Lua-Code zur Erzeugung von automatischem Zugverkehr auf Ihrer EEP-Anlage kann mit einem Code-Generator-Tool erzeugt werden.
In Demo 6 sehen wir, wie wir den Lua ATC Code Generator verwenden können. Basierend auf der EEP anl3 Datei wird der Lua Code für den automatischen Zugverkehr automatisch generiert. Darin enthalten sind die Strecken, Gegenverkehrsblocks und die Zugtabellen. Was wir selbst anpassen müssen, sind die Tabellen mit den erlaubten Blöcken. Wenn es die Anlage erfordert, müssen wir eventuell auch eine Anti-Deadlock-Tabelle hinzufügen.

- [Automatic Train Traffic on any EEP Layout v2.2 - 07](https://www.youtube.com/watch?v=Jy6LAwftW9g&ab_channel=Rudyshobbychannel)  
EEP Lua ATC Version 2.2 wurde veröffentlicht. Dieses Video zeigt alle Schritte, vom Herunterladen bis zum vollautomatischen Fahren von drei Zügen.  
Eine der neuen Funktionen in v2.2 ist die Art und Weise, wie Züge umgedreht werden können. Es werden keine Sensoren für die Geschwindigkeitsumkehr mehr benötigt, was auch die Notwendigkeit einer sorgfältigen Platzierung und den immer noch sichtbaren Schluckauf bei der Geschwindigkeitsumkehr eliminiert. Lua kümmert sich um die Umkehrung, sobald eine Strecke die zusätzliche Angabe reverse=true erhalten hat. Mit dieser Umkehrmethode ist es auch möglich, Züge in einem Block umzukehren, der keine Sackgasse ist.

- [Automatic Train Traffic on any EEP Layout v2.2 - 08](https://www.youtube.com/watch?v=YdrGc5KIsmM&ab_channel=Rudyshobbychannel)  
Die automatische Zugsteuerung Version 2.2 bietet die Möglichkeit, Züge ohne Gleissensoren umzukehren, Lua übernimmt die Umkehrung. Das macht es möglich, einen Zug an jedem Block umzukehren, nicht nur an Sackgassen. Der Block muss nicht einmal ein Zweiwege-Block sein, Züge können an jedem Block umkehren.  
Der Lua ATC Code Generator kann unsere Absichten nicht erraten, er wird immer Strecken ohne Umkehrungen generieren, und Züge nur in Sackgassen umkehren lassen. Wenn wir wollen, dass ein Zug in einem Block, der keine Sackgasse ist, rückwärts fährt, müssen wir die Routen dafür selbst hinzufügen und reverse=true für diese Routen angeben. Wenn Sie sowohl die Vorwärts- als auch die Rückwärtsroute in der Tabelle belassen, führt dies dazu, dass die Züge 50 % der Zeit vorwärts fahren und die anderen 50 % der Zeit rückwärts.

- [Automatic Train Traffic on any EEP Layout v2.3 - 09](https://www.youtube.com/watch?v=KGXL2a99CjM&ab_channel=Rudyshobbychannel)  
Bei dieser Version geht es darum, alles noch einfacher zu machen:  
  - Es gibt den neuen EEP-Installer, der mit zwei Mausklicks den Inhalt der ZIP-Datei installiert.  
  - Das BetterContacts-Modul ist enthalten, mit freundlicher Genehmigung von Benjamin Hogl.  
  - Es gibt ein neues Benutzerhandbuch, das jeden einzelnen Schritt von der Installation der Software bis zum automatischen Fahren erklärt.  
  - Der Schwerpunkt des Handbuchs liegt jetzt auf der Verwendung des Lua-Code-Generators, der uns die meiste Arbeit abnimmt.  
  - Ein neues Demo-Layout, Peace River, ist enthalten.  

- [Automatic Train Traffic on any EEP Layout v2.3 - 10](https://www.youtube.com/watch?v=ISWab3A1tbI&ab_channel=Rudyshobbychannel)  
Dieses Video zeigt, wie das Demo-Layout Peace River automatisiert wurde.  

- [Automatic Train Traffic on any EEP Layout v2.3 - 11](https://www.youtube.com/watch?v=nq5rGOXgdRQ&ab_channel=Rudyshobbychannel)  
Dieses Video zeigt, wie das Demolayout Swyncombe automatisiert wurde und beschreibt die neuen Funktionen der Version 2.3.2:  
  - Effiziente Möglichkeiten zur Definition erlaubter Blöcke  
  - Zufällige Wartezeiten, zwischen einem Minimal- und Maximalwert, pro Zug und Block  
  - Informationen über fehlende Züge während des Zugsuchmodus 

## Zusammenarbeit

Alle Fragen, Kommentare und Ideen sind willkommen. Sie können einen der folgenden Kanäle verwenden:

- GitHub [issues](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/issues) und [discussions](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/discussions)
- EEP-Forum-Thread auf [Englisch](https://www.eepforum.de/forum/thread/36688-lua-automatic-train-control-for-any-layout-version-2/) oder [Deutsch](https://www.eepforum.de/forum/thread/36689-lua-automatische-zugsteuerung-f%C3%BCr-jedes-layout-version-2/)
- EEP-Forum-[Konversationen](https://www.eepforum.de/conversation-add)  mit `_RudyB` und `frank.buchholz`

In der Zwischenzeit ... viel Spaß.  
Rudy und Frank

_Übersetzt mit www.DeepL.com/Translator_
