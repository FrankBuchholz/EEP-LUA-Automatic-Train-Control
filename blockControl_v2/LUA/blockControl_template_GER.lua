-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, April 2022
-- EEP Lua-Code zum automatischen Fahren von Z�gen von Block zu Block.
-- Der Benutzer muss nur das Layout definieren, indem er einige Tabellen und Variablen konfiguriert
-- Es besteht keine Notwendigkeit, Lua-Code zu schreiben, der Code verwendet die Daten in den Tabellen und Variablen.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Vorlage mit allen Funktionen
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Hauptsignal zum Starten der automatischen Blocksteuerung
-- (Sie k�nnen das Signal zweimal umschalten, um Tipp-Texte ein-/auszublenden)
local main_signal = 80

-- (Optional) Verwenden Sie ein Z�hlersignal, um die Protokollstufe zu setzen
--local counterSignal = 47

-- (Optional) Konfigurieren Sie Blocksignale
-- Es ist m�glich, diese Tabelle aus anderen Variablen abzuleiten, allerdings bietet die Verwendung dieser Tabelle M�glichkeiten zur Konsistenzpr�fung.
-- Die Reihenfolge der Eintr�ge spielt keine Rolle.
-- (Sie k�nnen einen beliebigen Namen f�r die Variable 'block_signals' w�hlen.)
local block_signals  = { 
--19, 25, 26, 27, 
}

-- Konfigurieren Sie die zul�ssigen Bl�cke f�r verschiedene Gruppen von Z�gen und die Wartezeit vor dem Verlassen des Blocks. 
-- Wartezeit nicht definiert (nil) oder 0: keine Einfahrt in diesen Block, 1: Block ist erlaubt (Durchfahrt), >1: minimale Wartezeit in Sekunden zwischen Einfahrt in den Block und Verlassen des Blocks (= Fahrzeit vom Kontakt zum Signal + Haltezeit).
-- (Der Name dieser Variablen ist frei w�hlbar.)
local passengerTrains = {
--[Blocksignal] = minimale Wartezeit,
--[19] = 45,
}

local cargoTrains = {
--[Blocksignal] = minimale Wartezeit,
--[26] = 40,
}

-- Konfigurieren Sie die Namen und (optionalen) Signale der Z�ge und weisen Sie die zul�ssigen Bl�cke zu.
-- (Sie k�nnen einen beliebigen Namen f�r die Variable 'Trains' w�hlen, aber Sie m�ssen die Namen f�r die Komponenten 'name', 'signal', 'allowed' verwenden.)
-- (Die Variable 'Trains' k�nnte ein Array mit impliziten Schl�sseln sein, oder Sie k�nnen eine Tabelle mit expliziten Schl�sseln wie [9] oder Namen ["Cargo"] erstellen, um die Eintr�ge zu identifizieren.) 
local trains = {}                                      
-- Schl�ssel (nach Wahl) = EEP-Name, Zugsignal, Erlaubte Blocksignale mit Wartezeit
--trains["Steam CCW"]      = { name = "#Steam CCW", signal = 9,   allowed = passengerTrains }

-- Konfigurieren Sie Paare von Zweiwege-Blocksignalen.
-- (Sie k�nnen einen beliebigen Namen f�r die Variable 'two_way_blocks' w�hlen.)
local two_way_blocks = { 
--{ Paar von Zweiwegbl�cken },
--{ 82, 81 }, 
}

-- Konfigurieren Sie, wie man von einem Block zu einem anderen Block gelangt, indem man die Weichen umschaltet.
-- Zur besseren Lesbarkeit f�hren wir Konstanten ein 
local f = 1 -- Weichenstellung "Fahrt"
local a = 2 -- Weichenstellung "Abzweig"
-- (Sie k�nnen einen beliebigen Namen f�r die Variable 'routes' w�hlen, m�ssen aber den Namen f�r die Komponente 'turn' verwenden).
local routes = {
--{ Startblock, Zielblock, turn={ Weiche, Stellung, ...}}, with Stellung: 1=Hauptstrecke, 2=Abzweig, 3=Alternativstrecke
--{ 29, 74, turn={ 13,a, 11,a }}, -- von Block 29 zu Block 74 �ber die Weichen 13 und 11
}

