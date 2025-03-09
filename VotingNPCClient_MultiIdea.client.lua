-- MULTI-IDEA CLIENT SCRIPT
-- Place this script in StarterPlayer/StarterPlayerScripts
-- Works with multiple NPCs, each with different ideas

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("Multi-Idea VotingNPCClient script starting...")

-- Connect to ProximityPrompt trigger
local function setupProximityPromptConnections()
    -- Listen for ProximityPrompt triggers from any NPC
    local ProximityPromptService = game:GetService("ProximityPromptService")
    
    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        -- Check if this is a voting NPC prompt
        if prompt.Name == "VotePrompt" then
            -- Get the NPC ID from the prompt's attributes
            local npcId = prompt:GetAttribute("NPCId")
            if npcId then
                -- Find this NPC's remote events folder
                local NPCRemotes = ReplicatedStorage:FindFirstChild("NPCRemotes")
                if NPCRemotes and NPCRemotes:FindFirstChild(npcId) then
                    local npcFolder = NPCRemotes[npcId]
                    
                    -- Get this NPC's OpenVoteMenu event
                    local openVoteMenuEvent = npcFolder:FindFirstChild("OpenVoteMenu")
                    if openVoteMenuEvent then
                        -- The server will respond with the current vote and show the menu
                        openVoteMenuEvent:FireServer()
                    end
                end
            end
        end
    end)
    
    print("ProximityPrompt connections established")
end

-- Make sure we can find the RemoteEvents folder
local function waitForNPCRemotes()
    local maxWaitTime = 10
    local startTime = tick()
    
    -- Keep trying until we find the folder or time out
    while not ReplicatedStorage:FindFirstChild("NPCRemotes") do
        if tick() - startTime > maxWaitTime then
            warn("Timed out waiting for NPCRemotes folder")
            return false
        end
        wait(0.5)
    end
    
    return true
end

-- Track current NPC events we're connected to
local connectedEvents = {}

-- Connect to each NPC's events as they're created
local function monitorNPCFolders()
    local NPCRemotes = ReplicatedStorage:WaitForChild("NPCRemotes")
    
    -- Function to set up connections for a specific NPC folder
    local function connectToNPCFolder(npcFolder)
        local npcId = npcFolder.Name
        
        -- Skip if already connected
        if connectedEvents[npcId] then
            return
        end
        
        -- Create a table to track this NPC's connections
        connectedEvents[npcId] = {
            openMenuConnection = nil,
            cooldownConnection = nil,
            ideaInfo = {
                title = "רעיון חדש למשחק", -- Default title
                description = "אנא הצביעו אם אתם אוהבים את הרעיון." -- Default description
            }
        }
        
        -- Get idea info if available
        local ideaInfoFolder = npcFolder:FindFirstChild("IdeaInfo")
        if ideaInfoFolder then
            if ideaInfoFolder:FindFirstChild("Title") then
                connectedEvents[npcId].ideaInfo.title = ideaInfoFolder.Title.Value
            end
            
            if ideaInfoFolder:FindFirstChild("Description") then
                connectedEvents[npcId].ideaInfo.description = ideaInfoFolder.Description.Value
            end
        end
        
        -- Connect to OpenVoteMenu event
        local openVoteMenuEvent = npcFolder:FindFirstChild("OpenVoteMenu")
        if openVoteMenuEvent then
            connectedEvents[npcId].openMenuConnection = openVoteMenuEvent.OnClientEvent:Connect(function(currentVote)
                print("Received vote menu open event from NPC", npcId, ", current vote:", currentVote)
                createVotingUI(npcId, currentVote, connectedEvents[npcId].ideaInfo)
            end)
        end
        
        -- Connect to VoteCooldown event
        local voteCooldownEvent = npcFolder:FindFirstChild("VoteCooldown")
        if voteCooldownEvent then
            connectedEvents[npcId].cooldownConnection = voteCooldownEvent.OnClientEvent:Connect(function(remainingTime)
                print("Received cooldown notification from NPC", npcId, ":", remainingTime, "seconds")
                createCooldownNotification(remainingTime)
            end)
        end
        
        print("Connected to NPC:", npcId)
    end
    
    -- Connect to each existing NPC folder
    for _, folder in pairs(NPCRemotes:GetChildren()) do
        if folder:IsA("Folder") and folder.Name ~= "IdeaInfo" then
            connectToNPCFolder(folder)
        end
    end
    
    -- Watch for new NPC folders being added
    NPCRemotes.ChildAdded:Connect(function(child)
        if child:IsA("Folder") and child.Name ~= "IdeaInfo" then
            print("New NPC folder detected:", child.Name)
            wait(0.1) -- Brief wait for all events to be created
            connectToNPCFolder(child)
        end
    end)
    
    print("NPC folder monitoring active")
