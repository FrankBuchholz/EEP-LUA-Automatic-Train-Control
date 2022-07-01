-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, April 2022
-- EEP Lua module to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables.
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--[[
Version history:
2.0.0   22.04.2022
- Initial version 

2.0.2   02.05 2022
- Correction in 'make a list of all possible paths' to ignore dummy trains.
- Tipp-texts using <br> instead of \n
- Limitation: Currently only one route between same blocks can be processed, 
  therefore only the shortest route between same blocks is used.
- Typo in printStatus corrected.
- Show module version depending of log level during init call.

2.0.3   04.05 2022
- Corrected list of allowed blocks for trains in function printData
- Sorted lists by functions printData and printStatus
- Show statistics of visited blocks by function printStatus
- New parameter for function printStatus to define repetition frequency
- Optimized detection of trains entering or leaving blocks via tracks (not finished yet)
- Simplified prefix for print statements

2.1.0   06.05.2022
- New sub-version because of new demo layout showing double slip turnouts
- Use third parameter of functions EEPSetSignal and EEPSetSwitch always to allow users to work with EEPOn functions.
- Try to catch stopped trains in blocks even if no enter block event was triggered
- Improved error messages in case of incomplete data (function assert is not used anymore)
- Show run time statistics in function printStatus

2.2.0   05.06.2022
- New sub-version because of new option to reverse trains at block signals
  This requires to store the speed of trains in the tag text of the engine of the trains
- Allow reversing the direction of trains in two-way-blocks
- Two demo layouts showing reversing blocks
- Don't show misleading message "..and stays at least for 1 sec" if the allowed time is max 1
- Show top into text during find mode
- Skip functions like EEPChangeInfoSignal or EEPShowInfoTextTop if not available in this EEP version
- The allowed tables accepts value 'true' for a drive-throught block ('nil' and 'false' are already valid values in the allowed tables.)
- Show drive time between entering a block and stopping at the block signal

2.3.0   21.06.2022
- New sub-version because of new EEP installer and rearranged documentation
- Minor fixes

2.3.1   30.06.2022
- Translated texts (GER, ENG, FRA)

--]] 

local _VERSION = 'v2.3.1 - 30.06.2022'

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  MODULE blockControl
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Variables starting with an upper case letter are objects.
-- Variables starting with a lower letter are primitive data types or arrays.
-- Variables which are all upper case are constants.

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Language functions
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local language = "ENG"
if EEPLng then       -- Variable EEPLng showing the installed language version of EEP is available as of EEP 17 only
  language = EEPLng
else

  -- Read file eep.lng to identify the installed language
  local filename = "eep.lng"
  local file = io.open(filename, "r") 
  if file then
    --local section
    for line in io.lines(filename) do
      -- Read section
      --local s = line:match("^%[([^%]]+)%]$")
      --if s then section = s end
      
      -- Read Entry
      --local key, value = line:match("^(%w+)%s-=%s-(.+)$")
      
      -- Read specific entry
      --local value = line:match("^IDC_BUTTON_EXIT%s-=%s-\"(.+)\"")   -- Ende    Exit  Quitter (at the end of the file)
      local value = line:match("^IDC_BUT_CLOSE%s-=%s-\"(.+)\"")       -- Beenden Close Fermer  (at the beginning of the file)
      if value then
        if     value == "Beenden" then language = "GER"
        elseif value == "Close"   then language = "ENG"
        elseif value == "Fermer"  then language = "FRA"
        end
        break
      end
    end
    file:close()
  end
  
end

local function stringFormat( text, ... )
  if type(text) == "table" then
    return string.format( text[language], ... )     -- Use language specific text
  else
    return string.format( text, ... )               -- Use given text
  end  
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Utility functions
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local logLevel = 0                                -- Log level 0: off, 1: normal, 2: full, 3: extreme
local function printLog (level, ...)              -- A variable number of arguments is passed as second parameter
  if logLevel >= level then
    print(...)                                    -- Print variable number of argument values
  end
end

local function check (condition, ...)             -- Check a condition and show a message (simnilar like assert but without stopping)
  if not condition then
    print(...)                                    -- Print variable number of argument values
  end
end

local function pairsByKeys (tab, func)              -- see http://www.lua.org/pil/19.3.html
  local keys = {}                                   -- copy keys
  for k in pairs(tab) do table.insert(keys, k) end
  
  table.sort(keys, func)                            -- sort keys by key respective by using given sort function
  
  local i = 0                                       -- iterator variable
  local iterator = function ()                      -- iterator function
    i = i + 1
    if keys[i] == nil then return nil
    else return keys[i], tab[keys[i]]
    end
  end
  return iterator
end

-- Convert table to TAB separated string
-- Limitation: no support for nested tables, no TAB in value allowed 
local function serialize(data)
  local t = ""
  if type(data) == "table" then
    -- convert table
    local sep = string.char(09)                     -- TAB character
    for k, v in pairs(data) do
      local ks = tostring(k)
      local vs = ( type(v) == "number" and math.type(v) == "float" 
                   and string.format("%.3f", v)     -- 3 decimal places for floats are sufficent 
                   or tostring(v) 
                  )
      t = t..ks.."="..vs..sep     -- simple conversion, no nested tables possible
    end
  else
    -- convert anything else
    t = tostring(data)
  end  
  return t
end

-- Convert TAB separated string into table
local function deserialize(t)
  local sep = string.char(09)                     -- TAB character
  local pattern = "([^=]+)=([^"..sep.."]+)"..sep	-- key=value	
  local tab = {}
  for k, v in string.gmatch( t, pattern ) do
    local kn, vn = tonumber(k), tonumber(v)       -- try to convert numeric values
    tab[(kn and kn or k)] = (vn and vn or v)      -- use numeric value if possible, otherwise use string
  end
  if next(tab) then
    -- construct table
    return tab
  else
    -- construct anything else
    if t == "true" then 
      return true
    elseif t == "false" then 
      return false
    elseif t == "nil" then 
      return nil
    else
      local tn = tonumber(t)
      return tn and tn or t  -- number or string
    end  
  end
end

-- Get the wagon name of the engine of a train
local function getEngine( trainName )
  if   not EEPGetRollingstockItemsCount -- EEP 13.2 plug-in2
    or not EEPGetRollingstockItemName   -- EEP 13.2 plug-in2
    or not EEPRollingstockGetMotor      -- EEP 14.2 Plug-In 2
    then
    return nil
  end
  
  -- identify the first engine
  local count = EEPGetRollingstockItemsCount( trainName )
  for i = 0, count-1, 1 do
    local wagonName = EEPGetRollingstockItemName( trainName, i )
    local ok, gears = EEPRollingstockGetMotor( wagonName )
    if ok and gears > 0 then -- Is there an engine?
      return wagonName
    end
  end
  -- fallback 
  local wagonName = EEPGetRollingstockItemName( trainName, 1 )
  return wagonName
end

local TrainTab = {} 

-- Store a value or a simple key=value-table for the train
local reversingRoutesExist
local function storeTrainData( trainName, data )
  if EEPRollingstockSetTagText then -- EEP 14.2 Plug-In 2
    -- use a tag text
    local wagonName = getEngine( trainName ) or ""
    local text = serialize( data )
    local ok = EEPRollingstockSetTagText( wagonName, text )
    printLog(2, stringFormat({
        GER = "Tag-Text in Zug '%s' Waggon '%s' speichern: %s", 
        ENG = "Store tag text in train '%s' wagon '%s': %s", 
        FRA = "Enregistrer le texte de la balise dans le train '%s' wagon '%s' : %s", 
      }, trainName, wagonName, text )
    )

  else 
    -- use a data slot
    local Train = TrainTab[ trainName ]
    
    check(Train, stringFormat({
        GER = "Fehler beim Speichern von Daten: Zug '%s' nicht gefunden", 
        ENG = "Error while storing data: train '%s' not found", 
        FRA = "Erreur lors du stockage des données: train '%s' non trouvé", 
      }, trainName )
    )
    
    if reversingRoutesExist and not Train.slot then 
    
      print(stringFormat({
          GER = "Fehler beim Speichern von Daten: kein Slot für den Zug '%s' definiert", 
          ENG = "Error while storing data: no slot defined for train '%s'", 
          FRA = "Erreur lors de l'enregistrement des données: aucun emplacement défini pour le train '%s'", 
        }, trainName )
      )
    
    end
    if Train.slot then 
      local text = serialize( data )
      local ok = EEPSaveData( Train.slot or 0, text )
      if ok then 
        printLog(2, stringFormat({
            GER = "Daten für Zug '%s' in Slot %d speichern: %s", 
            ENG = "Store data for train '%s' in slot %d: %s", 
            FRA = "Stocker les données du train '%s' dans le slot %d: %s", 
          }, trainName, Train.slot, text )
        )
        
      else
      
        print(stringFormat({
            GER = "Speichern von Daten für Zug '%s' in Slot %d fehlgeschlagen: %s", 
            ENG = "Storing data for train '%s' in slot %d failed: %s", 
            FRA = "Le stockage des données pour le train '%s' dans l'emplacement %d a échoué: %s", 
          }, trainName, Train.slot or 0, text )
        )
        
      end 
    end    
  end
end

-- Retrieve a value or a simple key=value-table from a train
local function readTrainData( trainName )
  if EEPRollingstockSetTagText then -- EEP 14.2 Plug-In 2
    -- use a tag text
    local wagonName = getEngine( trainName ) or ""
    local ok, text = EEPRollingstockGetTagText( wagonName )
    printLog(2, stringFormat({
        GER = "Abrufen des Tag-Textes aus dem Zug '%s'-Wagen '%s': %s", 
        ENG = "Retrieve tag text from train '%s' wagon '%s': %s", 
        FRA = "Récupérer le texte de l'étiquette du train '%s' wagon '%s': %s", 
      }, trainName, wagonName, text )
    )
    
    local data = deserialize( text )
    return data

  else 
    -- use a data slot
    local Train = TrainTab[ trainName ]
    
    check(Train, stringFormat({
        GER = "Fehler beim Lesen von Daten: Zug '%s' nicht gefunden", 
        ENG = "Error while reading data: train '%s' not found", 
        FRA = "Erreur lors de la lecture des données: train '%s' non trouvé", 
      }, trainName )
    )
    
    check(Train.slot, stringFormat({
        GER = "Fehler beim Lesen der Daten: kein Slot für Zug '%s' definiert", 
        ENG = "Error while reading data: no slot defined for train '%s'", 
        FRA = "Erreur lors de la lecture des données: aucun emplacement défini pour le train '%s'", 
      }, trainName )
    )

    local ok, text = EEPLoadData( Train.slot or 0 )
    if ok then 
      printLog(2, stringFormat({
          GER = "Abrufen von Daten für den Zug '%s' von Slot %d: %s", 
          ENG = "Retrieve data for train '%s' from slot %d: %s", 
          FRA = "Récupérer les données pour le train '%s' depuis l'emplacement %d: %s", 
        }, trainName, Train.slot, text )
      )
      
    else
      print(stringFormat({
          GER = "Fehler: Lesen der Daten für Zug '%s' von Slot %d fehlgeschlagen", 
          ENG = "Error: Reading data for train '%s' from slot %d failed", 
          FRA = "Erreur: La lecture des données du train '%s' à partir de l'emplacement %d a échoué", 
        }, trainName, Train.slot or 0 )
      )
      
    end    
    local data = deserialize( text )
    return data

  end  

end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Get the options from the caller to initialize the module
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local MAINSW                                      -- ID of the main switch

local MAINON                                      -- ON    state of main switch
local MAINOFF                                     -- OFF   state of main switch
local BLKSIGRED                                   -- RED   state of block signals
local BLKSIGGRN                                   -- GREEN state of block signals
local TRAINSIGRED                                 -- RED   state of train signals
local TRAINSIGGRN                                 -- GREEN state of train signals

local showTippText = true                         -- Toggle visibility of tipp texts via callback function of the main switch

local useBetterContacts = false                   -- Do not generate functions for entering and leaving blocks if module BetterContacts is used

-- Decide if block numbers are 
-- a) based on array index numbers or 
-- b) based on block signal numbers:
local useBlockIndexNumbers

local trackSystem                                 -- Track system (only used if trackdata are provided)

