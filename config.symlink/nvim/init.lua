-- prefer , rather than default \
vim.g.mapleader = ','
vim.g.maplocalleader = ','

vim.g.have_nerd_font = false

vim.opt.showmode = false

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.opt.breakindent = true

vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the
-- search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = false

vim.opt.signcolumn = 'yes'

vim.opt.updatetime = 250

vim.opt.timeoutlen = 300

-- Auto-reload files when changed externally
vim.opt.autoread = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split'

vim.opt.cursorline = true

-- center the cursor
vim.opt.scrolloff = 999

-- Allow backspace over line breaks, indent, and insert-start
vim.opt.backspace = 'start,indent,eol'

-- Minimum width for current window
vim.opt.winwidth = 81
-- Keep windows equally sized when splitting
vim.opt.equalalways = true

-- Show confirmation dialog for unsaved changes
vim.opt.confirm = true

-- Jump to existing window if buffer is already open
vim.opt.switchbuf = 'useopen'

-- Look for tags file in .git directory as well
vim.opt.tags:append '.git/tags'

-- tab/indentation settings
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- Save on any buffer/window switch or exit
vim.opt.autowriteall = true

-- deactivate mouse support
vim.opt.mouse = ''

-- configure completions
vim.opt.completeopt = 'menuone,popup,longest'

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- keep selection after visual in/out-dent
vim.keymap.set('v', '>', '>gv')
vim.keymap.set('v', '<', '<gv')

-- Toggle paste mode for current file
vim.keymap.set('n', '<leader>p', ':setlocal paste!<cr>', { remap = false })

-- visually select the last pasted hunk
vim.keymap.set('n', '<leader>vp', '`[v`]', { remap = false })

-- use ctrl-n/p in normal mode to cycle through the quickfix list
vim.keymap.set('n', '<C-n>', ':cn<CR>', { remap = false })
vim.keymap.set('n', '<C-p>', ':cp<CR>', { remap = false })

-- <c-c> is not exactly equivalent to <esc> - make it so
vim.keymap.set('n', '<C-c>', '<esc>', { remap = false })
vim.keymap.set('i', '<C-c>', '<esc>', { remap = false })

-- make grep easier
vim.keymap.set('n', '<leader>f', ':grep <C-R><C-A>', { remap = false })

-- Edit or view files in same directory as current file
vim.keymap.set('c', '%%', "<C-R>=expand('%:h').'/'<cr>", { remap = false })
vim.keymap.set('n', '<leader>de', ':edit %%<CR>')
vim.keymap.set('n', '<leader>dv', ':vsplit %%<cr>')

-- make it easier to tweak
vim.keymap.set('n', '<leader>ev', ':vsplit $MYVIMRC<cr>')

-- move by display lines
vim.keymap.set('n', 'k', 'gk', { remap = false })
vim.keymap.set('n', 'j', 'gj', { remap = false })

-- delete all buffers
vim.keymap.set('n', '<leader>dd', ':%bdelete<cr>')

