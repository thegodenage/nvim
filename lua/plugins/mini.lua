return {
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "echasnovski/mini.surround",
    keys = {
      { "sa", desc = "Add surrounding",            mode = { "n", "v" } },
      { "sd", desc = "Delete surrounding" },
      { "sr", desc = "Replace surrounding" },
      { "sf", desc = "Find right surrounding" },
      { "sF", desc = "Find left surrounding" },
      { "sh", desc = "Highlight surrounding" },
    },
    opts = {
      mappings = {
        add            = "sa",
        delete         = "sd",
        find           = "sf",
        find_left      = "sF",
        highlight      = "sh",
        replace        = "sr",
        update_n_lines = "sn",
      },
    },
  },
}
