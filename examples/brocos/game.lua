--! state 0 as "menu"
--! state 1 as "game"
--! state 2 as "check matches"
--! state 3 as "show matches"
--! state 4 as "remove matched"
--! state 10 as "pause"

--! 0 --> 1
--! 1 --> 2
--! 1 --> 10
--! 2 --> 3
--! 3 --> 4
--! 4 --> 1
--! 10 --> 0
--! 10 --> 1

-- Color Table
local colorTable = {}
colorTable.background = 0x424242FF
colorTable.backgroundBoard = 0xC0C0C0FF
colorTable.backgroundAlternate = 0x800000FF
colorTable.gold = 0xFFD700FF
colorTable.diamond = 0xB9F2FFFF
colorTable.emerald = 0x00D062FF
colorTable.obsidian = 0x3D354BFF
colorTable.sapphire = 0x172F5DFF
colorTable.crimson = 0xDC143CFF
colorTable.cyan = 0x00FFFFFF
-- /Color Table

local function init(std, game)
    game.fixedHSize = 800
    game.fixedVSize = 600
    game.offsetH = 0
    game.offsetV = 0
    game.bgColor = {}

    game.state = 0
    game.switchState = false
    game.difficulty = 2 -- 1 easy, 2 normal, 3 hard
    game.highscore = game.highscore or 0
    game.cursor = 0

    game.boardStartHorizontal = 160
    game.boardStartVertical   = 80
    game.boardHorSize =  {7, 9, 11}  -- easy, normal, hard
    game.boardVerSize =  {8, 10, 12} -- easy, normal, hard
    game.maxBrocos = {4, 5, 6}
    game.diffOffset = {80, 40, 0}

    game.board = {}
    game.selected = {}
    game.playerPos = {}
    game.count = {}

    game.basePoints = 10
    game.brocoMultiplier = {10, 5, 2} -- easy, normal, hard
    game.hitMultiplier = {5, 3, 1}  -- easy, normal, hard

    game.matchBoard = {}
    game.matchBoardIndex = 1
    
    game.loopCount = 0
    game.canReadInput = true
    game.pause = false
    game.destroy = false
end

local function init_board(std, game)
    game.score = 0
    game.board = {}
    for cont = 1, (game.boardHorSize[game.difficulty] * game.boardVerSize[game.difficulty]) do
        game.board[cont] = std.math.random(1, game.maxBrocos[game.difficulty])
    end
    game.matchBoard = {}
    
    game.selected.broco = 0
    game.selected.h = 0
    game.selected.v = 0

    game.playerPos.h = 0
    game.playerPos.v = 0

    game.matchesHit = 0
    game.matchesCount = 0
    
    game.count.squares = 0
    game.count.diamonds = 0
    game.count.triangles = 0
    game.count.plus = 0
    game.count.trapezoid = 0
    game.count.star = 0

    game.switchState = true
end

local function menu_logic(std, game)
    if game.canReadInput then
        if std.key.press.right == 1 and game.difficulty < 3 then
            game.difficulty = game.difficulty + 1
            game.canReadInput = false
        end
        if std.key.press.left == 1 and game.difficulty > 1 then
            game.difficulty = game.difficulty - 1
            game.canReadInput = false
        end
        if std.key.press.up == 1 and game.cursor > 0 then
            game.cursor = game.cursor - 1
            game.canReadInput = false
        end
        if std.key.press.down == 1 and game.cursor < 1 then
            game.cursor = game.cursor + 1
            game.canReadInput = false
        end
        if std.key.press.red == 1 or std.key.press.enter == 1 then
            if game.cursor == 0 then
                init_board(std, game)
                game.canReadInput = false
            else
                std.game.exit()
            end
        end
    end
end

