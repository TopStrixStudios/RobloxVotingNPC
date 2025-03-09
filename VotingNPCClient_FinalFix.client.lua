-- FINAL FIXED CLIENT SCRIPT
-- Place this script in StarterPlayer/StarterPlayerScripts
-- Name it exactly "VotingNPCClient.client.lua"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("Final Fixed VotingNPCClient script starting...")

-- Make sure we can find the RemoteEvents
local function waitForRemotes()
    local maxWaitTime = 10
    local startTime = tick()
    
    -- Keep trying until we find the folder or time out
    while not ReplicatedStorage:FindFirstChild("NPCRemotes") do
        if tick() - startTime > maxWaitTime then
            warn("Timed out waiting for NPCRemotes folder")
            return nil
        end
        wait(0.5)
    end
    
    local NPCRemotes = ReplicatedStorage.NPCRemotes
    
    -- Wait for all required events
    local events = {}
    local requiredEvents = {"OpenVoteMenu", "SubmitVote", "VoteCooldown"}
    
    for _, eventName in ipairs(requiredEvents) do
        local event = NPCRemotes:FindFirstChild(eventName)
        if not event then
            local timeLeft = maxWaitTime - (tick() - startTime)
            if timeLeft <= 0 then
                warn("Timed out waiting for " .. eventName)
                return nil
            end
            
            -- Try to wait for it
            event = NPCRemotes:WaitForChild(eventName, timeLeft)
            if not event then
                warn("Could not find " .. eventName)
                return nil
            end
        end
        
        events[eventName] = event
    end
    
    return events
end

-- Create a voting UI with current vote highlighted
local function createVotingUI(currentVote)
    -- Remove any existing UI
    if playerGui:FindFirstChild("VotingUI") then
        playerGui.VotingUI:Destroy()
    end
    
    -- Create the main GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VotingUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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
    titleLabel.Text = "רעיון חדש למשחק"
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
    descriptionLabel.Text = "אנחנו שוקלים להוסיף מערכת משימות חדשה בגרסה הבאה של המשחק. המערכת תכלול משימות יומיות ושבועיות עם פרסים מיוחדים. האם אתם מעוניינים בתכונה זו?"
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
        print("Voted: Liked")
        ReplicatedStorage.NPCRemotes.SubmitVote:FireServer(true)
        
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
    end)
    
    noButton.MouseButton1Click:Connect(function()
        print("Voted: Disliked")
        ReplicatedStorage.NPCRemotes.SubmitVote:FireServer(false)
        
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
    end)
    
    return screenGui
end

-- Create cooldown notification
local function createCooldownNotification(remainingTime)
    if playerGui:FindFirstChild("CooldownNotification") then
        playerGui.CooldownNotification:Destroy()
    end
    
    -- Create notification GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CooldownNotification"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Create notification frame
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationFrame"
    notifFrame.Size = UDim2.new(0, 300, 0, 100)
    notifFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    notifFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notifFrame
    
    -- Add message
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "MessageLabel"
    textLabel.Size = UDim2.new(1, -20, 1, -20)
    textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = "יש להמתין " .. remainingTime .. " שניות\nלפני שינוי הצבעה"
    textLabel.TextWrapped = true
    textLabel.Parent = notifFrame
    
    -- Animate
    notifFrame.Size = UDim2.new(0, 0, 0, 0)
    local openTween = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, 100)
    })
    openTween:Play()
    
    -- Auto close
    task.delay(3, function()
        local closeTween = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
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
    print("Initializing Voting Client...")
    
    -- Wait for remote events
    local events = waitForRemotes()
    if not events then
        warn("Failed to find required remote events")
        return
    end
    
    print("Found all required RemoteEvents")
    
    -- Connect event handlers
    events.OpenVoteMenu.OnClientEvent:Connect(function(currentVote)
        print("Received vote menu open event, current vote:", currentVote)
        createVotingUI(currentVote)
    end)
    
    events.VoteCooldown.OnClientEvent:Connect(function(remainingTime)
        print("Received cooldown notification: " .. remainingTime .. " seconds")
        createCooldownNotification(remainingTime)
    end)
    
    print("Voting client system ready")
end

-- Start the system
initialize()