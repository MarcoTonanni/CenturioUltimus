-- AI References:
    -- https://courses.cs.washington.edu/courses/cse326/03su/homework/hw3/bestfirstsearch.html
    -- https://medium.com/omarelgabrys-blog/path-finding-algorithms-f65a8902eb40
    -- http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
    -- https://medium.com/customertimes/artificial-intelligence-algorithms-and-kubernetes-4669b33ba054

-- Along the code you'll find some print statements as annotations, used in development for improving and debugging the AI

local Unit = require "unit"
local Enemy = Unit:extend()

function Enemy:new(atk, def, dmg_min, dmg_max, arm, dis, morale, hp, range)
    Enemy.super.new(self, atk, def, dmg_min, dmg_max, arm, dis, morale, hp)
    self.range = range or 1
    self.roman = false
end

-- Base function for determining the way the AI will act
function Enemy:enemyBehaviour()

    -- Used to select the best target (least health)
    local target = nil

    -- AI's Priority: Attacking
    for _, unit in ipairs(units) do
        -- Checks if enemy in range
        if unit.roman and (manhattanDistance(self.x, self.y, unit.x, unit.y) <= self.range) and not unit.dead
            and not (self.x < 0 or self.x > 29 or self.y < 0 or self.y > 19) then  -- So that Archers can't shoot from outside the map
            unit.attackCost = self:attackHeuristic(unit)  -- Calculates its heuristic, for if more than one unit in range

            -- If there's no prior target creates one, otherwise picks the best unit to attack
            if not target then
                target = unit
            elseif unit.attackCost <= target.attackCost then
                target = unit
            end
        end
    end

    -- If it can attack, then attacks and exits the function, as it has no more AP after the attack
    if target then
        -- print("Target = " .. target.x .. " " .. target.y)
        self:attack(target)
        return
    end

    -- Otherwise move once towards the neareast enemy and then call the function again
    local romans = self:nearestRoman()  -- Gets a list of the nearest Romans
    
    -- If all Romans are dead or unreachable
    if not romans then
        self.ap = 0  -- So not to enter an infinite loop
        return
    end

    local goals = {}
    local path = {}
    for _, roman in ipairs(romans) do  -- Iterates through all possible enemies
        -- print("Nearest Roman = " .. roman.x .. " " .. roman.y)
        goals = self:findMoveGoal(roman)  -- Gets a list of the nearest attack positions
        if #goals > 0 then
            for _, goal in ipairs(goals) do  -- Iterates through all possible attack positions for said enemy
                -- print("Goal = " .. goal.x .. " " .. goal.y)
                path = self:queuePathStar(goal.x, goal.y)
                if path then
                    -- for i=1, #path do
                       -- print("Path[" .. i .. "] = " .. path[i].x .. " " .. path[i].y)
                    -- end
                    break
                end
            end
            -- If we actually found a valid path then exit the loop
            if path then
                if #path > 0 then
                    break
                end
            end
        end
    end

    -- If it couldn't find any path, to any roman
    if not goals or not path or #path == 0 then
        self.ap = 0  -- So not to enter an infinite loop
        return
    end

    -- Limits the movement to the unit's MP, +1 because the first position is the unit's x and y
    local moveGoalFound = false
    for i=1, self.mp + 1 do
        if i == #path then
            self.moveGoal = {x = path[i].x, y = path[i].y}
            moveGoalFound = true
        end
    end
    if not moveGoalFound then
        self.moveGoal = {x = path[self.mp + 1].x, y = path[self.mp + 1].y}
    end

    -- print("self.moveGoal = " .. self.moveGoal.x .. " " .. self.moveGoal.y)
    self.ap = self.ap - 1
    self.moveQueue = path  -- This is what actually kicks-in the animation with Unit:updateMovement
    animationOn = true
end

