-- EEP File 'EEP_LUA_ATC_Peace_River_extended'
-- Lua program for module 'blockControl.lua' for track system 'Railroad'
-- For every block entry sensor enter the following into field 'Lua function' (where ## is the number of the block signal): blockControl.enterBlock_##

-- Allowed blocks with wait time
local st = { 20, 50 }                          -- short random time between 20 and 50 seconds
local lt = { 50, 100 }                         -- long random time between 50 and 100 seconds

local CCW_depot = { 
  [52]=st, [53]=st, [54]=st, [55]=st, [56]=st, -- depot
  [82]=st, [83]=st, [84]=st, [85]=st, [86]=st, -- depot, extended
}
local CCW_Pass = { 
  CCW_depot,
  [38]=30, [45]= 1,
  [47]=30, [48]=120,                           -- station mid
  [50]= 1, [75]=30, [51]= 1, 
}
local CCW_Cargo = { 
  CCW_depot,
  [38]= 1, [45]= 1,
  [47]= 1, [48]= 1, [49]=120,                  -- station mid
  [50]= 1, [75]=30, [51]= 1, 
}

local CW_Pass = { 
  [57]=lt, [58]=lt, [59]=lt, [60]=lt, [61]=lt, -- depot
  [87]=lt, [88]=lt, [89]=lt, [90]=lt, [91]=lt, -- depot, extended
  [174]= 1,[65]=120, [62]= 1,
  [66]=90, [67]=120,                           -- station mid
  [46]= 1, [74]=30, [63]= 1, 
}
local CW_Cargo = { 
  [57]= 1, [58]= 1, [59]= 1, [60]= 1, [61]= 1, -- depot
  [87]= 1, [88]= 1, [89]= 1, [90]= 1, [91]= 1, -- depot, extended
  [174]= 1,[65]= 1, [62]= 1, [72]=30, [73]=30,
  [77]=120,                                    -- station mid
  [46]= 1, [74]= 1, [63]= 1, 
}
local Shuttle_North = { 
  [37]=30, [64]=30, [69]=30, [78]=30, [79]=30, -- shuttle station 
  -- The following entries allow the train to leave the shuttle station for a CCW run
  [52]= 1, [53]= 1, [54]= 1, [55]= 1, [56]= 1, -- depot
  [82]= 1, [83]= 1, [84]= 1, [85]= 1, [86]= 1, -- depot, extended
  [38]= 1, [45]= 1,
  [50]= 1, [75]= 1, [51]= 1,
}

local trains = {
-- No train signals are assigned yet
-- The speed is used for reversing trains
-- The slots are only used in EEP bersions below 14.2
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
  { name="#North Blue Cargo",     signal=0, allowed=Shuttle_North, speed=35, slot=14, },
}

local main_signal = 1

local block_signals = { 37, 38, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 69, 72, 73, 74, 75, 77, 78, 79, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 174, }
-- 44 signals use BLKSIGRED = 1, BLKSIGGRN = 2

local two_way_blocks = { { 45, 46 }, { 52, 87 }, { 53, 88 }, { 54, 89 }, { 55, 90 }, { 56, 91 }, { 57, 86 }, { 58, 85 }, { 59, 84 }, { 60, 83 }, { 61, 82 }, }

-- Crossings protection:
-- Pairs or triples of coupled turnouts: automatically add the last turnout to the routes which contain the preceeding turnouts
local crossings_protection = {
  { 70, 81, 80 }, { 41, 43, 44 },
}

local routes = {
  { 37, 50, turn={ 25,1, 137,1, } },
  { 37, 69, turn={ 29,1, 39,2, }, reverse=true }, -- manually added
  { 38, 45, turn={ 2,1, } },
  { 45, 37, turn={ 40,2, 34,1, 30,1, 32,2, 36,2, 35,1, 29,2, 39,1, } },
  { 45, 47, turn={ 40,2, 34,2, 33,2, } },
  { 45, 48, turn={ 40,2, 34,2, 33,1, } },
  { 45, 49, turn={ 40,2, 34,1, 30,1, 32,1, } },
  { 45, 64, turn={ 40,2, 34,1, 30,1, 32,2, 36,2, 35,1, 29,2, 39,2, } },
  { 46, 74, turn={ 2,2, } },
  { 47, 50, turn={ 23,2, 137,2, } },
  { 48, 50, turn={ 23,1, 137,2, } },
  { 49, 50, turn={ 25,2, 137,1, } },
  { 50, 51, turn={ 26,1, 27,1, 24,2, 22,2, 21,2, 20,2, 76,2, 28,1, } }, -- long detour
  { 50, 73, turn={ 26,1, 27,1, 24,2, 22,2, 21,1, } },
  { 50, 75, turn={ 26,2, } }, -- direct

  -- Depot entry from East
  { 51, 52, turn={ 44,2, 41,1, 15,2, 16,1, 17,1, 18,1, } },
  { 51, 53, turn={ 44,2, 41,1, 15,2, 16,1, 17,1, 18,2, } },
  { 51, 54, turn={ 44,2, 41,1, 15,2, 16,1, 17,2, } },
  { 51, 55, turn={ 44,2, 41,1, 15,2, 16,2, } },
  { 51, 56, turn={ 44,2, 41,1, 15,1, } },
  { 51, 82, turn={ 44,1, 42,2, 11,1, } },
  { 51, 83, turn={ 44,1, 42,2, 11,2, 12,2, } },
  { 51, 84, turn={ 44,1, 42,2, 11,2, 12,1, 13,2, } },
  { 51, 85, turn={ 44,1, 42,2, 11,2, 12,1, 13,1, 14,2, } },
  { 51, 86, turn={ 44,1, 42,2, 11,2, 12,1, 13,1, 14,1, } },

  -- Depot exit to West
  { 52, 38, turn={ 10,1, 9,1, 8,1, 7,2, 80,1, 70,2, } },
  { 53, 38, turn={ 10,2, 9,1, 8,1, 7,2, 80,1, 70,2, } },
  { 54, 38, turn={ 9,2, 8,1, 7,2, 80,1, 70,2, } },
  { 55, 38, turn={ 8,2, 7,2, 80,1, 70,2, } },
  { 56, 38, turn={ 7,1, 80,1, 70,2, } },

  -- Depot exit to East
  { 57, 174, turn={ 14,1, 13,1, 12,1, 11,2, 42,1, 43,1, } },
  { 58, 174, turn={ 14,2, 13,1, 12,1, 11,2, 42,1, 43,1, } },
  { 59, 174, turn={ 13,2, 12,1, 11,2, 42,1, 43,1, } },
  { 60, 174, turn={ 12,2, 11,2, 42,1, 43,1, } },
  { 61, 174, turn={ 11,1, 42,1, 43,1, } },

  { 62, 66, turn={ 31,2, 19,1, } },
  { 62, 67, turn={ 31,2, 19,2, } },
  { 62, 77, turn={ 31,1, 23,0, } }, -- turnout 23 protects the crossing

  -- Depot entry from West
  { 63, 57, turn={ 71,2, 81,1, 3,2, 4,1, 5,1, 6,1, } },
  { 63, 58, turn={ 71,2, 81,1, 3,2, 4,1, 5,1, 6,2, } },
  { 63, 59, turn={ 71,2, 81,1, 3,2, 4,1, 5,2, } },
  { 63, 60, turn={ 71,2, 81,1, 3,2, 4,2, } },
  { 63, 61, turn={ 71,2, 81,1, 3,1, } },
  { 63, 87, turn={ 71,1, 80,2, 7,2, 8,1, 9,1, 10,1, } },
  { 63, 88, turn={ 71,1, 80,2, 7,2, 8,1, 9,1, 10,2, } },
  { 63, 89, turn={ 71,1, 80,2, 7,2, 8,1, 9,2, } },
  { 63, 90, turn={ 71,1, 80,2, 7,2, 8,2, } },
  { 63, 91, turn={ 71,1, 80,2, 7,1, } },

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

  -- Depot exit to West
  { 82, 38, turn={                     3,1, 81,2, 70,1, } }, 
  { 83, 38, turn={               4,2,  3,2, 81,2, 70,1, } },
  { 84, 38, turn={         5,2,  4,1,  3,2, 81,2, 70,1, } },
  { 85, 38, turn={   6,2,  5,1,  4,1,  3,2, 81,2, 70,1, } },
  { 86, 38, turn={   6,1,  5,1,  4,1,  3,2, 81,2, 70,1, } },

  -- Depot exit to East
  { 87, 174, turn={ 18,1, 17,1, 16,1, 15,2, 41,2, 43,2, } },
  { 88, 174, turn={ 18,2, 17,1, 16,1, 15,2, 41,2, 43,2, } },
  { 89, 174, turn={       17,2, 16,1, 15,2, 41,2, 43,2, } },
  { 90, 174, turn={             16,2, 15,2, 41,2, 43,2, } },
  { 91, 174, turn={                   15,1, 41,2, 43,2, } },

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
  crossings       = crossings_protection, -- Coupled turnouts to protect crossings

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
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme
  showTippText    = true,           -- (Optional) Show tipp texts true / false (Later you can toggle the visibility of the tipp texts using the main switch.)
  start           = false,          -- (Optional) Activate / deactivate main signal. Useful to start automatic block control after finding all known trains.
  startAllTrains  = true,           -- (Optional) Activate / deactivate all train signals
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
--blockControl.printStatus( 120 )   -- Print the status every 2 minutes

  return 1
end
[EEPLuaData]
DS_1 = "block=56	speed=38.639	"
DS_2 = "block=52	speed=29.153	"
DS_3 = "block=54	speed=63.777	"
DS_4 = "block=83	speed=50.029	"
DS_5 = "block=48	speed=6.279	"
DS_6 = "block=85	speed=32.450	"
DS_7 = "block=174	speed=59.755	"
DS_8 = "block=77	speed=47.817	"
DS_9 = "block=65	speed=5.307	"
DS_10 = "block=73	speed=-15.195	"
DS_11 = "block=67	speed=69.979	"
DS_12 = "block=74	speed=29.901	"
DS_13 = "block=82	speed=30.080	"
DS_14 = "block=45	speed=34.917	"
