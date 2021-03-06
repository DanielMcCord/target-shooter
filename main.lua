-----------------------------------------------------------------------------------------
--
-- main.lua
--
-- Author:		Daniel McCord
-- Instructor:	Dave Parker
-- Course:		CSCI 79
-- Semester:	Spring 2019
-- Assignment:	Target Shooter
--
-----------------------------------------------------------------------------------------

-- Constants

-- Get the screen metrics (use the entire device screen area)
local WIDTH = display.actualContentWidth -- the actual width of the display
local HEIGHT = display.actualContentHeight -- the actual height of the display
local X_MIN = display.screenOriginX -- the left edge of the display
local Y_MIN = display.screenOriginY -- the top edge of the display
local X_MAX = X_MIN + WIDTH -- the right edge of the display
local Y_MAX = Y_MIN + HEIGHT -- the bottom edge of the display
local X_CENTER = (X_MIN + X_MAX) / 2 -- the center of the display (horozontal axis)
local Y_CENTER = (Y_MIN + Y_MAX) / 2 -- the center of the display (vertical axis)
local SPAWN_Y_MIN = Y_MIN + HEIGHT / 16
local SPAWN_Y_MAX = Y_MAX - HEIGHT / 4
local GAME_SPEED = 1

-- File local variables
local bullets -- display group of all active bullets
local targets -- display group of all active targets
local turret -- display group for the turret
local scores -- table of Score objects
local targetTypes = { -- tables of object contructor functions
    display.newRect,
    display.newRoundedRect,
    display.newCircle
}

-- File local classes
local Score

-- File local functions
local createBullet
local createTarget
local bulletDone
local targetDone
local touched
local hypotenuse
local hitTest
local newFrame
local initGame

-- Class definitions
Score =
{
    -- Instance variables:
        -- value -- Number. The actual score.
        -- text -- String. The text to display before the score.
        -- textObj -- DisplayObject. Text box that dispays ( text .. value ).

    -- Constructor. Parameters follow modern syntax for display.newText(),
    -- with one difference: the default value of 0 is appended to score.textObj.text,
    -- but instance variable text is set to the passed value of text.
    new = function( self, options )
        local score = {
            value = 0,
        }
        if options then
            score.textObj = display.newText( options )
            score.text = score.textObj.text
            score.textObj.text = score.text .. score.value
        end
        setmetatable( score, self )
        self.__index = self
        return score
    end,

    -- Increases or decreases the score by some amount.
    change = function( self, amount )
        self.value = self.value + amount
        self.textObj.text = self.text .. self.value
    end,
}

-- Function definitions
-- Create and return a new bullet object.
function createBullet()
    local t = turret
    local x, y = t:localToContent( t[1].x, t[1].y - t[1].height / 2 )
    local b = display.newCircle( bullets, x, y, t.caliber / 2 )
    return b
end

