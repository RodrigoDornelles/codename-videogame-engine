local os = require('os')
local zeebo_module = require('src/lib/engine/module')
local zeebo_args = require('src/lib/common/args')
local engine_game = require('src/lib/engine/game')
local engine_math = require('src/lib/engine/math')
local engine_draw = require('src/engine/core/love/draw')
local engine_keys = require('src/engine/core/love/keys')
local engine_loop = require('src/engine/core/love/loop')
local engine_memory = require('src/lib/engine/memory')
local engine_color = require('src/lib/object/color')
local engine_http = require('src/lib/engine/http')
local engine_i18n = require('src/lib/engine/i18n')
local engine_encoder = require('src/lib/engine/encoder')
local engine_draw_fps = require('src/lib/draw/fps')
local engine_draw_poly = require('src/lib/draw/poly')
local protocol_curl_love = require('src/lib/protocol/http_curl_love')
local library_csv = require('src/third_party/csv/rodrigodornelles')
local library_json = require('src/third_party/json/rxi')
local util_lua = require('src/lib/util/lua')
local game = require('src/lib/object/game')
local std = require('src/lib/object/std')

function love.load(args)
    local w, h = love.graphics.getDimensions()
    local screen = args and zeebo_args.get(args, 'screen')
    local game_title = zeebo_args.param(arg, {'screen'}, 2)
    local application = zeebo_module.loadgame(game_title)
    local polygons = {
        triangle=engine_draw.triangle,
        poly=love.graphics.polygon,
        modes={'fill', 'line', 'line'}
    }

    if screen then
        w, h = screen:match('(%d+)x(%d+)')
        w, h = tonumber(w), tonumber(h)
        love.window.setMode(w, h, {resizable=true})
    end
    if not application then
        error('game not found!')
    end
    
    zeebo_module.require(std, game, application)
        :package('@game', engine_game, love.event.quit)
        :package('@math', engine_math)
        :package('@draw', engine_draw)
        :package('@keys', engine_keys)
        :package('@loop', engine_loop)
        :package('@color', engine_color)
        :package('@draw.fps', engine_draw_fps)
        :package('@draw.poly', engine_draw_poly, polygons)
        :package('@memory', engine_memory)
        :package('load', zeebo_module.load)
        :package('math', engine_math.clib)
        :package('math.random', engine_math.clib_random)
        :package('http', engine_http, protocol_curl_love)
        :package('csv', engine_encoder, library_csv)
        :package('json', engine_encoder, library_json)
        :package('i18n', engine_i18n, util_lua.get_sys_lang)
        :register(function(listener)
            love.update = listener('loop')
            love.draw = listener('draw')
            love.keypressed = listener('keydown')
            love.keyreleased = listener('keyup')
        end)
        :run()

    game.width, game.height = w, h
    game.fps_max = application.config and application.config.fps_max or 100
    game.fps_show = application.config and application.config.fps_show or 0
    love.window.setTitle(application.meta.title..' - '..application.meta.version)
    application.callbacks.init(std, game)
end
