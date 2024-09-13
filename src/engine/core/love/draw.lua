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

local function color(c)
    local DIV = love.wiimote and 1 or 255
    local R = bit.band(bit.rshift(c, 24), 0xFF)/DIV
    local G = bit.band(bit.rshift(c, 16), 0xFF)/DIV
    local B = bit.band(bit.rshift(c, 8), 0xFF)/DIV
    local A = bit.band(bit.rshift(c, 0), 0xFF)/DIV
    love.graphics.setColor(R, G, B, A)
end

local function rect(a,b,c,d,e,f)
    love.graphics.rectangle(modes[love.wiimote ~= nil][a], b, c, d, e)
end

--! @todo support WII
local function text(x, y, text)
    if love.wiimote then return 32 end
    local font = love.graphics.getFont()
    local t = text and tostring(text) or tostring(x)
    local n = select(2, t:gsub('\n', '')) + 1
    local w = love.graphics.getFont():getWidth(t)
    local h = (font:getHeight('A') * n) + (font:getLineHeight() * n)
    if x and y then
        love.graphics.print(t, x, y)
    end
    return w, h
end

local function line(x1, y1, x2, y2)
    love.graphics.line(x1, y1, x2, y2)
end

--! @todo implement it!
local function font(a, b)

end

local function install(self)
    local std = self and self.std or {}
    local game = self and self.game or {}
    local event = self and self.event or {}
    local application = self and self.application or {}
    event.draw = event.draw or {}
    application.callbacks.draw = application.callbacks.draw or function() end

    std.draw.color=color
    std.draw.rect=rect
    std.draw.text=text
    std.draw.line=line
    std.draw.font=font

    std.draw.clear = function(c)
        color(c)
        love.graphics.rectangle(modes[love.wiimote ~= nil][0], 0, 0, game.width, game.height)
    end

    event.draw[#event.draw + 1] = function()
        application.callbacks.draw(std, game)
    end

    if love then
        love.draw = function()
            local index = 1
            while index <= #event.draw do
                event.draw[index](std, game)
                index = index + 1
            end
        end
        love.resize = function(w, h)
            local index = 1
            game.width, game.height = w, h
        end
    end

    return {
        event={event=event.draw},
        std={draw=std.draw}
    }
end

local P = {
    install = install
}

return P