local BlockTab = {}                               -- Blocks
local enterBlock                                  -- Lua requires a look-ahead definition for function enterBlock
local leaveBlock                                  -- Lua requires a look-ahead definition for function leaveBlock
local function collectBlock (k, s)                -- Collect new blocks into block table
  local b
  local signal
  if s then                                       -- The callers provide one or two parameters 
    b      = useBlockIndexNumbers and k or s      -- Use block index numbers respective block signal numbers as key
    signal = s
  else
    b      = k
    signal = k
  end

  if not BlockTab[b] then                         -- Create new entry in not known yet
    BlockTab[b] = {
      signal      = signal,                       -- Block signal
      twoWayBlock = 0,                            -- Two way twin block
      reserved    = nil,                          -- Train which has reserved the block (nil = free)
      occupied    = nil,                          -- Train name if a block is occupied
      occupiedOld = nil,                          -- Old value, used to check for transitions from free to occupied
      request     = nil,                          -- Train which has a request for the block (nil = free)
      stopTimer   = 0,                            -- Waittime, decremented every EEPmain() cycle, which is 5x/s
      
      visits      = 0,                            -- Statistic counter how often a train has visited this block
      enterBlockCycle = nil,                      -- Cycle when the entered the block to calculate the drive time until it stopps at at the signal
    }

    EEPSetSignal( signal, BLKSIGRED, 1 )          -- Stop all trains at block signals

    -- Generate functions to catch changes for signals
    if logLevel >= 3 then 
      EEPRegisterSignal(signal)
      _ENV["EEPOnSignal_"..signal] = function(pos)
        printLog(3, "EEPOnSignal_",signal," -> ",pos)
      end
    end

    if not useBetterContacts then                 -- Do not generate functions for entering and leaving blocks if module BetterContacts is used
      -- Generate individual functions which you can use in Lua contacts like 'blockControl.enterBlock_25'
      local funcname = "blockControl"..".".."enterBlock_"..b
      _ENV[funcname] = function (trainName)
        enterBlock(trainName, b)
      end
      -- Generate individual functions which you can use in Lua contacts like 'blockControl.leaveBlock_25'
      local funcname = "blockControl"..".".."leaveBlock_"..b
      _ENV[funcname] = function (trainName)
        leaveBlock(trainName, b)
      end
    end
  end
end

local function copyBlocks (blockSignals)          -- Copy (optional) block signals into local block table.
  for k, signal in pairs(blockSignals) do         -- Collect block numbers
    collectBlock( k, signal )
  end
end

local function copyBlockTracks (blockTracks)
  for b, blockTrack in pairs(blockTracks) do      -- Collect block numbers
    collectBlock( b )
    
    local Block = BlockTab[b]
    
		-- Limitation: Dead ends are not correct:
		--   If the signal is located on the last track of a dead end then you will see last=next.
		--   Instead we have to get next=prev and last=first

    if blockTrack.prev then                       -- Copy named attributes
      Block.prev  = blockTrack.prev
      Block.first = blockTrack.first
      Block.last  = blockTrack.last
      Block.next  = blockTrack.next
    else                                          -- Copy positional attributes
      Block.prev  = blockTrack[1]
      Block.first = blockTrack[2]
      Block.last  = blockTrack[3]
      Block.next  = blockTrack[4]
    end
    
    if type(Block.prev) == "number" then          -- Ensure to use a table even if there is ony one value
      Block.prev = { Block.prev }
    end  
    if type(Block.next) == "number" then          -- Ensure to use a table even if there is ony one value
      Block.next = { Block.next }
    end
    
    -- Register tracks
    local EEPRegisterTrackFunctions = { EEPRegisterRailTrack, EEPRegisterRoadTrack, EEPRegisterTramTrack, EEPRegisterAuxiliaryTrack, EEPRegisterControlTrack }
    local EEPRegisterTrack = EEPRegisterTrackFunctions[trackSystem]
    for k, track in pairs(Block.prev) do
      if not EEPRegisterTrack( track ) then 
        print(stingFormat({
            GER = "Fehler: Gleis %d existiert nicht",
            ENG = "Error: track %d does not exist",
            FRA = "Erreur: la piste %d n'existe pas",
          }, track )
        )
      end
    end
    if not EEPRegisterTrack( Block.first ) then 
      print(stingFormat({
            GER = "Fehler: Gleis %d existiert nicht",
            ENG = "Error: track %d does not exist",
            FRA = "Erreur: la piste %d n'existe pas",
        }, Block.first )
      ) 
    end
    if not EEPRegisterTrack( Block.last ) then 
      print(stingFormat({
            GER = "Fehler: Gleis %d existiert nicht",
            ENG = "Error: track %d does not exist",
            FRA = "Erreur: la piste %d n'existe pas",
        }, Block.last )
      ) 
    end
    for k, track in pairs(Block.next) do
      if not EEPRegisterTrack( track ) then 
        print(stingFormat({
            GER = "Fehler: Gleis %d existiert nicht",
            ENG = "Error: track %d does not exist",
            FRA = "Erreur: la piste %d n'existe pas",
          }, track )
        ) 
      end
    end
    
  end
end

local function copyTwoWayBlocks (twoWayBlocks)
  -- Variable twoWayBlocks offers various data formats:
  -- a) full array of related blocks with block number as key: { 0, 3, 2, 0, 0, 0, 0, 0}
  -- b) array of related blocks with block number as key: { [2] = 3, [3] = 2}
  -- c) set of related blocks: { {2,3} }
  local _, firstEntry = next(twoWayBlocks)
  if type(firstEntry) == "number" then          -- option a) or b)
    for b, twoWayBlock in pairs(twoWayBlocks) do
      if twoWayBlock and twoWayBlock > 0 then
        collectBlock( b )
        BlockTab[b].twoWayBlock = twoWayBlock
      end
    end

  elseif type(firstEntry) == "table" then       -- option c)
    for _, relatedBlocks in pairs(twoWayBlocks) do
      local b1 = relatedBlocks[1]
      local b2 = relatedBlocks[2]
      collectBlock( b1 )
      collectBlock( b2 )
      BlockTab[b1].twoWayBlock = b2
      BlockTab[b2].twoWayBlock = b1
    end

  end  

  for b, Block in pairs(BlockTab) do
    if Block.twoWayBlock and Block.twoWayBlock > 0 then
      printLog(3, "Block ",b," has twoWayBlock ",Block.twoWayBlock)
    end
  end

end

local pathTab = {}                                -- Paths
local function copyPaths (paths)
  -- Expand complex paths and copy them into the path table
  for _, complexPath in pairs(paths) do

    local flatPaths = {{}}              -- Start with one empty path

    --[[
    In the first step we expand a complex path like this
      { {5,6,7}, 26, {12,13} }          -- this is a complex path
    into an array of flat paths:
      {
        { 5, 26, 12 },                  -- this is a flat path (including starting block)
        { 6, 26, 12 },
        { 7, 26, 12 },
        { 5, 26, 13 },
        { 6, 26, 13 },
        { 7, 26, 13 },
      }
    --]]
    for _, part in ipairs(complexPath) do -- Within a path, the order of the parts is important, therefore 'ipairs' is important here

      if type(part) == "number" then
        -- This part is a single block
        local block = part
        collectBlock( block )
        -- Append single block to all previously collected paths
        for _, flatPath in pairs(flatPaths) do
          table.insert(flatPath, block)
        end

      elseif type(part) == "table" then
        -- This part is an array of blocks
        -- Copy all previously collected paths for each block in the array and append the block
        local flatPaths2 = {}
        for _, block in pairs(part) do
          collectBlock( block )
          for _, flatPath in pairs(flatPaths) do
            -- Copy path
            local flatPath2 = {}
            for _, b in ipairs(flatPath) do -- Within a path, the order of the blocks is important, therefore 'ipairs' is important here
              table.insert(flatPath2, b)
            end
            -- Append block
            table.insert(flatPath2, block)
            -- Store path
            table.insert(flatPaths2, flatPath2)
          end
        end
        flatPaths = flatPaths2

      end
    end

    --[[
    Now we copy the flat paths into seperate parts of the path table to allow fast access to all paths starting from a specific block:
      {
        [5] = {                                       -- this is a starting block
                { 5, 26, 12 },                        -- this is a path
                { 5, 26, 13 },
              },
        [6] = {
                { 6, 26, 12 },
                { 6, 26, 13 },
              },
        [7] = {
                { 7, 26, 12 },
                { 7, 26, 13 },
              },
      },
    --]]
    for _, flatPath in pairs(flatPaths) do
      flatPath.visits = 0                             -- Statistic counter how often a train used this path
      local fromBlock = flatPath[1]                   -- The first block is a starting block
      if not pathTab[fromBlock] then
        pathTab[fromBlock] = {}                       -- create new entry for this starting block
      end
      table.insert(pathTab[fromBlock], flatPath)      -- append entry to starting block
    end

  end
end

local routeTab = {}                               -- Routes
local TurnReserved  = {}                          -- Stores the free/reserved state for every turnout, false=free, true=reseved
local function copyRoutes (routes)                -- Copy routes into route table and generate entries in path table
  for r, Route in pairs(routes) do
    local fromBlock = Route[1]
    local toBlock = Route[2]
    
    collectBlock( fromBlock )                     -- Collect block numbers
    collectBlock( toBlock )

    reversingRoutesExist = reversingRoutesExist or Route.reverse  -- Does there exist any reversing routes?
    
    -- Limitation: currently only one route between both blocks can be processed
    -- Simple solution: use the first found route between both blocks
    -- Better solution: use the shortest route between both blocks
    local turn  = Route.turn or {}                -- turn is optional if there are no turnouts for this route
    local found = false
    for _r, _Route in pairs(routeTab) do
      if _Route[1] == fromBlock and _Route[2] == toBlock then  -- Do we know such a route already?
        found = true
        
        printLog(1, stringFormat({
            GER = "Eine alternative Route von Block %d nach Block %d wird ignoriert. Es wird nur die kürzeste Route verwendet.", 
            ENG = "Alternate route from block %d to block %d is ignored. Only the shortest route is used.", 
            FRA = "L'itinéraire alternatif du bloc %d au bloc %d est ignoré. Seul l'itinéraire le plus court est utilisé.", 
          }, fromBlock, toBlock )
        )
        
        if #_Route.turn > #turn then                           -- Is the new route shorter than the known route?
          _Route.turn = turn                                   -- Store the shorter route
        end		  
        break
      end
    end

    if not found then 
      table.insert(routeTab, {                      -- Store only one route between both blocks 
        fromBlock, 
        toBlock, 
        turn = turn, 
        
        reverse = Route.reverse,                    -- Reverse direction when leaveing the from block
        
        visits = 0,                                 -- Statistic counter how often a train has used this route 
      } )
    end     
    
    if Route.turn then
      for to = 1, #Route.turn / 2 do                -- Collect turnout numbers
        local switch = Route.turn[to*2-1]
        local pos    = Route.turn[to*2]
        
        if TurnReserved[ switch ] == nil then
          TurnReserved[ switch ] = false
        end
      end
    end

    local pathExists                              -- Check if a (required) path already exists
    if pathTab[fromBlock] then 
      for _, flatPath in pairs(pathTab[fromBlock]) do
        if flatPath[1] == fromBlock and flatPath[2] == toBlock then
          pathExists = true
        end  
      end
    end
    
    if pathExists then                            -- Generate path for this route if no explicit path is provided
      printLog(2, stringFormat({
          GER = "Pfad für Route von Block %d nach Block %d bereits gefunden",
          ENG = "Path for route from block %d to block %d already found",
          FRA = "Le chemin pour la route du bloc %d au bloc %d a déjà été trouvé",
        }, fromBlock, toBlock )
      )
      
    else
      printLog(2, stringFormat({
          GER = "Generierter Pfad für Route von Block %d nach Block %d",
          ENG = "Generated path for route from block %d to block %d",
          FRA = "Chemin généré pour la route du bloc %d au bloc %d",
        }, fromBlock, toBlock )
      )
      
      if not pathTab[fromBlock] then
        pathTab[fromBlock] = { }                  -- Create new entry for this starting block
      end
      local flatPath = { fromBlock, toBlock }
      flatPath.visits = 0,                        -- Statistic counter how often a train used this path
      table.insert(pathTab[fromBlock], flatPath ) -- append entry to starting block
    end
  end
end

