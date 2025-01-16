# Centurio Ultimus

#### Download the game for free here: https://cappadociusbr.itch.io/centurio-ultimus

#### Video Demo:  https://youtu.be/PZMKgT5uYhw
## Concept:
Centurio Ultimus ("The Last Centurion", translated to English from Latin) is a small game created with LÖVE2D, a framework for the Lua language. The game was created in order to be presented as the final project for Harvard's CS50: Introduction to Computer Science, taken online during the second half of 2024.

The project took around one and a half month to get to the current state, the first three weeks or so of which had full-time dedication from the developer, while the rest of the time it was done more sporadically, not every day, slowing down considerably. Part of this time was dedicated to art aspects, be creating, post-editing or searching for them.

The game's inspired by a real battle in Ancient Roman history, briefly explained in-game, and by miniature wargames and the tactics genre of video games. Before any coding was started, some design docs were written with the basic idea and structure intended for the game, but as the original scope was broader than what time, and the developer's experience, would allow for the project, it ended up being simplified and taking the current form. We could say this is a MVP of the game, from which it could be expandend and refined.

In short, Centurio Ultimus is a tactics survival game where the player is doomed to fall before the endless onslaught of their enemies, the question is: how long will you survive? How many enemies of Rome will you take with you?

## Files:
In this part of the README I'll map out, briefly, all the files that compose the whole that is Centurio Ultimus, mentioning what one can find inside each of them and what is their function.

### Project's Code

#### A preliminary note 

While reviewing the code in order to write this document some parts were identified which could be further improved. Due to time-constraints and the current stability of the game achieved this has not been done, for it would require further testing to guarantee no bug could surface from those alterations.

In a different note, it's worth mentioning that the game uses a custom set of coordinates for **x** and **y** based in the game map, which is divided in squares. This ends up abstracting the pixels actually involved, most of the time.

#### *conf.lua*
This is a small file that contains some basic parameters to configurate the game, such as the window size and the name and icon showed in it.

#### *main.lua*
The core of our game, running over 600 lines of code and annotations.

This file is divided, as with almost any project for LÖVE2D, in three main functions: love.load, love.update and love.draw. Besides those, it has a host of smaller auxiliary functions, using either in itself or in other files, such as unit.lua and enemy.lua. 

**love.load** is where we load and prepare almost all the libraries, variables and objects (such as images, music, sound effects, the map itself, the ) we'll be using to make our game run. We could say it sets the field for what's to come. 

**love.update** is the main responsible for updating our game, checking what's happening, make sure animations happen, units fight, the game passes from one state to another, everything in the right order, without overlapping, crashing or entering loops. It's deeply interrelated with all other parts of the code, not only in main, but in the other files as well.

**love.draw** is the part of the code that actually make things happen in the screen, so that the player can see them. Depending on which stage of the game we are in (main menu screen, story sequence, tutoria sequence, game proper, credits) it will draw different objects.

Then we have our auxiliary functions. 

**love.keypressed** is used to allow the player to interact with the game, be it passing from one game state to another, controlling and selecting units

**isTilePassable** checks if a tile is free so that a unit can occupy it.

Similarly, **isOccupied** checks if a unit is in a given tile.

**newTurn** is used to pass from one game turn to another, reseting appropriate variables so that units can act once more, setting the camera in a live Roman, healing units when appropriate and creating new enemies.

**cycleUnit** lets the player cycle through his different units.

**manhattanDistance** calculates the said distance between two sets of coordinates. This is used for some unit checks and the enemy's AI.

**moveHeuristics** another function used for the enemy's AI, it is very, very simple considering what it could be, but, nonetheless, helps the AI make decisions regarding it's movement path. This and other functions only used by the enemy's AI could have been put in the appropriate enemy.lua file, but since the initial concept of the game contemplated an AI for allied units as well, they were kept in main.

**sortingByMoveCost** is a function to give Lua arrays a specific sorting method, in this case based in Movement Cost. This is also for the enemy's AI.

**changeGameState** a simple function used to pass from one stage of the game to another, and for exiting the game from the Credits screen.

#### *unit.lua*
This file is for the unit superclass, the one used for all characters in the game, both enemies and allies. It contains functions and methods that control how units move, attack one another, their animations, etc. Thus, it ended up being the longest of all archives of the game, with a bit more than 700 lines.

**:new** is the default builder for units, with all their necessary variables, such as their game characteristics (Atack, Defense, Health, etc.) and others used in different functions.

**:draw** and **:drawAP** are two simple functions that call for the unit and some icons representing their Action Points (AP) to be drawed, they are used in main's love.draw, making it cleaner.

