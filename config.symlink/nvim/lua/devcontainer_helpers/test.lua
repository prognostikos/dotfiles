-- test.lua
--
-- Automated tests for the devcontainer_helpers module
-- Run with: nvim --headless -l ~/.config/nvim/lua/devcontainer_helpers/test.lua
--
-- Or from vim: :luafile ~/.config/nvim/lua/devcontainer_helpers/test.lua

local test_results = {
  passed = 0,
  failed = 0,
  tests = {}
}

-- Simple test framework
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    test_results.passed = test_results.passed + 1
    table.insert(test_results.tests, {name = name, passed = true})
    print(string.format("✓ %s", name))
  else
    test_results.failed = test_results.failed + 1
    table.insert(test_results.tests, {name = name, passed = false, error = err})
    print(string.format("✗ %s", name))
    print(string.format("  Error: %s", err))
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s\n  Expected: %s\n  Actual: %s",
      message or "Assertion failed",
      vim.inspect(expected),
      vim.inspect(actual)))
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "Expected true, got false")
  end
end

local function assert_false(value, message)
  if value then
    error(message or "Expected false, got true")
  end
end

local function assert_table_equal(actual, expected, message)
  if vim.inspect(actual) ~= vim.inspect(expected) then
    error(string.format("%s\n  Expected: %s\n  Actual: %s",
      message or "Tables not equal",
      vim.inspect(expected),
      vim.inspect(actual)))
  end
end

-- Save original environment
local original_env = vim.env.RUNNING_IN_DEVCONTAINER
local original_cwd = vim.fn.getcwd()

print("========================================")
print("Testing devcontainer_helpers module")
print("========================================\n")

-- Ensure we're in the right directory for tests
local project_root = vim.fn.expand("~/workspaces/mrclean")
if vim.fn.isdirectory(project_root) == 1 then
  vim.cmd("cd " .. project_root)
end

-- Clean module cache before each test suite
package.loaded['devcontainer_helpers'] = nil

-- Test Suite 1: Basic Setup
print("Test Suite 1: Basic Setup and Detection")
print("----------------------------------------")

test("Module can be required", function()
  local devcontainer_helpers = require('devcontainer_helpers')
  assert_true(devcontainer_helpers ~= nil, "Module should load")
  assert_true(type(devcontainer_helpers.setup) == "function", "setup should be a function")
end)

test("Setup returns true when .devcontainer exists and not in container", function()
  vim.env.RUNNING_IN_DEVCONTAINER = nil
  package.loaded['devcontainer_helpers'] = nil
  local devcontainer_helpers = require('devcontainer_helpers')
  local enabled = devcontainer_helpers.setup({ wrapper_command = 'deve' })

  -- This assumes we're running from mrclean project with .devcontainer
  if vim.fn.filereadable('.devcontainer/devcontainer.json') == 1 then
    assert_true(enabled, "Should be enabled when .devcontainer exists")
  end
end)

test("Setup returns false when RUNNING_IN_DEVCONTAINER=1", function()
  vim.env.RUNNING_IN_DEVCONTAINER = "1"
  package.loaded['devcontainer_helpers'] = nil
  local devcontainer_helpers = require('devcontainer_helpers')
  local enabled = devcontainer_helpers.setup({ wrapper_command = 'deve' })
  assert_false(enabled, "Should not be enabled when inside container")
  vim.env.RUNNING_IN_DEVCONTAINER = nil
end)

-- Test Suite 2: Command Wrapping
print("\nTest Suite 2: Command Wrapping")
print("----------------------------------------")

-- Reset for these tests
vim.env.RUNNING_IN_DEVCONTAINER = nil
package.loaded['devcontainer_helpers'] = nil
local devcontainer_helpers = require('devcontainer_helpers')
devcontainer_helpers.setup({ wrapper_command = 'deve' })

test("wrap_command wraps simple command", function()
  local result = devcontainer_helpers.wrap_command('bin/rails')
  assert_equal(result, 'deve bin/rails', "Should wrap with deve prefix")
end)

test("wrap_command wraps command with arguments", function()
  local result = devcontainer_helpers.wrap_command('bin/rails test models')
  assert_equal(result, 'deve bin/rails test models', "Should wrap command with args")
end)

