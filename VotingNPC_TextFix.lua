-- VotingNPC Final Fix - Text Display Focus
-- Place this script inside your NPC model and name it "VotingNPC"
-- DELETE ANY OTHER VotingNPC SCRIPTS FROM ServerScriptService!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

print("VotingNPC Text Fix script starting...")

local npc = script.Parent

-- Make sure we have storage for votes
if not ServerStorage:FindFirstChild("VotedPlayers") then
    local votedPlayersFolder = Instance.new("Folder")
    votedPlayersFolder.Name = "VotedPlayers"
    votedPlayersFolder.Parent = ServerStorage
end

-- Setup vote counters
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

-- Setup RemoteEvents
if not ReplicatedStorage:FindFirstChild("NPCRemotes") then
    local remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "NPCRemotes"
    remotesFolder.Parent = ReplicatedStorage
    
    local openMenuEvent = Instance.new("RemoteEvent")
    openMenuEvent.Name = "OpenVoteMenu"
    openMenuEvent.Parent = remotesFolder
    
    local submitVoteEvent = Instance.new("RemoteEvent")
    submitVoteEvent.Name = "SubmitVote"
    submitVoteEvent.Parent = remotesFolder
end

-- AGGRESSIVE CLEANUP: Remove ALL existing displays from the game
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") and obj.Name == "VoteDisplay" then
        obj:Destroy()
    end
end

-- Clean up conflicts
for _, part in pairs(npc:GetDescendants()) do
    if part:IsA("BasePart") then
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("ClickDetector") then
                child:Destroy()
            end
        end
    end
end

-- Find primary part for display
local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("Part")
if not primaryPart then
    error("NPC has no valid parts for attaching display!")
    return
end

-- Create a SINGLE vote display
local function createVoteDisplay()
    -- Remove any existing displays first
    for _, child in pairs(primaryPart:GetChildren()) do
        if child:IsA("BillboardGui") then
            child:Destroy()
        end
    end
    
    -- Create fresh display
    local voteDisplay = Instance.new("BillboardGui")
    voteDisplay.Name = "VoteDisplay"
    voteDisplay.Size = UDim2.new(0, 200, 0, 100)
    voteDisplay.StudsOffset = Vector3.new(0, 3, 0)
    voteDisplay.AlwaysOnTop = true
    voteDisplay.MaxDistance = 7  -- Only visible within 7 studs
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

-- Update TEXT ONLY (no creation)
local function updateDisplayText()
    -- Find existing display
    local display = primaryPart:FindFirstChild("VoteDisplay")
    if not display then return end
    
    local textLabel = display:FindFirstChild("VotesText")
    if not textLabel then return end
    
    -- Update text with current vote counts
    textLabel.Text = "בעד הרעיון: " .. ServerStorage.VotesFor.Value .. 
                    "\nלא בעד הרעיון: " .. ServerStorage.VotesAgainst.Value
end

-- Create a fresh display
local voteDisplay = createVoteDisplay()
updateDisplayText()

-- Add ProximityPrompt for interaction
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

-- Anti-exploit tracking
local lastInteraction = {}

-- Connect the interaction
prompt.Triggered:Connect(function(player)
    -- Cooldown check
    local currentTime = tick()
    if lastInteraction[player.UserId] and currentTime - lastInteraction[player.UserId] < 1 then
        return
    end
    lastInteraction[player.UserId] = currentTime
    
    -- Get current vote
    local currentVote = nil
    local voteRecord = ServerStorage.VotedPlayers:FindFirstChild("Vote_" .. player.UserId)
    if voteRecord and voteRecord:IsA("BoolValue") then
        currentVote = voteRecord.Value
    end
    
    -- Open menu
    ReplicatedStorage.NPCRemotes.OpenVoteMenu:FireClient(player, currentVote)
end)

-- Handle vote submission
ReplicatedStorage.NPCRemotes.SubmitVote.OnServerEvent:Connect(function(player, liked)
    if not player or not player:IsA("Player") then return end
    
    -- Rate limiting
    local currentTime = tick()
    if lastInteraction[player.UserId] and currentTime - lastInteraction[player.UserId] < 0.5 then
        return
    end
    lastInteraction[player.UserId] = currentTime
    
    -- Track votes
    local voteKey = "Vote_" .. player.UserId
    local voteRecord = ServerStorage.VotedPlayers:FindFirstChild(voteKey)
    
    if voteRecord and voteRecord:IsA("BoolValue") then
        -- Changing vote
        if voteRecord.Value ~= liked then
            -- Remove old vote from count
            if voteRecord.Value == true then
                ServerStorage.VotesFor.Value = math.max(0, ServerStorage.VotesFor.Value - 1)
            else
                ServerStorage.VotesAgainst.Value = math.max(0, ServerStorage.VotesAgainst.Value - 1)
            end
            
            -- Add new vote to count
            if liked then
                ServerStorage.VotesFor.Value = ServerStorage.VotesFor.Value + 1
            else
                ServerStorage.VotesAgainst.Value = ServerStorage.VotesAgainst.Value + 1
            end
            
            -- Update record
            voteRecord.Value = liked
        end
    else
        -- New vote
        if voteRecord then voteRecord:Destroy() end
        
        voteRecord = Instance.new("BoolValue")
        voteRecord.Name = voteKey
        voteRecord.Value = liked
        voteRecord.Parent = ServerStorage.VotedPlayers
        
        -- Update count
        if liked then
            ServerStorage.VotesFor.Value = ServerStorage.VotesFor.Value + 1
        else
            ServerStorage.VotesAgainst.Value = ServerStorage.VotesAgainst.Value + 1
        end
    end
    
    -- Update display - THIS IS KEY
    updateDisplayText()
end)

-- Self-repair system
spawn(function()
    while wait(5) do
        local display = primaryPart:FindFirstChild("VoteDisplay")
        if not display then
            voteDisplay = createVoteDisplay()
            updateDisplayText()
        end
    end
end)

print("Vote display system ready!")