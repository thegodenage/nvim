require("thegodenage.remap")
require("thegodenage.projcmds")
require("thegodenage.rust")
require("thegodenage.hcl").setup()

-- Keep all buffers unfolded unless explicitly enabled in a buffer
vim.o.foldenable = false
vim.o.foldmethod = "manual"
