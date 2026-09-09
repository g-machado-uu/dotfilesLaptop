return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          settings = {
            texlab = {
              build = {
                executable = "latexmk",
                args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                onSave = true,
              },
              forwardSearch = {
                executable = "okular",
                args = { "--unique", "file:%p#src:%l%f" },
              },
            },
          },
          -- increase timeout for complex documents
          timeout = 120000,
        },
      },
    },
  },
}
