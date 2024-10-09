local os = require('os')

local function create_file(filepath, content)
    local file = io.open(filepath, "w")
    if file then
        file:write(content)
        file:close()
    else
        print("Error while creating file: " .. filepath)
    end
end

local function create_directory(path)
    local success = os.execute("mkdir " .. path)
    if not success then
        print("Error while creating directory: " .. path)
    end
end

local function init_project(project_name)
    create_directory(project_name)
    create_file(project_name .. "/.gitignore", ".DS_Store\nThumbs.db\n")
    
    create_directory(project_name .. "/dist")
    create_directory(project_name .. "/vendor")
    
    create_file(project_name .. "/README.md", "# " .. project_name .. "\n\n * **use:** `./cli.sh run src/game.lua`\n")
    
    create_directory(project_name .. "/src")
    
    local game_lua_content = 'local function init(std, game)\n\nend\n\n'
    ..'local function loop(std, game)\n\nend\n\n'
    ..'local function draw(std, game)\n'
    ..'   std.draw.clear(std.color.black)\n'
    ..'   std.draw.color(std.color.white)\n'
    ..'   std.draw.text(8, 8, "hello world")\n'
    ..'end\n\n'
    ..'local function exit(std, game)\n\nend\n\n'
    ..'local P = {\n'
    ..'    meta={\n'
    ..'        title="' .. project_name .. '",\n'
    ..'        author="YourName",\n'
    ..'        description="description about the game",\n'
    ..'        version="1.0.0"\n'
    ..'    },\n'
    ..'    callbacks={\n'
    ..'        init=init,\n'
    ..'        loop=loop,\n'
    ..'        draw=draw,\n'
    ..'        exit=exit\n'
    ..'    }\n'
    ..'}\n\n'
    ..'return P\n'

    create_file(project_name .. "/src/game.lua", game_lua_content)
    
    print("Project " .. project_name .. " created with success!")
end

return {
    init_project = init_project
}
