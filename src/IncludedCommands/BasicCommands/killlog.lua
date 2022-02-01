--[[
TheNexusAvenger

Implementation of a command.
--]]

local BaseCommand = require(script.Parent.Parent:WaitForChild("BaseCommand"))
local Logs = require(script.Parent.Parent.Parent:WaitForChild("Common"):WaitForChild("Logs"))
local Command = BaseCommand:Extend()



--[[
Creates the command.
--]]
function Command:__new()
    self:InitializeSuper("killlogs", "BasicCommands", "Opens up a window containing the logs of kills.")
    self.KillLogs = Logs.new()

    --Create the remote function.
    local GetKillLogsRemoteFunction = Instance.new("RemoteFunction")
    GetKillLogsRemoteFunction.Name = "GetKillLogs"
    GetKillLogsRemoteFunction.Parent = self.API.EventContainer

    function GetKillLogsRemoteFunction.OnServerInvoke(Player)
        if self.API.Authorization:IsPlayerAuthorized(Player, self.AdminLevel) then
            return self.KillLogs:GetLogs()
        else
            return {}
        end
    end

    --[[
    Connects the a character dieing.
    --]]
    local function CharacterAdded(Player, Character)
        --Connect the humanoid death.
        local Humanoid = Character:WaitForChild("Humanoid")
        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        Humanoid.Died:Connect(function()
            --Store the log.
            local CreatorTag = Humanoid:FindFirstChild("creator")
            local KillingPlayer = CreatorTag and CreatorTag.Value
            local KillingCharacter = KillingPlayer and KillingPlayer.Character
            local KillingCharacterTool = KillingCharacter and KillingCharacter:FindFirstChildOfClass("Tool")
            local KillingCharacterHumanoidRootPart = KillingCharacter and KillingCharacter:FindFirstChild("HumanoidRootPart")
            self.KillLogs:Add({
                KilledPlayer = Player,
                KillingPlayer = KillingPlayer,
                KillingPlayerEquipedToolName = KillingCharacterTool and KillingCharacterTool.Name,
                Distance = KillingCharacterHumanoidRootPart and (KillingCharacterHumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude,
            })
        end)
    end

    --[[
    Connects the characters being added for a player.
    --]]
    local function PlayerAdded(Player)
        Player.CharacterAdded:Connect(function(Character)
            CharacterAdded(Player, Character)
        end)
        if Player.Character then
            CharacterAdded(Player, Player.Character)
        end
    end

    --Connect the players.
    self.Players.PlayerAdded:Connect(PlayerAdded)
    for _,Player in pairs(self.Players:GetPlayers()) do
        task.spawn(function()
            PlayerAdded(Player)
        end)
    end
end



return Command