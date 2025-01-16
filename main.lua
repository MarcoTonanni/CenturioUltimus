local map, screenWidth, screenHeight, cameraMaxX, cameraMaxY, cameraMinX, cameraMinY, gui, allRomansExhausted

-- Used to control Update Flux and animations
animationOn = false
local allEnemiesExhausted = true
dtotal = 0

-- Used for when the game ends
local gameEndCounter = 0

-- A list with all units and dead icons
units = {}
local dead = {}


function love.load()
    -- Calling the libraries used and the classes files
    Object = require "classic"
    local camera = require "hump_camera"
    local sti = require "sti"
    local Unit = require "unit"
    local Enemy = require "enemy"

    -- So not to distort tiles when expanding images
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- The fonts for the game
    font1 = love.graphics.newFont("/Art_Assets/Fonts/prstart.ttf", 15)
    font2 = love.graphics.newFont("/Art_Assets/Fonts/Darinia/Darinia.ttf", 20)
    love.graphics.setFont(font2)

    -- Sets the mouse to visible
    love.mouse.isVisible()

    -- Puts the main song to play and loads SFXs
    backgroundMusic = love.audio.newSource("/Art_Assets/Sound/POL-the-hordes-advance-short.wav", 'stream')
    backgroundMusic:setLooping(true)
    backgroundMusic:setVolume(0.3)
    backgroundMusic:play()
    atkSFX = love.audio.newSource("Art_Assets/Sound/atk_short.wav", 'static')
    arrowSFX = love.audio.newSource("Art_Assets/Sound/arrow_attack.wav", 'static')
    deathSFX = love.audio.newSource("Art_Assets/Sound/death_sfx.wav", 'static')
    atk_missSFX = love.audio.newSource("Art_Assets/Sound/atk_miss.wav", 'static')

    -- Loads the MainScreen and sets the variables for the game flow
    mainScreen = love.graphics.newImage("Art_Assets/Images/MainScreen.png")
    mainMenu = true
    storyScreen1 = love.graphics.newImage("Art_Assets/Images/Story_1.png")
    storyScreen2 = love.graphics.newImage("Art_Assets/Images/Story_2.png")
    storyScreen3 = love.graphics.newImage("Art_Assets/Images/Story_3.png")
    story1, story2, story3 = false
    tutorialScreen1 = love.graphics.newImage("Art_Assets/Images/Tutorial_1.png")
    tutorialScreen2 = love.graphics.newImage("Art_Assets/Images/Tutorial_2.png")
    tutorialScreen3 = love.graphics.newImage("Art_Assets/Images/Tutorial_3.png")
    tutorialScreen4 = love.graphics.newImage("Art_Assets/Images/Tutorial_4.png")
    tutorialScreen5 = love.graphics.newImage("Art_Assets/Images/Tutorial_5.png")
    tutorialScreen6 = love.graphics.newImage("Art_Assets/Images/Tutorial_6.png")
    tutorial1, tutorial2, tutorial3, tutorial4, tutorial5, tutorial6 = false
    gameOn = false
    creditsScreen = love.graphics.newImage("Art_Assets/Images/Credits.png")
    credits = false

    -- Loads all information from the map made with Tiled
    mapInfo = require "Map1"
    tileSize = mapInfo["tilewidth"] -- In Pixels
    mapWidth = mapInfo["width"] * tileSize -- In Pixels, not tiles
    mapHeight = mapInfo["height"] * tileSize -- In Pixels, not tiles

    -- An array of 20(y) arrays of 30(x) mapping the unpassable tiles in the map
    obstacles = {
        {0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0},
        {1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0},
        {1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0},
        {1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0},
        {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1},
        {0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
        {0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    }

    -- Loads the map itself using STI
    map = sti("Map1.lua")

    -- Loads the GUI for the game screen
    gui = love.graphics.newImage("/Art_Assets/UI/GUI_V4.png")

    -- Used in love.drawing and other functions, so everything falls in place
    TranslateX = 68
    TranslateY = 64

    -- Creates all the Roman Heroes and enemies, and populates the units list with them
    createRomanHeroes(units)
    cycle = 1 -- Value always used for the centurion main-character
    unitSelected = units[cycle] -- By defaul the initial selectedUnit
    createInitialEnemies(units)

    -- Icon that shows which is the selected unit, to help the player locate himself
    selectedIcon = love.graphics.newImage("Art_Assets/Icons/Misc/Laurels_small.png")


    -- Sets the game camera
    cam = camera(unitSelected.x * tileSize, unitSelected.y * tileSize)
    zoom = 1.3  -- For the camera and other calculations
    cam:zoom(zoom)
    cam.smoother = camera.smooth.linear(100)
    -- Used to keep the camera inside the appropriate area
    screenWidth, screenHeight = love.graphics.getDimensions()
    cameraMinX = screenWidth / 2 / zoom
    cameraMinY = screenHeight / 2 / zoom
    cameraMaxX = 32 + 957 / zoom
    cameraMaxY = mapHeight - (screenHeight / 2 / zoom) + (TranslateY / zoom)

    turn = 1  -- For keeping track of turns
    allRomansDead = false  -- To help with the end-game flow
    healthBarOn = true
    targeting = false  -- For tracking Target Mode
    playerSelectMovement = false  -- For tracking a unit's movement selection
    printingInformation = false  -- For controlling information print over the scroll
    kills = 0  -- For the kill counter
end

function love.update(dt)

    -- When the actual gameplay is running
    if gameOn and not allRomansDead then
        -- Used to control the flow of things
        dtotal = dtotal + dt

        -- Activates the enemy units after the Roman Units have no more AP  
        allRomansExhausted = true
        for _, unit in ipairs(units) do
            if unit.roman and unit.ap > 0 then
                allRomansExhausted = false
                dtotal = 0
                break
            end
        end

        if allRomansExhausted and not animationOn then
            allEnemiesExhausted = true
            for _, unit in ipairs(units) do
                if not (unit.roman or unit.dead) and unit.ap > 0 and (dtotal >= 1) then
                    unitSelected = unit
                    unit:enemyBehaviour()
                    dtotal = 0
                    allEnemiesExhausted = false
                    break
                end
            end
        end

        -- Animates the units' movements and attacks
        if animationOn then
            unitSelected:updateMovement(dt)
            -- Checks if the animation is finished
            if unitSelected.x == unitSelected.moveGoal.x and unitSelected.y == unitSelected.moveGoal.y then
                animationOn = false
                unitSelected.moveGoal = {}
                unitSelected.moveQueue = {}  -- Erases the queue
                unitSelected.mp = 4  -- Guarantees the unit gets all its MP back
            end
        end

        -- Since the attackAnimation is really fast it doesn't need to be controlled by start.Animation
        -- It has an inbuilt dtotal=0 with conditions so that animations are properly activated before the AI goes
        unitSelected:attackAnimation(dt)

        -- Removes dead enemy units from the list, to improve performance
        for i=#units, 1, -1 do -- Do it from finish to start, to always pass through enemies first, since romans are not deleted
            if units[i].dead then 
                if not units[i].roman then
                    local corpse = {
                        x = units[i].x,
                        y = units[i].y,
                        image = love.graphics.newImage("Art_Assets/Units/Dead2.png")
                    }
                    table.insert(dead, corpse)
                    table.remove(units, i)
                    break
                -- Changes Roman's image to a dead one, but keeps them in the units list for their portraits
                else
                    units[i].image = love.graphics.newImage("Art_Assets/Units/Dead2.png")
                end
            end
        end

        -- Checks if all Romans are dead, which is used in order to end the game
        allRomansDead = true
        for i=1, 6 do
            if units[i].dead == false then
                allRomansDead = false
                break
            end
        end

        -- Checks if all units have acted and a new turn should start
        if allRomansExhausted and allEnemiesExhausted and (dtotal > 1) and not animationOn then
            newTurn()
        end


        -- Sets the camera to look at the acting unit, inside the appropriate boundaries
        local targetX = math.max(cameraMinX, math.min(unitSelected.x * tileSize, cameraMaxX))
        local targetY = math.max(cameraMinY, math.min(unitSelected.y * tileSize, cameraMaxY))
        cam:lookAt(targetX, targetY)

        map:update(dt)

    -- Ends the game proper when all Romans have died, loading up the Credits screen
    elseif gameOn and allRomansDead then
        gameEndCounter = gameEndCounter + dt
        if gameEndCounter >= 7 then
            gameOn = false
            credits = true
        end
    end
end


function love.draw(dt)
    -- Draw pre-game screens
    if mainMenu then
        love.graphics.draw(mainScreen)
    elseif story1 then
        love.graphics.draw(storyScreen1)
    elseif story2 then
        love.graphics.draw(storyScreen2)
    elseif story3 then
        love.graphics.draw(storyScreen3)
    elseif tutorial1 then
        love.graphics.draw(tutorialScreen1)
    elseif tutorial2 then
        love.graphics.draw(tutorialScreen2)
    elseif tutorial3 then
        love.graphics.draw(tutorialScreen3)
    elseif tutorial4 then
        love.graphics.draw(tutorialScreen4)
    elseif tutorial5 then
        love.graphics.draw(tutorialScreen5)
    elseif tutorial6 then
        love.graphics.draw(tutorialScreen6)
    elseif credits then
        love.graphics.draw(creditsScreen)
    end

    -- Draws everything when in gameplay stage
    if gameOn then

        if allRomansDead then
            love.graphics.setColor(0.6, 0.4, 0.4, 1)
        end

        -- Draws the UI and portraits
        love.graphics.draw(units[1].portrait, 988, 47) -- Portrait 1
        love.graphics.draw(units[2].portrait, 1136, 46)  -- Portrait 2
        love.graphics.draw(units[3].portrait, 988, 228)  -- Portrait 3
        love.graphics.draw(units[4].portrait, 1136, 227)  -- Portrait 4
        love.graphics.draw(units[5].portrait, 988, 405)  -- Portrait 5
        love.graphics.draw(units[6].portrait, 1136, 404)  -- Portrait 6
        love.graphics.draw(gui)

        love.graphics.push()  -- Saves the current, blank, coordinates
        love.graphics.translate(TranslateX, TranslateY)  -- Transforms all further coordinates after it

        cam:attach()
            love.graphics.setScissor(TranslateX, TranslateY, (957 - TranslateX), (724 - TranslateY))
            map:drawTileLayer("Background")
            map:drawTileLayer("Decorations")

            -- First draw the enemy corpses, then draw the units themselves, lastly draw Roman soldiers dead
            for _,corpse in ipairs(dead) do
                love.graphics.draw(corpse.image, corpse.x * tileSize, corpse.y * tileSize)
            end
            for _,unit in ipairs(units) do  -- Could be eventually optimized
                if unit.dead then
                    unit:draw()
                end
            end
            for _,unit in ipairs(units) do
                if not unit.dead then
                    unit:draw()
                end
            end

            -- Shows which unit is selected
            if unitSelected.roman then
                love.graphics.draw(selectedIcon, unitSelected.x * tileSize + 6, unitSelected.y * tileSize + 20)
            end

            -- Draw the obstacles last, so that units appear under trees when appropriate
            map:drawTileLayer("Obstacles")

            -- Draw healthbars if they are to be shown
            if healthBarOn then
                for _,unit in ipairs(units) do
                    unit:drawHealthBar()
                end
            end

            -- Draws the selected Roman unit's AP
            if unitSelected.roman then
                unitSelected:drawAP()
            end

            -- When moving show the squares the unit can move to, but not if it's in mid of an animation
            if playerSelectMovement and not unitSelected.isMoving or unitSelected.roman then
                unitSelected:selectMove()
            end

            love.graphics.setScissor()

            -- After scissors so to be able to show information over the Scroll
            printingInformation = false

            -- When attacking show the squares the unit can target
            if not printingInformation then
                if targeting and unitSelected.ap > 0 and unitSelected.roman then
                    printingInformation = true
                    unitSelected:selectTarget()
                end
            end

            -- Draw Unit information if they are to be shown
            if not printingInformation then
                printingInformation = true
                for _,unit in ipairs(units) do
                    unit:drawInformation()
                end
            end
            printingInformation = false

        cam:detach()
        love.graphics.pop()  -- Reverts to the coordinates saved in the push


        -- Draws a rustic Turn-Counter overlay and a Kill-Counter if the game is still on, or tell the player his results
        if not allRomansDead then
            love.graphics.setColor(0.75, 0.55, 0.3, 0.9)
            love.graphics.rectangle('fill', TranslateX + 10, TranslateY + 10, 117, 29)
            love.graphics.setColor(0.1, 0.1, 0.1, 1)
            love.graphics.rectangle('line', TranslateX + 9, TranslateY + 9, 118, 30)
            love.graphics.rectangle('line', TranslateX + 8, TranslateY + 10, 119, 31)
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.print("Turn: " .. turn, TranslateX + 15, TranslateY + 15)
            love.graphics.setColor(1,1,1,1)

            love.graphics.setColor(0.75, 0.55, 0.3, 0.9)
            love.graphics.rectangle('fill', TranslateX + 10, TranslateY + 41, 117, 29)
            love.graphics.setColor(0.1, 0.1, 0.1, 1)
            love.graphics.rectangle('line', TranslateX + 9, TranslateY + 40, 118, 30)
            love.graphics.rectangle('line', TranslateX + 8, TranslateY + 41, 119, 31)
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.print("Kills: " .. kills, TranslateX + 15, TranslateY + 46)
            love.graphics.setColor(1,1,1,1)
        else
            love.graphics.setColor(0.75, 0.55, 0.3, 0.9)
            love.graphics.rectangle('fill', TranslateX + 244, TranslateY + 255, 577, 39)
            love.graphics.setColor(0.1, 0.1, 0.1, 1)
            love.graphics.rectangle('line', TranslateX + 243, TranslateY + 254, 578, 40)
            love.graphics.rectangle('line', TranslateX + 242, TranslateY + 255, 579, 41)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(font1)
            love.graphics.print("    You have survived for " .. turn .. " turns\n  and killed "
                                .. kills .. " barbarians for Rome.", TranslateX + 249, TranslateY + 260)
            love.graphics.setColor(1,1,1,1)
            love.graphics.setFont(font2)
        end
    end
end

function love.keypressed(key)
    -- Controls the pre-game flow
    if mainMenu or story1 or story2 or story3 or tutorial1 or tutorial2 or tutorial3 or tutorial4 or tutorial5 or tutorial6
         or credits or (gameOn and allRomansDead) then
        if key == 'space' then
            changeGameStage()
        end
    end

    -- Controls for when gameplay is on
    if gameOn then
        -- Enters Attack Mode
        if key == '1' and not (targeting or playerSelectMovement or animationOn) and (unitSelected.ap > 0) then
            targeting = true
        elseif key == '1' and targeting then
            targeting = false
        end

        -- Enters Movement Mode
        if key == '2' and not (targeting or playerSelectMovement or animationOn) and (unitSelected.ap > 0) then
            playerSelectMovement = true
        elseif key == '2' and playerSelectMovement then -- Stops moving midway
            playerSelectMovement = false
        end

        -- Controls if the Health Bars should or should not be shown
        if key == 'lshift' and not healthBarOn then
            healthBarOn = true
        elseif key == 'lshift' and healthBarOn then
            healthBarOn = false
        end

        -- Cycling through roman units
        if not (playerSelectMovement or targeting or unitSelected.isAttacking or animationOn or allRomansExhausted) then
           -- Selects other unit
            if key == 'tab' then
                cycleUnit()
            elseif key == 'return' then
                unitSelected:skipTurn()
            end
        end

        -- Used while testing, not for the final version but kept as annotation anyway
        -- if key == '3' then
           -- unitSelected.hp_current = 1
        -- end
        -- if key == 'f10' then
           -- love.event.quit('restart')
        -- end
    end
end

-- Used by the move function, made with help from ChatGPT
function isTilePassable(x, y)
    if x < 0 or y < 0 or x >= mapInfo["width"] or y >= mapInfo["height"] then
        return false -- Out of the map
    end
    if obstacles[y+1] and obstacles[y+1][x+1] then
        -- Check for obstacles with +1 because Lua counts from 1 instead of 0
        if obstacles[y+1][x+1] ~= 0 then
            return false  -- Tile is blocked
        end


        -- Check if the area is occupied by a live unit
        if isOccupied(x, y) then
            return false
        end
        return true  -- Not blocked
    end
end

function isOccupied(x, y)
    -- Check if the area is occupied by a live unit
    for _,unit in ipairs(units) do
        if x == unit.x and y == unit.y and not unit.dead then
            return true
        end
    end
    return false
end

-- Used to refresh all live units Action Points and Movement Points
function newTurn()
    for i=1, #units do
        if not units[i].dead then
            units[i].ap = 2
            units[i].mp = 4
            units[i].moveQueue = {}
            -- When unit gets to 30 morale and is damaged it heals for 50% of damage and sets Morale to its initial value
            if units[i].morale_current >= 30 and units[i].hp_current < units[i].hp then
                units[i].morale_current = units[i].morale
                units[i].hp_current = math.floor((units[i].hp - units[i].hp_current) / 2) + units[i].hp_current
            end
        end
    end

    -- Starts with the first live Roman selected and checks all initial 6 of them
    local turnStartRomanSelected = false
    for i=1, 6 do
        if units[i].roman and not units[i].dead then
            cycle = i
            turnStartRomanSelected = true
            break
        end
    end
    if not turnStartRomanSelected then
        cycle = 1  -- Looks at the Centurions corpse, just to guarantee no unexpected behaviour    
    end

    unitSelected = units[cycle]
    moving = false
    targeting = false
    turn = turn + 1
    allEnemiesExhausted = false
    local x = 1
    if turn > 25 then
        x = 4
    elseif turn > 14 then
        x = 3
    elseif turn > 5 then
        x = 2
    end

    -- Creates new enemies, if the total of enemies is no more than 10 at a single moment, this helps guarantee performance
    if #units < 16 then
        createNewEnemies(x, units)
    end
end

-- Cycle through units
function cycleUnit()
    if cycle < #units then
        cycle = cycle + 1
        -- Skips enemies and dead units
        while (not units[cycle].roman) or units[cycle].dead or units[cycle].ap == 0 do
            if cycle < #units then
                cycle = cycle + 1
            else
                cycle = 1
            end
        end
    else
        cycle = 1
    end
    if units[cycle].ap > 0 then
        unitSelected = units[cycle]
    end
end

-- Calculates the Manhattan Distance between two tiles
function manhattanDistance(x1, y1, x2, y2)
    return math.abs(x1 - x2) + math.abs(y1 - y2)
end

-- Used to calculate the best path towards the goal tile, the least the better
function moveHeuristic(x1, y1, goalX, goalY)
    local cost = manhattanDistance(x1, y1, goalX, goalY)

    -- Checks neighbors
    local neighbors = {
        {dx = x1+1, dy = y1},  -- Right
        {dx = x1-1, dy = y1},  -- Left
        {dx = x1, dy = y1+1},  -- Down
        {dx = x1, dy = y1-1}   -- Up
    }
    local count = 0

    for _, n in ipairs(neighbors) do
        if not isTilePassable(n.dx, n.dy) then
            count = count + 1
        end
    end

    -- Improve this part of the algorithm with a unitAdjacent function, so to not be such a drastic cost
    if count >= 3 then
        cost = cost + 5
    end
    return cost
end

-- Used to sort a list based on movement cost
function sortingByMoveCost(element1, element2)
    return element1.moveCost < element2.moveCost
end

-- Used to controll the flow of the game stage
function changeGameStage()
    if mainMenu then
        mainMenu = false
        story1 = true
        return
    elseif story1 then
        story1 = false
        story2 = true
        return
    elseif story2 then
        story2 = false
        story3 = true
        return
    elseif story3 then
        story3 = false
        tutorial1 = true
        return
    elseif tutorial1 then
        tutorial1 = false
        tutorial2 = true
        return
    elseif tutorial2 then
        tutorial2 = false
        tutorial3 = true
        return
    elseif tutorial3 then
        tutorial3 = false
        tutorial4 = true
        return
    elseif tutorial4 then
        tutorial4 = false
        tutorial5 = true
        return
    elseif tutorial5 then
        tutorial5 = false
        tutorial6 = true
        return
    elseif tutorial6 then
        tutorial6 = false
        gameOn = true
        return
    elseif gameOn then
        gameOn = false
        credits = true
    elseif credits then
        love.event.quit()
    end
end
