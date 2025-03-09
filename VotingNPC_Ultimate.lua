-- VotingNPC Ultimate Fix Script
-- Place this script inside your NPC model and name it "VotingNPC"
-- MAKE SURE TO DELETE ANY OTHER VotingNPC SCRIPTS FROM ServerScriptService!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

print("VotingNPC Ultimate Fix script starting...")

-- EMERGENCY CLEANUP: Remove ALL existing vote displays from anywhere in the game
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") and obj.Name == "VoteDisplay" then
        obj:Destroy()
        print("Destroyed existing vote display")
    end
end

-- EMERGENCY CLEANUP: Remove any ClickDetectors from the NPC
local npc = script.Parent
for _, obj in pairs(npc:GetDescendants()) do
    if obj:IsA("ClickDetector") then
        obj:Destroy()
        print("Removed old ClickDetector")
    end
end

-- Make sure we have a voted players folder for tracking
if not ServerStorage:FindFirstChild("VotedPlayers") then
    local votedPlayersFolder = Instance.new("Folder")
    votedPlayersFolder.Name = "VotedPlayers"
    votedPlayersFolder.Parent = ServerStorage
    print("Created VotedPlayers folder")
end

-- Create vote counter values if they don't exist
if not ServerStorage:FindFirstChild("VotesFor") then
    local votesFor = Instance.new("IntValue")
    votesFor.Name = "VotesFor"
    votesFor.Value = 0
    votesFor.Parent = ServerStorage
else
    -- Reset existing counter to match actual votes
    local votesFor = 0
    for _, record in pairs(ServerStorage.VotedPlayers:GetChildren()) do
        if record:IsA("BoolValue") and record.Name:sub(1, 5) == "Vote_" and record.Value == true then
            votesFor = votesFor + 1
        end
    end
    ServerStorage.VotesFor.Value = votesFor
    print("Reset VotesFor to: " .. votesFor)
end

if not ServerStorage:FindFirstChild("VotesAgainst") then
    local votesAgainst = Instance.new("IntValue")
    votesAgainst.Name = "VotesAgainst"
    votesAgainst.Value = 0
    votesAgainst.Parent = ServerStorage
else
    -- Reset existing counter to match actual votes
    local votesAgainst = 0
    for _, record in pairs(ServerStorage.VotedPlayers:GetChildren()) do
        if record:IsA("BoolValue") and record.Name:sub(1, 5) == "Vote_" and record.Value == false then
            votesAgainst = votesAgainst + 1
        end
    end
    ServerStorage.VotesAgainst.Value = votesAgainst
    print("Reset VotesAgainst to: " .. votesAgainst)
end

-- Create RemoteEvents if they don't exist
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
    
    print("Created RemoteEvents")
end

-- Create a single vote display for the NPC
local function createVoteDisplay()
    local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("Part")
    
    if not primaryPart then
        warn("NPC has no valid parts for vote display!")
        return
    end
    
    -- Remove any existing vote displays from this NPC first
    for _, obj in pairs(primaryPart:GetChildren()) do
        if obj:IsA("BillboardGui") and obj.Name == "VoteDisplay" then
            obj:Destroy()
        end
    end
    
    -- Create new display
    local voteDisplay = Instance.new("BillboardGui")
    voteDisplay.Name = "VoteDisplay"
    voteDisplay.Size = UDim2.new(0, 200, 0, 100)
    voteDisplay.StudsOffset = Vector3.new(0, 3, 0)
    voteDisplay.AlwaysOnTop = true
    voteDisplay.MaxDistance = 7  -- Only visible within 7 studs
    voteDisplay.Parent = primaryPart
    
    -- Create display text
    local votesText = Instance.new("TextLabel")
    votesText.Name = "VotesText"
    votesText.Size = UDim2.new(1, 0, 1, 0)
    votesText.BackgroundTransparency = 1
    votesText.TextColor3 = Color3.fromRGB(255, 255, 255)
    votesText.TextStrokeTransparency = 0
    votesText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    votesText.Font = Enum.Font.GothamBold
    votesText.TextSize = 20
    votesText.Text = "בעד הרעיון: " .. ServerStorage.VotesFor.Value .. "\nלא בעד הרעיון: " .. ServerStorage.VotesAgainst.Value
    votesText.Parent = voteDisplay
    
    print("Created vote display")
    return voteDisplay
end

-- Update the vote display text
local function updateVoteDisplayText()
    local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("Part")
    if not primaryPart then return end
    
    local voteDisplay = primaryPart:FindFirstChild("VoteDisplay")
    if not voteDisplay then 
        voteDisplay = createVoteDisplay()
    else
        local votesText = voteDisplay:FindFirstChild("VotesText")
        if votesText then
            votesText.Text = "בעד הרעיון: " .. ServerStorage.VotesFor.Value .. "\nלא בעד הרעיון: " .. ServerStorage.VotesAgainst.Value
        end
    end
end

-- Add a ProximityPrompt to the NPC
local function setupProximityPrompt()
    local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("Part")
    
    if not primaryPart then
        warn("NPC has no valid parts for ProximityPrompt")
        return
    end
    
    -- Remove any existing ProximityPrompts
    for _, obj in pairs(primaryPart:GetChildren()) do
        if obj:IsA("ProximityPrompt") then
            obj:Destroy()
        end
    end
    
    -- Create the ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = "NPC"
    prompt.ActionText = "דבר עם ה־NPC"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = primaryPart
    
    print("Added ProximityPrompt")
    return prompt
