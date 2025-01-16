local Unit = Object:extend()

function Unit:new(atk, def, dmg_min, dmg_max, arm, dis, morale, hp, range)    
    -- Unit Stats: Attack, Defense, Damage, Armor, Discipline, Morale, Hit Points, Attack Range
    self.atk = atk
    self.def = def
    self.dmg_min = dmg_min
    self.dmg_max = dmg_max
    self.arm = arm
    self.dis = dis
    self.morale = morale
    self.hp = hp
    self.range = range or 1

    -- Fixed Initial Stats common to all units: Move, Action Points, Experience
    self.mp = 4 -- No need for a derived stat, since its regular value is always the same
    self.ap = 2 -- Same as above
    self.xp = 0    

    -- Derived values which are actually used in the functions
    self.atk_current = self.atk
    self.def_current = self.def
    self.morale_current = self.morale
    self.hp_current = self.hp

    -- Used in other functions to map the location of the unit and make it move
    self.x = 0
    self.y = 0

    -- Used to create the notion of teams and check if a unit is dead
    self.roman = true
    self.dead = false

    -- Used for the UI
    self.apIcon = love.graphics.newImage("Art_Assets/Icons/Misc/CoinSilver_.png")

    -- Used for animation
    self.current_frame = 1
    self.frame_timer = 0
    self.frame_duration = 0.1 -- Time per frame
    self.isAttacking = false
    self.isMoving = false
    self.moveQueue = {}  -- Used for animating movement iteratively
    self.moveGoal = {}  -- Used for controlling when an animation should end
    self.attack_frames = {1, 2, 3, 4, 5, 6, 7} -- Quads to use for the attack
end

-- Draws a unit in main's love.draw
function Unit:draw()
    love.graphics.draw(self.image, self.x * tileSize, self.y * tileSize)
end

-- Draw icons to represent the current unit's AP
function Unit:drawAP()
    cam:detach()
        for i=1, unitSelected.ap do
            love.graphics.draw(unitSelected.apIcon, 895 - TranslateX, 580 - TranslateY + i * 38)
        end
    cam:attach()
end

-- Used to show Health Bar's above units
function Unit:drawHealthBar()
    -- Mouse hover
    if not healthBarOn then
        local x, y = cam:worldCoords(love.mouse.getPosition())
        local tileX = math.floor(x / tileSize)
        local tileY = math.floor(y / tileSize)
        for i,unit in ipairs(units) do    
            if tileX == unit.x and tileY == unit.y and not unit.dead then
                showHealthBar(unit)
            end
        end

    -- LShift mode
    else
        for _,unit in ipairs(units) do
            if not unit.dead then
                if not (unit.x < 0 or unit.x > 29) and not (unit.y < 0 or unit.y > 19) then
                    showHealthBar(unit)
                end
            end
        end
    end
end

function showHealthBar(unit)
    if (unit.hp_current / unit.hp) >= 0.7 then
        love.graphics.setColor(0, 1, 0, 0.8)
    elseif (unit.hp_current / unit.hp) >= 0.35 then
        love.graphics.setColor(1, 1, 0, 0.8)
    else
        love.graphics.setColor(1, 0, 0, 0.8)
    end

    local barWidth = (unit.hp_current / unit.hp) * 15
    local barHeight = 2.5
    love.graphics.rectangle('fill', unit.x * tileSize + 8, unit.y * tileSize - 5, barWidth, barHeight)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('line', unit.x * tileSize + 8, unit.y * tileSize - 5, barWidth, barHeight)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Gives the player information over units in the UI
function Unit:drawInformation()
    local x, y = cam:worldCoords(love.mouse.getPosition())
    local tileX = math.floor((x - (TranslateX/zoom)) / tileSize)
    local tileY = math.floor((y - (TranslateY/zoom)) / tileSize)
    for _,unit in ipairs(units) do
        if tileX == unit.x and tileY == unit.y and not unit.dead then
                cam:detach()
                    love.graphics.setColor(0.05, 0, 0, 0.95)
                    love.graphics.printf(
                        "HP: " .. unit.hp_current .. "   MOR: " .. unit.morale_current ..
                        "\nATK: " .. unit.atk_current .. "   DEF: " .. unit.def_current ..
                        "\nDMG: " .. unit.dmg_min .. "-" .. unit.dmg_max .. "   ARM: " .. unit.arm,
                        990 - TranslateX, 645 - TranslateY, 275, 'center'
                        )
                    love.graphics.setColor(1, 1, 1, 1)
                cam:attach()
        end
    end
