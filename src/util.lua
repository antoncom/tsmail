local uci = require "luci.model.uci".cursor()
local util = require "luci.util"

function if_debug(title, value, comment)
    local is_debug = (uci:get("tsmail", "general", "debug") == "1") and true
    local val = ""

    if is_debug then
        if (value and type(value) == "table") then
            val = util.serialize_json(value)
        elseif (value and type(value) == "string") then
            val = value:gsub("%c", " ")
        else
            val = value
        end
        print(title,val,"","", comment)
    end
end
