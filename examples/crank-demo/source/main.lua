--[[
    Crank Demo Example
    Demonstrates all crank-related APIs
]]

import "CoreLibs/graphics"
import "CoreLibs/crank"

local gfx <const> = playdate.graphics

local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240
local CENTER_X <const> = 200
local CENTER_Y <const> = 120

function playdate.update()
    gfx.clear()

    -- Crank state
    local isDocked = playdate.isCrankDocked()
    local position = playdate.getCrankPosition()  -- 0-360
    local change = playdate.getCrankChange()      -- delta
    local ticks = playdate.getCrankTicks(12)      -- 12 ticks per revolution

    -- Draw dial
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(CENTER_X, CENTER_Y, 60)

    -- Draw pointer based on crank position
    local rad = math.rad(position - 90)
    local pointerX = CENTER_X + math.cos(rad) * 50
    local pointerY = CENTER_Y + math.sin(rad) * 50
    gfx.fillCircleAtPoint(pointerX, pointerY, 8)
    gfx.drawLine(CENTER_X, CENTER_Y, pointerX, pointerY)

    -- Draw info
    gfx.drawText("Crank Demo", 5, 5)
    gfx.drawText("Position: " .. math.floor(position) .. "°", 5, 30)
    gfx.drawText("Change: " .. string.format("%.1f", change), 5, 50)
    gfx.drawText("Ticks: " .. ticks, 5, 70)

    if isDocked then
        gfx.drawTextAligned("Crank is DOCKED", CENTER_X, SCREEN_HEIGHT - 30, kTextAlignment.center)
        gfx.drawTextAligned("Extend it to play!", CENTER_X, SCREEN_HEIGHT - 15, kTextAlignment.center)
    else
        gfx.drawTextAligned("Spin the crank!", CENTER_X, SCREEN_HEIGHT - 20, kTextAlignment.center)
    end
end

function playdate.crankDocked()
    print("Crank was docked")
end

function playdate.crankUndocked()
    print("Crank was undocked")
end
