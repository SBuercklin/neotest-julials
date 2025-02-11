local M = {}

---Maps file URIs to sets of TestItem IDs that map to TestItems
---@type { [string]: { [string] : TestItemDetailLSP } }
M.julia_tests = {}

---Maps a file URI to its corresponding test setups
---@type { [string]: TestSetupDetailLSP }
M.julia_test_setups = {}

---Maps a file URI to corresponding test errors
---@type { [string]: TestErrorDetailLSP }
M.julia_test_errors = {}

---Maps a URI to its test environment details
---@type { [string]: GetTestEnvRequestParamsReturnLSP }
M.julia_test_envs = {}

---Maps a test UUID to a status, output pair
---@type { [string]: [boolean, string ]}
M.julia_test_index = {}

---The number of threads to start the Julia test runners with
---@type integer
M.num_threads = 1

---Extra environment variables to set for the test environment
---@type { [string]: string }
M.julia_env = {}

---Maximum number of test processes to run in parallel
---@type number
M.max_process_count = 1

---@type string[]
M.juliatic_cmd = {}

---Persistent Julia TIC server
M.juliatic_server = nil

M.tmpdir = "/tmp/samtest/"

return M
