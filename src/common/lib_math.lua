local function intersect_line_circle(x1, y1, x2, y2, h, k, raio)
    local m = (y2 - y1) / (x2 - x1)
    local c = y1 - m * x1
    local A = 1 + m^2
    local B = 2 * (m * c - m * k - h)
    local C = h^2 + k^2 + c^2 - 2 * c * k - raio^2
    local discriminante = B^2 - 4 * A * C
    return discriminante >= 0
end

local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

local function dir(value, alpha)
    alpha = alpha or 0
    if value < -alpha then
        return -1
    elseif value > alpha then
        return 1
    else
        return 0
    end
end

local function dis(x1,y1,x2,y2)
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

local function abs(value)
    if value < 0 then
        return -value
    end
    return value
end

local function saw(x)
    if x < 0.25 then
        return x * 4
    elseif x < 0.50 then
        return 1 - ((x - 0.25) * 4)
    elseif x < 0.75 then
        return ((x - 0.50) * 4) * (-1)
    end
    return ((x - 0.75) * 4) - 1
end

local function lerp(a, b, alpha)
    return a + alpha * ( b - a )
end 

local function map(x, in_min, in_max, out_min, out_max)
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

local function clamp2(value, min, max)
    return (value - min) % (max - min + 1) + min
end

local function cycle(passed, duration)
    local endtime = (passed) % duration
    return ((endtime == 0 and (passed % (duration * 2)) or endtime)) / duration
end

local function max(...)
    local args = {...}
    local index = 1
    local value = nil
    local max_value = nil
    
    if #args == 1 and type(args[1]) == "table" then
        args = args[1]
    end

    while index <= #args do
        value = args[index]
        if max_value == nil or value > max_value then
            max_value = value
        end
        index = index + 1
    end

    return max_value
end

local P = {
    intersect_line_circle=intersect_line_circle,
    cycle=cycle,
    clamp=clamp,
    clamp2=clamp2,
    lerp=lerp,
    abs=abs,
    map=map,
    dis=dis,
    saw=saw,
    max=max
}

return P;