-- cleanup the current buffer
local function cleanup()
  -- Handle SQL files with sqlfmt if available
  if vim.fn.executable('sqlfmt') == 1 and vim.bo.filetype == 'sql' then
    vim.cmd([[%!sqlfmt --tab-width 2 --use-spaces]])
    return
  end

  -- Save current position and search register
  local save_cursor = vim.fn.getpos('.')
  local old_query = vim.fn.getreg('/')

  -- Apply tab/space settings
  vim.cmd('retab')

  -- Reindent entire file
  vim.cmd('normal! gg=G')

  -- Strip trailing whitespace
  vim.cmd([[%s/\s\+$//e]])

  -- Remove multiple blank lines
  vim.cmd([[%s/\n\{3,}/\r\r/e]])

  -- Restore cursor position and search register
  vim.fn.setpos('.', save_cursor)
  vim.fn.setreg('/', old_query)
end

vim.keymap.set('n', '<leader>cu', function()
  cleanup()
end, { silent = true, noremap = true })

local function rename_file()
  local old_name = vim.fn.expand('%')
  local new_name = vim.fn.input('New file name: ', vim.fn.expand('%'), 'file')

  if new_name ~= '' and new_name ~= old_name then
    vim.cmd('saveas ' .. new_name)
    vim.fn.delete(old_name)
    vim.cmd('redraw!')
  end
end

vim.keymap.set('n', '<leader>rn', rename_file,
  { silent = true, noremap = true }
)

-- open a window with routes for a project
local function show_routes()
  -- Create top split window with Routes title
  vim.cmd('topleft 100 split __Routes__')

  -- Set buffer options
  vim.bo.buftype = 'nofile'
  vim.opt_local.wrap = false

  -- Clear buffer content
  vim.cmd('normal! gg"_dG')

  -- Execute rails routes and put output in buffer
  vim.cmd('0r! rails routes')

  -- Get number of lines and resize window
  local line_count = vim.fn.line('$')
  vim.cmd('normal! ' .. line_count .. '_')

  -- Move cursor to top and remove empty trailing line
  vim.cmd('normal! ggdd')
end

vim.keymap.set('n', '<leader>rr', show_routes, { silent = true })

vim.diagnostic.config({
  virtual_text = false,
  underline = false
})

vim.filetype.add({
  filename = {
    ["aliases"] = "zsh",
  },
  pattern = {
    [".*/aliases"] = "zsh",
  },
})

-- put results of :grep in quickfix window
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  pattern = {'grep', 'vimgrep'},
  group = vim.api.nvim_create_augroup('qfgrep', { clear = true }),
  callback = function()
    vim.cmd.cwindow()
  end
})

-- use my grepprg setup
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('fixrg', { clear = true }),
  callback = function()
    if vim.fn.executable('rg') == 1 then
      vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden'
      vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
    else
      vim.opt.grepprg = 'ag --smart-case --nogroup --nocolor'
      vim.opt.grepformat = '%f:%l:%m,%f:%l%m,%f  %l%m'
    end
  end
})

-- syntax highlighting for files that are in fact ruby
vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
  pattern = { 'Vagrantfile', 'Rakefile', 'Guardfile', 'Cheffile', 'Brewfile' },
  group = vim.api.nvim_create_augroup('reallyruby', { clear = true }),
  callback = function()
    vim.bo.filetype = 'ruby'
    -- vim.opt_local.iskeyword:append('!,?')
  end
})

-- open help in a vertical split
vim.api.nvim_create_augroup('help', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = 'help',
  pattern = 'help',
  callback = function()
    vim.cmd('wincmd L')
  end
})

-- create folder for file if it doesn't exist
vim.api.nvim_create_augroup('dowhatimean', { clear = true })

vim.api.nvim_create_autocmd('BufWritePre', {
  group = 'dowhatimean',
  callback = function()
    local dir = vim.fn.expand('%:p:h')
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
      print('created directory: ' .. dir)
    end
  end
})

-- dts inserts the current timestamp in insert mode
vim.cmd [[iabbrev <expr> dts strftime('%Y-%m-%d %H:%M:%S %Z')]]

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('journal', { clear = true }),
  pattern = '*/journal.md.pgp',
  callback = function()
    -- Get formatted date string
    local format = '%Y-%m-%d %H:%M'
    local timestamp = os.date(format)

    -- Get current buffer
    local buf = vim.api.nvim_get_current_buf()

    -- Insert the header at the top of the file
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
      '## ' .. timestamp,
      '',
      '',
      ''
    })

    -- Move cursor to the empty line
    vim.api.nvim_win_set_cursor(0, {3, 0})
  end
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- change some settings when window is active
vim.api.nvim_create_augroup('activewindow', { clear = true })

vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'BufWinEnter' }, {
  group = 'activewindow',
  callback = function()
    if vim.bo.filetype == 'help' then
      return
    end

    vim.opt_local.cursorline = true
    vim.opt_local.colorcolumn = '80'
    vim.opt_local.signcolumn = 'yes'
    vim.opt_local.number = true
    vim.opt_local.relativenumber = true
  end,
})

vim.api.nvim_create_autocmd('WinLeave', {
  group = 'activewindow',
  callback = function()
    vim.opt_local.cursorline = false
    vim.opt_local.colorcolumn = '0'
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

-- restore last cursor position
vim.api.nvim_create_autocmd({'BufWinEnter','BufReadPost'}, {
  group = vim.api.nvim_create_augroup('lastmark', { clear = true }),
  callback = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname:match("COMMIT_EDITMSG$") or bufname:match("MERGE_MSG$") then
      return
    end

    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end
})

-- make it easier to edit translation files
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('translation_keys', { clear = true }),
  callback = function()
    local file_path = 'config/locales/pending-upload.yml'

    if vim.fn.filereadable(file_path) == 1 then
      vim.keymap.set('n', '<leader>et', function()
        vim.cmd('tabedit ' .. file_path)
      end, { silent = true, noremap = true })

      vim.keymap.set('n', '<leader>vt', function()
        vim.cmd('vsplit ' .. file_path)
      end, { silent = true, noremap = true })
    end
  end
})

-- highlight curly templates correctly
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  group = vim.api.nvim_create_augroup('curly', { clear = true }),
  pattern = '*.curly',
  callback = function()
    vim.bo.filetype = 'html.mustache'
    vim.bo.syntax = 'mustache'
  end,
})

-- change ruby defaults
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup('rubysettings', { clear = true }),
  pattern = { "ruby", "eruby" },
  callback = function()
    vim.g.ruby_indent_assignment_style = 'variable'
    vim.g.ruby_indent_hanging_elements = 0
  end,
})

-- Disable autocomplete in markdown, text, and gitcommit files
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text', 'gitcommit' },
  group = vim.api.nvim_create_augroup('disable_cmp', { clear = true }),
  callback = function()
    require('cmp').setup.buffer({ enabled = false })
  end
})

-- Auto-continue lists in markdown, text, and gitcommit files
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text', 'gitcommit' },
  group = vim.api.nvim_create_augroup('auto_lists', { clear = true
  }),
  callback = function()
    vim.opt_local.formatoptions:append('o')
    vim.opt_local.comments = 'b:- [ ],b:- [x],b:- [X],b:-,b:*'
  end
})

-- Enable CsvView for CSV files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'csv',
  group = vim.api.nvim_create_augroup('csvview_auto', { clear = true }),
  callback = function()
    vim.cmd('CsvViewEnable')
  end
})

-- Diag for viewing Diagnostics
local function show_diagnostics(line)
  line = line or vim.fn.line('.')
  vim.diagnostic.open_float({pos = {line - 1, 0}})
end

vim.api.nvim_create_user_command('Diag', function(opts)
  local line = opts.args and tonumber(opts.args) or nil
  show_diagnostics(line)
end, { nargs = '?' })

vim.keymap.set('n', '<leader>d', show_diagnostics, { desc = 'Show line diagnostics' })

-- Poll for external file changes every 500ms.
-- Pulls in changes to the file by external programs without focusing on the
-- tmux pane or nvim buffer.
local timer = vim.uv.new_timer()
timer:start(0, 500, vim.schedule_wrap(function()
  vim.cmd('checktime')
end))

-- [[ Devcontainer Helpers ]]
-- Keep command wrapping small and explicit. LSP clients run on the host.
local devcontainer_file = vim.fs.joinpath(vim.fn.getcwd(), '.devcontainer', 'devcontainer.json')
local has_devcontainer = vim.fn.filereadable(devcontainer_file) == 1
local devcontainer_enabled = has_devcontainer
    and vim.env.RUNNING_IN_DEVCONTAINER ~= '1'
    and vim.fn.executable('deve') == 1