local function pause_logic(std, game)
    if game.canReadInput then
        if std.key.press.up == 1 and game.cursor > 0 then
            game.cursor = game.cursor - 1
            game.canReadInput = false
        end
        if std.key.press.down == 1 and game.cursor < 2 then
            game.cursor = game.cursor + 1
            game.canReadInput = false
        end
        if std.key.press.red == 1 then
            if game.cursor == 1 then
                game.destroy = true
                game.cursor = 0
                init_board(std, game)
            elseif game.cursor == 2 then
                std.game.exit()
            end
            game.pause = false
            game.switchState = true
            game.canReadInput = false
        end
    end
end

local function game_logic(std, game)
    if game.canReadInput then
        if std.key.press.right == 1 and game.playerPos.h < (game.boardHorSize[game.difficulty] - 1) then
            game.playerPos.h = game.playerPos.h + 1
            game.canReadInput = false
        end
        if std.key.press.left == 1 and game.playerPos.h > 0 then
            game.playerPos.h = game.playerPos.h - 1
            game.canReadInput = false
        end
        if std.key.press.down == 1 and game.playerPos.v < (game.boardVerSize[game.difficulty] - 1) then
            game.playerPos.v = game.playerPos.v + 1
            game.canReadInput = false
        end
        if std.key.press.up == 1 and game.playerPos.v > 0 then
            game.playerPos.v = game.playerPos.v - 1
            game.canReadInput = false
        end
        if std.key.press.enter == 1 then
            game.pause = true
            game.cursor = 0
            game.switchState = true
            game.canReadInput = false
        end
        if std.key.press.red == 1 then
            local index = 0
            -- if is empty
            if game.selected.broco == 0 then
                index = (game.playerPos.v * game.boardHorSize[game.difficulty]) + game.playerPos.h + 1
                game.selected.broco = game.board[index]
                game.selected.h = game.playerPos.h
                game.selected.v = game.playerPos.v
            --if is not empty
            else
                local newSelectedH = game.playerPos.h
                local newSelectedV = game.playerPos.v

                local diffH = std.math.abs(game.selected.h - newSelectedH)
                local diffV = std.math.abs(game.selected.v - newSelectedV)
                
                if (diffH + diffV) == 1 then
                    local toSwitch = 0
                    index = (game.playerPos.v * game.boardHorSize[game.difficulty]) + game.playerPos.h + 1
                    toSwitch = game.board[index]
                    if game.selected.broco ~= toSwitch then
                        game.board[index] = game.selected.broco
                        index = (game.selected.v * game.boardHorSize[game.difficulty]) + game.selected.h + 1
                        game.board[index] = toSwitch
                        game.switchState = true
                    end
                end
                index = 0
                game.selected.broco = 0
                game.selected.h = -1
                game.selected.v = -1
            end
            game.canReadInput = false
        end
    end
end

