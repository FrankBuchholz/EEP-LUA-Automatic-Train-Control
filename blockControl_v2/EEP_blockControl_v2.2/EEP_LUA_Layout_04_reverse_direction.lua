-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, April 2022
-- EEP Lua code to automatically drive trains from block to block.
-- There's no need to write any Lua code, the code uses the data in the Configuration tables and variables below.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Configuration for Demo Layout 04 based on block signal numbers
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Main signal to start automatic block control
-- (You can toggle the signal twice to show/hide tipp texts)
local main_signal = 3

-- Configure block signals (this is optional if you are using block signal numbers)
-- (It is possible to derive this table from other variables, however, using it gives opportunities for consistency checks.)
-- (The order of the entries does not matter.)
-- (You can choose any name for variable 'block_signals'.)
local block_signals = { 
   8, -- South 1 -> East
  18, -- South 2 -> East two way
   9, -- South 2 -> West two way
  19, -- South 3 -> West
  26, -- North 1 dead end
  10, -- North 2 -> East
  13, -- North 3 -> West
  27, -- North 4 dead end
}

-- Configure allowed blocks for different groups of trains and the wait time before leaving the block. 
-- Wait time not defined (nil) or 0: no entry to this block, 1: block is allowed (drive throught), >1: minimal wait time in seconds between entering and leaving the block (= drive time from contact to signal + stop time).
-- (You can choose any name for variables 'passengerTrains' and 'cargoTrains'.)
local everywhere = {
  [ 8] = 30, -- numbers > 1 are stop times
  [18] =  1,
  [ 9] =  1,
  [19] = 30,   
  [26] = 30,
  [10] = 20,
  [13] = 20,
  [27] = 30,
}

-- Configure names and (optional) signals of trains and assign the allowed blocks.
local trains = {    
--  EEP name,         Train signal, Allowed block signals with wait time, speed when reversing direction
  { name = "#Orange", signal = 4,   allowed = everywhere,                 speed = 80 },
  { name = "#Steam",  signal = 30,  allowed = everywhere,                 speed = 45 },
  { name = "#Blue",   signal = 14,  allowed = everywhere,                 speed = 50 },
}

-- Configure pairs of two way twin block signals.
-- (You can choose any name for variable 'two_way_blocks'.)
local two_way_blocks = { {18, 9} }

-- Configure how to get from one block to another block by switching turnouts.
-- (You can choose any name for variable 'routes', but you have to use the name for components 'turn'.)
local routes = {
-- { from block, to block, turn={ turnout, state, ...}}, with state: 1=main, 2=branch, 3=alternate branch
  -- Station South
  {  8, 13, turn={  2,1, 12,1, 22,2 }},
  {  8, 27, turn={  2,1, 12,1, 22,1 }},
  { 18, 13, turn={ 17,1,  2,2, 12,1, 22,2 }},
  { 18, 27, turn={ 17,1,  2,2, 12,1, 22,1 }},
  {  9, 26, turn={ 16,1,  1,2, 11,2, 23,2 }},
  {  9, 10, turn={ 16,1,  1,2, 11,2, 23,1 }},
  { 19, 26, turn={ 16,2,  1,2, 11,2, 23,2 }},
  { 19, 10, turn={ 16,2,  1,2, 11,2, 23,1 }},
  -- Station North
  { 26,  8, turn={ 23,2, 11,2,  1,1 },       reverse=true },
  { 26, 18, turn={ 23,2, 11,2,  1,2, 16,1 }, reverse=true },
  { 10,  9, turn={ 12,2,  2,2, 17,1 }},
  { 10, 19, turn={ 12,2,  2,2, 17,2 }},
  { 13,  8, turn={ 11,1,  1,1 }},
  { 13, 18, turn={ 11,1,  1,2, 16,1 }},
  { 27,  9, turn={ 22,1, 12,1,  2,2, 17,1 }, reverse=true },
  { 27, 19, turn={ 22,1, 12,1,  2,2, 17,2 }, reverse=true },
}


-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()

local blockControl = require("blockControl") -- Load the module

blockControl.init({                          -- Initialize the module
  logLevel        = 1,           -- Log level 0 (default): off, 1: normal, 2: full, 3: extreme

  trains          = trains,       -- (Optional) Unknows trains get detected automatically, however, such trains do not have a train signal and can go everywhere.
  
  blockSignals    = block_signals,
  twoWayBlocks    = two_way_blocks,
  routes          = routes,

  MAINSW          = main_signal, -- ID of the main switch (optional)

  --[[ The default values work fine for this layout
  MAINON          = 1,           -- ON    state of main switch
  MAINOFF         = 2,           -- OFF   state of main switch
  BLKSIGRED       = 1,           -- RED   state of block signals
  BLKSIGGRN       = 2,           -- GREEN state of block signals
  TRAINSIGRED     = 1,           -- RED   state of train signals
  TRAINSIGGRN     = 2,           -- GREEN state of train signals
  --]]  
})

-- [[ Optional: Set one or more runtime parameters at any time 
blockControl.set({
  logLevel        = 1,           -- Log level 0 (default): off, 1: normal, 2: full, 3: extreme
  showTippText    = true,        -- Show tipp texts true / false (Later you can toggle the visibility of the tipp texts using the main switch.)
  start           = false,        -- Activate/deactivate main signal. Useful to start automatic block control after finding all known train.
  --startAllTrains  = true,        -- Activate/deactivate all train signals
})
--]]

if EEPActivateCtrlDesk then -- (Optional) Activate a control desk for the EEP layout, available as of EEP 16.1 patch 1
  local ok = EEPActivateCtrlDesk("Block control")             
  if ok then print("Show control desk 'Block control'") end
end

function EEPMain()

  blockControl.run()

  return 1
end