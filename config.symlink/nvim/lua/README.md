# devcontainer_lsp Module

A Neovim module that enables LSP servers and development tools to run inside a devcontainer while Neovim runs on the host.

## Features

- **Automatic Detection**: Checks for `.devcontainer/devcontainer.json` and `RUNNING_IN_DEVCONTAINER` env var
- **Path Translation**: Translates file paths between host and container for LSP communication
- **Configuration**: Reads `workspaceFolder` from `devcontainer.json`
- **Utilities**: Helper functions to wrap any command to run in the devcontainer

## Setup

```lua
local devcontainer_lsp = require('devcontainer_lsp')
local enabled = devcontainer_lsp.setup({
  wrapper_command = 'deve'  -- Your devcontainer exec wrapper command
})
```

## API

### Detection

```lua
-- Check if devcontainer mode is enabled
devcontainer_lsp.is_enabled()  -- Returns: true/false
```

### Command Wrapping

```lua
-- Get the configured wrapper command
devcontainer_lsp.get_wrapper_command()  -- Returns: 'deve'

-- Wrap a command string
devcontainer_lsp.wrap_command('bin/rails test')
-- Returns: 'deve bin/rails test' (or unwrapped if disabled)

-- Wrap a command array
devcontainer_lsp.wrap_command_array({'bin/rspec', 'spec/models'})
-- Returns: {'deve', 'bin/rspec', 'spec/models'} (or unwrapped if disabled)
```

### LSP Integration

```lua
-- Wrap LSP server command
local wrapped_cmd = devcontainer_lsp.wrap_lsp_cmd(server_name, server_config)

-- Create before_init hook with path translation
server_config.before_init = devcontainer_lsp.create_before_init(server_config.before_init)
```

## Usage Examples

### vim-dispatch

```lua
if devcontainer_enabled then
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'ruby',
    callback = function()
      vim.bo.makeprg = devcontainer_lsp.wrap_command('bin/rails')
    end
  })
end
```

### vim-test

```lua
if devcontainer_enabled then
  vim.g['test#ruby#rspec#executable'] = devcontainer_lsp.wrap_command('bin/rspec')
end
```

### LSP Configuration

```lua
if devcontainer_enabled and vim.tbl_contains(devcontainer_servers, server_name) then
  local wrapped_cmd = devcontainer_lsp.wrap_lsp_cmd(server_name, server_config)
  if wrapped_cmd then
    server_config.cmd = wrapped_cmd
    server_config.before_init = devcontainer_lsp.create_before_init(server_config.before_init)
  end
end
```

## Testing

### Run Automated Tests

```bash
# Run all tests
nvim --headless -l ~/.config/nvim/lua/devcontainer_lsp_test.lua

# Or use the convenience script
tmp/run_devcontainer_tests.sh
```

### Debug Current Setup

From within Neovim:

```vim
:luafile ~/.config/nvim/lsp-debug.lua
```

This will show:
- Whether devcontainer mode is enabled
- Configured wrapper command
- Active LSP clients and their configuration
- Workspace folder from devcontainer.json

## How It Works

1. **Detection**: On setup, checks for:
   - `RUNNING_IN_DEVCONTAINER != "1"` (not inside container)
   - `.devcontainer/devcontainer.json` exists

2. **Configuration**: Reads `workspaceFolder` from devcontainer.json (defaults to `/workspaces/<dirname>`)

3. **Path Translation**:
   - Outgoing: Translates host paths to container paths before sending to LSP
   - Incoming: Translates container paths back to host paths in LSP responses

4. **Command Wrapping**: Provides utilities to wrap any command with the devcontainer wrapper

## Requirements

- Neovim 0.11+
- A devcontainer wrapper command (e.g., `deve`, `devcontainer exec`)
- `.devcontainer/devcontainer.json` in project root

## Configuration File Format

The module reads from `.devcontainer/devcontainer.json`:

```json
{
  "workspaceFolder": "/workspaces/myproject"
}
```

If `workspaceFolder` is not specified, it defaults to `/workspaces/<directory-name>`.