end

-- Anti-exploit: Track last interaction time per player
local lastInteraction = {}

-- Create the vote display and setup the ProximityPrompt
local voteDisplay = createVoteDisplay()
local prompt = setupProximityPrompt()

-- Connect prompt triggering
prompt.Triggered:Connect(function(player)
    -- Anti-exploit: Cooldown system
    local currentTime = tick()
    if lastInteraction[player.UserId] and currentTime - lastInteraction[player.UserId] < 1 then
        print("Interaction too frequent from " .. player.Name .. " - ignoring")
        return
    end
    lastInteraction[player.UserId] = currentTime
    
    print("NPC prompt triggered by " .. player.Name)
    
    -- Get player's current vote
    local currentVote = nil
    local voteRecordName = "Vote_" .. tostring(player.UserId)
    local voteRecord = ServerStorage.VotedPlayers:FindFirstChild(voteRecordName)
    
    if voteRecord and voteRecord:IsA("BoolValue") then
        currentVote = voteRecord.Value
    end
    
    -- Open voting menu for player with current vote state
    ReplicatedStorage.NPCRemotes.OpenVoteMenu:FireClient(player, currentVote)
end)

-- Handle vote submission from client
ReplicatedStorage.NPCRemotes.SubmitVote.OnServerEvent:Connect(function(player, liked)
    -- Basic validation
    if not player or not player:IsA("Player") then return end
    
    -- Anti-exploit: Rate limiting
    local currentTime = tick()
    if lastInteraction[player.UserId] and currentTime - lastInteraction[player.UserId] < 0.5 then
        print("Vote too soon after interaction from " .. player.Name .. " - ignoring")
        return
    end
    lastInteraction[player.UserId] = currentTime
    
    print("Vote received from " .. player.Name .. ": " .. (liked and "Liked" or "Disliked"))
    
    -- Use a consistent naming scheme
    local voteRecordName = "Vote_" .. tostring(player.UserId)
    local voteRecord = ServerStorage.VotedPlayers:FindFirstChild(voteRecordName)
    
    -- Handle vote changing or new vote
    if voteRecord and voteRecord:IsA("BoolValue") then
        -- Player already voted, check if they're changing their vote
        if voteRecord.Value == liked then
            -- Same vote as before, no change needed
            print(player.Name .. " voted the same as before")
            return
        else
            -- Player is changing their vote
            print(player.Name .. " changing vote from " .. (voteRecord.Value and "Liked to Disliked" or "Disliked to Liked"))
            
            -- Update vote counts
            if voteRecord.Value == true then  -- Previously liked
                ServerStorage.VotesFor.Value = math.max(0, ServerStorage.VotesFor.Value - 1)
                ServerStorage.VotesAgainst.Value = ServerStorage.VotesAgainst.Value + 1
            else  -- Previously disliked
                ServerStorage.VotesAgainst.Value = math.max(0, ServerStorage.VotesAgainst.Value - 1)
                ServerStorage.VotesFor.Value = ServerStorage.VotesFor.Value + 1
            end
            
            -- Update player's vote
            voteRecord.Value = liked
        end
    else
        -- First time voting
        voteRecord = Instance.new("BoolValue")
        voteRecord.Name = voteRecordName
        voteRecord.Value = liked
        voteRecord.Parent = ServerStorage.VotedPlayers
        
        -- Update vote counts
        if liked then
            ServerStorage.VotesFor.Value = ServerStorage.VotesFor.Value + 1
        else
            ServerStorage.VotesAgainst.Value = ServerStorage.VotesAgainst.Value + 1
        end
        
        print("New vote recorded for " .. player.Name)
    end
    
    print("Current vote counts - For: " .. ServerStorage.VotesFor.Value .. ", Against: " .. ServerStorage.VotesAgainst.Value)
    
    -- Update the display
    updateVoteDisplayText()
end)

-- Verify vote counts periodically
spawn(function()
    while wait(30) do  -- Check every 30 seconds
        local votesFor = 0
        local votesAgainst = 0
        
        -- Count all actual votes
        for _, record in pairs(ServerStorage.VotedPlayers:GetChildren()) do
            if record:IsA("BoolValue") and record.Name:sub(1, 5) == "Vote_" then
                if record.Value then
                    votesFor = votesFor + 1
                else
                    votesAgainst = votesAgainst + 1
                end
            end
        end
        
        -- Fix any inconsistencies
        if votesFor ~= ServerStorage.VotesFor.Value or votesAgainst ~= ServerStorage.VotesAgainst.Value then
            warn("Vote count inconsistency detected! Fixing...")
            ServerStorage.VotesFor.Value = votesFor
            ServerStorage.VotesAgainst.Value = votesAgainst
            updateVoteDisplayText()
        end
        
        -- Also check that the display exists and is working
        local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("Part")
        if primaryPart and not primaryPart:FindFirstChild("VoteDisplay") then
            warn("Vote display missing - recreating")
            createVoteDisplay()
        end
    end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
    lastInteraction[player.UserId] = nil
end)

print("VotingNPC Ultimate Fix setup complete!")