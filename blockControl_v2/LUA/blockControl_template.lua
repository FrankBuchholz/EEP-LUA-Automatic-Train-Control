-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, April 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any Lua code, the code uses the data in the tables and variables.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Template showing all features
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Main signal to start automatic block control
-- (You can toggle the signal twice to show/hide tipp texts)
local main_signal = 80

-- (Optional) Use a counter signal to set the log level
--local counterSignal = 47

-- (Optional) Configure block signals
-- It is possible to derive this table from other variables, however, using it gives opportunities for consistency checks.
-- The order of the entries does not matter.
-- (You can choose any name for variable 'block_signals'.)
local block_signals  = { 
--19, 25, 26, 27, 
}

-- Configure allowed blocks for different groups of trains and the wait time before leaving the block. 
-- Wait time not defined (nil) or 0: no entry to this block, 1: block is allowed (drive throught), >1: minimal wait time in seconds between entering and leaving the block (= drive time from contact to signal + stop time).
-- (You can choose any name for these variables.)
local passengerTrains = {
--[block signal] = minimal wait time,
--[19] = 45,
}

local cargoTrains = {
--[block signal] = minimal wait time,
--[26] = 40,
}

-- Configure names and (optional) signals of trains and assign the allowed blocks.
-- (You can choose any name for variable 'Trains', but you have to use the names for the components 'name', 'signal', 'allowed'.)
-- (Variable 'Trains' could be an array with implizit keys, or you can create a table with explicit keys like [9] or names ["Cargo1"] to identify entries.) 
local trains = {}                                      
--       Key (your choice) =   EEP name,            Train signal, Allowed block signals with wait time
--trains["Steam CCW"]      = { name = "#Steam CCW", signal = 9,   allowed = passengerTrains }

-- Configure pairs of two way twin block signals.
-- (You can choose any name for variable 'two_way_blocks'.)
local two_way_blocks = { 
--{ pair of two way blocks },
--{ 82, 81 }, 
}

-- Configure how to get from one block to another block by switching turnouts.
-- Let's introduce constants for better readibility 
local f = 1 -- turnout position "fahrt"
local a = 2 -- turnout position "abzweig"
-- (You can choose any name for variable 'routes', but you have to use the name for components 'turn'.)
local routes = {
--{ from block, to block, turn={ turnout, state, ...}}, with state: 1=main, 2=branch, 3=alternate branch
--{ 29, 74, turn={ 13,a, 11,a }}, -- from block 29 to block 74 via turnouts 13 and 11
}

-- Configure required paths between starting blocks, some via blocks to ending blocks.
-- If similar paths have multiple starting blocks or ending blocks you can combine the paths by putting these blocks into brackets.
-- A path could have one or more via-blocks as well. If an intermediate part of the path has multiple options, than you could put these blocks into brackets as well.  
local anti_deadlock_paths = {
--{ { list of parallel from blocks }, list of via blocks, { list of parallel target blocks } },
--{ {46, 45}, 38, {28, 29, 30} }, -- from block 46 or 45 via block 38 to one of the blocks 28, 29 or 30
}




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()

local blockControl = require("blockControl")   -- Load the module

blockControl.init({                            -- Initialize the module
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme

  trains          = trains,         -- (Optional) Unknows trais get detected automatically, however, such trains do not have a train signal and can go everywhere.
  
  blockSignals    = block_signals,  -- Block signals
  twoWayBlocks    = two_way_blocks, -- Two way twin blocks (array or set of related blocks)
  routes          = routes,         -- Routes via turnouts from one block to the next block
  paths           = anti_deadlock_paths, -- Critical paths on which trains can go

  MAINSW          = main_signal,    -- ID of the main switch (optional)

  -- [[ Optional if the default values work fine for the layout
  MAINON          = 1,              -- ON    state of main switch
  MAINOFF         = 2,              -- OFF   state of main switch
  BLKSIGRED       = 1,              -- RED   state of block signals
  BLKSIGGRN       = 2,              -- GREEN state of block signals
  TRAINSIGRED     = 1,              -- RED   state of train signals
  TRAINSIGGRN     = 2,              -- GREEN state of train signals
  --]]  
})

-- [[ (Optional) Set one or more runtime parameters at any time 
blockControl.set({
  logLevel        = 1,              -- (Optional) Log level 0 (default): off, 1: normal, 2: full, 3: extreme
  showTippText    = true,           -- (Optional) Show tipp texts true / false (Later you can toggle the visibility of the tipp texts using the main switch.)
  start           = false,          -- (Optional) Activate/deactivate main signal. Useful to start automatic block control after finding all known train.
  startAllTrains  = true,           -- (Optional) Activate/deactivate all train signals
})
--]]

if EEPActivateCtrlDesk then         -- (Optional) Activate a control desk for the EEP layout, available as of EEP 16.1 patch 1
  local ok = EEPActivateCtrlDesk("Block control")             
  if ok then print("Show control desk 'Block control'") end
end

--[[ (Optional) Use counter signal to set log level
--local counterSignal = 47
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
--]]


function EEPMain()

  blockControl.run()
  --blockControl.printStatus(60)    -- (Optional) Show status and statistics every 60 seconds

  return 1
end
