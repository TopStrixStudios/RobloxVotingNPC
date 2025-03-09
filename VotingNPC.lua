-- VotingNPC script - handles NPC interaction and voting system
-- Place this script INSIDE your NPC model

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

print("VotingNPC script started!")

local npc = script.Parent

-- Make sure we have a VotedPlayers folder for tracking
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

-- Function to update vote display above NPC
local function updateVoteDisplay()
    local primaryPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("Part")
    
    if not primaryPart then
        warn("No valid part found for vote display")
        return
    end
    
    local voteDisplay = primaryPart:FindFirstChild("VoteDisplay")
    
    if not voteDisplay then
        voteDisplay = Instance.new("BillboardGui")
        voteDisplay.Name = "VoteDisplay"
        voteDisplay.Size = UDim2.new(0, 200, 0, 100)
        voteDisplay.StudsOffset = Vector3.new(0, 3, 0)
        voteDisplay.AlwaysOnTop = true
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
        
        print("Created new vote display")
    end
    
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

-- Set up initial vote display
updateVoteDisplay()

-- Connect prompt triggering
prompt.Triggered:Connect(function(player)
    print("NPC prompt triggered by " .. player.Name)
    
    -- Check if player has already voted
    if ServerStorage.VotedPlayers:FindFirstChild(tostring(player.UserId)) then
        print(player.Name .. " already voted")
        -- Send a notification that they've already voted
        ReplicatedStorage.NPCRemotes.OpenVoteMenu:FireClient(player, true)
        return
    end
    
    print("Opening vote menu for " .. player.Name)
    -- Open voting menu for player
    ReplicatedStorage.NPCRemotes.OpenVoteMenu:FireClient(player, false)
end)

print("VotingNPC setup complete!")