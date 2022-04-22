-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Find a solution to use 'via' blocks'.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
PLACE_TRAINS = 0 -- To place trains, change the code to PLACE_TRAINS=1, place the trains and fill the trains[t] table
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Below configuration is for the RB31 layout
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
train     = {}
train[1]  = {name="Steam CCW", onoff=9, route=0, block=19}
train[2]  = {name="Orange CCW", onoff=72, route=0, block=16}
train[3]  = {name="Blue CW", onoff=77, route=0, block=3}
train[4]  = {name="Cream CW", onoff=78, route=0, block=24}
train[5]  = {name="Shuttle Red", onoff=79, route=0, block=13}
train[6]  = {name="Shuttle Yellow", onoff=92, route=0, block=9}
train[7]  = {name="Shuttle Steam", onoff=93, route=0, block=8}

allowed={}
--      block  1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
allowed[1]= {35,25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0}
allowed[2]= {35,25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0}
allowed[3]= { 0, 0,40,30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0}
allowed[4]= { 0, 0,25,30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0}
allowed[5]= { 0, 1, 1, 1,28,28,28,28,28,28,28,28,28, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1}
allowed[6]= { 0, 1, 1, 1,28,28,28,28,28,28,28,28,28, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1}
allowed[7]= { 0, 1, 1, 1,28,28,28,28,28,28,28,28,28, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1}
twowayblk = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,18,17, 0, 0,22,21, 0, 0, 0,27,26}
blocksig  = {19,25,26,27,28,29,30,35,36,44,43,46,45,37,39,41,82,81,73,34,33,32,42,40,31,74,38}
memsig    = {47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,75,76}

-- Configure possible routes between blocks here
-- route[n] = {from block, to block, via={block,...}, turn={ID,state,...}} state: 1=main, 2=branch
route={}
route[ 1] = { 1,14,turn={3,1}}
route[ 2] = { 2,14,turn={3,2}}
route[ 3] = { 3,21,turn={1,2}}
route[ 4] = { 4,20,turn={}}
route[ 5] = { 5,26,turn={11,1}}
route[ 6] = { 6,26,turn={13,1,11,2}}
route[ 7] = { 7,26,turn={13,2,11,2}}
route[ 8] = { 8,15,turn={8,2,2,2,4,2,5,1}}
route[ 9] = { 9,15,turn={8,1,2,2,4,2,5,1}}
route[10] = {10,24,turn={15,1,12,2,14,1}}
route[11] = {11,24,turn={15,2,12,2,14,1}}
route[12] = {12,22,turn={18,1,22,1,21,2,23,2}}
route[13] = {12,27,turn={18,1,22,1,21,1,7,2}}
route[14] = {13,22,turn={18,2,22,1,21,2,23,2}}
route[15] = {13,27,turn={18,2,22,1,21,1,7,2}}
route[16] = {14,15,turn={5,2}}
route[17] = {15,10,turn={24,1,14,2,12,2,15,1}}
route[18] = {15,11,turn={24,1,14,2,12,2,15,2}}
route[19] = {15,16,turn={24,2}}
route[20] = {16,17,turn={16,1}}
route[21] = {17,19,turn={20,2}}
route[22] = {17,22,turn={20,1,17,2,23,1}}
route[23] = {18,23,turn={16,2}}
route[24] = {19, 1,turn={}}
route[25] = {20,12,turn={7,1,21,1,22,1,18,1}}
route[26] = {20,13,turn={7,1,21,1,22,1,18,2}}
route[27] = {20,18,turn={7,1,21,1,22,2,17,1,20,1}}
route[28] = {21,12,turn={23,2,21,2,22,1,18,1}}
route[29] = {21,13,turn={23,2,21,2,22,1,18,2}}
route[30] = {21,18,turn={23,1,17,2,20,1}}
route[31] = {22, 2,turn={1,1}}
route[32] = {23,24,turn={12,1,14,1}}
route[33] = {24, 8,turn={4,1,2,2,8,2}}
route[34] = {24, 9,turn={4,1,2,2,8,1}}
route[35] = {24,25,turn={4,1,2,1}}
route[36] = {25, 3,turn={6,1}}
route[37] = {25, 4,turn={6,2}}
route[38] = {26,12,turn={7,2,21,1,22,1,18,1}}
route[39] = {26,13,turn={7,2,21,1,22,1,18,2}}
route[40] = {26,18,turn={7,2,21,1,22,2,17,1,20,1}}
route[41] = {27, 5,turn={11,1}}
route[42] = {27, 6,turn={11,2,13,2}}
route[43] = {27, 7,turn={11,2,13,1}}
 
