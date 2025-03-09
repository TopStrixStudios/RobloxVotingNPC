-- VotingNPC script - Final version
-- Place this script INSIDE your NPC model as "VotingNPC"
-- DELETE ANY OTHER VotingNPC scripts from your game!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Prevent multiple copies from running
if not _G.VotingSystemInitialized then
    _G.VotingSystemInitialized = true
else
    -- This is a duplicate script - disable it
    print("Duplicate VotingNPC script detected! Disabling this copy.")
    return
end

print("VotingNPC script initialized")

local npc = script.Parent

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
end

if not ServerStorage:FindFirstChild("VotesAgainst") then
    local votesAgainst = Instance.new("IntValue")
    votesAgainst.Name = "VotesAgainst"
    votesAgainst.Value = 0
    votesAgainst.Parent = ServerStorage
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

-- Update text on all existing BillboardGuis
local function updateAllDisplayText()
    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") then
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    local voteDisplay = part:FindFirstChild("VoteDisplay")
                    if voteDisplay and voteDisplay:IsA("BillboardGui") then
                        local votesText = voteDisplay:FindFirstChild("VotesText")
                        if votesText and votesText:IsA("TextLabel") then
                            votesText.Text = "בעד הרעיון: " .. ServerStorage.VotesFor.Value .. 
                                             "\nלא בעד הרעיון: " .. ServerStorage.VotesAgainst.Value
                        end
                    end
                end
            end
        end
    end
end

-- Function to ensure an NPC has a vote display
local function ensureVoteDisplay(model)
    local primaryPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("Part")
    
    if not primaryPart then
        warn("No valid part found for vote display on " .. model.Name)
        return
    end
    
    -- Check for existing display
    local voteDisplay = primaryPart:FindFirstChild("VoteDisplay")
    
    -- Only create if it doesn't exist
    if not voteDisplay then
        voteDisplay = Instance.new("BillboardGui")
        voteDisplay.Name = "VoteDisplay"
        voteDisplay.Size = UDim2.new(0, 200, 0, 100)
        voteDisplay.StudsOffset = Vector3.new(0, 3, 0)
        voteDisplay.AlwaysOnTop = true
        voteDisplay.MaxDistance = 7  -- Only visible within 7 studs as requested
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
        
        print("Created new vote display for " .. model.Name)
    end
    
    -- Always update the text
    local votesText = voteDisplay.VotesText
    votesText.Text = "בעד הרעיון: " .. ServerStorage.VotesFor.Value .. "\nלא בעד הרעיון: " .. ServerStorage.VotesAgainst.Value
end

-- Add a ProximityPrompt to the NPC (for E key interaction)
local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("Part")

if not primaryPart then
    warn("NPC has no valid parts for ProximityPrompt")
    return
end

-- Remove any existing ClickDetectors or ProximityPrompts
local existingClickDetector = primaryPart:FindFirstChild("ClickDetector")
if existingClickDetector then
    existingClickDetector:Destroy()
end

local existingPrompt = primaryPart:FindFirstChild("ProximityPrompt")
if existingPrompt then
    existingPrompt:Destroy()
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
print("Added ProximityPrompt to " .. primaryPart.Name)

-- Set up initial display
ensureVoteDisplay(npc)

-- Anti-exploit: Track last interaction time per player
local lastInteraction = {}

-- Connect prompt triggering
prompt.Triggered:Connect(function(player)
    -- Anti-exploit: Cooldown system
    local currentTime = tick()
    if lastInteraction[player.UserId] and currentTime - lastInteraction[player.UserId] < 1 then
        print("Interaction too frequent from " .. player.Name .. " - possible exploit attempt")
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
    -- Ensure player exists and is connected
    if not player or not player:IsDescendantOf(Players) then
        warn("Vote from invalid player detected")
        return
    end
    
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
    
    if voteRecord then
        -- Only proceed if it's a valid BoolValue
        if voteRecord:IsA("BoolValue") then
            -- Player already voted, check if they're changing their vote
            if voteRecord.Value == liked then
                -- Same vote as before, no change needed
                print(player.Name .. " voted the same as before")
                return
            else
                -- Player is changing their vote
                print(player.Name .. " changed vote from " .. (voteRecord.Value and "Liked to Disliked" or "Disliked to Liked"))
                
                -- Update vote counts (remove old vote, add new vote)
                if voteRecord.Value == true then  -- Previously liked
                    ServerStorage.VotesFor.Value = math.max(0, ServerStorage.VotesFor.Value - 1)
                    ServerStorage.VotesAgainst.Value = ServerStorage.VotesAgainst.Value + 1
                else  -- Previously disliked
                    ServerStorage.VotesAgainst.Value = math.max(0, ServerStorage.VotesAgainst.Value - 1)
                    ServerStorage.VotesFor.Value = ServerStorage.VotesFor.Value + 1
                end
                
                -- Update player's vote record
                voteRecord.Value = liked
            end
        else
            -- Invalid vote record type, remove and create a new one
            voteRecord:Destroy()
            voteRecord = nil
        end
    end
    
    -- Create a new vote record if needed
    if not voteRecord then
        -- First time voting or needed to recreate
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
    
    -- Just UPDATE text instead of recreating displays
    updateAllDisplayText()
end)

-- Anti-exploit: Validate vote counts periodically
spawn(function()
    while wait(60) do  -- Check every minute
        local votesFor = 0
        local votesAgainst = 0
        
        -- Count all votes to ensure consistency
        for _, record in pairs(ServerStorage.VotedPlayers:GetChildren()) do
            if record:IsA("BoolValue") and record.Name:sub(1, 5) == "Vote_" then
                if record.Value then
                    votesFor = votesFor + 1
                else
                    votesAgainst = votesFor + 1
                end
            end
        end
        
        -- Check and fix inconsistencies
        if votesFor ~= ServerStorage.VotesFor.Value or votesAgainst ~= ServerStorage.VotesAgainst.Value then
            warn("Vote count inconsistency detected! Fixing...")
            ServerStorage.VotesFor.Value = votesFor
            ServerStorage.VotesAgainst.Value = votesAgainst
            updateAllDisplayText()
        end
    end
end)

-- Players leaving cleanup
Players.PlayerRemoving:Connect(function(player)
    lastInteraction[player.UserId] = nil
end)

print("VotingNPC setup complete!")