local JuliaAdapter = { name = "neotest-julia" }

---@type { [string]: TestItemDetailLSP }
local julia_tests = {}

---@type { [string]: TestItemDetailLSP }
local julia_test_setups = {}

---@type { [string]: TestErrorDetailLSP }
local julia_test_errors = {}

local julia_environment = ""
local logging = false

local log = function(...)
    if logging then
        vim.print("NEOTEST-JULIALS:", ...)
    end
end

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

-- Given the description of the test, convert it to the neotest Position type
local function position(id, type, name, path, range)
    return { id = id, type = type, name = name, path = path, range = range }
end

local function position_from_entries(path, entries)
    local positions = {}
    for _, e in pairs(entries) do
        local id = e.label
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

-- The key for the given tests
local function keyfunc(pos) return pos.name end

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

---Handles the julia test results from julia/publishTests, populating the vim.g.tests_jl
---global variable with information about the tests
---@param err any
---@param result PublishTestsParams
---@param ctx any
---@param config any
---@return boolean
local handle_julia_tests = function(err, result, ctx, config)
    local uri = result.uri
    local new_test_table = {}
    local new_setup_table = {}
    local new_error_table = {}

    log("Handling tests")
    log(result)
    if result.testItemDetails ~= nil then
        for _, test in pairs(result.testItemDetails) do
            table.insert(new_test_table, test)
        end
    end
    if result.testSetupDetails ~= nil then
        for _, setup in pairs(result.testSetupDetails) do
            table.insert(new_setup_table, setup)
        end
    end
    if result.testErrorDetails ~= nil then
        for _, error in pairs(result.testErrorDetails) do
            table.insert(new_error_table, error)
        end
    end

    local updated_test_table = julia_tests
    updated_test_table[uri] = new_test_table
    julia_tests = updated_test_table
    vim.g.tests_jl = julia_tests

    local updated_setup_table = julia_test_setups
    updated_setup_table[uri] = new_setup_table
    julia_test_setups = updated_setup_table
    vim.g.setups_jl = julia_test_setups

    local updated_error_table = julia_test_errors
    updated_error_table[uri] = new_error_table
    julia_test_errors = updated_error_table
    vim.g.errors_jl = julia_test_errors

    log("Tests", julia_tests)
    log("Setups", julia_test_setups)
    log("Errors", julia_test_errors)

    return true
end

local default_options = {
    activate = true,
    environment = "@test_item_controller",
    logging = false
}

JuliaAdapter.setup = function(_opts)
    local opts = vim.tbl_deep_extend('force', default_options, _opts)
    if opts.activate then
        vim.lsp.handlers['julia/publishTests'] = handle_julia_tests
        julia_environment = opts.environment
        logging = opts.logging

        log("Initialized with environemt", julia_environment)
    end

    return true
end

return JuliaAdapter
