-- devcontainer_helpers.lua
--
-- Enables LSP servers and development tools to run inside a devcontainer while nvim runs on the host.
-- Translates file paths between host and container so LSPs can find files correctly.
--
-- Features:
-- - Automatic detection of devcontainer via .devcontainer/devcontainer.json
-- - Reads workspaceFolder from devcontainer.json
-- - Only activates when NOT running inside the container
-- - Provides utilities to wrap any command to run in devcontainer
--
-- Setup:
--   local devcontainer_helpers = require('devcontainer_helpers')
--   local enabled = devcontainer_helpers.setup({
--     wrapper_command = 'deve'  -- Command that wraps devcontainer exec (e.g., 'devcontainer exec')
--   })
--
-- API:
--   devcontainer_helpers.is_enabled()                     -- Check if devcontainer mode is active
--   devcontainer_helpers.get_wrapper_command()            -- Get the wrapper command name
--   devcontainer_helpers.wrap_command('bin/rails')        -- Returns: 'deve bin/rails'
--   devcontainer_helpers.wrap_command_array({'bin/rspec'}) -- Returns: {'deve', 'bin/rspec'}
--   devcontainer_helpers.wrap_lsp_cmd(name, config)       -- Wrap LSP command for server
--   devcontainer_helpers.create_before_init(fn)           -- Create before_init hook with path translation

local M = {}

-- Default configuration
local config = {
  container_root = nil, -- Will be read from devcontainer.json
  wrapper_command = "deve",
  host_root = nil, -- Will be set to vim.fn.getcwd() if not provided
}

-- Read workspaceFolder from devcontainer.json
local function get_container_root()
  local devcontainer_json = vim.fn.getcwd() .. "/.devcontainer/devcontainer.json"

  if vim.fn.filereadable(devcontainer_json) == 0 then
    return nil
  end

  -- Read and parse the JSON file
  local ok, content = pcall(vim.fn.readfile, devcontainer_json)
  if not ok then
    return nil
  end

  local json_str = table.concat(content, "\n")
  local parsed = vim.json.decode(json_str)

  if not parsed then
    return nil
  end

  -- Return workspaceFolder if it exists, otherwise default to /workspaces/<dirname>
  if parsed.workspaceFolder then
    return parsed.workspaceFolder
  end

  -- Default: /workspaces/<project_directory_name>
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  return "/workspaces/" .. project_name
end

-- Check if we should enable devcontainer LSP support
local function should_enable()
  -- Don't enable if we're already running inside the devcontainer
  if vim.env.RUNNING_IN_DEVCONTAINER == "1" then
    return false
  end

  -- Check if .devcontainer/devcontainer.json exists in the project root
  local devcontainer_json = vim.fn.getcwd() .. "/.devcontainer/devcontainer.json"
  if vim.fn.filereadable(devcontainer_json) == 0 then
    return false
  end

  return true
end

