pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--------------------------------------------------------------------------------
-- class: vector
--------------------------------------------------------------------------------
vector =
{
    type = "vector",
    __add = function(a, b)
                return vector:new(a.x + b.x,
                                  a.y + b.y)
            end,
    __sub = function(a, b)
                return vector:new(a.x - b.x,
                                  a.y - b.y)
            end,
    __mul = function(vector, number)
                return vector:new(vector.x * number, vector.y * number)
            end,
    __div = function(vector, number)
                return vector:new(vector.x/number, vector.y/number)
            end,
    __eq = function (a, b)
                return a.x == b.x and a.y == b.y
           end,
    distance = function(self, a, b)
                   local vect = a - b
                   return vect:magnitude()
               end,
    magnitude = function(self)
                    return sqrt(self.x^2 + self.y^2)
                end,
    normal = function(self)
                return vector:new(-1 * self.y, self.x)
             end,
    normalize = function(self)
                    local magnitude = self:magnitude()
                    return vector:new(self.x/magnitude, self.y/magnitude)
                end,
    tostring = function(self)
                    return "(" .. self.x .. ", " .. self.y .. ")"
               end,
    new = function(self, x, y)
              instance = {x = x, y = y}
              setmetatable(instance, self)
              self.__index = self

              return instance
          end
}

--------------------------------------------------------------------------------
-- class: tween
--------------------------------------------------------------------------------
tween =
{
    eases = { linear = function(self, t, b, c, d)
                             return c * t/d + b 
                         end,
              easeoutquad = function(self, t, b, c, d)
                                t /= d;
	                            return -c * t*(t-2) + b;
                            end,
              insine = function(self, t, b, c, d)
                          return -c * cos(t / d * 3.14159 / 2) + c + b
                      end,
              outback = function(self, t, b, c, d, s)
                            s = s or 2.5 -- 1.70158 -- original value
                            t = t / d - 1
                            return c * (t * t * ((s + 1) * t + s) + 1) + b
                        end,
              outbounce = function(self, t, b, c, d)
                              t = t / d
                              if t < 1 / 2.75 then
                                  return c * (7.5625 * t * t) + b
                              elseif t < 2 / 2.75 then
                                  t = t - (1.5 / 2.75)
                                  return c * (7.5625 * t * t + 0.75) + b
                              elseif t < 2.5 / 2.75 then
                                  t = t - (2.25 / 2.75)
                                  return c * (7.5625 * t * t + 0.9375) + b
                              else
                                  t = t - (2.625 / 2.75)
                                  return c * (7.5625 * t * t + 0.984375) + b
                              end
                          end
            },

    updatenumber = function(self)
                       local time = self:gettweentime()
                       local iscomplete = false
                       local value = self:ease(time, 
                                               self.startvalue, 
                                               self.changeinvalue, 
                                               self.duration)
                        if time >= self.duration then
                            value = self.endvalue
                            iscomplete = true
                        end

                        self.object[self.property] = value

                        if iscomplete then
                           del(tweens, self)

                           if self.oncomplete != nil then
                               self.oncomplete()
                           end

                           self.iscomplete = true
                        end
                   end,

    updatevector = function(self)
                       local time = self:gettweentime()
                       local iscomplete = false
                       local x = self:ease( time, 
                                            self.startvalue.x, 
                                            self.changeinvalue.x, 
                                            self.duration )
                       local y = self:ease( time, 
                                            self.startvalue.y, 
                                            self.changeinvalue.y, 
                                            self.duration )
                                            
                       if time >= self.duration then
                           x = self.endvalue.x
                           y = self.endvalue.y
                           iscomplete = true
                       end

                       self.object[self.property] = vector:new(x, y)

                       if iscomplete then
                           del(tweens, self)

                           if oncomplete != nil then
                               oncomplete()
                           end

                           self.iscomplete = true
                       end
                   end,

    new = function(self, object, property, startvalue, endvalue, duration, easename, oncomplete)
              instance = 
              { 
                  object = object, 
                  property = property,
                  startvalue = startvalue,
                  endvalue = endvalue, 
                  changeinvalue = endvalue - startvalue,
                  duration = duration,
                  ease = self.eases[easename],
                  iscomplete = false,
                  oncomplete = oncomplete,
                  update = nil,

                  starttime = time()
              }

              setmetatable(instance, self)
              self.__index = self

              if type(object[property]) == "number" then
                  instance.update = self.updatenumber
              elseif object[property].type == "vector" then
                  instance.update = self.updatevector
              else
                  instance.update = self.updatenumber
              end

              return instance
          end,

    gettweentime = function(self)
                       return time() - self.starttime
                   end,
}

