--[[
MULTI-IDEA VOTING NPC

SETUP INSTRUCTIONS FOR MULTIPLE NPCs:
1. Place this script INSIDE each NPC model
2. Set an "NPCId" attribute on each NPC model with a unique name (e.g., "MusicAreas", "NewSkins")
3. Set "IdeaTitle" and "IdeaDescription" attributes on each NPC model with your custom content
4. Each NPC will have its own separate data storage

With this system, you can have multiple NPCs for different ideas, each with:
- Unique title and description
- Separate vote counts
- Independent data storage
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- CONFIGURATION
local VOTE_COOLDOWN = 10 -- Seconds before a player can change their vote
local DISPLAY_VISIBILITY_DISTANCE = 25 -- Maximum distance to see the display (studs)
local HOLOGRAM_HEIGHT = 3.5 -- Height above NPC
local UPDATE_INTERVAL = 0.5 -- How often to refresh the display
local AUTO_SAVE_INTERVAL = 60 -- How often to auto-save vote data (seconds)
local INTERACTION_DISTANCE = 8 -- How close player needs to be to interact (studs)

-- DEFAULT CONTENT (will be overridden by model attributes if set)
local DEFAULT_TITLE = "רעיון חדש למשחק" -- "New Idea for the Game"
local DEFAULT_DESCRIPTION = "אנא הצביעו אם אתם אוהבים את הרעיון." -- "Please vote if you like the idea"

-- Get the NPC's unique ID or create a new one if none exists
local npcModel = script.Parent
local npcId = npcModel:GetAttribute("NPCId")
if not npcId then
    -- Generate a random ID if none set
    npcId = "NPC_" .. math.random(1000, 9999)
    npcModel:SetAttribute("NPCId", npcId)
    print("Created new NPCId:", npcId)
else
    print("Using existing NPCId:", npcId)
end

-- Get idea content from model attributes
local ideaTitle = npcModel:GetAttribute("IdeaTitle") or DEFAULT_TITLE
local ideaDescription = npcModel:GetAttribute("IdeaDescription") or DEFAULT_DESCRIPTION

-- Data Store key is unique for each NPC ID
local DATA_STORE_KEY = "VoteData_" .. npcId
local VoteDataStore = DataStoreService:GetDataStore("NPCVotingSystemV3")

print("=== Multi-Idea Voting NPC Starting ===")
print("NPC ID:", npcId)
print("Idea Title:", ideaTitle)

----------------------------
-- UTILITY FUNCTIONS
----------------------------

-- Count items in a table (local function, not modifying global table)
local function countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

----------------------------
-- INITIALIZATION
----------------------------

-- Ensure we're in an NPC model
local isInNPC = false
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
    voterData = {}, -- [userId string] = {vote = bool, timestamp = number}
    voteDisplay = nil
}

-- Setup event folder for client-server communication
local NPCRemotes
if ReplicatedStorage:FindFirstChild("NPCRemotes") then
    NPCRemotes = ReplicatedStorage.NPCRemotes
else
    NPCRemotes = Instance.new("Folder")
    NPCRemotes.Name = "NPCRemotes"
    NPCRemotes.Parent = ReplicatedStorage
    print("Created NPCRemotes folder")
end

-- Create a folder for this specific NPC's remotes
local npcRemoteFolder = NPCRemotes:FindFirstChild(npcId)
if npcRemoteFolder then
    -- Clean up existing events to prevent duplicates
    for _, child in pairs(npcRemoteFolder:GetChildren()) do
        child:Destroy()
    end
    print("Cleaned up existing NPC remotes folder for", npcId)
else
    npcRemoteFolder = Instance.new("Folder")
    npcRemoteFolder.Name = npcId
    npcRemoteFolder.Parent = NPCRemotes
    print("Created new NPC remotes folder for", npcId)
end

-- Create RemoteEvents for this NPC
local openVoteMenuEvent = Instance.new("RemoteEvent")
openVoteMenuEvent.Name = "OpenVoteMenu"
openVoteMenuEvent.Parent = npcRemoteFolder

local submitVoteEvent = Instance.new("RemoteEvent")
submitVoteEvent.Name = "SubmitVote"
submitVoteEvent.Parent = npcRemoteFolder

local voteCooldownEvent = Instance.new("RemoteEvent")
voteCooldownEvent.Name = "VoteCooldown"
voteCooldownEvent.Parent = npcRemoteFolder

-- Store idea content in this NPC's RemoteEvents folder
local ideaInfoFolder = Instance.new("Folder")
ideaInfoFolder.Name = "IdeaInfo"
ideaInfoFolder.Parent = npcRemoteFolder

local titleValue = Instance.new("StringValue")
titleValue.Name = "Title"
titleValue.Value = ideaTitle
titleValue.Parent = ideaInfoFolder

local descriptionValue = Instance.new("StringValue")
descriptionValue.Name = "Description"
descriptionValue.Value = ideaDescription
descriptionValue.Parent = ideaInfoFolder

print("RemoteEvents created successfully for NPC:", npcId)

----------------------------
-- ANTI-EXPLOIT VERIFICATION
----------------------------

-- Verify vote counts match actual voters data
local function verifyVoteCounts()
    -- Count likes and dislikes from voters list
    local actualLikes = 0
    local actualDislikes = 0
    
    -- Count each vote in the voters table
    for _, voterData in pairs(voteData.voterData) do
        if voterData.vote == true then
            actualLikes = actualLikes + 1
        elseif voterData.vote == false then
            actualDislikes = actualDislikes + 1
        end
    end
    
    -- If counts don't match, correct them
    if actualLikes ~= voteData.likes or actualDislikes ~= voteData.dislikes then
        print("Vote count mismatch detected! Correcting counts...")
        print("Previous counts: Likes =", voteData.likes, "Dislikes =", voteData.dislikes)
        voteData.likes = actualLikes
        voteData.dislikes = actualDislikes
        print("Corrected counts: Likes =", voteData.likes, "Dislikes =", voteData.dislikes)
    end
end

----------------------------
-- VOTE DISPLAY FUNCTIONS
----------------------------

-- Create a vote display above the NPC with title
local function createVoteDisplay()
    -- First clean up any existing displays
    if voteData.voteDisplay and voteData.voteDisplay.Parent then
        voteData.voteDisplay:Destroy()
    end
    
    -- Create a new BillboardGui to display votes and title
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "VoteDisplay"
    billboardGui.Size = UDim2.new(0, 240, 0, 100) -- Increased height for title
    billboardGui.StudsOffset = Vector3.new(0, HOLOGRAM_HEIGHT, 0) -- Height offset
    billboardGui.Adornee = npcModel.PrimaryPart -- Attach to NPC
    billboardGui.AlwaysOnTop = true -- Make it visible
    billboardGui.MaxDistance = DISPLAY_VISIBILITY_DISTANCE
    billboardGui.Active = true
    
    -- Create a background frame for better visibility
    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "Background"
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgFrame.BackgroundTransparency = 0.3 -- More opaque for better visibility
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
    
    -- Create the title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0.5, 0, 0, 10)
    titleLabel.AnchorPoint = Vector2.new(0.5, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 22
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Text = ideaTitle
    titleLabel.Parent = bgFrame
    
    -- Create the vote count label
    local voteLabel = Instance.new("TextLabel")
    voteLabel.Name = "VoteCountLabel"
    voteLabel.Size = UDim2.new(1, -20, 0, 30)
    voteLabel.Position = UDim2.new(0.5, 0, 1, -40)
    voteLabel.AnchorPoint = Vector2.new(0.5, 0)
    voteLabel.BackgroundTransparency = 1
    voteLabel.Font = Enum.Font.GothamBold
    voteLabel.TextSize = 24
    voteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    voteLabel.TextStrokeTransparency = 0
    voteLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    voteLabel.Parent = bgFrame
    
    -- Update with current vote counts
    updateVoteText(voteLabel)
    
    -- Add the display to the NPC model
    billboardGui.Parent = npcModel
    voteData.voteDisplay = billboardGui
    
    print("Created vote display for NPC:", npcId)
    return billboardGui
end

-- Update the text on the vote display
function updateVoteText(textLabel)
    if not textLabel or not textLabel.Parent then return end
    
    -- Format with emojis: 👍 X | 👎 Y
    textLabel.Text = "👍 " .. voteData.likes .. " | 👎 " .. voteData.dislikes
    
    -- Color the text based on which has more votes
    if voteData.likes > voteData.dislikes then
        textLabel.TextColor3 = Color3.fromRGB(85, 255, 127) -- Green
    elseif voteData.dislikes > voteData.likes then
        textLabel.TextColor3 = Color3.fromRGB(255, 85, 85) -- Red
    else
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White (equal)
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
        local voteLabel = backgroundFrame:FindFirstChild("VoteCountLabel")
        if voteLabel then
            updateVoteText(voteLabel)
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
-- DATA PERSISTENCE
----------------------------

-- Convert voter data to saveable format (DataStore doesn't like numeric keys)
local function prepareVoterDataForSaving()
    local saveableData = {}
    
    for userId, voteInfo in pairs(voteData.voterData) do
        -- Ensure userId is a string
        local userIdStr = tostring(userId)
        
        saveableData[userIdStr] = {
            vote = voteInfo.vote,
            timestamp = voteInfo.timestamp
        }
    end
    
    return saveableData
end

-- Load vote data from DataStore
local function loadVoteData()
    local success, result = pcall(function()
        return VoteDataStore:GetAsync(DATA_STORE_KEY)
    end)
    
    if success and result then
        -- Copy likes and dislikes from saved data
        voteData.likes = result.likes or 0
        voteData.dislikes = result.dislikes or 0
        
        -- Load voter data if available
        if result.voterData then
            voteData.voterData = {}
            
            -- Process each voter entry
            for userIdStr, voteInfo in pairs(result.voterData) do
                voteData.voterData[userIdStr] = {
                    vote = voteInfo.vote,
                    timestamp = voteInfo.timestamp
                }
            end
            
            local voterCount = countTable(result.voterData)
            print("Loaded voter data for", voterCount, "players (NPC:", npcId, ")")
        end
        
        print("Loaded vote data for NPC", npcId, ": Likes =", voteData.likes, "Dislikes =", voteData.dislikes)
        
        -- Now verify votes match actual voter data
        verifyVoteCounts()
        return true
    else
        if not success then
            warn("Failed to load vote data for NPC", npcId, ":", result)
        else
            print("No saved vote data found for NPC", npcId, ", starting fresh")
        end
        return false
    end
end

-- Save vote data to DataStore
local function saveVoteData()
    -- Prepare voter data for saving
    local voterDataToSave = prepareVoterDataForSaving()
    
    -- Create data package
    local dataToSave = {
        likes = voteData.likes,
        dislikes = voteData.dislikes,
        voterData = voterDataToSave,
        lastUpdated = os.time()
    }
    
    local success, result = pcall(function()
        VoteDataStore:SetAsync(DATA_STORE_KEY, dataToSave)
    end)
    
    if success then
        local count = countTable(voterDataToSave)
        print("Successfully saved vote data for NPC", npcId, ": Likes =", voteData.likes, "Dislikes =", voteData.dislikes, "Voters =", count)
        return true
    else
        warn("Failed to save vote data for NPC", npcId, ":", result)
        return false
    end
end

-- Auto-save data periodically
local function startAutoSave()
    spawn(function()
        while wait(AUTO_SAVE_INTERVAL) do
            saveVoteData()
        end
    end)
    print("Started auto-save system for NPC", npcId)
end

----------------------------
-- PLAYER MANAGEMENT
----------------------------

-- When a player joins, check if they have voted before
local function onPlayerAdded(player)
    -- Convert userId to string for lookup
    local userIdStr = tostring(player.UserId)
    
    -- Check if this player has a saved vote for this specific NPC
    if voteData.voterData[userIdStr] then
        print(player.Name, "joined with existing vote for NPC", npcId, ":", 
              voteData.voterData[userIdStr].vote and "Like" or "Dislike")
    else
        print(player.Name, "joined with no previous vote for NPC", npcId)
    end
end

----------------------------
-- INTERACTION HANDLING
----------------------------

-- Process a player's vote
local function processVote(player, liked)
    -- Use string keys for DataStore compatibility
    local userIdStr = tostring(player.UserId)
    
    -- First vote or changing vote after cooldown?
    if not voteData.voterData[userIdStr] then
        -- First time voting
        voteData.voterData[userIdStr] = {
            vote = liked,
            timestamp = os.time()
        }
        
        -- Update totals
        if liked then
            voteData.likes = voteData.likes + 1
        else
            voteData.dislikes = voteData.dislikes + 1
        end
        
        print(player.Name, "voted on NPC", npcId, ":", liked and "Liked" or "Disliked")
    else
        -- Changing vote, check cooldown
        local lastVote = voteData.voterData[userIdStr]
        local timeSinceLastVote = os.time() - lastVote.timestamp
        
        if timeSinceLastVote < VOTE_COOLDOWN then
            -- Cooldown still active
            local timeRemaining = math.ceil(VOTE_COOLDOWN - timeSinceLastVote)
            print(player.Name, "tried to change vote on NPC", npcId, "too soon. Cooldown:", timeRemaining, "seconds")
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
            voteData.voterData[userIdStr] = {
                vote = liked,
                timestamp = os.time()
            }
            
            print(player.Name, "changed vote on NPC", npcId, "from", previousVote and "Like" or "Dislike", 
                "to", liked and "Like" or "Dislike")
        else
            print(player.Name, "voted the same as before on NPC", npcId, ":", liked and "Like" or "Dislike")
        end
    end
    
    -- Verify counts match voter data
    verifyVoteCounts()
    
    -- Update the display
    updateVoteDisplay()
    
    -- Save data after vote changes
    spawn(saveVoteData)
    
    return true
end

-- Setup ProximityPrompt for E key interaction
local function setupProximityPrompt()
    if not isInNPC then
        warn("NPC model not properly setup, interaction may not work correctly")
        return
    end
    
    -- Remove any existing ClickDetector
    local clickDetector = npcModel.PrimaryPart:FindFirstChild("ClickDetector")
    if clickDetector then
        clickDetector:Destroy()
        print("Removed old ClickDetector from NPC", npcId)
    end
    
    -- Remove any existing ProximityPrompt
    local existingPrompt = npcModel.PrimaryPart:FindFirstChild("VotePrompt")
    if existingPrompt then
        existingPrompt:Destroy()
    end
    
    -- Create new ProximityPrompt
    local proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.Name = "VotePrompt"
    proximityPrompt.ObjectText = ideaTitle -- Use NPC's specific title
    proximityPrompt.ActionText = "הצבע" -- Vote
    proximityPrompt.MaxActivationDistance = INTERACTION_DISTANCE
    proximityPrompt.HoldDuration = 0 -- No need to hold the button
    proximityPrompt.RequiresLineOfSight = false
    proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
    proximityPrompt.Parent = npcModel.PrimaryPart
    
    -- Set a hidden attribute to store the NPC ID
    proximityPrompt:SetAttribute("NPCId", npcId)
    
    -- Connect to the triggered event
    proximityPrompt.Triggered:Connect(function(player)
        print(player.Name, "pressed E to interact with NPC", npcId)
        
        -- Use string key for lookup
        local userIdStr = tostring(player.UserId)
        
        -- Get current vote status for this player on this specific NPC
        local currentVote = nil
        if voteData.voterData[userIdStr] then
            currentVote = voteData.voterData[userIdStr].vote
        end
        
        -- Open the voting menu with current vote status
        openVoteMenuEvent:FireClient(player, currentVote)
    end)
    
    print("E key interaction setup for NPC", npcId)
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
    print("Started display update loop for NPC", npcId)
end

----------------------------
-- SELF-REPAIR SYSTEM
----------------------------

-- Check if vote display is still valid, recreate if needed
local function checkVoteDisplay()
    if not voteData.voteDisplay or not voteData.voteDisplay.Parent then
        print("Vote display missing for NPC", npcId, "- recreating")
        createVoteDisplay()
    end
end

-- Check if ProximityPrompt still exists, recreate if needed
local function checkProximityPrompt()
    if not npcModel.PrimaryPart:FindFirstChild("VotePrompt") then
        print("ProximityPrompt missing for NPC", npcId, "- recreating")
        setupProximityPrompt()
    end
end

-- Self-repair loop
local function startSelfRepairSystem()
    spawn(function()
        while wait(5) do -- Check every 5 seconds
            checkVoteDisplay()
            checkProximityPrompt()
            -- Also verify vote counts regularly
            verifyVoteCounts()
        end
    end)
    print("Started self-repair system for NPC", npcId)
end

----------------------------
-- SHUTDOWN HANDLING
----------------------------

-- Save data when server is shutting down
local function onGameShutdown()
    print("Game shutting down, saving vote data for NPC", npcId)
    saveVoteData()
end

----------------------------
-- MAIN INITIALIZATION
----------------------------

-- Start the system
local function initializeVotingSystem()
    -- Try to load saved data within pcall to handle any errors
    pcall(function()
        loadVoteData()
    end)
    
    -- Create vote display
    createVoteDisplay()
    
    -- Setup E key interaction
    setupProximityPrompt()
    
    -- Connect submit vote event
    submitVoteEvent.OnServerEvent:Connect(function(player, liked)
        processVote(player, liked)
    end)
    
    -- Connect player joining
    Players.PlayerAdded:Connect(onPlayerAdded)
    
    -- Connect shutdown event
    game:BindToClose(onGameShutdown)
    
    -- Start self-repair system
    startSelfRepairSystem()
    
    -- Start continuous display update
    startDisplayUpdateLoop()
    
    -- Start auto-save system
    startAutoSave()
    
    -- Process existing players
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    print("=== Multi-Idea Voting NPC Initialized ===")
    print("NPC ID:", npcId)
    print("Idea Title:", ideaTitle)
end

-- Initialize!
initializeVotingSystem()