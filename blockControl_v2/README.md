# EEP-Lua-Automatic-Train-Control

## Documentation

You find an explanation on how it works and on how to fill the Lua tables with data that define your own layout here:

- English: [`EEP_Lua_Automatic_Train_Control_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatic_Train_Control_v2.pdf)
- German: [`EEP_Lua_Automatische_Zugsteuerung_v2.pdf`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/blob/main/blockControl_v2/EEP_LUA_Automatische_Zugsteuerung_v2.pdf)

## Files

You can download the latest version of the EEP Lua Automatic Traffic Control project here:
[`EEP_blockControl.zip`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/releases/latest/download/EEP_blockControl.zip)

The EEP folder contains several working EEP demo layouts with the Lua code and the layout definition included.

The `LUA` folder contains the `blockControl` module and template files, which you can use as a starting point to develop your own Lua ATC scripts.

The `GBS` folder contains files with the track view consoles, which are inserted into the demo layouts as well.
Near the start/stop signal you find the train signals. These signals can also be used in automatic operation.
The block signals as well as the switches must not be adjusted in automatic operation.

## Online tools

The `routes` table in the Lua configuration section describes the available routes from one block to the next by defining the ‘main’ / ‘branch’ states of the turnouts between the two blocks. This table can be created by hand but this requires great focus … one small mistake with a turnout state can cause a train to drive to an unexpected block, resulting in erratic automated traffic.

Two tools come to the rescue.

- As a first step, you can use the [Track Plan Program](https://frankbuchholz.github.io/EEP_convert_anl3_file/EEP_Gleisplan.html). It shows the EEP track plan in your browser window, including signals and switch numbers, in an easy-to-read format.
- A second tool goes a big step further: it can create a proposal for all Lua configuration tables except the paths table. First open the track plan in the track plan program. Now open the [Generate Program](https://frankbuchholz.github.io/EEP_convert_anl3_file/EEP_blockControl.html) in another tab of the same browser and click the "Generate" button.
- Finally, you can use the [Inventory Program](https://frankbuchholz.github.io/EEP_convert_anl3_file/EEP_Inventar.html) to check the settings of the contacts including the Lua function in the contacts.

## Videos

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

- [Automatic Train Traffic on any EEP Layout v2 - 04B](https://www.youtube.com/watch?v=4VcZgUUgHy0&ab_channel=Rudysmodelrailway)  
In the previous video on the Demo 4 layout we allowed every train on every block. This had the effect that passenger trains started to drive backwards when moving out of the dead end blocks, which is unrealistic. By simply changing the allowed blocks tables we’ll make the orange passenger train drive clockwise, the steam train drive counter-clockwise and the cargo train is the only one that drives into the dead ends. All three trains can use the middle block of station South, which is a two way block, where they will drive through if they can.

- [Automatic Train Traffic on any EEP Layout v2 - 05](https://www.youtube.com/watch?v=qjrlIr_JMXY&ab_channel=Rudysmodelrailway)  
Demo 5 is a somewhat larger model railway layout, with 27 blocks and 7 trains. Two trains drive from / to the station counterclockwise, 2 trains do the same clockwise, and 3 cargo trains shuttle between the 4 groups of dead end tracks that resemble industry areas.  
Via the ‘allowed blocks’ tables we specify which trains are allowed to drive where.  
The trains table specifies the train names, their start/stop switches and their allowed blocks table.  
The routes table specifies every possible route from block A to block B and which turnuts to switch to get there.  
We also have a look at the section where the parameters can be set to change the amount of messages to show on the Lua screen, if the tooltips show or not, if the main switch is on or off and if all train switches are on or off at startup.

- [Automatic Train Traffic on any EEP Layout v2 - 06](https://www.youtube.com/watch?v=xxssAIgqxk0&ab_channel=Rudyshobbychannel)  
The Lua code to create automatic train traffic on your EEP layout can be generated with a code generator tool.
In demo 6 we see how we can use the Lua ATC Code Generator. Based on the EEP anl3 file the Lua code for automatic train traffic is automatically generated. Included are the routes, two-way-blocks and the trains tables. What we need to adjust ourselves is the allowed blocks tables and the trains table to put specific trains on specific allowed tables. If the layout requires we may also need to add an anti-deadlock table.

- [Automatic Train Traffic on any EEP Layout v2.2 - 07](https://www.youtube.com/watch?v=Jy6LAwftW9g&ab_channel=Rudyshobbychannel)  
Automatic Train Control on any EEP Layout with Lua - v2.2 - 7
EEP Lua ATC version 2.2 has been released. This video shows all the steps, from downloading up to having three trains driving around fully automatic.  
One of the new features in v2.2 is the way trains can be reversed. There’s no need for speed reverse sensors anymore, which also eliminates the need for careful sensor placement, and the always still visible speed reversal hiccup is history. Lua takes care of the reversal once a route has been given the additional specification reverse=true. This reversal method also makes it possible to reverse trains on a block that is not a dead end.

- [Automatic Train Traffic on any EEP Layout v2.2 - 08](https://www.youtube.com/watch?v=YdrGc5KIsmM&ab_channel=Rudyshobbychannel)  
Automatic Train Control version 2.2 has the feature of being able to reverse trains without using any track sensors, Lua takes care of the reversal. This makes it possible to reverse a train on any block, not only on dead ends. The block need not even be a two-way block, trains can reverse on any block.  
The Lua ATC Code Generator can not guess our intentions, it will always generate routes without reversals, and reverse trains only in dead ends. When we want a train to reverse on a non dead end block we’ll have to add the routes for this ourselves and specify reverse=true for those routes. If you leave both the forward and the reversal route in the table, the result will be that trains will drive on 50% of the time and reverse the other 50% of the times.

- [Automatic Train Traffic on any EEP Layout v2.3 - 09](https://www.youtube.com/watch?v=KGXL2a99CjM&ab_channel=Rudyshobbychannel)  
This version is all about making things even easier:  
  - There’s the new EEP installer that with two mouse clicks installs the content of the ZIP file.  
  - The BetterContacts module is included, courtesy of Benjamin Hogl.  
  - There’s a new User Manual that talks us through each and every step from installing the oftware up to driving around automatically.  
  - The manual now focuses on using the Lua Code Generator, which takes most work out of ur hands.  
  - A new demo layout, Peace River, is included.  

- [Automatic Train Traffic on any EEP Layout v2.3 - 10](https://www.youtube.com/watch?v=ISWab3A1tbI&ab_channel=Rudyshobbychannel)  
This video shows how demo layout Peace River was automated.

- [Automatic Train Traffic on any EEP Layout v2.3 - 11](https://www.youtube.com/watch?v=nq5rGOXgdRQ&ab_channel=Rudyshobbychannel)  
This video shows how demo layout Swyncombe was automated and describes new features of version 2.3.2:  
  - Efficient ways to define allowed blocks  
  - Random wait times, between a min and max value, per train per block  
  - Info on missing trains during train find mode  

## Collaboration

Any questions, comments and ideas are welcome. You can use one of these channels:

- GitHub [issues](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/issues) or [discussions](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/discussions)
- EEP Forum thread in [English](https://www.eepforum.de/forum/thread/36688-lua-automatic-train-control-for-any-layout-version-2/) or [German](https://www.eepforum.de/forum/thread/36689-lua-automatische-zugsteuerung-f%C3%BCr-jedes-layout-version-2/)
- EEP Forum [conversations](https://www.eepforum.de/conversation-add)  with both `RudyB` and `frank.buchholz`

In the meantime … have fun.  
Rudy and Frank
