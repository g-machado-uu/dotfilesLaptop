return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          settings = {
            texlab = {
              -- No `build` block: VimTeX's continuous latexmk owns build/.
              -- A texlab onSave build ran a second latexmk into the same
              -- directory and corrupted the PDF/aux files.
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
