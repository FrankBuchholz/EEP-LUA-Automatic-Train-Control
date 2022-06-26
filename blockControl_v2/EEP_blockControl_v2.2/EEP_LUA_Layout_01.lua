-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, April 2022
-- EEP Lua code to automatically drive trains from block to block.
-- There's no need to write any Lua code, the code uses the data in the Configuration tables and variables below.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Configuration for Demo Layout 01 based on block signal numbers
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Main signal to start automatic block control
local main_signal = 3

-- Configure allowed blocks for different groups of trains and the wait time before leaving the block. 
-- Wait time not defined (nil) or 0: no entry to this block, 1: block is allowed (drive throught), >1: minimal wait time in seconds between entering and leaving the block (= drive time from contact to signal + stop time).
local passengerTrains = {
-- [block signal] = minimal wait time,
  [8]  = 15, 
  [9]  = 1, 
  [10] = 1, 
}

-- Configure names and (optional) signals of trains and assign the allowed blocks.
local trains = {    
--  EEP name,       Train signal, Allowed block signals with wait time
  { name = "Steam", signal = 4,   allowed = passengerTrains, },
}

-- Configure how to get from one block signal to another block signal by switching turnouts.
local routes = {
-- { from block, to block, turn={ turnout, state, ...}}, with state: 1=main, 2=branch, 3=alternate branch
  { 8,10, turn={2,1} },
  { 9,10, turn={2,2} },
  {10, 8, turn={1,1} },
  {10, 9, turn={1,2} },
}

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local blockControl = require("blockControl") -- Load the module

blockControl.init({                          -- Initialize the module
  logLevel        = 1,

  trains          = trains,   
  
  routes          = routes,

  MAINSW          = main_signal, -- ID of the main switch (optional)

  -- [[ The default values work fine for this layout
  MAINON          = 1,           -- ON    state of main switch
  MAINOFF         = 2,           -- OFF   state of main switch
  BLKSIGRED       = 1,           -- RED   state of block signals
  BLKSIGGRN       = 2,           -- GREEN state of block signals
  TRAINSIGRED     = 1,           -- RED   state of train signals
  TRAINSIGGRN     = 2,           -- GREEN state of train signals
  --]]  
})

function EEPMain()

  blockControl.run()

  return 1
end