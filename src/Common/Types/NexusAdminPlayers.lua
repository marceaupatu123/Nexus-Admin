--[[
TheNexusAvenger

Custom players type closer to the old
format. Also adds keywords like admins and nonadmins.
--]]

--[[
Registers the types.
--]]
return function(API,TestPlayersService,TestTeamsService)
    local PlayersService = TestPlayersService or game:GetService("Players")
    local Teams = TestTeamsService or game:GetService("Teams")
    local ExactShorthands = {}
    local PatternShorthands = {}
    local NexusAdminPlayersType = nil

    --[[
    Returns the players to operate on.
    --]]
    local function GetFilteredPlayers(Text, Executor)
        local FilterText = string.match(Text, "%[(.+)%]$")
        if FilterText then
            local Players = {}
            local PlayersMap = {}
            for _, TextEntry in pairs(string.split(FilterText, ",")) do
                for _, Player in pairs(NexusAdminPlayersType.Parse(NexusAdminPlayersType.Transform(TextEntry, Executor))) do
                    if not PlayersMap[Player] then
                        PlayersMap[Player] = true
                        table.insert(Players, Player)
                    end
                end
            end 
            return Players
        end
        return PlayersService:GetPlayers()
    end

    --[[
    Returns the teams for a given string. Returns nil if
    the string is not valid for teams.
    --]]
    local function GetTeams(Text)
        --Return if the message doesn't start with %.
        if string.sub(Text,1,1) ~= "%" then
            return
        end

        --Return the teams.
        local PreFilterText = string.match(Text, "([^%[]+)%[.+%]$") or Text
        return API.Cmdr.Util.MakeFuzzyFinder(Teams:GetTeams())(string.sub(PreFilterText,2))
    end

    --[[
    Returns the players for the given string.
    --]]
    local function GetPlayers(Text,Executor)
        --Return if a shorthand exists.
        local PreFilterText = string.match(Text, "([^%[]+)%[.+%]$") or Text
        local LowerText = string.lower(PreFilterText)
        local Players = GetFilteredPlayers(Text, Executor)
        for Shorthand,Callback in pairs(ExactShorthands) do
            if LowerText == Shorthand then
                return Callback(Text, Executor, Players)
            end
        end
        for Shorthand,Callback in pairs(PatternShorthands) do
            if string.find(LowerText,Shorthand) then
                return Callback(Text, Executor, Players)
            end
        end

        --Get the results from searching.
        return API.Cmdr.Util.MakeFuzzyFinder(Players)(Text)
    end

    --Create the players type.
    NexusAdminPlayersType = {
        Listable = true,

        --[[
        Transforms the string to a list of fast flags.
        --]]
        Transform = function(Text,Executor)
            return {Text=Text,Executor=Executor}
        end,

        --[[
        Returns if the input is valid and an error message
        for when it is invalid.
        --]]
        Validate = function(ArgumentData)
            --Return the results for teams.
            local Teams = GetTeams(ArgumentData.Text)
            if Teams then
                return #Teams > 0,"No teams were found matching that query."
            end

            --Return the results for players.
            local FoundPlayers = GetPlayers(ArgumentData.Text,ArgumentData.Executor)
            return #FoundPlayers > 0,"No players were found matching that query."
        end,
    
        --[[
        Returns the results for auto completing.
        --]]
        Autocomplete = function(ArgumentData)
            --Return the teams.
            local Teams = GetTeams(ArgumentData.Text)
            if Teams then
                local TeamStrings = {}
                for _,Team in pairs(GetTeams(ArgumentData.Text)) do
                    table.insert(TeamStrings,"%"..Team.Name)
                end
                return TeamStrings
            end

            --Return the players.
            local FoundPlayers = GetPlayers(ArgumentData.Text,ArgumentData.Executor)
            return API.Cmdr.Util.GetNames(FoundPlayers)
        end,

        --[[
        Returns the value to use.
        --]]
        Parse = function(ArgumentData)
            --Get the players.
            local Teams = GetTeams(ArgumentData.Text)
            local SelectedPlayers = {}
            if Teams then
                --Get the filter players.
                local AllowedPlayers = {}
                for _, Player in pairs(GetFilteredPlayers(ArgumentData.Text, ArgumentData.Executor)) do
                    AllowedPlayers[Player] = true
                end

                --Add the team players.
                for _,Team in pairs(Teams) do
                    for _,Player in pairs(Team:GetPlayers()) do
                        if AllowedPlayers[Player] then
                            table.insert(SelectedPlayers,Player)
                        end
                    end
                end
            else
                SelectedPlayers = GetPlayers(ArgumentData.Text,ArgumentData.Executor)
            end

            --Return the players.
            return SelectedPlayers
        end,
    }

    --Register the types.
    API.Cmdr.Registry:RegisterType("nexusAdminPlayers",NexusAdminPlayersType)
    API.Types.NexusAdminPlayers = {
        RegisterShortHand = function(_,Name,Callback)
            if typeof(Name) == "table" then
                for _, SubName in pairs(Name) do
                    API.Types.NexusAdminPlayers:RegisterShortHand(SubName, Callback)
                end
                return
            end
            ExactShorthands[string.lower(Name)] = Callback
        end,
        RegisterPatternShortHand = function(_,Name,Callback)
            if typeof(Name) == "table" then
                for _, SubName in pairs(Name) do
                    API.Types.NexusAdminPlayers:RegisterPatternShortHand(SubName, Callback)
                end
                return
            end
            PatternShorthands[Name] = Callback
        end,
    }

    --Register the shorthands.
    API.Types.NexusAdminPlayers:RegisterShortHand({"me", "."}, function(Text, Executor, Players)
        --Return the executing player if it is contained in the list of players.
        for _, Player in pairs(Players) do
            if Player == Executor then
                return {Executor}
            end
        end
        return {}
    end)
    API.Types.NexusAdminPlayers:RegisterShortHand({"random", "?"}, function(Text, Executor, Players)
        --Return a random player.
        if #Players == 0 then
            return {}
        end
        return {Players[math.random(1, #Players)]}
    end)
    API.Types.NexusAdminPlayers:RegisterShortHand({"all", "*"}, function(Text, Executor, Players)
        --Return all of the players.
        return Players
    end)
    API.Types.NexusAdminPlayers:RegisterShortHand("others", function(Text, Executor, Players)
        --Return all of the players except for the executor.
        local Others = {}
        for _, Player in pairs(Players) do
            if Player ~= Executor then
                table.insert(Others, Player)
            end
        end
        return Others
    end)
    API.Types.NexusAdminPlayers:RegisterShortHand("admins", function(Text, Executor, Players)
        --Return the admins (Nexus Admin only).
        local Admins = {}
        for _,Player in pairs(Players) do
            if API.Authorization:IsPlayerAuthorized(Player,0) then
                table.insert(Admins,Player)
            end
        end
        return Admins
    end)
    API.Types.NexusAdminPlayers:RegisterShortHand("nonadmins", function(Text, Executor, Players)
        --Return the non-admins (Nexus Admin only).
        local NonAdmins = {}
        for _,Player in pairs(Players) do
            if not API.Authorization:IsPlayerAuthorized(Player,0) then
                table.insert(NonAdmins,Player)
            end
        end
        return NonAdmins
    end)
    API.Types.NexusAdminPlayers:RegisterPatternShortHand("%?%d+",function(Text, Executor, Players)
        --Return a random set of players. Use of "random" is not supported for this.
        local RandomMatch = Text:match("%?(%d+)")
        if RandomMatch then
            local MaxSize = tonumber(RandomMatch)
            if MaxSize and MaxSize > 0 then
                local RandomPlayers = {}
                local RemainingPlayers = {}
                for _, Player in pairs(Players) do
                    table.insert(RemainingPlayers, Player)
                end
                for i = 1,math.min(MaxSize, #RemainingPlayers) do
                    table.insert(RandomPlayers, table.remove(RemainingPlayers, math.random(1,#RemainingPlayers)))
                end

                return RandomPlayers
            end
        end
    end)
    API.Types.NexusAdminPlayers:RegisterShortHand("not", function(Text, Executor, Players)
        --Return all of players not in the given list of players.
        local NegatedPlayers = {}
        local PlayersMap = {}
        for _, Player in pairs(Players) do
            PlayersMap[Player] = true
        end
        for _, Player in pairs(PlayersService:GetPlayers()) do
            if not PlayersMap[Player] then
                table.insert(NegatedPlayers, Player)
            end
        end
        return NegatedPlayers
    end)
end