**:drawHealthBar** and **showHealthBar** are intrinsically related. The first is used in love.draw, again making it cleaner. Together, they make so that unit's show a health bar above themselves representing how much HP they have left.

**:drawInformation** is also used in love.draw to print information for the player regarding units in the game, showing their characteristics.

**:attack** is a large function that controls all the attack interations between two units (an attacker and a target). In just a few words, it makes rolls for attacks and for damage, calling the appropriate sound effects and changing the appropriate variables in the units themselves. It also contains variables used for animation and to help control the game flow in main.

**:attackAnimation** the actual function used to animate attacks, so that the player can see them. It basically moves the unit incrementally towards it's target, a certain distance, and then snaps back to its original position. It also has variables used to help control the game flow, so that things happen in order and don't overlap.

**:updateMovement** similarly to :attackAnimation, this function animates unit's movement, taking them from the a initial square to a final square. In order to do so, it works alongside **:queuPathTo**, which is a relatively simple path-finding algorithm, made with the help of ChatGPT (specially for debugging), as this was my first function of this type. Basically what this second functions does is give an array representing a path linking adjacent squares, through which the unit will pass.

**:selectTarget** and **:selectMove** are functions used in main and that allow the player to select enemy targets to attack or to move in the map. They make it visible by drawing colored square for the player to select with the mouse. In the case of :selectTarget, it also permits the player to glimpse information about it's chances when attacking enemies, getting to know their unit's hit chance and possible damage inflicted. :selectMove actually uses another path-finding algorithm that, together with main's isTilePassable, actually only prints the tiles to where the unit could get with one action from where it is. This time the algorithm was made entirely without the help from AI, although looking upon what I made in :queuPathTo. 

**:attackHeuristics** a simple attack heuristics used by the AI to select a target when more than one are available.

**:skipTurn** sets a units movement points and action points to 0, so that it won't act this turn.

Both **:isObstructed** and **:isUntargetable** serve as auxiliary functions for the enemy's AI. The first sees if a certain place in the map is reacheable by a specific unit, while the second sees if a certain target unit is theoretically attackable by the acting unit, not checking for range or if the unit can actually get to where it needs to but simply looking available attack positions from where to attack (further cogitations are made in the proper enemy functions that calls on those). 

**createRomanHeroes** a shortcut function to make main cleaner. It basically creates the six roman character of the game, with their appropriate stats, images and map positions.


#### *enemy.lua*
This file creates the enemy subclass, where we'll see all the functions and methods specific to the enemy units, including the main part of what makes it's AI tick. This is the smallest of the code files of the project, with 440 lines, but the most complex one. At the start of the file you'll find links for the main material read in order to build the AI. Other bibliography was read in the course of the research, but ended up not being useful for one reason or another, so it doesn't appear here. 

**:new** is the default builder of the subclass, building on top of Unit:new. It doesn't actually add anything new, just makes it so that the enemies will have access to the subclass methods and that they won't be identified as Romans.

**:enemyBehaviour** is the main algorithm controlling the AI's behaviour. It's order dictates the priorities for the enemies' behaviour, besides helping main.lua control and organize the game's action flow. In order to work, this method calls on many other functions from all the project's files, many of which built specifically for it and about which we'll talk in the following paragraphs. Put in short, the behaviour the enemies follow is this: attack if able, otherwise move to the nearest target it can attack. This script can run once or twice, depending on the enemies remaining Action Points; moving costs only one AP, attacking costs all of the unit's AP. Considering the above, an enemy unit can act in four different ways during it's game turn: attack; move and attack; move and move; stand still. The last behaviour will only kick in when it would be impossible for an enemy to get in a position from which it could attack a Roman, even if it could move infinitely without the game state changing (i.e., without units moving and things happening). For this project's scope, it was not considered necessary to improve upon this, as to make the enemy try to reach a better position, go to some goal-tile, etc.

**:nearestRoman** is a method that creates an ordered list of roman units, based on how close they are to the acting enemy. It uses Unit:isUntargetable so it will only grab valid targets and then sorts the list through main's sortingByMoveCost in order to achieve what it needs to. If no available targets it will return a nil value used by :enemyBehaviour to make the unit stand still. 

**:findMoveGoal** gets the list from :nearestRoman to find the actual tiles from which the enemy could attack their Roman enemies. It gives back another sorted list of attack positions, using the same criterion as above. If it gives back a list with no elements, :unitBehaviour will make the unit stand still.

