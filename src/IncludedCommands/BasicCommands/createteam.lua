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
    self:InitializeSuper({"createteam","addteam"},"BasicCommands","Creates teams of given colors and given name.")

    self.Arguments = {
        {
            Type = "brickColors",
            Name = "Colors",
            Description = "Colors to create.",
        },
        {
            Type = "string",
            Name = "Name",
            Optional = true,
            Description = "Name to use.",
        },
    }
end

--[[
Runs the command.
--]]
function Command:Run(CommandContext,Colors, Name)
    self.super:Run(CommandContext)
    
    --Create the teams.
    for _,Color in pairs(Colors) do
        --Get if the team exists.
        local ExistingTeam
        for _,Team in pairs(self.Teams:GetTeams()) do
            if Team.TeamColor == Color then
                ExistingTeam = Team
            end
        end

        --Create a team or display an error.
        if ExistingTeam then
            self:SendError("Team with color "..tostring(Color).." ("..ExistingTeam.Name..") already exists.")
        else
            local NewTeam = Instance.new("Team")
            NewTeam.TeamColor = Color
            NewTeam.AutoAssignable = false
            NewTeam.Name = (Name == nil and tostring(Color).." Team" or self.API.Filter:FilterString(Name, CommandContext.Executor))
            NewTeam.Parent = self.Teams
        end
    end
end



return Command
