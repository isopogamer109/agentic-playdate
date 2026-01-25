--[[
    Hello World Example
    The simplest possible Playdate game
]]

import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

function playdate.update()
    gfx.clear()
    gfx.drawTextAligned("Hello, Playdate!", 200, 110, kTextAlignment.center)
    gfx.drawTextAligned("Press any button!", 200, 130, kTextAlignment.center)

    if playdate.buttonJustPressed(playdate.kButtonA) then
        print("A pressed!")
    end
end