--local TrainTab = {}                               -- Trains (already defined above)
local function copyTrains (Trains)                -- Copy trains with allowed blocks into local train table. (The function uses 'BlockTab').

  for t, Train in pairs(Trains) do
  
    local trainName = (string.sub(Train.name, 1, 1) == "#" and Train.name or "#"..Train.name) -- Add leading # character to align names with EEP
  
    if Train.allowed then 
      for b, waitTime in pairs(Train.allowed) do  -- Collect block numbers
        collectBlock( b )
      end
      for b, _ in pairs(BlockTab) do
        if not Train.allowed[b] then 
          Train.allowed[b] = 0                    -- Other blocks are forbidden
        end  
        if Train.allowed[b] == true then 
          Train.allowed[b] = .1                   -- replace true with number
        end  
      end
      
    else                                          -- No allowed blocks defined
      Train.allowed = {}
      for b, Block in pairs(BlockTab) do
        Train.allowed[b] = .1                     -- Train can go everywhere 
      end
    end
    
    if Train.signal == 0 then
      Train.signal = nil
    end

    TrainTab[trainName] = {
      name    = trainName,
      signal  = Train.signal,                     -- Train signal (optional)
      allowed = Train.allowed,                    -- Allowed blocks per train
      block   = nil,                              -- Current block where the train is
      
      --targetSpeed = targetSpeed,                  -- see below
      --speed       = speed,                        -- see below
      slot        = Train.slot,                   -- EEP versions below 14.2 cannot handle tag texts, in this case slots are used 
      
      visits  = 0,                                -- Statistic counter how often a train visited a block
    }

    -- Get train speed to be able to reverse the direction of a train at a block signal
    local ok, speed
    local data = readTrainData( trainName )
    if type(data) == "table" and data.speed then
      speed = data.speed
      printLog(3, "speed found '",trainName,"' ", speed, " ",type(speed), " ", math.type(speed) )
    else  
      -- store current speed in the tag text of the train   
      ok, speed = EEPGetTrainSpeed( trainName )
      if speed ~= 0 then
        storeTrainData( trainName, { speed = speed } )
      end
    end
    printLog(3, "A speed set '",trainName,"' ", speed, " ",type(speed), " ", math.type(speed) )

    local targetSpeed = (Train.speed and math.abs(Train.speed) or speed)

    TrainTab[trainName].targetSpeed = targetSpeed    -- The target speed is used to set the speed while reversing the direction of trains
    TrainTab[trainName].speed       = speed          -- The current speed is used to calculate the sign of the speed while reversing the direction of trains
    
  end
end

local function printData ()
  
  print(
    "\n"..
    stringFormat({
      GER = "Blöcke",
      ENG = "Blocks",
      FRA = "Blocs",
    })..
    ":"
  )
  for b, Block in pairsByKeys(BlockTab) do
    if useBlockIndexNumbers then 
      print(
        stringFormat({
            GER = "Block %d",
            ENG = "Block %d",
            FRA = "Bloc %d",
          }, b ),
        " ",
        stringFormat({
            GER = "Signal %d",
            ENG = "Signal %d",
            FRA = "Signal %d",
          }, Block.signal )
      )
    else  
      print(
        stringFormat({
            GER = "Block %d",
            ENG = "Block %d",
            FRA = "Bloc %d",
          }, Block.signal )
      )
    end  
  end

  print(
    "\n"..
    stringFormat({
      GER = "Routen",
      ENG = "Routes",
      FRA = "Routes",
    })..
    ":"
  )
  local sortRoutes = function(a,b) 
    local ra = routeTab[a]
    local rb = routeTab[b]
    return ra[1] == rb[1] and ra[2] < rb[2] or ra[1] < rb[1] 
  end  
  for _, Route in pairsByKeys(routeTab, sortRoutes) do
    print(
      stringFormat({
          GER = "Von Block %d nach Block %d über Weichen %s",
          ENG = "From block %d to block %d via turnouts %s",
          FRA = "Du bloc %d au bloc %d via les aiguillages %s",
        }, Route[1], Route[2], table.concat(Route.turn, ", ") ),
      (Route.reverse
        and stringFormat({
            GER = " mit Umkehrung der Richtung beim Startlock",
            ENG = " reverse direction at starting block", 
            FRA = " averc inversion de la direction au bloc de départ",
          })
        or ""
      )
    )
  end

  print(
    "\n"..
    stringFormat({
        GER = "Erweiterte Pfade",
        ENG = "Expanded paths",
        FRA = "Des chemins élargis",
    })..
    ":"
  )
  for fromBlock, paths in pairs(pathTab) do
    for _, path in pairs(paths) do
      print(stringFormat({
          GER = "Von Block %d auf Pfad %s",
          ENG = "From block %d on path %s",
          FRA = "Du bloc %d sur le chemin %s",
        }, fromBlock, table.concat(path, ", ") )
      )
    end
  end

  print(
    "\n"..
    stringFormat({
        GER = "Züge",
        ENG = "Trains",
        FRA = "Trains",
    })..
    ":"
  )
  for _, Train in pairsByKeys(TrainTab) do
    local allowedBlocks = ""
    for b, waitTime in pairsByKeys(Train.allowed) do
      if waitTime > 0 then
        --allowedBlocks = allowedBlocks..(allowedBlocks == "" and "" or ", " ).."["..b.."]="..waitTime
        allowedBlocks = allowedBlocks..(allowedBlocks == "" and "" or ", " )..b
      end  
    end  
  
    print(
      stringFormat({
          GER = "Zug '%s'", 
          ENG = "Train '%s'", 
          FRA = "Train '%s'", 
        }, Train.name ),
      ", ",  
      (Train.signal      
        and stringFormat({
                GER = "Signal %s",
                ENG = "Signal %s",
                FRA = "Signal %s",
              }, Train.signal )
        or ""),
      ", ",  
      (Train.targetSpeed 
        and stringFormat({
                GER = "Zielgeschwindigkeit %.1f km/h",
                ENG = "target speed %.1f km/h",
                FRA = "vitesse cible %.1f km/h",
              }, Train.targetSpeed )                
        or ""),
      ", ",  
      (Train.speed
        and stringFormat({
                GER = "letzte Geschwindigkeit %.1f km/h",
                ENG = "last speed %.1f km/h",
                FRA = "dernière vitesse %.1f km/h",
              }, Train.speed )
        or ""),       
      ", ",
      stringFormat({
          GER = "erlaubte Blöcke %s",
          ENG = "allowed blocks %s",
          FRA = "blocs autorisés %s",
        }, allowedBlocks )
    )
  end
  
  print("")
end 

