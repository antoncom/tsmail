local mailsend = {
    output_tmp_file_path = "/tmp/mailsend_output.txt",
    smtp_server = "",
    port = "",
}

function mailsend.setup(smtp_server, port)
    mailsend.smtp_server = smtp_server
    mailsend.port = port
end

function mailsend.send(from_email, to_email, title, message)
    local cmd = string.format(
        'mailsend -w -smtp %s -port %s -from %s -to %s -sub "%s" -M "%s"',
        -- > %s
        -- 2>&1
        mailsend.smtp_server,
        mailsend.port,
        from_email,
        to_email,
        title,
        message,
        mailsend.output_tmp_file_path
    )

    local shell_process = io.popen(cmd)
    -- local os_execute_result = os.execute(cmd)
    local status = ""
    local result = ""

    if shell_process then
        result = shell_process:read("*a")
        print('result [' .. tostring(result) .. ']')
        shell_process:close()
    end

    -- local output_tmp_file = io.open(mailsend.output_tmp_file_path, "r")
    -- if output_tmp_file then
    --     result = output_tmp_file:read("*a")
    --     output_tmp_file:close()
    -- end
    -- os.remove(mailsend.output_tmp_file)

    if result:find("sent successfully") then
        status = "ok"
    else
        status = "error"
    end

    return status, result
end

return mailsend
