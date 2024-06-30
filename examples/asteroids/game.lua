--! @par Game FSM
--! @startuml
--! hide empty description
--! state 1 as "menu"
--! state 2 as "credits"
--! state 3 as "game_spawn"
--! state 4 as "game_play"
--! state 5 as "game_player_dead"
--! state 6 as "game_player_win"
--! state 7 as "game_over"
--! state 8 as "menu"
--! 
--! [*] -> 1
--! 1 --> 2
--! 1 --> 3
--! 2 --> 1
--! 3 --> 4
--! 4 --> 5
--! 4 --> 6
--! 5 --> 3
--! 5 --> 7
--! 6 --> 3
--! 7 --> [*]
--! 
--! 4 -> 8: pause
--! 8 -> 4: resume
--! @enduml

local math = require('math')

local function asteroid_fragments(game, size, level)
    -- level 1,2,3
    if size == game.asteroid_small_size and level <=3 then return 0, -1 end
    if size == game.asteroid_mid_size and level <= 3 then return 2, game.asteroid_small_size end				
    if size == game.asteroid_large_size and level <= 3 then return 1, game.asteroid_mid_size end
    -- level 4,5,6
    if size == game.asteroid_small_size and level <= 6 then return 1, game.asteroid_mini_size end
    if size == game.asteroid_mid_size and level <= 6 then return 2, game.asteroid_small_size end
    if size == game.asteroid_large_size and level <= 6 then return 1, game.asteroid_mid_size end
    -- level 7,8,9c
    if size == game.asteroid_small_size and level <= 9 then return 1, game.asteroid_mini_size end
    if size ==  game.asteroid_mid_size and level <= 9 then return 3, game.asteroid_small_size end
    if size == game.asteroid_large_size and level <= 9 then return 1,  game.asteroid_mid_size end
    -- level 10... all asteroids
    if size == game.asteroid_small_size then return 1, game.asteroid_mini_size end
    if size == game.asteroid_mid_size then return 3, game.asteroid_small_size end
    if size == game.asteroid_large_size then return 2, game.asteroid_mid_size end
    return 0, -1
end

local function asteroid_nest(std, game, x, y, id)
    local index = 1
    while index < #game.asteroid_size do
        if index ~= id then
            local distance = std.math.dis(x, y, game.asteroid_pos_x[index], game.asteroid_pos_y[index])
            if (distance - 3) <= (game.asteroid_size[index] / 2) then
                return true
            end
        end
        index = index + 1
    end
    return false
end

