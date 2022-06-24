-- EEP File 'Double_slip_turnouts'
-- Lua program for module 'blockControl.lua' for track system 'Railroad'

-- Allowed blocks with wait time
local passenger = { [6]=1,  [7]=1,  [8]=1,  [9]=1,  [10]=1,  [11]=1,  [12]=1,  [13]=1,  }
local cargo     = { [6]=20, [7]=30, [8]=20, [9]=20, [10]=20, [11]=30, [12]=30, [13]=30, }

local trains = {
 { name="#Orange",      signal=14, allowed=passenger },
 { name="#Shuttle Red", signal=15, allowed=cargo     },
}

local main_signal = 16

local block_signals = { 6, 7, 8, 9, 10, 11, 12, 13, }

local two_way_blocks = { { 6, 8 }, { 7, 9 }, { 10, 12 }, { 11, 13 }, }

local routes = {
-- CCW via DST using 4 turnouts (manually adjusted to secure the crossing) 
  { 8, 12, turn={ 2,2, 1,2,     3,0 }},	-- crossing
  { 8, 13, turn={ 2,1, 3,1, }}, 		-- straight
  { 9, 12, turn={ 4,1, 1,1, }},			-- straight
  { 9, 13, turn={ 4,2, 3,2,     1,0 }},	-- crossing

-- CCW via track object DST     (manually created)
  { 13, 8, turn={ 5,1 }}, 		-- left/left
  { 13, 9, turn={ 5,2 }}, 		-- left/right
  { 12, 9, turn={ 5,3 }}, 		-- right/right
  { 12, 8, turn={ 5,4 }}, 		-- right/left			

-- CW via DST using 4 turnouts  (manually adjusted to secure the crossing)   
  { 10, 6, turn={ 1,2, 2,2,     3,0 }},	-- crossing
  { 10, 7, turn={ 1,1, 4,1, }},			-- straight
  { 11, 6, turn={ 3,1, 2,1, }},			-- straight 
  { 11, 7, turn={ 3,2, 4,2,     2,0 }},	-- crossing

-- CW via track object DST 		(manually created)
  { 6, 11, turn={ 5,1 }}, 		-- left/left
  { 7, 11, turn={ 5,2 }}, 		-- left/right
  { 7, 10, turn={ 5,3 }}, 		-- right/right
  { 6, 10, turn={ 5,4 }}, 		-- right/left
}

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--clearlog()

require("BetterContacts_BH2")

blockControl = require("blockControl")   -- Load the module

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

function EEPMain()
  blockControl.run()
  return 1
end