-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, June 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any Lua code, the code uses the data in the tables and variables.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- EEP Datei 'EEP_LUA_ATC_Model_Railroad_Layout_1'
-- Lua-Programm für Modul 'blockControl.lua' für Gleisart 'Eisenbahn'
-- For every block entry sensor enter the following into field 'Lua function' (where ## is the number of the block signal): blockControl.enterBlock_##

-- Configure allowed blocks for different groups of trains and the wait time before leaving the block. 
-- Wait time not defined (nil) or 0: no entry to this block, 1: block is allowed (drive throught), >1: minimal wait time in seconds between entering and leaving the block (= drive time from contact to signal + stop time).
-- (You can choose any name for these variables.)
local CW      = { [26]=30, [27]=30, [33]= 1, [34]= 1, [81]= 1, [42]= 1, [40]= 1, [31]= 1, }
local CCW     = { [19]=30, [25]=30, [37]= 1, [39]= 1, [41]= 1, [82]= 1, [32]= 1, [73]= 1, }
local Shuttle = { [28]=30, [29]=30, [30]=30, [38]= 1, [74]= 1, [45]=30, [46]=30, [73]= 1, 
                  [32]=30, [25]= 1, [37]= 1, [39]= 1, [43]=30, [44]=30, [40]= 1, [35]=30, [36]=30,
                  [31]= 1, [26]= 1, [27]= 1, [33]= 1, [34]= 1, }

-- Configure names and (optional) signals of trains and assign the allowed blocks.
-- (You can choose any name for variable 'Trains', but you have to use the names for the components 'name', 'signal', 'allowed'.)
-- (Variable 'Trains' could be an array with implizit keys, or you can create a table with explicit keys like [9] or names ["Cargo1"] to identify entries.) 
local trains = {
  { name="#Blue CW",        signal= 9, allowed=CW,      speed=40, slot=1, },
  { name="#Cream CW",       signal=72, allowed=CW,      speed=50, slot=2, },
  { name="#Steam CCW",      signal=77, allowed=CCW,     speed=30, slot=3, },
  { name="#Orange CCW",     signal=78, allowed=CCW,     speed=50, slot=4, },
  { name="#Shuttle Red",    signal=79, allowed=Shuttle, speed=40, slot=5, },
  { name="#Shuttle Steam",  signal=92, allowed=Shuttle, speed=30, slot=6, },
  { name="#Shuttle Yellow", signal=93, allowed=Shuttle, speed=40, slot=7, },
}

-- Main signal to start automatic block control
-- (You can toggle the signal twice to show/hide tipp texts)
local main_signal = 80

-- Configure block signals (this is optional if you are using block signal numbers)
-- (It is possible to derive this table from other variables, however, using it gives opportunities for consistency checks.)
-- (The order of the entries does not matter.)
-- (You can choose any name for variable 'block_signals'.)
local block_signals = { 19, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 73, 74, 81, 82, }
-- 27 signals use BLKSIGRED = 1, BLKSIGGRN = 2

-- Configure pairs of two way twin block signals.
-- (You can choose any name for variable 'two_way_blocks'.)
local two_way_blocks = { { 32, 33 }, { 38, 74 }, { 81, 82 }, }

-- Configure how to get from one block to another block by switching turnouts.
-- (You can choose any name for variable 'routes', but you have to use the name for components 'turn'.)
local routes = {
  { 19, 37, turn={ 3,1, } },
  { 25, 37, turn={ 3,2, } },
  { 26, 33, turn={ 1,2, } },
  { 27, 34, turn={ } },
  { 28, 74, turn={ 11,1, }, reverse=true },
  { 29, 74, turn={ 13,2, 11,2, }, reverse=true },
  { 30, 74, turn={ 13,1, 11,2, }, reverse=true },
  { 31, 26, turn={ 6,1, } },
  { 31, 27, turn={ 6,2, } },
  { 32, 25, turn={ 1,1, } },
  { 33, 45, turn={ 23,2, 21,2, 22,1, 18,2, } },
  { 33, 46, turn={ 23,2, 21,2, 22,1, 18,1, } },
  { 33, 81, turn={ 23,2, 21,2, 22,2, 17,1, 20,1, } },
  { 33, 81, turn={ 23,1, 17,2, 20,1, } },
  { 34, 45, turn={ 7,1, 21,1, 22,1, 18,2, } },
  { 34, 46, turn={ 7,1, 21,1, 22,1, 18,1, } },
  { 34, 81, turn={ 7,1, 21,1, 22,2, 17,1, 20,1, } },
  { 35, 39, turn={ 8,2, 2,2, 4,2, 5,2, }, reverse=true },
  { 36, 39, turn={ 8,1, 2,2, 4,2, 5,2, }, reverse=true },
  { 37, 39, turn={ 5,1, } },
  { 38, 28, turn={ 11,1, } },
  { 38, 29, turn={ 11,2, 13,2, } },
  { 38, 30, turn={ 11,2, 13,1, } },
  { 39, 41, turn={ 24,2, } },
  { 39, 43, turn={ 24,1, 14,2, 12,2, 15,2, } },
  { 39, 44, turn={ 24,1, 14,2, 12,2, 15,1, } },
  { 40, 31, turn={ 4,1, 2,1, } },
  { 40, 35, turn={ 4,1, 2,2, 8,2, } },
  { 40, 36, turn={ 4,1, 2,2, 8,1, } },
  { 41, 82, turn={ 16,1, } },
  { 42, 40, turn={ 12,1, 14,1, } },
  { 43, 40, turn={ 15,2, 12,2, 14,1, }, reverse=true },
  { 44, 40, turn={ 15,1, 12,2, 14,1, }, reverse=true },
  { 45, 32, turn={ 18,2, 22,1, 21,2, 23,2, }, reverse=true },
  { 45, 38, turn={ 18,2, 22,1, 21,1, 7,2, }, reverse=true },
  { 46, 32, turn={ 18,1, 22,1, 21,2, 23,2, }, reverse=true },
  { 46, 38, turn={ 18,1, 22,1, 21,1, 7,2, }, reverse=true },
  { 73, 19, turn={ } },
  { 74, 45, turn={ 7,2, 21,1, 22,1, 18,2, } },
  { 74, 46, turn={ 7,2, 21,1, 22,1, 18,1, } },
  { 74, 81, turn={ 7,2, 21,1, 22,2, 17,1, 20,1, } },
  { 81, 42, turn={ 16,2, } },
  { 82, 32, turn={ 20,1, 17,2, 23,1, } },
  { 82, 32, turn={ 20,1, 17,1, 22,2, 21,2, 23,2, } },
  { 82, 38, turn={ 20,1, 17,1, 22,2, 21,1, 7,2, } },
  { 82, 73, turn={ 20,2, } },
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

if EEPActivateCtrlDesk then -- (Optional) Activate a control desk for the EEP layout, available as of EEP 16.1 patch 1
  local ok = EEPActivateCtrlDesk("Block control")             
  if ok then print("Show control desk 'Block control'") end
end

-- Use counter signal to set log level
local counterSignal = 47
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
DS_1 = "block=34	speed=15.668	"
DS_2 = "block=26	speed=11.006	"
DS_3 = "block=19	speed=30.035	"
DS_4 = "block=82	speed=18.273	"
DS_5 = "block=74	speed=17.670	"
DS_6 = "block=37	speed=26.444	"
DS_7 = "block=32	speed=39.978	"
