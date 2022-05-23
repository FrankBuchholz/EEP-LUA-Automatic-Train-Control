-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, Frank Buchholz, April 2022
-- EEP Lua code to automatically drive trains from block to block.
-- There's no need to write any Lua code, the code uses the data in the Configuration tables and variables below.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Configuration for modified Demo Layout 01 with reversing blocks
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Configure allowed blocks for different groups of trains and the wait time before leaving the block.
-- It's recommended to give enought time to stop trains at reversing signals.
local passengerTrains = {
  [8]  = 15, -- dead end block which reverses the direction of the train
  [9]  = 15, -- normal block 
  [10] = 1,  -- normal block
  [11] = 15, -- new block with normal routes and reversing routes
  [12] = 15, -- new block to find a CW route from block 11
}

-- Configure names and (optional) signals of trains and assign the allowed blocks.
-- Because some blocks reverse the direction of trains it's required to define the target speed for each train
local trains = {    
  { name = "Steam", signal = 4, allowed = passengerTrains, speed=60 },
}

-- Main signal to start automatic block control
local main_signal = 3

local block_signals = { 8, 9, 10, 11, 12, }
-- 5 signals use BLKSIGRED = 1, BLKSIGGRN = 2

local two_way_blocks = { { 9, 12 }, { 10, 11 }, }

-- Configure how to get from one block signal to another block signal by switching turnouts.
local routes = {
  -- generated routes
  { 8, 11,  turn={ 1,1, }, reverse=true }, -- reverse direction at dead end and then go clockwise
  { 9, 10,  turn={ }},
  { 10, 8,  turn={ 1,1, }},
  { 10, 9,  turn={ 1,2, }},
  { 11, 12, turn={ }},
  { 12, 11, turn={ 1,2 }},

  -- Additional routse to allow the train to reverse direction
  -- Depending on the position of the pre-signal 10 activate the corresponding routes. 

  -- Variant a) The pre-signal 10 is near the main signal and there is a lot of space in front of it. 
  -- All trains which stop and reverse their direction at block 11 will run over this pre-signal.
  -- This could be a typical situation in a large station with long tracks.
  -- In this case we simply define a reversing route from block 11 to 10:
  { 11,10, turn={}, reverse=true }, -- reverse direction at block signal 11 and then go counter-clockwise towards block 10

  -- Variant b) The pre-signal 10 is far away from the main signal and there is no of space in front of it. 
  -- Trains which reverses their direction at block 11 not run over this pre-signal!
  -- This could be a typical situation in a small station with short tracks.
  -- The trains do not ron over pre-signal 10, therefore we cannot define a route towards this block.
  -- We have to define routes to the next blocks:
  --{ 11, 8, turn={ 1,1, }, reverse=true }, -- reverse direction after block signal 11 and then go counter-clockwise
  --{ 11, 9, turn={ 1,2, }, reverse=true }, -- reverse direction after block signal 11 and then go counter-clockwise
}


-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local blockControl = require("blockControl") -- Load the module

blockControl.init({                          -- Initialize the module
  logLevel        = 1,

  trains          = trains,   
  
  twoWayBlocks    = two_way_blocks, -- Two way twin blocks (array or set of related blocks)
  routes          = routes,         -- Routes via turnouts from one block to the next block

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