-- Create and return a new target group at a random altitude.
function createTarget()
    local t = display.newGroup ()-- composite target object
    t.constructor = targetTypes[math.random(#targetTypes)]
    t.values = { math.random( 10, 40 ), math.random( 10, 40 ), 10 }
    t.targetSize = 20
    -- only make non-circles rotate, because why not?
    if t.constructor == display.newCircle then
        t.rotates = false
    else
        t.rotates = true
    end
    t.direction = t.constructor == display.newRoundedRect and
        1 or -1 -- non-rounded rects move to left
    t.constructor(t, 0, t.targetSize, unpack(t.values) ) 
    t.constructor(t, t.targetSize, 0, unpack(t.values) )
    t.constructor(t, 0, -t.targetSize, unpack(t.values) )
    t.constructor(t, -t.targetSize, 0, unpack(t.values) )
    t.y = math.random( SPAWN_Y_MIN, SPAWN_Y_MAX )
    if t.direction == 1 then
        t.direction = 1
        t.x = X_MIN
    else
        t.direction = -1
        t.x = X_MAX
    end
    t.rotation = math.random( -180, 180 )
    --display.newRoundedRect(t, 0, 0, math.random( 10, 40 ), math.random( 10, 40 ), 10 )
    --display.newRoundedRect(t, 0, 0, math.random( 10, 40 ), math.random( 10, 40 ), 10 )
    --t[1].x = t[1].x + 20
    --t[2].x = t[2].x - 20
    --print(t.numChildren)
    for i = t.numChildren, 1, -1 do
        t[i]:setFillColor(
            math.random() / 3 + 0.5,
            math.random() / 3 + 0.5,
            math.random() / 3 + 0.5
        )
    end
    targets:insert( t )   -- put t into the targets group
    return t
end

-- Called when a bullet goes off the top of the screen
-- Delete the bullet and count a bullet miss.
function bulletDone( obj )
    scores.bulletMisses:change( 1 )
    obj:removeSelf()
end

-- Called when a target goes off the left of the screen
-- Delete the target and count a target miss.
function targetDone( obj )
    scores.targetMisses:change( 1 )
    display.remove( obj )
end

-- Called when the screen is touched
-- Fire a new bullet.
function touched( event )
    local t = turret
    if event.phase == "began" then
        -- Determine what the angle of the turret should be based on event coordinates
        local rotation = math.deg( math.atan2( event.y - t.y, event.x - t.x ) ) + 90
        if math.abs(rotation) < t.firingArc / 2 then
            t.rotation = rotation
            local b = createBullet()
            -- Calculate the x coordinate where the bullet would reach the top
            local bEndingX = b.x + (b.y - Y_MIN) * math.tan( math.rad( rotation ) )
            local bEndingY -- Will be nil unless bullet is hitting the side
            -- Check if the bullet is going to hit the side first
            if bEndingX <= X_MIN or bEndingX >= X_MAX then
                bEndingY = b.y + (b.x - ( t.rotation < 0 and X_MIN or X_MAX ) )
                    / math.tan( math.rad( rotation ) )
                bEndingX = math.max( math.min( bEndingX, X_MAX ), X_MIN )
            end
            transition.to( b, {
                y = bEndingY or Y_MIN,
                x = bEndingX,
                time = hypotenuse( b.y - ( bEndingY or Y_MIN ), b.x - bEndingX)
                    / t.firingVelocity,
                onComplete = bulletDone,
            } )
        end
    end
end

-- Returns the hypotenuse of a right triangle given the other two sides
function hypotenuse( a, b )
    return math.sqrt( math.pow( a, 2 ) + math.pow( b, 2 ) )
end

-- Return true if the given bullet hit the given target
-- b should be a circle.
-- t should be a display group of circles, rects, and/or roundedRects.
function hitTest( b, t )
    local rBullet = b.path.radius
    for i = t.numChildren, 1, -1 do
        -- Get coordinates of bullet with respect to the target
        local bX, bY = t[i]:contentToLocal( b.x, b.y )
        if t[i].path.type == "rect" or t[i].path.type == "roundedRect" then
            -- Calculate x and y distance of bullet center from target edge
            local xDist = math.abs( bX ) - t[i].width / 2
            local yDist = math.abs( bY ) - t[i].height / 2
            -- Check if bullet has crossed both edge lines
            if xDist < rBullet and yDist < rBullet then
                -- Check for special case where bullet is near a corner
                if xDist > 0 and yDist > 0 then
                    local rCorner = t[i].path.radius or 0 -- rectangle corner radius
                    -- Check if bullet is actually touching the corner
                    if hypotenuse( xDist + rCorner, yDist + rCorner )
                            < rBullet + rCorner then
                        -- The bullet hit the corner
                        return true
                    end
                else
                    -- The bullet hit the edge
                    return true
                end
            end
        else -- treat t as a circle by default
            if hypotenuse( math.abs( bX - t[i].x ), math.abs( bY - t[i].y ) )
                    < rBullet + ( t.width + t.height ) / 4 then
                return true
            end
        end
    end
    return false
end

-- Called before each animation frame
function newFrame()
    -- Launch new targets at random intervals and speeds
    if math.random() < 0.01 then
        local t = createTarget()
        transition.to( t, {
            x = X_CENTER + t.direction * WIDTH / 2,
            onComplete = targetDone,
            rotation = t.rotation +
                ( t.rotates and ( math.random() - 0.5 ) * 4 * 360 or 0 ),
            time = 150000 / ( 1 + t.y * math.random() ) / GAME_SPEED
        } )
    end
    -- Test for hits (all bullets against all targets)
    for i = bullets.numChildren, 1, -1 do
        local b = bullets[i]
        for j = targets.numChildren, 1, -1 do
            local t = targets[j]
            if hitTest( b, t ) then
                -- Count a hit
                scores.hits:change( 1 )

                -- Make an explosion
                local explosion = display.newCircle( t.x, t.y, ( t.width + t.height ) / 4 )
                explosion.explosive = true
                transition.to( explosion, {
                    xScale = 2,
                    yScale = 2,
                    alpha = 0,
                    onComplete = explosion.removeSelf
                    } )

                -- Delete the bullet
                transition.cancel( b )
                b:removeSelf()

                -- Delete the target
                transition.cancel( t )
                t:removeSelf()

                -- Don't let this bullet affect any more targets
                break
            end
        end
    end
end

-- Init the app
function initGame()
    -- Create display groups for active bullets, targets, and the turret
    bullets = display.newGroup()
    targets = display.newGroup()
    turret = display.newGroup()
    -- Create the table for the score objects
    scores = {
        hits = Score:new{
            text = "#hits: ",
            x = X_CENTER,
            y = Y_MIN + 0.5 * HEIGHT / 13,
            width = WIDTH,
            align = "left",
        },
        bulletMisses = Score:new{
            text = "#bullet misses: ",
            x = X_CENTER,
            y = Y_MIN + HEIGHT / 13,
            width = WIDTH,
            align = "left",
        },
        targetMisses = Score:new{
            text = "#target misses: ",
            x = X_CENTER,
            y = Y_MIN + 1.5 * HEIGHT / 13,
            width = WIDTH,
            align = "left",
        },
    }
    --
    

    -- Create and position the turret
    turret:insert( display.newImage( "turret.png" ) ) 
    turret[1].aspect = turret[1].width / turret[1].height
    turret.x = X_CENTER
    turret.y = Y_MAX - turret[1].height / 2
    turret.firingArc = 180
    turret.firingVelocity = .25
    turret.caliber = 10

    -- Add event listeners
    Runtime:addEventListener( "touch", touched )
    Runtime:addEventListener( "enterFrame", newFrame )
end

-- Start the game
initGame()