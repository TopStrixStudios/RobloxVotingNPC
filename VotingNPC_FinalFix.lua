--[[
FINAL FIXED VOTING NPC SERVER SCRIPT

IMPORTANT SETUP INSTRUCTIONS:
1. Place this script INSIDE your Voting NPC model
2. The NPC model must have a PrimaryPart (usually the Torso/HumanoidRootPart)
3. Remove ANY other voting NPC scripts from the entire game
4. Place the matching VotingNPCClient script in StarterPlayerScripts

This script provides:
- Clear emoji vote display (👍 and 👎)
- Highly visible hologram above NPC
- Vote changing with 10-second cooldown
- Auto-repair if display disappears
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- CONFIGURATION
local VOTE_COOLDOWN = 10 -- Seconds before a player can change their vote
local DISPLAY_RADIUS = 50 -- Increased visibility radius
local HOLOGRAM_HEIGHT = 3.5 -- Height above NPC
local UPDATE_INTERVAL = 0.5 -- How often to refresh the display

print("=== Final Fixed Voting NPC Starting ===")

----------------------------
-- INITIALIZATION
----------------------------

-- Ensure we're in an NPC model
local isInNPC = false
local npcModel = script.Parent
if npcModel:IsA("Model") and npcModel.PrimaryPart then
    isInNPC = true
    print("NPC model found with PrimaryPart")
else
    warn("WARNING: This script should be placed inside an NPC model with a PrimaryPart")
    warn("Current parent:", npcModel.Name, "is", npcModel.ClassName)
    -- Will continue running but some features may not work correctly
end

-- Remove any existing voting NPCs to prevent duplicates
print("Checking for duplicate scripts...")
local duplicates = 0
for _, existingScript in pairs(npcModel:GetDescendants()) do
    if existingScript:IsA("Script") and 
       existingScript ~= script and 
       (existingScript.Name:find("VotingNPC") or existingScript.Name:find("Vote")) then
        print("Found duplicate script:", existingScript.Name, "- Disabling")
        existingScript.Disabled = true
        duplicates = duplicates + 1
    end
end
print("Disabled", duplicates, "duplicate scripts")

-- Initialize storage
local voteData = {
    likes = 0,
    dislikes = 0,
    voted = {}, -- [userId] = {vote = bool, timestamp = number}
    voteDisplay = nil
}

-- Setup event folder for client-server communication
local NPCRemotes
if ReplicatedStorage:FindFirstChild("NPCRemotes") then
    NPCRemotes = ReplicatedStorage.NPCRemotes
    -- Clean up any existing events to prevent duplicates
    for _, child in pairs(NPCRemotes:GetChildren()) do
        child:Destroy()
    end
    print("Cleaned up existing NPCRemotes folder")
else
    NPCRemotes = Instance.new("Folder")
    NPCRemotes.Name = "NPCRemotes"
    NPCRemotes.Parent = ReplicatedStorage
    print("Created new NPCRemotes folder")
end

-- Create RemoteEvents
local openVoteMenuEvent = Instance.new("RemoteEvent")
openVoteMenuEvent.Name = "OpenVoteMenu"
openVoteMenuEvent.Parent = NPCRemotes

local submitVoteEvent = Instance.new("RemoteEvent")
submitVoteEvent.Name = "SubmitVote"
submitVoteEvent.Parent = NPCRemotes

local voteCooldownEvent = Instance.new("RemoteEvent")
voteCooldownEvent.Name = "VoteCooldown"
voteCooldownEvent.Parent = NPCRemotes

print("RemoteEvents created successfully")

----------------------------
-- VOTE DISPLAY FUNCTIONS
----------------------------

-- Create a vote display above the NPC
local function createVoteDisplay()
    -- First clean up any existing displays
    if voteData.voteDisplay and voteData.voteDisplay.Parent then
        voteData.voteDisplay:Destroy()
    end
    
    -- Create a new BillboardGui to display votes
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "VoteDisplay"
    billboardGui.Size = UDim2.new(0, 300, 0, 80) -- Larger size for better visibility
    billboardGui.StudsOffset = Vector3.new(0, HOLOGRAM_HEIGHT, 0)
    billboardGui.Adornee = npcModel.PrimaryPart
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = DISPLAY_RADIUS -- Increased to be more visible
    
    -- Create a background frame for better visibility
    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "Background"
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgFrame.BackgroundTransparency = 0.5 -- Semi-transparent background
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = billboardGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bgFrame
    
    -- Add a glow effect around the frame
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 2
    uiStroke.Color = Color3.fromRGB(255, 255, 255)
    uiStroke.Transparency = 0.3
    uiStroke.Parent = bgFrame
    
    -- Create the text label for the vote count
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "VoteCountLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 32 -- Larger text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = bgFrame
    
    -- Update with current vote counts
    updateVoteText(textLabel)
    
    -- Add the display to the workspace
    billboardGui.Parent = npcModel
    voteData.voteDisplay = billboardGui
    
    print("Enhanced vote display created with high visibility")
    return billboardGui
end

-- Update the text on the vote display
function updateVoteText(textLabel)
    if not textLabel or not textLabel.Parent then return end
    
    -- Simple format with large emojis: 👍 X | 👎 Y
    textLabel.Text = "👍 " .. voteData.likes .. " | 👎 " .. voteData.dislikes
    
    -- Color the text based on which has more votes
    if voteData.likes > voteData.dislikes then
        textLabel.TextColor3 = Color3.fromRGB(85, 255, 127) -- Green
        textLabel.Parent.BackgroundColor3 = Color3.fromRGB(0, 50, 0) -- Dark green background
    elseif voteData.dislikes > voteData.likes then
        textLabel.TextColor3 = Color3.fromRGB(255, 85, 85) -- Red
        textLabel.Parent.BackgroundColor3 = Color3.fromRGB(50, 0, 0) -- Dark red background
    else
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White (equal)
        textLabel.Parent.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black background
    end
end

-- Update the vote display with current totals
local function updateVoteDisplay()
    -- If display doesn't exist, create it
    if not voteData.voteDisplay or not voteData.voteDisplay.Parent then
        voteData.voteDisplay = createVoteDisplay()
        return
    end
    
    -- Otherwise just update the text
    local backgroundFrame = voteData.voteDisplay:FindFirstChild("Background")
    if backgroundFrame then
        local textLabel = backgroundFrame:FindFirstChild("VoteCountLabel")
        if textLabel then
            updateVoteText(textLabel)
        else
            -- If the label is missing, recreate the display
            voteData.voteDisplay = createVoteDisplay()
        end
    else
        -- If the structure is wrong, recreate the display
        voteData.voteDisplay = createVoteDisplay()
    end
end

----------------------------
-- INTERACTION HANDLING
----------------------------

-- Process a player's vote
local function processVote(player, liked)
    local userId = player.UserId
    
    -- First vote or changing vote after cooldown?
    if not voteData.voted[userId] then
        -- First time voting
        voteData.voted[userId] = {
            vote = liked,
            timestamp = os.time()
        }
        
        -- Update totals
        if liked then
            voteData.likes = voteData.likes + 1
        else
            voteData.dislikes = voteData.dislikes + 1
        end
        
        print(player.Name, "voted:", liked and "Liked" or "Disliked")
    else
        -- Changing vote, check cooldown
        local lastVote = voteData.voted[userId]
        local timeSinceLastVote = os.time() - lastVote.timestamp
        
        if timeSinceLastVote < VOTE_COOLDOWN then
            -- Cooldown still active
            local timeRemaining = math.ceil(VOTE_COOLDOWN - timeSinceLastVote)
            print(player.Name, "tried to change vote too soon. Cooldown:", timeRemaining, "seconds")
            voteCooldownEvent:FireClient(player, timeRemaining)
            return false
        end
        
        -- Cooldown passed, allow vote change
        local previousVote = lastVote.vote
        
        -- Only make changes if the vote is actually different
        if previousVote ~= liked then
            -- Update totals (remove old vote, add new vote)
            if previousVote then
                voteData.likes = voteData.likes - 1
            else
                voteData.dislikes = voteData.dislikes - 1
            end
            
            if liked then
                voteData.likes = voteData.likes + 1
            else
                voteData.dislikes = voteData.dislikes + 1
            end
            
            -- Update player's vote record
            voteData.voted[userId] = {
                vote = liked,
                timestamp = os.time()
            }
            
            print(player.Name, "changed vote from", previousVote and "Like" or "Dislike", 
                "to", liked and "Like" or "Dislike")
        else
            print(player.Name, "voted the same as before:", liked and "Like" or "Dislike")
        end
    end
    
    -- Update the display
    updateVoteDisplay()
    return true
end

-- Handle click/touch detection
local function setupInteraction()
    if not isInNPC then
        warn("NPC model not properly setup, interaction may not work correctly")
        return
    end
    
    local clickDetector = npcModel:FindFirstChild("ClickDetector")
    if not clickDetector then
        clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 10
        clickDetector.Parent = npcModel.PrimaryPart
        print("Created new ClickDetector for NPC")
    end
    
    clickDetector.MouseClick:Connect(function(player)
        print(player.Name, "clicked the voting NPC")
        
        -- Get current vote status for this player
        local currentVote = nil
        if voteData.voted[player.UserId] then
            currentVote = voteData.voted[player.UserId].vote
        end
        
        -- Open the voting menu with current vote status
        openVoteMenuEvent:FireClient(player, currentVote)
    end)
    
    print("NPC interaction setup complete")
end

----------------------------
-- CONTINUOUS DISPLAY UPDATE
----------------------------

-- Start a continuous update loop for the display
local function startDisplayUpdateLoop()
    spawn(function()
        while wait(UPDATE_INTERVAL) do
            updateVoteDisplay()
        end
    end)
    print("Started continuous display update loop")
end

----------------------------
-- SELF-REPAIR SYSTEM
----------------------------

-- Check if vote display is still valid, recreate if needed
local function checkVoteDisplay()
    if not voteData.voteDisplay or not voteData.voteDisplay.Parent then
        print("Vote display missing - recreating")
        createVoteDisplay()
    end
end

-- Self-repair loop
local function startSelfRepairSystem()
    spawn(function()
        while wait(5) do -- Check every 5 seconds
            checkVoteDisplay()
        end
    end)
    print("Started self-repair system")
end

----------------------------
-- PLAYER MANAGEMENT
----------------------------

-- Handle player leaving
local function onPlayerRemoving(player)
    local userId = player.UserId
    
    -- If the player had voted, they're leaving, so remove their vote
    if voteData.voted[userId] then
        local playerVote = voteData.voted[userId].vote
        
        -- Adjust the counts
        if playerVote then
            voteData.likes = voteData.likes - 1
        else
            voteData.dislikes = voteData.dislikes - 1
        end
        
        -- Clean up stored vote
        voteData.voted[userId] = nil
        
        -- Update display
        updateVoteDisplay()
        print(player.Name, "left game, removed their vote")
    end
end

----------------------------
-- MAIN INITIALIZATION
----------------------------

-- Start the system
local function initializeVotingSystem()
    -- Create vote display
    createVoteDisplay()
    
    -- Setup interaction
    setupInteraction()
    
    -- Connect submit vote event
    submitVoteEvent.OnServerEvent:Connect(function(player, liked)
        processVote(player, liked)
    end)
    
    -- Connect player leaving
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Start self-repair system
    startSelfRepairSystem()
    
    -- Start continuous display update
    startDisplayUpdateLoop()
    
    print("=== Final Fixed Voting NPC Initialized ===")
end

-- Initialize!
initializeVotingSystem()