local main_signal = 65

-- Allowed blocks and wait times
local CW = {
  [54]=30, [55]=90,	          -- Station Mid
  [60]= 1,
  [79]=30, [80]=90,           -- Station East
  [62]= 1, [97]= 1, [73]= 1,
  [86]=30, [87]=90,	          -- Station West
  [93]= 1, [74]= 1, 
}

local CCW = {
  [58]=30, [59]=90,	          -- Station Mid
  [52]= 1, [94]= 1,
  [88]=30, [89]=90,           -- Station West
  [96]= 1, [98]= 1, [101]= 1, [53]= 1,
  [75]=30, [76]=90,	          -- Station East
  [61]= 1, 
}

local Cargo = {
  [ 43]=40, [44]=40, [45]=40, [46]=40, [47]=40, -- Cargo Dead End West
  [ 50]= 1, [57]= 1,
  [ 51]= 1,        	          -- Station Mid
  [113]= 1, [60]= 1, [81]= 1, 
  [ 83]= 1,        	          -- Station East
  [107]= 1,
  [ 68]=30, [69]=30, [70]=30, [71]=30,          -- Cargo Dead End East
  [108]= 1,
  [ 78]= 1,        	          -- Station East
  [114]= 1,
  [ 77]= 1, [61]= 1,
  [ 56]= 1,        	          -- Station Mid
  [ 64]= 1, [82]= 1,
}

local Benelux = {
  [7]=40,                     -- Dead End West
  [50]= 1, [57]= 1,
  [51]=30,        	          -- Station Mid
  [113]= 1, [60]= 1, [81]= 1, 
  [83]=30,        	          -- Station East
  [107]= 1,
  [72]=40,                    -- Dead End East
  [108]= 1,
  [78]=30,        	          -- Station East
  [114]= 1,
  [77]= 1,[61]= 1,
  [56]=30,        	          -- Station Mid
  [64]= 1,
}

local Flirt = {
  [54]=30, [55]=30,	          -- Station Mid CW CW CW CW CW 
  [60]= 1,
  [79]=30, [80]=30,           -- Station East
  [62]= 1, [97]= 1, [73]= 1,
  [86]=30, [87]=30,	          -- Station West
  [93]= 1, [74]= 1,
  [58]=30, [59]=30,	          -- Station Mid CCW CCW CCW CCW
  [52]= 1, [94]= 1,
  [88]=30, [89]=30,           -- Station West
  [96]= 1, [98]= 1, [101]= 1, [53]= 1,
  [75]=30, [76]=30,	          -- Station East
  [61]= 1, 
  [63]= 1, [104]= 1,          -- reverse tracks
}

-- Trains
-- The train signal numbers are assigned in the order of signals on the control panel and the GBS
-- The slot numbers are only used on lower EEP versions below 14.2
-- The speed is only used to reverse trains at dead ends.
local trains = {
 { name = "CW1",       signal =  91, allowed = CW,      slot = 1, speed = 80,},
 { name = "CW2",       signal =  90, allowed = CW,      slot = 2, speed = 80,},
 { name = "CCW1",      signal =  85, allowed = CCW,     slot = 3, speed = 50,},
 { name = "CCW2",      signal =  84, allowed = CCW,     slot = 4, speed = 50,},
 { name = "CargoCCW1", signal =  92, allowed = Cargo,   slot = 5, speed = 40,},
 { name = "CargoCCW2", signal = 110, allowed = Cargo,   slot = 6, speed = 40,},
 { name = "CargoCW1",  signal = 109, allowed = Cargo,   slot = 7, speed = 40,},
 { name = "CargoCW2",  signal =  66, allowed = Cargo,   slot = 8, speed = 40,},
 { name = "Benelux",   signal =  67, allowed = Benelux, slot = 9, speed = 50,},
 { name = "Flirt",     signal = 102, allowed = Flirt,   slot =10, speed = 50,},
}

local block_signals = { 7, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 
58, 59, 60, 61, 62, 63, 64, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 
83, 86, 87, 88, 89, 93, 94, 96, 97, 98, 101, 104, 107, 108, 113, 114, }
-- 54 signals use BLKSIGRED = 1, BLKSIGGRN = 2

