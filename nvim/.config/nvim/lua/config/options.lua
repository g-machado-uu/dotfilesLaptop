-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- (LaTeX settings live in lua/plugins/latex.lua)

-- npm/node come from nvm, which only ~/.zshrc loads. Neovim started outside an
-- interactive zsh (app launcher, keybind, yazi...) wouldn't see them, and Mason
-- fails to install npm-based tools. Prepend the newest nvm node bin to PATH.
do
  local versions = vim.fn.glob(vim.fn.expand("~/.nvm/versions/node/*/bin"), false, true)
  table.sort(versions, function(a, b)
    return vim.version.lt(a:match("v([%d.]+)"), b:match("v([%d.]+)"))
  end)
  local bin = versions[#versions]
  if bin and not vim.env.PATH:find(bin, 1, true) then
    vim.env.PATH = bin .. ":" .. vim.env.PATH
  end
end
