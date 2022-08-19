# EEP-Lua-Automatic-Train-Control

## Die Geschichte zu diesem Projekt

Im November 2021 bin ich in ein neues Haus gezogen. Neben den vielen Vorteilen, die das neue Haus bietet, gibt es ein kleines Problem: Es gibt keinen Platz mehr für meine Modelleisenbahn. EEP kam zur Rettung ... Ich kann immer noch Modelleisenbahnen entwerfen und 'bauen', und auf meinem 4k-Bildschirm macht es Spaß, daran herumzubasteln.

Meine alte Modelleisenbahn war computergesteuert mit einem Programm namens Traincontroller. Es ermöglicht einen automatischen Zugverkehr, wobei es sich um das Schalten von Weichen und Signalen sowie das Beschleunigen und Abbremsen der Züge kümmert.

Mir ist aufgefallen, dass EEP keine automatische Zugsteuerung eingebaut hat ... oder zumindest nicht in einer Weise, die benutzerfreundlich ist. Es gibt jedoch Lua, mit dem wir Code schreiben können, um diese Aufgaben auszuführen. Ich habe mich gefragt, ob es möglich wäre, ein Lua-Programm zu schreiben, das den automatischen Zugverkehr in EEP steuert, so wie es Traincontroller mit einer echten Modellbahnanlage tut.

Ich habe mir folgende Ziele gesetzt:

- Die Züge sollen automatisch von Block zu Block fahren
- Es sollte möglich sein, festzulegen, welche Züge in welchen Blöcken fahren dürfen
- Es soll möglich sein, Haltezeiten zu definieren, pro Zug und Block
- Es soll möglich sein, einzelne Züge zu starten / zu stoppen
- Es soll für jede (Modell-)Bahnanlage funktionieren, ohne dass Lua-Code (neu)  geschrieben werden muss
- Die Anlage wird ausschließlich durch die Eingabe von Daten über Züge, Signale, Weichen und Strecken definiert

## NEWS Februar 2022

Frank Buchholz fügte dem Code mehrere Verbesserungen hinzu, wie zum Beispiel:

- Automatische Erkennung von platzierten Zügen
- Aufteilen des Codes in eine Benutzerkonfigurationsdatei und eine separate Steuerdatei, die nicht bearbeitet werden muss
- Option zum Hinzufügen von "Zielblöcken", über die Lua mehr als einen Block vorausschaut, um einen möglichen Stillstand gegenläufiger Züge zu verhindern.

## NEWS April 2022

Veröffentlichung der Version 2.

Ich habe mich entschieden, den Code der Version 1 in seinem ursprünglichen, minimalistischen Zustand zu belassen.

## Versionen und andere Ordner

Dieses GitHub Repository enthält das Ergebnis dieses EEP Lua Automatic Traffic Control Projekts.

Es gibt zwei Versionen des Projektes:

- Version 1 nutzt ein effektives, minimalistisches Lua-Programm - kürzer als 200 Zeilen - um eine Anlage automatisch zu betreiben. Diese Version bleibt aus historischen Gründen verfügbar.
- Version 2 verwendet erweiterten modularisierten Code mit weniger erforderlicher Konfiguration, mehr Optionen, stärkerer Robustheit, Konsistenzprüfungen und erweiterter Protokollierung.  
Verwenden sie diese Version!  
Sie können das Paket hier herunterladen:
[`EEP_blockControl.zip`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/releases/latest/download/EEP_blockControl.zip)

Der "TC"-Ordner enthält die 5 Layouts in Traincontroller, für diejenigen, die vielleicht mit TC basteln möchten. Kostenlose Demo-Version: <https://www.freiwald.com/pages/download.htm>

Der Ordner "Images" enthält Bildschirmfotos der 5 Layouts in EEP, SCARM und Traincontroller.

Der "SCARM"-Ordner enthält 2 SCARM-Dateien, eine mit den Layouts 1-4 (öffnen Sie das Menü Ansicht > Ebenen, um die Ebenen zu wechseln) und eine mit Layout 5, für diejenigen, die vielleicht mit SCARM basteln möchten. Kostenlose Demo-Version: <https://www.scarm.info/index.php>

Alle Fragen, Kommentare und Ideen sind willkommen. In der Zwischenzeit ... viel Spaß.
