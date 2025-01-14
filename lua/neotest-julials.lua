local JuliaAdapter = { name = "neotest-julia" }

local julia_tests = {}

JuliaAdapter.root = function(dir)
    local f = vim.fs.dirname(vim.fs.find('Project.toml', { upward = true, path = dir })[1])
    return f
end

JuliaAdapter.filter_dir = function(_, rel_path, _)
    return (rel_path == 'test') or (rel_path == 'src')
end

JuliaAdapter.is_test_file = function(file_path)
    local bname = vim.fs.basename(file_path)
    return string.sub(bname, -3, -1) == '.jl'
end

-- The key for the given tests
local function keyfunc(pos) return pos.name end

-- Given the description of the test, convert it to the neotest Position type
local function position(id, type, name, path, range)
    return { id = id, type = type, name = name, path = path, range = range }
end

local function position_from_entries(path, entries)
    local positions = {}
    for _, e in pairs(entries) do
        local id = e.id
        local type = 'test'
        local name = id
        local range = {
            e.range['start'].line,
            e.range['start'].character,
            e.range['end'].line,
            e.range['end'].character,
        }

        table.insert(positions, position(id, type, name, path, range))
    end

    return positions
end

JuliaAdapter.discover_positions = function(file_path)
    local positions = {}

    for k, v in pairs(vim.g.tests_jl) do
        local subbed = string.sub(k, 8, -1)
        if subbed == file_path then
            positions = position_from_entries(file_path, v)
        end
    end
    local max_end_row = 0
    for _, v in pairs(positions) do
        max_end_row = math.max(max_end_row, v.range[3])
    end


    local id = file_path
    local type = 'file'
    local name = vim.fn.fnamemodify(file_path, ':t')
    local path = file_path
    local range = { 0, 0, max_end_row, 0 }

    local file_pos = position(id, type, name, path, range)

    table.insert(positions, 1, file_pos)

    return require('neotest.types.tree').from_list(positions, keyfunc)
end

local handle_julia_tests = function(err, result, ctx, config)
    uri = result.uri
    local new_table = {}

    for _, test in pairs(result.testitemdetails) do
        table.insert(new_table, test)
    end

    local updated_table = julia_tests
    updated_table[uri] = new_table
    julia_tests = updated_table

    return true
end

local default_options = {}

local setup = function(_opts)
    local opts = vim.tbl_deep_extend('force', default_options, _opts)
    vim.lsp.handlers["julia/publishTests"] = handle_julia_tests
end


return JuliaAdapter
