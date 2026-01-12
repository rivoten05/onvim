local function append_lines(arr, str)
    local lines = vim.split(str, "\n", { plain = true })
    for _, line in ipairs(lines) do
        table.insert(arr, line)
    end
end

local function eval_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local chunk = table.concat(lines, "\n")

    -- 1. Create/Get Buffer
    local buf_name = "LuaOutput"
    local buf = vim.fn.bufnr(buf_name)
    
    if buf == -1 then
        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, buf_name)
        vim.api.nvim_set_option_value("filetype", "lua", { buf = buf })
        -- Map 'q' to close the window only for this buffer
        vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, noremap = true, silent = true })
    end

    -- 2. Open Floating Window
    local width = math.ceil(vim.o.columns * 0.5)
    local height = math.ceil(vim.o.lines * 0.5)
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.ceil((vim.o.lines - height) / 2),
        col = math.ceil((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Lua Runner ",
        title_pos = "center",
    })

    -- 3. Setup Capture Environment
    local output = {}
    local old_print = print
    print = function(...)
        local args = {}
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            -- Automatically inspect tables so they are readable!
            table.insert(args, type(v) == "table" and vim.inspect(v) or tostring(v))
        end
        append_lines(output, table.concat(args, "\t"))
    end

    -- 4. Execute and Time the code
    local func, err = load(chunk)
    local ok, result
    local start_time = vim.loop.hrtime() -- START TIMER

    if func then
        ok, result = pcall(func)
    else
        ok, result = false, err
    end

    local end_time = vim.loop.hrtime() -- END TIMER
    print = old_print -- Restore print immediately

    -- 5. Format Results
    if ok then
        if result ~= nil then
            table.insert(output, "Result: " .. vim.inspect(result))
        else
            table.insert(output, "✔ Buffer executed successfully")
        end
    else
        table.insert(output, "❌ Error: " .. result)
    end

    local duration = (end_time - start_time) / 1e6
    table.insert(output, string.format("⏱ Time: %.2fms", duration))

    -- 6. Set lines
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
end

vim.keymap.set("n", "<leader>bx", eval_buffer, { desc = "Execute Lua Buffer" })
