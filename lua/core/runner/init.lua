local function append_lines(arr, str)
	local lines = vim.split(str, "\n", { plain = true })
	for _, line in ipairs(lines) do
		table.insert(arr, line)
	end
end

local function eval_buffer()
	-- get lines
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local chunk = table.concat(lines, "\n")

	-- crea buf if not exists
	local buf_name = "LuaOutput"
	local buf = vim.fn.bufnr(buf_name)
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, buf_name)
		vim.api.nvim_buf_set_option(buf, "filetype", "lua")
	end

	-- if exists
	local width = math.ceil(vim.o.columns * 0.4)
	local height = math.ceil(vim.o.lines * 0.5)
	local _ = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.ceil((vim.o.lines - height) / 2),
		col = math.ceil((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
	})
	-- clear buf
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

	local output = {}

	local old_print = print
	print = function(...)
		local args = {}
		for i = 1, select("#", ...) do
			table.insert(args, tostring(select(i, ...)))
		end
		local text = table.concat(args, "\t")
		append_lines(output, text)
	end

	-- Run Lua code
	local func, err = load(chunk)

	local ok, result
	if func then
		ok, result = pcall(func)
	else
		ok, result = false, err
	end
	-- Restore original print
	print = old_print

	-- result
	if ok then
		if result ~= nil then
			table.insert(output, "Result: " .. vim.inspect(result))
		else
			table.insert(output, "✔ Buffer executed successfully")
		end
	else
		table.insert(output, "❌ Error: " .. result)
	end

	-- set lines in buf
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
end

vim.keymap.set("n", "<leader>bx", eval_buffer, { desc = "Execute Lua Buffer" })
