# UNSOLVED: vscode-langservers-extracted LSPs Crash in Devcontainer Setup

## Problem Statement

HTML, CSS, JSON, and ESLint LSPs from vscode-langservers-extracted crash with exit code 1 after ~4 seconds when:
- nvim runs on host Mac
- LSPs run in devcontainer via `deve` wrapper
- Editing .html.erb files (eruby filetype)
- Ruby LSP works perfectly in the same setup

**Key Observation**: Both ruby_lsp and html LSP are configured for "eruby" filetype and BOTH can handle the same file simultaneously - this is intentional and should work.

## What I Discovered

### 1. RPC Params Mutation (FIXED ✅)
**Problem**: `setup_client_wrapping()` was mutating params objects in place
**Fix**: Added `vim.deepcopy(params)` before modifying in notify/request wrappers
**Location**: Lines 140, 154 in devcontainer_helpers/init.lua
**Status**: This fix prevents CSS LSP from crashing (verified)

### 2. Config Merging Issue (FIXED ✅)
**Problem**: User's partial LSP configs weren't being merged with lspconfig defaults
**Fix**: Load `lspconfig.configs.<server>.default_config` first, then merge user config
**Location**: init.lua lines ~997-1016
**Status**: Config now shows correct filetypes, cmd, root_dir

### 3. vim.lsp.enable() Not Working (FIXED ✅)
**Problem**: `vim.lsp.enable(server_names)` doesn't work reliably in nvim 0.11
**Fix**: Replaced with FileType autocmds that call `vim.lsp.start()` explicitly
**Location**: init.lua lines ~1033-1065
**Status**: LSPs now start on FileType events

### 4. Funcref Error (FIXED ✅)
**Problem**: `E729: Using a Funcref as a String` when calling root_dir function
**Fix**: Call `root_dir` function before passing to vim.lsp.start(), don't use tbl_extend
**Location**: init.lua lines 1043-1046
**Status**: No more Funcref errors

### 5. Response Handler Mutation (ATTEMPTED ❌)
**Problem**: `translate_response()` mutates response tables in place
**Attempt 1**: Added `vim.deepcopy(value)` inside recursive function (lines 101-110)
  - Result: Massive performance issue - copies of copies of copies
  - HTML LSP still crashes
**Attempt 2**: Moved `vim.deepcopy(result)` to top level only (line 119)
  - Result: More efficient but HTML LSP still crashes
**Location**: devcontainer_helpers/init.lua lines 98-125
**Status**: STILL CRASHING - This is not the root cause

## Current Status

### ✅ Working
- ruby_lsp on eruby files
- HTML LSP starts successfully
- HTML LSP initializes and returns capabilities
- HTML LSP responds to textDocument/diagnostic requests
- Path translation works (host <-> container URIs are correct)
- Both LSPs can coexist on same file initially

### ❌ Not Working
- HTML LSP crashes with exit code 1 after ~4 seconds
- Error message: "Client html quit with exit code 1 and signal 0"
- No error in stderr output from LSP process
- LSP log shows successful communication before crash
- Crash happens in both headless and normal nvim

## Evidence from LSP Log

```
[INFO] Starting RPC client { cmd = { "deve", "vscode-html-language-server", "--stdio" } }
[INFO] LSP[html] server_capabilities { ... }  # Successfully initialized
[DEBUG] rpc.send textDocument/diagnostic  # Making requests
[DEBUG] rpc.receive { id = 2, result = { items = {}, kind = "full" } }  # Getting responses
# Then silence... process exits with code 1
```

**Key Finding**: LSP is working correctly for several seconds, then suddenly exits. No error messages. This suggests:
- Not a startup/config issue
- Not a communication issue
- Possibly a resource/memory issue
- Possibly triggered by specific LSP response content
- Possibly an issue with how responses are being handled

## What Makes This Unique

1. **Ruby LSP works perfectly** with same devcontainer setup
2. **All vscode-langservers-extracted LSPs fail** (HTML, CSS, JSON, ESLint)
3. **Crashes after successful operation** (not immediate)
4. **No stderr error messages** from LSP process
5. **Happens with multiple LSPs on same file** (ruby_lsp + html both handle eruby)

## Testing Scripts Created

All in `/Users/rohrer/c/bn/mrclean/tmp/`:

