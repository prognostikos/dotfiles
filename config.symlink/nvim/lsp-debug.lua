-- Debug script to check LSP and devcontainer setup
-- Run with: :luafile ~/.config/nvim/lsp-debug.lua

print("=== LSP & Devcontainer Debug Info ===")
print("Current file: " .. vim.fn.expand('%:p'))
print("CWD: " .. vim.fn.getcwd())
print("RUNNING_IN_DEVCONTAINER: " .. (vim.env.RUNNING_IN_DEVCONTAINER or "not set"))
print("")

-- Check devcontainer_helpers module status
local devcontainer_helpers = require('devcontainer_helpers')
print("=== Devcontainer Helpers Module ===")
print("Enabled: " .. tostring(devcontainer_helpers.is_enabled()))
if devcontainer_helpers.is_enabled() then
  print("Wrapper command: " .. devcontainer_helpers.get_wrapper_command())
  print("Example wrap: " .. devcontainer_helpers.wrap_command('bin/rails'))
end
print("")

-- Check active LSP clients
local clients = vim.lsp.get_clients({ bufnr = 0 })
if #clients == 0 then
  print("No LSP clients attached to this buffer")
else
  print("=== Active LSP Clients ===")
  for _, client in ipairs(clients) do
    print(string.format("  - %s (id: %d)", client.name, client.id))
    print(string.format("    root_dir: %s", client.config.root_dir or "not set"))
    print(string.format("    cmd: %s", vim.inspect(client.config.cmd)))
    if client.workspace_folders then
      print("    workspace_folders:")
      for _, folder in ipairs(client.workspace_folders) do
        print(string.format("      - %s", folder.name))
      end
    end
  end
end
print("")

-- Check .devcontainer/devcontainer.json
local devcontainer_json = vim.fn.getcwd() .. "/.devcontainer/devcontainer.json"
if vim.fn.filereadable(devcontainer_json) == 1 then
  print("=== Devcontainer Configuration ===")
  local content = vim.fn.readfile(devcontainer_json)
  local json_str = table.concat(content, "\n")
  local parsed = vim.json.decode(json_str)
  if parsed.workspaceFolder then
    print("workspaceFolder: " .. parsed.workspaceFolder)
  else
    print("workspaceFolder: (not set, using default)")
  end
else
  print("No .devcontainer/devcontainer.json found")
end