end

-- Create a voting UI with current vote highlighted
local function createVotingUI(npcId, currentVote, ideaInfo)
    -- Remove any existing UI
    if playerGui:FindFirstChild("VotingUI") then
        playerGui.VotingUI:Destroy()
    end
    
    -- Create the main GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VotingUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Store NPC ID as an attribute
    screenGui:SetAttribute("NPCId", npcId)
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center position
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Anchor at center
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    -- Add gradient
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    uiGradient.Rotation = 45
    uiGradient.Parent = mainFrame
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = ideaInfo.title
    titleLabel.Parent = mainFrame
    
    -- Add description
    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "DescriptionLabel"
    descriptionLabel.Size = UDim2.new(0.9, 0, 0, 120)
    descriptionLabel.Position = UDim2.new(0.5, 0, 0, 70)
    descriptionLabel.AnchorPoint = Vector2.new(0.5, 0)
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.Font = Enum.Font.Gotham
    descriptionLabel.TextSize = 18
    descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descriptionLabel.Text = ideaInfo.description
    descriptionLabel.TextWrapped = true
    descriptionLabel.Parent = mainFrame
    
    -- Show current vote status if already voted
    if currentVote ~= nil then
        local voteStatusLabel = Instance.new("TextLabel")
        voteStatusLabel.Name = "VoteStatusLabel"
        voteStatusLabel.Size = UDim2.new(0.9, 0, 0, 30)
        voteStatusLabel.Position = UDim2.new(0.5, 0, 0, 190)
        voteStatusLabel.AnchorPoint = Vector2.new(0.5, 0)
        voteStatusLabel.BackgroundTransparency = 1
        voteStatusLabel.Font = Enum.Font.GothamBold
        voteStatusLabel.TextSize = 16
        voteStatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        voteStatusLabel.Text = "הצבעה נוכחית שלך: " .. (currentVote and "בעד הרעיון" or "לא בעד הרעיון")
        voteStatusLabel.Parent = mainFrame
    end
    
    -- Buttons container
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Name = "ButtonsContainer"
    buttonsContainer.Size = UDim2.new(0.9, 0, 0, 60)
    buttonsContainer.Position = UDim2.new(0.5, 0, 1, -80)
    buttonsContainer.AnchorPoint = Vector2.new(0.5, 0)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = mainFrame
    
    -- Button layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 20)
    layout.Parent = buttonsContainer
    
    -- Find the NPC's submit vote event
    local submitVoteEvent = nil
    if ReplicatedStorage:FindFirstChild("NPCRemotes") and 
       ReplicatedStorage.NPCRemotes:FindFirstChild(npcId) and
       ReplicatedStorage.NPCRemotes[npcId]:FindFirstChild("SubmitVote") then
        submitVoteEvent = ReplicatedStorage.NPCRemotes[npcId].SubmitVote
    else
        warn("Could not find SubmitVote event for NPC:", npcId)
    end
    
    -- Yes button (Like)
    local yesButton = Instance.new("TextButton")
    yesButton.Name = "YesButton"
    yesButton.Size = UDim2.new(0, 150, 0, 50)
    -- Highlight if this is the current vote
    if currentVote == true then
        yesButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60) -- Brighter green
        yesButton.BorderSizePixel = 2
        yesButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    else
        yesButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
    end
    yesButton.Font = Enum.Font.GothamBold
    yesButton.TextSize = 18
    yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesButton.Text = "אהבתי את הרעיון"
    yesButton.Parent = buttonsContainer
    
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 8)
    yesCorner.Parent = yesButton
    
    -- No button (Dislike)
    local noButton = Instance.new("TextButton")
    noButton.Name = "NoButton"
    noButton.Size = UDim2.new(0, 150, 0, 50)
    -- Highlight if this is the current vote
    if currentVote == false then
        noButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60) -- Brighter red
        noButton.BorderSizePixel = 2
        noButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    else
        noButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    end
    noButton.Font = Enum.Font.GothamBold
    noButton.TextSize = 18
    noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    noButton.Text = "לא אהבתי את הרעיון"
    noButton.Parent = buttonsContainer
    
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 8)
    noCorner.Parent = noButton
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -10, 0, 10)
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeButton
    
    -- Animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 300)
    })
    openTween:Play()
    
    -- Button handlers
    closeButton.MouseButton1Click:Connect(function()
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
    
    yesButton.MouseButton1Click:Connect(function()
        if submitVoteEvent then
            print("Voted: Liked on NPC", npcId)
            submitVoteEvent:FireServer(true)
            
            -- Confirm animation
            yesButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            wait(0.1)
            
            -- Close the menu
            local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            })
            closeTween:Play()
            closeTween.Completed:Connect(function()
                screenGui:Destroy()
            end)
        end
    end)
    
    noButton.MouseButton1Click:Connect(function()
        if submitVoteEvent then
            print("Voted: Disliked on NPC", npcId)
            submitVoteEvent:FireServer(false)
            
            -- Confirm animation
            noButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            wait(0.1)
            
            -- Close the menu
            local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            })
            closeTween:Play()
            closeTween.Completed:Connect(function()
                screenGui:Destroy()
            end)
        end
    end)
    
    return screenGui
