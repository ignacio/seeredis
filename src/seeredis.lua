--require('mobdebug').start('192.168.0.103')

local orbit = require "orbit"
local Redis = require "resty.redis"
local md5 = require "md5"

-- Hacks to allow my old code to work.
webHandler = {}
webHandler.CollectTraceback = debug.traceback

_G.LogError = function(...)
	return ngx.log(ngx.ERR, ...)
end

_G.LogWarning = function(...)
	return ngx.log(ngx.WARN, ...)
end


local m_applicationName = "seeredis"

local htmlRender = require "webrender".new(m_applicationName)

htmlRender:AddCommonScript("/scripts/jquery-1.8.2.min.js")
htmlRender:AddCommonStylesheet("/styles/master.css")


---
-- Create a new Orbit application
--
local app = orbit.new({})

-- let nginx deal with serving files
--[[
local function serve_file(app_module)
	return function (web)
		local filename = string.sub(web.path_info, 2, #web.path_info)
		return app:serve_static(web, ngx.var.document_root.."/"..filename)
	end
end
app:dispatch_get(serve_file(app_module), "/images/.+", "/styles/.+", "/scripts/.+")
--]]

local function get_server_and_port (web)
	local server = web.cookies.redis_server or "127.0.0.1"
	if not server then
		web.status = 302
		web.headers.Location = "/"
		return nil
	end

	local port = tonumber(web.cookies.redis_port) or 6379
	if not port then
		web.status = 302
		web.headers.Location = "/"
		return nil
	end

	return server, port
end

local function redis_connect (server, port)
	local redis = Redis:new()
	redis:set_timeout(1000)
	local ok, err = redis:connect(server, port)
	if not ok then
		return nil, "Failed to connect: "..tostring(err)
	end
	return redis
end


---
--
app:dispatch_get(function(web, key)
	local server, port = get_server_and_port(web)
	if not server then
		return ""
	end

	local client, err = redis_connect(server, port)
	if not client then
		web.status = 500
		return err
	end
	
	local key_type = client:type(key)
	local args = { redis = client, key = key, key_type = key_type, redis_server = server, redis_port = port }
	
	if key_type == "set" then
		args.values = client:smembers(key)
		
	elseif key_type == "zset" then
		args.values = client:zrange(key, 0, -1, "WITHSCORES")
	
	elseif key_type == "list" then
		args.values = client:lrange(key, 0, -1)
		
	elseif key_type == "hash" then
		args.values = client:array_to_hash(client:hgetall(key))
		
	elseif key_type == "string" then
		args.values = { client:get(key) }
	end
	
	return htmlRender:RenderPageLP("pages/inspect_"..key_type..".html", web, args)
end, "/inspect/(.+)")


---
-- strings only
--
app:dispatch_post(function(web, key)
	local newValue = web.input["post_data"]
	
	local server, port = get_server_and_port(web)
	if not server then
		return ""
	end
	local client, err = redis_connect(server, port)
	if not client then
		web.status = 500
		return err
	end
	--check key type
	local key_type = client:type(key)
	if key_type == "string" then
		client:set(key, newValue)
	end
	return ""
end, "/update/(.+)")


---
--
app:dispatch_get(function(web)
	local client, err = redis_connect(web.input.server, tonumber(web.input.port) or 6379)
	if not client then
		web.status = 302
		web.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, post-check=0, pre-check=0"
		web.headers.Location = web:link("")
		-- TODO: fix delete_cookie (use ngx.cookie_time)
		--web:delete_cookie("redis_server")
		--web:delete_cookie("redis_port")

		web.headers["Set-Cookie"] = {
			"redis_server=xxx; expires=Thursday, 01-Jan-1970 00:00:01 GMT",
			"redis_port=xxx; expires=Thursday, 01-Jan-1970 00:00:01 GMT"
		}
		return ""
	end
	
	web.status = 302
	web.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, post-check=0, pre-check=0"
	web.headers.Location = web:link("keys")
	
	web:set_cookie("redis_server", {value = web.input.server, path = "/"})
	web:set_cookie("redis_port", {value = web.input.port, path = "/"})
	
	return ""
end, "/connect")


---
--
app:dispatch_get(function(web)
	local server, port = get_server_and_port(web)
	if not server then
		return ""
	end
	
	local client, err = redis_connect(server, port)
	if not client then
		web.status = 500
		return err
	end

	local query = web.input.query

    local page = htmlRender:RenderPageLP("pages/keys.html", web, {
    					redis_server = server,
    					redis_port = port,
						redis = client,
						query = query
						})
	local hash = md5.sumhexa(page .. (query or "") .. server .. port)
	
	if web.vars.HTTP_IF_NONE_MATCH == hash then
		web.status = 304
		return ""
	end
	web.headers["ETag"] = hash
	return page
end, "/keys")


---
--
app:dispatch_get(function(web)
	web.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, post-check=0, pre-check=0"
	
	local server = web.cookies.redis_server or "127.0.0.1"
	local port = web.cookies.redis_port or 6379
	return htmlRender:RenderPageLP("pages/main.html", web, {
		redis_server = server,
		redis_port = port
	})
end, "/")

return app
