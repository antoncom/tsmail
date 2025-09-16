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
local uci = require "luci.model.uci".cursor()
local mailsend = require "tsmail.mailsend"
require "tsmail.util"

local app = {}

app.conn = nil

function app.init()
    app.conn = ubus.connect()
    if not app.conn then
        error("Failed to connect to ubus from Tsmail")
    else
        local smtp_server = uci:get("tsmail", "general", "smtp_server")
        local smtp_port = uci:get("tsmail", "general", "smtp_port")
        local use_starttls = (uci:get("tsmail", "general", "use_starttls") == "1")
        local use_auth = (uci:get("tsmail", "general", "use_auth") == "1")

        if not (smtp_server and smtp_port) then
            error("Add smtp_server and smtp_port fields in uci config")
        end

        local auth_user, auth_password = "", ""
        if use_auth then
            auth_user = uci:get("tsmail", "general", "auth_user") or ""
            auth_password = uci:get("tsmail", "general", "auth_password") or ""
        end

        if_debug("uci_config", "smtp_server", smtp_server)
        if_debug("uci_config", "smtp_port", smtp_port)
        if_debug("uci_config", "use_starttls", use_starttls)
        if_debug("uci_config", "use_auth", use_auth)
        if_debug("uci_config", "auth_user", auth_user)
        if_debug("uci_config", "auth_password (length)", string.len(auth_password))

        mailsend.init(app, smtp_server, smtp_port, use_starttls, use_auth, auth_user, auth_password)
        app.make_ubus()
    end
end

function app.make_ubus()
    local ubus_methods = {
        ["tsmail"] = {
            send = {
                function (req, msg)
                    local from = msg["from"]
                    local to = msg["to"]
                    local subj = msg["subj"]
                    local body = msg["body"]
                    local attach = msg["attach"]

                    if not (from and to and subj and body) then
                        app.conn:reply(req, {
                            status = "error",
                            result = "[from], [to], [subj] and [body] are required params."
                        })
                    end

                    local status, result = mailsend.send(from, to, subj, body, attach)

                    app.conn:reply(req, { status = status, result = result } )
                end, { from = ubus.STRING, to = ubus.STRING, subj = ubus.STRING, body = ubus.STRING, attach = ubus.STRING }
            }
        }
    }

    app.conn:add(ubus_methods)
    app.ubus_methods = ubus_methods
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