end

-- Controls the attack interaction between units
function Unit:attack(target)
    self.ap = 0 -- Attacking cost a unit all it's remaining AP

    -- Used for the animation and handled in the Unit:attackAnimation function
    self.initialX = self.x
    self.initialY = self.y
    self.initialDistanceToTarget = manhattanDistance(self.x, self.y, target.x, target.y)
    self.attackTarget = target
    self.isAttacking = true

    -- 30% Base Hit-chance for Bows, but with a penalty for the target's Defense
    -- 60% Base Hit-chance for Melee
    local hit_chance = 0
    if self.range >= 3 then
        hit_chance = 30 + (self.atk_current - math.ceil(target.def_current * 0.3))
        love.audio.play(arrowSFX)  -- Sound for shooting attack (Be it a hit or a miss)
    else
        hit_chance = 60 + (self.atk_current - (target.def_current))
    end

    -- Critical Hit calculation, minimum 5% in regular circumstances
    local criticalHit = false
    local criticalHitChance = 5 + math.floor((self.atk_current - target.def_current) / 10)
    if criticalHitChance < 5 then
        criticalHitChance = 5
    end

    -- Maximum and minimum hit-chance of 95% and 5%, respectively
    if hit_chance > 95 then
        hit_chance = 95
    elseif hit_chance < 5 then
        hit_chance = 5
        criticalHitChance = 0 -- No possibility to inflict extra damage in these conditions
    end

    -- Roll to hit
    local roll = love.math.random(100)
    if roll > hit_chance then -- Miss, otherwise it's a hit and the function goes on
        targeting = false
        if self.range < 3 then
            love.audio.play(atk_missSFX)  -- Sound for melee attack miss
        end
        return
    elseif roll < criticalHitChance then
        criticalHit = true
    end

    -- The target was hit, play the appropriate SFX
    if self.range < 3 then
        love.audio.play(atkSFX)  -- Sound for melee attack hit
    end

    -- Damage roll, Death check and Morale damage
    local damage = love.math.random(self.dmg_min, self.dmg_max) - target.arm

    -- A Critical Hit always inflicts at least 1 damage, if no damage was gonna be inflicted
    if criticalHit then
        if damage < 1 then
            damage = 1
        else
            damage = damage * 2
        end
    elseif damage < 1 then
        return  -- So as for units not to heal when damage is negative
    end

    target.hp_current = target.hp_current - damage

    -- Check if dead and then use it's variable somewhere else to remove it from play
    if target.hp_current <= 0 then
        target.dead = true
        love.audio.play(deathSFX)  -- Sound for when the target is killed
        if target.roman then
            target.portrait = love.graphics.newImage("/Art_Assets/Images/dead.png")  -- Changes the portrait to show he's dead

        else
            kills = kills + 1  -- Updates the kill counter for the player
        end

        self.morale_current = self.morale_current + 3 -- Gets 4 Morale for killing the target, countign the one from below

        -- Allies get extra morale and enemies lose morale
        for _, unit in ipairs(units) do
            if target.roman then
                if unit.roman then
                    unit.morale_current = unit.morale_current - 1
                else
                    unit.morale_current = unit.morale_current + 1
                end
            else
                if not unit.roman then
                    unit.morale_current = unit.morale_current - 1
                else
                    unit.morale_current = unit.morale_current + 1
                end
            end
        end


    else
        self.morale_current = self.morale_current + 1 -- Otherwise gets 1 Morale for damaging an enemy

        -- If alive and with morale left, the target might take morale damage
        if target.morale_current > 0 then
            -- Considered a Discipline roll, the fail difference is used for the damage
            morale_damage = (target.dis - damage * 3) - love.math.random(100)
            if (morale_damage < 0) then
                target.morale_current = target.morale_current + math.ceil(morale_damage * 0.05) -- math.ceil rounds the number
                -- Morale can't get negative
                if target.morale_current < 0 then
                    target.morale_current = 0
                end
            end
        end
    end

    targeting = false
end

