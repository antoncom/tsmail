local mailsend = {
    smtp_server = "",
    port = "",
}

function mailsend.setup(smtp_server, port)
    mailsend.smtp_server = smtp_server
    mailsend.port = port
end

function mailsend.send(from, to, subj, body, attach)
    local log_file_path = string.format('/tmp/mailsend_log_%s.txt', os.time())
    local cmd = string.format(
        'mailsend -smtp %s -port %s -from %q -to %q -sub %q -M %q -attach %q -log %q 2>&1',
        mailsend.smtp_server,
        mailsend.port,
        from,
        to,
        subj,
        body,
        attach,
        log_file_path
    )
    local shell_process = io.popen(cmd)
    local status = ""
    local result = ""

    if shell_process then
        local shell_result = shell_process:read("*a")
        shell_process:close()
        if shell_result:find("Error") then
            os.remove(log_file_path)
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
            os.remove(attach)
        else
            status = "error"
            result = log
        end
    end

    return status, result
end

return mailsend