-- Path translation functions
local function host_to_container_path(path)
  local host_root = config.host_root
  if path:sub(1, #host_root) == host_root then
    return config.container_root .. path:sub(#host_root + 1)
  end
  return path
end

local function container_to_host_path(path)
  if path:sub(1, #config.container_root) == config.container_root then
    return config.host_root .. path:sub(#config.container_root + 1)
  end
  return path
end

-- Setup response handlers to translate paths back from container to host
local function setup_response_handlers()
  -- Helper to recursively translate all URIs in a table
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

  -- Wrap LSP handlers to translate paths in responses
  local original_handlers = vim.lsp.handlers
  for method, handler in pairs(original_handlers) do
    vim.lsp.handlers[method] = function(err, result, ctx, config)
      if result then
        result = translate_response(result)
      end
      return handler(err, result, ctx, config)
    end
  end
end

-- Setup client RPC wrapping for outgoing requests
local function setup_client_wrapping()
  local vim_lsp_client = require('vim.lsp.client')
  local original_create = vim_lsp_client.create

  vim_lsp_client.create = function(lsp_config, dispatch_config)
    local client = original_create(lsp_config, dispatch_config)

    -- Only wrap devcontainer LSP clients
    if lsp_config.cmd and lsp_config.cmd[1]:match(config.wrapper_command .. "$") then
      -- Wrap the underlying RPC notify method to translate paths
      local original_rpc_notify = client.rpc.notify
      client.rpc.notify = function(method, params)
        if params and params.textDocument and params.textDocument.uri then
          local path = vim.uri_to_fname(params.textDocument.uri)
          params.textDocument.uri = vim.uri_from_fname(host_to_container_path(path))
        end
        return original_rpc_notify(method, params)
      end

      -- Wrap the underlying RPC request method to translate paths
      local original_rpc_request = client.rpc.request
      client.rpc.request = function(method, params, callback)
        if params and params.textDocument and params.textDocument.uri then
          local path = vim.uri_to_fname(params.textDocument.uri)
          params.textDocument.uri = vim.uri_from_fname(host_to_container_path(path))
        end
        return original_rpc_request(method, params, callback)
      end
    end

    return client
  end
end

-- Wrap LSP command to run in devcontainer
function M.wrap_lsp_cmd(server_name, original_config)
  local default_cmd = original_config.cmd

  -- If no cmd provided, try to get it from the nvim-lspconfig server file
  if not default_cmd then
    local ok, server_config = pcall(require, 'lspconfig.configs.' .. server_name)
    if ok and server_config and server_config.default_config then
      default_cmd = server_config.default_config.cmd
    end
  end

  if not default_cmd then
    return nil
  end

  local wrapped = { config.wrapper_command }
  for _, part in ipairs(default_cmd) do
    table.insert(wrapped, part)
  end
  return wrapped
end

-- Add before_init hook to translate initialization paths
function M.create_before_init(original_before_init)
  return function(params, lsp_config)
    -- Translate all URIs in initialization params
    if params.rootUri and type(params.rootUri) == "string" then
      local host_path = vim.uri_to_fname(params.rootUri)
      params.rootUri = vim.uri_from_fname(host_to_container_path(host_path))
    end
    if params.rootPath and type(params.rootPath) == "string" then
      params.rootPath = host_to_container_path(params.rootPath)
    end
    if params.workspaceFolders and type(params.workspaceFolders) == "table" then
      for _, folder in ipairs(params.workspaceFolders) do
        if folder.uri and type(folder.uri) == "string" then
          local host_path = vim.uri_to_fname(folder.uri)
          folder.uri = vim.uri_from_fname(host_to_container_path(host_path))
        end
        if folder.name and type(folder.name) == "string" then
          folder.name = host_to_container_path(folder.name)
        end
      end
    end

    if original_before_init then
      original_before_init(params, lsp_config)
    end
  end
end

-- Main setup function
function M.setup(opts)
  -- Merge user config with defaults
  config = vim.tbl_deep_extend('force', config, opts or {})

  -- Set host_root if not provided
  if not config.host_root then
    config.host_root = vim.fn.getcwd()
  end

  -- Check if we should enable devcontainer LSP support
  if not should_enable() then
    return false
  end

  -- Get container root from devcontainer.json if not provided
  if not config.container_root then
    config.container_root = get_container_root()
    if not config.container_root then
      vim.notify("devcontainer_lsp: Could not determine container root from devcontainer.json", vim.log.levels.ERROR)
      return false
    end
  end

  -- Setup the various hooks and wrappers
  setup_response_handlers()
  setup_client_wrapping()

  return true
end

-- Check if devcontainer LSP support is enabled
function M.is_enabled()
  return should_enable()
end

-- Get the wrapper command name
function M.get_wrapper_command()
  return config.wrapper_command
end

-- Wrap a command to run in the devcontainer
-- Usage: devcontainer_helpers.wrap_command('bin/rails test')
-- Returns: 'deve bin/rails test'
function M.wrap_command(cmd)
  if not should_enable() then
    return cmd
  end

  return config.wrapper_command .. ' ' .. cmd
end

-- Wrap a command array to run in the devcontainer
-- Usage: devcontainer_helpers.wrap_command_array({'bin/rspec', 'spec/models'})
-- Returns: {'deve', 'bin/rspec', 'spec/models'}
function M.wrap_command_array(cmd_array)
  if not should_enable() then
    return cmd_array
  end

  local wrapped = { config.wrapper_command }
  for _, part in ipairs(cmd_array) do
    table.insert(wrapped, part)
  end
  return wrapped
end

return M