local function check_matches(std, game)
    local checkPosH = 0
    local checkPosV = 0
    local index = 0
    local limitH = game.boardHorSize[game.difficulty] - 2
    local limitV = game.boardVerSize[game.difficulty] - 2

    game.matchesHit = 0
    --check rows
    while (checkPosV < game.boardVerSize[game.difficulty]) do
        while (checkPosH < limitH) do
            game.matchesCount = 0
            index = (checkPosV * game.boardHorSize[game.difficulty]) + checkPosH + 1
            if game.board[index] > 0
            and game.board[index] < 7
            and game.board[index] == game.board[index + 1]
            and game.board[index] == game.board[index + 2] then
                game.matchesHit = game.matchesHit + 1
                game.matchesCount = game.matchesCount + 3
                if checkPosH < (limitH - 1) and game.board[index] == game.board[index + 3] then
                    game.matchesCount = game.matchesCount + 1
                    --game.board[index + 3] = 7
                    game.matchBoard[index + 3] = 7
                    if checkPosH < (limitH - 2) and game.board[index] == game.board[index + 4] then
                        game.matchesCount = game.matchesCount + 1
                        --game.board[index + 4] = 7
                        game.matchBoard[index + 4] = 7
                    end
                end
                game.score = game.score + (game.matchesCount * (game.basePoints * game.brocoMultiplier[game.difficulty]))
                game.score = game.score + (game.matchesHit * game.hitMultiplier[game.difficulty])
                
                if game.board[index] == 1 then
                    game.count.squares = game.count.squares + game.matchesCount
                elseif game.board[index] == 2 then
                    game.count.diamonds = game.count.diamonds + game.matchesCount
                elseif game.board[index] == 3 then
                    game.count.triangles = game.count.triangles + game.matchesCount
                elseif game.board[index] == 4 then
                    game.count.plus = game.count.plus + game.matchesCount
                elseif game.board[index] == 5 then
                    game.count.trapezoid = game.count.trapezoid + game.matchesCount
                elseif game.board[index] == 6 then
                    game.count.star = game.count.star + game.matchesCount
                end

                --game.board[index + 2] = 7
                --game.board[index + 1] = 7
                --game.board[index] = 7
                game.matchBoard[index + 2] = 7
                game.matchBoard[index + 1] = 7
                game.matchBoard[index] = 7
            end
            if game.matchesCount == 0 then
                checkPosH = checkPosH + 1
            else
                checkPosH = checkPosH + game.matchesCount
            end
        end
        checkPosH = 0
        checkPosV = checkPosV + 1
    end

    checkPosH = 0
    checkPosV = 0
    --check columns
    while (checkPosH < game.boardHorSize[game.difficulty]) do
        while (checkPosV < limitV) do
            game.matchesCount = 0
            index = (checkPosV * game.boardHorSize[game.difficulty]) + checkPosH + 1
            if game.board[index] > 0
            and game.board[index] < 7
            and game.board[index] == game.board[index + game.boardHorSize[game.difficulty] ]
            and game.board[index] == game.board[index + (game.boardHorSize[game.difficulty] * 2)] then
                game.matchesHit = game.matchesHit + 1
                game.matchesCount = game.matchesCount + 3
                if checkPosH < (limitV - 1) and game.board[index] == game.board[index + (game.boardHorSize[game.difficulty] * 3)] then
                    game.matchesCount = game.matchesCount + 1
                    --game.board[index + 3] = 8
                    game.matchBoard[index + (game.boardHorSize[game.difficulty] * 3)] = 8
                    if checkPosH < (limitV - 2) and game.board[index] == game.board[index + (game.boardHorSize[game.difficulty] * 4)] then
                        game.matchesCount = game.matchesCount + 1
                        --game.board[index + 4] = 8
                        game.matchBoard[index + (game.boardHorSize[game.difficulty] * 4)] = 8
                    end
                end
                game.score = game.score + (game.matchesCount * (game.basePoints * game.brocoMultiplier[game.difficulty]))
                game.score = game.score + (game.matchesHit * game.hitMultiplier[game.difficulty])

                if game.board[index] == 1 then
                    game.count.squares = game.count.squares + game.matchesCount
                elseif game.board[index] == 2 then
                    game.count.diamonds = game.count.diamonds + game.matchesCount
                elseif game.board[index] == 3 then
                    game.count.triangles = game.count.triangles + game.matchesCount
                elseif game.board[index] == 4 then
                    game.count.plus = game.count.plus + game.matchesCount
                elseif game.board[index] == 5 then
                    game.count.trapezoid = game.count.trapezoid + game.matchesCount
                elseif game.board[index] == 6 then
                    game.count.star = game.count.star + game.matchesCount
                end
                
                --game.board[index + (game.boardHorSize[game.difficulty] * 2)] = 8
                --game.board[index + game.boardHorSize[game.difficulty] ] = 8
                --game.board[index] = 8
                game.matchBoard[index + (game.boardHorSize[game.difficulty] * 2)] = 8
                game.matchBoard[index + game.boardHorSize[game.difficulty]] = 8
                game.matchBoard[index] = 8
            end
            if game.matchesCount == 0 then
                checkPosV = checkPosV + 1
            else
                checkPosV = checkPosV + game.matchesCount
            end
        end
        checkPosV = 0
        checkPosH = checkPosH + 1
    end
    game.switchState = true