--------------------------------------------------------------------------------
-- global variables 
--------------------------------------------------------------------------------
---------- state variables
titlestate = { init = function() inittitle() end, 
               update = function() updatetitle() end,
               draw = function() drawtitle() end }
gamestate = { init = function() initgame() end, 
              update = function() updategame() end,
              draw = function() drawgame() end }
gameoverstate = { init = function() initgameover() end, 
                  update = function() updategameover() end,
                  draw = function() drawgameover() end }
currentstate = titlestate

---------- game variables
normal = 0
hard = 1
insane = 2
gamemode = normal

timelimit = 60
scoretarget = 100
currentscore = 0
currenttime = timelimit

---------- input/system variables
left = 0
right = 1
up = 2
down = 3

z = 4
x = 5

max = 128

---------- dot variables
dotsize = 5.1 -- offset is because of weird circfill radius draw issues
dots = {}

removeddotsize = 3.5
addeddotsize = 10
squarepulsesize = 12

---------- board variables
gridcols = 6
gridrows = 6
gridsize = dotsize * 3.5

directions = {left, down, up, right}
fillindirection = down -- dots fill from this direction
fillvalues = 
{ 
    up = 
    {
        movevector = vector:new(0, -1),
        startvalue = vector:new(0, 0),
        checkvector = vector:new(0, 1),
        scanvector = vector:new(1, 0)
    },
    down =
    {
        movevector = vector:new(0, 1),
        startvalue = vector:new(0, gridrows-1),
        checkvector = vector:new(0, -1),
        scanvector = vector:new(1, 0)
    },
    left =
    {
        movevector = vector:new(-1, 0),
        startvalue = vector:new(0, 0),
        checkvector = vector:new(1, 0),
        scanvector = vector:new(0, 1)
    },
    right =
    {
        movevector = vector:new(1, 0),
        startvalue = vector:new(gridcols-1, 0),
        checkvector = vector:new(-1, 0),
        scanvector = vector:new(0, 1)
    }
}

lastmovedirection = nil

gridspaces = {}
gridspacesclone = {}

---------- color variables
originalcolors = {8,10,11,12,13}
originalbackgroundcolor = 7

colors = originalcolors
backgroundcolor = originalbackgroundcolor

---------- player variables
player = {}
currentpath = {}
playerisselecting = false

---------- time variables
lasttime = 0
deltatime = 0

---------- tweens 
tweens = {}

defaultease = "easeoutquad"
fillease = "outbounce"
shrinkoutease = "linear"
shuffleease = "outback"

filltime = .35
shrinkouttime = .2

---------- coroutines
blockingcoroutines = {}

---------- debug variables
debugobject = {}

--------------------------------------------------------------------------------
-- title functions
--------------------------------------------------------------------------------
function inittitle()
    backgroundcolor = originalbackgroundcolor
end

function updatetitle()
    if btnp(z) then
        changestate(gamestate)
    end
end

function drawtitle()
    drawbackground()
    
    local pico = "pico"
    local dots = "dots"
    local start = "press z to play"
    local instructions = "score 100 dots in 60 seconds"

    print(pico, hcenter(pico), 64-8, 8)
    print(dots, hcenter(dots), 70-8, 8)

    print(start, hcenter(start), 100, 8)
    print(instructions, hcenter(instructions), 110, 8)
end

--------------------------------------------------------------------------------
-- game functions -- init
--------------------------------------------------------------------------------
function initgame()
    resetscore()
    resetgame()

    gridspaces = creategrid()
    gridspacesclone = clonegrid(gridspaces)

    fillgridwithdots(fillindirection)

    player = createplayer()
end

function resetscore()
    currentscore = 0
    currenttime = timelimit
end

function resetgame()
    backgroundcolor = originalbackgroundcolor
    dots = {}
    currentpath = {}
    playerisselecting = false
end

