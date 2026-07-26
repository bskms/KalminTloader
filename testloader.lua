local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ========================================== --
-- //          CONFIGURATION               // --
-- ========================================== --
local Config = {
    -- List of Game PlaceIds that are strictly forbidden.
    Blacklist = {
        0000000001,
    },
    
    -- Status configuration: "Up" or "Down"
    Status = "Up", 
    DowntimeReason = "Script is currently undergoing maintenance to bypass new anti-cheats. Check Discord(.gg/DdjVT2aMwx)",
    
    -- The script to execute when all checks pass
    TargetScript = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/API-AyGent/KalminKeySystem/refs/heads/main/Kalmin.lua"))()]],
    
    -- Visual timings (Seconds)
    CheckDelay = 1.2, -- How long it fakes "checking" per step for the visual effect
    FadeTime = 0.5
}

-- ========================================== --
-- //           UI GENERATION              // --
-- ========================================== --

local function GetSecureParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        if syn and syn.protect_gui then
            local gui = Instance.new("ScreenGui")
            syn.protect_gui(gui)
            gui.Parent = CoreGui
            return gui
        end
        return CoreGui
    end)
    return success and parent or Players.LocalPlayer:WaitForChild("PlayerGui")
end

local TargetParent = GetSecureParent()
for _, child in ipairs(TargetParent:GetChildren()) do
    if child.Name == "KalminTerminalLoader" then child:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KalminTerminalLoader"
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = TargetParent

-- // Main Background \\
local MainFrame = Instance.new("CanvasGroup")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 220)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.GroupTransparency = 1 -- Starts hidden
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 6)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(50, 50, 50)
MainStroke.Thickness = 1
MainStroke.Transparency = 1
MainStroke.Parent = MainFrame

-- // Top Bar \\
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Icon = Instance.new("ImageLabel")
Icon.Size = UDim2.new(0, 18, 0, 18)
Icon.Position = UDim2.new(0, 10, 0.5, 0)
Icon.AnchorPoint = Vector2.new(0, 0.5)
Icon.BackgroundTransparency = 1
Icon.Image = "rbxassetid://126925031200401"
Icon.ImageColor3 = Color3.fromRGB(150, 150, 150)
Icon.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 35, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Kalmin Loader"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- // Lines Container \\
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -30, 1, -70)
ContentFrame.Position = UDim2.new(0, 15, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = ContentFrame

-- Creates the retro text lines
local Lines = {}
local function CreateLine(layoutOrder)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = ""
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.Arcade -- Gives that exact blocky pixel font from the screenshot
    lbl.TextSize = 18
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.RichText = true
    lbl.LayoutOrder = layoutOrder
    lbl.Parent = ContentFrame
    table.insert(Lines, lbl)
    return lbl
end

local LineBlacklist = CreateLine(1)
local LineStatus = CreateLine(2)
local LineExecutor = CreateLine(3)
local LineLoading = CreateLine(4)

-- // Progress Bar \\
local ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Size = UDim2.new(1, 0, 0, 20)
ProgressLabel.Position = UDim2.new(0, 0, 1, -25)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "0% -[____________________]-"
ProgressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressLabel.Font = Enum.Font.Arcade
ProgressLabel.TextSize = 16
ProgressLabel.Parent = MainFrame

-- ========================================== --
-- //             LOGIC ENGINE             // --
-- ========================================== --

local Colors = {
    Red = "rgb(255, 50, 50)",
    Green = "rgb(50, 255, 50)",
    Blue = "rgb(50, 150, 255)"
}

-- Progress Bar Logic
local ProgressValue = Instance.new("NumberValue")
ProgressValue.Value = 0

local ProgressBarConnection = ProgressValue.Changed:Connect(function(val)
    local percent = math.floor(val)
    local barLength = 20
    local filled = math.floor((percent / 100) * barLength)
    local empty = barLength - filled
    
    local fillStr = string.rep("#", filled)
    local emptyStr = string.rep("_", empty)
    
    ProgressLabel.Text = string.format("%d%% -[%s%s]-", percent, fillStr, emptyStr)
    
    if percent >= 100 then
        ProgressLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    end
end)

local function SetProgress(targetVal)
    TweenService:Create(ProgressValue, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = targetVal}):Play()
