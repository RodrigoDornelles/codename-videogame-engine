local os = require('os')
local zeebo_math = require('src/lib/engine/math')
local zeebo_module = require('src/lib/engine/module')
local decorators = require('src/lib/engine/decorators')
local zeebo_args = require('src/lib/common/args')
local color = require('src/lib/object/color')
local game = require('src/lib/object/game')
local std = require('src/lib/object/std')
local key_bindings = {
    up='up',
    left='left',
    right='right',
    down='down',
    z='red',
    x='green',
    c='yellow',
    v='blue',
    ['return']='enter'
}

local modes = {
    [true] = {
        [0] = true,
        [1] = false
    },
    [false] = {
        [0] = 'fill',
        [1] = 'line'
    }
}

local application = nil

local function std_draw_color(color)
    local DIV = love.wiimote and 1 or 255
    local R = bit.band(bit.rshift(color, 24), 0xFF)/DIV
    local G = bit.band(bit.rshift(color, 16), 0xFF)/DIV
    local B = bit.band(bit.rshift(color, 8), 0xFF)/DIV
    local A = bit.band(bit.rshift(color, 0), 0xFF)/DIV
    love.graphics.setColor(R, G, B, A)
end

local function std_draw_clear(color)
    std_draw_color(color)
    love.graphics.rectangle(modes[love.wiimote ~= nil][0], 0, 0, game.width, game.height)
end

local function std_draw_rect(a,b,c,d,e,f)
    love.graphics.rectangle(modes[love.wiimote ~= nil][a], b, c, d, e)
end

local function std_draw_text(x, y, text)
    if love.wiimote then return 32 end -- TODO support WII
    if x and y then
        love.graphics.print(text, x, y)
    end
    return love.graphics.getFont():getWidth(text or x)
end

local function std_draw_line(x1, y1, x2, y2)
    love.graphics.line(x1, y1, x2, y2)
end

local function std_draw_font(a,b)
    -- TODO: not must be called in update 
end

local function std_game_exit()
    if application.callbacks.exit then
        application.callbacks.exit(std, game)
    end
    love.event.quit()
end

function love.draw()
    application.callbacks.draw(std, game)
end

function love.update(dt)
    game.dt = dt * 1000
    game.milis = love.timer.getTime() * 1000
    game.fps = love.timer.getFPS()
    application.callbacks.loop(std, game)
end

function love.keypressed(key)
    if key_bindings[key] then
        std.key.press[key_bindings[key]] = 1
    end
end

function love.keyreleased(key)
    if key_bindings[key] then
        std.key.press[key_bindings[key]] = 0
    end
end

function love.resize(w, h)
    game.width = w
    game.height = h
end

function love.load(args)
    local w, h = love.graphics.getDimensions()
    local screen = args and zeebo_args.get(args, 'screen')
    local game_title = zeebo_args.param(arg, {'screen'}, 2)
    application = zeebo_module.loadgame(game_title)

    if not application then
        error('game not found!')
    end
    if screen then
        w, h = screen:match('(%d+)x(%d+)')
        w, h = tonumber(w), tonumber(h)
        love.window.setMode(w, h, {resizable=true})
    end
    std.color = color
    std.math=zeebo_math
    std.math.random = love.math.random
    std.draw.clear=std_draw_clear
    std.draw.color=std_draw_color
    std.draw.rect=std_draw_rect
    std.draw.text=std_draw_text
    std.draw.font=std_draw_font
    std.draw.line=std_draw_line
    std.draw.poly=decorators.poly(0, love.graphics.polygon)
    std.game.reset=decorators.reset(application.callbacks, std, game)
    std.game.exit=std_game_exit
    game.width=w
    game.height=h
    if love.window and love.window.setTitle then
        love.window.setTitle(application.meta.title..' - '..application.meta.version)
    end
    application.callbacks.init(std, game)
end