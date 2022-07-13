-- EEP File 'Shelf_Layout_Lua_ATC_'
-- Lua program for module 'blockControl.lua' for track system 'Railroad'
-- For every block entry sensor enter the following into field 'Lua function' (where ## is the number of the block signal): blockControl.enterBlock_##

-- Allowed blocks with wait time
-- All trains have access to the depot
local rt = { 10, 40 } -- Random (minimum) waiting time for the depot between 10 and 40 seconds
local depot = { 
  [44]=rt, [45]=rt, [46]=rt, [47]=rt, [48]=rt, [49]=rt, [50]=rt, -- depot
  [42]=1,  [51]=20, [52]=20,                                     -- access to depot                           
}
-- Different trains use different tracks in the station
local short = { [35]=20, [36]=1,  [37]=120, [38]=20, [39]=120,          [41]=20, [43]=1, [53]=1, }
local mid   = { [35]=20, [36]=20,           [38]=20,                    [41]=20,                 }
local long  = {          [36]=20,           [38]=20,           [40]=20,                          }

local trains = {
  { name = "#Long1",  signal = 0, slot = 1,  speed = 55, allowed = { long,  depot, } },
  { name = "#Long2",  signal = 0, slot = 2,  speed = 55, allowed = { long,  depot, } },
  { name = "#Long3",  signal = 0, slot = 3,  speed = 34, allowed = { long,  depot, } },
  { name = "#Long4",  signal = 0, slot = 4,  speed = 36, allowed = { long,  depot, } },
  { name = "#Mid1",   signal = 0, slot = 5,  speed = 30, allowed = { mid,   depot, } },
  { name = "#Mid2",   signal = 0, slot = 6,  speed = 32, allowed = { mid,   depot, } },
  { name = "#Mid3",   signal = 0, slot = 7,  speed = 34, allowed = { mid,   depot, } },
  { name = "#Mid4",   signal = 0, slot = 8,  speed = 36, allowed = { mid,   depot, } },
  { name = "#Short1", signal = 0, slot = 9,  speed = 30, allowed = { short, depot, } },
  { name = "#Short2", signal = 0, slot = 10, speed = 32, allowed = { short, depot, } },
  { name = "#Short3", signal = 0, slot = 11, speed = 34, allowed = { short, depot, } },
  { name = "#Short4", signal = 0, slot = 12, speed = 36, allowed = { short, depot, } },
}

local main_signal   = 22
local counterSignal = 26

local block_signals = { 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, }
-- 19 signals use BLKSIGRED = 2, BLKSIGGRN = 1
-- Ignored signals: 23, 24, 25, 

local two_way_blocks = { { 36, 43 }, { 38, 53 }, }

local routes = {
  { 35, 42, turn={ 3,2, 4,1, 7,1, }, reverse=true },       -- End

  { 36, 37, turn={ 1,1, } },
  { 36, 42, turn={ 7,1, 4,1, 3,1, }, reverse=true },       -- manually added

  { 37, 43, turn={ 1,1, }, reverse=true },                 -- End
  { 37, 53, turn={ 1,2, 2,2, }, reverse=true },

  { 38, 37, turn={ 2,2, 1,2, } },
  { 38, 39, turn={ 2,1, } },
  { 38, 42, turn={ 7,1, 4,2, 5,2, }, reverse=true },       -- manually added

  { 39, 53, turn={ 2,1, }, reverse=true },                 -- End

  { 40, 42, turn={ 6,2, 5,1, 4,2, 7,1, }, reverse=true },  -- End

  { 41, 42, turn={ 6,1, 5,1, 4,2, 7,1, }, reverse=true },  -- End

  { 42, 44, turn={ 10,1, 11,2, } },
  { 42, 45, turn={ 10,1, 11,1, 9,2, } },
  { 42, 46, turn={ 10,1, 11,1, 9,1, 12,2, } },
  { 42, 47, turn={ 10,1, 11,1, 9,1, 12,1, 13,2, } },
  { 42, 48, turn={ 10,1, 11,1, 9,1, 12,1, 13,1, 14,2, } },
  { 42, 49, turn={ 10,1, 11,1, 9,1, 12,1, 13,1, 14,1, 15,2, } },
  { 42, 50, turn={ 10,1, 11,1, 9,1, 12,1, 13,1, 14,1, 15,1, } },

  { 43, 42, turn={ 3,1, 4,1, 7,1, } },
  
-- Depot   
  { 44, 52, turn={ 21,1, 20,1, 19,1, 16,1, 18,1, 17,2, } },
  { 45, 52, turn={ 21,2, 20,1, 19,1, 16,1, 18,1, 17,2, } },
  { 46, 52, turn={ 20,2, 19,1, 16,1, 18,1, 17,2, } },
  { 47, 52, turn={ 19,2, 16,1, 18,1, 17,2, } },
  { 48, 52, turn={ 16,2, 18,1, 17,2, } },
  { 49, 52, turn={ 18,2, 17,2, } },
  { 50, 52, turn={ 17,1, } },

-- The depot operates in both directions (manually added) 
  { 44, 51, turn={ 10,2, 11,2, },                              reverse=true },
  { 45, 51, turn={ 10,2, 11,1, 9,2, },                         reverse=true },
  { 46, 51, turn={ 10,2, 11,1, 9,1, 12,2, },                   reverse=true },
  { 47, 51, turn={ 10,2, 11,1, 9,1, 12,1, 13,2, },             reverse=true },
  { 48, 51, turn={ 10,2, 11,1, 9,1, 12,1, 13,1, 14,2, },       reverse=true },
  { 49, 51, turn={ 10,2, 11,1, 9,1, 12,1, 13,1, 14,1, 15,2, }, reverse=true },
  { 50, 51, turn={ 10,2, 11,1, 9,1, 12,1, 13,1, 14,1, 15,1, }, reverse=true },


  { 51, 35, turn={ 8,1, 7,2, 4,1, 3,2, } },
  { 51, 36, turn={ 8,1, 7,2, 4,1, 3,1, } },
  { 51, 38, turn={ 8,1, 7,2, 4,2, 5,2, } },
  { 51, 40, turn={ 8,1, 7,2, 4,2, 5,1, 6,2, } },
  { 51, 41, turn={ 8,1, 7,2, 4,2, 5,1, 6,1, } },
  { 52, 35, turn={ 8,2, 7,2, 4,1, 3,2, } },
  { 52, 36, turn={ 8,2, 7,2, 4,1, 3,1, } },
  { 52, 38, turn={ 8,2, 7,2, 4,2, 5,2, } },
  { 52, 40, turn={ 8,2, 7,2, 4,2, 5,1, 6,2, } },
  { 52, 41, turn={ 8,2, 7,2, 4,2, 5,1, 6,1, } },

  { 53, 42, turn={ 5,2, 4,2, 7,1, } },
}

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--clearlog()

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
  BLKSIGRED       = 2,              -- RED   state of block signals
  BLKSIGGRN       = 1,              -- GREEN state of block signals
  TRAINSIGRED     = 1,              -- RED   state of train signals
  TRAINSIGGRN     = 2,              -- GREEN state of train signals
})

