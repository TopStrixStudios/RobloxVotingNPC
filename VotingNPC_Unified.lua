-- FINAL UNIFIED VOTING NPC SCRIPT
-- Place this script INSIDE your NPC model (not in ServerScriptService)
-- DELETE ALL OTHER versions of VotingNPC scripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local VOTE_COOLDOWN = 10  -- 10 seconds between vote changes

print("Unified VotingNPC script starting...")

-- Ensure this script is in the NPC model
local npc = script.Parent
if not npc:IsA("Model") then
    error("VotingNPC script must be placed inside an NPC model!")
    return
end

-- Basic storage setup
if not ServerStorage:FindFirstChild("VotedPlayers") then
    local votedPlayersFolder = Instance.new("Folder")
    votedPlayersFolder.Name = "VotedPlayers"
    votedPlayersFolder.Parent = ServerStorage
end

if not ServerStorage:FindFirstChild("VotesFor") then
    local votesFor = Instance.new("IntValue")
    votesFor.Name = "VotesFor"
    votesFor.Value = 0
    votesFor.Parent = ServerStorage
end

if not ServerStorage:FindFirstChild("VotesAgainst") then
    local votesAgainst = Instance.new("IntValue")
    votesAgainst.Name = "VotesAgainst"
    votesAgainst.Value = 0
    votesAgainst.Parent = ServerStorage
end

-- Set up RemoteEvents
local remoteEventNames = {"OpenVoteMenu", "SubmitVote", "VoteCooldown"}
local NPCRemotes

if not ReplicatedStorage:FindFirstChild("NPCRemotes") then
    -- Create the folder
    NPCRemotes = Instance.new("Folder")
    NPCRemotes.Name = "NPCRemotes"
    NPCRemotes.Parent = ReplicatedStorage
    
    -- Create all needed remote events
    for _, name in ipairs(remoteEventNames) do
        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = NPCRemotes
    end
    
    print("Created RemoteEvents folder with all events")
else
    NPCRemotes = ReplicatedStorage.NPCRemotes
    
    -- Ensure all events exist
    for _, name in ipairs(remoteEventNames) do
        if not NPCRemotes:FindFirstChild(name) then
            local event = Instance.new("RemoteEvent")
            event.Name = name
            event.Parent = NPCRemotes
            print("Created missing RemoteEvent: " .. name)
        end
    end
end

-- Remove all existing BillboardGuis from the workspace
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") and obj.Name == "VoteDisplay" then
        obj:Destroy()
    end
end

-- Find NPC's primary part
local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("Part")
if not primaryPart then
    error("NPC has no valid parts for display!")
    return
end

-- Remove any ClickDetectors
for _, part in pairs(npc:GetDescendants()) do
    if part:IsA("BasePart") then
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("ClickDetector") then
                child:Destroy()
            end
        end
    end
end

-- Create the vote display
local function createVoteDisplay()
    -- Remove any existing displays
    for _, child in pairs(primaryPart:GetChildren()) do
        if child:IsA("BillboardGui") and child.Name == "VoteDisplay" then
            child:Destroy()
        end
    end
    
    -- Create a new display
    local voteDisplay = Instance.new("BillboardGui")
    voteDisplay.Name = "VoteDisplay"
    voteDisplay.Size = UDim2.new(0, 200, 0, 100)
    voteDisplay.StudsOffset = Vector3.new(0, 3, 0)
    voteDisplay.AlwaysOnTop = true
    voteDisplay.MaxDistance = 7
    voteDisplay.Parent = primaryPart
    
    local votesText = Instance.new("TextLabel")
    votesText.Name = "VotesText"
    votesText.Size = UDim2.new(1, 0, 1, 0)
    votesText.BackgroundTransparency = 1
    votesText.TextColor3 = Color3.fromRGB(255, 255, 255)
    votesText.TextStrokeTransparency = 0
    votesText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    votesText.Font = Enum.Font.GothamBold
    votesText.TextSize = 20
    votesText.Parent = voteDisplay
    
    return voteDisplay
end

-- Update only the text
local function updateDisplayText()
    local display = primaryPart:FindFirstChild("VoteDisplay")
    if not display then
        display = createVoteDisplay()
    end
    
    local textLabel = display:FindFirstChild("VotesText")
    if textLabel then
        textLabel.Text = "בעד הרעיון: " .. ServerStorage.VotesFor.Value .. 
                        "\nלא בעד הרעיון: " .. ServerStorage.VotesAgainst.Value
    end
