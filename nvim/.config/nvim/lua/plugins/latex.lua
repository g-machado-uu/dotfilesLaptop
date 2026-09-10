return {
  -- Improve concealment for better readability
  {
    "lervag/vimtex",
    lazy = false,
    config = function()
      vim.g.vimtex_view_general_viewer = "okular"
      vim.g.vimtex_view_general_options = "--unique file:@pdf\\#src:@line@tex"
      vim.g.tex_flavor = "latex"
      vim.g.vimtex_compiler_progname = "nvr"
      vim.g.vimtex_view_forward_search_on_start = false
      vim.g.vimtex_imaps_enabled = 0
      vim.g.vimtex_syntax_conceal_disable = 0
      vim.g.tex_conceal = "abdmg"
    end,
  },
}