-- Allows the player to select who to attack
function Unit:selectTarget(dt)
    -- Draw cells
    -- Horizontal
    for i=self.range, 0, -1 do -- Columns
        if i > 0 then
            love.graphics.setColor(0.45, 0, 0, 0.4)
            love.graphics.rectangle('fill', (self.x + i) * tileSize, (self.y) * tileSize, tileSize, tileSize)
            love.graphics.rectangle('fill', (self.x - i) * tileSize, (self.y) * tileSize, tileSize, tileSize)
            -- White outline
            for k=0, 1 do
                love.graphics.setColor(0, 0, 0, 0.5)
                love.graphics.rectangle('line', (self.x + i) * tileSize - k, self.y * tileSize - k, tileSize, tileSize)
                love.graphics.rectangle('line', (self.x - i) * tileSize - k, self.y * tileSize - k, tileSize, tileSize)
            end
        end

        -- Vertical and diagonal
        if i < self.range then
            for j=1, (self.range - i) do -- Lines
                love.graphics.setColor(0.45, 0, 0, 0.4)
                if i > 0 then
                    love.graphics.rectangle('fill', (self.x + i) * tileSize, (self.y + j) * tileSize, tileSize, tileSize)
                    love.graphics.rectangle('fill', (self.x + i) * tileSize, (self.y - j) * tileSize, tileSize, tileSize)
                    love.graphics.rectangle('fill', (self.x - i) * tileSize, (self.y + j) * tileSize, tileSize, tileSize)
                    love.graphics.rectangle('fill', (self.x - i) * tileSize, (self.y - j) * tileSize, tileSize, tileSize)
                    -- White outline
                    for k=0, 1 do
                        love.graphics.setColor(0, 0, 0, 0.5)
                        love.graphics.rectangle('line', (self.x + i) * tileSize - k, (self.y + j) * tileSize - k, tileSize, tileSize)
                        love.graphics.rectangle('line', (self.x + i) * tileSize - k, (self.y - j) * tileSize - k, tileSize, tileSize)
                        love.graphics.rectangle('line', (self.x - i) * tileSize - k, (self.y + j) * tileSize - k, tileSize, tileSize)
                        love.graphics.rectangle('line', (self.x - i) * tileSize - k, (self.y - j) * tileSize - k, tileSize, tileSize)
                    end
                -- This way it won't go two times when self.x + i and self.x - i would be the same
                else
                    love.graphics.rectangle('fill', (self.x) * tileSize, (self.y + j) * tileSize, tileSize, tileSize)
                    love.graphics.rectangle('fill', (self.x) * tileSize, (self.y - j) * tileSize, tileSize, tileSize)
                    -- White outline
                    for k=0, 1 do
                        love.graphics.setColor(0, 0, 0, 0.5)
                        love.graphics.rectangle('line', (self.x) * tileSize - k, (self.y + j) * tileSize - k, tileSize, tileSize)
                        love.graphics.rectangle('line', (self.x) * tileSize - k, (self.y - j) * tileSize - k, tileSize, tileSize)
                    end
                end                    
            end    
        end
    end

    -- Mouse position for hovering over information and selecting target
    local x, y = cam:worldCoords(love.mouse.getPosition())
    local tileX = math.floor((x - (TranslateX/zoom)) / tileSize)
    local tileY = math.floor((y - (TranslateY/zoom)) / tileSize)

    -- Mouse hover to give information about Hit-chance and Damage
    for i,unit in ipairs(units) do
        if tileX == unit.x and tileY == unit.y and not unit.dead  -- Checks if unit is alive and mouse over it
        and (manhattanDistance(self.x, self.y, unit.x, unit.y) <= self.range) then  -- Checks if in range of attack
            local hitChanceP, dmgMinP, dmgMaxP
            if (self.roman and not unit.roman)
            or (not self.roman and unit.roman) then
                -- Hit chance and Critical Hit chance
                if self.range <= 2 then
                    hitChanceP = self.atk_current - unit.def_current + 60
                else
                    hitChanceP = self.atk_current - unit.def_current + 30
                end
                if hitChanceP > 95 then
                    hitChanceP = 95
                elseif hitChanceP < 5 then
                    hitChanceP = 5
                end

                dmgMinP = self.dmg_min - unit.arm
                if dmgMinP < 0 then
                    dmgMinP = 0
                end
                dmgMaxP = self.dmg_max - unit.arm

                -- Printing over UI's scroll
                cam:detach()
                    printingInformation = true
                    love.graphics.setColor(0.05, 0, 0, 0.95)
                    love.graphics.printf(
                        "Hit Chance: " .. hitChanceP .. "%\nDamage: " .. dmgMinP .. "-" .. dmgMaxP,
                        990 - TranslateX, 655 - TranslateY, 275, 'center'
                        )
                    love.graphics.setColor(1, 1, 1, 1)
                    pritingInformation = false
                cam:attach()
            end
        end
    end

    -- Mouse input to select the enemy
    if love.mouse.isDown(1) then
        -- Loops through the list of all units in play
        for _, unit in ipairs(units) do
            if tileX == unit.x and tileY == unit.y and not unit.dead -- Target unit is alive
            and manhattanDistance(self.x, self.y, unit.x, unit.y) <= self.range then -- Target unit is in range
                if (self.roman and not unit.roman)
                or (not self.roman and unit.roman) then
                    self:attack(unit)
                    return true
                end
            end
        end
    end