-- Konfigurieren Sie die erforderlichen Pfade zwischen Startbl�cken, einigen Durchgangsbl�cken und Zielbl�cken.
-- Wenn �hnliche Pfade mehrere Startbl�cke oder Zielbl�cke haben, k�nnen Sie die Pfade kombinieren, indem Sie diese Bl�cke in Klammern setzen.
-- Ein Pfad kann auch einen oder mehrere Durchgangsbl�cke haben. Wenn ein Zwischenteil des Pfades mehrere Optionen hat, dann kann man diese Bl�cke ebenfalls in Klammern setzen.  
local anti_deadlock_paths = {
--{ { Liste der parallelen Startbl�cke }, Liste der Durchgangsbl�cke, { Liste der parallelen Zielbl�cke } },
--{ {46, 45}, 38, {28, 29, 30} }, -- von Block 46 oder 45 �ber Block 38 zu einem der Bl�cke 28, 29 oder 30
}




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Verbleibender Teil des Hauptskripts in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()

local blockControl = require("blockControl")   -- Lade das Modul

blockControl.init({                     -- Initialisieren des Moduls
  logLevel      = 1,                    -- (Optional) Loglevel 0 (Standard): aus, 1: normal, 2: voll, 3: extrem

--language      = "GER",                -- (Optional) GER: Deutsch, ENG: Englisch, FRA: Franz�sisch; standardm��ig wird die installierte Sprache von EEP verwendet   

  trains        = trains,               -- (Optional) Unbekannte Z�ge werden automatisch erkannt, allerdings haben solche Z�ge kein Zugsignal und k�nnen �berall fahren.
  
  blockSignals  = block_signals,        -- Blocksignale
  twoWayBlocks  = two_way_blocks,       -- Zweiweg-Doppelbl�cke
  routes        = routes,               -- Routen �ber Weichen von einem Block zum n�chsten Block
  paths         = anti_deadlock_paths,  -- Kritische Pfade, auf denen Z�ge fahren k�nnen


  MAINSW        = main_signal,          -- ID des Hauptschalters (optional)

  -- [[ Optional, wenn die Standardwerte f�r das Layout gut funktionieren
  MAINON        = 1,      -- EIN-Zustand des Hauptschalters
  MAINOFF       = 2,      -- AUS-Zustand des Hauptschalters
  BLKSIGRED     = 1,      -- HALT-Zustand der Blocksignale
  BLKSIGGRN     = 2,      -- FAHRT-Zustand der Blocksignale
  TRAINSIGRED   = 1,      -- HALT-Zustand der Zugsignale
  TRAINSIGGRN   = 2,      -- FAHRT-Zustand der Zugsignale
  --]]  
})

-- [[ (Optional) Setzen eines oder mehrerer Laufzeitparameter zu einem beliebigen Zeitpunkt 
blockControl.set({
  logLevel      = 1,      -- (Optional) Loglevel 0 (Standard): aus, 1: normal, 2: voll, 3: extrem
--language      = "ENG",  -- (Optional) GER: Deutsch, ENG: Englisch, FRA: Franz�sisch; standardm��ig wird die installierte Sprache von EEP verwendet 
  showTippText  = true,   -- (Optional) Tipptexte anzeigen true / false (Sp�ter kann man die Sichtbarkeit der Tipptexte mit dem Hauptschalter umschalten).
  start         = false,  -- (Optional) Aktivieren/Deaktivieren des Hauptsignals. N�tzlich, um die automatische Blocksteuerung zu starten, nachdem alle bekannten Z�ge gefunden wurden.
  startAllTrains = true,  -- (Optional) Aktiviert/deaktiviert alle Zugsignale
})
--]]

if EEPActivateCtrlDesk then         -- (Optional) Aktiviert ein Stellpult f�r die EEP-Anlage, verf�gbar ab EEP 16.1 Patch 1
  local ok = EEPActivateCtrlDesk("Block control")             
  if ok then print("Zeige Stellpult 'Block control'") end
end

--[[ (Optional) Z�hlersignal zum Setzen des Loglevels verwenden
local counterSignal = 47
blockControl.set({ logLevel = EEPGetSignal( counterSignal ) - 1 })
EEPRegisterSignal( counterSignal )
_ENV["EEPOnSignal_"..counterSignal] = function(pos)
  local logLevel = pos - 1
  if logLevel > 3 then -- Maximalwert einschr�nken
    logLevel = 0
    blockControl.set({ logLevel = logLevel })
    EEPSetSignal( counterSignal, logLevel + 1 )
  sonst
    blockControl.set({ logLevel = logLevel })
  Ende
  print("Protokollierungslevel eingestellt auf ", logLevel)
end
--]]


function EEPMain()

  blockControl.run()
  --blockControl.printStatus(60) -- (Optional) Anzeige von Status und Statistiken alle 60 Sekunden

  return 1
end