end

local function show_matches(std, game)
    --pass matched brocos
    if game.matchBoard[game.matchBoardIndex] ~= nil then
        game.board[game.matchBoardIndex] = game.matchBoard[game.matchBoardIndex]
        game.matchBoard[game.matchBoardIndex] = nil
        game.matchesCount = game.matchesCount + 1
    end
    if game.matchBoardIndex <= (game.boardHorSize[game.difficulty] * game.boardVerSize[game.difficulty]) then
        game.matchBoardIndex = game.matchBoardIndex + 1
    else
        game.matchBoardIndex = 1
        game.switchState = true
        game.matchBoard = {}
        game.matchesCount = 0
    end
end

local function remove_matched(std, game)
    for cont = 1, (game.boardHorSize[game.difficulty] * game.boardVerSize[game.difficulty]) do
        if game.board[cont] >= 7 then
            game.board[cont] = std.math.random(1, game.maxBrocos[game.difficulty])
        end
    end
    game.switchState = true
end

local function loop(std, game)
    if game.state == 0 then
        menu_logic(std, game)
    elseif game.state == 1 then
        game_logic(std, game)
    elseif game.state == 2 then
        check_matches(std, game)
    elseif game.state == 3 then
        show_matches(std, game)
    elseif game.state == 4 then
        remove_matched(std, game)
    elseif game.state == 10 then
        pause_logic(std, game)
    end
    if game.switchState then
        if game.state == 0 then
            game.state = 1
        elseif game.state == 1 then
            if game.pause then
                game.state = 10
            else
                game.state = 2
            end
        elseif game.state == 2 then
            if game.matchesHit > 0 then
                game.matchesHit = 0
                game.state = 3
            else
                game.state = 1
            end
        elseif game.state == 3 then
            game.state = 4
        elseif game.state == 4 then
            game.state = 1
        elseif game.state == 10 then
            if game.destroy then
                game.cursor = 0
                game.destroy = false
                game.state = 0
            else
                game.state = 1
            end
        end
        game.switchState = false
    end
    if game.loopCount <= 60 then
        game.loopCount = game.loopCount + 1
    else
        game.loopCount = 1
    end
    if  game.loopCount > 0
    and game.loopCount % 15 == 0
    and game.canReadInput == false then
        game.canReadInput = true
    end
end

local function render_broco(std, game, posX, posY, broco)
    posX = posX + 2
    posY = posY + 2
    if broco == 1 then -- square
        local square = {0,0,39,0,39,39,0,39}
        std.draw.color(colorTable.gold)
        std.draw.poly(0, square, posX, posY, 0.9)
    elseif broco == 2 then -- diamond
        local diamond = {19,0,20,0,39,19,39,20,20,39,19,39,0,20,0,19}
        std.draw.color(colorTable.diamond)
        std.draw.poly(0, diamond, posX, posY, 0.9)
    elseif broco == 3 then -- triangle
        local triangle = {0,39,19,0,20,0,39,39}
        std.draw.color(colorTable.emerald)
        std.draw.poly(0, triangle, posX, posY, 0.9)
    elseif broco == 4 then -- plus
        local plusV = {15,0,24,0,24,39,15,39}
        local plusH = {0,24,0,15,39,15,39,24}
        std.draw.color(colorTable.obsidian)
        std.draw.poly(0, plusV, posX, posY, 0.9)
        std.draw.poly(0, plusH, posX, posY, 0.9)
    elseif broco == 5 then -- trapezoid
        local trapezoid = {0,39,39,39,28,0,11,0}
        std.draw.color(colorTable.sapphire)
        std.draw.poly(0, trapezoid, posX, posY, 0.9)
    elseif broco == 6 then -- star
        local star = {19,26,0,39,20,0,20,26,39,39,19,0,19,26,0,13,39,13,20,26}
        std.draw.color(colorTable.crimson)
        std.draw.poly(0, star, posX, posY, 1)
    elseif broco == 7 or broco == 8 then 
        -- 7, cross, row/horizontal match
        -- 8, cross, column/vertical match
        local cross1 = {0,39,0,35,35,0,39,0,39,4,4,39}
        local cross2 = {0,0,4,0,39,35,39,39,35,39,0,4}
        std.draw.color(colorTable.cyan)
        std.draw.poly(0, cross1, posX, posY, 0.9)
        std.draw.poly(0, cross2, posX, posY, 0.9)
    end
