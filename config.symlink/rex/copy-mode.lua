-- Standalone Neovim settings: do not load plugins or save terminal history.
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.modeline = false
vim.opt.shadafile = "NONE"
vim.opt.clipboard = ""
vim.opt.mouse = "a"
vim.opt.wrap = true
vim.opt.laststatus = 2
vim.opt.statusline = " Copy mode | v: select | V: lines | Ctrl-V: block | y: copy and close | q: close"
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.bo.modifiable = false
    vim.cmd("normal! G$")
  end,
})
vim.keymap.set({ "n", "x" }, "q", "<Cmd>qa!<CR>")
vim.keymap.set("n", "<Esc>", "<Cmd>qa!<CR>")
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator ~= "y" then return end
    local text = table.concat(vim.v.event.regcontents, "\n")
    if vim.v.event.regtype == "V" then text = text .. "\n" end
    vim.fn.system({ "/usr/bin/pbcopy" }, text)
    if vim.v.shell_error ~= 0 then
      vim.notify("Clipboard copy failed", vim.log.levels.ERROR)
      return
    end
    vim.schedule(function() vim.cmd("qa!") end)
  end,
})
