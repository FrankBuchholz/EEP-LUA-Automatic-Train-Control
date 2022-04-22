# EEP-Lua-Automatic-Train-Control

Sie können die Version 2 des EEP Lua Automatic Traffic Control Projekts hier herunterladen:
[`EEP_blockControl.zip`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/raw/main/blockControl_v2/EEP_blockControl.zip)

Eine Erklärung, wie es funktioniert und wie man die Lua-Tabellen mit Daten füllt, die das eigene Layout definieren, liegt bei:

- Englisch: [`EEP_Lua_Automatic_Train_Control_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatic_Train_Control_v2.pdf)
- Deutsch: [`EEP_Lua_Automatische_Zugsteuerung_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatische_Zugsteuerung_v2.pdf)

Der EEP-Ordner enthält 5 funktionierende EEP-Demo-Layouts mit dem Lua-Code und der Layoutdefinition.

- Demo 01: Dies ist die erste Anlage, in der gezeigt wird, wie mit Hilfe eines Lua-Skripts automatischer Zugverkehr auf jeder beliebigen Anlage des EEP (Modellbahn)-Simulators erzeugt werden kann. Der Benutzer muss keinen Code (neu) schreiben, sondern lediglich die Anlage definieren, indem er Daten über Züge, Signale und Strecken in eine Reihe von Tabellen eingibt.

- Demo 02: In der zweiten Anlage verwenden wir vier Blöcke und fügen einen zweiten Zug hinzu.

- Demo 03: In der dritten Anlage fügen wir einen Zwei-Wege-Block hinzu und sehen, wie man ihn in den Lua-Daten konfiguriert.

- Demo 04: In der vierten Anlage fügen wir zwei Sackgassengleise hinzu und sehen, wie wir Züge dort umkehren lassen können. Außerdem fügen wir einen dritten Zug hinzu, konfigurieren die Anlage in Lua und fahren mit drei Zügen ohne Kollisionen herum.

- Demo 05: In der fünften Anlage werfen wir einen Blick auf eine etwas ernstere Anlage mit 27 Blöcken, 43 Strecken und 7 Zügen, die alle gleichzeitig fahren!  
Zu dieser Anlage gibt es eine Variante die das Modul [BetterContacts](https://emaps-eep.de/lua/bettercontacts) von [Benny](https://www.eepforum.de/user/37-benny-bh2/) verwendet.

Der `LUA`-Ordner enthält das `blockControl` Modul.

Der `GBS`-Ordner enthält 5 Dateien mit den Gleisbildstellpulten, die auch in die Anlagen eingefügt sind.
Unter dem Start/Stopp-Signal befinden sich die Zugsignale. Diese Signale können auch im automatischen Betrieb betätigt werden.
Die Block-Signale sowie die Weichen dürfen im automatischen Betrieb nicht verstellt werden.

Alle Fragen, Kommentare und Ideen sind willkommen. In der Zwischenzeit ... viel Spaß.

Übersetzt mit www.DeepL.com/Translator
