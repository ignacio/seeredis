local openresty = require "wsapi.openresty"
local seeredis = require "seeredis"

-- Esto es necesario o arma mal los links a la applicacion
seeredis.prefix = "/"

local handler = openresty.makeHandler(seeredis, "", "/", "")

return handler