end

-- Shows the squares the player can move to and allows him to choose where to move
-- Breadth-First Search (BFS) implementation
function Unit:selectMove(dt)
    -- Only execute if the unit is currently moving
    if not playerSelectMovement then return end

    -- Queue to process each tile within the movement range
    local queue = {}
    local visited = {}

    -- Initialize by pushing the unit's current position with full movement points
    table.insert(queue, {x = self.x, y = self.y, mp = self.mp})

    -- Add the starting position to visited
    visited[self.x .. "," .. self.y] = true

    -- BFS loop to go over all locations, one at a time, expanding from parent to child tiles
    while #queue > 0 do
        -- Take the first tile from the queue
        local current = table.remove(queue, 1)

        -- Set the color and draw the tile
        love.graphics.setColor(0, 0, 0.45, 0.4)
        if isTilePassable((current.x), (current.y)) then
            love.graphics.rectangle("fill", current.x * tileSize, current.y * tileSize, tileSize, tileSize)
        end
        -- Draw white outline
        for k=0, 1 do
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("line", current.x * tileSize - k, current.y * tileSize - k, tileSize, tileSize)
        end

        -- Explore the 4 possible adjacent tiles
        local directions = {
            {dx = 1, dy = 0},  -- Right
            {dx = -1, dy = 0}, -- Left
            {dx = 0, dy = 1},  -- Down
            {dx = 0, dy = -1}  -- Up
        }

        for _, dir in ipairs(directions) do
            local nx, ny = current.x + dir.dx, current.y + dir.dy
            local remaining_mp = current.mp - 1

            -- Skip if we've already visited this tile or if we don't have enough movement points of if the tile is not passable
            if remaining_mp >= 0 and not visited[nx .. "," .. ny] and isTilePassable(nx, ny) then
                -- Mark as visited
                visited[nx .. "," .. ny] = true
                -- Add the new position to the queue with the remaining movement points
                table.insert(queue, {x = nx, y = ny, mp = remaining_mp})
            end
        end
    end
    
    -- Mouse position for hovering over information and selecting target
    local x, y = cam:worldCoords(love.mouse.getPosition())
    local tileX = math.floor((x - (TranslateX/zoom)) / tileSize)
    local tileY = math.floor((y - (TranslateY/zoom)) / tileSize)

    -- Mouse input to select the tile
    if love.mouse.isDown(1) then
        if visited[tileX .. "," .. tileY] then
            self:queuPathTo(tileX, tileY)
            playerSelectMovement = false
        end
    end
end

