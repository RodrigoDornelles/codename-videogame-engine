local luaunit = require('luaunit')
local protocol_http = require('src/lib/protocol/http_ginga')

local application = {}
local http_handler = protocol_http.install({}, {}, application)
event = {
    post=function() end
}

function test_http_fast_post_201()
    local response = {}
    local http = {
        std=std,
        game=game,
        application=application,
        speed='_fast',
        method='POST',
        body_content='',
        url='http://example.com/create-user',
        set = function(key, value)
            response[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http)

    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='example.com',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='HTTP/1.1 201 OK\r\nContent-Length: 2\r\n\r\nOK\r\n\r\n',
        connection=1
    })
    
    luaunit.assertEquals(response.ok, true)
    luaunit.assertEquals(response.status, 201)
    luaunit.assertEquals(response.body, '')
    luaunit.assertEquals(response.error, nil)
end

function test_http_get_200()
    local response = {}
    local http = {
        std=std,
        game=game,
        application=application,
        speed='',
        method='GET',
        body_content='',
        url='http://pudim.com.br',
        set = function(key, value)
            response[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http)

    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com.br',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='HTTP/1.1 200 OK\r\nContent-Length: 13\r\n\r\neu',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value=' amo ',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='pudim!',
        connection=1
    })
    
    luaunit.assertEquals(response.ok, true)
    luaunit.assertEquals(response.status, 200)
    luaunit.assertEquals(response.body, 'eu amo pudim!')
    luaunit.assertEquals(response.error, nil)
end

function test_http_simultaneous_requests()
    local response1 = {}
    local http1 = {
        std=std,
        game=game,
        application=application,
        speed='',
        method='GET',
        body_content='',
        url='http://pudim.com.br/chocolate',
        set = function(key, value)
            response1[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }
    local response2 = {}
    local http2 = {
        std=std,
        game=game,
        application=application,
        speed='',
        method='GET',
        body_content='',
        url='http://pudim.com.br/doce-de-leite',
        set = function(key, value)
            response2[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }
    local response3 = {}
    local http3 = {
        std=std,
        game=game,
        application=application,
        speed='',
        method='GET',
        body_content='',
        url='http://pudim.com.br/leite-condesado',
        set = function(key, value)
            response3[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http1)
    http_handler(http2)
    http_handler(http3)

    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com.br',
        connection=3
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com.br',
        connection=2
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='HTTP/1.1 200 OK\r\nContent-Length: 28\r\n\r\namo',
        connection=2
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com.br',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='HTTP/1.1 200 OK\r\nContent-Length: 23\r\n\r\namo',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value=' pudim de ',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value=' pudim de doce de leite!',
        connection=2
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='HTTP/1.1 200 OK\r\nContent-Length: 19\r\n\r\namo pudim de leite!',
        connection=3
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='chocolate!',
        connection=1
    })

    luaunit.assertEquals(response1.body, 'amo pudim de chocolate!')
    luaunit.assertEquals(response2.body, 'amo pudim de doce de leite!')
    luaunit.assertEquals(response3.body, 'amo pudim de leite!')
end

function test_http_error_http()
    local response = {}
    local http = {
        std=std,
        game=game,
        application=application,
        method='GET',
        body_content='',
        url='https://pudim.com.br/',
        set = function(key, value)
            response[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http)
    
    luaunit.assertEquals(response.ok, false)
    luaunit.assertEquals(response.status, nil)
    luaunit.assertEquals(response.body, nil)
    luaunit.assertEquals(response.error, 'HTTPS is not supported!')
end

function test_http_error_https_redirect()
    local response = {}
    local http = {
        std=std,
        game=game,
        application=application,
        speed='',
        method='GET',
        body_content='',
        url='http://pudim.com.br/',
        set = function(key, value)
            response[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http)

    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com.br',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='HTTP/1.1 300 Redirect\r\nLocation: https://pudim.com.br\r\n\r\n',
        connection=1
    })
    
    luaunit.assertEquals(response.ok, false)
    luaunit.assertEquals(response.status, nil)
    luaunit.assertEquals(response.body, nil)
    luaunit.assertEquals(response.error, 'HTTPS is not supported!')
end

function test_http_fast_empty_status_error()
    local response = {}
    local http = {
        std=std,
        game=game,
        application=application,
        speed='_fast',
        method='POST',
        body_content='',
        url='http://pudim.com.br/create-user',
        set = function(key, value)
            response[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http)

    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com.br',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='some error',
        connection=1
    })
    
    luaunit.assertEquals(response.ok, false)
    luaunit.assertEquals(response.status, nil)
    luaunit.assertEquals(response.body, nil)
    luaunit.assertEquals(response.error, 'some error')
end

function test_http_dns_error()
    local response = {}
    local http = {
        std=std,
        game=game,
        application=application,
        speed='',
        method='POST',
        body_content='',
        url='http://pudim.com',
        set = function(key, value)
            response[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http)

    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com',
        error='cannot resolve pudim.com'
    })

    luaunit.assertEquals(response.ok, false)
    luaunit.assertEquals(response.status, nil)
    luaunit.assertEquals(response.body, nil)
    luaunit.assertEquals(response.error, 'cannot resolve pudim.com')
end

function test_http_data_error()
    local response = {}
    local http = {
        std=std,
        game=game,
        application=application,
        speed='',
        method='POST',
        body_content='',
        url='http://pudim.com.br',
        set = function(key, value)
            response[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http)

    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com.br',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        error='some data error',
        connection=1
    })

    luaunit.assertEquals(response.ok, false)
    luaunit.assertEquals(response.status, nil)
    luaunit.assertEquals(response.body, nil)
    luaunit.assertEquals(response.error, 'some data error')
end

function test_http_error_not_implemented_redirect()
    local response = {}
    local http = {
        std=std,
        game=game,
        application=application,
        speed='',
        method='GET',
        body_content='',
        url='http://pudim.com.br/',
        set = function(key, value)
            response[key] = value
        end,
        promise = function() end,
        resolve = function() end
    }

    http_handler(http)

    application.internal.event_loop[1]({
        class='tcp',
        type='connect',
        host='pudim.com.br',
        connection=1
    })
    application.internal.event_loop[1]({
        class='tcp',
        type='data',
        value='HTTP/1.1 300 Redirect\r\nLocation: http://amo.pudim.com.br\r\n\r\n',
        connection=1
    })
    
    luaunit.assertEquals(response.ok, false)
    luaunit.assertEquals(response.status, nil)
    luaunit.assertEquals(response.body, nil)
    luaunit.assertEquals(response.error, 'redirect not implemented!')
end

os.exit(luaunit.LuaUnit.run())
