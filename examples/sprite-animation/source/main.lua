--[[
    Sprite Animation Example
    Demonstrates frame-based animation using imagetables
]]

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animation"

local gfx <const> = playdate.graphics

-- Constants
local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240
local PLAYER_SPEED <const> = 2
local FRAME_DURATION <const> = 100  -- ms per frame

-- Animation state
local playerX = SCREEN_WIDTH / 2
local playerY = SCREEN_HEIGHT / 2
local currentFrame = 1
local frameTimer = 0
local numFrames = 4
local isMoving = false
local facingRight = true

-- Generate animation frames (since we don't have actual images)
local frames = {}
for i = 1, numFrames do
    local img = gfx.image.new(24, 24)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        -- Draw a simple animated character (circle with legs)
        gfx.fillCircleAtPoint(12, 8, 7)  -- head
        -- Legs alternate based on frame
        if i == 1 or i == 3 then
            gfx.drawLine(8, 16, 6, 24)   -- left leg
            gfx.drawLine(16, 16, 18, 24) -- right leg
        else
            gfx.drawLine(8, 16, 10, 24)  -- left leg
            gfx.drawLine(16, 16, 14, 24) -- right leg
        end
    gfx.popContext()
    frames[i] = img
end

function playdate.update()
    gfx.clear()

    -- Handle input
    local dx, dy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonUp) then dy = -PLAYER_SPEED end
    if playdate.buttonIsPressed(playdate.kButtonDown) then dy = PLAYER_SPEED end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        dx = -PLAYER_SPEED
        facingRight = false
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        dx = PLAYER_SPEED
        facingRight = true
    end

    isMoving = (dx ~= 0 or dy ~= 0)

    -- Update position
    playerX = math.max(12, math.min(SCREEN_WIDTH - 12, playerX + dx))
    playerY = math.max(12, math.min(SCREEN_HEIGHT - 12, playerY + dy))

    -- Update animation frame
    if isMoving then
        frameTimer = frameTimer + playdate.getElapsedTime() * 1000
        if frameTimer >= FRAME_DURATION then
            frameTimer = 0
            currentFrame = currentFrame + 1
            if currentFrame > numFrames then
                currentFrame = 1
            end
        end
    else
        currentFrame = 1
        frameTimer = 0
    end
    playdate.resetElapsedTime()

    -- Draw player
    local img = frames[currentFrame]
    if facingRight then
        img:draw(playerX - 12, playerY - 12)
    else
        img:draw(playerX - 12, playerY - 12, gfx.kImageFlippedX)
    end

    -- Draw info
    gfx.drawText("Sprite Animation Demo", 5, 5)
    gfx.drawText("Frame: " .. currentFrame .. "/" .. numFrames, 5, 25)
    gfx.drawText("D-pad to move", 5, SCREEN_HEIGHT - 20)

    playdate.timer.updateTimers()
end
