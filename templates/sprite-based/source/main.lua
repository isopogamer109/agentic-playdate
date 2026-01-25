--[[
    Sprite-Based Game Template

    Demonstrates:
    - Sprite creation and management
    - Collision detection
    - Score tracking

    Controls:
    - D-pad: Move player
    - A: Dash/Speed boost
]]

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

-- Constants
local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240
local PLAYER_SPEED <const> = 3
local BOOST_SPEED <const> = 6

-- Create player sprite class
class('Player').extends(gfx.sprite)

function Player:init(x, y)
    Player.super.init(self)

    -- Create player image (simple rectangle for now)
    local img = gfx.image.new(20, 20)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, 20, 20)
    gfx.popContext()

    self:setImage(img)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, 20, 20)
    self:add()
end

function Player:update()
    local speed = PLAYER_SPEED
    if playdate.buttonIsPressed(playdate.kButtonA) then
        speed = BOOST_SPEED
    end

    local dx, dy = 0, 0

    if playdate.buttonIsPressed(playdate.kButtonUp) then dy = -speed end
    if playdate.buttonIsPressed(playdate.kButtonDown) then dy = speed end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then dx = -speed end
    if playdate.buttonIsPressed(playdate.kButtonRight) then dx = speed end

    if dx ~= 0 or dy ~= 0 then
        local newX = math.max(10, math.min(SCREEN_WIDTH - 10, self.x + dx))
        local newY = math.max(10, math.min(SCREEN_HEIGHT - 10, self.y + dy))
        self:moveTo(newX, newY)
    end
end

-- Create collectible sprite class
class('Collectible').extends(gfx.sprite)

function Collectible:init()
    Collectible.super.init(self)

    local img = gfx.image.new(16, 16)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(8, 8, 7)
    gfx.popContext()

    self:setImage(img)
    self:randomPosition()
    self:setCollideRect(0, 0, 16, 16)
    self:add()
end

function Collectible:randomPosition()
    local x = math.random(20, SCREEN_WIDTH - 20)
    local y = math.random(40, SCREEN_HEIGHT - 20)
    self:moveTo(x, y)
end

-- Game state
local player = nil
local collectibles = {}
local score = 0
local NUM_COLLECTIBLES = 5

local function setup()
    -- Create player
    player = Player(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

    -- Create collectibles
    for i = 1, NUM_COLLECTIBLES do
        collectibles[i] = Collectible()
    end
end

function playdate.update()
    -- Clear and update sprites
    gfx.clear()
    gfx.sprite.update()

    -- Check collisions
    local collisions = player:overlappingSprites()
    for _, sprite in ipairs(collisions) do
        if sprite:isa(Collectible) then
            score = score + 10
            sprite:randomPosition()
        end
    end

    -- Draw UI
    gfx.drawText("Score: " .. score, 5, 5)

    playdate.timer.updateTimers()
end

-- Initialize
setup()
