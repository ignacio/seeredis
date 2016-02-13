local STP = require "StackTracePlus"
local ngx = require "ngx"

STP.add_known_table(ngx, "ngx_lua module")
debug.traceback = STP.stacktrace

local handler = require "web"
handler()