local two_way_blocks = { 
  { 48, 49 }, 
  { 50, 82 }, 
  { 57, 64 }, 
  { 77, 81 }, 
  { 107, 108 }, 
  { 113, 114 }, 
}

local routes = {
  { 7,  57, turn={ 32,2, 31,1, 30,2, }, reverse=true },
  { 43, 57, turn={ 31,2, 30,2, }, reverse=true },
  { 44, 57, turn={ 30,1, }, reverse=true },
  { 45, 50, turn={ 27,1, }, reverse=true },
  { 46, 50, turn={ 29,2, 28,1, 27,2, }, reverse=true },
  { 47, 50, turn={ 29,1, 28,1, 27,2, }, reverse=true },
  { 48, 50, turn={ 28,2, 27,2, } },
  { 49, 57, turn={ 32,1, 31,1, 30,2, } },
  { 50, 51, turn={ 26,2, 25,1, } },
  { 51, 60, turn={ 17,2, 16,2, 19,1, 20,2, } },
  { 51, 113, turn={ 17,2, 16,1, } },
  { 52, 94, turn={ } },
  { 53, 75, turn={ 42,1, } },
  { 53, 76, turn={ 42,2, } },
  { 54, 60, turn={ 21,2, 20,1, } },
  { 55, 60, turn={ 21,1, 20,1, } },
  { 56, 64, turn={ 25,2, 26,1, } },
  { 56, 82, turn={ 25,2, 26,2, } },
  { 57, 51, turn={ 26,1, 25,1, } },
  { 58, 52, turn={ 24,1, } },
  { 59, 52, turn={ 24,2, } },
  { 60, 79, turn={ 13,1, 14,1, 15,2, } },
  { 60, 80, turn={ 13,1, 14,1, 15,1, } },
  { 60, 81, turn={ 13,2, 11,2, 10,1, } },
  { 60, 104, turn={ 13,1, 14,2, } },
  { 61, 56, turn={ 18,2, 19,2, 16,2, 17,1, } },
  { 61, 58, turn={ 18,1, 22,1, } },
  { 61, 59, turn={ 18,1, 22,2, } },
  { 62, 97, turn={ 40,2, } },
  { 63, 97, turn={ 40,1, } },
  { 64,  7, turn={ 30,2, 31,1, 32,2, } },
  { 64, 43, turn={ 30,2, 31,2, } },
  { 64, 44, turn={ 30,1, } },
  { 64, 48, turn={ 30,2, 31,1, 32,1, } },
  { 68, 108, turn={ 5,2, }, reverse=true },
  { 69, 108, turn={ 4,2, 5,1, }, reverse=true },
  { 70, 108, turn={ 6,2, 4,1, 5,1, }, reverse=true },
  { 71, 108, turn={ 8,2, 6,1, 4,1, 5,1, }, reverse=true },
  { 72, 108, turn={ 8,1, 6,1, 4,1, 5,1, }, reverse=true },
  { 73, 86, turn={ 38,2, } },
  { 73, 87, turn={ 38,1, } },
  { 74, 54, turn={ 23,1, } },
  { 74, 55, turn={ 23,2, } },
  { 75, 61, turn={ 33,1, 12,1, } },
  { 76, 61, turn={ 33,2, 12,1, } },
  { 77, 61, turn={ 10,1, 11,1, 12,2, } },
  { 77, 114, turn={ 10,2, 9,2, } },
  { 78, 114, turn={ 1,1, 9,1, } },
  { 79, 62, turn={ 34,2, } },
  { 80, 62, turn={ 34,1, } },
  { 81, 107, turn={ 3,2, 2,1, } },
  { 82, 45, turn={ 27,1, } },
  { 82, 46, turn={ 27,2, 28,1, 29,2, } },
  { 82, 47, turn={ 27,2, 28,1, 29,1, } },
  { 82, 49, turn={ 27,2, 28,2, } },
  { 83, 107, turn={ 2,2, } },
  { 86, 93, turn={ 39,2, } },
  { 87, 93, turn={ 39,1, } },
  { 88, 96, turn={ 36,2, } },
  { 89, 96, turn={ 36,1, } },
  { 93, 74, turn={ } },
  { 94, 88, turn={ 37,1, } },
  { 94, 89, turn={ 37,2, } },
  { 96, 98, turn={ } },
  { 97, 73, turn={ } },
  { 98, 101, turn={ } },
  { 101, 53, turn={ 41,2, 35,2, } },
  { 101, 63, turn={ 41,2, 35,1, } },
  { 104, 53, turn={ 41,1, 35,2, } },
--  { 104, 63, turn={ 41,1, 35,1, } }, not include reverse to reverse
  { 107, 68, turn={ 5,2, } },
  { 107, 69, turn={ 5,1, 4,2, } },
  { 107, 70, turn={ 5,1, 4,1, 6,2, } },
  { 107, 71, turn={ 5,1, 4,1, 6,1, 8,2, } },
  { 107, 72, turn={ 5,1, 4,1, 6,1, 8,1, } },
  { 108, 77, turn={ 2,1, 3,2, } },
  { 108, 78, turn={ 2,1, 3,1, } },
  { 113, 81, turn={ 9,2, 10,2, } },
  { 113, 83, turn={ 9,1, 1,2, } },
  { 114, 56, turn={ 16,1, 17,1, } },
}

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()