-- API function to initialize the module
local function init ( Options )
--[[
Options.logLevel          Log level 0 (default): off, 1: normal, 2: full, 3: extreme
Options.language          Language GER, ENG (default), FRA

Options.MAINSW            ID of the main switch (optional)

Options.MAINON            ON    state of main switch (optional)
Options.MAINOFF           OFF   state of main switch (optional)
Options.BLKSIGRED         RED   state of block signals (optional)
Options.BLKSIGGRN         GREEN state of block signals (optional)
Options.TRAINSIGRED       RED   state of train signals (optional)
Options.TRAINSIGGRN       GREEN state of train signals (optional)

Options.trains            Trains including allowed blocks per train to find a path

Options.blockSignals      Block signals
Options.twoWayBlocks      Two way twin blocks (array or set of related blocks)

Options.routes            Routes via turnouts from one block to the next block

Options.paths             Paths on which trains can go
--]]

  if Options.language and ({ GER = true, ENG = true, FRA = true, })[Options.language] then
    language = Options.language
  end

  check(BLKSIGRED == nil, stringFormat({
      GER = "Fehler: Modul blockControl ist bereits initialisiert",
      ENG = "Error: Module blockControl is already initialized",
      FRA = "Erreur: Le module blockControl est déjà initialisé",
  }))

  if Options.logLevel then
    logLevel = Options.logLevel
  end

  printLog(1, stringFormat({
      GER = "Version des Moduls blockControl: %s",
      ENG = "Version of module blockControl: %s",
      FRA = "Version du module blockControl: %s",
    }, _VERSION )
  )

  if Options.BetterContacts ~= nil then
    useBetterContacts = Options.BetterContacts
  end

  MAINSW        = Options.MAINSW      or 0  -- ID of the main switch

  -- Default values for the state of signals
  MAINON        = Options.MAINON      or 1  -- ON    state of main switch
  MAINOFF       = Options.MAINOFF     or 2  -- OFF   state of main switch
  BLKSIGRED     = Options.BLKSIGRED   or 1  -- RED   state of block signals
  BLKSIGGRN     = Options.BLKSIGGRN   or 2  -- GREEN state of block signals
  TRAINSIGRED   = Options.TRAINSIGRED or 1  -- RED   state of train signals
  TRAINSIGGRN   = Options.TRAINSIGGRN or 2  -- GREEN state of train signals


  EEPSetSignal( MAINSW, MAINOFF, 1 )           -- Main stop, do not allow creating any new requests

  -- Toggle visibility of tipp texts via callback function of the main switch
  if MAINSW > 0 then
    EEPRegisterSignal(MAINSW)               -- Toggle visibility of tipp texts via callback function of the main switch
    _ENV["EEPOnSignal_"..MAINSW] = function(pos)
      if pos == MAINON then
        showTippText = not showTippText
        
        printLog(2, stringFormat({
            GER = "Tipp-Text umschalten: %s",
            ENG = "Toggle tipp text: %s",
            FRA = "Texte de basculement: %s",
          }, tostring(showTippText) )
        )
        
      end
    end
  end


  -- Decide if block numbers are 
  -- a) based on array index numbers or 
  -- b) based on block signal numbers:
  useBlockIndexNumbers = false
  -- Check if all block numbers in routes match to possible block index numbers
  if Options.blockSignals and Options.routes then 
    useBlockIndexNumbers = true
    for r, Route in pairs(Options.routes) do
      if   Route[1] > #Options.blockSignals 
        or Route[2] > #Options.blockSignals then
        useBlockIndexNumbers = false
      end  
    end
  end
  if useBlockIndexNumbers then
    printLog(2, stringFormat({
        GER = "Blockindexnummern 1, ..., %d werden zur Identifizierung von Blöcken verwendet", 
        ENG = "Block index numbers 1, ..., %d are used to identify blocks", 
        FRA = "Les numéros d'index de bloc 1, ..., %d sont utilisés pour identifier les blocs", 
      }, #Options.blockSignals )
    )
    
  else
    printLog(2, stringFormat({
        GER = "Blocksignalnummern werden zur Identifizierung von Blöcken verwendet",
        ENG = "Block signal numbers are used to identify blocks",
        FRA = "Les numéros de signal de bloc sont utilisés pour identifier les blocs",
    }))
  end  


  -- Get block data (optional)
  --check( Options.blockSignals, "Error in 'blockSignals': Missing block data")
  if Options.blockSignals then 
    -- Copy block signals into local block table.
    copyBlocks( Options.blockSignals )
  end


  -- Get block track data (optional)
  if Options.trackSystem and Options.blockTracks then 
    trackSystem = Options.trackSystem
    -- Copy block track signals into local block table.
    copyBlockTracks( Options.blockTracks )
  end
  
  
  -- Get two way twin blocks data
  if Options.twoWayBlocks then -- optional
    -- Consistency checks (only possible if blockSignals are available)
    if Options.blockSignals then 
      local _, firstEntry = next(Options.twoWayBlocks)
      if type(firstEntry) == "number" then          -- option a) or b)
        for b, twoWayBlock in pairs(Options.twoWayBlocks) do
          if twoWayBlock and twoWayBlock >= 1 then
          
            check( BlockTab[twoWayBlock], stringFormat({
                GER = "Fehler in 'twoWayBlocks': Unbekannter Block %d in twoWayBlock[%d]",
                ENG = "Error in 'twoWayBlocks': Unknown block %d in twoWayBlock[%d]",
                FRA = "Erreur dans 'twoWayBlocks': Bloc inconnu %d dans twoWayBlock[%d]",
              }, twoWayBlock, b )
            )
            
          end
        end

      elseif type(firstEntry) == "table" then       -- option c)
        for k, relatedBlocks in pairs(Options.twoWayBlocks) do
          local b1 = relatedBlocks[1]
          local b2 = relatedBlocks[2]
          
          check(b1 >= 1 and BlockTab[b1], stringFormat({
              GER = "Fehler in 'twoWayBlocks': Unbekannter Block %d in twoWayBlock[%d]",
              ENG = "Error in 'twoWayBlocks': Unknown block %d in twoWayBlock[%d]",
              FRA = "Erreur dans 'twoWayBlocks': Bloc inconnu %d dans twoWayBlock[%d]",
            }, b1, k )
          )
          
          check(b2 >= 1 and BlockTab[b2], stringFormat({
              GER = "Fehler in 'twoWayBlocks': Unbekannter Block %d in twoWayBlock[%d]",
              ENG = "Error in 'twoWayBlocks': Unknown block %d in twoWayBlock[%d]",
              FRA = "Erreur dans 'twoWayBlocks': Bloc inconnu %d dans twoWayBlock[%d]",
            }, b2, k )
          )
          
        end
      end
    end 

    -- Copy two way twin blocks into local block table.
    copyTwoWayBlocks( Options.twoWayBlocks )
  end

  -- Get additional paths (optional)
  --check( Options.paths, "Error in 'paths': Missing path data")
  if Options.paths then 
    -- Copy routes into local path table.
    copyPaths( Options.paths )
  end

  -- Get route data
  check( Options.routes, "Error in 'routes': Missing route data")
  -- Consistency checks (only possible if blockSignals are available)
  if Options.blockSignals then 
    local fromBlocks = {}
    local toBlocks   = {}
    for r, Route in pairs(Options.routes) do
      local b1 = Route[1]
      local b2 = Route[2]
      
      -- Do routes contain existing blocks only (or do we see more numbers)?
      check( b1 >= 1 and BlockTab[b1], stringFormat({
          GER = "Fehler in 'routes': Unbekannter erster Block %d in route[%d]",
          ENG = "Error in 'routes': Unknown first block %d in route[%d]",
          FRA = "Erreur dans 'routes': Premier bloc inconnu %d dans route[%d]",
        }, b1 , r )
      )
      
      check( b2 >= 1 and BlockTab[b2], stringFormat({
          GER = "Fehler in 'routes': Unbekannter zweiter Block %d in route[%d]",
          ENG = "Error in 'routes': Unknown second block %d in route[%d]",
          FRA = "Erreur dans 'routes': Deuxième bloc %d inconnu dans route[%d]",
        }, b2, r )
      )
      
      -- Do all blocks have at least one route where this block is the first block?
      fromBlocks[b1] = true
      -- Do all blocks have at least one route where this block is the second block?
      toBlocks[b2] = true
      
      -- Consistency checks for Route.turn      
      check( #Route.turn % 2 == 0, stringFormat({
          GER = "Fehler in 'routes': Kein Paar von Daten in route[%d].turn",
          ENG = "Error in 'routes': No pair of data in route[%d].turn",
          FRA = "Erreur dans 'routes': Aucune paire de données dans route[%d].turn",
        }, r )
      )
      
    end
    for b, _ in pairs(BlockTab) do
    
      -- Do all blocks have at least one route where this block is the first block?
      check(fromBlocks[b], stringFormat({
          GER = "Fehler in 'routes': Block %d ist kein Startblock einer Route",
          ENG = "Error in 'routes': Block %d is not a starting block of any route",
          FRA = "Erreur dans 'routes': Le bloc %d n'est pas le bloc de départ d'un itinéraire",
        }, b )
      )
      
      -- Do all blocks have at least one route where this block is the second block?
      check(toBlocks[b], stringFormat({
          GER = "Fehler in 'routes': Block %d ist kein Zielblock einer Route",
          ENG = "Error in 'routes': Block %d is not a target block of any route",
          FRA = "Erreur dans 'routes': Le bloc %d n'est pas un bloc cible d'une route",
        }, b )
      )
      
    end
  end
  
  -- Copy routes into local route table and generate paths.
  copyRoutes( Options.routes )


  -- Consistency checks (it's easier, to validate the data after expansion of the paths)
  local fromBlocks = {}
  local toBlocks   = {}
  for fromBlock, paths in pairs(pathTab) do
    -- Do all blocks have at least one path where this block is the starting block?
    fromBlocks[fromBlock] = true
    for p, path in pairs(paths) do
      for k, block in ipairs(path) do -- Within a path, the order of the blocks is important, therefore 'ipairs' is important here
      
        -- Do paths contain existing blocks only (or do we see more numbers)?
        check( block >= 1 and BlockTab[block], stringFormat({
            GER = "Fehler in 'routes' / 'paths': Unbekannter Block %d in einem Pfad, der mit Block %d beginnt",
            ENG = "Error in 'routes' / 'paths': Unknown block %d in a path starting from block %d",
            FRA = "Erreur dans 'routes' / 'paths': Bloc %d inconnu dans un chemin commençant par le bloc %d",
          }, block, fromBlock ) 
        )
        
        -- Do all blocks have at least one path where this block is a via or an ending block?
        if k > 1  then toBlocks[block] = true end
      end
    end
  end
  for b, _ in pairs(BlockTab) do
  
    -- Do all blocks have at least one route where this block is the first block?
    check(fromBlocks[b], stringFormat({
        GER = "Fehler in 'routes' / 'paths': Block %d ist kein Startblock eines Pfades",
        ENG = "Error in 'routes' / 'paths': Block %d is not a starting block of any path",
        FRA = "Erreur dans 'routes' / 'paths': Le bloc %d n'est pas le bloc de départ d'un chemin.",
      }, b )
    )
    
    -- Do all blocks have at least one route where this block is the second block?
    check(toBlocks[b], stringFormat({
        GER = "Fehler in 'routes' / 'paths': Block %d ist weder ein Durchgangs- noch ein Zielblock eines Pfades",
        ENG = "Error in 'routes' / 'paths': Block %d is not a via or a target block of any path",
        FRA = "Erreur dans 'routes' / 'paths': Le bloc %d n'est pas un bloc via ou un bloc cible d'un chemin",
      }, b )
    )
    
  end
  
  
  -- Get train data
  if Options.trains then
    -- Copy trains with allowed blocks into local train table.
    -- More data is added while running.
    -- (The function uses 'BlockTab').
    copyTrains( Options.trains )
  else
    printLog(1, stringFormat({
        GER = "Es werden keine Zugdaten bereitgestellt. Warten Sie, bis alle Züge erfasst sind, bevor Sie den Automatikmodus starten.",
        ENG = "No train data is provided. Wait until all trains are detected before starting automatic mode.",
        FRA = "Aucune donnée sur les trains n'est fournie. Attendez que tous les trains soient détectés avant de lancer le mode automatique.",
      })
    )
  end

  -- Show data
  if logLevel >= 2 then
    printData()
  end  
  
end

-- API function to set runtime parameters of the module
local function set ( Options )
--[[
Options.logLevel          Log level 0 (default): off, 1: normal, 2: full, 3: extreme
Options.language          Language GER, ENG (default), FRA
Options.showTippText      Show (true) or hide (false) tipp texts on signals
Options.start             Set the main signal "green" (true) respective to "red" (false) as soon as find mode is finished
Options.startAllTrains    Set the train signals of all trains to "green" (true) respective to "red" (false)
--]]

  if Options.language and ({ GER = true, ENG = true, FRA = true, })[Options.language] then
    language = Options.language
  end
  
  if Options.logLevel then
    logLevel = Options.logLevel
  end

  if Options.showTippText ~= nil then
    showTippText = Options.showTippText
  end

  -- Activate/deactivate main signal
  if Options.start ~= nil then
    EEPSetSignal( MAINSW, (Options.start and MAINON or MAINOFF), 1 )
  end

  -- Activate/deactivate all train signals
  if Options.startAllTrains ~= nil then
    for t, Train in pairs(TrainTab) do
      if Train.signal then
        EEPSetSignal( Train.signal, (Options.startAllTrains and TRAINSIGGRN or TRAINSIGRED), 1 )
      end
    end
  end

end


local DummyTrain    = { name = "#Dummy train" }   -- Dummy train which could reserve a twin block

math.randomseed(os.time())                        -- Initialization of random generator
local cycle = 0
local runtime = {
    total           = 0.0,                        -- total runtime of function run (average = total / cycle) 
    min             = 9999.9,                     -- mimimal runtime of function run
    max             = 0.0,                        -- maximal runtime of function run
}


-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Initialization - find trains
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local findMode = true
local function findTrains ()
  local text = stringFormat({
    GER = "Der Modus 'Zugsuche' ist aktiv",
    ENG = "The 'Find Train' mode is active",
    FRA = "Le mode de 'recherche de train' est actif",
  })
  if cycle == 1 then 
    printLog(1, text)
  end  
  if cycle <= 7 then -- I've no idea why it is neccessary to wait for at least 7 cycles after loading a layout
    if EEPShowInfoTextTop then
      local r, g, b   = 1, 1, 1   -- red, green, blue
      local size      = 1         -- Font size 0.5 .. 2
      local duration  = 10        -- Duration in seconds, min. 5 sec.
      local alignment = 1         -- block = 0, central = 1, left = 2, right = 3
      local ok        = EEPShowInfoTextTop(r, g, b, size, duration, alignment, text)   
    end
  end

  -- Find trains in blocks
  for b, Block in pairs(BlockTab) do
    local signal = Block.signal
    local trainName = EEPGetSignalTrainName(signal, 1)  -- Get the train name from the block signal

    if trainName == "" and Block.occupied then          -- Get the train name from the contact
      trainName = Block.occupied
    end
    if trainName ~= "" then                             -- The block knows a train
    
      local ok, speed = EEPGetTrainSpeed( trainName )   -- Get current speed

      if speed == 0 then 
        printLog(3, string.format("Train '%s' is located in block %d", trainName, b))
      else
        printLog(3, string.format("Train '%s' is running in block %d with speed %.1f km/h", trainName, b, speed))
      end  

      local Train = TrainTab[trainName]                 -- Get the train
      if not Train then                                 -- Is it a new train?

        local targetSpeed                               -- Get target speed to be able to reverse the direction of the train at a block signal
        local data = readTrainData( trainName )
        if type(data) == "table" and data.speed then
          targetSpeed = math.abs(data.speed)
        else
          targetSpeed = math.abs(speed)
          -- store current speed in the tag text of the train   
          storeTrainData( trainName, { block = b, speed = speed } )
        end

        Train = {                                       -- Create an entry for an new train (without train signal)
          name = trainName, 
          allowed = {}, 
          visits = 0, 

          targetSpeed = targetSpeed,                    -- The target speed is used to set speed while reversing the direction of trains
          speed   = speed,                              -- The current speed is used to calculate the sign of the speed while reversing the direction of trains          
        }

        for b, _ in pairs(BlockTab) do
          Train.allowed[b] = .1                         -- Such trains can go everywhere
        end
        
        TrainTab[trainName] = Train
        printLog(1, stringFormat({
            GER = "Neuen Zug '%s' im Block %d mit Zielgeschwindigkeit %.1f km/h anlegen", 
            ENG = "Create new train '%s' in block %d with target speed %.1f km/h", 
            FRA = "Création d'un nouveau train '%s' dans le bloc %d avec la vitesse cible %.1f km/h", 
          }, trainName, b, Train.targetSpeed )
        )

      elseif not Train.block then                       -- We can assign the block to a named train.
        if reversingRoutesExist then                    -- The target speed is required to reverse trains
          if Train.targetSpeed ~= 0 then 
            printLog(1, stringFormat({
                GER = "Zug '%s' gefunden in Block %d mit Zielgeschwindigkeit %.1f km/h", 
                ENG = "Train '%s' found in block %d with target speed %.1f km/h", 
                FRA = "Train '%s' trouvé dans le bloc %d avec une vitesse cible de %.1f km/h", 
              }, trainName, b, Train.targetSpeed )
            )
            
          else  
            print(stringFormat({
                GER = "Fehler: Der Zug '%s' in Block %d hat keine Zielgeschwindigkeit", 
                ENG = "Error: Train '%s' found in block %d has no target speed", 
                FRA = "Erreur: Le train '%s' trouvé dans le bloc %d n'a pas de vitesse cible", 
              }, trainName, b )
            )
            
          end
        else                                            -- No need to handle any target speed
          printLog(1, stringFormat({
              GER = "Zug '%s' in Block %d gefunden", 
              ENG = "Train '%s' found in block %d", 
              FRA = "Train '%s' trouvé dans le bloc %d", 
            }, trainName, b )
          )
          
        end

      else
        -- Train is already known
      end

      Train.block       = b                             -- and occupies the block
      --Train.path        = nil                         -- and has no path yet

      Block.reserved    = Train                         -- Place the train in the block
      Block.occupied    = trainName                     -- Set arrival at new block ...
      Block.occupiedOld = nil                           -- ... to request a new route in next cycle
      local TwoWayBlock = (Block.twoWayBlock and BlockTab[ Block.twoWayBlock ] or nil)
      if TwoWayBlock then TwoWayBlock.reserved = DummyTrain end
      --Block.request     = nil
      
      -- Consistency check: Does the train has any available path?
      local trainHasAvailablePath = false  
      if pathTab[b] then 
        for _, Path in pairs(pathTab[b]) do             -- Find free paths starting at current block
          local pathIsAvailable = true                  -- Is this an available path for this train?
          for k=2, #Path do                             -- Are all next blocks free?
            local nextBlock = Path[k]							      -- Is next block allowed for the train?
            pathIsAvailable = pathIsAvailable and Train.allowed[nextBlock] and Train.allowed[nextBlock] > 0 
          end
          trainHasAvailablePath = trainHasAvailablePath or pathIsAvailable
        end
      end
      
      check( trainHasAvailablePath, stringFormat({
            GER = "Fehler: Kein verfügbarer Pfad für Zug '%s' in Block %d",
            ENG = "Error: No available path for train '%s' in block %d",
            FRA = "Erreur: Aucun chemin disponible pour le train '%s' dans le bloc %d",
          }, Train.name, b )
      )
      
    end
  end

  -- End find mode if user activated the main signal and all trains are assigned to a block
  local finished = true
  local count = 0
  for trainName, Train in pairs(TrainTab) do
    printLog(3, "Train '",trainName,"' was found in block ", (Train.block or "-"))
    if not Train.block then
      finished = false
    else
      count = count + 1
    end
  end
  printLog(3, "FIND MODE finished ", finished and "yes " or "no ", count)
  if finished then
    if not MAINSW or MAINSW == 0 or EEPGetSignal( MAINSW ) == MAINON then
      findMode = false
      
      printLog(1, stringFormat({
          GER = "Der Modus 'Zugsuche' wurde beendet",
          ENG = "The 'Find Train' mode has ended",
          FRA = "Le mode 'Trouver des Trains' est terminé",
        })
      )
      
      if EEPHideInfoTextTop then
        EEPHideInfoTextTop()
      end
    else
      if cycle % 50 == 1 then               -- Do this every 10 seconds, given that EEPMain() runs 5x/s
        local text    = stringFormat({
            GER = "Der Modus 'Zugsuche' hat %d Züge gefunden",
            ENG = "The 'Find Train' mode has detected %d trains",
            FRA = "Le mode 'Trouver des Trains' a détecté %d trains",
          }, count )
          
        printLog(1, text)
        if EEPShowInfoTextTop then
          local r, g, b   = 1, 1, 1   -- red, green, blue
          local size      = 1         -- Font size 0.5 .. 2
          local duration  = 10        -- Duration in seconds, min. 5 sec.
          local alignment = 1         -- block = 0, central = 1, left = 2, right = 3
          local ok        = EEPShowInfoTextTop(r, g, b, size, duration, alignment, text) 
        end
      end
    end
  end
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Show current signal status of all block signals
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local function showSignalStatus()
  if not EEPChangeInfoSignal then return end

  -- <j> linkbündig, <c> zentriert, <r> rechtsbündig, <br> Zeilenwechsel
  -- <b>Fett</b>, <i>Kursiv</i>, <fgrgb=0,0,0> Schriftfarbe, <bgrgb=0,0,0> Hintergrundfarbe
  -- siehe https://www.eepforum.de/forum/thread/34860-7-6-3-tipp-texte-f%C3%BCr-objekte-und-kontaktpunkte/
  local tippTextRED    = "<bgrgb=240,0,0>"
  local tippTextGREEN  = "<bgrgb=0,220,0>"
  local tippTextYELLOW = "<bgrgb=220,220,0>"

  -- Main signal
  if findMode then
    local pos = math.floor( EEPGetSignal( MAINSW ) )
    EEPChangeInfoSignal( MAINSW, 
      "<b>"..stringFormat({
        GER = "Initialisierung: Züge in Blöcken finden",
        ENG = "Initialization: Find trains in blocks",
        FRA = "Initialisation: Trouver les trains dans les blocs",
      }).."</b>"
      ..(logLevel >= 2 and "<br>"..stringFormat({
          GER = "Signalposition %d",
          ENG = "Signal position %d",
          FRA = "Position du signal %d",
        }, pos) or "")
    )
    EEPShowInfoSignal( MAINSW, true )
  else
    local pos = EEPGetSignal( MAINSW )
    EEPChangeInfoSignal(MAINSW, 
      stringFormat({
        GER = "Blockkontrolle ist aktiv",
        ENG = "Block control is active",
        FRA = "Le contrôle de bloc est actif",
      })
      ..(logLevel >= 2 and "<br>"..stringFormat({
          GER = "Signalposition %d",
          ENG = "Signal position %d",
          FRA = "Position du signal %d",
        }, pos) or "")
      .."<br>"
      ..( pos == MAINOFF 
          and tippTextRED..  stringFormat({ GER = "ROT",  ENG = "RED",   FRA = "ROUGE", }) 
          or  tippTextGREEN..stringFormat({ GER = "GRÜN", ENG = "GREEN", FRA = "VERT",  })
        )
    )
    EEPShowInfoSignal( MAINSW, showTippText )
  end

  -- Block signals
  for b, Block in pairs(BlockTab) do
    local Train = Block.reserved

    local signal = Block.signal
    local pos    = EEPGetSignal( signal )
    local trainName = EEPGetSignalTrainName( signal, 1 )    -- Get the name from EEP if the signal already holds the train ...
    if trainName == "" and Train then
      trainName = Train.name                                -- ... otherwise get it from the table
    end

    EEPChangeInfoSignal( signal, 
        stringFormat({
            GER = "Block %d", 
            ENG = "Block %d", 
            FRA = "Bloc %d", 
          }, b )
--    .. string.format(" (%d)", signal)
      .. ( (( findMode and logLevel >= 1 ) or logLevel >= 2 ) 
          and "<br>"..stringFormat({
              GER = "Signalposition %d",
              ENG = "Signal position %d",
              FRA = "Position du signal %d", 
            }, pos) 
          or "")
      .. "<br>"
      .. string.sub(trainName, 2, -1)                 -- Show train name without leading # character
      .. "<br>"
      .. ( Block.occupied 
          and tippTextRED          .. stringFormat({ GER = "besetzt",    ENG = "occupied", FRA = "occupé",  }) 
          or ( Train 
                and tippTextYELLOW .. stringFormat({ GER = "reserviert", ENG = "reserved", FRA = "réservé", })
                or tippTextGREEN   .. stringFormat({ GER = "frei",       ENG = "free",     FRA = "libre",   }) 
             ) 
         )
    )
    EEPShowInfoSignal( signal, showTippText )
  end

  -- Train signals
  for trainName, Train in pairs(TrainTab) do
    if Train.signal then
      local pos = math.floor( EEPGetSignal( Train.signal ) )
      EEPChangeInfoSignal( Train.signal,
           string.sub(trainName, 2, -1)                     -- Show train name without leading # character
        .. ( (( findMode and logLevel >= 1 ) or logLevel >= 2 ) 
              and "<br>"..stringFormat({
                  GER = "Signalposition %d",
                  ENG = "Signal position %d",
                  FRA = "Position du signal %d",  
                }, pos ) 
              or "")
        .. (Train.block 
              and "<br>"..stringFormat({
                  GER = "Block %d",
                  ENG = "Block %d",
                  FRA = "Bloc %d",
                }, Train.block ) 
              or "")
        .. "<br>"
        .. (pos == TRAINSIGRED 
              and tippTextRED   .. stringFormat({ GER = "STOP",  ENG = "STOP", FRA = "STOP",  })
              or  tippTextGREEN .. stringFormat({ GER = "FAHRT", ENG = "GO",   FRA = "ALLEZ", })
           )
      )
      EEPShowInfoSignal( Train.signal, showTippText )
    end
  end
  
  -- Turnouts
  for s, reserved in pairs(TurnReserved) do
    local pos = math.floor( EEPGetSwitch( s ) )
    EEPChangeInfoSwitch( s, 
      stringFormat({ 
          GER = "Weiche %d<br>Position %d<br>",
          ENG = "Turnout %d<br>Position %d<br>",
          FRA = "Aiguillage %d<br>Position %d<br>",
        }, s, pos )
        .. (reserved 
            and tippTextYELLOW .. stringFormat({ GER = "reserviert", ENG = "reserved", FRA = "réservé", })
            or  tippTextGREEN  .. stringFormat({ GER = "frei",       ENG = "free",     FRA = "libre",   })
           )
    )
    EEPShowInfoSwitch( s, showTippText and logLevel >= 0 )
  end
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Print current status of trains, blocks and routes
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local function printStatus( periodicTime )

  if periodicTime and cycle % (periodicTime*5) ~= 0 then -- skip execution depending on cycle count if periodic execution is requested
    return
  end  

  print(
    "\n*** ", 
    stringFormat({
        GER = "Status",
        ENG = "Status",
        FRA = "Statut",
      }),
    " ***"
  )

  print(
    "\n",
    stringFormat({
        GER = "Laufzeit pro Zyklus nach %1.0f sec", 
        ENG = "Run time per cycle after %1.0f sec", 
        FRA = "Temps de fonctionnement par cycle après %1.0f sec", 
      }, cycle / 5 ),
    "\n",
    stringFormat({
        GER = "Durchschnitt: %8.3f sec", 
        ENG = "Average: %8.3f sec", 
        FRA = "Moyenne: %8.3f sec", 
      }, runtime.total / cycle ),
    "\n",
    stringFormat({
        GER = "Max:          %8.3f sec", 
        ENG = "Max:     %8.3f sec", 
        FRA = "Max:     %8.3f sec", 
      }, runtime.max )
    --string.format("\nMin:     %8.3f sec", runtime.min),
    --string.format("\nTotal:   %8.3f sec", runtime.total),
  )

  print(
    "\n",
    stringFormat({
        GER = "Züge",
        ENG = "Trains",
        FRA = "Trains",
    }),
    "\n"
  )

  for trainName, Train in pairsByKeys(TrainTab) do
    
    local text = stringFormat({
        GER = "Zug '%s'",
        ENG = "Train '%s'",
        FRA = "Train '%s'",
      }, trainName )

    if EEPGetTrainLength then 
      local ok, trainLength = EEPGetTrainLength( trainName ) 
      text = text..", "..stringFormat({
          GER = "Länge %d m",
          ENG = "length %d m",
          FRA = "longueur %d m",
        }, math.floor(trainLength) )
    end

    if Train.signal then
      local pos = math.floor( EEPGetSignal( Train.signal ))
      text = text..", "..
        stringFormat({
            GER = "Signal %s", 
            ENG = "Signal %s", 
            FRA = "Signal %s", 
          }, Train.signal )..
        " "..
        (pos == TRAINSIGRED 
          and stringFormat({ GER = "STOP",  ENG = "STOP", FRA = "STOP",  }) 
          or  stringFormat({ GER = "FAHRT", ENG = "GO",   FRA = "ALLEZ", })
        )
    end

    local ok, speed = EEPGetTrainSpeed( trainName )
    if speed and speed ~= 0.0 then
      text = text..", "..string.format("%.1f", speed).." km/h"
    end

    local Block
    if Train.block then
      text = text..", "..
        stringFormat({
            GER = "Block %d",
            ENG = "block %d",
            FRA = "bloc %d",
          }, Train.block )
            
      Block = BlockTab[ Train.block ]
    end

    if Train.path then 
      text = text..", "..
        stringFormat({
            GER = "Pfad %s",
            ENG = "path %s",
            FRA = "chemin %s",
          }, table.concat(Train.path, " ") )
    end 
    
    if Block and not Train.path then 
      text = text..", "..
        stringFormat({
            GER = "Timer %d sec",
            ENG = "timer %d sec",
            FRA = "temps %d sec",
          }, math.floor(Block.stopTimer/5) )
    end

    if Block and Block.request then 
      text = text..", "..
        stringFormat({
            GER = "Route angefordert",
            ENG = "route requested",
            FRA = "route demandée",
          })
    end
    
    text = text..", "..
      stringFormat({
          GER = "besuchte Blöcke: %d",
          ENG = "visited blocks: %d",
          FRA = "blocs visités: %d",
        }, Train.visits )
    
    print(text)
    
  end

  print(
    "\n",
    stringFormat({
        GER = "Blöcke",
        ENG = "Blocks",
        FRA = "Blocs",
      }), 
    "\n"
  )

  for b, Block in pairsByKeys(BlockTab) do
    
    local text = stringFormat({
        GER = "Block %d",
        ENG = "block %d",
        FRA = "Bloc %d",
      }, b )
  
    local pos = math.floor( EEPGetSignal( Block.signal ))
    text = text.." "..
      (pos == BLKSIGRED 
        and stringFormat({ GER = "STOP",  ENG = "STOP", FRA = "STOP",  }) 
        or  stringFormat({ GER = "FAHRT", ENG = "GO",   FRA = "ALLEZ", })
      )
    
    local Train = Block.reserved
    text = text.." "..
      ( Block.occupied 
          and       stringFormat({ GER = "besetzt",    ENG = "occupied", FRA = "occupé",  }) 
          or ( Train 
                and stringFormat({ GER = "reserviert", ENG = "reserved", FRA = "réservé", })
                or  stringFormat({ GER = "frei",       ENG = "free",     FRA = "libre",   })
              ) 
      )
    
    if Block.request then 
      text = text..", "..
        stringFormat({ 
            GER = "Route angefordert",
            ENG = "route requested",
            FRA = "route demandée",
          })
    end

    if Train then 
      text = text.." '"..Train.name.."'"
    end  

    if Block.stopTimer > 0 then 
      text = text..", "..
        stringFormat({
            GER = "Timer %d sec",
            ENG = "timer %d sec",
            FRA = "temps %d sec",
        }, math.floor(Block.stopTimer/5) )
    end
    
    if Block.visits > 0 then
      text = text..", "..
        "visited trains: "..Block.visits
    else
        text = text..", "..
          stringFormat({
              GER = "nicht von Zügen benutzt",
              ENG = "not used by trains",
              FRA = "non utilisé par les trains",
            })
    end
    
    print(text)

  end

  print(
    "\n",
    stringFormat({
      GER = "Routen",
      ENG = "Routes",
      FRA = "Routes",
    }),  
    "\n"
  )

  local sortRoutes = function(a,b) 
    local ra = routeTab[a]
    local rb = routeTab[b]
    return ra[1] == rb[1] and ra[2] < rb[2] or ra[1] < rb[1] 
  end
  for r, Route in pairsByKeys(routeTab, sortRoutes) do
    
    local text = stringFormat({
        GER = "Route von Block %d nach %d",
        ENG = "Route from block %d to %d",
        FRA = "Route du bloc %d à %d",
      }, Route[1], Route[2] )
    
    if Route.visits > 0 then 
        text = text..", "..
          stringFormat({
              GER = "von Zügen benutzt: %d",
              ENG = "used by trains: %d",
              FRA = "utilisé par les trains: %d",
            }, Route.visits )
            
    else
        text = text..", "..
          stringFormat({
              GER = "nicht von Zügen benutzt",
              ENG = "not used by trains",
              FRA = "non utilisé par les trains",
            })
    end
    
    print(text)
  
  end

  print("\n")

end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Function to be called in EEPMain
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local function run ()
  
  cycle = cycle + 1                     -- EEPMain cycle number
  local prefix = string.format("%8.1f ", cycle / 5)  -- prefix for print staments to show the cycle time
  
  local t0 = os.clock()                 -- Prepare to calculate runtime

  if findMode then
    findTrains()                        -- Find trains and assign them to blocks
    showSignalStatus()                  -- Show current signal status
    return
  end

  if cycle % 25 == 1 then               -- Do this every 5 seconds, given that EEPmain() runs 5x/s
    if EEPGetSignal( MAINSW ) == MAINOFF then 
      printLog(1, stringFormat({
          GER = "Hauptschalter von blockControl ist aus",
          ENG = "Main switch of blockControl is off",
          FRA = "L'interrupteur principal du blockControl est éteint",
        })
      ) 
    end
  end

  showSignalStatus()                    -- Show current signal status of all block signals

  local availablePath = {}              -- Stores available paths. Per EEPmain() cycle only one path will be randomly selected fom this table

  for b, Block in pairs(BlockTab) do    -- Check all blocks for arrivals and calculate possible new routes

    local trainName = EEPGetSignalTrainName(Block.signal, 1)    -- Get the name from EEP 

    local Train = Block.reserved        -- A train or a dummy train has reserved this block (could be nil, then the block is free)

    if trainName and trainName ~= "" then 
      printLog(3, prefix, string.format(
        "Main loop: Train '%s' in block %d, occupied='%s', reserved='%s'", 
        trainName, 
        b,
        Block.occupied and Block.occupied      or "NIL",
        Block.reserved and Block.reserved.name or "NIL"
      ))
    end

    -- Constistency check: Do we already know this train?
    if trainName ~= "" then 
      if Train then
        if trainName ~= Train.name then
          print(stringFormat({
              GER = "Fehler: Block %d: Zug am Signal '%s' <> '%s' im Block",
              ENG = "Error: Block %d: Train at signal '%s' <> '%s' in block",
              FRA = "Erreur: Block %d: Train au signal '%s' <> '%s' dans le bloc",
            }, b, trainName, Train.name )               
          )
          
--enterBlock( trainName, b ) --###                               -- Let's try to fix it
        end
      else
        print(stringFormat({
              GER = "Fehler: Block %d: Zug '%s' am Signal, aber kein Zug hat den Block reserviert",
              ENG = "Error: Block %d: Train '%s' at signal but no train has reserved the block",
              FRA = "Erreur: Block %d: Train '%s' au signal mais aucun train n'a réservé le bloc",
          }, b, trainName )               
        )
        
--enterBlock( trainName, b ) --###                               -- Let's try to fix it
     end 
    end      

    if trainName and trainName ~= "" then  
      local ok, speed = EEPGetTrainSpeed(trainName)
      if ok  and math.abs(speed) < 1 then                         -- A train stopped
      
        -- Show the drive time once
        if Train.enterBlockCycle then
          local driveTime = ( cycle - Train.enterBlockCycle ) / 5
          local stopTime = math.max( Train.allowed[b] - driveTime, 0 )
          if driveTime > 1 then
          
            printLog(1, prefix, stringFormat({
                GER = "Zug '%s' hält am Blocksignal %d für mindestens %.0f Sekunden nach einer Fahrzeit von %.0f Sekunden", 
                ENG = "Train '%s' stops at block signal %d for at least %.0f seconds after driving for %.0f seconds", 
                FRA = "Le train '%s' s'arrête au signal de canton %d pendant au moins %.0f secondes après avoir roulé pendant %.0f secondes", 
              }, trainName, b, stopTime, driveTime )
            )
            
          end  
          Train.enterBlockCycle = nil
        end
      
        -- A train stopped at a block but somehow the enter block event was not captured
        if not Block.occupied then
        
          printLog(1, prefix, stringFormat({
              GER = "Zug '%s' mit Geschwindigkeit %.2f in Block %d gefunden, aber kein Ereignis wurde ausgelöst", 
              ENG = "Train '%s' speed %.2f catched in block %d but no event was triggered", 
              FRA = "Le train '%s' à la vitesse %.2f a été intercepté dans le bloc %d mais aucun événement n'a été déclenché", 
            }, trainName, speed, b )
          )
          
          enterBlock( trainName, b )                                -- Let's try to fix it
        end
        
      end  
    end

    if trainName and trainName ~= "" and Train and Train.enterBlockCycle then  -- A train stopped at a block and we want to show the drive time
      -- ...
    end

    if Block.stopTimer > 0 then                                   -- count down the block stop time
      Block.stopTimer = Block.stopTimer - 1
    end


-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check if tracks are occupied based on track reserved functions of EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    if Block.prev then                          -- Does the user has provided track data for blocks?
      -- Get EEP function for current track system
      local EEPIsTrackReservedFunctions = { EEPIsRailTrackReserved, EEPIsRoadTrackReserved, EEPIsTramTrackReserved, EEPIsAuxiliaryTrack, EEPIsControlTrackReserved }
      local EEPIsTrackReserved = EEPIsTrackReservedFunctions[trackSystem]
      
      -- Inspect the first track and all previous tracks of the block
      local ok, occupied, trainName = EEPIsTrackReserved( Block.first, true )
      local firstTrackTrainName = nil
      if occupied then
        firstTrackTrainName = trainName
      end

      local prevTrackTrainName = nil
      for k, track in pairs(Block.prev) do
        local ok, occupied, trainName = EEPIsTrackReserved( track, true )
        if occupied and trainName == firstTrackTrainName then -- ### not perfect 
          prevTrackTrainName = trainName
        end
      end
      
      -- Did a train has entered the block?
      if    Block.prevTrackTrainNameOld                               -- If one of the previous tracks were occupied during pevious cycle
        and not prevTrackTrainName                                    -- and all previous tracks are now free
        and firstTrackTrainName                                       -- and the first track of the block is now occupied 
        and Block.prevTrackTrainNameOld ==  firstTrackTrainName then  -- and the trains are identical
        
        printLog(1, prefix, stringFormat({
            GER = "Gleise prüfen: Zug '%s' fährt in Block %d ein",
            ENG = "Check tracks: Train '%s' enters block %d",
            FRA = "Vérifiez les voies: Le train '%s' entre dans le bloc %d",
          }, firstTrackTrainName, b )
        )
        
        enterBlock( firstTrackTrainName, b )
      end  
      
      
      -- Inspect the last track and all next trecks of the block
      local ok, occupied, trainName = EEPIsTrackReserved( Block.last, true )
      local lastTrackTrainName = nil
      if occupied then
        lastTrackTrainName = trainName
      end      
      
      local nextTrackTrainName = nil
      for k, track in pairs(Block.next) do
        local ok, occupied, trainName = EEPIsTrackReserved( track, true )
        if occupied and trainName == Block.lastTrackTrainNameOld then -- ### not perfect
          nextTrackTrainName = trainName
        end
      end

      -- Did a train has left the block?
       if   Block.lastTrackTrainNameOld                               -- If the last track was occupied during pevious cycle
        and not lastTrackTrainName                                    -- and it's not occupied anymore
        and nextTrackTrainName                                        -- and one of the next tracks is now occupied
        and Block.lastTrackTrainNameOld ==  nextTrackTrainName then   -- and the trains are identical
        
        printLog(1, prefix, stringFormat({
            GER = "Gleise prüfen: Zug '%s' verlässt Block %d",
            ENG = "Check tracks: Train '%s' leaves block %d",
            FRA = "Vérifiez les voies: Le train '%s' quitte le bloc %d",
          }, nextTrackTrainName, b )
        )
        
        leaveBlock( nextTrackTrainName, b )
      end 
     
      -- Store track status to compare it in next run
      Block.prevTrackTrainNameOld = prevTrackTrainName
      Block.lastTrackTrainNameOld = lastTrackTrainName
    end


-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check for released blocks (triggered by function leaveBlock) 
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    if not Block.occupied and Block.occupiedOld then            -- A train released this block
      Block.occupiedOld = Block.occupied                        -- Set block memory old to 'free', now this 'if' statement won't run again

      printLog(1, prefix, stringFormat({
            GER = "Zug '%s' gibt Block %d frei",
            ENG = "Train '%s' releases block %d",
            FRA = "Le train '%s' libère le bloc %d",
          }, Train.name, b )
        ,(Block.twoWayBlock and Block.twoWayBlock > 0 and 
            stringFormat({
                GER = " und Zwillingsblock %d",
                ENG = " and twin block %d",
                FRA = " et bloc jumeau %d",
              }, Block.twoWayBlock ) 
            or "")
        , stringFormat({
              GER = " und fährt weiter auf dem Pfad %s",
              ENG = " and continues on path %s",
              FRA = " et continue sur le chemin %s",
            }, table.concat((Train.path or {}), ", ") )
      )

      Train.block = nil                                         -- Set train to be located outside of any block

      Block.reserved = nil                                      -- Set block to 'free'
      local twoWayBlock = (Block.twoWayBlock and BlockTab[ Block.twoWayBlock ] or nil)
      if twoWayBlock then twoWayBlock.reserved = nil end        -- Also the two way twin block is now 'free'

      Block.stopTimer = 0

      EEPSetSignal( Block.signal, BLKSIGRED, 1 )                -- Set the block signal to RED
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check arrivals and set new path requests (triggered by function enterBlock)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    if Train and Train ~= DummyTrain then                       -- A real train...
      if Block.occupied and not Block.occupiedOld then          -- ... enters a free block which is now occupied by this train
        Block.occupiedOld = Block.occupied                      -- Set block memory old to 'occupied', now this 'if' statement won't run again

        --assert(Train.allowed, "Block "..b.."\nTrain "..Train.name.."\n"..debug.traceback())

        printLog(1, prefix, stringFormat({
            GER = "Zug '%s' kommt in Block %d an",
            ENG = "Train '%s' arrives in block %d",
            FRA = "Le train '%s' arrive dans le bloc %d",
          }, Train.name, b )
          ,(Train.path and 
              stringFormat({
                  GER = " auf dem Pfad %s",
                  ENG = " on path %s",
                  FRA = " sur le chemin %s",
                }, table.concat(Train.path, ", ")
              ) or "")
          ,(Train.allowed[b] > 1 and 
              stringFormat({
                  GER = " und bleibt mindestens für %d Sekunden",
                  ENG = " and stays at least for %d sec",
                  FRA = " et reste au moins pendant %d sec",
                }, Train.allowed[b]
              ) or "")
        )
        -- Store current cycle to be able to calculate the drive time between entering the block and stopping at the signal
        Train.enterBlockCycle = cycle
        
        -- Store train speed to be able to reverse the speed at the block signal
        local ok, speed = EEPGetTrainSpeed( Train.name )
        if speed ~= 0 then -- keep known speed if train is stopped
          Train.speed = speed
          printLog(3, "B speed set '",trainName,"' ", speed, " ",type(speed), " ", math.type(speed) )
        end
        storeTrainData( Train.name, { block = b, speed = Train.speed })
        
        if Train.path then

          local pb = Train.path[1]                              -- Previous block, where the train came from
          local previousBlock = BlockTab[pb]

          if Train.block then                                   -- Is the train still in previous block?
            check(Train.block == pb, stringFormat({
                GER = "Fehler: Aktueller Block %d des Zuges '%s' stimmt nicht mit dem vorherigen Block %d überein",
                ENG = "Error: Current block %d of train '%s' does not match previous block %d",
                FRA = "Erreur: Le bloc actuel %d du train '%s' ne correspond pas au bloc précédent %d",
              }, Train.block, Train.name, pb )
            )

            -- Release previous block

            printLog(2, prefix, 
              stringFormat({
                  GER = "Zug '%s' gibt Block %d frei", 
                  ENG = "Train '%s' releases block %d", 
                  FRA = "Le train '%s' libère le bloc %d", 
                }, Train.name, pb ),
              ( previousBlock.twoWayBlock and previousBlock.twoWayBlock > 0 
                  and stringFormat({
                          GER = " und Zwillingsblock %d",
                          ENG = " and twin block %d",
                          FRA = " et bloc jumeau %d",
                        }, previousBlock.twoWayBlock ) 
                  or ""
              ),
              stringFormat({
                  GER = " und weiter auf dem Pfad %s",
                  ENG = " and continues on path %s",
                  FRA = " et continue sur le chemin %s",
                }, table.concat((Train.path or {}), ", ")
              )
            )

            previousBlock.occupied = nil                         -- Free previous block to react on new trains entering this block
            previousBlock.occupiedOld = nil

            previousBlock.reserved = nil                         -- Set previous block to 'free'
            local twoWayBlock = (previousBlock.twoWayBlock and BlockTab[ previousBlock.twoWayBlock ] or nil)
            if twoWayBlock then twoWayBlock.reserved = nil end   -- Also the two way twin block is now 'free'

            local ok = EEPSetSignal( previousBlock.signal, BLKSIGRED, 1 )   -- Set the block signal to RED
            printLog(2, prefix, "EEPSetSignal( ",previousBlock.signal,", RED )",(ok == 1 and "" or " error") )

          else
            printLog(2, prefix, stringFormat({
                GER = "Der vorherige Block %d des Zuges '%s auf dem Pfad %s ist bereits freigegeben",
                ENG = "Previous block %d of train '%s on path %s is already released",
                FRA = "Le bloc %d précédent du train '%s sur le chemin %s est déjà libéré",
              }, pb, Train.name, table.concat((Train.path or {}), ", ") )
            )
          
          end

          -- Release previous turnouts

            printLog(2, prefix, stringFormat({
                GER = "Suche Route von Block %d nach Block %d zur Freigabe der Weichen",
                ENG = "Search route from block %d to block %d to release turnouts",
                FRA = "Recherche d'un itinéraire du bloc %d au bloc %d pour libérer les aiguillages",
              }, pb, b )  
            )
            
          local turn = nil                                      -- Search route to release the turnouts
          for r, Route in pairs(routeTab) do                    -- (Full table scan is not very efficent but it works fine.)
            if Route[1] == pb and Route[2] == b then            -- Assumption: there exist only one route between both blocks
              turn = Route.turn
              Route.visits = Route.visits + 1                   -- Update statistics
              break                                             -- Use the first found route between both blocks
            end
          end
          if turn then
            local turnouts = {}                                 -- Only used to print the array of turnouts
            for to = 1, #turn / 2 do                            -- The turn table contains pairs of data
              local switch = turn[to*2-1]
              TurnReserved[ switch ] = false                    -- Release the turnouts of the current route
              table.insert(turnouts, switch)
            end
            printLog(2, prefix, stringFormat({
                GER = "Zug '%s' in Block %d gibt Weichen %s frei",
                ENG = "Train '%s' in block %d releases turnouts %s",
                FRA = "Train '%s' dans le bloc %d libère les aiguillages %s",
              }, Train.name, b, table.concat(turnouts,", ") )
            )
            
          end

          -- Process current path

          table.remove(Train.path, 1)                           -- Shorten the path of the train

          if #Train.path < 2 then
            Block.request = Train                               -- Flag is raised that the train in block b requests a new path
            printLog(2, prefix, stringFormat({
                GER = "Zug '%s' beendet den Pfad und fordert einen neuen Pfad von Block %d an",
                ENG = "Train '%s' finishes the path and requests a new path from block %d",
                FRA = "Le train '%s' termine le chemin et demande un nouveau chemin à partir du bloc %d",
              }, Train.name, b )
            )
          else
            printLog(2, prefix, stringFormat({
                GER = "Zug '%s' fährt weiter auf Pfad %s",
                ENG = "Train '%s' continues travelling on path %s",
                FRA = "Le train '%s' continue de circuler sur le chemin %s",
              }, Train.name, table.concat((Train.path or {}), ", ") )
            )
          end

        else -- no train path yet
            Block.request = Train                               -- Flag is raised that the train in block b requests a new path
            printLog(3, prefix, "Train '",Train.name,"' requests a new path from block ",b )
        end

        -- Update train data

        Train.block = b                                         -- Remember the location of the train...
        
        -- Update statistics
        Train.visits = Train.visits + 1
        Block.visits = Block.visits + 1

        if Train.allowed[b] > 1 then
          Block.stopTimer = 5 * Train.allowed[b]                -- Calculate the stop timer in seconds
        else
          Block.stopTimer = 0
        end

      end
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Make a list of all possible paths for trains who's stop stopTimer ran out
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    if Train and Train ~= DummyTrain then                         -- A real train...
      if Block.request and Block.stopTimer == 0 then              -- ... has a request and no wait time (anymore)
        if not Train.signal or EEPGetSignal( Train.signal ) == TRAINSIGGRN then  -- Does this train has a train signal?
          printLog(2, prefix, stringFormat({
              GER = "Zug '%s' sucht einen neuen Pfad ab Block %d",
              ENG = "Train '%s' searches a new path from block %d",
              FRA = "Le train '%s' recherche un nouveau chemin à partir du bloc %d",
            }, Train.name, b ) 
          )
          
          check(b>0, stringFormat({
              GER = "Fehler: Liste der Pfade erstellen: Block b=%d",
              ENG = "Error: Make list of paths: block b=%d",
              FRA = "Erreur: Faire la liste des chemins: bloc b=%d",
            }, b )
          )
          
          
          check(type(pathTab[b])=="table", stringFormat({
              GER = "Fehler: Liste der Pfade erstellen: type(pathTab[%d])=%s",
              ENG = "Error: Make list of paths: type(pathTab[%d])=%s",
              FRA = "Erreur: Faire la liste des chemins: type(pathTab[%d])=%s",
            }, b, type(pathTab[b]) )
          )

          local trainHasAvailablePath = false                     -- Consistency check: Does the train has any available path?

          if pathTab[b] then 
            for _, Path in pairs(pathTab[b]) do                     -- Find free paths starting at current block
              local pathIsAvailable = true                          -- Is this an available path for this train?
              local freePath        = true                          -- Is this a free path for this train

              for k=2, #Path do                                     -- Are all next blocks free?
                local nextBlock = Path[k]
                
                pathIsAvailable = pathIsAvailable and Train.allowed[nextBlock] and Train.allowed[nextBlock] > 0 -- Is next block allowed for the train?
                
                freePath =    freePath                              -- Is it still a free path?
                          and pathIsAvailable                       -- Is it still an available path?
                          and (   BlockTab[nextBlock].reserved    == nil   -- Is next block free?
                               or BlockTab[nextBlock].twoWayBlock == b   ) -- Or is the next block the other block of the same two-way-block?

                printLog(3, prefix, "nextBlock ",nextBlock," wait=",Train.allowed[nextBlock]," ",(BlockTab[nextBlock].reserved and "reserved" or "available"))

              end

              printLog(3, prefix, "Check path ",table.concat(Path, ", "), ": ", (freePath and "free" or "blocked") )

              for k=1, #Path-1 do                                   -- Are all turnouts free?
                local fromBlock = Path[k]
                local toBlock   = Path[k+1]
                if freePath then                                    -- Is it still a free path?
                  for r, Route in pairs(routeTab) do                -- Let's check if all turnouts are free to reach the next block
                    if freePath and Route[1] == fromBlock and Route[2] == toBlock then -- Assumption: there exist only one route between both blocks
                      for to = 1, #Route.turn / 2 do                -- Check if the route turnouts are free
                        local switch = Route.turn[to*2-1]
                        freePath = freePath and not TurnReserved[ switch ]
                        
                        printLog(3, prefix, "From ",fromBlock," to ",toBlock," Check turnout ",switch,": ",(TurnReserved[ switch ] and "locked" or "free"))
                      end
                      break                                         --Use the first found route between both blocks
                    end
                  end
                end

              end

              trainHasAvailablePath = trainHasAvailablePath or pathIsAvailable

              if freePath then                                      -- Is it a free path?
                printLog(2, prefix, stringFormat({
                    GER = "Zug '%s' hat einen freien Pfad von Block %d auf Pfad %s",
                    ENG = "Train '%s' has a free path from block %d on path %s",
                    FRA = "Le train '%s' a un chemin libre à partir du bloc %d sur le chemin %s",
                  }, Train.name, b, table.concat(Path,", ") )
                )
                
                table.insert(availablePath, { Train, b, Path })     -- Store the tuple
              end
            end
          end
          
          check( trainHasAvailablePath, stringFormat({ 
              GER = "Fehler: Kein verfügbarer Pfad für Zug '%s' in Block %d",
              ENG = "Error: No available path for train '%s' in block %d",
              FRA = "Erreur: Aucun chemin disponible pour le train '%s' dans le bloc %d",
            }, Train.name, b )
          )

        end
      end
    end

  end -- for b, Block in pairs(BlockTab)

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Randomly select a path to start from the available ones
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

  if MAINSW > 0 and EEPGetSignal( MAINSW ) == MAINOFF then
    return -- Quit because no new path is activated

  elseif #availablePath > 0 then                                  -- At least one path is available
    printLog(2, prefix, stringFormat({
        GER = "Anzahl der verfügbaren Pfade: %d", 
        ENG = "Count of available paths: %d", 
        FRA = "Nombre de chemins disponibles: %d", 
      }, #availablePath )
    )

    local nr = math.random(#availablePath)                        -- A new path is randomly selected
    local Train, b, Path = table.unpack(availablePath[nr])        -- Get the path
    
    check( b == Path[1], stringFormat({
        GER = "Fehler bei der Auswahl eines neuen Pfads: Unstimmigkeit zwischen dem aktuellen Block %d und dem ausgewählten Pfad %s",
        ENG = "Error while selecting a new path: mismatch between current block %d and selected path %s",
        FRA = "Erreur lors de la sélection d'un nouveau chemin: inadéquation entre le bloc actuel %d et le chemin sélectionné %s",
      }, b, table.concat(Path, ", ") )
    )

    Train.path = {}                                               -- Copy path into the train.
    for k=1, #Path do                                             -- Will be used to unlock blocks and turnouts on the go.
      table.insert(Train.path, Path[k])                           -- It's neccesary to copy the path to be able to remove data from it while travelling.
    end

    printLog(1, prefix, stringFormat({
        GER = "Der Zug '%s' fährt von Block %d auf dem Pfad %s",
        ENG = "Train '%s' travels from block %d on path %s",
        FRA = "Le train '%s' part du bloc %d et emprunte le chemin %s",
      }, Train.name, b, table.concat(Train.path, ", ") )
    )
    
    local Block = BlockTab[b]
    Block.request = nil                                           -- New path is allocated, reset the request for a new path

    -- Lock blocks of the path, set signals, and lock and set turnouts for the path
    local turnouts = {}                                           -- Only used to print the array of turnouts
    local prevBlock = b
    for k = 1, #Train.path do                                     -- Lock all blocks including the starting block of the path
      local nextBlock = Train.path[k]

      local Block = BlockTab[nextBlock]
      Block.reserved = Train                                      -- Reserve the block

      local twoWayBlock = (Block.twoWayBlock and BlockTab[ Block.twoWayBlock ] or nil)
      if twoWayBlock then twoWayBlock.reserved = DummyTrain end   -- Also reserve the two way twin block with the dummy train

      local ok = EEPSetSignal( Block.signal, (k==#Train.path and BLKSIGRED or BLKSIGGRN), 1)  -- Set the block signals to GREEN, the train may go, except for the last one.
      printLog(2, prefix, "EEPSetSignal( ",Block.signal,", ",(k==#Train.path and "RED" or "GREEN")," )",(ok == 1 and "" or " error") )

      if k > 1 then
      for r, Route in pairs(routeTab) do                          -- Search in all routes
        local fromBlock = Route[1]
        local toBlock   = Route[2]
        if prevBlock == fromBlock and nextBlock == toBlock then   -- Assumption: there exist only one route between both blocks
          for to = 1, #Route.turn / 2 do
            local switch = Route.turn[to*2-1]
            local pos    = Route.turn[to*2]
            TurnReserved[ switch ] = true                         -- Reserve the turnout
            EEPSetSwitch( switch, pos, 1 )                        -- Switch the turnout
            table.insert(turnouts, switch)
          end

          if Route.reverse then                                   -- Does the train has to reverse its direction to start the path?
            check(k == 2, stringFormat({
                GER = "Fehler beim Umkehren der Zugrichtung: Strecke von %d nach %d ist nicht der erste Teil (%d) des Pfades %s", 
                ENG = "Error during reversing train direction: Route from %d to %d is not the first part (%d) of the path %s", 
                FRA = "Erreur lors de l'inversion du sens du train: L'itinéraire de %d à %d n'est pas la première partie (%d) du chemin %s", 
              }, fromBlock, toBlock, k,table.concat(Train.path, " ") ) 
            )
            
            if not Train.speed then 
              print(stringFormat({
                  GER = "Fehler beim Umkehren der Zugrichtung: Zug '%s' hat keine gespeicherte Geschwindigkeit",
                  ENG = "Error during reversing train direction: Train '%s' has no stored speed",
                  FRA = "Erreur lors de l'inversion du sens du train: Le train '%s' n'a pas de vitesse enregistrée",
                }, Train.name )
              )

              local ok, speed = EEPGetTrainSpeed( Train.name )    -- Useless if the value is zero

              check(ok, stringFormat({
                  GER = "Fehler beim Umkehren der Zugrichtung: Geschwindigkeit des Zuges '%s' konnte nicht ermittelt werden",
                  ENG = "Error during reversing train direction: could not get train speed for train '%s'",
                  FRA = "Erreur lors de l'inversion de la direction du train: impossible d'obtenir la vitesse du train '%s'",
                }, Train.name )
              )

              check(speed ~= 0, stringFormat({
                  GER = "Fehler beim Umkehren der Zugrichtung: Zug '%s' hat angehalten und hat daher eine unbekannte Richtung",
                  ENG = "Error during reversing train direction: Train '%s' has stopped and therefore has an unknown direction",
                  FRA = "Erreur lors de l'inversion de la direction du train: le train '%s' s'est arrêté et a donc une direction inconnue",
                }, Train.name )
              )

              Train.speed = speed
              printLog(3, "C speed set '",trainName,"' ", speed, " ",type(speed), " ", math.type(speed) )
            end

            if not Train.targetSpeed then 
              print(stringFormat({
                  GER = "Fehler beim Umkehren der Zugrichtung: Der Zug '%s' hat keine Zielgeschwindigkeit für die Richtungsumkehr",
                  ENG = "Error during reversing train direction: Train '%s' does not have a target speed to reverse the direction",
                  FRA = "Erreur lors de l'inversion de la direction du train: Le train '%s' n'a pas de vitesse cible pour inverser le sens de marche",
                }, Train.name )
              )
              
              Train.targetSpeed = Train.speed
            end

            local newSpeed = Train.targetSpeed * (Train.speed >= 0 and -1 or 1)  -- Reverse speed
            local ok = EEPSetTrainSpeed( Train.name, newSpeed )

            check(ok, stringFormat({
                GER = "Fehler beim Umkehren der Zugrichtung: Zuggeschwindigkeit für Zug '%s' konnte nicht eingestellt werden",
                ENG = "Error during reversing train direction: could not set train speed for train '%s'",
                FRA = "Erreur lors de l'inversion de la direction du train: Impossible de définir la vitesse du train '%s'",
              }, Train.name )
            )

            printLog(1, prefix, stringFormat({
                GER = "Geschwindigkeit des Zuges '%s' von %.1f auf %.1f km/h umkehren", 
                ENG = "Reverse speed of train '%s' from %.1f to %.1f km/h", 
                FRA = "Inversion de la vitesse du train '%s' de %.1f à %.1f km/h", 
              }, Train.name, Train.speed, newSpeed )
            )
            
          end

          break                                                   -- Use the first found route between both blocks
        end
      end
      prevBlock = nextBlock                                       -- prepare to lock the next part of the path

    end
    end

    printLog(2, prefix, stringFormat({
        GER = "Zug '%s' in Block %d sperrt und stellt Weichen %s",
        ENG = "Train '%s' in block %d locks and sets turnouts %s",
        FRA = "Le train '%s' du bloc %d verrouille et active les aiguillages %s",
      }, Train.name, b, table.concat(turnouts,", ") )
    )

  end
  
  local t1 = os.clock()                                           -- Timestamp to calculate runtime
  local tdiff = t1 - t0                                           -- Runtime of function run
  runtime.total = runtime.total + tdiff                           -- Sum up total runtime
  if runtime.min > tdiff then runtime.min = tdiff end 
  if runtime.max < tdiff then runtime.max = tdiff end 
  if tdiff > 0.1 then 
    printLog(1, prefix, stringFormat({
        GER = "Hohe Laufzeit: %.3f sec", 
        ENG = "High run time: %.3f sec", 
        FRA = "Temps de fonctionnement élevé: %.3f sec", 
      }, tdiff )
    )
    
  elseif tdiff > 0.01 then  
    printLog(2, prefix, stringFormat({
        GER = "Laufzeit: %.3f sec", 
        ENG = "Run time: %.3f sec", 
        FRA = "Temps de fonctionnement: %.3f sec", 
      }, tdiff)
    )
    
  end  

  return
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Function(s) to be used in Lua contacts 
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--[[
The beginning of blocks is marked by (any type of) contacts which call a specific Lua function to record arriving trains at blocks.

a) You can use Lua functions like this (with N = block number):
blockControl.enterBlock_N

In this case you have to follow following order of actions while designing the EEP layout:
1. Place signals (and optionally empty contacts) and enter the signal numbers into variable "blockSignals"
2. Execute the Lua script once to register the corresponding Lua functions for the blocks.
3. Place contacts if not already done. Enter the Lua function into these contacts.

b) If module "BetterContacts_BH2" is available, you can use a Lua function with parameter instead (with N = block number):
blockControl.enterBlock(Zugname, N)

In this case the order of actions does not matter (after you have executed the Lua script once to initialize the module).
--]]

-- Parametrisied function which you can use in Lua contacts: blockControl.enterBlock(Zugname, 25)
enterBlock = function (trainName, b)              -- (The local variable 'enterBlock' is already defined above)
  local Train = TrainTab[trainName]             -- Get train ...
  local path = Train.path or {}                 -- and current route of that train.

  if not findMode then
    --if b then
    
      -- Consistency checks
      if path[1] and path[2] then                 -- The train has a path 
        check(b == path[2], stringFormat({
            GER = "Zug '%s' fährt in Block %d ein, sollte aber in Block %d einfahren", 
            ENG = "Train '%s' enters block %d but was expected to enter block %d", 
            FRA = "Le train '%s' entre dans le bloc %d mais était censé entrer dans le bloc %d", 
          }, trainName, b, path[2] )
        )
        
      elseif path[1] and not path[2] then         -- The stopped train was catched by a block signal earlier

        if b == path[1] then
          printLog(2, stringFormat({
              GER = "Zug '%s' betritt erneut den Block %d (Ereignis wird ignoriert)", 
              ENG = "Train '%s' re-enters block %d (event is ignored)", 
              FRA = "Le train '%s' rentre dans le bloc %d (l'événement est ignoré)", 
            }, trainName, b )
          )
          
          return                                  -- No need to enter the block again

        else
          printLog(1, stringFormat({
              GER = "Zug '%s' fährt wieder in Block %d ein, aber es wurde erwartet, dass er wieder in Block %d einfährt", 
              ENG = "Train '%s' re-enters block %d but was expected to re-enter block %d", 
              FRA = "Le train '%s' réintègre le bloc %d mais il était prévu qu'il réintègre le bloc %d", 
            }, trainName, b, path[1] )
          )

        end        

      elseif not path[1] then                     -- The train does not have a path
        print(stringFormat({
            GER = "Zug '%s' fährt in Block %d ein, folgt aber keinem Pfad", 
            ENG = "Train '%s' enters block %d but does not follow a path", 
            FRA = "Le train '%s' entre dans le bloc %d mais ne suit pas un chemin", 
          }, trainName, b )
        )                                         
        
      end
      
      printLog(2, stringFormat({
          GER = "Zug '%s' fährt in Block %d ein", 
          ENG = "Train '%s' enters block %d", 
          FRA = "Le train '%s' entre dans le bloc %d", 
        }, trainName, b )
      )
      
    --elseif path[2] > 0 then
    --  b = path[2]
    --  printLog(3, string.format("Train '%s' enters block %d via unspecific enterBlock function", trainName, b))
    --end
  end  

  printLog(3, string.format(
    "enter block: Train '%s' enters block %d, occupied='%s', reserved='%s'", 
    trainName, 
    b,
    BlockTab[b].occupied and BlockTab[b].occupied      or "NIL",
    BlockTab[b].reserved and BlockTab[b].reserved.name or "NIL"
  ))

  BlockTab[b].occupied = trainName                -- Train enters block
  
end

-- Parameterized function which you can use in Lua contacts: blockControl.leaveBlock(Zugname, 25)
leaveBlock = function (trainName, b)              -- (The local variable 'leaveBlock' is already defined above)

  if not findMode then
    local Train = TrainTab[trainName]             -- Get train ...
    local path = Train.path or {}                 -- and current route of that train.
    
    --if b then
    
      -- Consistency checks
      if path[1] and path[2] then                 -- The train has a path 
        check(b == path[1], stringFormat({
            GER = "Zug '%s' verlässt den Block %d, sollte aber den Block %d verlassen", 
            ENG = "Train '%s' leaves block %d but was expected to leave block %d", 
            FRA = "Le train '%s' quitte le bloc %d mais était censé quitter le bloc %d", 
          }, trainName, b, path[1] )
        )
        
        printLog(2, stringFormat({
            GER = "Zug '%s' verlässt Block %d", 
            ENG = "Train '%s' leaves block %d", 
            FRA = "Le train '%s' quitte le bloc %d", 
          }, trainName, b )
        )

      elseif path[1] and not path[2] then          -- Weird situation should not happen
        print(stringFormat({
            GER = "Zug '%s' verlässt Block %d, hat aber einen unvollständigen Pfad", 
            ENG = "Train '%s' leaves block %d but has an incomplete path", 
            FRA = "Le train '%s' quitte le bloc %d mais a un chemin incomplet", 
          }, trainName, b )
        )                                         

      elseif not path[1] then                      -- The train does not have a path
        print(stringFormat({
            GER = "Zug '%s' verlässt Block %d, folgt aber keinem Pfad", 
            ENG = "Train '%s' leaves block %d but does not follow a path", 
            FRA = "Le train '%s' quitte le bloc %d mais ne suit pas un chemin", 
          }, trainName, b )
        )                                         
        
      end
      
    --elseif path[1] > 0 then
    --  b = path[1]
    --  printLog(3, string.format("Train '%s' leaves block %d via unspecific leaveBlock function", trainName, b))
    --end
    
  end 
  
  printLog(3, string.format(
    "leave block: Train '%s' leaves block %d, occupied='%s', reserved='%s'", 
    trainName, 
    b,
    BlockTab[b].occupied and BlockTab[b].occupied      or "NIL",
    BlockTab[b].reserved and BlockTab[b].reserved.name or "NIL"
  ))

  BlockTab[b].occupied = nil                      -- Train leaves block

end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  API of the module
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

return {

  _VERSION    = _VERSION,

  init        = init,       -- Call this function during initialization
  set         = set,        -- Set runtime parameters logLevel and showTippText
  run         = run,        -- Call this function in EEPMain

  enterBlock  = enterBlock, -- Used in contacts, e.g. like this: blockControl.enterBlock(Zugname, 5)
  leaveBlock  = leaveBlock, -- Used in contacts, e.g. like this: blockControl.leaveBlock(Zugname, 5)
  
  printStatus = printStatus, -- Print current status about trains, blocks, routes,...

}