-- [[ Optional: Set one or more runtime parameters at any time 
blockControl.set({
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme
  showTippText    = true,           -- (Optional) Show tipp texts true / false (Later you can toggle the visibility of the tipp texts using the main switch.)
  start           = true,          -- (Optional) Activate / deactivate main signal. Useful to start automatic block control after finding all known trains.
  startAllTrains  = true,           -- (Optional) Activate / deactivate all train signals
})
--]]

-- (Extension) Use counter signal to set log level
--local counterSignal = 26 -- already defined above
blockControl.set({ logLevel = EEPGetSignal( counterSignal ) - 1 })
EEPRegisterSignal( counterSignal )
_ENV["EEPOnSignal_"..counterSignal] = function(pos)
  local logLevel = pos - 1
  if logLevel > 3 then                        -- Restrict maximum value
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
DS_1 = "speed=54.971	"
DS_2 = "speed=-1.839	block=38	"
DS_3 = "speed=-10.764	block=47	"
DS_4 = "speed=-14.870	block=49	"
DS_5 = "speed=30.067	block=36	"
DS_6 = "speed=11.899	block=41	"
DS_7 = "speed=-33.948	"
DS_8 = "speed=36.035	"
DS_9 = "speed=29.978	block=50	"
DS_10 = "speed=-32.008	block=45	"
DS_11 = "speed=34.075	block=51	"
DS_12 = "speed=-36.004	block=37	"
