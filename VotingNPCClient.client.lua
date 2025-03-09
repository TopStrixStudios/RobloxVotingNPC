local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("VotingNPCClient script started!")

-- Create voting UI
local function createVotingUI()
    print("Creating voting UI")
    -- Check if UI already exists
    if playerGui:FindFirstChild("VotingUI") then
        playerGui.VotingUI:Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VotingUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Create main frame
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
    
    -- Create vote buttons container
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Name = "ButtonsContainer"
    buttonsContainer.Size = UDim2.new(0.9, 0, 0, 60)
    buttonsContainer.Position = UDim2.new(0.5, 0, 1, -80)
    buttonsContainer.AnchorPoint = Vector2.new(0.5, 0)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = mainFrame
    
    -- Add layout for buttons
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 20)
    layout.Parent = buttonsContainer
    
    -- Create vote yes button
    local voteYesButton = Instance.new("TextButton")
    voteYesButton.Name = "VoteYesButton"
    voteYesButton.Size = UDim2.new(0, 150, 0, 50)
    voteYesButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
    voteYesButton.Font = Enum.Font.GothamBold
    voteYesButton.TextSize = 18
    voteYesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    voteYesButton.Text = "אהבתי את הרעיון"
    voteYesButton.Parent = buttonsContainer
    
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 8)
    yesCorner.Parent = voteYesButton
    
    -- Create vote no button
    local voteNoButton = Instance.new("TextButton")
    voteNoButton.Name = "VoteNoButton"
    voteNoButton.Size = UDim2.new(0, 150, 0, 50)
    voteNoButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    voteNoButton.Font = Enum.Font.GothamBold
    voteNoButton.TextSize = 18
    voteNoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    voteNoButton.Text = "לא אהבתי את הרעיון"
    voteNoButton.Parent = buttonsContainer
    
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 8)
    noCorner.Parent = voteNoButton
    
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
    
    -- Animate opening
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 300)
    })
    openTween:Play()
    
    -- Button Events
    closeButton.MouseButton1Click:Connect(function()
        print("Close button clicked")
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
    
    voteYesButton.MouseButton1Click:Connect(function()
        print("Voted: Liked")
        ReplicatedStorage.NPCRemotes.SubmitVote:FireServer(true)
        closeButton.MouseButton1Click:Fire()
    end)
    
    voteNoButton.MouseButton1Click:Connect(function()
        print("Voted: Disliked")
        ReplicatedStorage.NPCRemotes.SubmitVote:FireServer(false)
        closeButton.MouseButton1Click:Fire()
    end)
    
    return screenGui
end

-- Create already voted notification
local function createAlreadyVotedNotification()
    print("Creating already voted notification")
    -- Check if notification already exists
    if playerGui:FindFirstChild("VotedNotification") then
        playerGui.VotedNotification:Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VotedNotification"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Create notification frame
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationFrame"
    notifFrame.Size = UDim2.new(0, 300, 0, 100)
    notifFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    notifFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    notifFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui
    
    -- Add gradient
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    uiGradient.Rotation = 45
    uiGradient.Parent = notifFrame
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notifFrame
    
    -- Add text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "MessageLabel"
    textLabel.Size = UDim2.new(1, -20, 1, -20)
    textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = "כבר הצבעת על הרעיון הזה"
    textLabel.TextWrapped = true
    textLabel.Parent = notifFrame
    
    -- Animate
    notifFrame.Size = UDim2.new(0, 0, 0, 0)
    local openTween = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, 100)
    })
    openTween:Play()
    
    -- Auto close after 3 seconds
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

-- Connect to the RemoteEvent
spawn(function()
    while not ReplicatedStorage:FindFirstChild("NPCRemotes") do
        print("Waiting for NPCRemotes folder...")
        wait(1)
    end
    
    print("Found NPCRemotes folder")
    
    local openVoteMenu = ReplicatedStorage.NPCRemotes:WaitForChild("OpenVoteMenu")
    
    openVoteMenu.OnClientEvent:Connect(function(alreadyVoted)
        print("Received menu open event: " .. tostring(alreadyVoted))
        if alreadyVoted then
            createAlreadyVotedNotification()
        else
            createVotingUI()
        end
    end)
    
    print("Successfully connected to OpenVoteMenu event")
end)

print("VotingNPCClient initialization complete")