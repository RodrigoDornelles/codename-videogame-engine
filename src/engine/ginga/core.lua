local mathstd = require('math')
local game = require('game')
local math = require('lib_math')
local decorators = require('decorators')
local canvas = canvas
local event = event
local game_obj = {meta={}, config={}, callbacks={}}
local std = {draw={},key={press={}},game={}}
local fixture190 = ''

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
local fps = require('lib_fps')
local fps_obj = {total=0,count=0,period=0,passed=0,delta=0,falls=0,drop=0}
local fps_limiter = {[100]=1, [60]=10, [30]=30, [20]=40, [15]=60, [10]=90}
local fps_dropper = {[100]=60, [60]=30, [30]=20, [20]=15, [15]=10, [10]=10}

-- Ginga?
_ENV = nil

local function std_draw_fps(x, y)
    canvas:attrColor('yellow')
    if game_obj.fps_show >= 1 then
        canvas:drawRect('fill', x, y, 40, 24)
    end
    if game_obj.fps_show >= 2 then
        canvas:drawRect('fill', x + 48, y, 40, 24)
    end
    canvas:attrColor('black')
    canvas:attrFont('Tiresias', 16)
    if game_obj.fps_show >= 1 then
        canvas:drawText(x + 2, y, fps_obj.total)
    end
    if game_obj.fps_show >= 1 then
        canvas:drawText(x + 50, y, game_obj.fps_max)
    end
end

local function std_draw_clear(color)
    canvas:attrColor(color)
    canvas:drawRect('fill', 0, 0, game_obj.width, game_obj.height)
end

local function std_draw_color(color)
    canvas:attrColor(color)
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

local function std_draw_circle(mode, x, y, radius)
    canvas:drawEllipse(mode, x, y, radius, radius)
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
    event.post({class="ncl", type="stop"})
end

local function event_loop(evt)
    if evt.class ~= 'key' then return end
    if not key_bindings[evt.key] then return end

    -- https://github.com/TeleMidia/ginga/issues/190
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
    game_obj.milis = event.uptime()
    game_obj.fps = fps_obj.total
    game_obj.dt = fps_obj.delta 
    if not fps.counter(game_obj.fps_max, fps_obj, game_obj.milis) then
        game_obj.fps_max = fps_dropper[game_obj.fps_max]
    end

    -- game loop
    game.callbacks.loop(std, game_obj)
    
    -- game render
    canvas:attrColor(0, 0, 0, 0)
    canvas:clear()
    game.callbacks.draw(std, game_obj)
    std_draw_fps(8,8)
    canvas:flush()

    -- internal loop
    event.timer(fps_limiter[game_obj.fps_max], fixed_loop)
end

local function setup(evt)
    if evt.class ~= 'ncl' or evt.action ~= 'start' then return end
    local w, h = canvas:attrSize()
    std.math=math
    std.math.random = mathstd.random
    std.draw.clear=std_draw_clear
    std.draw.color=std_draw_color
    std.draw.rect=std_draw_rect
    std.draw.text=std_draw_text
    std.draw.font=std_draw_font
    std.draw.line=std_draw_line
    std.draw.circle=std_draw_circle
    std.draw.poly=decorators.poly(0, nil, std_draw_line, std_draw_circle)
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
    game_obj.milis=0
    game_obj.fps=0
    game_obj.fps_max = game.config and game.config.fps_max or 100
    game_obj.fps_show = game.config and game.config.fps_max or 0
    fps_obj.drop_time = game.config and game.config.fps_time or 1
    fps_obj.drop_count = game.config and game.config.fps_drop or 2
    game.callbacks.init(std, game_obj)
    event.register(event_loop)
    event.timer(1, fixed_loop)
    event.unregister(setup)
end

event.register(setup)
