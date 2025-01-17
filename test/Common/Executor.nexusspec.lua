--[[
TheNexusAvenger

Tests the Executor class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local ExecutorUnitTest = NexusUnitTesting.UnitTest:Extend()

local Executor = require(game:GetService("ServerScriptService"):WaitForChild("MainModule"):WaitForChild("NexusAdmin"):WaitForChild("Common"):WaitForChild("Executor"))



--[[
Sets up the unit test.
--]]
function ExecutorUnitTest:Setup()
    --Create the mock Cmdr.
    self.MockCmdr = {
        Dispatcher = {
            EvaluateAndRun = function(self,Command)
                self.LastCommand = Command
                return "Mock success."
            end,
        }
    }

    --Create the mock registry.
    self.MockRegistry = {
        PrefixCommands = {
            [":m"] = "m",
            [":cmds"] = "cmds",
            ["!cmds"] = "cmds",
        }
    }

    --Create the component under testing.
    self.CuT = Executor.new(self.MockCmdr,self.MockRegistry)
end

--[[
Tests the Unescape method.
--]]
NexusUnitTesting:RegisterUnitTest(ExecutorUnitTest.new("Unescape"):SetRun(function(self)
    --Assert no escaping.
    self:AssertEquals(self.CuT:Unescape("test"),"test")

    --Assert escaping.
    self:AssertEquals(self.CuT:Unescape("test\\test"),"testtest")
    self:AssertEquals(self.CuT:Unescape("test\\\\test"),"test\\test")
    self:AssertEquals(self.CuT:Unescape("\"test\""),"test")
    self:AssertEquals(self.CuT:Unescape("\"test\"test\"test\""),"testtesttest")
    self:AssertEquals(self.CuT:Unescape("test\\\\\"test"),"test\\test")
    self:AssertEquals(self.CuT:Unescape("test\\\\\\\"test"),"test\\\"test")
end))

--[[
Tests the ExecuteCommandWithPrefix method.
--]]
NexusUnitTesting:RegisterUnitTest(ExecutorUnitTest.new("ExecuteCommandWithPrefix"):SetRun(function(self)
    --Assert running commands executes correctly.
    self:AssertEquals(self.CuT:ExecuteCommandWithPrefix(":m Test"),"Mock success.")
    self:AssertEquals(self.MockCmdr.Dispatcher.LastCommand,"m Test")
    self:AssertEquals(self.CuT:ExecuteCommandWithPrefix(":M Test"),"Mock success.")
    self:AssertEquals(self.MockCmdr.Dispatcher.LastCommand,"m Test")
    self:AssertEquals(self.CuT:ExecuteCommandWithPrefix(":cmds"),"Mock success.")
    self:AssertEquals(self.MockCmdr.Dispatcher.LastCommand,"cmds")
    self:AssertEquals(self.CuT:ExecuteCommandWithPrefix("!cmds"),"Mock success.")
    self:AssertEquals(self.MockCmdr.Dispatcher.LastCommand,"cmds")
    self:AssertEquals(self.CuT:ExecuteCommandWithPrefix(":CmdS"),"Mock success.")
    self:AssertEquals(self.MockCmdr.Dispatcher.LastCommand,"cmds")
    self:AssertEquals(self.CuT:ExecuteCommandWithPrefix("!CMDS"),"Mock success.")
    self:AssertEquals(self.MockCmdr.Dispatcher.LastCommand,"cmds")
    self:AssertEquals(self.CuT:ExecuteCommandWithPrefix(";cmds"),"Unknown command.")
    self:AssertEquals(self.CuT:ExecuteCommandWithPrefix(":test"),"Unknown command.")
end))

--[[
Tests the SplitCommands method.
--]]
NexusUnitTesting:RegisterUnitTest(ExecutorUnitTest.new("SplitCommands"):SetRun(function(self)
    --Assert no splitting.
    self:AssertEquals(self.CuT:SplitCommands("","/"),{""})
    self:AssertEquals(self.CuT:SplitCommands("test","/"),{"test"})
    self:AssertEquals(self.CuT:SplitCommands("test\\test","/"),{"testtest"})

    --Assert basic splitting.
    self:AssertEquals(self.CuT:SplitCommands("//","/"),{"","",""})
    self:AssertEquals(self.CuT:SplitCommands("test/test/test","/"),{"test","test","test"})

    --Assert whitespace trimming.
    self:AssertEquals(self.CuT:SplitCommands("  test  /  test/  test  ","/"),{"test","test","test"})

    --Assert quotes with splitting.
    self:AssertEquals(self.CuT:SplitCommands("test\"/\"test","/"),{"test/test"})
    self:AssertEquals(self.CuT:SplitCommands("test\"/test\"","/"),{"test/test"})
    self:AssertEquals(self.CuT:SplitCommands("\"test/\"test","/"),{"test/test"})
    self:AssertEquals(self.CuT:SplitCommands("\"test/test\"","/"),{"test/test"})
    self:AssertEquals(self.CuT:SplitCommands("\"","/"),{""})
end))



return true