### test_html_lsp_attach.sh
Basic test to check if HTML LSP attaches to eruby file:
```bash
#!/bin/bash
echo "Testing HTML LSP attachment to ERB file..."
rm ~/.local/state/nvim/lsp.log 2>/dev/null

nvim --headless -c "edit app/views/donations/new.html.erb" -c "lua vim.defer_fn(function() \
  local clients = vim.lsp.get_clients({ bufnr = 0 }); \
  print('\\n=== LSP Clients for current buffer ==='); \
  for _, c in ipairs(clients) do \
    print(string.format('✓ %s (id: %d)', c.name, c.id)); \
  end; \
  if #clients == 0 then \
    print('✗ No LSP clients attached!'); \
  end; \
  vim.cmd('quit'); \
end, 5000)" 2>&1 | grep -E "LSP Clients|✓|✗"

echo ""
echo "=== Checking LSP log for errors ==="
if [ -f ~/.local/state/nvim/lsp.log ]; then
  if grep -q "html.*quit" ~/.local/state/nvim/lsp.log; then
    echo "✗ HTML LSP crashed"
  elif grep -q "Starting RPC.*html" ~/.local/state/nvim/lsp.log; then
    echo "✓ HTML LSP started successfully"
  fi
fi
```

### test_final_verification.lua
Checks LSP attachment after waiting for initialization:
```lua
vim.defer_fn(function()
  print("=== Opening eruby file ===\n")
  vim.cmd("edit app/views/donations/new.html.erb")
  local bufnr = vim.api.nvim_get_current_buf()

  vim.defer_fn(function()
    print("=== Attached LSP Clients (after 4s) ===")
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    if #clients > 0 then
      for _, client in ipairs(clients) do
        print(string.format("✓ %s (id: %d)", client.name, client.id))
      end
    else
      print("✗ No clients attached")
    end

    vim.cmd("quit!")
  end, 4000)
end, 500)
```

### test_root_dir.lua
Tests if root_dir config is working:
```lua
vim.defer_fn(function()
  local html_config = vim.lsp.config.html

  print("=== HTML LSP Config ===")
  print("filetypes:", vim.inspect(html_config.filetypes))
  print("cmd:", vim.inspect(html_config.cmd))
  print("root_dir type:", type(html_config.root_dir))

  if html_config.root_dir then
    vim.cmd("edit app/views/donations/new.html.erb")
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    print("\nTesting root_dir function:")
    local ok, root = pcall(html_config.root_dir, bufname, bufnr)
    if ok then
      print("  root_dir result:", root or "nil")
    else
      print("  root_dir error:", root)
    end
  end

  vim.cmd("quit!")
end, 500)
```

Run with:
```bash
nvim --headless -u ~/.config/nvim/init.lua -S tmp/test_root_dir.lua 2>&1
```

## Files Modified

### ~/.config/nvim/lua/devcontainer_helpers/init.lua

**Lines 137-161: RPC wrapping with deepcopy**
```lua
-- Wrap the underlying RPC notify method
client.rpc.notify = function(method, params)
  if params and type(params) == "table" and params.textDocument and params.textDocument.uri then
    params = vim.deepcopy(params)  -- ✅ FIXED: Prevent mutation
    local ok, path = pcall(vim.uri_to_fname, params.textDocument.uri)
    if ok then
      params.textDocument.uri = vim.uri_from_fname(host_to_container_path(path))
    end
  end
  return original_rpc_notify(method, params)
end
```

**Lines 98-125: Response handler with deepcopy**
```lua
local function setup_response_handlers()
  local function translate_response(value)
    if type(value) == "table" then
      if value.uri then
        value.uri = vim.uri_from_fname(container_to_host_path(vim.uri_to_fname(value.uri)))
      end
      for k, v in pairs(value) do
        value[k] = translate_response(v)
      end
    end
    return value
  end

  local original_handlers = vim.lsp.handlers
  for method, handler in pairs(original_handlers) do
    vim.lsp.handlers[method] = function(err, result, ctx, config)
      if result then
        result = vim.deepcopy(result)  -- ⚠️ ATTEMPTED FIX: Still crashes
        result = translate_response(result)
      end
      return handler(err, result, ctx, config)
    end
  end
end
```

### ~/.config/nvim/init.lua

**Lines ~997-1016: Config merging with lspconfig defaults**
```lua
-- Setup each LSP server
local server_names = {}
for server_name, server_config in pairs(servers) do
  -- Load lspconfig defaults if available
  local ok, lspconfig_server = pcall(require, 'lspconfig.configs.' .. server_name)
  local base_config = {}
  if ok and lspconfig_server and lspconfig_server.default_config then
    base_config = vim.tbl_deep_extend('force', {}, lspconfig_server.default_config)
  end

  -- Merge: lspconfig defaults <- our config <- capabilities
  server_config = vim.tbl_deep_extend('force', base_config, server_config, ...)

  -- ... rest of config
end
```