end

-- Helper to find the executor name
local function GetExecutorName()
    if identifyexecutor then return identifyexecutor() end
    if KRNL_LOADED then return "Krnl" end
    if syn then return "Synapse" end
    return "Unknown Exec"
end

-- Asynchronous checking animation engine
local function RunCheck(label, baseText, checkRoutine)
    local isChecking = true
    local dots = 0
    
    -- Dot animation thread
    local dotTask = task.spawn(function()
        while isChecking do
            label.Text = baseText .. string.rep(".", dots)
            dots = (dots + 1) % 4
            task.wait(0.35)
        end
    end)
    
    -- Run the actual check (yields)
    local resultText, resultColor, returnFlag = checkRoutine()
    
    -- Stop animation and finalize text
    isChecking = false
    task.cancel(dotTask)
    
    label.Text = baseText .. "... <font color='" .. resultColor .. "'>[" .. resultText .. "]</font>"
    return returnFlag
end

-- ========================================== --
-- //            MAIN ROUTINE              // --
-- ========================================== --

task.spawn(function()
    -- 1. Fade In UI
    TweenService:Create(MainFrame, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
    TweenService:Create(MainStroke, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}):Play()
    task.wait(Config.FadeTime + 0.5)

    -- 2. Check Blacklist
    local isSafe = RunCheck(LineBlacklist, "Checking Blacklist", function()
        task.wait(Config.CheckDelay)
        if table.find(Config.Blacklist, game.PlaceId) then
            return "Skipped", Colors.Green, false
        end
        return "Skipped", Colors.Green, true
    end)

    if not isSafe then
        task.wait(1.5)
        Players.LocalPlayer:Kick("Kalmin Security: This game is globally blacklisted due to highly aggressive Anti-Cheats.")
        return
    end
    SetProgress(34)

    -- 3. Check Status
    local statusUp = RunCheck(LineStatus, "Checking Status", function()
        task.wait(Config.CheckDelay)
        if string.lower(Config.Status) == "down" then
            return "Down", Colors.Red, false
        end
        return "Up", Colors.Green, true
    end)

    if not statusUp then
        task.wait(1.5)
        Players.LocalPlayer:Kick("Kalmin Status [OFFLINE]:\n\n" .. Config.DowntimeReason)
        return
    end
    SetProgress(68)

    -- 4. Check Executor
    RunCheck(LineExecutor, "Checking Executor", function()
        task.wait(Config.CheckDelay)
        local execName = GetExecutorName()
        return execName, Colors.Green, true
    end)
    SetProgress(85)

    -- 5. Final Loading & Execution
    RunCheck(LineLoading, "Loading", function()
        SetProgress(100)
        task.wait(1.5) -- Wait for progress bar to hit 100%
        
        -- Safely Execute Target Script
        local success, err = pcall(function()
            local func = loadstring(Config.TargetScript)
            if func then func() else warn("Kalmin: Failed to compile loadstring.") end
        end)
        
        if not success then warn("Kalmin Execution Error:", err) end
        
        return "Done", Colors.Green, true
    end)

    -- 6. Outro Fade & Cleanup
    task.wait(0.1)
    local fadeOut = TweenService:Create(MainFrame, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1, Size = UDim2.new(0, 440, 0, 230)})
    TweenService:Create(MainStroke, TweenInfo.new(Config.FadeTime), {Transparency = 1}):Play()
    fadeOut:Play()
    
    fadeOut.Completed:Wait()
    ProgressBarConnection:Disconnect()
    ScreenGui:Destroy()
end)