-- Returns an ordered list of the nearest Romans to a unit, considering its attack range
function Enemy:nearestRoman()
    local romans = {}
    for _, unit in ipairs(units) do
        if unit.roman and not unit.dead and not self:isUntargetable(unit) then
            -- We use Roman so that we won't change the units themselves
            local roman = {
                x = unit.x, y = unit.y,
                moveCost = manhattanDistance(self.x, self.y, unit.x, unit.y),
                def_current = unit.def_current,
                hp_current = unit.hp_current,
                arm = unit.arm
                }
            table.insert(romans, roman)
        end
    end

    if #romans == 0 then
        return nil
    end

    if #romans > 1 then
        table.sort(romans, sortingByMoveCost)    
    end
    return romans
end

-- Returns an ordered list of tiles from where the unit can attack, not considering obstacles in the path, just the tiles
function Enemy:findMoveGoal(unit)

    -- Opens a list for all attack positions from the unit against its target
    attackPositions = {}

    -- Iterates over positions adding them to the list if passable, does so from end to start as we need the zero
    for i=self.range, 0, -1 do -- Iterates over Columns
        -- Horizontal attack positions
        if i > 0 then  -- We are not interested in the target's position itself
            local position1 = {x = unit.x + i, y = unit.y}
            if isTilePassable(position1.x, position1.y) and not self:isObstructed(position1.x, position1.y) then
                position1.moveCost = manhattanDistance(self.x, self.y, position1.x, position1.y)
                table.insert(attackPositions, position1)    
            end
            local position2 = {x = unit.x - i, y = unit.y}
            if isTilePassable(position2.x, position2.y) and not self:isObstructed(position2.x, position2.y) then
                position2.moveCost = manhattanDistance(self.x, self.y, position2.x, position2.y)
                table.insert(attackPositions, position2)
            end
        end

        -- Diagonals and vertical attack positions
        if i < self.range then
            for j=1, (self.range - i) do  -- Iterates over lines
                if i > 0 then
                    local position3 = {x = unit.x + i, y = unit.y + j}
                    if isTilePassable(position3.x, position3.y) and not self:isObstructed(position3.x, position3.y) then
                        position3.moveCost = manhattanDistance(self.x, self.y, position3.x, position3.y)
                        table.insert(attackPositions, position3)
                    end
                    local position4 = {x = unit.x - i, y = unit.y + j}
                    if isTilePassable(position4.x, position4.y) and not self:isObstructed(position4.x, position4.y) then
                        position4.moveCost = manhattanDistance(self.x, self.y, position4.x, position4.y)
                        table.insert(attackPositions, position4)
                    end
                    local position5 = {x = unit.x + i, y = unit.y - j}
                    if isTilePassable(position5.x, position5.y) and not self:isObstructed(position5.x, position5.y) then
                        position5.moveCost = manhattanDistance(self.x, self.y, position5.x, position5.y)
                        table.insert(attackPositions, position5)
                    end
                    local position6 = {x = unit.x - i, y = unit.y - j}
                    if isTilePassable(position6.x, position6.y) and not self:isObstructed(position6.x, position6.y) then
                        position6.moveCost = manhattanDistance(self.x, self.y, position6.x, position6.y)
                        table.insert(attackPositions, position6)
                    end
                else  -- So not to have duplicated positions when i == 0
                    local position7 = {x = unit.x, y = unit.y + j}
                    if isTilePassable(position7.x, position7.y) and not self:isObstructed(position7.x, position7.y) then
                        position7.moveCost = manhattanDistance(self.x, self.y, position7.x, position7.y)
                        table.insert(attackPositions, position7)
                    end
                    local position8 = {x = unit.x, y = unit.y - j}
                    if isTilePassable(position8.x, position8.y)and not self:isObstructed(position8.x, position8.y)  then
                        position8.moveCost = manhattanDistance(self.x, self.y, position8.x, position8.y)
                        table.insert(attackPositions, position8)
                    end
                end
            end
        end
    end

    -- Sorts the possible attackPositions in order to help the AI not get stuck in-game or in a loop then returns it
    if attackPositions then
        if #attackPositions > 1 then
            table.sort(attackPositions, sortingByMoveCost)
        end
        return attackPositions  -- If it couldn't find any suitable place, #attackPositions = 0
    end
end