if has_devcontainer and not devcontainer_enabled and vim.env.RUNNING_IN_DEVCONTAINER ~= '1' then
  vim.notify('Devcontainer commands are disabled because deve is not installed', vim.log.levels.INFO)
end

local function devcontainer_command(command)
  return devcontainer_enabled and 'deve ' .. command or command
end

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  'junegunn/fzf',
  'lervag/lists.vim',
  'mustache/vim-mustache-handlebars',
  'tpope/vim-bundler',
  'tpope/vim-endwise',
  'tpope/vim-eunuch',
  'tpope/vim-fugitive',
  'tpope/vim-rake',
  'tpope/vim-sleuth',
  'tpope/vim-surround',
  'tpope/vim-vinegar',

  {
    'tinted-theming/tinted-vim',
    init = function()
      vim.cmd.colorscheme 'base16-dracula'

    end
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        ruby = { "standardrb" },
        javascript = { "standardjs" },
        javascriptreact = { "standardjs" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
      }

      -- Configure standardrb to ignore exit code 1 (which means violations found)
      lint.linters.standardrb.ignore_exitcode = true

      local function linter_is_available(linter)
        local command = linter.cmd
        if type(command) == "function" then
          command = command()
        end

        return vim.fn.executable(command) == 1
      end

      -- Do not lint while a file is opening. Missing commands are filtered out.
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup('nvim_lint', { clear = true }),
        callback = function()
          if vim.bo.modifiable then
            lint.try_lint(nil, { filter = linter_is_available })
          end
        end,
      })
    end
  },

  {
    'tpope/vim-rails',
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'eruby.yaml',
        group = vim.api.nvim_create_augroup('rails', { clear = true }),
        command = 'set filetype=yaml'
      })
    end
  },

  {
    'mattn/emmet-vim',
    config = function()
      vim.g.user_emmet_mode = 'i'

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'html', 'css', 'scss', 'eruby', 'html.mustache' },
        group = vim.api.nvim_create_augroup('emmet', { clear = true }),
        callback = function()
          vim.keymap.set('i', '<C-e>', '<Cmd>call emmet#expandAbbr(3,"")<CR>',
            { buffer = true, silent = true })
        end
      })
    end
  },

  {
    'ludovicchabant/vim-gutentags',
    config = function()
      vim.g.gutentags_ctags_exclude = {
        'node_modules/*',
        'vendor/*',
        'public/*',
        'app/assets/stylesheets/*',
        'app/assets/images/*',
        'config/quickpay/*',
        'tmp/*',
        'config/locales/*',
      }
    end
  },

  {
    'jamessan/vim-gnupg',
    config = function()
      vim.g.GPGDefaultRecipients = { "Matt Rohrer <matt@prognostikos.com>" }
    end
  },

  {
    'tpope/vim-dispatch',
    config = function()
      if devcontainer_enabled then
        vim.api.nvim_create_autocmd('FileType', {
          pattern = 'ruby',
          group = vim.api.nvim_create_augroup('dispatch_devcontainer', { clear = true }),
          callback = function()
            vim.bo.makeprg = devcontainer_command('bin/rails')
          end
        })
      end

      vim.keymap.set('n', '<leader>rm', '<cmd>Dispatch<cr>', {
        silent = true
      })
    end
  },

  {
    'janko-m/vim-test',
    config = function()
      if devcontainer_enabled then
        vim.g['test#ruby#rspec#executable'] = devcontainer_command('bin/rspec')
      end

      vim.g['test#strategy'] = 'dispatch'
      vim.keymap.set('n', '<leader>rt', '<cmd>TestFile<cr>', {
        silent = true,
      })
      vim.keymap.set('n',  '<leader>rT', '<cmd>TestNearest<cr>', {
        silent = true,
      })
    end
  },

  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    dependencies = { 'hrsh7th/nvim-cmp' },
    config = function()
      require('nvim-autopairs').setup {}
      local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
      local cmp = require 'cmp'
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },

  {
    'AndrewRadev/splitjoin.vim',
    config = function()
      vim.g.splitjoin_split_mapping = ""
      vim.g.splitjoin_join_mapping = ""
      vim.g.splitjoin_ruby_curly_braces = 0
      vim.g.splitjoin_ruby_hanging_args = 0

      vim.keymap.set('n', '<leader>sj', ':SplitjoinSplit<CR>', {
        remap = false, silent = true
      })
    end
  },

  {
    'lervag/wiki.vim',
    config = function()
      vim.g.wiki_global_load = 0

      local wiki_path = vim.env.VIM_WIKI_ROOT or '~/Documents/wiki'
      local wiki_dir = vim.fn.expand(wiki_path)
      if vim.fn.isdirectory(wiki_dir) == 1 then
        vim.g.wiki_root = wiki_path
      end

      vim.keymap.set('n', '<leader>wo', '<cmd>WikiOpen<cr>', {
        silent = true, desc = '[W]iki [O]pen'
      })
      vim.keymap.set('n', '<leader>wp', '<cmd>WikiPages<cr>', {
        silent = true, desc = '[W]iki [P]ages'
      })
      vim.keymap.set('n', '<leader>wi', '<cmd>WikiIndex<cr>', {
        silent = true, desc = '[W]iki [I]ndex'
      })
    end
  },

  { "qadzek/link.vim" },

  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup(
        {
          signs = {
            add = { text = '+' },
            change = { text = '~' },
            delete = { text = '_' },
            topdelete = { text = '‾' },
            changedelete = { text = '~' },
          },
          linehl = true
        }
      )

      vim.keymap.set('n', '<leader>gp', ':Gitsigns preview_hunk<cr>', {})
      vim.keymap.set('n', '<leader>gb', ':Gitsigns toggle_current_line_blame<cr>', {})
      vim.keymap.set('n', '<leader>gl', ':Gitsigns toggle_linehl<cr>', {})
    end
  },

  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',

        build = 'make',

        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()

      require('telescope').setup {
        pickers = {
          find_files = {
            hidden = true,
            file_ignore_patterns = { '.git/' },
          },
        },
        defaults = {
          mappings = {
            i = {
              ['<C-s>'] = require('telescope.actions').select_horizontal,
            },
            n = {
              ['<C-s>'] = require('telescope.actions').select_horizontal,
            }
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>t', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'j-hui/fidget.nvim', opts = {} },

      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          map('<leader>rN', vim.lsp.buf.rename, '[R]e[n]ame')

          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          map('K', vim.lsp.buf.hover, '[K] Hover/Diagnostics')

          map('<leader>lf', vim.lsp.buf.format, 'Format Buffer')
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      local servers = {
        ruby_lsp = {
          cmd = { "ruby-lsp" },
          filetypes = { "ruby", "eruby" },
          init_options = {
            formatter = "standard",
            addonSettings = {
              ["Ruby LSP Rails"] = {
                enablePendingMigrationsPrompt = false,
              },
            },
          },
        },
        ts_ls = {
          cmd = { "typescript-language-server", "--stdio" },
          filetypes = { 'typescript', 'javascript' },
        },

        lua_ls = {
          cmd = { "lua-language-server" },
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },

        -- vscode-langservers-extracted
        html = {
          cmd = { "vscode-html-language-server", "--stdio" },
          filetypes = { "html", "eruby" },
        },
        cssls = {
          cmd = { "vscode-css-language-server", "--stdio" },
          filetypes = { "css", "scss", "less" },
        },
        jsonls = {
          cmd = { "vscode-json-language-server", "--stdio" },
          filetypes = { "json", "jsonc" },
        },
        eslint = {
          cmd = { "vscode-eslint-language-server", "--stdio" },
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        }
      }

      local server_names = {}
      for server_name, server_config in pairs(servers) do
        server_config.capabilities = vim.tbl_deep_extend(
          'force',
          {},
          capabilities or {},
          server_config.capabilities or {}
        )

        vim.lsp.config(server_name, server_config)
        table.insert(server_names, server_name)
      end

      vim.lsp.enable(server_names)
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            config = function()
              require('luasnip.loaders.from_vscode').lazy_load()
            end,
          },
        },
      },
      'saadparwaiz1/cmp_luasnip',

      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer',
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}
      luasnip.filetype_extend("ruby", {"rails"})

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },

        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          ['<C-y>'] = cmp.mapping.confirm { select = true },

          ['<C-Space>'] = cmp.mapping.complete {},

          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),

        },
        sources = {
          {
            name = 'lazydev',
            group_index = 0,
          },
          { name = 'buffer' },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      }
    end,
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    commit = 'cf12346a3414fa1b06af75c79faebe7f76df080a',
    dependencies = {
      'RRethy/nvim-treesitter-endwise'
    },
    build = ':TSUpdate',
    config = function(_, opts)
      if vim.fn.has('nvim-0.12') == 1 then
        -- Neovim 0.12 may hand directive captures to the frozen nvim-treesitter
        -- master branch as one-element tables instead of bare TSNodes.
        local query = require('vim.treesitter.query')
        local directive_opts = vim.fn.has('nvim-0.10') == 1 and { force = true, all = false } or true
        local html_script_type_languages = {
          ["importmap"] = "json",
          ["module"] = "javascript",
          ["application/ecmascript"] = "javascript",
          ["text/ecmascript"] = "javascript",
        }
        local non_filetype_match_injection_language_aliases = {
          ex = "elixir",
          pl = "perl",
          sh = "bash",
          uxn = "uxntal",
          ts = "typescript",
        }

        local function unwrap_query_capture(node)
          if type(node) == 'table' then
            return node[#node]
          end
          return node
        end

        local function parser_from_markdown_info_string(injection_alias)
          local match = vim.filetype.match { filename = "a." .. injection_alias }
          return match or non_filetype_match_injection_language_aliases[injection_alias] or injection_alias
        end

        query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
          local node = unwrap_query_capture(match[pred[2]])
          if not node then
            return
          end

          local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
          local configured = html_script_type_languages[type_attr_value]
          if configured then
            metadata["injection.language"] = configured
          else
            local parts = vim.split(type_attr_value, "/", {})
            metadata["injection.language"] = parts[#parts]
          end
        end, directive_opts)

        query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
          local node = unwrap_query_capture(match[pred[2]])
          if not node then
            return
          end

          local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
          metadata["injection.language"] = parser_from_markdown_info_string(injection_alias)
        end, directive_opts)

        query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
          local id = pred[2]
          local node = unwrap_query_capture(match[id])
          if not node then
            return
          end

          local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
          if not metadata[id] then
            metadata[id] = {}
          end
          metadata[id].text = string.lower(text)
        end, directive_opts)
      end

      require('nvim-treesitter.configs').setup(opts)
    end,
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'ruby',
        'query',
        'vim',
        'vimdoc',
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
      endwise = {
        enable = true
      }
    },
  },

  {
    'hat0uma/csvview.nvim',
    opts = {
      parser = {
        delimiter = {
          ft = {}
        }
      }
    }
  },

  'tpope/vim-rsi',

}, {
    rocks = {
      enabled = false,
    },
    ui = {
      icons = vim.g.have_nerd_font and {} or {
        cmd = '⌘',
        config = '🛠',
        event = '📅',
        ft = '📂',
        init = '⚙',
        keys = '🗝',
        plugin = '🔌',
        runtime = '💻',
        require = '🌙',
        source = '📄',
        start = '🚀',
        task = '📌',
        lazy = '💤 ',
      },
    },
  })
