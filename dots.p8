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
              easeinquad = function(self, t, b, c, d)
                                 t /= d
                                 return c * t*t + b
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
                        if (time >= self.duration) then
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
                                            
                       if (time >= self.duration) then
                           x = self.endvalue.x
                           y = self.endvalue.y
                           iscomplete = true
                       end

                       self.object[self.property] = vector:new(x, y)

                       if (iscomplete) then
                           del(tweens, self)

                           if oncomplete != nil then
                               oncomplete()
                           end

                           self.iscomplete = true
                       end
                   end,

    gettweentime = function(self)
                       return time() - self.starttime
                   end,
}

--------------------------------------------------------------------------------
-- global variables 
--------------------------------------------------------------------------------
-- input variables
left = 0
right = 1
up = 2
down = 3

z = 4
x = 5

playerisselecting = false

-- dot variables
dotsize = 5.1 -- offset is because of weird circfill radius draw issues

dots = {}

-- board variables
max = 128
gridcols = 5
gridrows = 5
gridsize = dotsize * 3.5

directions = {left, down, up, right}
fillindirection = down -- Dots fill from this direction

gridspaces = {}
gridspacesclone = {}

-- color variables
colors = {8,10,11,12,13}
backgroundcolor = 7

-- player variables
player = {}
currentpath = {}

-- time variables
lasttime = 0
deltatime = 0

-- tweens 
tweens = {}

defaultease = "easeoutquad"
fillease = "outbounce"
shrinkoutease = "linear"
shuffleease = "outback"

-- coroutines
blockingcoroutines = {}

-- debug variables
debugobject = {}


--------------------------------------------------------------------------------
-- initialization functions
--------------------------------------------------------------------------------
function creategrid()
    local grid = {}
    
    dotoffsetx, dotoffsety = gridsize/2, gridsize/2
    gridwidth = (gridcols + 1) * gridsize
    gridheight = (gridrows+1) * gridsize
    boardoffsetx = (max - gridwidth)/2
    boardoffsety = (max - gridheight)/2

    offsetx = dotoffsetx + boardoffsetx
    offsety = dotoffsety + boardoffsety

    for dx = 0,gridrows do 
        for dy = 0,gridcols do
            local newspace = creategridspace(dy, offsetx,
                                             dx, offsety)
            add(grid, newspace)
        end
    end

    return grid
end

function clonegrid(originalgrid)
    local grid = {}
    for space in all(originalgrid) do
        add(grid, space)
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
        getneighbor = function (self, vector)
                          local newx = self.index.x + vector.x
                          local newy = self.index.y + vector.y

                          if newx < 0 or newx > gridcols or 
                             newy < 0 or newy > gridrows then
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

function createplayer()
    return { 
              pos = vector:new(0,0),
              color = 0,
              getgridspace = function (self)
                                 return getgridspace(self.pos.x, self.pos.y)
                             end
            }
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

function checkforavailableconnection()
    for space in all(gridspaces) do
        local neighbors = space:getneighbors()
        local color = space.currentdot.color
        for neighbor in all(neighbors) do
            if neighbor.currentdot.color == color then
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
    local delay = .5
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
        
        adddottogridspace(newspace, dot)
        local tween = tween:new(dot, "pos", dot.pos, newspace.pos, .5, shuffleease, nil)
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

function getfillvaluesfordirection(fillindirection)
    fillvalues = { 
        movevector = nil,
        startvalue = nil,
        checkvector = nil,
        scanvector = nil,
    }
    
    if fillindirection == up then
        fillvalues.movevector = vector:new(0, -1)
        fillvalues.startvalue = vector:new(0, 0)
        fillvalues.checkvector = vector:new(0, 1)
        fillvalues.scanvector = vector:new(1, 0)
    elseif fillindirection == down then
        fillvalues.movevector = vector:new(0, 1)
        fillvalues.startvalue = vector:new(0, gridrows)
        fillvalues.checkvector = vector:new(0, -1)
        fillvalues.scanvector = vector:new(1, 0)
    elseif fillindirection == left then
        fillvalues.movevector = vector:new(-1, 0)
        fillvalues.startvalue = vector:new(0, 0)
        fillvalues.checkvector = vector:new(1, 0)
        fillvalues.scanvector = vector:new(0, 1)
    elseif fillindirection == right then
        fillvalues.movevector = vector:new(1, 0)
        fillvalues.startvalue = vector:new(gridcols, 0)
        fillvalues.checkvector = vector:new(1, 0)
        fillvalues.scanvector = vector:new(0, 1)
    end
    
    return fillvalues
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
                                    .35, 
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

