-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, June 2022
-- EEP Lua code to automatically drive trains from block to block.
-- There's no need to write any Lua code, the code uses the data in the Configuration tables and variables below.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- EEP Datei 'EEP_LUA_Layout_04_Reverse_Video'
-- Lua-Programm für Modul 'blockControl.lua' für Gleisart 'Eisenbahn'

-- Configure allowed blocks for different groups of trains and the wait time before leaving the block. 
-- Wait time not defined (nil) or 0: no entry to this block, 1: block is allowed (drive throught), >1: minimal wait time in seconds between entering and leaving the block (= drive time from contact to signal + stop time).
-- (You can choose any name for these variables.)
local CW =      { [10]= 1, [19]=30, }
local CCW =     { [ 8]=30, [13]= 1, }
local Shuttle = { [ 9]= 1, [18]= 1, [26]=30, [27]=30, }

-- Configure names and (optional) signals of trains and assign the allowed blocks.
-- (You can choose any name for variable 'Trains', but you have to use the names for the components 'name', 'signal', 'allowed'.)
-- (Variable 'Trains' could be an array with implizit keys, or you can create a table with explicit keys like [9] or names ["Cargo1"] to identify entries.) 
local trains = {
  { name="#Blue",   signal= 4, allowed=Shuttle, speed=40, slot=1, },
  { name="#Orange", signal=14, allowed=CW,      speed=50, slot=2, },
  { name="#Steam",  signal=30, allowed=CCW,     speed=50, slot=3, },
}

-- Main signal to start automatic block control
-- (You can toggle the signal twice to show/hide tipp texts)
local main_signal = 3

-- Configure block signals (this is optional if you are using block signal numbers)
-- (It is possible to derive this table from other variables, however, using it gives opportunities for consistency checks.)
-- (The order of the entries does not matter.)
-- (You can choose any name for variable 'block_signals'.)
local block_signals = { 8, 9, 10, 13, 18, 19, 26, 27, }
-- 8 signals use BLKSIGRED = 1, BLKSIGGRN = 2

-- Configure pairs of two way twin block signals.
-- (You can choose any name for variable 'two_way_blocks'.)
local two_way_blocks = { { 9, 18 }, }

-- Configure how to get from one block to another block by switching turnouts.
-- (You can choose any name for variable 'routes', but you have to use the name for components 'turn'.)
local routes = {
-- { from block, to block, turn={ turnout, state, ...}}, with state: 1=main, 2=branch, 3=alternate branch
  {  8, 13, turn={ 2,1, 12,1, 22,2, } },
  {  8, 27, turn={ 2,1, 12,1, 22,1, } },
  {  9, 10, turn={ 16,1, 1,2, 11,2, 23,1, } },
  {  9, 26, turn={ 16,1, 1,2, 11,2, 23,2, } },
  { 10,  9, turn={ 12,2, 2,2, 17,1, } },
  { 10, 19, turn={ 12,2, 2,2, 17,2, } },
  { 13,  8, turn={ 11,1, 1,1, } },
  { 13, 18, turn={ 11,1, 1,2, 16,1, } },
  { 18, 13, turn={ 17,1, 2,2, 12,1, 22,2, } },
  { 18, 27, turn={ 17,1, 2,2, 12,1, 22,1, } },
  { 19, 10, turn={ 16,2, 1,2, 11,2, 23,1, } },
  { 19, 26, turn={ 16,2, 1,2, 11,2, 23,2, } },
  { 26,  8, turn={ 23,2, 11,2, 1,1, },       reverse=true },
  { 26, 18, turn={ 23,2, 11,2, 1,2, 16,1, }, reverse=true },
  { 27,  9, turn={ 22,1, 12,1, 2,2, 17,1, }, reverse=true },
  { 27, 19, turn={ 22,1, 12,1, 2,2, 17,2, }, reverse=true },
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

-- [[ Optional: Set one or more runtime parameters at any time 
blockControl.set({
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme
  showTippText    = false,           -- (Optional) Show tipp texts true / false (Later you can toggle the visibility of the tipp texts using the main switch.)
  start           = false,          -- (Optional) Activate/deactivate main signal. Useful to start automatic block control after finding all known train.
  startAllTrains  = true,           -- (Optional) Activate/deactivate all train signals
})
--]]

if EEPActivateCtrlDesk then -- (Optional) Activate a control desk for the EEP layout, available as of EEP 16.1 patch 1
  local ok = EEPActivateCtrlDesk("#2_Stellpult")             
  if ok then print("Show control desk 'Block control'") end
end

function EEPMain()
  blockControl.run()
  return 1
end
[EEPLuaData]
DS_1 = "block=18	speed=-11.652	"
DS_2 = "block=10	speed=-40.593	"
DS_3 = "block=13	speed=-12.046	"
