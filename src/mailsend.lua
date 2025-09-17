local mailsend = {
    app = nil,
    smtp_server = "",
    port = "",
    use_ssl = false,
    use_starttls = false,
    use_auth = false,
    auth_user = "",
    auth_password = "",
}

function mailsend.init(app, smtp_server, port, use_ssl, use_starttls, use_auth, auth_user, auth_password)
    mailsend.app = app
    mailsend.smtp_server = smtp_server
    mailsend.port = port
    mailsend.use_ssl = use_ssl or false
    mailsend.use_starttls = use_starttls or false
    mailsend.use_auth = use_auth or false
    mailsend.auth_user = auth_user or ""
    mailsend.auth_password = auth_password or ""
end

function mailsend.send(from, to, subj, body, attach)
    local log_file_path = string.format('/tmp/mailsend_log_%s.txt', os.time())
    local cmd = string.format(
        'mailsend -smtp %s -port %s -from %q -to %q -sub %q -M %q -log %q',
        mailsend.smtp_server,
        mailsend.port,
        from,
        to,
        subj,
        body,
        log_file_path
    )

    if attach and attach ~= "" then
        cmd = cmd .. string.format(" -attach %q", attach)
    end

    if mailsend.use_ssl then
        cmd = cmd .. " -ssl"
    elseif mailsend.use_starttls then
        cmd = cmd .. " -starttls"
    end

    if mailsend.use_auth then
        cmd = cmd .. string.format(" -auth -user %q -pass %q", mailsend.auth_user, mailsend.auth_password)
    end

    cmd = cmd .. " 2>&1"

    local shell_process = io.popen(cmd)
    local status = ""
    local result = ""

    if shell_process then
        local shell_result = shell_process:read("*a")
        shell_process:close()
        if shell_result:find("Error") then
            os.remove(log_file_path)
            mailsend.app.conn:notify(mailsend.app.ubus_methods["tsmail"].__ubusobj, "ERROR", { result = shell_result })
            return 'error', shell_result
        end
    end

    local log_file = io.open(log_file_path, 'r')
    if log_file then
        local log = log_file:read("*a")
        os.remove(log_file_path)

        if log:find("Mail sent successfully") then
            status = "ok"
            result = "Mail sent successfully"
            if attach and attach ~= "" then
                os.remove(attach)
            end
        else
            status = "error"
            result = log
            mailsend.app.conn:notify(mailsend.app.ubus_methods["tsmail"].__ubusobj, "ERROR", { result = result })
        end
    end

    return status, result
end

return mailsend