local function asteroids_rain(std, game)
    local index = 1
    local n1 = 0.5 * math.min(game.level/3, 1)
    local n2 = 1.0 * math.min(game.level/3, 1)
    local n3 = 2.0 * math.min(game.level/3, 1)
    local n4 = 2.5 * math.min(game.level/3, 1)
    local hspeed = {-n1, 0, 0, 0, 0, 0, n1}
    local vspeed = {-n4, -n3, -n2, n2, n3, n4}
    local middle_left = game.width/4
    local middle_right = game.width/4 * 3

    while index <= game.asteroids_max and index <= 10 do
        repeat
            local success = true
            game.asteroid_size[index] = game.asteroid_large_size
            game.asteroid_pos_x[index] = std.math.random(1, game.width)
            game.asteroid_pos_y[index] = std.math.random(1, game.height)
            game.asteroid_spd_x[index] = hspeed[std.math.random(1, #hspeed)]
            game.asteroid_spd_y[index] = vspeed[std.math.random(1, #vspeed)]

            if game.asteroid_pos_x[index] > middle_left and game.asteroid_pos_x[index] < middle_right then
                success = false
            end

            if asteroid_nest(std, game, game.asteroid_pos_x[index], game.asteroid_pos_x[index], index) then
                success = false
            end
        until success
        index = index + 1
    end
end

local function asteroid_destroy(std, game, id)
    local index = 1
    local hspeed = {-1, 1}
    local vspeed = {-2, -1, 1, 2}
    local asteroids = #game.asteroid_size
    local original_size = game.asteroid_size[id]
    local fragments, size = asteroid_fragments(game, original_size, game.level)
    
    game.asteroid_size[id] = -1

    while index <= fragments do
        game.asteroid_size[asteroids + index] = size
        game.asteroid_pos_x[asteroids + index] = game.asteroid_pos_x[id]
        game.asteroid_pos_y[asteroids + index] = game.asteroid_pos_y[id]
        game.asteroid_spd_x[asteroids + index] = hspeed[std.math.random(1, #hspeed)] * math.min(game.level/5, 1)
        game.asteroid_spd_y[asteroids + index] = vspeed[std.math.random(1, #vspeed)] * math.min(game.level/5, 1)
        index = index + 1
    end

    return original_size * fragments
end

local function init(std, game)
    -- game
    game.state = 1
    game.lifes = 3
    game.level = 1
    game.score = 0
    game.boost = 0.12
    game.highscore = 0
    game.speed_max = 5
    game.asteroids_max = 10
    game.asteroids_count = 0
    -- player
    game.player_pos_x = game.width/2
    game.player_pos_y = game.height/2
    game.player_spd_x = 0
    game.player_spd_y = 0
    game.player_angle = 0
    game.player_last_teleport = 0
    -- cannon
    game.laser_enabled = false
    game.laser_pos_x1 = 0
    game.laser_pos_y1 = 0
    game.laser_pos_x2 = 0
    game.laser_pos_y2 = 0
    game.laser_last_fire = 0
    game.laser_time_fire = 50
    game.laser_time_recharge = 300
    game.laser_distance_fire = 300
    -- asteroids
    game.asteroid_pos_x = {}
    game.asteroid_pos_y = {}
    game.asteroid_spd_x = {}
    game.asteroid_spd_y = {}
    game.asteroid_size = {}
    -- polys
    game.asteroid_large = {27, 0, 27, 15, 15, 12, 0, 30, 18, 39, 9, 48, 15, 60, 30, 66, 48, 66, 57, 57, 60, 51, 66, 42, 66, 33, 54, 12, 27, 0}
    game.asteroid_mid = {6, 0, 0, 21, 9, 33, 9, 48, 24, 51, 36, 45, 48, 42, 36, 12, 48, 3, 18, 0, 6, 0}
    game.asteroid_small = {3, 0, 0, 3, 3, 9, 3, 12, 0, 18, 6, 21, 12, 21, 18, 18, 21, 15, 21, 3, 12, 3, 9, 6, 3, 0}
    game.asteroid_mini = {6, 0, 6, 6, 0, 6, 0, 12, 3, 18, 6, 18, 6, 15, 15, 15, 18, 9, 12, 6, 12, 0, 6, 0}
    game.spaceship = {-2,3, 0,-2, 2,3}
    -- sizes
    game.asteroid_large_size = std.math.max(game.asteroid_large)
    game.asteroid_mid_size = std.math.max(game.asteroid_mid)
    game.asteroid_small_size = std.math.max(game.asteroid_small)
    game.asteroid_mini_size = std.math.max(game.asteroid_mini)
    -- start
    asteroids_rain(std, game)
end

local function loop(std, game)
    -- player move
    game.player_angle = std.math.cycle(game.player_angle + (std.key.press.right - std.key.press.left) * 0.1, math.pi * 2) * math.pi * 2
    game.player_pos_x = game.player_pos_x + (game.player_spd_x/16 * game.dt)
    game.player_pos_y = game.player_pos_y + (game.player_spd_y/16 * game.dt)
    if std.key.press.up == 0 and (std.math.abs(game.player_spd_x) + std.math.abs(game.player_spd_y)) < 0.45 then
        game.player_spd_x = 0
        game.player_spd_y = 0
    end
    if std.key.press.up == 1 then
        game.player_spd_x = game.player_spd_x + (game.boost * math.cos(game.player_angle - math.pi/2))
        game.player_spd_y = game.player_spd_y + (game.boost * math.sin(game.player_angle - math.pi/2))
        local max_spd_x = std.math.abs(game.speed_max * math.cos(game.player_angle - math.pi/2))
        local max_spd_y = std.math.abs(game.speed_max * math.sin(game.player_angle - math.pi/2))
        game.player_spd_x = std.math.clamp(game.player_spd_x, -max_spd_x, max_spd_x) 
        game.player_spd_y = std.math.clamp(game.player_spd_y, -max_spd_y, max_spd_y)
    end
    if game.player_pos_y < 3 then
        game.player_pos_y = game.height
    end
    if game.player_pos_x < 3 then
        game.player_pos_x = game.width
    end
    if game.player_pos_y > game.height then
        game.player_pos_y = 3
    end
    if game.player_pos_x > game.width then
        game.player_pos_x = 3
    end
    -- player teleport
    if std.key.press.down == 1 and game.milis > game.player_last_teleport + 1000 then
        game.player_last_teleport = game.milis
        game.player_spd_x = 0
        game.player_spd_y = 0
        repeat
            game.player_pos_x = std.math.random(1, game.width)
            game.player_pos_y = std.math.random(1, game.height)
        until not asteroid_nest(std, game, game.player_pos_x, game.player_pos_y, -1)
    end
    -- player shoot
    if not game.laser_enabled and (std.key.press.red == 1 or std.key.press.enter == 1) then
        local index = 1
        local asteroids = #game.asteroid_size
        local sin = math.cos(game.player_angle - math.pi/2)
        local cos = math.sin(game.player_angle - math.pi/2)
        local laser_fake_x = game.player_pos_x - (game.laser_distance_fire * sin * 2)
        local laser_fake_y = game.player_pos_y - (game.laser_distance_fire * cos * 2)
        game.laser_pos_x2 = game.player_pos_x + (game.laser_distance_fire * sin)
        game.laser_pos_y2 = game.player_pos_y + (game.laser_distance_fire * cos)
        game.laser_pos_x1 = game.player_pos_x + (12 * sin)
        game.laser_pos_y1 = game.player_pos_y + (12 * cos)
        game.laser_last_fire = game.milis
        game.laser_enabled = true
        while index <= asteroids do
            if game.asteroid_size[index] ~= -1 then
                local size = game.asteroid_size[index]/2
                local x = game.asteroid_pos_x[index] + size
                local y = game.asteroid_pos_y[index] + size
                local dis_p1 = std.math.dis(game.laser_pos_x1, game.laser_pos_y1, x,y)
                local dis_p2 = std.math.dis(game.laser_pos_x2, game.laser_pos_y2, x,y)
                local dis_fake = std.math.dis(laser_fake_x, laser_fake_y, x,y)
                local intersect = std.math.intersect_line_circle(game.laser_pos_x1, game.laser_pos_y1, game.laser_pos_x2, game.laser_pos_y2, x, y, size*2)
                if intersect and dis_p2 < dis_fake and dis_p1 < game.laser_distance_fire then
                    game.score = game.score + asteroid_destroy(std, game, index)
                end
            end
            index = index + 1
        end
    end
    if game.laser_enabled and game.milis > game.laser_last_fire + game.laser_time_recharge then
        game.laser_enabled = false
    end
    -- asteroids move
    local index = 1
    game.asteroids_count = 0
    while index <= #game.asteroid_size do
        if game.asteroid_size[index] ~= -1 then
            game.asteroids_count = game.asteroids_count + 1
            game.asteroid_pos_x[index] = game.asteroid_pos_x[index] + game.asteroid_spd_x[index]
            game.asteroid_pos_y[index] = game.asteroid_pos_y[index] + game.asteroid_spd_y[index]
            if game.asteroid_pos_y[index] < 1 then
                game.asteroid_pos_y[index] = game.height
            end
            if game.asteroid_pos_x[index] < 1 then
                game.asteroid_pos_x[index] = game.width
            end
            if game.asteroid_pos_y[index] > game.height then
                game.asteroid_pos_y[index] = 1
            end
            if game.asteroid_pos_x[index] > game.width then
                game.asteroid_pos_x[index] = 1
            end
        end
        index = index + 1
    end
end

local function draw(std, game)
    std.draw.clear('black')
    -- draw asteroids
    std.draw.color('white')
    local index = 1
    while index <= #game.asteroid_size do
        if game.asteroid_size[index] ~= -1 then
            if game.asteroid_size[index] == game.asteroid_large_size then
                std.draw.poly('fill', game.asteroid_large, game.asteroid_pos_x[index], game.asteroid_pos_y[index])
            elseif game.asteroid_size[index] == game.asteroid_mid_size then
                std.draw.poly('fill', game.asteroid_mid, game.asteroid_pos_x[index], game.asteroid_pos_y[index])
            elseif game.asteroid_size[index] == game.asteroid_small_size then
                std.draw.poly('fill', game.asteroid_small, game.asteroid_pos_x[index], game.asteroid_pos_y[index])
            else
                std.draw.poly('fill', game.asteroid_mini, game.asteroid_pos_x[index], game.asteroid_pos_y[index])
            end
        end
        index = index + 1
    end
    -- draw player
    std.draw.color('yellow')
    std.draw.poly('fill', game.spaceship, game.player_pos_x, game.player_pos_y, 3, game.player_angle)
    -- laser bean
    std.draw.color('green')
    if game.laser_enabled and game.milis < game.laser_last_fire + game.laser_time_fire then
        std.draw.line(game.laser_pos_x1, game.laser_pos_y1, game.laser_pos_x2, game.laser_pos_y2)
    end
    -- draw gui
    local w = game.width/16
    std.draw.color('black')  
    std.draw.rect('fill', 0, 0, game.width, 32)
    std.draw.color('white')
    s=std.draw.text(8, 8, 'lifes:')
    std.draw.text(8+s, 8, game.lifes)
    s=std.draw.text(w*2, 8, 'level:')
    std.draw.text(w*2+s, 8, game.level)
    s=std.draw.text(w*4, 8, 'asteroids:')
    std.draw.text(w*4+s, 8, game.asteroids_count)
    s=std.draw.text(w*9, 8, 'score:')
    std.draw.text(w*9+s, 8, game.score)
    s=std.draw.text(w*12, 8, 'highscore:')
    std.draw.text(w*12+s, 8, game.highscore)
end

local function exit(std, game)
    game.asteroid_pos_x = nil
    game.asteroid_pos_y = nil
    game.asteroid_spd_x = nil
    game.asteroid_spd_y = nil
    game.asteroid_size = nil
    game.asteroid_large = nil
    game.asteroid_mid =  nil
    game.asteroid_small = nil
    game.asteroid_mini = nil
end

local P = {
    meta={
        title='AsteroidsTV',
        description='similar to the original but with lasers because televisions may have limited hardware.',
        version='1.0.0'
    },
    callbacks={
        init=init,
        loop=loop,
        draw=draw,
        exit=exit
    }
}

return P;
