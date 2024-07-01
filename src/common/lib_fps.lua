local function fps_counter(fps_limit, fps_obj, uptime)
    if uptime >= fps_obj.period + 1000 then
        fps_obj.period = uptime
        fps_obj.total = fps_obj.count
        fps_obj.count = 0

        if fps_obj.drop_count == 0 then
            return true
        end

        if fps_obj.total + fps_obj.drop_count > fps_limit then
            fps_obj.falls = 0
            return true
        end

        fps_obj.falls = fps_obj.falls + 1
        
        if fps_obj.drop_time < fps_obj.falls then
            fps_obj.falls = 0
            return false
        end
    end
    
    fps_obj.count = fps_obj.count + 1
    fps_obj.delta = uptime - fps_obj.passed
    fps_obj.passed = uptime

    return true
end

local P = {
    counter=fps_counter
}

return P
