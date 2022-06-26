-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, April 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any Lua code, the code uses the data in the tables and variables.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Configuration for Demo Layout 05 based on block signal numbers
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Main signal to start automatic block control
-- (You can toggle the signal twice to show/hide tipp texts)
local main_signal = 80

-- Configure block signals (this is optional if you are using block signal numbers)
-- (It is possible to derive this table from other variables, however, using it gives opportunities for consistency checks.)
-- (The order of the entries does not matter.)
-- (You can choose any name for variable 'block_signals'.)
--[[
local block_signals  = { 
  19, 25, 26, 27,                     -- Station North
  28, 29, 30,                         -- Cargo Station North
  35, 36,                             -- Cargo Station West
  44, 43, 46, 45,                     -- Cargo Station South
  37, 39, 41, 82, 81,                 -- Connections
  73, 34, 33, 32, 42, 40, 31, 74, 38,
}
--]]

-- Configure allowed blocks for different groups of trains and the wait time before leaving the block. 
-- Wait time not defined (nil) or 0: no entry to this block, 1: block is allowed (drive throught), >1: minimal wait time in seconds between entering and leaving the block (= drive time from contact to signal + stop time).
-- (You can choose any name for these variables.)
local passengerTrains = {
-- [block signal] = minimal wait time,
  -- Station North CCW
  [19] = 45, -- You may want to copy the data for train 'Orange CCW' with wait time 25
  [25] = 45, -- You may want to copy the data for train 'Orange CCW' with wait time 25 

  -- Connection CCW from Station North to Station North
  [37] = 1, 
  [39] = 1, 
  [41] = 1, 
  [82] = 1, 
  [73] = 1, [32] = 1, 
}
local cargoTrains = {
-- [block signal] = minimal wait time,
  -- Station North CW
  [26] = 40, -- You may want to copy the data for train 'Cream CW' with wait time 25
  [27] = 30,

  -- Connections CW from Station North to Station North
  [33] = 1, [34] = 1, 
  [81] = 1, 
  [42] = 1, 
  [40] = 1, 
  [31] = 1, 
}
local shuttleTrains = {
-- [block signal] = minimal wait time,
  -- Station North CCW
  [25] = 1, 
  -- Station North CW
  [26] = 1, 
  [27] = 1,

  -- Cargo Station North
  [28] = 28,
  [29] = 28,
  [30] = 28,

  -- Cargo Station West
  [35] = 28,
  [36] = 28,

  -- Cargo Station South
  [44] = 28,
  [43] = 28,
  [46] = 28,
  [45] = 28, 

  -- Connections from Station North CCW to Cargo Station South
  [37] = 1, 
  [39] = 1,
   
  -- Connections from Station North CW to CargoStation South
  [33] = 1, [34] = 1, 
   
  -- Connections from Cargo Station West to Cargo Station South
  [74] = 1, 
   
  -- Connections from Cargo Station South to Station North CCW
  [32] = 1, 

  -- Connections from Cargo Station South to Cargo Station West and Station North CW 
  [40] = 1, 
  [31] = 1, 
   
  -- Connections from Cargo Station South to Cargo Station North
  [38] = 1,
}

-- [[ -- ### Begin: check paths
-- Sometimes a lockdown could occur if trains just travel from block to block.
-- Example for a modified demo layout 05 where you do now allow shuttle trains to go to block 32.
-- Let's modify the entry created above:
shuttleTrains[32] = nil		-- Do not allow shuttle trains to go to block 32 

-- Now, trains on block 45 and 46 could only leave via block 74 which would lock twin block 38 as well.
-- Everything seems to work fine but let's assume blocks 45 and 46 are both occupied by trains which are waiting.  
-- Then, no train should leave from one of the blocks 28, 29, or 30 towards block 38 which would lock twin block 74.
-- Otherwise, none of the trains on block 45, 46, and 38 could find a new route anymore.  
--]] -- ### End: check paths


