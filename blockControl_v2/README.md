# EEP-Lua-Automatic-Train-Control

You can download version 2 of the EEP Lua Automatic Traffic Control Project here:
[`EEP_blockControl.zip`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/raw/main/blockControl_v2/EEP_blockControl.zip)

An explanation on how it works and on how to fill the Lua tables with data that define your own layout goes with it:

- English: [`EEP_Lua_Automatic_Train_Control_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatic_Train_Control_v2.pdf)
- German: [`EEP_Lua_Automatische_Zugsteuerung_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatische_Zugsteuerung_v2.pdf)

The EEP folder contains several working EEP demo layouts with the Lua code and the layout definition included.

- Demo 01: This is the first layout to demonstrate how automatic train traffic can be generated on any EEP (model) railway simulator layout, using a Lua script. The user doesn't have to (re)write any code, all that is needed is to define the layout by entering data on trains, signals and routes in a set of tables.

- Demo 02: In the second layout we use four blocks and add a second train.

- Demo 03: In the third layout we use a two way block and see how to configure it in the Lua data.

- Demo 04: In the fourth layout we use two dead end tracks and see how we an make trains reverse there. We'll also run a third train, configure the layout in Lua and drive three trains around without collisions.

- Demo 05: In the fifth layout we have a look at a somewhat more serious layout with 27 blocks, 43 routes and 7 trains, all driving simultaneously!  
You find a second variant of that layout which make use of the [BetterContacts](https://emaps-eep.de/lua/bettercontacts) module from [Benny](https://www.eepforum.de/user/37-benny-bh2/).

- Demo "Double Slip Turnouts": This demo layout shows both flavors of a DST, a 4-turnout-DST at the top and a track object DST at the bottom.

- Demo "Train Reversal": Two modified demo layouts based on demo 04 and 01 show how to reverse the direction of trains in dead ends or two-way blocks without using contacts. The new demo "Baan Nico" also uses the possibility of train reversal.

The `LUA` folder contains the `blockControl` module.

The `GBS` folder contains 5 files with the track view consoles, which are inserted into the demo layouts as well.
Below the start/stop signal are the train signals. These signals can also be used in automatic operation.
The block signals as well as the switches must not be adjusted in automatic operation.

A series of YouTube videos can be found here:

- [Automatic Train Traffic on any EEP Layout v2 - 01](https://www.youtube.com/watch?v=6X1fmBAHgpY&ab_channel=Rudysmodelrailway)  
This is the first video in a series to demonstrate how automatic train traffic can be generated on any EEP (model) railway simulator layout, using a Lua script. The user doesn't have to (re)write any code, all that is needed is to define the layout by entering data on trains, signals and routes in a set of tables.

- [Automatic Train Traffic on any EEP Layout v2 - 02](https://www.youtube.com/watch?v=qEFNnP-s14c&ab_channel=Rudysmodelrailway)  
In demo 2 we add a second train. They drive around, controlled by Lua, without ever colliding. Lua only allows a train to start driving if the destination block and all the required turnouts on the way are free. If a train is allowed to start, Lua reserves the turnouts and the destination block; these are now unavailable to other trains until they are released again when the train arrives at its destination block, which is detected via the block entry sensor.

- [Automatic Train Traffic on any EEP Layout v2 - 03](https://www.youtube.com/watch?v=YouDOfVNHgk&ab_channel=Rudysmodelrailway)  
Let's have a two way traffic track in the layout and see how this can be configured.
A two way track is treated as two separate one way blocks on the same track. Both blocks have their own block signal and entry sensor. When Lua reserves one of the two blocks for a train, the other block has to be reserved too. Likewise, when released, the twin block also has to be released. We'll have to tell Lua which blocks are 'two way twin' blocks, such that this extra reservation and release can take place.

- [Automatic Train Traffic on any EEP Layout v2 - 04](https://www.youtube.com/watch?v=x8MSMDGuqrM&ab_channel=Rudysmodelrailway)  
Based on the Demo 3 layout we now add two dead end tracks at station North. First both ways to make a dead end track in EEP are explained. Then the Lua configuration for this layout is examined, step by step. The dead ends don’t require any specific configuration, they are treated like any other block.

- [Automatic Train Traffic on any EEP Layout v2 - 05](https://www.youtube.com/watch?v=qjrlIr_JMXY&ab_channel=Rudysmodelrailway)  
Demo 5 is a somewhat larger model railway layout, with 27 blocks and 7 trains. Two trains drive from / to the station counterclockwise, 2 trains do the same clockwise, and 3 cargo trains shuttle between the 4 groups of dead end tracks that resemble industry areas.  
Via the ‘allowed blocks’ tables we specify which trains are allowed to drive where.  
The trains table specifies the train names, their start/stop switches and their allowed blocks table.  
The routes table specifies every possible route from block A to block B and which turnuts to switch to get there.  
We also have a look at the section where the parameters can be set to change the amount of messages to show on the Lua screen, if the tooltips show or not, if the main switch is on or off and if all train switches are on or off at startup.

- [Automatic Train Traffic on any EEP Layout v2 - 06](https://www.youtube.com/watch?v=xxssAIgqxk0&ab_channel=Rudyshobbychannel)  
The Lua code to create automatic train traffic on your EEP layout can be generated with a code generator tool. The video shows how.

Any questions, comments and ideas are welcome. In the meantime … have fun.
