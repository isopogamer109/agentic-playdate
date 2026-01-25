--[[
    Basic Playdate Game Template

    Controls:
    - D-pad: Move
    - A: Action
    - B: Back/Cancel
]]

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

-- Game state
local playerX = 200
local playerY = 120
local playerSpeed = 3

function playdate.update()
    gfx.clear()

    -- Handle input
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        playerY = playerY - playerSpeed
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then
        playerY = playerY + playerSpeed
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        playerX = playerX - playerSpeed
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        playerX = playerX + playerSpeed
    end

    -- Keep on screen
    playerX = math.max(10, math.min(390, playerX))
    playerY = math.max(10, math.min(230, playerY))

    -- Draw player
    gfx.fillCircleAtPoint(playerX, playerY, 10)

    -- Draw position
    gfx.drawText("X:" .. playerX .. " Y:" .. playerY, 5, 5)

    playdate.timer.updateTimers()
end