function creategrid()
    local grid = {}
    
    dotoffsetx, dotoffsety = gridsize/2, gridsize/2
    gridwidth = gridcols * gridsize
    gridheight = gridrows * gridsize
    boardoffsetx = (max - gridwidth)/2
    boardoffsety = (max - gridheight)/2

    offsetx = dotoffsetx + boardoffsetx
    offsety = dotoffsety + boardoffsety

    for dx = 0,gridrows-1 do 
        for dy = 0,gridcols-1 do
            local newspace = creategridspace(dy, offsetx,
                                             dx, offsety)
            add(grid, newspace)
        end
    end

    return grid
end

function creategridspace(dy, offsetx, dx, offsety)
    local thisx = dy * gridsize + offsetx
    local thisy = dx * gridsize + offsety
    local thisindex = vector:new(dy, dx)
    local thispos = vector:new(thisx, thisy)

    return 
    {
        index = thisindex,
        pos = thispos, 
        currentdot = nil,
        getneighbor = function(self, vector)
                          local newx = self.index.x + vector.x
                          local newy = self.index.y + vector.y

                          if newx < 0 or newx > gridcols-1 or 
                             newy < 0 or newy > gridrows-1 then
                              return nil
                          end

                          return getgridspace(self.index.x + vector.x, 
                                              self.index.y + vector.y)
                      end,
        getneighbors = function(self)
                           local movevectors = {}
                           for direction in all(directions) do
                               local fillvalues = getfillvaluesfordirection(direction)
                               add(movevectors, fillvalues.movevector)
                           end
                           
                           local neighbors = {}
                           for vector in all(movevectors) do
                               local neighbor = self:getneighbor(vector)
                               if neighbor != nil then
                                   add(neighbors, neighbor)
                               end
                           end

                           return neighbors
                       end
     }
end

-- create shallow clone of the original grid, just makes shuffling easier
function clonegrid(originalgrid)
    local grid = {}
    for space in all(originalgrid) do
        add(grid, space)
    end

    return grid
end

function createplayer()
    return { 
              pos = vector:new(0,0),
              color = 0,
              getgridspace = function(self)
                                 return getgridspace(self.pos.x, self.pos.y)
                             end
            }
end

--------------------------------------------------------------------------------
-- game functions -- update
--------------------------------------------------------------------------------
function updategame()
    updatescore()

    updatetweens()
    updatedots()

    if runblockingcoroutines() then
        return
    end

    updateplayer()
end

function updatescore()
    currenttime -= deltatime

    if currenttime <= 0 or currentscore >= scoretarget then
        changestate(gameoverstate)
    end
end

function updatetweens()
    foreach(tweens, function(tween) tween:update() end)
end

function updatedots()
    local lerpspeed = 7 * deltatime
    local size = dotsize

    for dot in all(dots) do
        dot.size = lerp(dot.size, size, lerpspeed)
    end
end

-- blocking coroutines are for logic that's meant to freeze gameplay until they're resolved
-- primarily used for the board fill/dot shrink out animations/phases.
function runblockingcoroutines()
    local isrunning = false

    for coroutine in all(blockingcoroutines) do
        if costatus(coroutine.routine) != "dead" then
            if #coroutine.params == 1 then
                coresume(coroutine.routine, coroutine.params[1])
            else
                coresume(coroutine.routine)
            end

            isrunning = true
        else
            del(blockingcoroutines, coroutine)
        end
    end
    
    return isrunning
end

function updateplayer()
    moveplayer()
    restrictplayer()
    selectplayer()
end

--------------------------------------------------------------------------------
-- game functions -- update player movement
--------------------------------------------------------------------------------
function moveplayer()
    if btnp(left) then
        player.pos.x -= getallowedmovement(left)
        domove(left)
    end

    if btnp(right) then
        player.pos.x += getallowedmovement(right)
        domove(right)
    end

    if btnp(up) then
        player.pos.y -= getallowedmovement(up)
        domove(up)
    end

    if btnp(down) then
        player.pos.y += getallowedmovement(down)
        domove(down)
    end
end

function restrictplayer()
    if player.pos.x < 0 then
        player.pos.x = gridcols - 1
    elseif player.pos.x >= gridcols then
        player.pos.x = 0
    end

    if player.pos.y < 0 then
        player.pos.y = gridrows-1
    elseif player.pos.y >= gridrows then
        player.pos.y = 0
    end
end

