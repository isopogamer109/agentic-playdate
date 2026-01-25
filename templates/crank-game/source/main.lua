--[[
    Crank-Based Game Template

    Controls:
    - Crank: Primary control (rotation)
    - A: Action
    - B: Back/Cancel
]]

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

local gfx <const> = playdate.graphics

-- Constants
local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240
local CENTER_X <const> = SCREEN_WIDTH / 2
local CENTER_Y <const> = SCREEN_HEIGHT / 2

-- Game state
local crankAngle = 0
local score = 0
local targetAngle = 45

-- Spawn new target
local function newTarget()
    targetAngle = math.random(0, 359)
end

function playdate.update()
    gfx.clear()

    -- Get crank input
    crankAngle = playdate.getCrankPosition()

    -- Check if player matched the target (within 10 degrees)
    local diff = math.abs(crankAngle - targetAngle)
    if diff > 180 then diff = 360 - diff end

    if diff < 10 and playdate.buttonJustPressed(playdate.kButtonA) then
        score = score + 1
        newTarget()
    end

    -- Draw target indicator
    gfx.setColor(gfx.kColorBlack)
    local targetRad = math.rad(targetAngle - 90)
    local targetX = CENTER_X + math.cos(targetRad) * 80
    local targetY = CENTER_Y + math.sin(targetRad) * 80
    gfx.drawCircleAtPoint(targetX, targetY, 15)

    -- Draw player indicator (filled when close to target)
    local playerRad = math.rad(crankAngle - 90)
    local playerX = CENTER_X + math.cos(playerRad) * 80
    local playerY = CENTER_Y + math.sin(playerRad) * 80

    if diff < 10 then
        gfx.fillCircleAtPoint(playerX, playerY, 12)
    else
        gfx.fillCircleAtPoint(playerX, playerY, 8)
    end

    -- Draw center
    gfx.drawCircleAtPoint(CENTER_X, CENTER_Y, 5)

    -- Draw UI
    gfx.drawText("Score: " .. score, 5, 5)
    gfx.drawText("Crank: " .. math.floor(crankAngle) .. "°", 5, 25)

    if playdate.isCrankDocked() then
        gfx.drawText("Extend crank to play!", CENTER_X - 80, SCREEN_HEIGHT - 25)
    else
        gfx.drawText("Align & press A!", CENTER_X - 60, SCREEN_HEIGHT - 25)
    end

    playdate.timer.updateTimers()
end

-- Crank dock callbacks
function playdate.crankDocked()
    print("Crank docked - game paused")
end

function playdate.crankUndocked()
    print("Crank undocked - game active")
end

-- Initialize
newTarget()
