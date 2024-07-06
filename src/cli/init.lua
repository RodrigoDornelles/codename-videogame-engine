local os = require('os')
local zeebo_args = require('src/shared/args')

--! @cond
local run = zeebo_args.has(arg, 'run')
local coverage = zeebo_args.has(arg, 'coverage')
local game = zeebo_args.get(arg, 'game', './examples/pong')
local core = zeebo_args.get(arg, 'core', 'ginga')
local screen = zeebo_args.get(arg, 'screen', '1280x720')
local command = zeebo_args.param(arg, {'game', 'core', 'screen'}, 1, 'help')

if command == 'test-self' then
    coverage = coverage and '-lluacov' or ''
    local ok = os.execute('lua '..coverage..' ./tests/*.lua')
    if #coverage > 0 then
        os.execute('luacov src')
    end
    if not ok then
        os.exit(1)
    end
elseif command == 'build' then
    -- clean dist
    os.execute('mkdir -p ./dist/')
    os.execute('rm -Rf ./dist/*')

    -- move game
    os.execute('cp '..game..'/game.lua dist/game.lua')

    -- move common lib
    os.execute('cp src/lib/common/*.lua dist')
    os.execute('cp src/object/application.lua dist/src_object_application.lua')
    os.execute('cp src/object/game.lua dist/src_object_game.lua')
    os.execute('cp src/object/std.lua dist/src_object_std.lua')
    os.execute('cp src/shared/*.lua dist')

    -- move engine
    if core == 'ginga' then
        os.execute('cp src/lib/ginga/main.ncl dist/main.ncl')
        os.execute('cp src/lib/ginga/core.lua dist/main.lua')
    elseif core == 'repl' then
        os.execute('cp src/lib/repl/core.lua dist/main.lua')
    elseif core == 'love' or core == 'love2d' then
        os.execute('cp src/lib/love2d/core.lua dist/main.lua')
    else
        error('this core is dont supported!')
    end

    -- post execute game
    if run then
        if core == 'ginga' then
            os.execute('ginga ./dist/main.ncl -s '..screen)
        elseif core == 'repl' then
            os.execute('lua dist/main.lua')
        elseif core == 'love' or core == 'love2d' then
            os.execute('love dist --screen '..screen)
        end
    end
else
    print('command not found: '..command)
    os.exit(1)
end

--! @endcond
