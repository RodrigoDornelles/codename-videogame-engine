local os = require('os')

local zeebo_fs = require('src/lib/cli/fs')
local zeebo_bundler = require('src/lib/cli/bundler')
local zeebo_bootstrap = require('src/lib/cli/bootstrap')

local function cli_test(args)
    local coverage = args.coverage and '-lluacov' or ''
    local files = zeebo_fs.ls('./tests')
    local index = 1
    local ok = true
    while index <= #files do
        ok = ok and os.execute('lua '..coverage..' ./tests/'..files[index])
        index = index + 1
    end
    if #coverage > 0 then
        os.execute('luacov src')
        os.execute('tail -n '..tostring(#files + 5)..' luacov.report.out')
    end
    return ok
end

local function cli_build(args)
    local dist = args.dist
    zeebo_fs.clear(dist)
    zeebo_bundler.build('src/cli/', 'main.lua', dist..'main.lua')
    local ok, message = zeebo_bootstrap.build(dist..'main.lua', dist..'cli.lua', './src', './assets', './examples', './mock')
    os.remove(dist..'main.lua')
    return ok, message
end

local function cli_dump(args)
    return zeebo_bootstrap.dump(dist)
end

local function cli_init(args)
    local project_name = args[1] or 'my_project'
    init.init_project(project_name)
end

local P = {
    ['cli-build'] = cli_build,
    ['cli-test'] = cli_test,
    ['cli-dump'] = cli_dump,
    ['cli-init'] = cli_init
}

return P
