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

--[[
In this assignment you will create a simple target shooting game, using a couple of new
Corona features: Display Groups, and Transition Animations. Display Groups are a way to
structure more complex graphics into sub-parts, and Transition Animations are a different
method of doing animation (rather than changing object positions manually in an
"enterFrame" event listener). In addition, you will make more use of functions in Lua to
organize your code and keep track of your objects effectively.

Game Description

At the bottom center of the screen there is a "gun" (or some kind of shooting weapon of
your choice). When the user taps the screen, the gun shoots a bullet upwards. You can
choose to have the bullet always shoot straight up, or shoot in the direction of the tap
if you want. Each time you tap, another bullet is fired. Holding your finger down after a
tap should not keep shooting more, though. In other words, we want a "semi-automatic"
machine gun, not a "fully automatic" one. Each bullet should move using a transition
animation (instead of modifying its coordinates manually each frame as we did in the Fly
Game).

Flying horizontally across the screen are various targets, which are launched at random
intervals, random altitudes, and random speeds. Each target should be a display group
made up of more than one sub-part that all move as one unit. In addition to moving
horizontally, targets should rotate about their center for a tumbling effect. Targets
also move using a transition animation.

There is no limit to the number of bullets that can be on the screen at a time (limited
only by the user's tapping speed). New bullets are created as needed, and when a bullet
goes off the top of the screen it is destroyed and a bullet miss is counted. 

If a target goes off the screen after flying by, a target miss is counted.

If a bullet hits a target, both the bullet and the target are destroyed and disappear, a
hit is counted, and an animated explosion is drawn. The explosion should grow in size and
also fade out over a time interval (again using a transition animation).

The game displays at least # hits, # bullet misses, and # target misses on-screen (and
percent stats using these if you want).

More Info and Hints

Your program should do the hit testing manually (don't use physics collisions). This can
be done by keeping a display group containing all the bullets, another display group of
all the targets, and then testing every active bullet against every active target, every
frame. This means you will have an "enterFrame" listener function which does something
like this:

for i = 1, bullets.numChildren do
     for j = 1, targets.numChildren do
          if hitTest( bullets[i], targets[j] ) then
                -- hit
          end
     end
end

You will need to write the hitTest(bullet, target) function (similar to Fly Game) and
figure out how to handle the hit. Handling the hit will include:

    Cancel any active transition animations on the bullet. You can use
    transition.cancel(obj).
    
    Delete the bullet object (which will automatically remove it from the bullets group).
    You can use obj:removeSelf()

    Cancel any active transition animations on the target.

    Delete the target object (which should automatically remove it from the bullets
    group)

    Count a hit

    Update the score display

    Create the explosion and start its animation


However, note that if you actually delete objects during the execution of the for loops
as shown above, then the loops will screw up and go too far and produce nil objects later
on (why?)... One way to solve this will be shown in the sample code posted.

You can detect misses for bullets and targets by the fact that its transition animation
completes, which will call the onComplete handler for the transition.

To animate an explosion, use transition.to, and see the xScale, yScale, and alpha
parameters. Make sure you delete the explosion object when it is done.

Grading

    [TODO](10) Start with the blank app template, app named correctly (e.g.
    "Parker Target Shooter"), no physics.

    [TODO](5) Bullet fired each time user taps screen (at start of touch, but only once
    per tap).

    [TODO](5) Bullets move up using a transition.to animation

    [TODO](5) Bullet objects are created right when fired, using a Lua function that
    creates and returns one.

    [TODO](5) Bullet objects are destroyed when they go off the top of the screen.

    [TODO](5) Target objects are display groups containing sub-parts (circles,
    rectangles, images, etc.)

    [TODO](5) Targets launch at random intervals, random altitudes, and random speeds.

    [TODO](10) Target objects are created right when launched using a Lua function that
    one, and destroyed when done.

    [TODO](5) Target flies horizontally across the screen and tumbles (rotates) while it
    flies, using a single transition.to animation.

    [TODO](5) Check for hits for any active bullet against any active target.

    [TODO](10) Handle hits properly

    [TODO](5) Handle misses properly

    [TODO](10) Explosion graphic is drawn at a hit and animated with transition.to. It
    should expand and fade, then get deleted.

    [TODO](5) Stats shown on-screen with at least #hits, #bullet misses, #target misses.

    [TODO](5) Lua code contains no global variables (file local Ok when appropriate) and
    no dangling object references (nothing should reference an object after it gets
    destroyed).

    [TODO](5) Code has good comments, indentation, and overall function structure. Write
    and use an initGame function to minimize code in the main chunk.


Extra Credit:

    [TODO](+5) Implement at least 3 different types of targets that look and act
    different, and are chosen randomly for each launch. Try to use tables, functions, and
    perhaps function references inside tables to create and process them (to avoid 3+
    chunks of near-duplicate code anywhere).


Total: 100 points, or up to 105 with extra credit.
]]--

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

-- File local variables
local bullets -- display group of all active bullets
local targets -- display group of all active targets
local turret -- display group for the turret

-- File local functions
local createBullet
local createTarget
local bulletDone
local targetDone
local touched
local hitTest
local newFrame
local initApp

-- Create and return a new bullet object.
function createBullet()
    -- local b = ...    (use the bullets group as the parent)
    -- return b
end

-- Create and return a new target object at a random altitude.
function createTarget()
    local t = display.newGroup()    -- composite target object
    -- ...
    targets:insert( t )   -- put t into the targets group
    return t
end

-- Called when a bullet goes off the top of the screen
-- Delete the bullet and count a bullet miss.
function bulletDone( obj )
    obj:removeSelf()
    -- ...
end

-- Called when a target goes off the left of the screen
-- Delete the target and count a target miss.
function targetDone( obj )
    -- ...
end

-- Called when the screen is touched
-- Fire a new bullet.
function touched( event )
    if event.phase == "began" then
        local b = createBullet()
        -- transition.to( b, { ... onComplete = bulletDone } )
        local t = turret
        t.rotation = math.deg( math.atan2( event.y - t.y, event.x - t.x ) ) + 90
    end
end

-- Return true if the given bullet hit the given target
-- Treats b as a circle even if it isn't. t can be a circle, rect, or roundedRect.
function hitTest( b, t )
    for i = t.numChildren, 1, -1 do
        local shape = t[i].path.type
        if shape == "rect" or shape == "roundedRect" then
            -- Get coordinates of bullet with respect to the target
            local bX, bY = t[i].contentToLocal( b.x, b.y )
            local r = b.path.radius or width * height / 2 -- in case r isn't a circle
            -- Calculate x and y distance of bullet center from target edge
            local xDist = math.abs( bX - t[i].x ) - width / 2
            local yDist = math.abs( bY - t[i].y ) - height / 2
            -- Check if bullet has crossed both edge lines
            if xDist < r and yDist < r then
                -- Check for special case where bullet is near a corner
                if xDist > 0 and yDist > 0 then
                    local rCorner = t[i].path.radius or 0 -- rectangle corner radius
                    -- Check if bullet is actually touching the corner
                    if math.sqrt( math.pow( xDist + ( rCorner ), 2 ) 
                            + math.pow( yDist + ( rCorner ), 2 ) ) < r + rCorner then
                        -- The bullet hit the corner
                        return true
                    end
                else
                    -- The bullet hit the edge
                    return true
                end
            end
        end
    end
    return false
end

-- Called before each animation frame
function newFrame()
    -- Launch new targets at random intervals and speeds
    if math.random() < 0.01 then
        createTarget()
    end

    -- Test for hits (all bullets against all targets)
    for i = bullets.numChildren, 1, -1 do
        local b = bullets[i]

        for j = targets.numChildren, 1, -1 do
            local t = targets[j]

            if hitTest( b, t ) then
                -- Count a hit
                -- ...

                -- Make an explosion
                -- ...

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
function initApp()
    -- Create display groups for active bullets, targets, and the turret
    bullets = display.newGroup()
    targets = display.newGroup()
    turret = display.newGroup()

    -- Create and position the turret
    turret:insert( display.newImage( "turret.png" ) ) 
    turret[1].aspect = turret[1].width / turret[1].height
    turret.x = X_CENTER
    turret.y = Y_MAX - turret[1].height / 2
    -- ...

    -- Add event listeners
    Runtime:addEventListener( "touch", touched )
    Runtime:addEventListener( "enterFrame", newFrame )
end

-- Start the game
initApp()