**:queuePathStar** the most complex path-finding algorithm implemented in the project. A significant part of the second-half of the project's development was dedicated to improving and riding of bugs this method, together with :enemyBehaviour and all other auxiliary functions and methods. The current state of the algorithm is based in the A* paradigm, although, I believe, in a somewhat simplified form. I spent considerable time reading on the topic and "rubber ducking" about it in order to improve it. It will try to find the best path to the closest position from where to attack an enemy target (given to it by :findMoveGoal). This process will be repeated, due to :enemyBehaviour, until it finds a path or exhaust all positions given in the list made by the previous method. How the algorithm works is, basically, by searching a path that starts at the enemy unit's position and tries to get closer and closer to the goal position, by exploring adjacent positions and, thus, building a path. In order to try to optimize the algorithm, it gives each possible state (or position in a given path) a cost, built from two sources: the actual cost in movement points + a value given by the moveHeuristic function (from main.lua). Through the use of those, the algorithm ends up exploring less options (such as not repeating positions, always considering only the less-costly way to get to said position). It also does so in an order that helps make it quicker, as it prioritizes exploring what it deems to be the most promising paths, i.e. those that cost less first. Lastly, in case it finds a path towards the goal, it then builds a list retroactively and orders it so that it will give a list from the starting enemy position towards where it needs to get (to do so each state, a.k.a. position, has a variable containing it's parent state). In case it doens't find a path, it ends not returning any value.

**getInList** is a small auxiliary function built to allow :queuePathStar to make comparisons between similar states, in order to only keep the ones that cost less. It expands what one can do with arrays in Lua in a way custom built for what I needed, i.e. working with .x and .y values of items, used in the coordinates system.

**createBerserker**, **createBarbarianSpearman**, **createThane** and **createBarbarianArcher** are functions that create a archetypal enemy of the specified type. Although the function for Barbarian Archers exist, it is not used in the game, as it was deemed that Archers would make the game a lot harder for the player than needed. 

**createInitialEnemies** is like a sister function to unit.lua's createRomanHeroes, but for the enemies that find themselves in the game when it starts. It works by using the above mentioned functions for each of the enemy types, putting them in specified coordinates in the map.

**createNewEnemies** is used to create new enemies in specific places just beyond the border of the map, so that they will enter the map from those positions. It works by using a list of entryPoints and by randomly selecting from it everytime it creates a new unit, then checking if the place is already occupied before actually inserting the unit in the game (so that in a given turn two enemies can't spawn in the same position). It also decides the type of the enemy randomly, there's a 10% chance to create a Thane, 40% a Berserker and 50% a Spearman.

#### *Map1.lua*

This is an export from Tiled with all the information regarding the game's map. It's required by main.lua, which uses the sti library to effectively and efficiently work with it.

### Third-party Libraries

#### *classic.lua*
This is a third-party library that gives Lua the classes functionality that we see in other programming languages, such as Python.

Link: <https://github.com/rxi/classic>

#### *hump_camera.lua*
A third-party library that is actually just one in a set of tools created for LÖVE2D. It comes with many functionalities related to controlling the game's camera.

Link: <https://github.com/vrld/hump>

#### *sti*
This folder contains a third-party library used to facilitate working with maps created by the program Tiled in LÖVE2D.

Link: <https://github.com/karai17/Simple-Tiled-Implementation>

### Art_Assets
This is the root folder to organize all art assets used by the game. There's no need to go over everything in here, as it's all quite self-explanatory and easy to explore. 

As mentioned in the in-game credits screen, all assets used were either created by the game author (mostly with the help of different AI tools) or downloaded for free from different repositories of the internet, always with the author's consent for use and/or editing. 

### Special Thanks
To the lovely LÖVE2D Discord community, which helped me with doubts while familiarizing myself with the framework and the Lua language, besides sometimes offering sugestions regarding libraries that could be useful. They certainly have made the project move along faster, often pointing me good paths for my studies. Closely related to them, a big thanks to those responsible by LÖVE2D's superbly organized and clear [wiki](https://www.love2d.org/wiki/Main_Page), the main source of knowledge regarding the framework.

Thanks to Sheepolution for his [excelent tutorial](https://www.sheepolution.com/learn/book/contents) on LÖVE2D, which kickstarted my learning of the framework.

To my great and knowledgeable friend, Ignasi Andrés, author of one of the articles read to build my AI and who was always up to hearing my ideas and helping me clear some theoretical doubts. Your patience and disposition were deeply appreciated.

Lastly, to the late Colleen McCullough, the amazing author of the *Masters of Rome* series of historical novels. The Battle of Arausio, backdrop for the game, is narrated by her in the first book of the series, *The First Man in Rome*, a true masterpiece, and served as inspiration for this project.