**Lines ~1033-1065: FileType autocmds instead of vim.lsp.enable()**
```lua
-- Enable all configured LSP servers using FileType autocmds
for _, server_name in ipairs(server_names) do
  local lsp_config = vim.lsp.config[server_name]
  if lsp_config and lsp_config.filetypes then
    vim.api.nvim_create_autocmd('FileType', {
      pattern = lsp_config.filetypes,
      callback = function(args)
        -- Build config for vim.lsp.start(), computing root_dir if it's a function
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        local root_dir = lsp_config.root_dir
        if type(root_dir) == 'function' then
          root_dir = root_dir(bufname, args.buf)
        end

        -- Create start config with only the fields vim.lsp.start() needs
        local start_config = {
          name = server_name,
          cmd = lsp_config.cmd,
          root_dir = root_dir,
          capabilities = lsp_config.capabilities,
          settings = lsp_config.settings,
          before_init = lsp_config.before_init,
          on_attach = lsp_config.on_attach,
          handlers = lsp_config.handlers,
          init_options = lsp_config.init_options,
        }

        vim.lsp.start(start_config, { bufnr = args.buf })
      end,
    })
  end
end
```

## Patch File

Complete diff saved to: `/Users/rohrer/c/bn/mrclean/tmp/nvim_config_changes.patch`

Apply with:
```bash
cd ~/.config/nvim
git apply /Users/rohrer/c/bn/mrclean/tmp/nvim_config_changes.patch
```

## Theories for Next Session

### Theory 1: Response Handler Wrapping Issue
The `setup_response_handlers()` wraps ALL LSP handlers globally. This means:
- Every response from every LSP goes through path translation
- Even non-devcontainer LSPs (ruby_lsp) get their responses deep copied
- This might break ruby_lsp or cause issues

**Test**: Only wrap handlers for devcontainer LSPs, not all handlers globally

### Theory 2: Deep Copy is Too Expensive
Even one deep copy per response might be too expensive for large responses (like full file content in didOpen).

**Test**: Only deep copy if response contains URIs that need translation

### Theory 3: vscode-langservers-extracted Specific Issue
All failing LSPs are from the same package. Maybe they share code that's sensitive to our modifications.

**Test**: Try a different HTML LSP (not from vscode-langservers-extracted)

### Theory 4: Response Translation is Corrupting Data
The recursive `translate_response()` might be corrupting response structure in ways that vscode LSPs can't handle.

**Test**:
- Add detailed logging to see what responses look like before/after translation
- Check if translated URIs are actually valid
- Verify the recursion doesn't break array structures

### Theory 5: Missing Error Logging
The real error might be happening but not being logged.

**Test**:
- Wrap LSP process in a script that captures all stderr
- Check if `deve` wrapper is suppressing errors
- Run vscode-html-language-server directly (not via deve) to see if it works

### Theory 6: Async/Timing Issue
Maybe responses arrive while we're still processing previous ones, causing race conditions.

**Test**: Add mutex/locking around response handler

## Recommended Next Steps

1. **Simplify response handler**: Only translate if result contains URIs, don't wrap all handlers
2. **Add detailed logging**: Log every response before/after translation to see what's breaking
3. **Test without devcontainer**: Run nvim inside devcontainer to eliminate host/container complexity
4. **Try different HTML LSP**: Test with html-lsp or emmet-ls instead of vscode-langservers-extracted
5. **Check for upstream issues**: Search vscode-langservers-extracted GitHub for similar problems
6. **Minimal reproduction**: Create smallest possible config that reproduces the issue

## Commands to Revert

```bash
cd ~/.config/nvim
git restore init.lua lua/devcontainer_helpers/init.lua
```

## Debug Log Level

Note: I set log level to DEBUG which causes performance issues. Revert with:
```lua
vim.lsp.set_log_level('WARN')  -- or 'INFO'
```

## Key Insight for Future

The fact that:
- Ruby LSP works perfectly
- HTML LSP crashes after working briefly
- No error messages

Strongly suggests the issue is in **how we're handling responses**, not in startup/config. The response handler modification is the smoking gun, but my deep copy approach isn't solving it correctly.

The next person should focus on making response translation more surgical - only touch what needs to be translated, don't wrap everything globally.
