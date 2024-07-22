local math = require('math')
local bit = require('bit32')
local application = require('game')
local zeebo_fps = require('src/lib/engine/fps')
local zeebo_math = require('src/lib/engine/math')
local decorators = require('src/lib/engine/decorators')
local color = require('src/lib/object/color')
local game = require('src/lib/object/game')
local std = require('src/lib/object/std')
local fixture190 = ''

--! @short nclua:canvas
--! @li <http://www.telemidia.puc-rio.br/~francisco/nclua/referencia/canvas.html>
local canvas = canvas

--! @short nclua:event
--! @li <http://www.telemidia.puc-rio.br/~francisco/nclua/referencia/event.html>
local event = event

-- key mappings
local key_bindings={
    CURSOR_UP='up',
    CURSOR_DOWN='down',
    CURSOR_LEFT='left',
    CURSOR_RIGHT='right',
    RED='red',
    GREEN='green',
    YELLOW='yellow',
    BLUE='blue',
    F6='red',
    z='red',
    x='green',
    c='yellow',
    v='blue',
    ENTER='enter'
}

-- FPS
local fps_obj = {total=0,count=0,period=0,passed=0,delta=0,falls=0,drop=0}
local fps_limiter = {[100]=1, [60]=10, [30]=30, [20]=40, [15]=60, [10]=90}
local fps_dropper = {[100]=60, [60]=30, [30]=20, [20]=15, [15]=10, [10]=10}

-- Ginga?
_ENV = nil

local function std_draw_fps(x, y)
    canvas:attrColor('yellow')
    if game.fps_show >= 1 then
        canvas:drawRect('fill', x, y, 40, 24)
    end
    if game.fps_show >= 2 then
        canvas:drawRect('fill', x + 48, y, 40, 24)
    end
    canvas:attrColor('black')
    canvas:attrFont('Tiresias', 16)
    if game.fps_show >= 1 then
        canvas:drawText(x + 2, y, fps_obj.total)
    end
    if game.fps_show >= 1 then
        canvas:drawText(x + 50, y, game.fps_max)
    end
end

local function std_draw_color(color)
    local R = bit.band(bit.rshift(color, 24), 0xFF)
    local G = bit.band(bit.rshift(color, 16), 0xFF)
    local B = bit.band(bit.rshift(color, 8), 0xFF)
    local A = bit.band(bit.rshift(color, 0), 0xFF)
    canvas:attrColor(R, G, B, A)
end

local function std_draw_clear(color)
    std_draw_color(color)
    canvas:drawRect('fill', 0, 0, game.width, game.height)
end

local function std_draw_rect(a,b,c,d,e,f)
    if f and canvas.drawRoundRect then
        canvas:drawRoundRect(a,b,c,d,e,f)
        return
    end
    canvas:drawRect(a,b,c,d,e)
end

local function std_draw_text(x, y, text)
    if x and y then
        canvas:drawText(x, y, text)
    end
    return canvas:measureText(text or x)
end

local function std_draw_font(a,b)
    canvas:attrFont(a,b)
end

local function std_draw_line(x1, y1, x2, y2)
    canvas:drawLine(x1, y1, x2, y2)
end

local function std_game_exit()
    if application.callbacks.exit then
        application.callbacks.exit(std, game)
    end
    event.post({class="ncl", type="stop"})
end

local function event_loop(evt)
    if evt.class ~= 'key' then return end
    if not key_bindings[evt.key] then return end

    --! @li https://github.com/TeleMidia/ginga/issues/190
    if #fixture190 == 0 and evt.key ~= 'ENTER' then
        fixture190 = evt.type
    end

    if fixture190 == evt.type then
        std.key.press[key_bindings[evt.key]] = 1
    else
        std.key.press[key_bindings[evt.key]] = 0
    end
end

local function fixed_loop()
    -- internal clock 
    game.milis = event.uptime()
    game.fps = fps_obj.total
    game.dt = fps_obj.delta 
    if not zeebo_fps.counter(game.fps_max, fps_obj, game.milis) then
        game.fps_max = fps_dropper[game.fps_max]
    end

    -- game loop
    application.callbacks.loop(std, game)
    
    -- game render
    canvas:attrColor(0, 0, 0, 0)
    canvas:clear()
    application.callbacks.draw(std, game)
    std_draw_fps(8,8)
    canvas:flush()

    -- internal loop
    event.timer(fps_limiter[game.fps_max], fixed_loop)
end

local function setup(evt)
    if evt.class ~= 'ncl' or evt.action ~= 'start' then return end
    local w, h = canvas:attrSize()
    std.color=color
    std.math=zeebo_math
    std.math.random = math.random
    std.draw.clear=std_draw_clear
    std.draw.color=std_draw_color
    std.draw.rect=std_draw_rect
    std.draw.text=std_draw_text
    std.draw.font=std_draw_font
    std.draw.line=std_draw_line
    std.draw.poly=decorators.poly(0, nil, std_draw_line)
    std.game.reset=decorators.reset(application.callbacks, std, game)
    std.game.exit=std_game_exit
    game.width=w
    game.height=h
    game.fps_max = application.config and application.config.fps_max or 100
    game.fps_show = application.config and application.config.fps_show or 0
    fps_obj.drop_time = application.config and application.config.fps_time or 1
    fps_obj.drop_count = application.config and application.config.fps_drop or 2
    application.callbacks.init(std, game)
    event.register(event_loop)
    event.timer(1, fixed_loop)
    event.unregister(setup)
end

event.register(setup)
