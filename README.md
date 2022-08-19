# EEP-Lua-Automatic-Train-Control

## The story of this project

November 2021 I moved to a new house. Besides the many pluses the new home offers there’s one little issue: there’s no room for my model railway anymore. EEP came to the rescue … I can still design and ‘build’ model railways and on my 4k screen they are fun to tinker with.

My old model railway was computer controlled with a program called Traincontroller. It allows for automatic train traffic whereby it takes care of switching turnouts and signals and accelerating and decelerating the trains.

It struck me that EEP has no automatic train control built in … or at least not in a way that is user friendly. There is however Lua, which allows us to write code to carry out these tasks. I wondered if it would be possible to write a Lua program that controls automatic train traffic in EEP, like Traincontroller does with a real model railway layout.

I set myself the following goals:

- Trains should automatically drive from block to block
- It should be possible to specify which trains are allowed in which blocks
- It should be possible to define stop times, per train per block
- It should be possible to start / stop individual trains
- It should work for any (model) railway layout without the need to (re)write Lua code
- The layout is defined solely by entering data on trains, signals, turnouts and routes

## NEWS February 2022

Frank Buchholz added several enhancements to the code, like:

- Automatic detection of placed trains
- Split the code into a user configuration file and a separate control file that doesn't require editing.
- Option to add 'destination blocks'via which Lua looks more than one block ahead to prevent possible opposing trains deadlock.

## NEWS April 2022

Publication of version 2.

I decided to keep the code of version 1 in its original, minimalist, state as well.

## Versions and other folders

This GitHub repository contains the result of this EEP Lua Automatic Traffic Control Project.

You find two versions of this project:

- Version 1 uses effective and minimalistic Lua code - less than 200 lines - to run a layout automatically. This is available for historical reasons.
- Version 2 uses enhanced modularized code with less configuration needed, more options, stronger robustness, consistency checks and extended logging.  
Go for this version!  
You can download the package here:
[`EEP_blockControl.zip`](https://github.com/FrankBuchholz/EEP-LUA-Automatic-Train-Control/releases/latest/download/EEP_blockControl.zip)

The "TC" folder contains the 5 layouts in Traincontroller, for those who might like to tinker with TC. Free demo version: <https://www.freiwald.com/pages/download.htm>

The "Images" folder contains screenshots of the 5 layouts in EEP, SCARM and Traincontroller.

The "SCARM" folder contains 2 SCARM files, one with layouts 1-4 (open menu View > Layers to switch layers) and one with layout 5, for those who might like to tinker with SCARM. Free demo version: <https://www.scarm.info/index.php>

Any questions, comments and ideas are welcome. In the meantime … have fun.