-- Configure names and (optional) signals of trains and assign the allowed blocks.
-- (You can choose any name for variable 'Trains', but you have to use the names for the components 'name', 'signal', 'allowed'.)
-- (Variable 'Trains' could be an array with implizit keys, or you can create a table with explicit keys like [9] or names ["Cargo1"] to identify entries.) 
local trains = {}                                      
-- [[
--    Key (your choice) =   EEP name,               Train signal, Allowed block signals with wait time
trains["Steam CCW"]     = { name="#Steam CCW",      signal=9,     allowed = passengerTrains }
trains["Orange CCW"]    = { name="#Orange CCW",     signal=72,    allowed = passengerTrains }
trains["Blue CW"]       = { name="#Blue CW",        signal=77,    allowed = cargoTrains     }
trains["Cream CW"]      = { name="#Cream CW",       signal=78,    allowed = cargoTrains     }
trains["Shuttle 1"]     = { name="#Shuttle Red",    signal=79,    allowed = shuttleTrains   }
trains["Shuttle 2"]     = { name="#Shuttle Yellow", signal=92,    allowed = shuttleTrains   }
trains["Shuttle 3"]     = { name="#Shuttle Steam",  signal=93,    allowed = shuttleTrains   }
--]] 

-- Configure pairs of two way twin block signals.
-- (You can choose any name for variable 'two_way_blocks'.)
local two_way_blocks = { {82, 81}, {32, 33}, {74, 38}, }

-- Configure how to get from one block to another block by switching turnouts.
-- Let's introduce constants for better readibility 
local f = 1 -- turnout position "fahrt"
local a = 2 -- turnout position "abzweig"
-- (You can choose any name for variable 'routes', but you have to use the name for components 'turn'.)
local routes = {
-- { from block, to block, turn={ turnout, state, ...}}, with state: 1=main, 2=branch, 3=alternate branch
  -- Station North
  { 19, 37, turn={  3,f }},
  { 25, 37, turn={  3,a }},
  { 26, 33, turn={  1,a }},
--{ 27, 34, turn={}},       -- no turnout required to go from block 27 to block 34
  { 27, 34 },       		-- you can omit an empty turn parameter 

  -- Cargo Station North, explicit paths are required for leaving the station to avoid a lockdown situation:
  -- Required paths from blocks 28, 29 or 30 via block 74 to one of the blocks 45 or 46
  { 28, 74, turn={ 11,f }},
  { 29, 74, turn={ 13,a, 11,a }},
  { 30, 74, turn={ 13,f, 11,a }},
  { 74, 45, turn={  7,a, 21,f, 22,f, 18,a }},
  { 74, 46, turn={  7,a, 21,f, 22,f, 18,f }},

  -- Cargo Station West
  { 35, 39, turn={  8,a,  2,a,  4,a,  5,a }},
  { 36, 39, turn={  8,f,  2,a,  4,a,  5,a }},

  -- Cargo Station South
  { 43, 40, turn={ 15,a, 12,a, 14,f }},
  { 44, 40, turn={ 15,f, 12,a, 14,f }},
  { 45, 32, turn={ 18,a, 22,f, 21,a, 23,a }},
  { 46, 32, turn={ 18,f, 22,f, 21,a, 23,a }},

  -- Cargo Station South, explicit paths are required for leaving the station to avoid a lockdown situation:
  -- Required paths from blocks 45 or 46 via block 38 to one of the blocks 28, 29 or 30
  { 45, 38, turn={ 18,a, 22,f, 21,f,  7,a }},
  { 46, 38, turn={ 18,f, 22,f, 21,f,  7,a }},
  { 38, 28, turn={ 11,f }},
  { 38, 29, turn={ 11,a, 13,a }},
  { 38, 30, turn={ 11,a, 13,f }},

  -- Connections
  { 37, 39, turn={  5,f }},
  { 39, 44, turn={ 24,f, 14,a, 12,a, 15,f }},
  { 39, 43, turn={ 24,f, 14,a, 12,a, 15,a }},
  { 39, 41, turn={ 24,a }},
  { 41, 82, turn={ 16,f }},
  { 82, 73, turn={ 20,a }},
  { 82, 32, turn={ 20,f, 17,a,             23,f }},
--{ 82, 32, turn={ 20,f, 17,f, 22,a, 21,a, 23,a }}, -- Omit alternate but longer path
--{ 82, 38, turn={ 20,f, 17,f, 22,a, 21,f,  7,a }}, -- Ignore this path to test potential lockdown situation
  { 81, 42, turn={ 16,a }},

  { 73, 19, turn={}},
  { 34, 46, turn={  7,f, 21,f, 22,f, 18,f }},
  { 34, 45, turn={  7,f, 21,f, 22,f, 18,a }},
  { 34, 81, turn={  7,f, 21,f, 22,a, 17,f, 20,f }},
  { 33, 46, turn={ 23,a, 21,a, 22,f, 18,f }},
  { 33, 45, turn={ 23,a, 21,a, 22,f, 18,a }},
  { 33, 81, turn={ 23,f,             17,a, 20,f }},
--{ 33, 81, turn={ 23,a, 21,a, 22,a, 17,f, 20,f }}, -- Omit alternate but longer path
  { 32, 25, turn={  1,f }},
  { 42, 40, turn={ 12,f, 14,f }},
  { 40, 35, turn={  4,f,  2,a,  8,a }},
  { 40, 36, turn={  4,f,  2,a,  8,f }},
  { 40, 31, turn={  4,f,  2,f }},
  { 31, 26, turn={  6,f }},
  { 31, 27, turn={  6,a }},
  { 74, 81, turn={  7,a, 21,f, 22,a, 17,f, 20,f }},
}