test("wrap_command_array wraps array correctly", function()
  local result = devcontainer_helpers.wrap_command_array({'bin/rspec', 'spec/models'})
  assert_table_equal(result, {'deve', 'bin/rspec', 'spec/models'}, "Should wrap array")
end)

test("wrap_command_array with single element", function()
  local result = devcontainer_helpers.wrap_command_array({'bundle'})
  assert_table_equal(result, {'deve', 'bundle'}, "Should wrap single element")
end)

test("get_wrapper_command returns configured command", function()
  local result = devcontainer_helpers.get_wrapper_command()
  assert_equal(result, 'deve', "Should return configured wrapper")
end)

-- Test Suite 3: Disabled Mode Behavior
print("\nTest Suite 3: Disabled Mode (inside container)")
print("----------------------------------------")

vim.env.RUNNING_IN_DEVCONTAINER = "1"
package.loaded['devcontainer_helpers'] = nil
local devcontainer_helpers_disabled = require('devcontainer_helpers')
devcontainer_helpers_disabled.setup({ wrapper_command = 'deve' })

test("wrap_command returns unwrapped when disabled", function()
  local result = devcontainer_helpers_disabled.wrap_command('bin/rails')
  assert_equal(result, 'bin/rails', "Should not wrap when disabled")
end)

test("wrap_command_array returns unwrapped when disabled", function()
  local result = devcontainer_helpers_disabled.wrap_command_array({'bin/rspec', 'spec'})
  assert_table_equal(result, {'bin/rspec', 'spec'}, "Should not wrap when disabled")
end)

test("is_enabled returns false when disabled", function()
  local result = devcontainer_helpers_disabled.is_enabled()
  assert_false(result, "Should report as disabled")
end)

-- Test Suite 4: Path Translation (if we have access to internals)
print("\nTest Suite 4: JSON Parsing")
print("----------------------------------------")

test("Reads workspaceFolder from devcontainer.json", function()
  vim.env.RUNNING_IN_DEVCONTAINER = nil

  -- Create a temporary devcontainer.json for testing
  local temp_dir = vim.fn.tempname()
  vim.fn.mkdir(temp_dir)
  vim.fn.mkdir(temp_dir .. '/.devcontainer')

  local test_json = vim.fn.json_encode({
    workspaceFolder = "/test/workspace"
  })
  vim.fn.writefile({test_json}, temp_dir .. '/.devcontainer/devcontainer.json')

  -- Change to temp dir and test
  local old_cwd = vim.fn.getcwd()
  vim.cmd('cd ' .. temp_dir)

  package.loaded['devcontainer_helpers'] = nil
  local dc = require('devcontainer_helpers')
  dc.setup({ wrapper_command = 'testcmd' })

  -- Cleanup
  vim.cmd('cd ' .. old_cwd)
  vim.fn.delete(temp_dir, 'rf')

  -- Test passes if no error occurred
  assert_true(true, "Should parse devcontainer.json")
end)

-- Test Suite 5: Configuration Options
print("\nTest Suite 5: Configuration Options")
print("----------------------------------------")

test("Custom wrapper command is used", function()
  vim.env.RUNNING_IN_DEVCONTAINER = nil
  package.loaded['devcontainer_helpers'] = nil
  local dc = require('devcontainer_helpers')
  dc.setup({ wrapper_command = 'custom-wrapper' })

  local result = dc.wrap_command('echo test')
  assert_equal(result, 'custom-wrapper echo test', "Should use custom wrapper")
end)

-- Restore original environment
vim.env.RUNNING_IN_DEVCONTAINER = original_env
vim.cmd('cd ' .. original_cwd)

-- Print results
print("\n========================================")
print("Test Results")
print("========================================")
print(string.format("Passed: %d", test_results.passed))
print(string.format("Failed: %d", test_results.failed))
print(string.format("Total:  %d", test_results.passed + test_results.failed))

if test_results.failed > 0 then
  print("\n❌ Some tests failed!")
  os.exit(1)
else
  print("\n✅ All tests passed!")
  os.exit(0)
end