MAINSW    = 80 -- ID of the main switch
MAINON    = 1 -- ON state of main switch
MAINOFF   = 2 -- OFF   state of main switch
BLKSIGRED = 1 -- RED   state of block signals
BLKSIGGRN = 2 -- GREEN state of block signals
MEMSIGRED = 1 -- RED   state of memory signals
MEMSIGGRN = 2 -- GREEN state of memory signals

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@ No need to change anything below this line
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

blkreserved   = {} -- Stores the free/reserved state for every block, 0=free, trainnr=reserved
turnreserved  = {} -- Stores the free/reserved state for every turnout, 0=free, 1=reseved
available     = {} -- Stores available routes. Per EEPmain() cycle only one route will be randomly selected fom this table
memsigold     = {} -- Old memory signal value, used to check with memsig[b] for 0>1 or 1>0 transitions
request       = {} -- A train that enters a block will request a new route: trainnr=request pending, 0=no request
stoptimer     = {} -- Waittime, decremented every EEPmain() cycle, which is 5x/s

train[0]      = {name=" ",route=0, block=0}
train[100]    = {name=" ",route=0, block=0}
allowed[0]    = 0
twowayblk[0]  = 0
blocksig[0]   = 0
memsig[0]     = 0
blkreserved[0]= 0
memsigold[0]  = 0
request[0]    = 0
stoptimer[0]  = 0
route[0]      = {0,0,turn={}}
for to=0,99 do turnreserved[to] = 0 end -- BEWARE, 99 is the max number of turnouts. If more, change the number!

clearlog()
math.randomseed(os.time())
cycle = 0

if PLACE_TRAINS==1 then
  EEPSetSignal(MAINSW,MAINOFF)
  for b=1,#blocksig do
    EEPSaveData(b,0) -- Write 0's to the block reservation disk file to make them not nil
    EEPSetSignal(blocksig[b],BLKSIGRED) -- Set all block signals to RED
  end
  for t=1,#train do                -- For all trains ...
    EEPSaveData(train[t].block, t) -- ... write the train nr to its current block in the reservation disk file
    EEPSaveData(twowayblk[train[t].block],t+100) -- Reserve the two way twin block with dummy train nr t+100
    EEPSetSignal(train[t].onoff, MEMSIGRED)
  end
  print("Initialization finished, change code to PLACE_TRAINS=0")
end

for b=1,#blocksig do
  notnil, t      = EEPLoadData(b) -- Read the train nr that reserves block b from the disk file ...
  blkreserved[b] = t              -- ... and write it in the blkreserved[b] table
  memsigold[b]   = MEMSIGGRN
  request[b]     = 0
  stoptimer[b]   = 0
  if t>0 and t<100 then -- if it's a two way twin block (t>100) we don't put memsig[b] on RED
    EEPSetSignal(memsig[b],MEMSIGRED)
    print(b," ",t," ",train[t].name)
  else 
    EEPSetSignal(memsig[b],MEMSIGGRN)
    if t>100 then print(b," ",t," ",train[t-100].name) end
  end

end

