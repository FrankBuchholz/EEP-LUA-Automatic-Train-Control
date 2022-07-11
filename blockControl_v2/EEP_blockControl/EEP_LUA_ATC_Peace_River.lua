-- EEP Datei 'RB-Peace-River'
-- Lua-Programm für Modul 'blockControl.lua' für Gleisart 'Eisenbahn'
-- For every block entry sensor enter the following into field 'Lua function' (where ## is the number of the block signal): blockControl.enterBlock_##

-- Erlaubte Blöcke mit Wartezeit
local st = { 20, 50 }                          -- short random wait time between 20 and 50 seconds
local lt = { 60, 100 }                         -- long random wait time between 60 and 100 seconds
local CCW_Pass = { 
  [52]=st, [53]=st, [54]=st, [55]=st, [56]=st, -- wait for a short time in the depot
  [38]=30, [45]= 1,
  [47]=30, [48]=120,                           -- station mid
  [50]= 1, [75]=30, [51]= 1, 
}
local CCW_Cargo = { 
  [52]=st, [53]=st, [54]=st, [55]=st, [56]=st, -- wait for a short time in the depot
  [38]= 1, [45]= 1,
  [47]= 1, [48]= 1, [49]=120,                  -- station mid
  [50]= 1, [75]=30, [51]= 1, 
}
local CW_Pass =   { 
  [57]=lt, [58]=lt, [59]=lt, [60]=lt, [61]=lt, -- wait for a longer time in the depot
  [174]= 1,[65]=120, [62]= 1,
  [66]=90, [67]=120,                           -- station mid
  [46]= 1, [74]=30, [63]= 1, 
}
local CW_Cargo =  { 
  [57]= 1, [58]= 1, [59]= 1, [60]= 1, [61]= 1, -- drive throught depot
  [174]= 1,[65]= 1, [62]= 1, [72]=30, [73]=30,
  [77]=120,                                    -- station mid
  [46]= 1, [74]= 1, [63]= 1, 
}
local Shuttle_North = { 
  [37]=30, [64]=30, [69]=30, [78]=30, [79]=30, 
}

local trains = {
-- (Slots are only used in EEP below version 14.2)
  { name="#CCW Blue Cargo",       signal=0, allowed=CCW_Cargo,     speed=50, slot= 1, },
  { name="#CCW Cream Passenger",  signal=0, allowed=CCW_Pass,      speed=60, slot= 2, },
  { name="#CCW Passenger Orange", signal=0, allowed=CCW_Pass,      speed=70, slot= 3, },
  { name="#CCW Red Cargo",        signal=0, allowed=CCW_Cargo,     speed=50, slot= 4, },
  { name="#CCW Red Passenger",    signal=0, allowed=CCW_Pass,      speed=60, slot= 5, },
  { name="#CCW Steam Passenger",  signal=0, allowed=CCW_Pass,      speed=90, slot= 6, },
  { name="#CW Cream Passenger",   signal=0, allowed=CW_Pass,       speed=60, slot= 7, },
  { name="#CW Green Cargo",       signal=0, allowed=CW_Cargo,      speed=50, slot= 8, },
  { name="#CW Orange Passenger",  signal=0, allowed=CW_Pass,       speed=70, slot= 9, },
  { name="#CW Red Cargo",         signal=0, allowed=CW_Cargo,      speed=50, slot=10, },
  { name="#CW Red Passenger",     signal=0, allowed=CW_Pass,       speed=60, slot=11, },
  { name="#CW Steam Passenger",   signal=0, allowed=CW_Pass,       speed=40, slot=12, },
  { name="#North Red Cargo",      signal=0, allowed=Shuttle_North, speed=30, slot=13, },
}

local main_signal = 1

local block_signals = { 37, 38, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 69, 72, 73, 74, 75, 77, 78, 79, 174, }
-- 34 signals use BLKSIGRED = 1, BLKSIGGRN = 2

local two_way_blocks = { { 45, 46 }, }

local routes = {
  { 37, 69, turn={ 29,1, 39,2, }, reverse=true }, -- manually added
  { 38, 45, turn={ 2,1, } },
  { 45, 37, turn={ 40,2, 34,1, 30,1, 32,2, 36,2, 35,1, 29,2, 39,1, } },
  { 45, 47, turn={ 40,2, 34,2, 33,2, } },
  { 45, 48, turn={ 40,2, 34,2, 33,1, } },
  { 45, 49, turn={ 40,2, 34,1, 30,1, 32,1, } },
  { 45, 64, turn={ 40,2, 34,1, 30,1, 32,2, 36,2, 35,1, 29,2, 39,2, } },
  { 46, 74, turn={ 2,2, } },
  { 47, 50, turn={ 23,2, 31,0, 137,2, } }, -- 31 for crossing protection
  { 48, 50, turn={ 23,1, 31,0, 137,2, } }, -- 31 for crossing protection
  { 49, 50, turn={ 25,2, 137,1, } },
  { 50, 51, turn={ 26,1, 27,1, 24,2, 22,2, 21,2, 20,2, 76,2, 28,1, } }, -- long detour
  { 50, 73, turn={ 26,1, 27,1, 24,2, 22,2, 21,1, } },
  { 50, 75, turn={ 26,2, } }, -- direct

  -- Depot entry from East
  { 51, 52, turn={ 15,2, 16,1, 17,1, 18,1, } },
  { 51, 53, turn={ 15,2, 16,1, 17,1, 18,2, } },
  { 51, 54, turn={ 15,2, 16,1, 17,2, } },
  { 51, 55, turn={ 15,2, 16,2, } },
  { 51, 56, turn={ 15,1, } },

  -- Depot exit to West
  { 52, 38, turn={ 10,1, 9,1, 8,1, 7,2, } },
  { 53, 38, turn={ 10,2, 9,1, 8,1, 7,2, } },
  { 54, 38, turn={ 9,2, 8,1, 7,2, } },
  { 55, 38, turn={ 8,2, 7,2, } },
  { 56, 38, turn={ 7,1, } },

  -- Depot exit to East
  { 57, 174, turn={ 14,1, 13,1, 12,1, 11,2, } },
  { 58, 174, turn={ 14,2, 13,1, 12,1, 11,2, } },
  { 59, 174, turn={ 13,2, 12,1, 11,2, } },
  { 60, 174, turn={ 12,2, 11,2, } },
  { 61, 174, turn={ 11,1, } },

  { 62, 66, turn={ 31,2, 19,1, } },
  { 62, 67, turn={ 31,2, 19,2, } },
  { 62, 77, turn={ 31,1, 23,0, } }, -- 23 for crossing protection

  -- Depot entry from West
  { 63, 57, turn={ 3,1, 4,1, 5,1, 6,1, } },
  { 63, 58, turn={ 3,1, 4,1, 5,1, 6,2, } },
  { 63, 59, turn={ 3,1, 4,1, 5,2, } },
  { 63, 60, turn={ 3,1, 4,2, } },
  { 63, 61, turn={ 3,2, } },

  { 64, 46, turn={ 39,2, 29,2, 35,1, 36,2, 32,2, 30,1, 34,1, 40,2, }, reverse=true },
  { 64, 69, turn={ 39,2, 29,1, }, reverse=true },
  { 64, 78, turn={ 39,2, 29,2, 35,2, }, reverse=true },
  { 64, 79, turn={ 39,2, 29,2, 35,1, 36,1, }, reverse=true },
  { 65, 62, turn={ 24,1, 27,2, } },
  { 66, 46, turn={ 68,1, 40,1, } },
  { 67, 46, turn={ 68,2, 40,1, } },
  { 69, 37, turn={ 29,1, 39,1, }, reverse=true },
  { 69, 64, turn={ 29,1, 39,2, }, reverse=true },
  { 72, 51, turn={ 22,1, 21,2, 20,2, 76,2, 28,1, }, reverse=true },
  { 72, 73, turn={ 22,1, 21,1, }, reverse=true },
  { 73, 62, turn={ 21,1, 22,2, 24,2, 27,2, }, reverse=true },
--  { 73, 72, turn={ 21,1, 22,1, }, reverse=true }, -- avoid endless shuttling
  { 74, 63, turn={ } },
  { 75, 51, turn={ 28,2, } },
  { 77, 46, turn={ 30,2, 34,1, 40,2, } },
  { 78, 37, turn={ 35,2, 29,2, 39,1, }, reverse=true },
  { 78, 64, turn={ 35,2, 29,2, 39,2, }, reverse=true },
  { 79, 37, turn={ 36,1, 35,1, 29,2, 39,1, }, reverse=true },
  { 79, 64, turn={ 36,1, 35,1, 29,2, 39,2, }, reverse=true },
--  { 174, 62, turn={ 76,1, 20,2, 21,2, 22,2, 24,2, 27,2, } }, -- long detour deactivated
  { 174, 65, turn={ 76,1, 20,1, } },
  { 174, 72, turn={ 76,1, 20,2, 21,2, 22,1, } },
}

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()

local blockControl = require("blockControl")   -- Load the module

blockControl.init({                 -- Initialize the module
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme

  trains          = trains,         -- (Optional) Unknown trains get detected automatically, however, such trains do not have a train signal and can go everywhere.
  
  blockSignals    = block_signals,  -- Block signals
  twoWayBlocks    = two_way_blocks, -- Two way twin blocks (array or set of related blocks)
  routes          = routes,         -- Routes via turnouts from one block to the next block
  paths           = anti_deadlock_paths, -- Critical paths on which trains have to go to avoid lockdown situations

  MAINSW          = main_signal,    -- ID of the main switch (optional)

  MAINON          = 1,              -- ON    state of main switch
  MAINOFF         = 2,              -- OFF   state of main switch
  BLKSIGRED       = 1,              -- RED   state of block signals
  BLKSIGGRN       = 2,              -- GREEN state of block signals
  TRAINSIGRED     = 1,              -- RED   state of train signals
  TRAINSIGGRN     = 2,              -- GREEN state of train signals
})

--[[ Optional: Set one or more runtime parameters at any time 
blockControl.set({
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme
  showTippText    = true,           -- (Optional) Show tipp texts true / false (Later you can toggle the visibility of the tipp texts using the main switch.)
  start           = false,          -- (Optional) Activate/deactivate main signal. Useful to start automatic block control after finding all known train.
  startAllTrains  = true,           -- (Optional) Activate/deactivate all train signals
})
--]]

-- Optional: Use a counter signal to set the log level
local counterSignal = 93
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

function EEPMain()
  blockControl.run()
  return 1
end		
[EEPLuaData]
DS_1 = "speed=50.010	block=75	"
DS_2 = "speed=59.982	block=38	"
DS_3 = "speed=69.995	block=55	"
DS_4 = "speed=46.514	block=52	"
DS_5 = "speed=59.969	block=48	"
DS_6 = "speed=40.033	block=47	"
DS_7 = "speed=54.134	block=65	"
DS_8 = "speed=-24.671	block=73	"
DS_9 = "speed=69.980	block=60	"
DS_10 = "speed=0.720	block=77	"
DS_11 = "speed=69.989	block=67	"
DS_12 = "speed=39.260	block=46	"
DS_13 = "speed=1.835	block=37	"
