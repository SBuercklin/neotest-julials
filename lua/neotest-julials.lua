local JuliaAdapter = { name = "neotest-julia" }

local jllib = require "julials-lib"
local Globals = require "globals"
local Utils = require "utilities"

local julia_tests = Globals.julia_tests
local julia_test_setups = Globals.julia_test_setups
local julia_test_errors = Globals.julia_test_errors
local julia_test_envs = Globals.julia_test_envs
local julia_test_index = Globals.julia_test_index

local Logging = require "logging"
local log = Logging.log
Logging.logging = false

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

---Given the description of the test, convert it to the neotest Position type
---comment
---@return neotest.Position
local function position(id, type, name, path, range)
    return { id = id, type = type, name = name, path = path, range = range }
end

---Given the path to the file and a list of test items, construct a list of tests
---@param path string
---@param entries TestItemDetailLSP[]
---@return neotest.Position[]
local function position_from_entries(path, entries)
    local positions = {}
    for _, e in pairs(entries) do
        local id = e.id
        local type = 'test'
        local name = e.label
        local range = {
            e.range['start'].line,
            e.range['start'].character,
            e.range['end'].line,
            e.range['end'].character,
        }

        local node = position(id, type, name, path, range)
        vim.tbl_deep_extend("force", node, { test_data = e })
        table.insert(positions, node)
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
            -- This is assignment because we extract all of the tests in the call
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

JuliaAdapter.build_spec = function(args)
    local data = args.tree:data()
    local file_key = "file://" .. data.path
    local test_id = data.id
    local test_df = vim.g.tests_jl[file_key][test_id]
    local test_env = julia_test_envs[file_key]

    local uuid = jllib.start_test_item(test_df, test_env)

    return {
        command = {
            "/home/sam/work/neotest-julials/scripts/wait_exists.sh",
            "/tmp/samtest/" .. uuid
        }
    }
end

JuliaAdapter.results = function(spec, result, tree)
    local _path = spec.command[2]
    local _splits = Utils.split(_path, '/')
    local _uuid = _splits[#_splits]

    local test_result = julia_test_index[_uuid]
    local test_success = test_result[1]
    if test_success then
        test_success = "passed"
    else
        test_success = "failed"
    end

    local f = io.open(_path, "w+")
    if f then
        f:write(test_result[2])
        f:close()
    end

    local neotest_id = tree:data().id

    return {
        [neotest_id] = {
            status = test_success,
            output = _path
        }
    }
end

local default_options = {
    activate = true,
    environment = "@test_item_controller",
    logging = false,
    num_threads = 1,
    julia_env = {},
    max_process_count = 1,
    juliatic_cmd = { "julia", "/home/sam/work/TestItemControllers.jl/runner.jl" }
}

JuliaAdapter.setup = function(_opts)
    local opts = vim.tbl_deep_extend('force', default_options, _opts)
    if opts.activate then
        vim.lsp.handlers['julia/publishTests'] = jllib.handle_julia_tests

        Globals.julia_environment = opts.environment
        Globals.num_threads = opts.num_threads
        Globals.julia_env = opts.julia_env
        Globals.max_process_count = opts.max_process_count
        Globals.juliatic_cmd = opts.juliatic_cmd
        Logging.logging = opts.logging

        log("Initialized with environment", Globals.julia_environment)
    end

    return true
end

return JuliaAdapter
