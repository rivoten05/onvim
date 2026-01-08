return {
  {
    "nvchad-colorify", -- A unique name for your local plugin
    dir = vim.fn.stdpath("config") .. "/lua/nvchad/colorify", -- Path to your files
    lazy = false, -- Load on startup so it can set up autocommands
    config = function()
      require("nvchad.colorify").run()
    end,
  },
}
