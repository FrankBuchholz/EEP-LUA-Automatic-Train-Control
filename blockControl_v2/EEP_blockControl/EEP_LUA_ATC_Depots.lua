-- EEP File 'Depots B'
-- Lua program for module 'blockControl.lua' for track system 'Railroad'
-- For every block entry sensor enter the following into field 'Lua function' (where ## is the number of the block signal):
--   blockControl.enterBlock(Zugname, ##)

-- Allowed blocks with wait time
local rt = { 20, 35 }
-- The additional entry showing dummy block 0 prevents some error messages but does not influence traffic on this layout.
local all = { 
  [0]  = 1,     -- (additional) Trains are allowed to leave the controlled part of the layout

  [8]  = rt,    -- Station CCW 
  [18] = rt,    -- Station CCW 
  [9]  = rt,    -- Station CW
  [19] = rt,    -- Station CW 

  [12] = 1,     -- Entry Depot 1 
  [11] = 1,     -- Exit Depot 1

  [5]  = 1,     -- Entry Depot 2 
  [6]  = 1,     -- Exit Depot 2
}

local trains = {
  { name="#Blue",           signal=30, slot=1, speed=70, allowed=all },
  { name="#Orange",         signal=14, slot=2, speed=70, allowed=all },
  { name="#Steam",          signal= 4, slot=3, speed=50, allowed=all },
  { name="#DB_216 beige",   signal=22, slot=4, speed=70, allowed=all },
  { name="#Shuttle Yellow", signal=23, slot=5, speed=50, allowed=all },
  { name="#Shuttle Red",    signal=24, slot=6, speed=50, allowed=all },
}

local main_signal = 3

local block_signals = { 5, 6, 8, 9, 11, 12, 18, 19, }
-- 8 signals use BLKSIGRED = 1, BLKSIGGRN = 2

local two_way_blocks = { { 9, 18 }, }

-- The additional entries showing dummy block 0 prevent some error messages but do not influence traffic on this layout.
-- The deactivated entries had been generated but are useless on this layout.
local routes = {
  { 0, 5, },                                    -- (additional) Train enters controlled part of the layout
  { 0, 11, },                                   -- (additional) Train enters controlled part of the layout

  { 5, 9, turn={ 7,2, 2,2, 17,1, } },         	-- To station CW
  { 5, 19, turn={ 7,2, 2,2, 17,2, } },         	-- To station CW

--{ 6, 5, turn={ 21,1, } }, 					-- (deactivated)
  { 6, 0, },                                    -- (additional) Train leaves controlled part of the layout

  { 8, 12, turn={ 2,1, 7,1, 13,1, } },         	-- From station CCW

  { 9, 6, turn={ 16,1, 1,2, 10,2, 20,2, } },  	-- From station CW

  { 11, 8, turn={ 10,1, 1,1, } },        		-- To station CCW
  { 11, 18, turn={ 10,1, 1,2, 16,1, } },        -- To station CCW

--{ 12, 12, turn={ 13,undefined, } }, 			-- (deactivated)
  { 12, 0, },                                   -- (additional) Train leaves controlled part of the layout

  { 18, 12, turn={ 17,1, 2,2, 7,1, 13,1, } },   -- From station CCW

  { 19, 6, turn={ 16,2, 1,2, 10,2, 20,2, } },  	-- From station CW
}

local anti_deadlock_paths = { -- (Optional) Critical paths on which trains have to go to avoid lockdown situations
}

local crossings_protection = { -- (Optional) Coupled turnouts to protect crossings
} 

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()

require("BetterContacts_BH2")       -- Load module BetterContacts from Benny
blockControl = require("blockControl")   -- Load the module (global variable to serve BetterContacts)

blockControl.init({                 -- Initialize the module
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme

  trains          = trains,         -- (Optional) Unknown trains get detected automatically, however, such trains do not have a train signal and can go everywhere.
  
  blockSignals    = block_signals,  -- (Optional) Block signals
  twoWayBlocks    = two_way_blocks, -- (Optional) Two way twin blocks (pairs of related blocks)
  routes          = routes,         -- Routes via turnouts from one block to the next block
  paths           = anti_deadlock_paths, -- (Optional) Critical paths on which trains have to go to avoid lockdown situations
  crossings       = crossings_protection, -- (Optional) Coupled turnouts to protect crossings																																																																				  

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
  start           = false,          -- (Optional) Activate/deactivate main signal. Useful to start automatic block control after finding all known trains.
  startAllTrains  = true,           -- (Optional) Activate/deactivate all train signals
})
--]]

function EEPMain()
  blockControl.run()
  return 1
end
[EEPLuaData]
DS_1 = "speed=18.778	block=19	"
DS_2 = "speed=-38.147	block=11	"
DS_3 = "speed=-4.055	block=8	"
DS_4 = "speed=3.123	"
DS_5 = "speed=49.967	"
DS_6 = "speed=41.597	block=18	"