end

-- Create display
local voteDisplay = createVoteDisplay()
updateDisplayText()

-- Add ProximityPrompt
local existingPrompt = primaryPart:FindFirstChild("ProximityPrompt")
if existingPrompt then
    existingPrompt:Destroy()
end

local prompt = Instance.new("ProximityPrompt")
prompt.ObjectText = "NPC"
prompt.ActionText = "דבר עם ה־NPC"
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = false
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.Parent = primaryPart

-- Tracking variables
local lastInteraction = {}  -- For general interactions
local lastVoteTime = {}     -- For vote change cooldown

-- Handle prompt trigger
prompt.Triggered:Connect(function(player)
    -- Basic cooldown check
    local currentTime = tick()
    if lastInteraction[player.UserId] and currentTime - lastInteraction[player.UserId] < 1 then
        return
    end
    lastInteraction[player.UserId] = currentTime
    
    -- Get current vote status
    local voteKey = "Vote_" .. player.UserId
    local voteRecord = ServerStorage.VotedPlayers:FindFirstChild(voteKey)
    local currentVote = nil
    
    if voteRecord and voteRecord:IsA("BoolValue") then
        currentVote = voteRecord.Value
    end
    
    -- Open menu
    NPCRemotes.OpenVoteMenu:FireClient(player, currentVote)
end)

-- Handle vote submission
NPCRemotes.SubmitVote.OnServerEvent:Connect(function(player, liked)
    if not player or not player:IsA("Player") then return end
    
    -- Basic rate limiting
    local currentTime = tick()
    if lastInteraction[player.UserId] and currentTime - lastInteraction[player.UserId] < 0.5 then
        return
    end
    lastInteraction[player.UserId] = currentTime
    
    -- Get vote record
    local voteKey = "Vote_" .. player.UserId
    local voteRecord = ServerStorage.VotedPlayers:FindFirstChild(voteKey)
    
    if voteRecord and voteRecord:IsA("BoolValue") then
        -- Player has voted before - check for vote changing
        if voteRecord.Value ~= liked then
            -- Check cooldown for changing votes
            if lastVoteTime[player.UserId] and currentTime - lastVoteTime[player.UserId] < VOTE_COOLDOWN then
                -- Still in cooldown
                local remainingTime = math.ceil(VOTE_COOLDOWN - (currentTime - lastVoteTime[player.UserId]))
                NPCRemotes.VoteCooldown:FireClient(player, remainingTime)
                return
            end
            
            -- Passed cooldown, allow vote change
            if voteRecord.Value == true then
                -- Was "for", now "against"
                ServerStorage.VotesFor.Value = math.max(0, ServerStorage.VotesFor.Value - 1)
                ServerStorage.VotesAgainst.Value = ServerStorage.VotesAgainst.Value + 1
            else
                -- Was "against", now "for"
                ServerStorage.VotesAgainst.Value = math.max(0, ServerStorage.VotesAgainst.Value - 1)
                ServerStorage.VotesFor.Value = ServerStorage.VotesFor.Value + 1
            end
            
            -- Update record and timestamp
            voteRecord.Value = liked
            lastVoteTime[player.UserId] = currentTime
            print(player.Name .. " changed vote")
        else
            -- Same vote as before
            print(player.Name .. " voted the same as before")
        end
    else
        -- First time voting
        if voteRecord then voteRecord:Destroy() end
        
        voteRecord = Instance.new("BoolValue")
        voteRecord.Name = voteKey
        voteRecord.Value = liked
        voteRecord.Parent = ServerStorage.VotedPlayers
        
        -- Record timestamp
        lastVoteTime[player.UserId] = currentTime
        
        -- Update counts
        if liked then
            ServerStorage.VotesFor.Value = ServerStorage.VotesFor.Value + 1
        else
            ServerStorage.VotesAgainst.Value = ServerStorage.VotesAgainst.Value + 1
        end
        
        print("New vote from " .. player.Name)
    end
    
    -- Update the display
    updateDisplayText()
end)

-- Self-repair system
spawn(function()
    while wait(5) do
        -- Check if display still exists
        if not primaryPart:FindFirstChild("VoteDisplay") then
            voteDisplay = createVoteDisplay()
            updateDisplayText()
        end
    end
end)

-- Cleanup on player removal
Players.PlayerRemoving:Connect(function(player)
    lastInteraction[player.UserId] = nil
    lastVoteTime[player.UserId] = nil
end)

print("Unified voting NPC system ready!")