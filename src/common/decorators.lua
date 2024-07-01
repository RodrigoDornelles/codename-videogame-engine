local math = require('math')

local function decorator_poly(limit_verts, func_draw_poly, func_draw_line, func_draw_circle)    
    return function (mode, verts, x, y, scale, angle, ox, oy)
        if #verts < 6 or #verts % 2 ~= 0 then return end

        ox = ox or 0
        oy = oy or ox or 0
        
        if not func_draw_poly and func_draw_line then
            func_draw_poly = function (_, verts)
                local index = 4
                while index <= #verts do
                    func_draw_line(verts[index - 3], verts[index - 2], verts[index - 1], verts[index])
                    index = index + 2
                end
            end
        end

        if (not func_draw_poly or (limit_verts ~= 0 and limit_verts < verts)) and func_draw_circle then
            local index = 1
            local radius = 10
            size = size or 1
            while index < #verts do
                radius = radius + verts[index]
                index = index + 1
            end
            radius = radius * size / #verts * 3
            func_draw_circle(mode, x, y, radius)
        elseif x and y and (angle == nil or angle == 0) then
            local index = 1
            local verts2 = {}
            scale = scale or 1

            while index <= #verts do
                if index % 2 ~= 0 then
                    verts2[index] = x + (verts[index] * scale)
                else
                    verts2[index] = y + (verts[index] * scale)
                end
                index = index + 1
            end
            func_draw_poly(mode, verts2)
        elseif x and y and scale and angle then
            local index = 1
            local verts2 = {}
            while index < #verts do
                local px = verts[index]
                local py = verts[index + 1]
                local xx = x + ((ox - px) * -scale * math.cos(angle)) - ((ox - py) * -scale * math.sin(angle))
                local yy = y + ((oy - px) * -scale * math.sin(angle)) + ((oy - py) * -scale * math.cos(angle))
                verts2[index] = xx
                verts2[index + 1] = yy
                index = index + 2
            end
            func_draw_poly(mode, verts2)
        else
            func_draw_poly(mode, verts)
        end
    end
end

local P = {
    poly=decorator_poly
}

return P;