end

local function draw_border(std, game, h, v, hSize, vSize, thick, color)
    color = color or std.color.black
    std.draw.color(color)
    std.draw.rect(0, h, v, hSize, thick)
    std.draw.rect(0, h, v + (vSize - thick), hSize, thick)
    std.draw.rect(0, h, v, thick, vSize)
    std.draw.rect(0, h + (hSize - thick), v, thick, vSize)
end

local function draw_logo(std, game)
    local menuBrocoLine = {1,2,3,4,5,6}
    local h = game.offsetH + 80
    local v = game.offsetV + 0

    std.draw.color(colorTable.backgroundBoard)
    std.draw.rect(0, h, v, (40*15), 40)

    for i = 1, #menuBrocoLine do
        local newH = h + (40 * (i - 1))
        render_broco(std, game, newH, v, menuBrocoLine[i])
    end
    draw_border(std, game, h - 5, v - 5, (40*15) + 10, 40 + 10, 5)
    if game.state == 10 then
        std.draw.text(h + 240 + 40, v+12, 'PAUSE')
    else
        std.draw.text(h + 240 + 35, v+12, 'BROCOS')
    end
    local newH = (h + 360)
    for i = 6, 1, -1 do
        render_broco(std, game, newH, v, menuBrocoLine[i])
        newH = newH + 40
    end
end

local function draw_menu(std, game)
    local h = game.offsetH + 320
    local v = game.offsetV + 120

    -- fill background
    std.draw.color(colorTable.backgroundBoard)
    std.draw.rect(0, h - 10, v - 10, 140, 180)

    --draw options
    draw_border(std, game, h - 10, v - 10, 140, 180, 5)
    std.draw.text(h + 25, v + 12,      ' Novo Jogo ')
    std.draw.text(h + 32, v + 40 + 12, '    Sair   ')
    std.draw.text(h + 25, v + 80 + 12, 'Dificuldade')
    if game.difficulty == 1 then
        std.draw.text(h + 45, v + 120 + 12, 'Fácil')
        std.draw.text(h + 95, v + 120 + 12, '->')
    elseif game.difficulty == 2 then
        std.draw.text(h + 10, v + 120 + 12, '<-')
        std.draw.text(h + 42, v + 120 + 12, 'Médio')
        std.draw.text(h + 95, v + 120 + 12, '->')
    else
        std.draw.text(h + 10, v + 120 + 12, '<-')
        std.draw.text(h + 45, v + 120 + 12, 'Difícil')
    end
    local hor = game.boardHorSize[game.difficulty]
    local ver = game.boardVerSize[game.difficulty]
    local mul = game.brocoMultiplier[game.difficulty]
    local comb = '(' .. hor .. 'x' .. ver .. ', ' .. mul .. 'x points' .. ')'
    std.draw.text(h + 5, v + 120 + 30, comb)
    std.draw.rect(1, h + 2, v + (game.cursor * 40) + 10, 116, 20)
end

