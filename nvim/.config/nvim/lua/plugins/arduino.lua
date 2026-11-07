-- Arduino support: LSP (arduino-language-server) + compile/upload/monitor keymaps.
--
-- Requirements (one-time):
--   arduino-cli config init              -> creates ~/.arduino15/arduino-cli.yaml
--   arduino-cli core install <core>      -> e.g. arduino:samd, arduino:avr
--   :MasonInstall arduino-language-server
--   user in the `dialout` group          -> serial port access on Linux
--
-- Per sketch: put a sketch.yaml next to the .ino file:
--   default_fqbn: arduino:samd:mkr1000   <- `arduino-cli board list` shows the FQBN
--   default_port: /dev/ttyACM0
-- The LSP reads default_fqbn from it; `arduino-cli compile/upload` read both.
-- After changing the board, run :LspRestart.

-- Board used when a sketch has no sketch.yaml (or no default_fqbn in it).
-- Change this if you mostly work with another board.
local function sketch_fqbn(dir)
  local f = io.open(dir .. "/sketch.yaml")
  if not f then
    return "arduino:samd:mkr1000"
  end
  local fqbn = f:read("*a"):match("default_fqbn:%s*(%S+)")
  f:close()
  return fqbn or "arduino:samd:mkr1000"
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        arduino_language_server = {
          -- Started per sketch so each project gets its own FQBN.
          cmd = function(dispatchers, config)
            local dir = config.root_dir or vim.fn.expand("%:p:h")
            return vim.lsp.rpc.start({
              "arduino-language-server",
              -- Must exist, or the server fails to start (`arduino-cli config init`).
              "-cli-config",
              vim.fn.expand("~/.arduino15/arduino-cli.yaml"),
              "-cli",
              "arduino-cli",
              -- clangd used under the hood. "clangd" = first on $PATH (/usr/bin, v22).
              -- Put a full path here to use a different version, e.g. an older
              -- clangd (<= 20) if you want the on_init workaround below removed.
              "-clangd",
              "clangd",
              "-fqbn",
              sketch_fqbn(dir),
            }, dispatchers, { cwd = dir })
          end,

          -- WORKAROUNDS for arduino-language-server being older than clangd.
          -- Symptom if either is removed: "client quit" warning, no completion.
          -- Diagnose with :LspLog (search for "panic" or "connection error").
          -- If a future arduino-language-server fixes these, delete them and test.

          -- 1. Completion: blink.cmp asks for insert/replace edits; clangd sends
          --    them and arduino-language-server can't parse them
          --    ("undefined required field range into lsp.TextEdit").
          capabilities = {
            textDocument = { completion = { completionItem = { insertReplaceSupport = false } } },
          },
          -- 2. Symbols: clangd >= 21 adds `tags` to document symbols and
          --    arduino-language-server panics ("not implemented").
          --    Cost: no breadcrumbs or symbol outline (<leader>ss) in .ino files.
          on_init = function(client)
            client.server_capabilities.documentSymbolProvider = false
          end,
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    init = function()
      -- Highlighting: the tree-sitter `arduino` parser tags every Arduino API call
      -- (setup, loop, pinMode, digitalWrite, analogRead...) as @function.builtin,
      -- which catppuccin paints peach, the same as numbers and constants, so a
      -- sketch looks almost all orange. Colour them like ordinary calls (blue).
      -- Delete this block to get the parser's default look back.
      local function arduino_hl()
        vim.api.nvim_set_hl(0, "@function.builtin.arduino", { link = "@function.call" })
      end
      arduino_hl()
      -- :colorscheme clears custom highlights, so reapply after every change.
      vim.api.nvim_create_autocmd("ColorScheme", { callback = arduino_hl })

      -- Keymaps only in .ino buffers (nvim gives them filetype "arduino").
      -- Commands run in a Snacks terminal in the sketch folder, so they pick up
      -- sketch.yaml.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "arduino",
        callback = function(ev)
          local dir = vim.fn.expand("%:p:h")
          local function run(cmd)
            return function()
              Snacks.terminal(cmd, { cwd = dir, interactive = true })
            end
          end
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          map("<leader>Ac", run("arduino-cli compile"), "Arduino compile")
          -- Close the monitor first: upload fails if the port is in use.
          map("<leader>Au", run("arduino-cli compile -u"), "Arduino upload")
          -- Port and baud are hard-coded here, not read from sketch.yaml.
          -- Port: SAMD boards can come back as /dev/ttyACM1 after an upload
          --       (check with `arduino-cli board list`).
          -- Baud: must match Serial.begin(...) in the sketch.
          -- Quit the monitor with Ctrl-C.
          map("<leader>Am", run("arduino-cli monitor -p /dev/ttyACM0 -c baudrate=115200"), "Arduino monitor")
        end,
      })
    end,
  },
}
