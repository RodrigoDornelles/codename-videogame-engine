local os = require('os')
local game = require('game')
local math = require('lib_math')
local decorators = require('decorators')
local game_obj = {}
local std = {draw={},key={press={}},game={}}
local started = false
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

local function std_draw_clear(color)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', 0, 0, game_obj.width, game_obj.height)
end

local function std_draw_color(color)
    local colors = {
        black = {0, 0, 0},
        white = {1, 1, 1},
        yellow = {1, 1, 0},
        green = {0, 1, 0},
        red= {1, 0, 0}
    }
    love.graphics.setColor(colors[color][1], colors[color][2], colors[color][3])
end

local function std_draw_rect(a,b,c,d,e,f)
    love.graphics.rectangle(a, b, c, d, e)
end

local function std_draw_text(x, y, text)
    if x and y then
        love.graphics.print(text, x, y)
    end
    return love.graphics.getFont():getWidth(text or x)
end

local function std_draw_circle(mode, x, y, r)
    love.graphics.circle(mode, x, y, r/2)
end

local function std_draw_line(x1, y1, x2, y2)
    love.graphics.line(x1, y1, x2, y2)
end

local function std_draw_font(a,b)
    -- TODO: not must be called in update 
end

local function std_game_reset()
    if game.callbacks.exit then
        game.callbacks.exit(std, game_obj)
    end
    if game.callbacks.init then
        game.callbacks.init(std, game_obj)
    end
end

local function std_game_exit()
    if game.callbacks.exit then
        game.callbacks.exit(std, game_obj)
    end
    love.event.quit()
end

function love.draw()
    game.callbacks.draw(std, game_obj)
end

function love.update(dt)
    game_obj.dt = dt * 1000
    game_obj.milis = love.timer.getTime() * 1000
    game_obj.fps = love.timer.getFPS()
    game.callbacks.loop(std, game_obj)
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

function love.load()
    local w, h = love.graphics.getDimensions()
    std.math=math
    std.math.random = love.math.random
    std.draw.clear=std_draw_clear
    std.draw.color=std_draw_color
    std.draw.rect=std_draw_rect
    std.draw.text=std_draw_text
    std.draw.font=std_draw_font
    std.draw.line=std_draw_line
    std.draw.circle=std_draw_circle
    std.draw.poly=decorators.poly(0, love.graphics.polygon, std_draw_circle)
    std.key.press.up=0
    std.key.press.down=0
    std.key.press.left=0
    std.key.press.right=0
    std.key.press.red=0
    std.key.press.green=0
    std.key.press.yellow=0
    std.key.press.blue=0
    std.key.press.enter=0
    std.game.reset=std_game_reset
    std.game.exit=std_game_exit
    game_obj.width=w
    game_obj.height=h
    game_obj.dt = 0
    love.window.setTitle(game.meta.title..' - '..game.meta.version)
    game.callbacks.init(std, game_obj)
end
