local random = math.random

math.randomseed(os.time())

local M = {}

--Generates a random-enough UUID
-- Source: https://gist.github.com/jrus/3197011
M.uuid = function()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

M.split = function(s, _sep)
    local fields = {}

    local sep = _sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

    return fields
end

return M