require("BetterContacts_BH2")			 -- Load module BetterContacts, see https://emaps-eep.de/lua/bettercontacts	

blockControl = require("blockControl")   -- Load the module

blockControl.init({                 -- Initialize the module
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme

  trains          = trains,         -- (Optional) Unknown trains get detected automatically, however, such trains do not have a train signal and can go everywhere.
  
  blockSignals    = block_signals,  -- Block signals
  twoWayBlocks    = two_way_blocks, -- Two way twin blocks (array or set of related blocks)
  routes          = routes,         -- Routes via turnouts from one block to the next block
  paths           = anti_deadlock_paths, -- Critical paths on which trains have to go to avoid lockdown situations

  trackSystem     = track_system,	-- Track system (required to define block tracks) 
  blockTracks     = block_tracks,	-- Previous, first, last and nexts tracks of blocks

  MAINSW          = main_signal,    -- ID of the main switch (optional)

  MAINON          = 1,              -- ON    state of main switch
  MAINOFF         = 2,              -- OFF   state of main switch
  BLKSIGRED       = 1,              -- RED   state of block signals
  BLKSIGGRN       = 2,              -- GREEN state of block signals
  TRAINSIGRED     = 1,              -- RED   state of train signals
  TRAINSIGGRN     = 2,              -- GREEN state of train signals
})

-- [[ Optional: Set one or more runtime parameters at any time 
blockControl.set({
--  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme
  showTippText    = false,           -- (Optional) Show tipp texts true / false (Later you can toggle the visibility of the tipp texts using the main switch.)
  start           = false,           -- (Optional) Activate/deactivate main signal. Useful to start automatic block control after finding all known train.
  startAllTrains  = true,           -- (Optional) Activate/deactivate all train signals
})
--]]

-- Optional: Use a counter signal to set the log level
local counterSignal = 112
blockControl.set({ logLevel = EEPGetSignal( counterSignal ) - 1 })
EEPRegisterSignal( counterSignal )
_ENV["EEPOnSignal_"..counterSignal] = function(pos)
  local logLevel = pos - 1
  if logLevel > 3 then
    logLevel = 0
    blockControl.set({ logLevel = logLevel })
    EEPSetSignal( counterSignal, logLevel + 1 )
  else
    blockControl.set({ logLevel = logLevel })
  end
  print("Log level set to ", logLevel)
end


if EEPActivateCtrlDesk then -- (Optional) Activate a control desk for the EEP layout, available as of EEP 16.1 patch 1
  local ok = EEPActivateCtrlDesk("Block control")             
  if ok then print("Show control desk 'Block control'") end
end

function EEPMain()
  blockControl.run()
  return 1
end	
[EEPLuaData]
DS_1 = "speed=37.353	block=80	"
DS_2 = "speed=1.693	"
DS_3 = "speed=47.196	block=59	"
DS_4 = "speed=-50.039	block=89	"
DS_5 = "speed=-39.991	block=83	"
DS_6 = "speed=40.035	block=43	"
DS_7 = "speed=-40.035	block=78	"
DS_8 = "speed=39.990	block=51	"
DS_9 = "speed=41.595	block=107	"
DS_10 = "speed=59.978	block=54	"