local function draw_pause(std, game)
    local h = game.offsetH + 320
    local v = game.offsetV + 120

    -- fill background
    std.draw.color(colorTable.backgroundBoard)
    std.draw.rect(0, h - 10, v - 10, 140, 140)
    -- draw options
    draw_border(std, game, h - 10, v - 10, 140, 140, 5)
    std.draw.text(h + 30, v + 12,      'Continuar')
    std.draw.text(h + 32, v + 40 + 12, '   Menu  ')
    std.draw.text(h + 32, v + 80 + 12, '   Sair  ')

    std.draw.rect(1, h + 2, v + (game.cursor * 40) + 10, 116, 20)
end

local function draw(std, game)
    local startH = 0
    local startV = 0

    if game.width > 800 then
        game.offsetH = 20 + (game.width - game.fixedHSize) / 2
    else
        game.offsetH = 20
    end
    if game.height > 600 then
        game.offsetV = 20 + (game.height - game.fixedVSize) / 2
    else
        game.offsetV = 20
    end

    -- fill background
    std.draw.color(colorTable.background)
    std.draw.rect(0, 0, 0, game.width, game.height)
    --std.draw.clear(std.color.black)

    -- draw logo
    draw_logo(std, game)

    -- draw main
    if game.state == 0 then
        -- main menu
        draw_menu(std, game)
    elseif game.state == 10 then
        -- pause menu
        draw_pause(std, game)
    else
        -- game board
        -- draw highscore
        startH = game.offsetH + 0
        startV = game.offsetV + 80
        std.draw.color(colorTable.backgroundBoard)
        --std.draw.color('white')
        std.draw.rect(0, startH, startV, 120, 80)
        std.draw.color(std.color.black)
        std.draw.text(startH + 30, startV + 15, 'HI-SCORE')
        std.draw.text(startH + 30, startV + 40 + 5, string.format("%07d", game.highscore))
        draw_border(std, game, startH - 5, startV - 5, 120 + 10, 80 + 10, 5)

        -- draw broco count
        startH = game.offsetH + 0
        startV = game.offsetV + 200
        local maxV = 280
        if game.difficulty == 1 then
            maxV = 200
        elseif game.difficulty == 2 then
            maxV = 240
        else
            maxV = 280
        end
        std.draw.color(colorTable.backgroundBoard)
        --std.draw.color('white')
        std.draw.rect(0, startH, startV, 120, maxV)
        std.draw.color(std.color.black)
        std.draw.text(startH + 16, startV + 15, 'BROCO COUNT')
        draw_border(std, game, startH - 5, startV - 5, 120 + 10, maxV + 10, 5)
        render_broco(std, game, startH, startV + 40, 1) --square
        std.draw.color(std.color.black)
        std.draw.text(startH + 40 + 16, startV + 40 + 12, string.format("%05d", game.count.squares))
        render_broco(std, game, startH, startV + 80, 2) --diamond
        std.draw.color(std.color.black)
        std.draw.text(startH + 40 + 16, startV + 80 + 12, string.format("%05d", game.count.diamonds))
        render_broco(std, game, startH, startV + 120, 3) --triangle
        std.draw.color(std.color.black)
        std.draw.text(startH + 40 + 16, startV + 120 + 12, string.format("%05d", game.count.triangles))
        render_broco(std, game, startH, startV + 160, 4) --plus
        std.draw.color(std.color.black)
        std.draw.text(startH + 40 + 16, startV + 160 + 12, string.format("%05d", game.count.plus))
        if game.difficulty > 1 then
            render_broco(std, game, startH, startV + 200, 5) --square
            std.draw.color(std.color.black)
            std.draw.text(startH + 40 + 16, startV + 200 + 12, string.format("%05d", game.count.trapezoid))
            if game.difficulty == 3 then
                render_broco(std, game, startH, startV + 240, 6) --square
                std.draw.color(std.color.black)
                std.draw.text(startH + 40 + 16, startV + 240 + 12, string.format("%05d", game.count.star))
            end
        end

        -- draw board background
        local hor = 0
        local ver = 0
        local posH = 0
        local posV = 0
        local hSize = game.boardHorSize[game.difficulty] * 40
        local vSize = game.boardVerSize[game.difficulty] * 40
        startH = game.offsetH + game.boardStartHorizontal + game.diffOffset[game.difficulty]
        startV = game.offsetV + game.boardStartVertical
        if game.state == 3 then
            std.draw.color(colorTable.backgroundAlternate)
            std.draw.rect(0, startH - 20, startV - 20, hSize + 40, vSize + 40)
            draw_border(std, game, startH - 20, startV - 20, hSize + 40, vSize + 40, 5, colorTable.cyan)
        else
            std.draw.color(colorTable.backgroundBoard)
            std.draw.rect(0, startH - 20, startV - 20, hSize + 40, vSize + 40)
            draw_border(std, game, startH - 20, startV - 20, hSize + 40, vSize + 40, 5)
        end
        -- draw brocos
        for i = 1, (game.boardHorSize[game.difficulty] * game.boardVerSize[game.difficulty]) do
            posH = startH + (hor * 40)
            posV = startV + (ver * 40)
            render_broco(std, game, posH, posV, game.board[i])       
            hor = hor + 1
            if(hor >= game.boardHorSize[game.difficulty]) then
                hor = 0
                ver = ver + 1
            end
        end

        -- draw player
        startH = startH + (game.playerPos.h * 40)
        startV = startV + (game.playerPos.v * 40)
        std.draw.color(std.color.black)
        std.draw.rect(1, startH, startV, 40, 40)

        -- draw score
        startH = game.offsetH + 640
        startV = game.offsetV + 80
        std.draw.color(colorTable.backgroundBoard)
        --std.draw.color('white')
        std.draw.rect(0, startH , startV, 120, 80)
        std.draw.color(std.color.black)
        std.draw.text(startH + 38, startV + 15, 'SCORE')
        std.draw.text(startH + 30, startV + 40 + 5, string.format("%07d", game.score))
        draw_border(std, game, startH, startV, 120, 80, 5)

        -- draw selected broco
        startH = game.offsetH + 640
        startV = game.offsetV + 200
        std.draw.color(colorTable.backgroundBoard)
        --std.draw.color('white')
        std.draw.rect(0, startH, startV, 120, 160)
        std.draw.color(std.color.black)
        std.draw.text(startH + 28, startV + 15, 'SELECTED')
        draw_border(std, game, startH, startV, 120, 160, 5)
        if game.selected.broco > 0 then
            render_broco(std, game, startH+40, startV + 80, game.selected.broco)
            startH = game.offsetH + game.boardStartHorizontal + game.diffOffset[game.difficulty] + (game.selected.h * 40)
            startV = game.offsetV + game.boardStartVertical + (game.selected.v * 40)
            std.draw.color(std.color.red)
            std.draw.rect(1, startH, startV, 40, 40)
        end

        -- draw matches
        if game.state == 3 then
            startH = game.offsetH + 640
            startV = game.offsetV + 400
            std.draw.color(colorTable.backgroundBoard)
            std.draw.rect(0, startH, startV, 120, 80)
            std.draw.color(std.color.black)
            std.draw.text(startH + 30, startV + 15, 'MATCHES')
            std.draw.text(startH + 48, startV + 40 + 5, string.format("%03d", game.matchesCount))
            draw_border(std, game, startH, startV, 120, 80, 5)
        end
    end
end

local function exit(std, game)
    game.highscore = std.math.clamp(game.highscore, game.score, game.highscore)
end

local P = {
    meta={
        title='Brocos',
        author='diegofs01',
        description='Simple tile matching game',
        version='1.0.0'
    },
    config={
        require = 'math random'
    },
    callbacks={
        init=init,
        loop=loop,
        draw=draw,
        exit=exit
    }
}

return P;