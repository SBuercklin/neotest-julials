local M = {}

local Globals = require "globals"

local julia_test_setups = Globals.julia_test_setups
local julia_test_errors = Globals.julia_test_errors
local julia_test_envs = Globals.julia_test_envs

local julia_test_index = Globals.julia_test_index

local log = require("logging").log

local uuid = require("utilities").uuid

local signal_finished = function(id)
    local fpath = Globals.tmpdir .. id
    f = io.open(fpath, "w+")
    f:write(julia_test_index[id][2])
    f:close()
end

local notification_disp = function(method, params)
    if method == "testItemStarted" then
        local id = params.testRunId
        log("Test ID started", id)
        julia_test_index[id] = { false, "" }
    elseif method == "testItemPassed" then
        local id = params.testRunId
        log("Test ID passed", id)
        julia_test_index[id][1] = true
        signal_finished(id)
    elseif method == "testItemFailed" then
        local id = params.testRunId
        log("Test ID failed", id)
        julia_test_index[id][1] = false
        signal_finished(id)
    elseif method == "appendOutput" then
        local id = params.testRunId
        log("Appending Output", params.output, julia_test_index, julia_test_index[id])
        if julia_test_index[id] ~= nil then
            julia_test_index[id][2] = julia_test_index[id][2] .. params.output
        end
    else
        log("Notification", method, params)
    end
end

local server_req_disp = function(method, params)
    log("Request", method, params)
end
local on_exit_disp = function(code, signal) end
local on_error_disp = function(code, err) end

local dispatchers = {
    notification = notification_disp,
    server_request = server_req_disp,
    on_exit = on_exit_disp,
    on_error = on_error_disp
}

---@param bufnr integer?
---@return vim.lsp.Client?
M.get_julials_client = function(bufnr)
    local filter = { name = "julials" }
    if bufnr then
        filter.bufnr = bufnr
    end

    local clients = vim.lsp.get_clients(filter)
    if #clients > 0 then
        -- We assume there's only one julials attached
        return clients[1]
    end
end

M.get_juliatic_client = function()
    local s = Globals.juliatic_server
    if s == nil or s.is_closing() then
        log("No valid JuliaTestItemController.jl instance")
        s = vim.lsp.rpc.start(Globals.juliatic_cmd, dispatchers)
        Globals.juliatic_server = s
        if s == nil then
            log("Failed to start a new JuliaTestItemController.jl instance")
            return nil
        end
        log("Started a JuliaTestItemController.jl instance")
    else
        log("Found an existing JuliaTestItemController.jl instance")
    end

    return s
end

local test_env_handler_factory = function(uri, tbl)
    return function(err, result, ctx, cfg)
        log("URI, Test Environment", uri, result)
        tbl[uri] = result
    end
end

---@param uri string
---@param test_envs table
M.get_test_env = function(uri, test_envs)
    ---@type GetTestEnvRequestParamsReturnLSP
    local params = { uri = uri }
    local client = M.get_julials_client()
    if client == nil then
        return nil
    end

    local handler = test_env_handler_factory(uri, test_envs)

    client.request("julia/getTestEnv", params, handler)
end

---Handles the julia test results from julia/publishTests, populating the vim.g.tests_jl
---global variable with information about the tests
---@param err any
---@param result PublishTestsParams
---@param ctx any
---@param config any
---@return boolean
M.handle_julia_tests = function(err, result, ctx, config)
    local uri = result.uri
    local new_test_table = {}
    local new_setup_table = {}
    local new_error_table = {}

    log("Handling tests")
    log(result)
    if result.testItemDetails ~= nil then
        for _, test in pairs(result.testItemDetails) do
            new_test_table[test.id] = test
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

    local updated_test_table = Globals.julia_tests
    updated_test_table[uri] = new_test_table
    Globals.julia_tests = updated_test_table
    vim.g.tests_jl = Globals.julia_tests

    local updated_setup_table = Globals.julia_test_setups
    updated_setup_table[uri] = new_setup_table
    Globals.julia_test_setups = updated_setup_table
    vim.g.setups_jl = Globals.julia_test_setups

    local updated_error_table = Globals.julia_test_errors
    updated_error_table[uri] = new_error_table
    Globals.julia_test_errors = updated_error_table
    vim.g.errors_jl = Globals.julia_test_errors

    log("Tests", Globals.julia_tests)
    log("Setups", Globals.julia_test_setups)
    log("Errors", Globals.julia_test_errors)

    M.get_test_env(uri, Globals.julia_test_envs)

    return true
end

---@param ti TestItemDetailLSP
---@param test_env GetTestEnvRequestParamsReturnLSP
---@return TestItemTIC
local to_test_item_tic = function(ti, test_env)
    return {
        id               = ti.id,
        uri              = ti.id,
        label            = ti.label,
        packageName      = test_env.packageName,
        packageUri       = test_env.packageUri,
        envContentHash   = test_env.envContentHash,
        useDefaultUsings = true,
        testSetups       = {}, -- TODO: This should be supported in general
        line             = ti.range.start.line,
        column           = ti.range.start.character,
        code             = ti.code,
        codeLine         = ti.codeRange.start.line,
        codeColumn       = ti.codeRange.start.character,
    }
end

---@param _uuid string
---@return fun(err: lsp.ResponseError?, result: CreateTestRunResponse)
local test_response_factory = function(_uuid)
    return function(err, result, context, config)
        if result.status ~= "success" then
            log("Test starting was not successful for " .. _uuid)
            local f = io.open("/tmp/samtest/" .. _uuid, "w")
            if f then
                f:write("asdf")
                f:close()
            end
        else
            log("Test starting was successful for " .. _uuid)
        end
    end
end

---Starts a test item with the active JuliaLS client, creates the testfile, and returns the
---UUID of the test we start
---@param test_item TestItemDetailLSP
---@param test_env GetTestEnvRequestParamsReturnLSP
---@return string?
M.start_test_item = function(test_item, test_env)
    local test_run_id = uuid()
    log("Test run ID", test_run_id)

    local test_item_tic = to_test_item_tic(test_item, test_env)

    ---@type TestProfileTIC
    local profile = {
        id = "JuliaTestProfile",
        label = "JuliaTestLabel",
        juliaCmd = "julia",
        juliaArgs = {},
        juliaNumThreads = tostring(Globals.num_threads),
        juliaEnv = Globals.julia_env,
        maxProcessCount = Globals.max_process_count,
        mode = "auto" -- TODO: this is technically an enum with other options
    }

    ---@type CreateTestRunRequestParams
    local request = {
        testRunId = test_run_id,
        testProfiles = { profile },
        testItems = { test_item_tic },
        testSetups = {} -- TODO: Test Setups not supported right now
    }

    ---@type vim.lsp.rpc.PublicClient?
    local client = M.get_juliatic_client()

    if client == nil then
        return nil
    end
    client.request("createTestRun", request, test_response_factory(test_run_id), function(_) end)

    return test_run_id
end

return M