-- Configure required paths between starting blocks, some via blocks to ending blocks.
-- If similar paths have multiple starting blocks or ending blocks you can combine the paths by putting these blocks into brackets.
-- A path could have one or more via-blocks as well. If an intermediate part of the path has multiple options, than you could put these blocks into brackets as well.  
local anti_deadlock_paths = {
  -- Cargo Station North
  { {28,29,30}, 74, {46,45}    }, -- from block 28, 29 or 30 via block 74 to one of the blocks 46 or 45
  -- Cargo Station South
  { {46,45},    38, {28,29,30} }, -- from block 46 or 45 via block 38 to one of the blocks 28, 29 or 30
}


--[[ Test: Add some wrong data to trigger error messages
table.insert( block_signals,  99 )                       -- Missing data for this additional block signal
table.insert( two_way_blocks, { 100, 101 } )             -- Unknown blocks 
table.insert( routes,         { 100, 101, turn={ 1 }} )  -- Unknown blocks, inconsistent turn data
table.insert( paths,          { 100, 101 } )             -- Unknown blocks
--]]


-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()

require("BetterContacts_BH2")				-- Load module BetterContacts, see https://emaps-eep.de/lua/bettercontacts		

blockControl = require("blockControl")   	-- Load the module (use a global variable to serve betterContacts) 

blockControl.init({                 -- Initialize the module
  BetterContacts  = true,			-- (Optional) Do not generate functions for entering and leaving blocks if module BetterContacts is used

  trains          = trains,         -- (Optional) Unknown trains get detected automatically, however, such trains do not have a train signal and can go everywhere.
  
  blockSignals    = block_signals,  -- Block signals
  twoWayBlocks    = two_way_blocks, -- Two way twin blocks (array or set of related blocks)
  routes          = routes,         -- Routes via turnouts from one block to the next block
  paths           = anti_deadlock_paths, -- Critical paths on which trains can go

  MAINSW          = main_signal,    -- ID of the main switch (optional)

  --[[ The default values work fine for this layout
  MAINON          = 1,              -- ON    state of main switch
  MAINOFF         = 2,              -- OFF   state of main switch
  BLKSIGRED       = 1,              -- RED   state of block signals
  BLKSIGGRN       = 2,              -- GREEN state of block signals
  TRAINSIGRED     = 1,              -- RED   state of train signals
  TRAINSIGGRN     = 2,              -- GREEN state of train signals
  --]]  
})

-- [[ Optional: Set one or more runtime parameters at any time 
blockControl.set({
  logLevel        = 1,           -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme
  showTippText    = true,        -- (Optional) Show tipp texts true / false (Later you can toggle the visibility of the tipp texts using the main switch.)
  start           = false,       -- (Optional) Activate/deactivate main signal. Useful to start automatic block control after finding all known train.
  startAllTrains  = true,        -- (Optional) Activate/deactivate all train signals
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

  -- Module ShowGlobalVariables from https://github.com/FrankBuchholz/EEP/blob/master/ShowGlobalVariables.lua
  if not ShowGlobalVariables then ShowGlobalVariables = require("ShowGlobalVariables")() end  -- Show global variables once

  blockControl.run()

  return 1
end
