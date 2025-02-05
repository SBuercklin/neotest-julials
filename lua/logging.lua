---@class Logger
---@field logging boolean
---@field log function
local M = {}

M.logging = false

M.log = function(...)
    if M.logging then
        vim.print("NEOTEST-JULIALS:", ...)
    end
end

return M
