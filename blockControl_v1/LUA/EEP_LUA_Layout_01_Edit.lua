-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Rudy Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- There's no need to write any Lua code, the code uses the data in the Configuration tables and variables below.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
train   = {}
allowed = {}
route   = {}
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Configuration for Demo Layout 01
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
PLACE_TRAINS = 0 -- Place trains, fill the train[t] table, reload, change to PLACE_TRAINS = 0, reload.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

train[1] = {name="Steam", onoff=4, route=0, block=3}

--     block  1, 2, 3
allowed[1]= {15, 1, 1} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)
twowayblk = { 0, 0, 0}
blocksig  = { 8, 9,10}
memsig    = { 5, 6, 7}

-- route[n] = {from block, to block, turn={ID,state,...}} state: 1=main, 2=branch
route[ 1] = { 1,3,turn={2,1}}
route[ 2] = { 2,3,turn={2,2}}
route[ 3] = { 3,1,turn={1,1}}
route[ 4] = { 3,2,turn={1,2}}
 
MAINSW    = 3 -- id of the main switch
MAINON    = 1 -- 'on' state of main switch
MAINOFF   = 2 -- 'off' state of main switch
BLKSIGRED = 1 -- 'red' state of block signals
BLKSIGGRN = 2 -- 'green' state of block signals
MEMSIGRED = 1 -- 'red' state of memory signals
MEMSIGGRN = 2 -- 'green' state of memory signals

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

  for b=1,#blocksig do

    t = blkreserved[b] -- holds the train number or 0 if the block is free
	
    if stoptimer[b]>0 then stoptimer[b] = stoptimer[b] - 1 end -- count down the block stop time

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check for released blocks
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    if EEPGetSignal(memsig[b])==MEMSIGGRN and memsigold[b]==MEMSIGRED then -- A train released this block
      memsigold[b] = MEMSIGGRN      -- Set block memory old to free, now this 'if' statement won't run again
      blkreserved[b] = 0            -- Set block to 'free'
      blkreserved[twowayblk[b]] = 0 -- Also the two way twin block is now 'free'
      EEPSaveData(b, 0)             -- Save the state in file for when EEP closes
      EEPSaveData(twowayblk[b], 0)  -- Also save the two-way twin block state
      EEPSetSignal(blocksig[b],BLKSIGRED) -- Set the block signal to RED
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check arrivals and set new route requests
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
    if EEPGetSignal(memsig[b])==MEMSIGRED and memsigold[b]==MEMSIGGRN then -- There is a new train in this block
      print(t," ",train[t].name,"     arrived in ",b," - stop ",allowed[t][b],"s")
      EEPSaveData(b, t)                -- Save the train number in this block to disk, to be read when EEP reopens
      EEPSaveData(twowayblk[b], t+100) -- Save the the dummy train nr t+100 in the two way twin block on disk
      memsigold[b] = MEMSIGRED -- Set block memory old to 'occupied', now this 'if' statement won't run again
      request[b] = t           -- Flag is raised that train t in block b requests a new route
      if allowed[t][b]>1 then stoptimer[b] = 5 * allowed[t][b] end
      r = train[t].route
      pb = route[r][1]         -- previous bock where the train came from
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
          if free==0 then     -- the destination block and turnouts are free (VIA BLOCKS ARE NOT USED YET)
            fr = fr + 1       -- increment free routes counter
            available[fr] = r -- Store this free route in the 'available' table
          end
        end
      end
    end
    
  end -- for b=1, ...

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Randomly select a route to start from the available ones
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

  if EEPGetSignal(MAINSW)==MAINOFF then
    return 1             -- Quit the EEPmain() loop here, no new route is activated
  elseif fr>0 then       -- At least one route is available
    nr = available[math.random(fr)] -- A new route is randomly selected
    cb = route[nr][1]    -- Current block, where the train is now
    db = route[nr][2]    -- Destination block, where the train will drive to
    t = blkreserved[cb]  -- Nr of the train in the current block
    train[t].route = nr
    request[cb]  = 0     -- New route is allocated, reset the request for a new route
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
