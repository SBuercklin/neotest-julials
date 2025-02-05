---@meta

-- Types below are according to LanguageServer.jl, not TestItemController.jl

---@class PositionLSP
---@field line integer
---@field character integer
Position = {}

---@class RangeLSP
---@field start PositionLSP
---@field stop PositionLSP
Range = {}

---@class TestItemDetailLSP
---@field id string
---@field label string
---@field range RangeLSP
---@field code string
---@field codeRange RangeLSP
---@field optionDefaultImports boolean
---@field optionTags string[]
---@field optionSetup string[]
TestItemDetailLSP = {}

---@class TestSetupDetailLSP
---@field name string
---@field kind string
---@field range RangeLSP
---@field code string
---@field codeRange RangeLSP
TestSetupDetailLSP = {}

---@class TestErrorDetailLSP
---@field id string
---@field label string
---@field range RangeLSP
---@field error string
TestErrorDetailLSP = {}

---@class PublishTestsParams
---@field uri string
---@field version integer?
---@field testItemDetails TestItemDetailLSP[]
---@field testSetupDetails TestSetupDetailLSP[]
---@field testErrorDetails TestErrorDetailLSP[]
PublishTestsParams = {}


---@class GetTestEnvRequestParamsLSP
---@field uri string
GetTestEnvRequestParamsLSP = {}

---@class GetTestEnvRequestParamsReturnLSP
---@field packageName string?
---@field packageUri string?
---@field projectUri string?
---@field envContentHash integer?
GetTestEnvRequestParamsReturnLSP = {}





--[[
        Types below are according to TestItemController.jl
]]


--[[
        CreateTestRunRequest types for createTestRun request
]]

---@class CreateTestRunRequestParams
---@field testRunId string
---@field testProfiles TestProfileTIC[]
---@field testItems TestItemTIC[]
---@field testSetups TestSetupTIC[]
CreateTestRunRequestParams = {}

---@class TestProfileTIC
---@field id string
---@field label string
---@field juliaCmd string
---@field juliaArgs string[]
---@field juliaNumThreads string
---@field juliaEnv any
---@field maxProcessCount number
---@field mode string
---@field coverageRootUris string[]?
TestProfileTIC = {}

---@class TestItemTIC
---@field id string
---@field uri string
---@field label string
---@field packageName string?
---@field packageUri string?
---@field projectUri string?
---@field envContentHash number?
---@field useDefaultUsings boolean
---@field testSetups string[]
---@field line number
---@field column number
---@field code string
---@field codeLine number
---@field codeColumn number
TestItemTIC = {}

---@class TestSetupTIC
---@field packageUri string?
---@field name string
---@field kind string
---@field uri string
---@field line number
---@field column number
---@field code string
TestSetupTIC = {}





--[[
        CreateTestRunRequest response
]]

---@class FileCoverage
---@field uri string
---@field coverage number?[]
FileCoverage = {}

---@class CoverageResult
---@field status string
---@field coverage FileCoverage[]?
CoverageResult = {}


---@class CreateTestRunResponse
---@field status string
---@field coverage FileCoverage[]?
CreateTestRunResponse = {}


--[[
        TerminateTestProcess params
]]

---@class TerminateTestProcessParams
---@field processId string





--[[
    Notifications from the server
]]


--[[
    testItemStarted notification
]]

---@class TestItemStarted
---@field testRunId string
---@field testItemId string
TestItemStarted = {}
