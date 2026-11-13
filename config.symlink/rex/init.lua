-- Rex keybindings modeled on tmux/tmux.conf.symlink
-- Docs: https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts
-- List available actions: rex -C <client> actions
-- Apply changes: rex config reload

local prefix = "ctrl+a"

local function bind(key, action, args)
  rex.bind(prefix .. ">" .. key, action, args)
end

-- behave like screen: C-a prefix, C-a C-a sends a literal C-a
bind("ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- vim-command-t -like shortcuts for new panes
bind("ctrl+v", "pane.split", { direction = "right" })
bind("ctrl+s", "pane.split", { direction = "down" })

-- vim-like movement between panes
bind("h", "pane.focus.left")
bind("j", "pane.focus.down")
bind("k", "pane.focus.up")
bind("l", "pane.focus.right")

-- vim-like pane resize, repeatable like `bind -r`: the first press resizes
-- and enters resize mode, where H/J/K/L keep resizing until Escape or Enter
local resize_amount = 5
local directions = { h = "left", j = "down", k = "up", l = "right" }

rex.mode("resize", {})
rex.bind("resize/enter", "client.mode.exit")

for key, direction in pairs(directions) do
  local name = "resize_" .. direction
  rex.action{
    name  = name,
    title = "Resize Pane " .. direction .. " (repeatable)",
    run   = function(ctx, args)
      rex.client.queue("pane.resize", { direction = direction, amount = resize_amount })
      rex.client.queue("client.mode.enter", { name = "resize" })
    end,
  }
  bind("shift+" .. key, name)
  rex.bind("resize/shift+" .. key, "pane.resize", {
    direction = direction,
    amount = resize_amount,
  })
end

-- popups
bind("u", "pane.new_floating")
bind("s", "session.switch")
bind("f", "pane.insert_path")

-- closest match to `switch-client -l`
bind("space", "session.previous")

-- tmux defaults
bind("c", "client.tab.new")
bind("n", "client.tab.next")
bind("p", "client.tab.previous")
bind(",", "client.tab.rename")
bind("shift+7", "client.tab.close")       -- &
bind("shift+4", "session.rename")         -- $
bind("w", "session.switch")
bind("shift+9", "session.previous")       -- (
bind("shift+0", "session.next")           -- )
bind("shift+5", "pane.split", { direction = "right" }) -- %
bind("shift+'", "pane.split", { direction = "down" })  -- "
bind("x", "pane.close")
bind("z", "pane.zoom")
bind("o", "pane.focus_next")
bind("shift+1", "pane.move_to_new_tab")   -- !
bind("]", "pane.paste")
bind("shift+;", "client.palette.toggle")  -- :
bind("shift+/", "client.palette.toggle")  -- ?
bind("left", "pane.focus.left")
bind("down", "pane.focus.down")
bind("up", "pane.focus.up")
bind("right", "pane.focus.right")

for i = 0, 9 do
  bind(tostring(i), "client.tab.goto", { index = i })
end

-- Capture the source pane in a floating, read-only Neovim copy window.
rex.action{
  name = "copy_mode",
  title = "Copy Mode",
  run = function(ctx)
    assert(ctx.block_id, "Copy mode needs a terminal pane")
    local info, err = rex.session.describe_block{ block_id = ctx.block_id }
    assert(info, err)
    local result, create_err = rex.session.new_layer{
      window_id = info.block.window_id,
      bounds = { 0.03, 0.03, 0.94, 0.94 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = {
          command = { "/bin/bash", os.getenv("HOME") .. "/.dotfiles/config.symlink/rex/copy-mode.sh",
            ctx.session_id, ctx.block_id },
          shell = "none",
        },
      },
    }
    assert(result, create_err)
    return result
  end,
}
bind("ctrl+c", "copy_mode")