function isvalidgridspace(vector)
    return vector.x >= 0 and vector.x <= gridcols and
           vector.y >= 0 and vector.y <= gridrows
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

function spawndot(spawnpos)
    if spawnpos == nil then
        spawnpos = vector:new(0, 0)
    end

    dot = 
    { 
        color = colors[ceil(rnd(#colors))],
        pos = vector:new(spawnpos.x, spawnpos.y),
        size = dotsize,
        gridspace = nil,
        getname = function(self) -- helper function for debugging
                      local space = self.gridspace
                      return space.index.x..", "..space.index.y
                  end
    }

    return dot
end

-- update functions

function handletime()
    deltatime = time() - lasttime
    lasttime = time()
end

function updatedots()
    local lerpspeed = 10 * deltatime
    local size = dotsize
    for dot in all(dots) do
        dot.size = lerp(dot.size, size, lerpspeed * .75)
        //dot.pos.x = lerp(dot.pos.x, dot.gridspace.pos.x, lerpspeed)
        //dot.pos.y = lerp(dot.pos.y, dot.gridspace.pos.y, lerpspeed)
    end
end

function moveplayer()
    if btnp(left) then
        player.pos.x -= getallowedmovement(left)
        domove()
    end

    if btnp(right) then
        player.pos.x += getallowedmovement(right)
        domove()
    end

    if btnp(up) then
        player.pos.y -= getallowedmovement(up)
        domove()
    end

    if btnp(down) then
        player.pos.y += getallowedmovement(down)
        domove()
    end

end

function domove()
    sfx(0)

    if playerisselecting then
        domoveselection()
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
    elseif currentspace.currentdot.color == nextspace.currentdot.color then
        return 1
    end

    return 0
end

function boundplayer()
    if player.pos.x < 0 then
        player.pos.x = gridcols
    elseif player.pos.x >= gridcols + 1 then
        player.pos.x = 0
    end

    if player.pos.y < 0 then
        player.pos.y = gridrows
    elseif player.pos.y >= gridrows + 1 then
        player.pos.y = 0
    end
end

function selectplayer()
    if (btnp(z)) then
        handleplayeraction()
    end

    if (btnp(x)) then
        shuffledots()
    end
end

function handleplayeraction()
    if (playerisselecting) then
        endselection()
    else
        startselection()
    end

    playerisselecting = not playerisselecting
end

function endselection()
    resolveselection()
end

function startselection()
    clearpath()
    continueselection()
end

function continueselection()
    local dottoadd = player:getgridspace().currentdot 
    if pathcontains(dottoadd) then
        dosquareeffect()
    end

    adddottopath(dottoadd)
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
        if (hash[dot]) then
            return true
        else
            hash[dot] = true
        end
    end

    return false
end

function dosquareeffect()
    local color = currentpath[1].color
    for dot in all(dots) do
        if dot.color == color then
            dot.size = 10
        end
    end
end

function revertselection()
    local dottoremove = currentpath[#currentpath]
    dottoremove.size = 3.5
    currentpath[#currentpath] = nil
    del(currentpath, nil)
end

function resolveselection()
    -- here we do square/no square
    if #currentpath > 1 then
        local matchcolor = currentpath[1].color

        if checksquarepath() then
            for dot in all(dots) do
                if (dot.color == matchcolor) then
                    if dot.gridspace != nil then
                        resolveremovedot(dot)
                    end
                end
            end
        else
            for dot in all(currentpath) do
                if (dot.gridspace != nil) then
                    resolveremovedot(dot)
                end
                del(currentpath, dot) -- sigh...doesn't delete all refs in path
            end
        end
    end

    clearpath()
    
    waitforfill()
end

function resolveremovedot(dot)
    local coroutine = { routine = cocreate(animateremovedot), params = {dot} }
    add(blockingcoroutines, coroutine)
end

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

function clearpath()
    currentpath = {}
end

function adddottopath(dot)
    dot.size = 10
    add(currentpath, dot)
end

function updatetweens()
    foreach(tweens, function(tween) tween:update() end)
end

function runblockingcoroutines()
    local isrunning = false
    for coroutine in all(blockingcoroutines) do
        if (costatus(coroutine.routine) != "dead") then
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

function animateremovedot(dot)
    local oncomplete = function() 
                           removedotfromgridspace(dot.gridspace) 
                           del(dots, dot)
                       end
    local tween = tween:new(dot, "size", dot.size, 0, .2, shrinkoutease, oncomplete)
    while not tween.iscomplete do
        tween:update()
        dot = yield()
    end
    yield()
end

-- draw functions
function drawbackground()
    rectfill(0,0,128,128,backgroundcolor)
end

function drawdots()
    for dot in all(dots) do
        circfill(dot.pos.x, dot.pos.y, dot.size, dot.color) 
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
        color = gridspace.currentdot.color
    end

    circ(gridspace.pos.x, gridspace.pos.y, size, color)
end

function drawpath()
    if #currentpath == 0 then
        return
    end

    local start = currentpath[1].pos
    local color = currentpath[1].color
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

    local borderlines =
    {
        { vector:new(64, 0), vector:new(0, 0), vector:new(0, 64) },
        { vector:new(64, 0), vector:new(128, 0), vector:new(128, 64) },
        { vector:new(64, 128), vector:new(0, 128), vector:new(0, 64) },
        { vector:new(64, 128), vector:new(128, 128), vector:new(128, 64) },
    }
    
    local color = currentpath[1].color
    local thickness = 3

    local maxconnection = 10
    local connectioncount = #currentpath
    
    for line in all(borderlines) do
        local totaldistance = 0
        for i = 1,#line-1 do
            totaldistance += vector:distance(line[i],line[i+1])
        end
        
        local time = mid(0, connectioncount/maxconnection, 1)
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

-- debug functions
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
           print("DELETE ME", 0, height, 0)
           del(debugobject, item)
        else
            print(item.message, 0, height, 0)
            height += 6
        end
    end
end

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------
function getgridspace(x, y)
    local xindex = x 
    local yindex = y * (gridcols + 1)
    return gridspaces[(xindex+yindex)+1]
end

function lerp(a, b, t)
    return ((1-t) * a + t * b)
end

function vectorlerp(a, b, t)
    local lerpx = lerp(a.x, b.x, t)
    local lerpy = lerp(a.y, b.y, t)
    return vector:new(lerpx, lerpy)
end

--function sin1(angle)
 --   return sin(angle/3.14159*2)
--end

--function cos1(angle)
    --return cos(angle/3.14159*2)
--end

cos1 = cos function cos(angle) return cos1(angle/(3.1415*2)) end
sin1 = sin function sin(angle) return sin1(-angle/(3.1415*2)) end

function shuffle(array)
    size = #array
    for i = size, 1, -1 do
        local rand = flr(rnd(size)) + 1
        array[i], array[rand] = array[rand], array[i]
    end
    return array
end
--------------------------------------------------------------------------------
-- system functions
--------------------------------------------------------------------------------
function _init()
    gridspaces = creategrid()
    gridspacesclone = clonegrid(gridspaces)

    fillgridwithdots(fillindirection)

    player = createplayer()
end

function _update()
    handletime()

    updatetweens()
    updatedots()

    if runblockingcoroutines() then
        return
    end

    moveplayer()
    boundplayer()

    selectplayer()
    
end

function _draw()
    cls()
    drawbackground()
    drawdots()

    drawplayer()

    drawpath()
    drawborderlines()

    debug()
end

__gfx__
00000000550550550000000000000000555550000005555500000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005000000500cccc0000bbbb00555550000005555500000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000cccccc00bbbbbb0550000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000500550050cccccc00bbbbbb0550000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000500550050cccccc00bbbbbb0550000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000cccccc00bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005000000500cccc0000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550550550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000550000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000550000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000550000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555500000000555500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555500000000555500000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000000016050160502350023500237002370023700237002270022700256002060016600146001160010600126000000000000000000000000000000000000000000000000000000000000000000000000
