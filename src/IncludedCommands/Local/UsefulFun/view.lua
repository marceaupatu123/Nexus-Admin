--[[
TheNexusAvenger

Implementation of a command.
--]]

local BaseCommand = require(script.Parent.Parent:WaitForChild("BaseCommand"))
local Command = BaseCommand:Extend()



--[[
Creates the command.
--]]
function Command:__new()
    self:InitializeSuper("view","UsefulFunCommands","Views a given player.")

    self.Arguments = {
        {
            Type = "nexusAdminPlayers",
            Name = "Player",
            Description = "Player to view.",
        },
    }
end

--[[
Runs the command.
--]]
function Command:Run(CommandContext,Players)
    self.super:Run(CommandContext)

    --Change the view.
    local Player = Players[1]
    if Player then
        if Player.Character then
            local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
            local Camera = self.Workspace.CurrentCamera
            if Humanoid then
                Camera.CameraSubject = Humanoid
                if Player == CommandContext.Executor then
                    Camera.CameraType = "Custom"
                else
                    Camera.CameraType = "Track"
                end
            end
        end
    end
end



return Command