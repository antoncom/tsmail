local signal = require("posix.signal")
signal.signal(signal.SIGINT, function(signum)
    io.write("\n")
    print("-----------------------")
    print("Tsmail debug stopped.")
    print("-----------------------")
    io.write("\n")
    os.exit(128 + signum)
end)

local ubus = require "ubus"
local uloop = require "uloop"
local mailsend = require "mailsend"
require "tsmail.util"

local app = {}

app.conn = nil

function app.init()
    app.conn = ubus.connect()
    if not app.conn then
        error("Failed to connect to ubus from Tsmail")
    else
        mailsend.setup("127.0.0.1", "25")
        app.make_ubus()
    end
end

function app.make_ubus()
    local ubus_methods = {
        ["tsmail"] = {
            send = {
                function (req, msg)
                    local from_email = tostring(msg["from_email"])
                    local to_email = tostring(msg["to_email"])
                    local title = tostring(msg["title"])
                    local message = tostring(msg["message"])

                    local status, result = mailsend.send(from_email, to_email, title, message)

                    app.conn:reply(req, { status = status, result = result } )
                end, { from_email = ubus.STRING, to_email = ubus.STRING, title = ubus.STRING, message = ubus.STRING }
            }
        }
    }

    app.conn:add(ubus_methods)
end

local metatable = {
    __call = function (app_)
        uloop.init()
        app_.init()
        uloop.run()
        app_.conn:close()
        return app_
    end
}
setmetatable(app, metatable)
app()