function EEPMain()
  
  if PLACE_TRAINS==1 then return 1 end -- do nothing as long as PLACE_TRAINS is 1
  cycle = cycle + 1 -- EEPMain cycle #
  fr = 0 -- free routes

  if cycle%25==1 then -- Do this every 5 seconds, given that EEPmain() runs 5x/s
    if EEPGetSignal(MAINSW)==MAINOFF then print("Main switch is off") end
  end

  for b=1,#blocksig do -- check all blocks for arrivals and calculate possible new routes

    t = blkreserved[b] -- Train t has reserved this block (could be 0, then the block is free)
	
    if stoptimer[b]>0 then stoptimer[b] = stoptimer[b] - 1 end -- count down the block stop time

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check for released blocks
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    if EEPGetSignal(memsig[b])==MEMSIGGRN and memsigold[b]==MEMSIGRED then -- A train released this block
      memsigold[b] = MEMSIGGRN -- Set block memory old to free, now this 'if' statement won't run again
      blkreserved[b] = 0                  -- Set block to 'free'
      blkreserved[twowayblk[b]] = 0        -- Also the two way twin block is now 'free'
      EEPSaveData(b, 0)                 -- Save the state in file for when EEP closes
      EEPSaveData(twowayblk[b], 0)      -- Also save the two-way twin block state
      EEPSetSignal(blocksig[b],BLKSIGRED)  -- Set the block signal to RED
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check arrivals and set new route requests
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
    if EEPGetSignal(memsig[b])==MEMSIGRED and memsigold[b]==MEMSIGGRN then -- There is a new train in this block
      print(t," ",train[t].name,"     arrived in ",b," - stop ",allowed[t][b],"s")
      EEPSaveData(b, t)                -- Save the train number in this block to disk, to be read when EEP reopens
      EEPSaveData(twowayblk[b], t+100) -- Save the the dummy train nr t+100 in the two way twin block on disk
      memsigold[b] = MEMSIGRED      -- Set block memory old to 'occupied', now this 'if' statement won't run again
      request[b] = t                -- Flag is raised that train t in block b requests a new route
      if allowed[t][b]>1 then stoptimer[b] = 5 * allowed[t][b] end
      r = train[t].route
      pb = route[r][1]                   -- previous bock where the train came from
      EEPSetSignal(memsig[pb],MEMSIGGRN) -- Set memory signal of previous block to GREEN to release it next cycle
      for to=1,#route[r].turn/2 do
        turnreserved[route[r].turn[to*2-1]] = 0 -- Release the turnouts of the current route
      end
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Make a list of all possible routes for trains who's stop stoptimer ran out
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    if request[b]>0 and stoptimer[b]==0 and EEPGetSignal(train[t].onoff)==MEMSIGGRN then -- Stop time passed and train switch is ON
      for r=1,#route do -- Check for free destination blocks in the route table
        if route[r][1]==b and allowed[t][route[r][2]]>0 then
          free = blkreserved[route[r][2]] -- Check if the destination block is free (free==0)
          for to=1,#route[r].turn/2 do -- Check if the route turnouts are free (free==0)
            free = free + turnreserved[route[r].turn[to*2-1]]
          end
          if free==0 then -- the destination block and turnouts are free
            fr = fr + 1 -- increment free routes counter
            available[fr] = r -- Store this free route in the 'available' table
--            if EEPGetSignal(MAINSW)==MAINON then print ("     can go from ",route[r][1]," to ",route[r][2]) end
          end
        end
      end
    end
    
  end -- for b=1, ...

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Randomly select a route to start from the available ones
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

  if EEPGetSignal(MAINSW)==MAINOFF then
    return 1 -- Quit the EEPmain() loop here, no new route is activated
  elseif fr>0 then -- At least one route is available
    nr = available[math.random(fr)] -- A new route is randomly selected
    cb = route[nr][1] -- Current block, where the train is now
    db = route[nr][2] -- Destination block, where the train will drive to
    t = blkreserved[cb]  -- Nr of the train in the current block
    train[t].route = nr
    request[cb]  = 0  -- New route is allocated, reset the request for a new route
    blkreserved[db] = t  -- Set destination block to 'reserved', other trains can't select it anymore
    blkreserved[twowayblk[db]] = t+100 -- Also set the two way twin block to 'reserved' with the dummy train nr t+100
    for to=1,#route[nr].turn/2 do -- Reserve and switch the turnouts
      EEPSetSwitch(route[nr].turn[to*2-1],route[nr].turn[to*2])
      turnreserved[route[nr].turn[to*2-1]] = 1 -- Reserve the turnout
    end
    EEPSetSignal(blocksig[cb],BLKSIGGRN) -- Current block signal to GREEN, the train may go.
    EEPSetSignal(blocksig[db],BLKSIGRED) -- Destination block signal to RED, train may have to stop there.
    print(t," ",train[t].name," from ",cb," to ",db)
  end

  return 1
end