-- Function to get an item that is a list inside another given list, used in queuePathStar
function getInList(list, item)
    for _, value in ipairs(list) do
        if value.x == item.x and value.y == item.y then
            return value
        end
    end
    return nil
end

-- Sort of an A* Search Algorith for AI's movement that creates a path list and uses it to feed unit.moveQueue, used in Unit:updateMovement
function Enemy:queuePathStar(goalX, goalY)
    -- Initializes the algorithm with lists to keep track of what to see and what has been seen and kept
    local openList = {}
    local closedList = {}
    local current_state = {}
    local goalFound = false

    -- Create the initial_state for the search algorithm, with its cost, and adds it to the openList
    local initial_state = {x = self.x, y = self.y, g_cost = 0}
    initial_state.h_cost = moveHeuristic(self.x, self.y, goalX, goalY)
    initial_state.cost = initial_state.g_cost + initial_state.h_cost
    table.insert(openList, initial_state)

    -- While openList is not empty
    while #openList > 0 do
        -- Pops the state with the least cost
        current_state = openList[1]  -- Initializes with the list's first state
        local lowest_index = 1
        if #openList > 1 then
            for i=2, #openList do
                if openList[i].cost < current_state.cost then
                    current_state = openList[i]
                    lowest_index = i
                end
            end
        end
        table.remove(openList, lowest_index)

        -- Checks if the goal was found
        if current_state.x == goalX and current_state.y == goalY then
            goalFound = true
            break
        end

        -- Generates successor states by checking each neighboring tile and exploring them
        local neighbors = {
            {dx = current_state.x+1, dy = current_state.y},  -- Right
            {dx = current_state.x-1, dy = current_state.y},  -- Left
            {dx = current_state.x, dy = current_state.y+1},  -- Down
            {dx = current_state.x, dy = current_state.y-1}   -- Up
        }

        for _,n in ipairs(neighbors) do
            if isTilePassable(n.dx, n.dy) then
                -- If an available tile, create a successor_state and calculates its cost, considering previous moves
                local successor_state = {x = n.dx, y = n.dy}
                local movement_cost = 1
                successor_state.g_cost = current_state.g_cost + movement_cost
                successor_state.h_cost = moveHeuristic(successor_state.x, successor_state.y, goalX, goalY)
                successor_state.cost = successor_state.g_cost + successor_state.h_cost

                -- Checks if there is a similar state (x and y) with a lower cost, if so does not add this one
                local found_open = getInList(openList, successor_state)
                local found_closed = getInList(closedList, successor_state)

                if found_open and found_open.cost <= successor_state.cost then
                elseif found_closed and found_closed.cost <= successor_state.cost then
                else
                    successor_state.parent = current_state
                    table.insert(openList, successor_state)
                end
            end
        end
        -- Ads the current_state to the closedList, after it has been fully explored
        table.insert(closedList, current_state)
    end

    -- Backtrack to create the right path
    if goalFound then
        local path = {}
        local step = current_state

        -- Inserts the step, always at the first position, as we'll go from end to start
        while step do
            table.insert(path, 1, {x = step.x, y = step.y})
            step = step.parent  -- Move to the parent
        end
        return path  -- Returns the path from Initial Tile to Goal
    end
end

-- Berserker builder
function createBerserker(x, y)
    barbarian_berserker = Enemy(60, 10, 1, 8, 0, 10, 20, 10)
    barbarian_berserker.image = love.graphics.newImage("/Art_Assets/Units/GermanBerserk2.png")
    barbarian_berserker.x = x
    barbarian_berserker.y = y
    return barbarian_berserker
end

-- Spearman builder
function createBarbarianSpearman(x, y)
    barbarian_spearman = Enemy(40, 20, 2, 5, 1, 20, 15, 8, 2)
    barbarian_spearman.image = love.graphics.newImage("/Art_Assets/Units/GermanSpear2.png")
    barbarian_spearman.x = x
    barbarian_spearman.y = y
    return barbarian_spearman
end

-- Thane builder
function createThane(x, y)
    thane = Enemy(50, 30, 2, 7, 2, 35, 12, 12)
    thane.image = love.graphics.newImage("/Art_Assets/Units/GermanThane.png")
    thane.x = x
    thane.y = y
    return thane