end

-- Create cooldown notification - Wide format at top of screen
local function createCooldownNotification(remainingTime)
    if playerGui:FindFirstChild("CooldownNotification") then
        playerGui.CooldownNotification:Destroy()
    end
    
    -- Create notification GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CooldownNotification"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Create notification frame - Wide and at top
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationFrame"
    notifFrame.Size = UDim2.new(0, 500, 0, 40) -- Wide and short
    notifFrame.Position = UDim2.new(0.5, 0, 0, 40) -- Top center
    notifFrame.AnchorPoint = Vector2.new(0.5, 0) -- Anchor at top center
    notifFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui
    
    -- Add gradient
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 70))
    })
    uiGradient.Rotation = 45
    uiGradient.Parent = notifFrame
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notifFrame
    
    -- Add message - single line
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "MessageLabel"
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 16
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = "יש להמתין " .. remainingTime .. " שניות לפני שינוי הצבעה"
    textLabel.TextWrapped = false -- Single line
    textLabel.Parent = notifFrame
    
    -- Animate from top
    notifFrame.Position = UDim2.new(0.5, 0, 0, -50) -- Start off-screen
    local openTween = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 40)
    })
    openTween:Play()
    
    -- Auto close
    task.delay(3, function()
        local closeTween = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -50)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
    
    return screenGui
end

-- Main initialization
local function initialize()
    print("Initializing Multi-Idea Voting Client...")
    
    -- Wait for NPCRemotes folder
    if not waitForNPCRemotes() then
        warn("Failed to find NPCRemotes folder")
        return
    end
    
    -- Setup ProximityPrompt connections (for E key interaction)
    setupProximityPromptConnections()
    
    -- Monitor and connect to all NPC folders
    monitorNPCFolders()
    
    print("Multi-Idea voting client system ready")
end

-- Start the system
initialize()