function getallowedmovement(direction)
    if playerisselecting then
        return getallowedmovementselected(direction)
    else
        return 1
    end
end

function getallowedmovementselected(direction)
    local currentspace = player:getgridspace()
    local nextspace = nil

    if direction == left then
        nextspace = currentspace:getneighbor(vector:new(-1, 0))
    elseif direction == right then
        nextspace = currentspace:getneighbor(vector:new(1, 0))
    elseif direction == up then
        nextspace = currentspace:getneighbor(vector:new(0, -1))
    elseif direction == down then
        nextspace = currentspace:getneighbor(vector:new(0, 1))
    end

    if nextspace == nil then
        return 0
    elseif checksquarepath() then
        local secondtolastdot = currentpath[#currentpath-1]
        if nextspace == secondtolastdot.gridspace then
            return 1
        else
            return 0
        end
    elseif currentspace.currentdot:getcolor() == nextspace.currentdot:getcolor() then
        return 1
    end

    return 0
end

function domove(direction)
    handlemodevariations(direction)
    if playerisselecting then
        domoveselection()
    else
        sfx(0)
    end
end

function handlemodevariations(direction)
    setmovedirection(direction)
    setcolors()
end

function setmovedirection(direction)
    lastmovedirection = direction
    
    if gamemode != normal then
        fillindirection = direction 
    end
end

function setcolors()
    if gamemode == insane then
        local randomcolors = {}

        for i = 0,15 do
            add(randomcolors, i)
        end
        
        shuffle(randomcolors)

        colors = randomcolors
        backgroundcolor = getrandomcolor()
    else
        colors = originalcolors
        backgroundcolor = originalbackgroundcolor
    end
end

function domoveselection()
    if currentpath == 0 or player:getgridspace() == nil then
        continueselection()
        return
    end

    local secondtolastdot = currentpath[#currentpath-1] 
    local lastdot = currentpath[#currentpath] 
    local currentdot = player:getgridspace().currentdot 

    if secondtolastdot == currentdot then
        revertselection()
    elseif lastdot != currentdot then
        continueselection()
    end
end

--------------------------------------------------------------------------------
-- game functions -- update player selection 
--------------------------------------------------------------------------------
function selectplayer()
    if btnp(z) then
        handleplayeraction()
    end

    if btnp(x) then
        debugbutton()
    end
end

function handleplayeraction()
    if playerisselecting then
        endselection()
    else
        startselection()
    end

    playerisselecting = not playerisselecting
end

function startselection()
    clearpath()
    continueselection()
end

function continueselection()
    local dottoadd = player:getgridspace().currentdot 

    if pathcontains(dottoadd) then
        dosquareeffect()
        local length = #currentpath

        sfx(length + 3)
        sfx(length + 5)
    end

    adddottopath(dottoadd)
end

function endselection()
    resolveselection()
end

function revertselection()
    local dottoremove = currentpath[#currentpath]
    dottoremove.size = removeddotsize
    currentpath[#currentpath] = nil
    del(currentpath, nil)
    sfx(#currentpath)
end

function resolveselection()
    -- here we do square/no square
    if #currentpath > 1 then
        local matchcolor = currentpath[1]:getcolor()

        if checksquarepath() then
            for dot in all(dots) do
                if dot:getcolor() == matchcolor then
                    if dot.gridspace != nil then
                        addscore(1)
                        resolveremovedot(dot)
                    end
                end
            end
        else
            for dot in all(currentpath) do
                if dot.gridspace != nil then
                    addscore(1)
                    resolveremovedot(dot)
                end
                del(currentpath, dot) -- not...doesn't delete all refs in path, just first
            end
        end
    end

    clearpath()
    
    waitforfill()
end

function addscore(amount)
    currentscore += amount
end

function clearpath()
    currentpath = {}
end

function adddottopath(dot)
    dot.size = addeddotsize
    add(currentpath, dot)
    sfx(#currentpath)
end

function pathcontains(dottocheck)
    for dot in all(currentpath) do
        if dot == dottocheck then
            return true
        end
    end

    return false
end

function checksquarepath()
    local hash = {}
    
    for dot in all(currentpath) do
        if hash[dot] then
            return true
        else
            hash[dot] = true
        end
    end

    return false
end

function dosquareeffect()
    local color = currentpath[1]:getcolor()
    local pulsesize = squarepulsesize
    for dot in all(dots) do
        if dot:getcolor() == color then
            dot.size = pulsesize
        end
    end
end

function resolveremovedot(dot)
    local coroutine = { routine = cocreate(animateremovedot), params = {dot} }
    add(blockingcoroutines, coroutine)
end

function animateremovedot(dot)
    local oncomplete = function() 
                           removedotfromgridspace(dot.gridspace) 
                           del(dots, dot)
                       end

    local tween = tween:new(dot, "size", dot.size, 0, shrinkouttime, shrinkoutease, oncomplete)

    while not tween.iscomplete do
        tween:update()
        dot = yield()
    end

    yield()
end

--------------------------------------------------------------------------------
-- game functions -- update grid/dots
--------------------------------------------------------------------------------
function waitforfill()
    local coroutine = { routine = cocreate(function() 
                                               while #blockingcoroutines > 1 do
                                                   yield()
                                               end

                                               fillgridwithdots(fillindirection)
                                           end),
                        params = {} }
    add(blockingcoroutines, coroutine)
end

-- goes through the board, determining where dots can "fall" and where new dots need to be
-- spawned in order to fill the board completely.
function fillgridwithdots(fillindirection)
    local fillvalues = getfillvaluesfordirection(fillindirection)
    fillgridindirection(fillvalues)

    if not checkforavailableconnection() then
        shuffledots()
    end
end

function getfillvaluesfordirection(fillindirection)
    if fillindirection == up then return fillvalues.up
    elseif fillindirection == down then return fillvalues.down
    elseif fillindirection == left then return fillvalues.left
    elseif fillindirection == right then return fillvalues.right end
end

function fillgridindirection(fillvalues)
    local currentvalue = fillvalues.startvalue;
    
    while isvalidgridspace(currentvalue) do
        filllineindirection(currentvalue, fillvalues.checkvector)
        currentvalue += fillvalues.scanvector
    end
end

function filllineindirection(startvalue, movevector)
    local currentvalue = startvalue

    while isvalidgridspace(currentvalue) do
        local gridspace = getgridspace(currentvalue.x, currentvalue.y)

        -- if the current gridspace has a dot, continue, if it doesn't
        -- need to fill from further down the line or spawn.
        if gridspace.currentdot == nil then
            nextdot = getnextavailabledotindirection(gridspace, movevector)
            adddottogridspace(gridspace, nextdot)
            local tween = tween:new(nextdot, 
                                    "pos", 
                                    nextdot.pos, 
                                    gridspace.pos, 
                                    filltime, 
                                    fillease, 
                                    nil)
            add(tweens, tween)
        end
        
        currentvalue += movevector
    end
end

function getnextavailabledotindirection(gridspace, movevector)
    local checkspace = gridspace:getneighbor(movevector)

    while checkspace != nil do
        if checkspace.currentdot != nil then
            return removedotfromgridspace(checkspace)
        end

        checkspace = checkspace:getneighbor(movevector)
    end
    
    local spawndistance = 100
    local spawnx = gridspace.pos.x + movevector.x * spawndistance
    local spawny = gridspace.pos.y + movevector.y * spawndistance
    local spawnpos = vector:new(spawnx, spawny)

    local newdot = spawndot(spawnpos)
    add(dots, newdot)
    return newdot
end

function spawndot(spawnpos)
    if spawnpos == nil then
        spawnpos = vector:new(0, 0)
    end

    dot = 
    { 
        mycolor = ceil(rnd(5)),
        pos = vector:new(spawnpos.x, spawnpos.y),
        size = dotsize,
        gridspace = nil,
        getcolor = function(self)
                       return colors[self.mycolor]
                   end,
        getname = function(self) -- helper function for debugging
                      local space = self.gridspace
                      return space.index.x..", "..space.index.y
                  end
    }

    return dot
end

function isvalidgridspace(vector)
    return vector.x >= 0 and vector.x <= gridcols-1 and
           vector.y >= 0 and vector.y <= gridrows-1
end

function adddottogridspace(space, dot)
    if space == nil or dot == nil then
        return
    end

    space.currentdot = dot
    dot.gridspace = space

    return dot
end

function removedotfromgridspace(space)
    if space.currentdot == nil then
        return nil
    end

    local returndot = space.currentdot
    returndot.gridspace = nil
    space.currentdot = nil

    return returndot
end

--------------------------------------------------------------------------------
-- game functions -- shuffle
--------------------------------------------------------------------------------
function checkforavailableconnection()
    for space in all(gridspaces) do
        local neighbors = space:getneighbors()
        local color = space.currentdot:getcolor()
        for neighbor in all(neighbors) do
            if neighbor.currentdot:getcolor() == color then
                return true
            end
        end
    end

    return false
end

function shuffledots()
    local coroutine = cocreate(doshuffleroutine)
    local params = {}
    add(blockingcoroutines, { routine = coroutine, params = params })
end

function doshuffleroutine()
    -- delay a bit
    local starttime = time()
    local delay = 1
    while time() - starttime < delay do
        yield()
    end

    local shuffledgrid = shuffle(gridspacesclone)
    local shuffletweens = {}
    local dots = {}
    
    -- remove dots from grid
    for space in all(gridspaces) do
        add(dots, removedotfromgridspace(space))
    end

    for i = 1,#shuffledgrid do
        local newspace = shuffledgrid[i]
        local dot = dots[i]
        local duration = 1
        
        adddottogridspace(newspace, dot)
        local tween = tween:new(dot, "pos", dot.pos, newspace.pos, duration, shuffleease, nil)
        add(shuffletweens, tween)
    end

    local iscomplete = false
    while not iscomplete do
        iscomplete = true
        for tween in all(shuffletweens) do
            tween:update()
            iscomplete = iscomplete and tween.iscomplete
        end
        yield()
    end
end

--------------------------------------------------------------------------------
-- game functions -- draw
--------------------------------------------------------------------------------
function drawgame()
    drawbackground()
    drawdots()

    drawplayer()

    drawpath()
    drawborderlines()
    
    drawui(0)
end

function drawbackground()
    rectfill(0,0,max,max,backgroundcolor)
end

function drawdots()
    for dot in all(dots) do
        circfill(dot.pos.x, dot.pos.y, dot.size, dot:getcolor()) 
    end
end

function drawplayer()
    local gridspace = getgridspace(player.pos.x, player.pos.y)
    local x = gridspace.pos.x - 7
    local y = gridspace.pos.y - 7
    local color = 0
    local size = dotsize + 3

    if playerisselecting then
        size += sin1(time())
        color = gridspace.currentdot:getcolor()
    end

    circ(gridspace.pos.x, gridspace.pos.y, size, color)
end

function drawpath()
    if #currentpath == 0 then
        return
    end

    local start = currentpath[1].pos
    local color = currentpath[1]:getcolor()
    local thickness = 3 

    for dot in all(currentpath) do
        drawline(start, dot.pos, color, thickness)
        start = dot.pos
    end
end

function drawline(startvector, endvector, color, thickness)
    local dir = endvector - startvector
    local offset = flr(thickness / 2)

    local normal = dir:normal():normalize()
    local startnormal = normal * (offset * -1)

    startvector = startvector + startnormal
    endvector = endvector + startnormal

    local iterations = thickness - 1
    for i = 0,iterations do
        local thisstartvector = startvector + (normal * i)
        local thisendvector = endvector + (normal * i)

        line(thisstartvector.x, thisstartvector.y, thisendvector.x, thisendvector.y, color)
    end
end

function drawborderlines()
    if #currentpath == 0 then
        return
    end

    local zero = .5;
    local half = 64;
    local full = 127;
    local borderlines =
    {
        { vector:new(half, zero), vector:new(zero, zero), vector:new(zero, half) },
        { vector:new(half, zero), vector:new(full, zero), vector:new(full, half) },
        { vector:new(half, full), vector:new(zero, full), vector:new(zero, half) },
        { vector:new(half, full), vector:new(full, full), vector:new(full, half) },
    }
    
    local color = currentpath[1]:getcolor()
    local thickness = 3

    local maxconnection = 10
    local connectioncount = #currentpath
    
    local time = mid(0, connectioncount/maxconnection, 1)

    if checksquarepath() then
        time = 1
    end

    for line in all(borderlines) do
        local totaldistance = 0
        for i = 1,#line-1 do
            totaldistance += vector:distance(line[i],line[i+1])
        end
        
        local covereddistance = lerp(0, totaldistance, time * time)
        local segmentlength = 0

        for i = 1,#line-1 do
            local localstartvector = line[i]
            local localendvector = line[i+1]

            segmentlength = vector:distance(localstartvector, localendvector)

            if covereddistance < segmentlength then
                local time = covereddistance / segmentlength 
                position = vectorlerp(localstartvector, localendvector, time)
            else
                position = localendvector
            end

            if covereddistance > 0 then
                covereddistance -= segmentlength
                drawline(localstartvector, position, color, thickness)
            end
        end
    end
end

function drawui(textcolor)
    local score = tostr(currentscore)
    local time = tostr(flr(currenttime))
    print(score, hcenter(score), 4, textcolor)
    print(time, hright(time)-4, 4, textcolor)
end

--------------------------------------------------------------------------------
-- game over functions
--------------------------------------------------------------------------------
function initgameover()
    local modetarget = gamemode

    if wonlastgame() then
        modetarget = gamemode + 1
    end

    gamemode = modetarget
end

function updategameover()
    updategameoverbackground()
    
    if btnp(z) then
        if gamemode < normal or gamemode > insane then
            changestate(titlestate)
        else
            changestate(gamestate)
        end
    end
end

function drawgameover()
    drawbackground()
    drawui(7)
    drawgameovertext()
end

function wonlastgame()
    return currentscore >= scoretarget
end

function updategameoverbackground()
    if wonlastgame() then
        backgroundcolor = getrandomcolor()
    else
        backgroundcolor = 0
    end
end

function drawgameovertext()
    local gameovermessage = "game over"
    local nextgamemessage = "press z to retry"
    local color = 7

    if wonlastgame() then
        gameovermessage = "you won!"
        color = getrandomcolor()
    end

    if gamemode == hard then
        nextgamemessage = "press z to play hard mode"
    elseif gamemode == insane then
        nextgamemessage = "press z to play insane mode" 
    elseif gamemode > insane then
        nextgamemessage = "you are cool and popular"
    end

    print(gameovermessage, hcenter(gameovermessage), 61, color)
    print(nextgamemessage, hcenter(nextgamemessage), 100, color)
end

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------
cos1 = cos function cos(angle) return cos1(angle/(3.1415*2)) end
sin1 = sin function sin(angle) return sin1(-angle/(3.1415*2)) end

function getgridspace(x, y)
    local xindex = x 
    local yindex = y * gridcols
    return gridspaces[(xindex+yindex)+1]
end

function getrandomcolor()
    return flr(rnd(15))
end

function hcenter(s)
    return 64-#s*2
end

function hright(s)
    return max-#s*4
end

function lerp(a, b, t)
    return ((1-t) * a + t * b)
end

function vectorlerp(a, b, t)
    local lerpx = lerp(a.x, b.x, t)
    local lerpy = lerp(a.y, b.y, t)
    return vector:new(lerpx, lerpy)
end

function shuffle(array)
    size = #array
    for i = size, 1, -1 do
        local rand = flr(rnd(size)) + 1
        array[i], array[rand] = array[rand], array[i]
    end
    return array
end

--------------------------------------------------------------------------------
-- debug functions
--------------------------------------------------------------------------------
function log(message)
    if message == nil then
        message = "nil"
    end

    add(debugobject, { message = message, time = time() })
end

function debug()
    local height = 0
    local duration = 1.5

    for item in all(debugobject) do
        if time() - item.time > duration then
           print("delete me", 0, height, 0)
           del(debugobject, item)
        else
            print(item.message, 0, height, 0)
            height += 6
        end
    end
end

function debugbutton()
    -- Add shortcuts here.
end

--------------------------------------------------------------------------------
-- system functions
--------------------------------------------------------------------------------
function _init()
    changestate(titlestate)
end

function _update()
    handletime()
    currentstate:update()
end

function _draw()
    cls()
    currentstate:draw()
    debug()
end

function changestate(state)
    currentstate = state
    currentstate:init()
end

function handletime()
    deltatime = time() - lasttime
    lasttime = time()
end

__gfx__

__sfx__
010f00000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900001805018050180000200023700237002370023700227002270025600206001660014600116001060012600000000000000000000000000000000000000000000000000000000000000000000000000000
010f00001a05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001c05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001e05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00002105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002205000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002a05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002e05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003205000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