-- Used for iterative movement animation, made with the help from ChatGPT
-- Uses self.moveQueue to create a path (BFS) used by the unit to execute moves
function Unit:queuPathTo(targetX, targetY)
    local queue = {}
    local visited = {}
    local cameFrom = {}

    -- Initialize the BFS queue
    table.insert(queue, {x = self.x, y = self.y, mp = self.mp})
    visited[self.x .. "," .. self.y] = true
    cameFrom[self.x .. "," .. self.y] = nil

    -- BFS to find the path
    local found = false
    while #queue > 0 do
        local current = table.remove(queue, 1)

        if current.x == targetX and current.y == targetY then
            found = true
            break
        end

        -- Explore adjacent tiles
        local directions = {
            {dx = 1, dy = 0},  -- Right
            {dx = -1, dy = 0}, -- Left
            {dx = 0, dy = 1},  -- Down
            {dx = 0, dy = -1}  -- Up
        }

        for _, dir in ipairs(directions) do
            local nx, ny = current.x + dir.dx, current.y + dir.dy
            local remaining_mp = current.mp - 1

            if remaining_mp >= 0 and not visited[nx .. "," .. ny] and isTilePassable(nx, ny) then
                visited[nx .. "," .. ny] = true
                cameFrom[nx .. "," .. ny] = {x = current.x, y = current.y} -- For each child marks its parent
                table.insert(queue, {x = nx, y = ny, mp = remaining_mp})
            end
        end
    end

    -- Backtrack to form the path if the target was found
    if found then
        local path = {}
        local step = {x = targetX, y = targetY}

        while step do
            table.insert(path, 1, step)  -- Insert at the start to reverse the order
            step = cameFrom[step.x .. "," .. step.y]
        end

        self.moveQueue = path
        self.moveGoal = {x = path[#path].x, y = path[#path].y}
        animationOn = true
        self.ap = self.ap - 1
    end
end

-- Function to update and animate movement (this is what actually moves the unit)
function Unit:updateMovement(dt)
    if #self.moveQueue > 0 then
        self.isMoving = true
        local nextStep = self.moveQueue[1]

        -- Convert target tile position to pixel coordinates, for smoother movement animation
        pixelX = self.x * tileSize
        pixelY = self.y * tileSize
        local targetX = nextStep.x * tileSize
        local targetY = nextStep.y * tileSize

        -- Calculate the distance to move in each frame
        local speed = 180 * dt
        local dx = (targetX - pixelX)
        local dy = (targetY - pixelY)

        -- Calculate the total distance to the target in pixels
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Check if the unit is close enough to snap to the target tile
        if distance < 3 then
            -- Snap to the exact tile position and remove this step
            self.x, self.y = nextStep.x, nextStep.y -- In tile coordinates
            table.remove(self.moveQueue, 1)
            self.mp = self.mp - 1
            -- If the unit has reached its destination or has run out of MPs, then update its AP and MP
            if #self.moveQueue == 0 or self.mp == 0 then
                self.isMoving = false
                self.mp = 4
                -- self.moveQueue = {}  -- Erases the queue
            end
        else
            -- Move incrementally towards the target tile
            self.x = self.x + ((dx / distance) * speed)/tileSize
            self.y = self.y + ((dy / distance) * speed)/tileSize
        end
    end
end

-- Function to animate attack
function Unit:attackAnimation(dt)
    if self.isAttacking and self.attackTarget then
        dtotal = 0  -- To help control the flow in love.update

        -- Convert position to pixel coordinates, for smoother animation
        targetX = self.attackTarget.x * tileSize
        targetY = self.attackTarget.y * tileSize
        pixelX = self.x * tileSize
        pixelY = self.y * tileSize

        -- Animation only for melee (Spears and other weapons)
        if self.range < 3 then
            -- Calculate the distance to move in each frame and the animation speed
            local speed = 75 * dt
            local dx = (targetX - pixelX)
            local dy = (targetY - pixelY)

            -- Calculate the total distance to the target in pixels
            local distance = math.sqrt(dx * dx + dy * dy)

            -- Check if the unit is close enough to have reached the target place, the idea is to move 3/4 of a tile towards the target
            if self.initialDistanceToTarget == 1 then
                distanceTarget = 8
            elseif self.attackTarget.x == self.initialX or self.attackTarget.y == self.initialY then -- Range 2 horizontal and vertical
                distanceTarget = 40
            else -- Range 2 diagonal
                distanceTarget = math.sqrt(8^2 + 8^2)
            end

            if distance > distanceTarget then
                -- Move incrementally towards the target tile
                self.x = self.x + ((dx / distance) * speed)/tileSize
                self.y = self.y + ((dy / distance) * speed)/tileSize
            else
                -- Stops the animation and gets back to where it all began
                self.x = self.initialX
                self.y = self.initialY
                self.isAttacking = false
                self.attackTarget = nil
                self.initialX = nil
                self.initialY = nil
                self.initialDistanceToTarget = nil
            end

        -- No animation for archers
        else
            self.x = self.initialX
            self.y = self.initialY
            self.isAttacking = false
            self.attackTarget = nil
        end
    end
end

-- Used to calculate the best target for attack when multiple choices available, the least the better
function Unit:attackHeuristic(target)
    -- Considers Atk vs Def, Enemy Health, Possible Max Damage
    return (target.def_current - self.atk_current) + (target.hp_current * 5) + ((target.arm - self.dmg_max) * 3)
end

function Unit:skipTurn()
    self.ap = 0
    self.mp = 0
end

-- Checks if target tile x, y is obstructed considering the starting position of the unit
function Unit:isObstructed(x1, y1)

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
        if n.dx == self.x and n.dy == self.y then  -- If the unit itself is neighboring then she can reach the target tile
            return false
        end
    end

    -- If no neighbor is passable then the tile is obstructed
    if count == 4 then
        return true
    end

    return false
end

-- Checks if a target is attackable by the unit
function Unit:isUntargetable(target)

    -- Archers, in practice, will always be able to find a spot from where to attack
    if self.range > 2 then
        return false
    end

    -- Checks neighbors
    local neighbors = {}
    for i = 1, self.range do
        table.insert(neighbors, {dx = target.x+i, dy = target.y})  -- Right
        table.insert(neighbors, {dx = target.x-i, dy = target.y})  -- Left
        table.insert(neighbors, {dx = target.x, dy = target.y+i})  -- Down
        table.insert(neighbors, {dx = target.x, dy = target.y-i})  -- Up
        if i == 2 then
            table.insert(neighbors, {dx = target.x+1, dy = target.y-1})  -- Upper right
            table.insert(neighbors, {dx = target.x-1, dy = target.y-1})  -- Upper left
            table.insert(neighbors, {dx = target.x+1, dy = target.y+1})  -- Down right
            table.insert(neighbors, {dx = target.x-1, dy = target.y+1})  -- Down left
        end
    end

    local count = 0

    for _, n in ipairs(neighbors) do
        if n.x == self.x and n.y == self.y then  -- If the unit itself is neighboring then she can reach the target tile
            return false
        end
        if not isTilePassable(n.dx, n.dy) then
            count = count + 1
        else
            return false
        end
    end

    -- If no neighbor is passable then the tile is obstructed
    if (self.range == 1 and count == 4) or (self.range == 2 and count == 12) then
        return true
    end

    return false
end

function createRomanHeroes(list)
    centurion = Unit(65, 60, 4, 9, 2, 85, 20, 16)
    centurion.x = 3
    centurion.y = 13
    centurion.image = love.graphics.newImage("Art_Assets/Units/RomanGeneral_2.png")
    centurion.portrait = love.graphics.newImage("/Art_Assets/Images/Centurio.png")
    table.insert(list, centurion)

    optio = Unit(50, 50, 4, 7, 2, 70, 18, 14)
    optio.x = 4
    optio.y = 15
    optio.image = love.graphics.newImage("Art_Assets/Units/CenturionSword_2.png")
    optio.portrait = love.graphics.newImage("/Art_Assets/Images/Roman4.png")
    table.insert(list, optio)

    roman_gladius = Unit(40, 30, 2, 7, 2, 55, 16, 12)
    roman_gladius.image = love.graphics.newImage("/Art_Assets/Units/RomanSword.png")
    roman_gladius.portrait = love.graphics.newImage("/Art_Assets/Images/Roman3.png")
    roman_gladius.x = 3
    roman_gladius.y = 7
    table.insert(list, roman_gladius)

    roman_spearman = Unit(35, 35, 2, 5, 2, 55, 16, 12, 2)
    roman_spearman.image = love.graphics.newImage("/Art_Assets/Units/RomanSpearman2.png")
    roman_spearman.portrait = love.graphics.newImage("/Art_Assets/Images/Roman1.png")
    roman_spearman.x = 10
    roman_spearman.y = 9
    table.insert(list, roman_spearman)

    roman_archer = Unit(45, 15, 2, 6, 1, 55, 15, 10, 6)
    roman_archer.image = love.graphics.newImage("/Art_Assets/Units/RomanBow.png")
    roman_archer.portrait = love.graphics.newImage("/Art_Assets/Images/RomanArcher.png")
    roman_archer.x = 2
    roman_archer.y = 9
    table.insert(list, roman_archer)

    auxilia_spearman = Unit(40, 30, 2, 6, 1, 40, 15, 13, 2)
    auxilia_spearman.image = love.graphics.newImage("/Art_Assets/Units/AuxiliaSpear2.png")
    auxilia_spearman.portrait = love.graphics.newImage("/Art_Assets/Images/Roman2.png")
    auxilia_spearman.x = 9
    auxilia_spearman.y = 14
    table.insert(list, auxilia_spearman)
end

return Unit