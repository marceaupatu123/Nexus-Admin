--[[
TheNexusAvenger

Base class for a command.
--]]

local NexusObject = require(script.Parent.Parent:WaitForChild("NexusInstance"):WaitForChild("NexusObject"))

local BaseCommand = NexusObject:Extend()
BaseCommand:SetClassName("BaseCommand")
BaseCommand.Workspace = game:GetService("Workspace")
BaseCommand.Lighting = game:GetService("Lighting")
BaseCommand.Players = game:GetService("Players")
BaseCommand.StarterGui = game:GetService("StarterGui")
BaseCommand.Teams = game:GetService("Teams")
BaseCommand.InsertService = game:GetService("InsertService")
BaseCommand.LogService = game:GetService("LogService")
BaseCommand.MarketplaceService = game:GetService("MarketplaceService")
BaseCommand.PhysicsService = game:GetService("PhysicsService")
BaseCommand.RunService = game:GetService("RunService")
BaseCommand.TeleportService = game:GetService("TeleportService")
BaseCommand.UserInputService = game:GetService("UserInputService")
BaseCommand.TweenService = game:GetService("TweenService")



--[[
Creates a base command
--]]
function BaseCommand:__new(Keyword,Category,Description)
    self:InitializeSuper()
    
    --Initialize the commadn data.
    if _G.GetNexusAdminServerAPI then
        self.API = _G.GetNexusAdminServerAPI()
    elseif _G.GetNexusAdminClientAPI then
        self.API = _G.GetNexusAdminClientAPI()
    end
    self.Prefix = ((self.API or {}).Configuration or {}).CommandPrefix
    self.Keyword = Keyword
    self.Category = Category
    self.Description = Description
    if self.API then
        if Keyword and Category then
            if type(Keyword) == "table" then
                self.AdminLevel = self.API.Configuration:GetCommandAdminLevel(Category,Keyword[1])
            else
                self.AdminLevel = self.API.Configuration:GetCommandAdminLevel(Category,Keyword)
            end
        end
    end
    self.Arguments = {}
end

--[[
Returns if a command is from a context.
--]]
function BaseCommand:ExecutedFromContext(Context)
    local Data = self.CurrentContext:GetData()
    return Data and type(Data) == "table" and Data.ExecuteContext == Context
end

--[[
Returns if a command was executed from the chat.
--]]
function BaseCommand:ExecutedFromChat()
    return self:ExecutedFromContext("Chat")
end

--[[
Returns if a command was executed from the gui console.
The GUI console was cancelled. This should never be true.
--]]
function BaseCommand:ExecutedFromGuiConsole()
    return self:ExecutedFromContext("NexusAdminConsole")
end

--[[
Returns if a command was executed from a keybind.
--]]
function BaseCommand:ExecutedFromKeybind()
    return self:ExecutedFromContext("Keybind")
end

--[[
Sends a response back to the executor.
--]]
function BaseCommand:SendResponse(Message,Color)
    if self:ExecutedFromChat() or self:ExecutedFromGuiConsole() or self:ExecutedFromKeybind() then
        if self.CurrentContext.Executor then
            if _G.GetNexusAdminServerAPI then
                self.API.Messages:DisplayHint(self.CurrentContext.Executor,Message)
            else
                self.API.Messages:DisplayHint(Message)
            end
        end
    else
        self.CurrentContext:Reply(Message,Color)
    end
end

--[[
Sends a message back to the executor.
--]]
function BaseCommand:SendMessage(Message)
    self:SendResponse(Message,Color3.new(1,1,1))
end

--[[
Sends an error back to the executor.
--]]
function BaseCommand:SendError(Message)
    self:SendResponse(Message,Color3.new(1,0,0))
end

--[[
Runs the command.
--]]
function BaseCommand:Run(CommandContext)
    self.CurrentContext = CommandContext
end

--[[
Returns the remaining string after a specified
amount of "sections".
--]]
function BaseCommand:GetRemainingString(CommandString,Sections)
    --Remove parts of the string until the sections are passed.
    local InitialSpacesCleared = false
    local InQuotes = false
    local Escaping = false
    local InWhitespace = false
    while CommandString ~= "" and Sections > 0 do
        local Character = string.sub(CommandString,1,1)
        CommandString = string.sub(CommandString,2)

        --Update the state based on the character.
        if InitialSpacesCleared or Character ~= " " then
            InitialSpacesCleared = true
            if Escaping then
                Escaping = false
            else
                if Character == "\\" then
                    Escaping = true
                    InWhitespace = false
                elseif Character == "\"" then
                    InQuotes = not InQuotes
                    InWhitespace = false
                elseif Character == " " then
                    if not InWhitespace and not InQuotes then
                        InWhitespace = true
                        Sections = Sections - 1
                    end
                else
                    InWhitespace = false
                end
            end
        end
    end

    --Remove the spaces in the front.
    while string.sub(CommandString,1,1) == " " do
        CommandString = string.sub(CommandString,2)
    end

    --Return the remaining string.
    return CommandString
end

--[[
Moves a player to a given CFrame.
Includes unsitting the player to prevent
teleporting seats.
--]]
function BaseCommand:TeleportPlayer(Player,TargetCFrame)
    if Player.Character then
        local HumanoidRootPart = Player.Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
        if HumanoidRootPart and Humanoid then
            if Humanoid.SeatPart then
                --Unsit the player if the player is sitting and wait for the player to leave the seat before teleporting.
                Humanoid.Sit = false
                delay(0,function()
                    while Humanoid.SeatPart do wait() end
                    Humanoid.Sit = true
                    HumanoidRootPart.CFrame = TargetCFrame
                end)
            else
                --Teleport the player.
                HumanoidRootPart.CFrame = TargetCFrame
            end
        end
    end
end

--[[
Flattens the class to a table.
--]]
function BaseCommand:Flatten()
    return {
        --Cmdr data.
        Name = self.Name,
        Aliases = self.Aliases,
        Group = self.Group,
        Args = self.Args,
        AutoExec = self.AutoExec,

        --Nexus Admin data.
        Prefix = self.Prefix,
        Keyword = self.Keyword,
        Category = self.Category,
        Description = self.Description,
        AdminLevel = self.AdminLevel,
        Arguments = self.Arguments,
        Run = function(_,...)
            return self:Run(...)
        end,
    }
end



return BaseCommand