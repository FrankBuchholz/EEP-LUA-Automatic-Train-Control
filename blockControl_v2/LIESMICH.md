# EEP-Lua-Automatic-Train-Control

Sie können die Version 2 des EEP Lua Automatic Traffic Control Projekts hier herunterladen:
[`EEP_blockControl.zip`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/raw/main/blockControl_v2/EEP_blockControl.zip)

Eine Erklärung, wie es funktioniert und wie man die Lua-Tabellen mit Daten füllt, die das eigene Layout definieren, liegt bei:

- Englisch: [`EEP_Lua_Automatic_Train_Control_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatic_Train_Control_v2.pdf)
- Deutsch: [`EEP_Lua_Automatische_Zugsteuerung_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatische_Zugsteuerung_v2.pdf)

Der EEP-Ordner enthält mehrere funktionierende EEP-Demo-Layouts mit dem Lua-Code und der Layoutdefinition.

- Demo 01: Dies ist die erste Anlage, in der gezeigt wird, wie mit Hilfe eines Lua-Skripts automatischer Zugverkehr auf jeder beliebigen Anlage des EEP (Modellbahn)-Simulators erzeugt werden kann. Der Benutzer muss keinen Code (neu) schreiben, sondern lediglich die Anlage definieren, indem er Daten über Züge, Signale und Strecken in eine Reihe von Tabellen eingibt.

- Demo 02: In der zweiten Anlage verwenden wir vier Blöcke und fügen einen zweiten Zug hinzu.

- Demo 03: In der dritten Anlage fügen wir einen Zwei-Wege-Block hinzu und sehen, wie man ihn in den Lua-Daten konfiguriert.

- Demo 04: In der vierten Anlage fügen wir zwei Sackgassengleise hinzu und sehen, wie wir Züge dort umkehren lassen können. Außerdem fügen wir einen dritten Zug hinzu, konfigurieren die Anlage in Lua und fahren mit drei Zügen ohne Kollisionen herum.

- Demo 05: In der fünften Anlage werfen wir einen Blick auf eine etwas ernstere Anlage mit 27 Blöcken, 43 Strecken und 7 Zügen, die alle gleichzeitig fahren!  
Zu dieser Anlage gibt es eine Variante die das Modul [BetterContacts](https://emaps-eep.de/lua/bettercontacts) von [Benny](https://www.eepforum.de/user/37-benny-bh2/) verwendet.

- Demo "Doppelkreuzungsweichen": Diese Demo-Anlage zeigt beide Varianten einer DKW, eine 4-Weichen-DKW oben und eine Gleisobjekt-DKW unten.

- Demo "Zugumkehr": Diese beiden Demo-Anlagen zeigen wie man die Fahrtrichtung der Züge in Sackgassen oder in Zwei-Wege-Blöcken umkehren kann ohne dafür Kontakte zu verwenden.

Der `LUA`-Ordner enthält das `blockControl` Modul.

Der `GBS`-Ordner enthält 5 Dateien mit den Gleisbildstellpulten, die auch in die Anlagen eingefügt sind.
Unter dem Start/Stopp-Signal befinden sich die Zugsignale. Diese Signale können auch im automatischen Betrieb betätigt werden.
Die Block-Signale sowie die Weichen dürfen im automatischen Betrieb nicht verstellt werden.

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

Alle Fragen, Kommentare und Ideen sind willkommen. In der Zwischenzeit ... viel Spaß.

Übersetzt mit www.DeepL.com/Translator