end

-- Archer builder
function createBarbarianArcher(x, y)
    barbarian_archer = Enemy(30, 10, 2, 5, 0, 25, 18, 6, 6)
    barbarian_archer.image = love.graphics.newImage("/Art_Assets/Units/GermanBow.png")
    barbarian_archer.x = x
    barbarian_archer.y = y
    return barbarian_archer
end

-- Initial enemies in the field, for main's love.load
function createInitialEnemies(list)
    barbarian_spearman1 = createBarbarianSpearman(6, 16)
    table.insert(units, barbarian_spearman1)

    barbarian_spearman2 = createBarbarianSpearman(16, 19)
    table.insert(units, barbarian_spearman2)

    barbarian_spearman3 = createBarbarianSpearman(15, 8)
    table.insert(units, barbarian_spearman3)

    barbarian_spearman4 = createBarbarianSpearman(11, 16)
    table.insert(units, barbarian_spearman4)

    barbarian_spearman5 = createBarbarianSpearman(22, 8)
    table.insert(units, barbarian_spearman5)

    barbarian_berserker1 = createBerserker(11, 18)
    table.insert(units, barbarian_berserker1)

    barbarian_berserker2 = createBerserker(2, 1)
    table.insert(units, barbarian_berserker2)

    barbarian_berserker3 = createBerserker(24, 9)
    table.insert(units, barbarian_berserker3)

    thane = createThane(29, 0)
    table.insert(units, thane)
end

-- Creates new enemies that will enter the field in the next turn
function createNewEnemies(x, list)
    -- A list of possible entry points
    local entryPoints = {
        -- North-West
        {x = -1, y = 0},
        {x = -1, y = 1},
        {x = -1, y = 2},
        {x = 0, y = -1},
        {x = 1, y = -1},
        {x = 2, y = -1},
        {x = 3, y = -1},
        {x = 4, y = -1},
        {x = 5, y = -1},
        {x = 6, y = -1},
        -- North-East
        {x = 29, y = -1},
        {x = 28, y = -1},
        {x = 27, y = -1},
        {x = 26, y = -1},
        {x = 25, y = -1},
        {x = 24, y = -1},
        {x = 23, y = -1},
        {x = 22, y = -1},
        {x = 21, y = -1},
        {x = 20, y = -1},
        {x = 19, y = -1},
        {x = 18, y = -1},
        {x = 17, y = -1},
        {x = 30, y = 0},
        {x = 30, y = 1},
        {x = 30, y = 2},
        {x = 30, y = 3},
        {x = 30, y = 4},
        {x = 30, y = 5},
        {x = 30, y = 6},
        {x = 30, y = 7},
        {x = 30, y = 8},
        {x = 30, y = 9},
        {x = 30, y = 10},
        -- South
        {x = 7, y = 20},
        {x = 8, y = 20},
        {x = 9, y = 20},
        {x = 10, y = 20},
        {x = 11, y = 20},
        {x = 12, y = 20},
        {x = 13, y = 20},
        {x = 14, y = 20},
        {x = 15, y = 20},
        {x = 16, y = 20}
    }

    -- Create X enemies at their first turn
    local count = 1
    while count <= x and #entryPoints > 0 do
        local num = love.math.random(1, #entryPoints)
        local n = table.remove(entryPoints, num)
        -- print("N.x = " .. n.x .. " N.y = " .. n.y)

        local roll = love.math.random(1,10)

        -- Create a random enemy, 10% for Thane, 40% for Berserker, 50% for Spearman
        if roll == 10 then
            unit = createThane(n.x, n.y)
        elseif roll >= 5 then
            unit = createBerserker(n.x, n.y)  
        else
            unit = createBarbarianSpearman(n.x, n.y)
        end

        -- Avoids the function bugging if enemies are blocking paths and units are getting stuck outside the map not moving
        if not isOccupied(unit.x, unit.y) then
            table.insert(list, unit)
            count = count + 1
        end
    end
end

return Enemy