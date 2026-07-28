local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    GuiService = game:GetService("GuiService"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    VirtualUser = game:GetService("VirtualUser"),
    HttpService = game:GetService("HttpService"),
    CoreGui = game:GetService("CoreGui")
}

local Player = Services.Players.LocalPlayer
local Global = type(getgenv) == "function" and getgenv() or _G

if type(Global.__BoogaUtilityStop) == "function" then
    pcall(Global.__BoogaUtilityStop)
    Global.__BoogaUtilityStop = nil
end

pcall(function()
    if type(getgc) ~= "function" then return end
    for _, candidate in ipairs(getgc(true)) do
        if type(candidate) == "table"
            and candidate.running == true
            and type(candidate.pathFolderName) == "string"
            and string.find(candidate.pathFolderName, "BoogaUtilityPath_", 1, true) == 1 then
            candidate.running = false
            if candidate.motionTween then pcall(function() candidate.motionTween:Cancel() end) end
            if candidate.freezeConnection then pcall(function() candidate.freezeConnection:Disconnect() end) end
            if candidate.pathFolder then pcall(function() candidate.pathFolder:Destroy() end) end
            for _, connection in ipairs(candidate.connections or {}) do
                pcall(function() connection:Disconnect() end)
            end
        end
    end
end)

pcall(function()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
end)

local Runtime = {
    running = true,
    startedAt = os.time(),
    connections = {},
    disabledIdleConnections = {},
    motionTween = nil,
    motionOwner = nil,
    motionTargetPosition = nil,
    pathIndex = nil,
    pathReached = false,
    pathWaitUntil = 0,
    pathControlledRoot = nil,
    pathHumanoid = nil,
    pathControls = nil,
    pathAnimate = nil,
    pathOriginalAnimateDisabled = nil,
    pathIdleTrack = nil,
    pathIdleAnimation = nil,
    pathRotation = nil,
    pathAttachment = nil,
    pathVelocity = nil,
    pathOrientation = nil,
    pathObstacleLiftUntil = 0,
    pathObstacleLiftSpeed = 0,
    pathGroundPullActive = false,
    pathFolder = nil,
    pathSelectedDot = nil,
    pathSelectedSource = nil,
    pathSelectedKey = nil,
    pathHandleStart = nil,
    pathAddClickMode = false,
    pathRestartCount = 0,
    antiCheckpoint = nil,
    antiCheckpointAt = 0,
    currentSlot = 1,
    nextFreezeAt = 0,
    freezeConnection = nil,
    selectedChest = nil,
    selectedChestHighlight = nil,
    listeningForChest = false,
    chestRestoreToken = 0,
    autoOpenChestFired = false,
    pathSlotOneEquipped = false,
    pathSlotCharacter = nil,
    pathSlotReadyAt = 0,
    pathTargetPosition = nil,
    pathWrongDirectionSince = 0,
    coinTweenActive = false,
    coinTweenStarted = false,
    coinSpawnInvoked = false,
    coinTweenToken = 0,
    spawnAttempted = false,
    spawnCompleted = false,
    spawnInitialCharacter = nil,
    nextSpawnAt = 0,
    goldMovers = {},
    goldLastPositions = {},
    goldLastDistances = {},
    goldLastProgressAt = {},
    goldReleaseUntil = {},
    goldMoverLastRecoveryAt = 0,
    deleting = {},
    campfireRefillInFlight = {},
    lastEat = 0,
    lastBloodfruitEat = 0,
    modalToken = 0,
    mainAnimationToken = 0,
    pageTween = nil,
    bindingKey = false,
    selector = nil,
    confirmCallback = nil,
    pageAnimationToken = 0,
    ultraLowToken = 0,
    ultraLowConnections = {},
    ultraLowOriginals = setmetatable({}, {__mode = "k"}),
    ultraLowQualityState = nil
}
Runtime.pathSpeed = 19
Runtime.pathHoverOffset = 0.1
Runtime.autoEatThreshold = 67

local UI = {
    Pages = {},
    Tabs = {},
    Toggles = {},
    Sliders = {},
    Dropdowns = {},
    Inputs = {},
    Watcher = {},
    ActiveTweens = {},
    Strokes = {},
    mainShown = true
}

local Colors = {
    Background = Color3.fromRGB(25, 25, 25),
    Header = Color3.fromRGB(25, 25, 25),
    Panel = Color3.fromRGB(30, 30, 31),
    Control = Color3.fromRGB(37, 37, 37),
    ControlHover = Color3.fromRGB(42, 42, 42),
    Stroke = Color3.fromRGB(55, 55, 55),
    Accent = Color3.fromRGB(212, 212, 212),
    EnabledText = Color3.fromRGB(0, 0, 0),
    Text = Color3.fromRGB(198, 198, 201),
    Muted = Color3.fromRGB(140, 140, 140),
    Black = Color3.fromRGB(0, 0, 0)
}

local Packets, ItemIDS, GameUtil
pcall(function()
    Packets = require(Services.ReplicatedStorage.Modules.Packets)
    ItemIDS = require(Services.ReplicatedStorage.Modules.ItemIDS)
end)
pcall(function()
    GameUtil = require(Services.ReplicatedStorage.Modules.GameUtil)
end)

local ByteNetReliable = Services.ReplicatedStorage:WaitForChild("ByteNetReliable")

local FruitIDs = {
    Bloodfruit = 94,
    Bluefruit = 377,
    Lemon = 99,
    Coconut = 1,
    Jelly = 604,
    Banana = 606,
    Orange = 602,
    Oddberry = 32,
    Berry = 35,
    Strangefruit = 302,
    Strawberry = 282,
    Sunfruit = 128,
    Pumpkin = 80,
    ["Prickly Pear"] = 378,
    Apple = 243,
    Barley = 247,
    Cloudberry = 101,
    Carrot = 147
}

local Defaults = {
    startPath = false,
    showPath = false,
    autoSelectChest = false,
    pauseNearPress = false,
    goldHitAura = false,
    switchSlots = false,
    pickupChestGold = false,
    coinPress = false,
    pickCoins = false,

    autoFarm = false,
    autoEat = false,
    sfAutoMove = false,
    dropUntil = false,
    deleteMaterials = false,
    pickupItem = false,
    refillCampfire = false,
    bfMasterFarm = false,
    bfAutoMove = false,
    bfAutoHarvest = false,
    bfAutoPlant = false,
    bfAutoEat = false,

    cpuMode = false,
    lowEnd = false,
    ultraLow = false,
    lockCamera = false,
    autoOpenChest = false,
    tweenToCoins = false,
    antiStuck = true,
    walkSpeedEnabled = false,

    moveSpeed = 19,

    hideKey = "B",
    configName = "default",
    loadConfig = "",
    deleteConfig = "",
    autoloadEnabled = false,
    autoloadConfig = "",
    selectedChestName = "",
    selectedChestPosition = {},
    pathEdits = {},
    pathAddedPoints = {},
    pathProfileName = "built-in",
    pathEditingMode = false
}

local State = {}
for key, value in pairs(Defaults) do
    State[key] = type(value) == "table" and table.clone(value) or value
end

Runtime.configRoot = "BoogaUtilityScript"
Runtime.configFolder = Runtime.configRoot .. "/configs"
Runtime.autoloadFile = Runtime.configRoot .. "/autoload.json"
Runtime.pathConfigFolder = Runtime.configRoot .. "/paths"
Runtime.pathDefaultFile = Runtime.configRoot .. "/default_path.json"
Runtime.fsAvailable = type(writefile) == "function"
    and type(readfile) == "function"
    and type(makefolder) == "function"
    and type(isfile) == "function"

function Runtime.EnsureFolders()
    if not Runtime.fsAvailable then return false end
    pcall(function() makefolder(Runtime.configRoot) end)
    pcall(function() makefolder(Runtime.configFolder) end)
    pcall(function() makefolder(Runtime.pathConfigFolder) end)
    pcall(function()
        local builtInPath = Runtime.pathConfigFolder .. "/built-in.json"
        if not isfile(builtInPath) then
            writefile(builtInPath, Services.HttpService:JSONEncode({pathEdits = {}, pathAddedPoints = {}}))
        end
        if not isfile(Runtime.pathDefaultFile) then
            writefile(Runtime.pathDefaultFile, Services.HttpService:JSONEncode({name = "built-in"}))
        end
    end)
    return true
end

function Runtime.SafeConfigName(name)
    local clean = tostring(name or ""):gsub("[^%w%-%_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" then clean = "default" end
    return string.sub(clean, 1, 48)
end

function Runtime.ConfigPath(name)
    return Runtime.configFolder .. "/" .. Runtime.SafeConfigName(name) .. ".json"
end

function Runtime.ReadConfigData(name)
    if not Runtime.fsAvailable then return nil end
    local path = Runtime.ConfigPath(name)
    local ok, result = pcall(function()
        if not isfile(path) then return nil end
        return Services.HttpService:JSONDecode(readfile(path))
    end)
    return ok and type(result) == "table" and result or nil
end

function Runtime.WriteAutoload()
    if not Runtime.EnsureFolders() then return end
    pcall(function()
        writefile(Runtime.autoloadFile, Services.HttpService:JSONEncode({
            enabled = State.autoloadEnabled,
            name = State.autoloadConfig
        }))
    end)
end

Runtime.EnsureFolders()
pcall(function()
    if isfile(Runtime.autoloadFile) then
        local marker = Services.HttpService:JSONDecode(readfile(Runtime.autoloadFile))
        if type(marker) == "table" then
            local markerName = tostring(marker.name or "")
            State.autoloadEnabled = marker.enabled == true
            State.autoloadConfig = markerName ~= "" and Runtime.SafeConfigName(markerName) or ""
            if State.autoloadEnabled and State.autoloadConfig ~= "" then
                local data = Runtime.ReadConfigData(State.autoloadConfig)
                if data then
                    for key, defaultValue in pairs(Defaults) do
                        local pathState = key == "pathEdits" or key == "pathAddedPoints"
                            or key == "pathProfileName" or key == "pathEditingMode"
                        if not pathState and data[key] ~= nil and type(data[key]) == type(defaultValue) then
                            State[key] = data[key]
                        end
                    end
                    if data.selectedChestEntityId ~= nil then
                        State.selectedChestEntityId = data.selectedChestEntityId
                    end
                    State.configName = State.autoloadConfig
                end
            end
            State.autoloadEnabled = marker.enabled == true
            State.autoloadConfig = markerName ~= "" and Runtime.SafeConfigName(markerName) or ""
        end
    end
end)

Runtime.itemAliases = {
    Leaves = {"Leaves", "Leaf"},
    Log = {"Log", "Logs"},
    Sunfruit = {"Sunfruit", "Sun Fruit"},
    ["Gold Bar"] = {"Gold Bar", "Gold", "Gold_Bar"}
}

for _, guiName in ipairs({"BoogaGoldUI", "BoogaUtilityUI", "BoogaGoldUnfocusBlack"}) do
    local oldGui = Services.CoreGui:FindFirstChild(guiName)
    if oldGui then oldGui:Destroy() end
    local playerGui = Player:FindFirstChild("PlayerGui")
    oldGui = playerGui and playerGui:FindFirstChild(guiName)
    if oldGui then oldGui:Destroy() end
end

function UI.Round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 7)
    corner.Parent = object
    return corner
end

function UI.Stroke(object, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Stroke
    stroke.Transparency = transparency or 0.35
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = object
    stroke:SetAttribute("BoogaBaseTransparency", stroke.Transparency)
    table.insert(UI.Strokes, stroke)
    return stroke
end

function UI.Tween(object, duration, properties, style, direction)
    local active = UI.ActiveTweens[object]
    if active then active:Cancel() end
    local tween = Services.TweenService:Create(
        object,
        TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        properties
    )
    UI.ActiveTweens[object] = tween
    tween.Completed:Connect(function()
        if UI.ActiveTweens[object] == tween then UI.ActiveTweens[object] = nil end
    end)
    tween:Play()
    return tween
end

function UI.TweenStrokes(visible, duration, ancestor)
    for index = #UI.Strokes, 1, -1 do
        local stroke = UI.Strokes[index]
        if not stroke or not stroke.Parent then
            table.remove(UI.Strokes, index)
        elseif not ancestor or stroke:IsDescendantOf(ancestor) then
            local transparency = stroke:GetAttribute("BoogaBaseTransparency")
            if type(transparency) ~= "number" then transparency = 0.35 end
            local target = visible and transparency or 1
            if duration and duration <= 0 then
                local active = UI.ActiveTweens[stroke]
                if active then active:Cancel() end
                UI.ActiveTweens[stroke] = nil
                stroke.Transparency = target
            else
                UI.Tween(stroke, duration or 0.18, {Transparency = target})
            end
        end
    end
end

function UI.MakeLabel(parent, text, height)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, height or 28)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

function UI.MakeButton(parent, text)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 30)
    button.BackgroundColor3 = Colors.Control
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = text
    button.TextColor3 = Colors.Text
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 11
    button.TextStrokeTransparency = 1
    button.Parent = parent
    UI.Round(button, 7)
    UI.Stroke(button, 0.45)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button
    button:SetAttribute("BoogaSelected", false)
    button.MouseEnter:Connect(function()
        button:SetAttribute("BoogaHovered", true)
        if button:GetAttribute("BoogaSelected") ~= true then
            UI.Tween(button, 0.16, {BackgroundColor3 = Colors.ControlHover})
        end
    end)
    button.MouseLeave:Connect(function()
        button:SetAttribute("BoogaHovered", false)
        UI.Tween(scale, 0.18, {Scale = 1})
        if button:GetAttribute("BoogaSelected") ~= true then
            UI.Tween(button, 0.18, {BackgroundColor3 = Colors.Control})
        end
    end)
    button.MouseButton1Down:Connect(function()
        UI.Tween(scale, 0.09, {Scale = 0.975}, Enum.EasingStyle.Quad)
    end)
    button.MouseButton1Up:Connect(function()
        UI.Tween(scale, 0.2, {Scale = 1}, Enum.EasingStyle.Quint)
    end)
    return button
end

function Runtime.SetToggle(key, value)
    State[key] = value == true
    if UI.Refresh then UI.Refresh() end
    if Runtime.OnToggle then Runtime.OnToggle(key, State[key]) end
end

function UI.MakeToggle(parent, key, label, confirmMessage)
    local button = UI.MakeButton(parent, label .. ": OFF")
    UI.Toggles[key] = {button = button, label = label}
    button.MouseButton1Click:Connect(function()
        if confirmMessage and not State[key] then
            UI.AskConfirm(confirmMessage, function() Runtime.SetToggle(key, true) end)
        else
            Runtime.SetToggle(key, not State[key])
        end
    end)
    return button
end

function UI.MakeToggleWithSettings(parent, key, label, settingsCallback, iconText)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 30)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local button = UI.MakeButton(holder, label .. ": OFF")
    button.Size = UDim2.new(1, -35, 1, 0)
    button.Position = UDim2.fromOffset(0, 0)
    UI.Toggles[key] = {button = button, label = label}
    button.MouseButton1Click:Connect(function()
        Runtime.SetToggle(key, not State[key])
    end)

    local settings = UI.MakeButton(holder, iconText or "⚙")
    settings.Size = UDim2.fromOffset(30, 30)
    settings.Position = UDim2.new(1, -30, 0, 0)
    settings.TextSize = 14
    settings.MouseButton1Click:Connect(settingsCallback)
    return holder, button, settings
end

function UI.MakeSlider(parent, key, label, minimum, maximum, step, suffix)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 42)
    holder.BackgroundColor3 = Colors.Panel
    holder.BorderSizePixel = 0
    holder.Parent = parent
    UI.Round(holder, 7)
    UI.Stroke(holder, 0.5)

    local labelObject = UI.MakeLabel(holder, label, 22)
    labelObject.Position = UDim2.new(0, 9, 0, 1)
    labelObject.Size = UDim2.new(1, -18, 0, 21)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -18, 0, 5)
    bar.Position = UDim2.new(0, 9, 1, -12)
    bar.BackgroundColor3 = Colors.Control
    bar.BorderSizePixel = 0
    bar.Parent = holder
    UI.Round(bar, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    UI.Round(fill, 4)

    local slider = {holder = holder, label = labelObject, bar = bar, fill = fill}
    UI.Sliders[key] = slider

    function slider:SetValue(value, updateState)
        value = math.clamp(tonumber(value) or minimum, minimum, maximum)
        value = math.floor((value / step) + 0.5) * step
        if step >= 1 then value = math.floor(value + 0.5) end
        if updateState ~= false then State[key] = value end
        local alpha = (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.fromScale(alpha, 1)
        local shown = step < 1 and string.format("%.2f", value) or tostring(value)
        labelObject.Text = label .. ": " .. shown .. (suffix or "")
    end

    local dragging = false
    local function updateFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        slider:SetValue(minimum + (maximum - minimum) * alpha, true)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(Runtime.connections, Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end))
    slider:SetValue(State[key], false)
    return holder
end

function UI.DropdownText(key, multi)
    local value = State[key]
    if multi then
        local count = 0
        for _, selected in pairs(value or {}) do
            if selected then count = count + 1 end
        end
        return count == 0 and "None selected" or tostring(count) .. " item" .. (count == 1 and "" or "s") .. " selected"
    end
    return (value == nil or value == "") and "Select" or tostring(value)
end

function UI.MakeDropdown(parent, key, label, valuesProvider, multi)
    local button = UI.MakeButton(parent, label .. ": " .. UI.DropdownText(key, multi))
    UI.Dropdowns[key] = {
        button = button,
        label = label,
        valuesProvider = valuesProvider,
        multi = multi
    }
    button.MouseButton1Click:Connect(function()
        UI.OpenSelector(key, label, valuesProvider(), multi)
    end)
    return button
end

function UI.MakeInput(parent, key, label, numeric, allowNegative)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 42)
    holder.BackgroundColor3 = Colors.Panel
    holder.BorderSizePixel = 0
    holder.Parent = parent
    UI.Round(holder, 7)
    UI.Stroke(holder, 0.5)

    local labelObject = UI.MakeLabel(holder, label, 18)
    labelObject.Position = UDim2.new(0, 9, 0, 2)
    labelObject.Size = UDim2.new(1, -18, 0, 18)
    labelObject.TextColor3 = Colors.Muted

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -18, 0, 19)
    box.Position = UDim2.new(0, 9, 0, 20)
    box.BackgroundTransparency = 1
    box.ClearTextOnFocus = false
    box.Text = tostring(State[key] or "")
    box.TextColor3 = Colors.Text
    box.PlaceholderColor3 = Colors.Muted
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = holder
    UI.Inputs[key] = box
    box.FocusLost:Connect(function()
        if numeric then
            local value = tonumber(box.Text) or tonumber(State[key]) or 0
            if not allowNegative then value = math.max(0, math.floor(value)) end
            State[key] = value
            box.Text = tostring(value)
        else
            State[key] = box.Text
        end
    end)
    return holder
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BoogaUtilityUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 100
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local parented = pcall(function()
    ScreenGui.Parent = gethui and gethui() or Services.CoreGui
end)
if not parented then ScreenGui.Parent = Player:WaitForChild("PlayerGui") end
UI.ScreenGui = ScreenGui

local Main = Instance.new("CanvasGroup")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(620, 360)
Main.Position = UDim2.new(0.5, -310, 0.5, -180)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.GroupTransparency = 1
Main.ZIndex = 2
Main.Parent = ScreenGui
UI.Round(Main, 12)
UI.Stroke(Main, 0.15)
UI.MainScale = Instance.new("UIScale")
UI.MainScale.Scale = 0.97
UI.MainScale.Parent = Main
UI.Main = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Colors.Header
Header.BorderSizePixel = 0
Header.Parent = Main
UI.Round(Header, 12)

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Colors.Header
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = UI.MakeLabel(Header, "booga utility script", 24)
Title.Position = UDim2.fromOffset(15, 5)
Title.Size = UDim2.new(1, -260, 0, 24)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15

local Subtitle = UI.MakeLabel(Header, "toolkit by okdude42 :)", 16)
Subtitle.Position = UDim2.fromOffset(15, 28)
Subtitle.Size = UDim2.new(1, -260, 0, 16)
Subtitle.TextColor3 = Colors.Accent
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 12

local TopNav = Instance.new("Frame")
TopNav.Size = UDim2.new(1, -24, 0, 32)
TopNav.Position = UDim2.fromOffset(12, 60)
TopNav.BackgroundTransparency = 1
TopNav.Parent = Main

function UI.MakePage(name)
    local page = Instance.new("CanvasGroup")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -24, 1, -112)
    page.Position = UDim2.fromOffset(12, 100)
    page.BackgroundTransparency = 1
    page.GroupTransparency = 1
    page.Visible = false
    page.Parent = Main
    UI.Pages[name] = page
    return page
end

for _, name in ipairs({"Gold", "Materials", "Utility", "Watcher", "Path", "Settings", "Configs"}) do
    UI.MakePage(name)
end

function UI.ShowPage(name)
    if not UI.Pages[name] then return end
    Runtime.pageAnimationToken = Runtime.pageAnimationToken + 1
    local token = Runtime.pageAnimationToken
    UI.currentPage = name
    for pageName, page in pairs(UI.Pages) do
        local selected = pageName == name
        if selected then
            page.Visible = true
            page.GroupTransparency = 1
            page.Position = UDim2.fromOffset(18, 100)
            UI.Tween(page, 0.24, {
                GroupTransparency = 0,
                Position = UDim2.fromOffset(12, 100)
            }, Enum.EasingStyle.Quint)
        elseif page.Visible then
            UI.Tween(page, 0.15, {
                GroupTransparency = 1,
                Position = UDim2.fromOffset(7, 100)
            }, Enum.EasingStyle.Quint)
            task.delay(0.15, function()
                if Runtime.pageAnimationToken == token and UI.currentPage ~= pageName then
                    page.Visible = false
                elseif UI.currentPage ~= pageName then
                    page.Visible = false
                end
            end)
        end
    end
    for tabName, button in pairs(UI.Tabs) do
        local selected = tabName == name
        button:SetAttribute("BoogaSelected", selected)
        UI.Tween(button, 0.2, {
            BackgroundColor3 = selected and Colors.Accent or Colors.Control,
            TextColor3 = selected and Colors.EnabledText or Colors.Text
        })
        if tabName == "Configs" and UI.SaveOutline then
            local glyphColor = selected and Colors.EnabledText or Colors.Muted
            UI.Tween(UI.SaveOutline, 0.2, {Color = glyphColor})
            UI.Tween(UI.SaveTop, 0.2, {BackgroundColor3 = glyphColor})
            UI.Tween(UI.SaveBottom, 0.2, {BackgroundColor3 = glyphColor})
        end
    end
end

for index, name in ipairs({"Gold", "Materials", "Utility", "Watcher"}) do
    local button = UI.MakeButton(TopNav, name)
    button.Size = UDim2.new(0.25, -5, 1, 0)
    button.Position = UDim2.new((index - 1) * 0.25, index == 1 and 0 or 2, 0, 0)
    UI.Tabs[name] = button
    button.MouseButton1Click:Connect(function() UI.ShowPage(name) end)
end

UI.SettingsIcon = UI.MakeButton(Header, "Settings")
UI.SettingsIcon.Name = "SettingsIcon"
UI.SettingsIcon.Size = UDim2.fromOffset(70, 30)
UI.SettingsIcon.Position = UDim2.new(1, -110, 0, 11)
UI.SettingsIcon.TextSize = 11
UI.SettingsIcon.Font = Enum.Font.GothamMedium
UI.SettingsIcon.ZIndex = 3
UI.Tabs.Settings = UI.SettingsIcon
UI.SettingsIcon.MouseButton1Click:Connect(function() UI.ShowPage("Settings") end)

UI.PathIcon = UI.MakeButton(Header, "Path")
UI.PathIcon.Name = "PathIcon"
UI.PathIcon.Size = UDim2.fromOffset(70, 30)
UI.PathIcon.Position = UDim2.new(1, -185, 0, 11)
UI.PathIcon.TextSize = 11
UI.PathIcon.Font = Enum.Font.GothamMedium
UI.PathIcon.ZIndex = 3
UI.Tabs.Path = UI.PathIcon
UI.PathIcon.MouseButton1Click:Connect(function() UI.ShowPage("Path") end)

UI.ConfigsIcon = UI.MakeButton(Header, "")
UI.ConfigsIcon.Name = "ConfigsIcon"
UI.ConfigsIcon.Size = UDim2.fromOffset(30, 30)
UI.ConfigsIcon.Position = UDim2.new(1, -35, 0, 11)
UI.ConfigsIcon.TextSize = 15
UI.ConfigsIcon.Font = Enum.Font.GothamBold
UI.ConfigsIcon.ZIndex = 3
UI.Tabs.Configs = UI.ConfigsIcon
UI.ConfigsIcon.MouseButton1Click:Connect(function() UI.ShowPage("Configs") end)

UI.SaveGlyph = Instance.new("Frame")
UI.SaveGlyph.Size = UDim2.fromOffset(14, 14)
UI.SaveGlyph.Position = UDim2.new(0.5, -7, 0.5, -7)
UI.SaveGlyph.BackgroundTransparency = 1
UI.SaveGlyph.BorderSizePixel = 0
UI.SaveGlyph.ZIndex = 4
UI.SaveGlyph.Parent = UI.ConfigsIcon
UI.Round(UI.SaveGlyph, 2)
local SaveOutline = Instance.new("UIStroke")
SaveOutline.Color = Colors.Muted
SaveOutline.Thickness = 1
SaveOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SaveOutline.Parent = UI.SaveGlyph
SaveOutline:SetAttribute("BoogaBaseTransparency", SaveOutline.Transparency)
table.insert(UI.Strokes, SaveOutline)
UI.SaveOutline = SaveOutline
local SaveTop = Instance.new("Frame")
SaveTop.Size = UDim2.fromOffset(8, 4)
SaveTop.Position = UDim2.fromOffset(3, 1)
SaveTop.BackgroundColor3 = Colors.Muted
SaveTop.BorderSizePixel = 0
SaveTop.ZIndex = 4
SaveTop.Parent = UI.SaveGlyph
UI.SaveTop = SaveTop
local SaveBottom = Instance.new("Frame")
SaveBottom.Size = UDim2.fromOffset(8, 5)
SaveBottom.Position = UDim2.fromOffset(3, 8)
SaveBottom.BackgroundColor3 = Colors.Muted
SaveBottom.BorderSizePixel = 0
SaveBottom.ZIndex = 4
SaveBottom.Parent = UI.SaveGlyph
UI.SaveBottom = SaveBottom
UI.Round(SaveBottom, 1)

function UI.MakeLane(parent, xScale)
    local lane = Instance.new("ScrollingFrame")
    lane.Size = UDim2.new(0.5, -5, 1, 0)
    lane.Position = UDim2.new(xScale, xScale == 0 and 0 or 5, 0, 0)
    lane.BackgroundTransparency = 1
    lane.BorderSizePixel = 0
    lane.ScrollBarThickness = 3
    lane.ScrollBarImageColor3 = Colors.Accent
    lane.CanvasSize = UDim2.new()
    lane.AutomaticCanvasSize = Enum.AutomaticSize.Y
    lane.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = lane
    return lane
end

UI.GoldLeft = UI.MakeLane(UI.Pages.Gold, 0)
UI.GoldRight = UI.MakeLane(UI.Pages.Gold, 0.5)
UI.MaterialsLeft = UI.MakeLane(UI.Pages.Materials, 0)
UI.MaterialsRight = UI.MakeLane(UI.Pages.Materials, 0.5)
UI.UtilityLeft = UI.MakeLane(UI.Pages.Utility, 0)
UI.UtilityRight = UI.MakeLane(UI.Pages.Utility, 0.5)
UI.SettingsLeft = UI.MakeLane(UI.Pages.Settings, 0)
UI.ConfigsLeft = UI.MakeLane(UI.Pages.Configs, 0)
UI.ConfigsLeft.Size = UDim2.new(1, 0, 1, 0)

UI.MakeToggle(UI.GoldLeft, "startPath", "Start Path")
UI.MakeToggle(UI.GoldLeft, "showPath", "Show Path")
UI.SelectChest = UI.MakeButton(UI.GoldLeft, "Select Gold Chest")
UI.MakeToggle(UI.GoldLeft, "autoSelectChest", "Auto Select Chest")
UI.MakeToggle(UI.GoldLeft, "pauseNearPress", "Pause Near Press")
UI.MakeToggle(UI.GoldLeft, "goldHitAura", "Gold Hit Aura")

UI.MakeToggle(UI.GoldRight, "switchSlots", "Switch Slot 1/2")
UI.MakeToggle(UI.GoldRight, "coinPress", "Coin Press")
UI.MakeToggle(UI.GoldRight, "pickupChestGold", "Pickup Gold")
UI.MakeToggle(UI.GoldRight, "pickCoins", "Pick Coins", "Enable Pick Coins?\nAre you sure?")
UI.MakeToggle(UI.GoldRight, "pickupItem", "Pick Up Gold Air")
UI.MakeToggle(UI.GoldRight, "refillCampfire", "Refill Campfire")

UI.MakeToggle(UI.MaterialsLeft, "dropUntil", "Drop Materials")
UI.MakeToggle(UI.MaterialsLeft, "deleteMaterials", "Delete Wood,Leaf,SF")
UI.MakeToggle(UI.MaterialsLeft, "autoFarm", "Farm SunFruits")
UI.MakeToggle(UI.MaterialsLeft, "autoEat", "Auto Eat Sunfruit")
UI.MakeToggle(UI.MaterialsLeft, "sfAutoMove", "Auto Move")

UI.MakeToggle(UI.MaterialsRight, "bfMasterFarm", "Auto Farm Bloodfruit")
UI.MakeToggle(UI.MaterialsRight, "bfAutoMove", "Auto Move")
UI.MakeToggle(UI.MaterialsRight, "bfAutoHarvest", "Auto Harvest")
UI.MakeToggle(UI.MaterialsRight, "bfAutoPlant", "Auto Plant")
UI.MakeToggle(UI.MaterialsRight, "bfAutoEat", "Auto Eat Bloodfruit")

UI.MakeToggle(UI.UtilityLeft, "walkSpeedEnabled", "Walkspeed")
UI.MakeSlider(UI.UtilityLeft, "moveSpeed", "Walkspeed Value", 10, 19, 1, "")
UI.MakeToggle(UI.UtilityLeft, "antiStuck", "Anti-Stuck")
UI.AntiStuckTimer = UI.MakeLabel(UI.UtilityLeft, "Anti-Stuck Timer: 40s", 30)
UI.AntiStuckTimer.BackgroundColor3 = Colors.Panel
UI.AntiStuckTimer.BackgroundTransparency = 0
UI.AntiStuckTimer.TextXAlignment = Enum.TextXAlignment.Center
UI.Round(UI.AntiStuckTimer, 7)
UI.Stroke(UI.AntiStuckTimer, 0.5)
UI.MakeToggle(UI.UtilityRight, "cpuMode", "CPU Mode")
UI.MakeToggle(UI.UtilityRight, "lockCamera", "Lock Camera")
UI.MakeToggle(UI.UtilityRight, "autoOpenChest", "Auto Open Chest")
UI.MakeToggle(UI.UtilityRight, "tweenToCoins", "Tween To Coins")

UI.MakeToggle(UI.SettingsLeft, "lowEnd", "Low End")
UI.MakeToggle(UI.SettingsLeft, "ultraLow", "Ultra Low")
UI.HideKeyButton = UI.MakeButton(UI.SettingsLeft, "Minimize Keybind: " .. State.hideKey)
UI.ExitButton = UI.MakeButton(UI.SettingsLeft, "Exit Script")

UI.MakeInput(UI.ConfigsLeft, "configName", "Name", false)
UI.SaveConfig = UI.MakeButton(UI.ConfigsLeft, "Save")
UI.LoadConfig = UI.MakeButton(UI.ConfigsLeft, "Load")
UI.DeleteConfig = UI.MakeButton(UI.ConfigsLeft, "Delete")
UI.AutoloadConfig = UI.MakeButton(UI.ConfigsLeft, "Autoload")
UI.ConfigStatus = {Text = ""}

function UI.MakeWatcherCard(text, x, y, width, height)
    local card = Instance.new("TextLabel")
    card.Size = UDim2.new(width, width == 1 and 0 or -5, 0, height or 58)
    card.Position = UDim2.new(x, x == 0 and 0 or 5, 0, y)
    card.BackgroundColor3 = Colors.Panel
    card.BorderSizePixel = 0
    card.Text = text
    card.TextColor3 = Colors.Text
    card.Font = Enum.Font.GothamMedium
    card.TextSize = 11
    card.TextWrapped = true
    card.Parent = UI.Pages.Watcher
    UI.Round(card, 8)
    UI.Stroke(card, 0.45)
    return card
end

UI.Watcher.Coins = UI.MakeWatcherCard("Coins\n0", 0, 0, 0.5, 44)
UI.Watcher.Calculated = UI.MakeWatcherCard("Calculated\n0", 0.5, 0, 0.5, 44)
UI.Watcher.Instance = UI.MakeWatcherCard("Instance\nChecking account...", 0, 52, 0.5, 44)
UI.Watcher.Workers = UI.MakeWatcherCard("Workers\nWaiting...", 0.5, 52, 0.5, 44)
UI.Watcher.Webhook = UI.MakeWatcherCard("Webhook\nInitializing...", 0, 104, 1, 44)
UI.Watcher.Session = UI.MakeWatcherCard("Session\nStarting...", 0, 156, 1, 44)
UI.Watcher.Calculated.TextColor3 = Colors.Accent

local ModalOverlay = Instance.new("TextButton")
ModalOverlay.Size = UDim2.fromScale(1, 1)
ModalOverlay.BackgroundColor3 = Colors.Black
ModalOverlay.BackgroundTransparency = 1
ModalOverlay.BorderSizePixel = 0
ModalOverlay.Text = ""
ModalOverlay.AutoButtonColor = false
ModalOverlay.Visible = false
ModalOverlay.ZIndex = 50
ModalOverlay.Parent = Main
UI.ModalOverlay = ModalOverlay

local Selector = Instance.new("CanvasGroup")
Selector.Size = UDim2.fromOffset(280, 220)
Selector.Position = UDim2.new(0.5, -140, 0.5, -110)
Selector.BackgroundColor3 = Colors.Header
Selector.BorderSizePixel = 0
Selector.GroupTransparency = 1
Selector.Visible = false
Selector.ZIndex = 51
Selector.Parent = ModalOverlay
UI.Round(Selector, 10)
UI.Stroke(Selector, 0.1)
UI.SelectorScale = Instance.new("UIScale")
UI.SelectorScale.Scale = 0.965
UI.SelectorScale.Parent = Selector
UI.SelectorTitle = UI.MakeLabel(Selector, "Select", 30)
UI.SelectorTitle.Position = UDim2.fromOffset(12, 5)
UI.SelectorTitle.Size = UDim2.new(1, -24, 0, 26)
UI.SelectorTitle.Font = Enum.Font.GothamBold
UI.SelectorTitle.ZIndex = 52

UI.SelectorSearch = Instance.new("TextBox")
UI.SelectorSearch.Size = UDim2.new(1, -24, 0, 28)
UI.SelectorSearch.Position = UDim2.fromOffset(12, 34)
UI.SelectorSearch.BackgroundColor3 = Colors.Control
UI.SelectorSearch.BorderSizePixel = 0
UI.SelectorSearch.PlaceholderText = "Search items..."
UI.SelectorSearch.PlaceholderColor3 = Colors.Muted
UI.SelectorSearch.Text = ""
UI.SelectorSearch.TextColor3 = Colors.Text
UI.SelectorSearch.Font = Enum.Font.GothamMedium
UI.SelectorSearch.TextSize = 11
UI.SelectorSearch.ClearTextOnFocus = false
UI.SelectorSearch.ZIndex = 52
UI.SelectorSearch.Parent = Selector
UI.Round(UI.SelectorSearch, 7)
UI.Stroke(UI.SelectorSearch, 0.45)

UI.SelectorList = Instance.new("ScrollingFrame")
UI.SelectorList.Size = UDim2.new(1, -24, 0, 104)
UI.SelectorList.Position = UDim2.fromOffset(12, 69)
UI.SelectorList.BackgroundTransparency = 1
UI.SelectorList.BorderSizePixel = 0
UI.SelectorList.ScrollBarThickness = 3
UI.SelectorList.ScrollBarImageColor3 = Colors.Accent
UI.SelectorList.CanvasSize = UDim2.new()
UI.SelectorList.AutomaticCanvasSize = Enum.AutomaticSize.Y
UI.SelectorList.ZIndex = 52
UI.SelectorList.Parent = Selector
local SelectorLayout = Instance.new("UIListLayout")
SelectorLayout.Padding = UDim.new(0, 5)
SelectorLayout.Parent = UI.SelectorList

UI.SelectorClear = UI.MakeButton(Selector, "Clear")
UI.SelectorClear.Size = UDim2.fromOffset(82, 28)
UI.SelectorClear.Position = UDim2.fromOffset(12, 181)
UI.SelectorClear.ZIndex = 52
UI.SelectorDone = UI.MakeButton(Selector, "Done")
UI.SelectorDone.Size = UDim2.fromOffset(82, 28)
UI.SelectorDone.Position = UDim2.new(1, -94, 0, 181)
UI.SelectorDone.ZIndex = 52

function UI.CloseModal(immediate)
    Runtime.modalToken = Runtime.modalToken + 1
    local token = Runtime.modalToken
    Runtime.selector = nil
    Runtime.confirmCallback = nil
    if immediate then
        UI.TweenStrokes(false, 0, Selector)
        if UI.Confirm then UI.TweenStrokes(false, 0, UI.Confirm) end
        Selector.Visible = false
        if UI.Confirm then UI.Confirm.Visible = false end
        ModalOverlay.Visible = false
        UI.SelectorScale.Scale = 0.965
        if UI.ConfirmScale then UI.ConfirmScale.Scale = 0.965 end
        return
    end
    UI.Tween(ModalOverlay, 0.2, {BackgroundTransparency = 1})
    if Selector.Visible then
        UI.TweenStrokes(false, 0.16, Selector)
        UI.Tween(Selector, 0.16, {GroupTransparency = 1})
        UI.Tween(UI.SelectorScale, 0.16, {Scale = 0.965})
    end
    if UI.Confirm and UI.Confirm.Visible then
        UI.TweenStrokes(false, 0.16, UI.Confirm)
        UI.Tween(UI.Confirm, 0.16, {GroupTransparency = 1})
        UI.Tween(UI.ConfirmScale, 0.16, {Scale = 0.965})
    end
    task.delay(0.2, function()
        if Runtime.modalToken == token then
            Selector.Visible = false
            if UI.Confirm then UI.Confirm.Visible = false end
            ModalOverlay.Visible = false
        end
    end)
end

function UI.RenderSelector()
    for _, child in ipairs(UI.SelectorList:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    local selectorData = Runtime.selector
    if not selectorData then return end
    local query = string.lower(UI.SelectorSearch.Text)
    local shown = 0
    for _, value in ipairs(selectorData.values) do
        if query == "" or string.find(string.lower(value), query, 1, true) then
            shown = shown + 1
            local row = UI.MakeButton(UI.SelectorList, value)
            row.Size = UDim2.new(1, -4, 0, 28)
            row.ZIndex = 53
            local selected = selectorData.multi and selectorData.selection[value] == true
                or (not selectorData.multi and State[selectorData.key] == value)
            row.BackgroundColor3 = selected and Colors.Accent or Colors.Control
            row.TextColor3 = selected and Colors.EnabledText or Colors.Text
            row.TextStrokeTransparency = 1
            row:SetAttribute("BoogaSelected", selected)
            row.MouseButton1Click:Connect(function()
                if selectorData.multi then
                    selectorData.selection[value] = not selectorData.selection[value]
                    UI.RenderSelector()
                else
                    State[selectorData.key] = value
                    UI.CloseModal()
                    UI.Refresh()
                    if selectorData.onSelected then
                        task.defer(selectorData.onSelected, value)
                    elseif selectorData.key == "autoloadConfig" then
                        Runtime.WriteAutoload()
                    end
                end
            end)
        end
    end
    if shown == 0 then
        local empty = UI.MakeLabel(UI.SelectorList, "No matching options", 34)
        empty.Size = UDim2.new(1, -4, 0, 34)
        empty.TextColor3 = Colors.Muted
        empty.TextXAlignment = Enum.TextXAlignment.Center
        empty.ZIndex = 53
    end
end

function UI.OpenSelector(key, label, values, multi, onSelected)
    local selection = {}
    if multi then
        local available = {}
        for _, value in ipairs(values) do available[value] = true end
        for value, selected in pairs(State[key] or {}) do
            if available[value] then selection[value] = selected == true end
        end
    end
    Runtime.selector = {
        key = key,
        label = label,
        values = values,
        multi = multi,
        selection = selection,
        onSelected = onSelected
    }
    UI.SelectorTitle.Text = label
    UI.SelectorSearch.Text = ""
    local loweredLabel = string.lower(label)
    UI.SelectorSearch.PlaceholderText = string.find(loweredLabel, "config", 1, true)
        and "Search configs..."
        or (string.find(loweredLabel, "path", 1, true) and "Search paths..." or "Search inventory...")
    UI.SelectorClear.Visible = multi
    UI.SelectorDone.Text = multi and "Done" or "Cancel"
    Runtime.modalToken = Runtime.modalToken + 1
    ModalOverlay.Visible = true
    ModalOverlay.BackgroundTransparency = 1
    Selector.Visible = true
    Selector.GroupTransparency = 1
    UI.SelectorScale.Scale = 0.965
    if UI.Confirm then UI.Confirm.Visible = false end
    UI.RenderSelector()
    UI.TweenStrokes(false, 0, Selector)
    UI.Tween(ModalOverlay, 0.22, {BackgroundTransparency = 0.42})
    UI.Tween(Selector, 0.22, {GroupTransparency = 0})
    UI.Tween(UI.SelectorScale, 0.22, {Scale = 1})
    UI.TweenStrokes(true, 0.22, Selector)
end

UI.SelectorSearch:GetPropertyChangedSignal("Text"):Connect(UI.RenderSelector)
UI.SelectorClear.MouseButton1Click:Connect(function()
    if Runtime.selector and Runtime.selector.multi then
        Runtime.selector.selection = {}
        UI.RenderSelector()
    end
end)
UI.SelectorDone.MouseButton1Click:Connect(function()
    if Runtime.selector and Runtime.selector.multi then
        State[Runtime.selector.key] = Runtime.selector.selection
        UI.Refresh()
    end
    UI.CloseModal()
end)
ModalOverlay.MouseButton1Click:Connect(function() end)

local Confirm = Instance.new("CanvasGroup")
Confirm.Size = UDim2.fromOffset(320, 150)
Confirm.Position = UDim2.new(0.5, -160, 0.5, -75)
Confirm.BackgroundColor3 = Colors.Header
Confirm.BorderSizePixel = 0
Confirm.GroupTransparency = 1
Confirm.Visible = false
Confirm.ZIndex = 60
Confirm.Parent = ModalOverlay
UI.Round(Confirm, 10)
UI.Stroke(Confirm, 0.1)
UI.ConfirmScale = Instance.new("UIScale")
UI.ConfirmScale.Scale = 0.965
UI.ConfirmScale.Parent = Confirm
UI.Confirm = Confirm
UI.ConfirmText = UI.MakeLabel(Confirm, "Confirm?", 70)
UI.ConfirmText.Position = UDim2.fromOffset(14, 12)
UI.ConfirmText.Size = UDim2.new(1, -28, 0, 70)
UI.ConfirmText.TextWrapped = true
UI.ConfirmText.TextXAlignment = Enum.TextXAlignment.Center
UI.ConfirmText.ZIndex = 61

UI.ConfirmYes = UI.MakeButton(Confirm, "Confirm")
UI.ConfirmYes.Size = UDim2.fromOffset(125, 32)
UI.ConfirmYes.Position = UDim2.fromOffset(22, 100)
UI.ConfirmYes.BackgroundColor3 = Colors.Accent
UI.ConfirmYes.TextColor3 = Colors.EnabledText
UI.ConfirmYes:SetAttribute("BoogaSelected", true)
UI.ConfirmYes.ZIndex = 61
UI.ConfirmNo = UI.MakeButton(Confirm, "Cancel")
UI.ConfirmNo.Size = UDim2.fromOffset(125, 32)
UI.ConfirmNo.Position = UDim2.new(1, -147, 0, 100)
UI.ConfirmNo.ZIndex = 61

function UI.AskConfirm(message, callback)
    UI.CloseModal(true)
    Runtime.modalToken = Runtime.modalToken + 1
    Runtime.confirmCallback = callback
    UI.ConfirmText.Text = message
    ModalOverlay.Visible = true
    ModalOverlay.BackgroundTransparency = 1
    Confirm.Visible = true
    Confirm.GroupTransparency = 1
    UI.ConfirmScale.Scale = 0.965
    UI.TweenStrokes(false, 0, Confirm)
    UI.Tween(ModalOverlay, 0.22, {BackgroundTransparency = 0.42})
    UI.Tween(Confirm, 0.22, {GroupTransparency = 0})
    UI.Tween(UI.ConfirmScale, 0.22, {Scale = 1})
    UI.TweenStrokes(true, 0.22, Confirm)
end

UI.ConfirmYes.MouseButton1Click:Connect(function()
    local callback = Runtime.confirmCallback
    UI.CloseModal(true)
    if callback then
        task.spawn(function()
            pcall(callback)
        end)
    end
end)
UI.ConfirmNo.MouseButton1Click:Connect(function()
    UI.CloseModal()
end)

function UI.Refresh()
    for key, data in pairs(UI.Toggles) do
        local enabled = State[key] == true
        data.button.Text = data.label .. (enabled and ": ON" or ": OFF")
        data.button.TextStrokeTransparency = 1
        data.button:SetAttribute("BoogaSelected", enabled)
        UI.Tween(data.button, 0.2, {
            BackgroundColor3 = enabled and Colors.Accent or Colors.Control,
            TextColor3 = enabled and Colors.EnabledText or Colors.Text
        })
    end
    for key, dropdown in pairs(UI.Dropdowns) do
        dropdown.button.Text = dropdown.label .. ": " .. UI.DropdownText(key, dropdown.multi)
        dropdown.button.TextColor3 = Colors.Text
    end
    for key, slider in pairs(UI.Sliders) do
        slider:SetValue(State[key], false)
    end
    for key, input in pairs(UI.Inputs) do
        if not input:IsFocused() then input.Text = tostring(State[key] or "") end
    end
    UI.HideKeyButton.Text = Runtime.bindingKey and "Press any key..." or "Minimize Keybind: " .. State.hideKey
    if Runtime.UpdateChestButton then Runtime.UpdateChestButton() end
    if Runtime.UpdatePathEditorInputs then Runtime.UpdatePathEditorInputs() end
end

UI.ShowPage("Gold")
UI.Refresh()
for _, stroke in ipairs(UI.Strokes) do stroke.Transparency = 1 end
UI.Tween(Main, 0.26, {GroupTransparency = 0})
UI.Tween(UI.MainScale, 0.26, {Scale = 1})
UI.TweenStrokes(true, 0.26)

local dragData = {active = false, input = nil, start = nil, position = nil}
table.insert(Runtime.connections, Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragData.active = true
        dragData.start = input.Position
        dragData.position = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragData.active = false end
        end)
    end
end))
table.insert(Runtime.connections, Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragData.input = input
    end
end))
table.insert(Runtime.connections, Services.UserInputService.InputChanged:Connect(function(input)
    if dragData.active and input == dragData.input then
        local delta = input.Position - dragData.start
        Main.Position = UDim2.new(
            dragData.position.X.Scale,
            dragData.position.X.Offset + delta.X,
            dragData.position.Y.Scale,
            dragData.position.Y.Offset + delta.Y
        )
    end
end))

local CpuCover = Instance.new("Frame")
CpuCover.Name = "CpuCover"
CpuCover.Size = UDim2.fromScale(1, 1)
CpuCover.BackgroundColor3 = Colors.Black
CpuCover.BorderSizePixel = 0
CpuCover.Visible = false
CpuCover.ZIndex = 1
CpuCover.Parent = ScreenGui
UI.CpuCover = CpuCover

local PATH_POINTS = {
    {x=-140.75302124023438, y=-29.985698699951172, z=-190.17254638671875, wait=2, equip=1, equipenable=true, jump=false},
    {x=-119.31350708007812, y=-25.793699264526367, z=-194.75294494628906, wait=1.5, equip=1, equipenable=false, jump=false},
    {x=-107.11988830566406, y=-14.877410888671875, z=-185.7013702392578, wait=0, equip=1, equipenable=false, jump=false},
    {x=-91.96001434326172, y=-6.04759407043457, z=-176.57630920410156, wait=0, equip=1, equipenable=false, jump=false},
    {x=-36.64952087402344, y=-2.8125057220458984, z=-133.5755157470703, wait=0, equip=1, equipenable=false, jump=false},
    {x=449.4616394042969, y=-3.3163070678710938, z=138.77236938476562, wait=0, equip=1, equipenable=false, jump=false},
    {x=457.09320068359375, y=12.64422607421875, z=140.4607391357422, wait=0, equip=1, equipenable=false, jump=false},
    {x=464.60321044921875, y=16.41159439086914, z=143.6938018798828, wait=0, equip=1, equipenable=false, jump=false},
    {x=476.8289489746094, y=12.090450286865234, z=151.6466064453125, wait=0.5, equip=1, equipenable=false, jump=false},
    {x=474.3323974609375, y=16.277469635009766, z=200.78839111328125, wait=0, equip=1, equipenable=false, jump=false},
    {x=469.9004211425781, y=11.689022064208984, z=233.28887939453125, wait=1, equip=1, equipenable=false, jump=false},
    {x=475.97784423828125, y=12.661579132080078, z=241.33673095703125, wait=0, equip=1, equipenable=false, jump=false},
    {x=490.5067138671875, y=-3, z=252.75474548339844, wait=0, equip=1, equipenable=false, jump=false},
    {x=729.6565551757812, y=-2.999999523162842, z=365.05615234375, wait=0, equip=1, equipenable=false, jump=false},
    {x=1057.869384765625, y=3.9935264587402344, z=511.57806396484375, wait=0, equip=1, equipenable=false, jump=false},
    {x=1162.157470703125, y=-3.3144607543945312, z=566.8117065429688, wait=0, equip=1, equipenable=false, jump=false},
    {x=1215.233642578125, y=-12.017799377441406, z=531.7390747070312, wait=0, equip=1, equipenable=false, jump=false},
    {x=1241.5537109375, y=-15.78512191772461, z=569.8186645507812, wait=1, equip=1, equipenable=false, jump=false},
    {x=1286.194091796875, y=-15.509637832641602, z=613.6463012695312, wait=0, equip=1, equipenable=false, jump=false},
    {x=1315.987060546875, y=-19.050758361816406, z=600.4512329101562, wait=1, equip=1, equipenable=false, jump=false},
    {x=1294.0362548828125, y=-15.575050354003906, z=621.3857421875, wait=0, equip=1, equipenable=false, jump=false},
    {x=1307.613037109375, y=-15.25442123413086, z=656.8776245117188, wait=0, equip=1, equipenable=false, jump=false},
    {x=1280.750244140625, y=-18.851194381713867, z=687.6311645507812, wait=1, equip=1, equipenable=false, jump=false},
    {x=1307.6617431640625, y=-15.256404876708984, z=656.7553100585938, wait=0, equip=1, equipenable=false, jump=false},
    {x=1305.692626953125, y=-15.763208389282227, z=649.06640625, wait=0, equip=1, equipenable=false, jump=false},
    {x=1241.618896484375, y=-15.779075622558594, z=569.8116455078125, wait=0, equip=1, equipenable=false, jump=false},
    {x=1215.2764892578125, y=-12.026765823364258, z=531.7905883789062, wait=0, equip=1, equipenable=false, jump=false},
    {x=1185.540771484375, y=-15.456033706665039, z=461.4212646484375, wait=1, equip=1, equipenable=false, jump=false},
    {x=1192.3968505859375, y=-15.762460708618164, z=475.7747802734375, wait=0, equip=1, equipenable=false, jump=false},
    {x=1207.5888671875, y=-20.595199584960938, z=470.5138244628906, wait=0, equip=1, equipenable=false, jump=false},
    {x=1275.562255859375, y=-23.544275283813477, z=456.6135559082031, wait=0, equip=1, equipenable=false, jump=false},
    {x=1273.831298828125, y=-18.170045852661133, z=435.40045166015625, wait=0, equip=1, equipenable=false, jump=false},
    {x=1263.4959716796875, y=-15.671236038208008, z=417.3788146972656, wait=0, equip=1, equipenable=false, jump=false},
    {x=1202.037841796875, y=-1.7144832611083984, z=334.905517578125, wait=0, equip=1, equipenable=false, jump=false},
    {x=1188.07373046875, y=-2.035244941711426, z=319.68603515625, wait=0, equip=1, equipenable=false, jump=false},
    {x=716.411376953125, y=-3.9945693016052246, z=-142.5128173828125, wait=0, equip=1, equipenable=false, jump=false},
    {x=694.3192138671875, y=17.386688232421875, z=-161.43527221679688, wait=0, equip=1, equipenable=false, jump=false},
    {x=683.3438110351562, y=32.30760192871094, z=-167.1634521484375, wait=0, equip=1, equipenable=false, jump=false},
    {x=660.0833740234375, y=32.245208740234375, z=-186.8964080810547, wait=1, equip=1, equipenable=false, jump=false},
    {x=699.4446411132812, y=28.500442504882812, z=-201.92117309570312, wait=0, equip=1, equipenable=false, jump=false},
    {x=715.6201782226562, y=26.26921844482422, z=-217.4705352783203, wait=0, equip=1, equipenable=false, jump=false},
    {x=727.9087524414062, y=23.044580459594727, z=-244.2185516357422, wait=0, equip=1, equipenable=false, jump=false},
    {x=702.0609741210938, y=34.193241119384766, z=-309.710205078125, wait=0, equip=1, equipenable=false, jump=false},
    {x=687.6783447265625, y=54.375221252441406, z=-330.9793701171875, wait=0, equip=1, equipenable=false, jump=false},
    {x=682.963623046875, y=62.84449768066406, z=-354.2230224609375, wait=0, equip=1, equipenable=false, jump=false},
    {x=682.5621337890625, y=74.81529235839844, z=-363.08709716796875, wait=0, equip=1, equipenable=false, jump=false},
    {x=679.9118041992188, y=80.4763412475586, z=-372.0174255371094, wait=0, equip=1, equipenable=false, jump=false},
    {x=678.1869506835938, y=79.29402923583984, z=-378.5758972167969, wait=1, equip=1, equipenable=false, jump=false},
    {x=593.1503295898438, y=22.726726531982422, z=-359.16217041015625, wait=0, equip=1, equipenable=false, jump=false},
    {x=593.8072509765625, y=-4.893863201141357, z=-353.7864074707031, wait=1, equip=1, equipenable=false, jump=false},
    {x=623.1016845703125, y=-7.344945907592773, z=-358.8044738769531, wait=0.25, equip=1, equipenable=false, jump=false},
    {x=630.2095947265625, y=-7.541135787963867, z=-379.7254333496094, wait=2, equip=1, equipenable=false, jump=false},
    {x=554.26904296875, y=12.96484375, z=-398.23663330078125, wait=0, equip=1, equipenable=false, jump=false},
    {x=464.4996032714844, y=-5, z=-419.7094421386719, wait=0, equip=1, equipenable=false, jump=false},
    {x=19.623218536376953, y=-6.068264484405518, z=-550.6239013671875, wait=0, equip=1, equipenable=false, jump=false},
    {x=-21.722415924072266, y=-3.0084075927734375, z=-557.9688110351562, wait=0, equip=1, equipenable=false, jump=false},
    {x=-57.53821563720703, y=-3.388853073120117, z=-570.225341796875, wait=0, equip=1, equipenable=false, jump=false},
    {x=-179.04275512695312, y=-1.5733046531677246, z=-621.7989501953125, wait=0, equip=1, equipenable=false, jump=false},
    {x=-198.27664184570312, y=6.366794586181641, z=-625.4280395507812, wait=0, equip=1, equipenable=false, jump=false},
    {x=-206.7178497314453, y=19.34856605529785, z=-626.2610473632812, wait=0, equip=1, equipenable=false, jump=false},
    {x=-212.7473602294922, y=19.61411476135254, z=-621.0771484375, wait=1, equip=1, equipenable=false, jump=false},
    {x=-227.88816833496094, y=2.816864013671875, z=-618.2684326171875, wait=0, equip=1, equipenable=false, jump=false},
    {x=-365.38031005859375, y=-3.0617294311523438, z=-611.3173828125, wait=0, equip=1, equipenable=false, jump=false},
    {x=-387.54278564453125, y=-11.44034194946289, z=-609.9725952148438, wait=0, equip=1, equipenable=false, jump=false},
    {x=-399.1018371582031, y=-22.568632125854492, z=-609.0355834960938, wait=0, equip=1, equipenable=false, jump=false},
    {x=-409.27484130859375, y=-39.42827606201172, z=-554.4389038085938, wait=0, equip=1, equipenable=false, jump=false},
    {x=-387.3904724121094, y=-43.19425582885742, z=-555.9221801757812, wait=1, equip=1, equipenable=false, jump=false},
    {x=-315.548583984375, y=-49.17181396484375, z=-569.5033569335938, wait=0, equip=1, equipenable=false, jump=false},
    {x=-281.66156005859375, y=-56.85545349121094, z=-558.1670532226562, wait=0, equip=1, equipenable=false, jump=false},
    {x=-230.5189971923828, y=-59, z=-539.8056640625, wait=0, equip=1, equipenable=false, jump=false},
    {x=-214.7939453125, y=-59.485443115234375, z=-526.3626708984375, wait=0, equip=1, equipenable=false, jump=false},
    {x=-201.5225830078125, y=-60.20200729370117, z=-541.5321044921875, wait=0, equip=1, equipenable=false, jump=false},
    {x=-174.5003204345703, y=-63.09870910644531, z=-563.3765258789062, wait=0, equip=1, equipenable=false, jump=false},
    {x=-157.77098083496094, y=-64.46682739257812, z=-593.5687866210938, wait=0, equip=1, equipenable=false, jump=false},
    {x=-207.91184997558594, y=-61.69873046875, z=-625.405517578125, wait=1, equip=1, equipenable=false, jump=false},
    {x=-157.7576446533203, y=-64.44625854492188, z=-593.5261840820312, wait=0, equip=1, equipenable=false, jump=false},
    {x=-174.50450134277344, y=-63.100341796875, z=-563.4628295898438, wait=0, equip=1, equipenable=false, jump=false},
    {x=-165.35691833496094, y=-63.074806213378906, z=-511.9172058105469, wait=0, equip=1, equipenable=false, jump=false},
    {x=-180.05520629882812, y=-69.2813491821289, z=-453.8267517089844, wait=0, equip=1, equipenable=false, jump=false},
    {x=-171.56483459472656, y=-73.43494415283203, z=-456.92535400390625, wait=0, equip=1, equipenable=false, jump=false},
    {x=-156.2505645751953, y=-99.44965362548828, z=-478.06658935546875, wait=0, equip=1, equipenable=false, jump=false},
    {x=-164.91696166992188, y=-99.43761444091797, z=-502.3164367675781, wait=0, equip=1, equipenable=false, jump=false},
    {x=-183.961181640625, y=-102.99999237060547, z=-505.1149597167969, wait=0, equip=1, equipenable=false, jump=false},
    {x=-192.162109375, y=-103.27455139160156, z=-496.7663879394531, wait=0, equip=1, equipenable=false, jump=false},
    {x=-189.58489990234375, y=-104.05291748046875, z=-456.0731201171875, wait=2, equip=1, equipenable=false, jump=false},
    {x=-192.1395263671875, y=-103.26908111572266, z=-496.70355224609375, wait=0, equip=1, equipenable=false, jump=false},
    {x=-183.95126342773438, y=-103, z=-505.1314392089844, wait=0, equip=1, equipenable=false, jump=false},
    {x=-164.86270141601562, y=-99.4522476196289, z=-502.3470153808594, wait=0, equip=1, equipenable=false, jump=false},
    {x=-146.2549591064453, y=-97.43460845947266, z=-495.0435485839844, wait=0, equip=1, equipenable=false, jump=false},
    {x=7.541040420532227, y=-103, z=-423.418212890625, wait=0, equip=1, equipenable=false, jump=false},
    {x=34.360626220703125, y=-99.18365478515625, z=-371.1417541503906, wait=0, equip=1, equipenable=false, jump=false},
    {x=55.09477996826172, y=-99, z=-359.40777587890625, wait=1, equip=1, equipenable=false, jump=false},
    {x=19.69225311279297, y=-99, z=-391.58526611328125, wait=0, equip=1, equipenable=false, jump=false},
    {x=11.900020599365234, y=-102.96358489990234, z=-415.3416748046875, wait=0, equip=1, equipenable=false, jump=false},
    {x=-45.130699157714844, y=-104.36945343017578, z=-389.5151672363281, wait=0, equip=1, equipenable=false, jump=false},
    {x=-92.34864044189453, y=-103, z=-353.9851379394531, wait=0, equip=1, equipenable=false, jump=false},
    {x=-123.5248794555664, y=-90.99566650390625, z=-291.9811706542969, wait=0, equip=1, equipenable=false, jump=false},
    {x=-159.88336181640625, y=-87.26156616210938, z=-263.26336669921875, wait=0, equip=1, equipenable=false, jump=false},
    {x=-245.3988494873047, y=-83, z=-248.14662170410156, wait=1, equip=1, equipenable=false, jump=false},
    {x=-230.7689666748047, y=-83.02196502685547, z=-257.0267639160156, wait=0, equip=1, equipenable=false, jump=false},
    {x=-232.29132080078125, y=-80.01478576660156, z=-268.34808349609375, wait=0, equip=1, equipenable=false, jump=false},
    {x=-262.0515441894531, y=-79, z=-298.0277404785156, wait=0, equip=1, equipenable=false, jump=false},
    {x=-262.7806091308594, y=-78.65348815917969, z=-323.1799621582031, wait=0, equip=1, equipenable=false, jump=false},
    {x=-304.8475036621094, y=-79, z=-368.1495056152344, wait=1, equip=1, equipenable=false, jump=false},
    {x=-262.7782897949219, y=-78.65474700927734, z=-323.1613464355469, wait=0, equip=1, equipenable=false, jump=false},
    {x=-262.1943054199219, y=-79, z=-297.93939208984375, wait=0, equip=1, equipenable=false, jump=false},
    {x=-232.17462158203125, y=-80.07608032226562, z=-268.10711669921875, wait=0, equip=1, equipenable=false, jump=false},
    {x=-230.7614288330078, y=-83.02151489257812, z=-256.96624755859375, wait=0, equip=1, equipenable=false, jump=false},
    {x=-234.27493286132812, y=-90.60616302490234, z=-217.21533203125, wait=0, equip=1, equipenable=false, jump=false},
    {x=-234.24928283691406, y=-88.4429702758789, z=-177.45703125, wait=0, equip=1, equipenable=false, jump=false},
    {x=-298.5879211425781, y=-93, z=-76.40196228027344, wait=0, equip=1, equipenable=false, jump=false},
    {x=-336.71014404296875, y=-91.015625, z=-47.368873596191406, wait=1, equip=1, equipenable=false, jump=false},
    {x=-322.3817138671875, y=-85.93417358398438, z=-103.84822082519531, wait=0, equip=1, equipenable=false, jump=false},
    {x=-312.7877502441406, y=-80.29764556884766, z=-107.85237884521484, wait=0, equip=1, equipenable=false, jump=false},
    {x=-291.18798828125, y=-72.95791625976562, z=-96.05986785888672, wait=0, equip=1, equipenable=false, jump=false},
    {x=-258.7352600097656, y=-71.40682220458984, z=-83.00981140136719, wait=0, equip=1, equipenable=false, jump=false},
    {x=-237.53225708007812, y=-71.65625, z=-83.11640167236328, wait=1, equip=1, equipenable=false, jump=false},
    {x=-264.6081237792969, y=-74.92657470703125, z=-74.37799072265625, wait=0, equip=1, equipenable=false, jump=false},
    {x=-271.8966369628906, y=-93, z=-69.28028106689453, wait=0, equip=1, equipenable=false, jump=false},
    {x=-244.89463806152344, y=-93, z=-94.01403045654297, wait=0, equip=1, equipenable=false, jump=false},
    {x=-234.6796417236328, y=-86.08658599853516, z=-96.06693267822266, wait=0, equip=1, equipenable=false, jump=false},
    {x=-208.53977966308594, y=-89.05722045898438, z=-92.98556518554688, wait=0, equip=1, equipenable=false, jump=false},
    {x=-186.21617126464844, y=-93, z=-86.48092651367188, wait=0, equip=1, equipenable=false, jump=false},
    {x=-23.464744567871094, y=-91.06700134277344, z=-6.431948661804199, wait=1, equip=1, equipenable=false, jump=false},
    {x=-54.05946731567383, y=-93, z=-34.732177734375, wait=0, equip=1, equipenable=false, jump=false},
    {x=-64.57084655761719, y=-83.93140411376953, z=-67.21971130371094, wait=0, equip=1, equipenable=false, jump=false},
    {x=-56.27317810058594, y=-75.80343627929688, z=-74.03585052490234, wait=0, equip=1, equipenable=false, jump=false},
    {x=-25.429244995117188, y=-75.0190658569336, z=-49.47193145751953, wait=0, equip=1, equipenable=false, jump=false},
    {x=-20.472515106201172, y=-75.26667785644531, z=-41.99848937988281, wait=0, equip=1, equipenable=false, jump=false},
    {x=3.372006416320801, y=-75.00245666503906, z=-37.93674087524414, wait=0, equip=1, equipenable=false, jump=false},
    {x=9.361078262329102, y=-75, z=-45.16803741455078, wait=0, equip=1, equipenable=false, jump=false},
    {x=2.1956307888031006, y=-83, z=-81.34650421142578, wait=1, equip=1, equipenable=false, jump=false},
    {x=7.540444850921631, y=-77.6328125, z=-91.84691619873047, wait=0, equip=1, equipenable=false, jump=false},
    {x=10.9675931930542, y=-73.97479248046875, z=-100.1095962524414, wait=0, equip=1, equipenable=false, jump=false},
    {x=21.415082931518555, y=-70.9155044555664, z=-110.52931213378906, wait=0, equip=1, equipenable=false, jump=false},
    {x=48.723270416259766, y=-75, z=-125.2779541015625, wait=0, equip=1, equipenable=false, jump=false},
    {x=63.05690383911133, y=-75.3080062866211, z=-130.89697265625, wait=0, equip=1, equipenable=false, jump=false},
    {x=70.77178192138672, y=-72.12876892089844, z=-118.96957397460938, wait=0, equip=1, equipenable=false, jump=false},
    {x=74.71022033691406, y=-60.7221565246582, z=-90.87541961669922, wait=0, equip=1, equipenable=false, jump=false},
    {x=67.58888244628906, y=-48.76361083984375, z=-62.624996185302734, wait=0, equip=1, equipenable=false, jump=false},
    {x=45.71700668334961, y=-36.125831604003906, z=-57.280296325683594, wait=0, equip=1, equipenable=false, jump=false},
    {x=-40.736576080322266, y=-35.00068664550781, z=-100.33395385742188, wait=0, equip=2, equipenable=true, jump=false},
    {x=-106.33723449707031, y=-35.000003814697266, z=-160.429931640625, wait=1, equip=1, equipenable=false, jump=false},
    {x=-125.25753784179688, y=-35.04928970336914, z=-160.6648406982422, wait=1, equip=1, equipenable=false, jump=false},
    {x=-144.2646484375, y=-34.70026397705078, z=-160.45301818847656, wait=1, equip=1, equipenable=false, jump=false},
    {x=-144.25091552734375, y=-34.70109558105469, z=-160.4765625, wait=0, equip=1, equipenable=true, jump=false},
}

Runtime.pathPoints = {}

function Runtime.GetPathEdit(index)
    local edits = type(State.pathEdits) == "table" and State.pathEdits or {}
    return edits[tostring(index)] or edits[index]
end

function Runtime.RebuildPathPoints()
    local points = {}
    for index, base in ipairs(PATH_POINTS) do
        local edit = Runtime.GetPathEdit(index)
        local point = {
            x = tonumber(base.x) or 0,
            y = tonumber(base.y) or 0,
            z = tonumber(base.z) or 0,
            wait = base.wait,
            equip = base.equip,
            equipenable = base.equipenable,
            jump = base.jump,
            originalIndex = index,
            source = "base",
            key = tostring(index)
        }
        if type(edit) == "table" then
            if tonumber(edit.x) then point.x = tonumber(edit.x) end
            if tonumber(edit.y) then point.y = tonumber(edit.y) end
            if tonumber(edit.z) then point.z = tonumber(edit.z) end
            if edit.wait ~= nil then point.wait = tonumber(edit.wait) or point.wait end
        end
        table.insert(points, point)
    end
    for addedIndex, added in ipairs(type(State.pathAddedPoints) == "table" and State.pathAddedPoints or {}) do
        if type(added) == "table" and added.deleted ~= true
            and tonumber(added.x) and tonumber(added.y) and tonumber(added.z) then
            added.id = tostring(added.id or ("added_" .. tostring(addedIndex)))
            table.insert(points, {
                x = tonumber(added.x),
                y = tonumber(added.y),
                z = tonumber(added.z),
                wait = tonumber(added.wait) or 0,
                equip = tonumber(added.equip) or 1,
                equipenable = added.equipenable == true,
                jump = added.jump == true,
                source = "added",
                key = added.id,
                addedIndex = addedIndex
            })
        end
    end
    if #points == 0 then
        for index, base in ipairs(PATH_POINTS) do
            points[index] = {
                x = base.x, y = base.y, z = base.z, wait = base.wait,
                equip = base.equip, equipenable = base.equipenable, jump = base.jump,
                originalIndex = index, source = "base", key = tostring(index)
            }
        end
    end
    Runtime.pathPoints = points
    return points
end

function Runtime.GetPathPoints()
    if type(Runtime.pathPoints) ~= "table" or #Runtime.pathPoints == 0 then
        return Runtime.RebuildPathPoints()
    end
    return Runtime.pathPoints
end

Runtime.pathFolderName = "BoogaUtilityPath_" .. tostring(Player.UserId)
Runtime.playerMouse = Player:GetMouse()

function Runtime.GetRoot()
    local character = Player.Character
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

function Runtime.IsCharacterSpawned()
    local character = Player.Character
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if Player:GetAttribute("hasSpawned") == false then return false end
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    if root.Position.Y > 800 then return false end
    return true
end

function Runtime.SetMovementStability(_enabled) end

function Runtime.UpdateMovementStability()
    Runtime.SetMovementStability(State.startPath)
end

function Runtime.CancelMotion(owner)
    if owner and Runtime.motionOwner ~= owner then return end
    if Runtime.motionTween then
        Runtime.motionTween:Cancel()
        Runtime.motionTween = nil
    end
    Runtime.motionOwner = nil
    Runtime.motionTargetPosition = nil
end

function Runtime.Steer(root, targetCFrame, owner)
    if not root or not targetCFrame then return end
    Runtime.CancelMotion()
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local speed = (owner == "path" and Runtime.pathSpeed)
        or (owner == "bloodfruitFarm" and 19)
        or math.max(tonumber(State.moveSpeed) or 19, 1)
    local duration = distance / speed
    local tween = Services.TweenService:Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()
    Runtime.motionTween = tween
    Runtime.motionOwner = owner
end

function Runtime.StopPathMovement()
    Runtime.CancelMotion("path")
    Runtime.pathTargetPosition = nil
    Runtime.pathWrongDirectionSince = 0
    Runtime.pathGroundPullActive = false
    if Runtime.pathVelocity and Runtime.pathVelocity.Parent then
        Runtime.pathVelocity.VectorVelocity = Vector3.zero
    end
    local root = Runtime.pathControlledRoot
    if root and root.Parent then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

function Runtime.SetPlayerControlsEnabled(enabled)
    local controls = Runtime.pathControls
    pcall(function()
        local playerScripts = Player:FindFirstChild("PlayerScripts")
        local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
        if playerModule then
            controls = require(playerModule):GetControls()
            Runtime.pathControls = controls
        end
    end)
    if controls then
        pcall(function()
            if enabled then controls:Enable() else controls:Disable() end
        end)
    end
end

function Runtime.EndPathControl()
    Runtime.StopPathMovement()
    Runtime.pathObstacleLiftUntil = 0
    Runtime.pathObstacleLiftSpeed = 0
    Runtime.SetPlayerControlsEnabled(true)
    for _, mover in pairs({Runtime.pathVelocity, Runtime.pathOrientation, Runtime.pathAttachment}) do
        if mover then pcall(function() mover:Destroy() end) end
    end
    if Runtime.pathIdleTrack then
        pcall(function() Runtime.pathIdleTrack:Stop(0.12) end)
    end
    if Runtime.pathIdleAnimation then
        pcall(function() Runtime.pathIdleAnimation:Destroy() end)
    end
    local controlledRoot = Runtime.pathControlledRoot
    if controlledRoot and controlledRoot.Parent then
        for _, name in ipairs({"BoogaPathVelocity", "BoogaPathOrientation", "BoogaPathAttachment"}) do
            local stale = controlledRoot:FindFirstChild(name)
            if stale then pcall(function() stale:Destroy() end) end
        end
        controlledRoot.Anchored = false
        controlledRoot.AssemblyLinearVelocity = Vector3.zero
        controlledRoot.AssemblyAngularVelocity = Vector3.zero
    end
    local humanoid = Runtime.pathHumanoid
    if humanoid and humanoid.Parent then
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid.AutoRotate = true
        humanoid.WalkSpeed = State.walkSpeedEnabled and State.moveSpeed or 16
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
    end
    local animate = Runtime.pathAnimate
    if animate and animate.Parent then
        animate.Disabled = Runtime.pathOriginalAnimateDisabled == true
    end
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        if humanoid and humanoid.Parent then camera.CameraSubject = humanoid end
    end
    Runtime.pathControlledRoot = nil
    Runtime.pathHumanoid = nil
    Runtime.pathControls = nil
    Runtime.pathAnimate = nil
    Runtime.pathOriginalAnimateDisabled = nil
    Runtime.pathIdleTrack = nil
    Runtime.pathIdleAnimation = nil
    Runtime.pathRotation = nil
    Runtime.pathAttachment = nil
    Runtime.pathVelocity = nil
    Runtime.pathOrientation = nil
    Runtime.pathOriginalAnchored = nil
    Runtime.pathOriginalAutoRotate = nil
    Runtime.pathOriginalWalkSpeed = nil
    task.defer(function()
        if State.startPath then return end
        Runtime.SetPlayerControlsEnabled(true)
        local currentRoot = Runtime.GetRoot()
        local currentHumanoid = currentRoot and currentRoot.Parent
            and currentRoot.Parent:FindFirstChildOfClass("Humanoid")
        if currentRoot then currentRoot.Anchored = false end
        if currentHumanoid then
            currentHumanoid.PlatformStand = false
            currentHumanoid.Sit = false
            currentHumanoid.AutoRotate = true
            currentHumanoid.WalkSpeed = State.walkSpeedEnabled and State.moveSpeed or 16
            pcall(function() currentHumanoid:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end)
end

function Runtime.BeginPathControl(root)
    local humanoid = root and root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    local controllerReady = Runtime.pathControlledRoot == root
        and Runtime.pathHumanoid == humanoid
        and Runtime.pathAttachment
        and Runtime.pathAttachment.Parent == root
        and Runtime.pathVelocity
        and Runtime.pathVelocity.Parent == root
        and Runtime.pathOrientation
        and Runtime.pathOrientation.Parent == root
    if controllerReady then return true end
    if Runtime.pathControlledRoot or Runtime.pathAttachment or Runtime.pathVelocity or Runtime.pathOrientation then
        Runtime.EndPathControl()
    end
    Runtime.pathControlledRoot = root
    Runtime.pathHumanoid = humanoid
    Runtime.pathOriginalAutoRotate = humanoid.AutoRotate
    Runtime.pathOriginalWalkSpeed = humanoid.WalkSpeed
    Runtime.pathOriginalAnchored = root.Anchored
    Runtime.pathRotation = root.CFrame - root.Position
    local animate = root.Parent:FindFirstChild("Animate")
    Runtime.pathAnimate = animate
    Runtime.pathOriginalAnimateDisabled = animate and animate.Disabled or nil
    if animate then animate.Disabled = true end
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0.1) end)
    end
    local idleAnimationId = nil
    if animate then
        local idleFolder = animate:FindFirstChild("idle") or animate:FindFirstChild("Idle")
        local configuredIdle = idleFolder and idleFolder:FindFirstChildWhichIsA("Animation", true)
        idleAnimationId = configuredIdle and configuredIdle.AnimationId or nil
    end
    if not idleAnimationId or idleAnimationId == "" then
        idleAnimationId = humanoid.RigType == Enum.HumanoidRigType.R6
            and "rbxassetid://180435571" or "rbxassetid://507766666"
    end
    local idleAnimation = Instance.new("Animation")
    idleAnimation.Name = "BoogaPathIdle"
    idleAnimation.AnimationId = idleAnimationId
    local animator = humanoid:FindFirstChildOfClass("Animator")
    local loaded, idleTrack = pcall(function()
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end
        return animator:LoadAnimation(idleAnimation)
    end)
    if loaded and idleTrack then
        idleTrack.Priority = Enum.AnimationPriority.Idle
        idleTrack.Looped = true
        idleTrack:Play(0.12, 1, 1)
        Runtime.pathIdleTrack = idleTrack
        Runtime.pathIdleAnimation = idleAnimation
    else
        idleAnimation:Destroy()
    end
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
    end
    Runtime.SetPlayerControlsEnabled(false)
    humanoid.Sit = false
    humanoid.AutoRotate = false
    humanoid.WalkSpeed = 0
    root.Anchored = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    for _, name in ipairs({"BoogaPathAttachment", "BoogaPathVelocity", "BoogaPathOrientation"}) do
        local stale = root:FindFirstChild(name)
        if stale then stale:Destroy() end
    end
    local attachment = Instance.new("Attachment")
    attachment.Name = "BoogaPathAttachment"
    attachment.Parent = root
    local velocity = Instance.new("LinearVelocity")
    velocity.Name = "BoogaPathVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    velocity.VectorVelocity = Vector3.zero
    pcall(function() velocity.ForceLimitsEnabled = false end)
    pcall(function() velocity.MaxForce = math.huge end)
    velocity.Parent = root
    local orientation = Instance.new("AlignOrientation")
    orientation.Name = "BoogaPathOrientation"
    orientation.Attachment0 = attachment
    orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    orientation.CFrame = Runtime.pathRotation
    orientation.RigidityEnabled = true
    orientation.Responsiveness = 200
    orientation.MaxTorque = math.huge
    orientation.Parent = root
    Runtime.pathAttachment = attachment
    Runtime.pathVelocity = velocity
    Runtime.pathOrientation = orientation
    return true
end

function Runtime.GetPathObstacleLift(root, horizontalDirection)
    if horizontalDirection.Magnitude <= 0.01 then return nil end
    local excluded = {root.Parent}
    if Runtime.pathFolder then table.insert(excluded, Runtime.pathFolder) end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = excluded
    rayParams.IgnoreWater = true
    pcall(function() rayParams.RespectCanCollide = true end)

    local forward = horizontalDirection.Unit * 4.25
    local sideways = Vector3.new(-horizontalDirection.Z, 0, horizontalDirection.X)
    local lowerOrigin = root.Position - Vector3.new(0, 2.1, 0)
    local upperOrigin = root.Position + Vector3.new(0, 0.75, 0)
    local lowerBlocked, upperBlocked = false, false
    for _, lateral in ipairs({-0.85, 0, 0.85}) do
        local sideOffset = sideways * lateral
        local lowerHit = workspace:Raycast(lowerOrigin + sideOffset, forward, rayParams)
        local upperHit = workspace:Raycast(upperOrigin + sideOffset, forward, rayParams)
        if lowerHit then lowerBlocked = true end
        if upperHit then upperBlocked = true end
    end
    if upperBlocked then
        Runtime.pathObstacleLiftSpeed = 0
        Runtime.pathObstacleLiftUntil = 0
    elseif lowerBlocked then
        Runtime.pathObstacleLiftSpeed = 4.5
        Runtime.pathObstacleLiftUntil = os.clock() + 0.16
    end
    if os.clock() < Runtime.pathObstacleLiftUntil then
        return Runtime.pathObstacleLiftSpeed
    end
    return nil
end

function Runtime.GetPathFloorOffset(root)
    if not root then return nil end
    local excluded = {root.Parent}
    if Runtime.pathFolder then table.insert(excluded, Runtime.pathFolder) end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = excluded
    rayParams.IgnoreWater = true
    pcall(function() rayParams.RespectCanCollide = true end)
    local humanoid = Runtime.pathHumanoid
        or (root and root.Parent and root.Parent:FindFirstChildOfClass("Humanoid"))
    local hipHeight = humanoid and tonumber(humanoid.HipHeight) or 2
    local halfHeight = root and root.Size and root.Size.Y * 0.5 or 1
    local clearance = hipHeight + halfHeight + Runtime.pathHoverOffset
    local hit = workspace:Raycast(
        root.Position + Vector3.new(0, 0.25, 0),
        Vector3.new(0, -16, 0),
        rayParams
    )
    if hit and hit.Normal.Y > 0.35 then
        return root.Position.Y - (hit.Position.Y + clearance)
    end
    local upperHit = workspace:Raycast(
        root.Position - Vector3.new(0, 0.25, 0),
        Vector3.new(0, 16, 0),
        rayParams
    )
    if upperHit and upperHit.Normal.Y > 0.35 then
        return root.Position.Y - (upperHit.Position.Y + clearance)
    end
    return nil
end

function Runtime.DrivePath(root, targetPosition)
    Runtime.pathTargetPosition = targetPosition
    local speed = 19
    Runtime.pathSpeed = speed

    if not Runtime.BeginPathControl(root) then return end
    local offset = targetPosition - root.Position
    if offset.Magnitude <= 0.01 then
        if Runtime.pathVelocity and Runtime.pathVelocity.Parent then
            Runtime.pathVelocity.VectorVelocity = Vector3.zero
        end
        return
    end

    local velocity = offset.Unit * speed
    local horizontal = Vector3.new(offset.X, 0, offset.Z)
    local horizontalDirection = horizontal.Magnitude > 0.01 and horizontal.Unit or root.CFrame.LookVector
    if horizontal.Magnitude > 0.01 then
        local obstacleLift = Runtime.GetPathObstacleLift(root, horizontalDirection)
        if obstacleLift and obstacleLift > velocity.Y then
            local upwardSpeed = math.min(obstacleLift, speed - 0.1)
            local forwardSpeed = math.sqrt(math.max(
                speed * speed - upwardSpeed * upwardSpeed,
                0
            ))
            velocity = horizontalDirection * forwardSpeed + Vector3.new(0, upwardSpeed, 0)
        end
    end
    local floorOffset = Runtime.GetPathFloorOffset(root)
    if not floorOffset then
        Runtime.pathGroundPullActive = false
    elseif floorOffset < -0.35 then
        Runtime.pathGroundPullActive = false
        local upwardSpeed = math.min(8, 2 + (-floorOffset) * 4)
        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        local hDir = horizontalVelocity.Magnitude > 0.01
            and horizontalVelocity.Unit
            or (horizontal.Magnitude > 0.01 and horizontal.Unit or root.CFrame.LookVector)
        if hDir then
            local forwardSpeed = math.sqrt(math.max(
                speed * speed - upwardSpeed * upwardSpeed,
                0
            ))
            velocity = hDir * forwardSpeed + Vector3.new(0, upwardSpeed, 0)
        else
            velocity = Vector3.new(0, upwardSpeed, 0)
        end
    elseif Runtime.pathGroundPullActive then
        if floorOffset <= 0.1 then Runtime.pathGroundPullActive = false end
    elseif floorOffset > 0.45 and velocity.Y <= 1 then
        Runtime.pathGroundPullActive = true
    end
    if Runtime.pathGroundPullActive and floorOffset then
        local downwardSpeed = math.min(12, 6 + math.max(floorOffset - 0.45, 0) * 4)
        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        local hDir = horizontalVelocity.Magnitude > 0.01
            and horizontalVelocity.Unit
            or (horizontal.Magnitude > 0.01 and horizontal.Unit or root.CFrame.LookVector)
        if hDir then
            local forwardSpeed = math.sqrt(math.max(
                speed * speed - downwardSpeed * downwardSpeed,
                0
            ))
            velocity = hDir * forwardSpeed + Vector3.new(0, -downwardSpeed, 0)
        else
            velocity = Vector3.new(0, -downwardSpeed, 0)
        end
    end

    if Runtime.pathVelocity and Runtime.pathVelocity.Parent then
        Runtime.pathVelocity.VectorVelocity = velocity
    end
end

function Runtime.NearestPathIndex(position)
    local closestIndex, closestDistance = 1, math.huge
    for index, point in ipairs(Runtime.GetPathPoints()) do
        local distance = (position - Vector3.new(point.x, point.y, point.z)).Magnitude
        if distance < closestDistance then
            closestIndex = index
            closestDistance = distance
        end
    end
    return closestIndex
end

function Runtime.DestroyPathDots()
    if Runtime.pathFolder then
        Runtime.pathFolder:Destroy()
        Runtime.pathFolder = nil
    end
    local stale = workspace:FindFirstChild(Runtime.pathFolderName)
    if stale then stale:Destroy() end
end

function Runtime.CreatePathDots()
    Runtime.DestroyPathDots()
    local points = Runtime.RebuildPathPoints()
    local folder = Instance.new("Folder")
    folder.Name = Runtime.pathFolderName
    folder.Parent = workspace
    Runtime.pathFolder = folder

    for index, point in ipairs(points) do
        local dot = Instance.new("Part")
        dot.Name = string.format("PathDot_%03d", index)
        dot:SetAttribute("PathSource", point.source or "base")
        dot:SetAttribute("PathKey", tostring(point.key or point.originalIndex or index))
        dot:SetAttribute("PathRuntimeIndex", index)
        dot.Shape = Enum.PartType.Ball
        dot.Size = Vector3.new(0.82, 0.82, 0.82)
        dot.CFrame = CFrame.new(point.x, point.y, point.z)
        dot.Anchored = true
        dot.CanCollide = false
        dot.CanTouch = false
        dot.CanQuery = State.pathEditingMode == true
        dot.CastShadow = false
        dot.Material = Enum.Material.Neon
        dot.Color = Color3.fromRGB(245, 245, 245)
        dot.Transparency = 0.04
        dot.Parent = folder

        local nameGui = Instance.new("BillboardGui")
        nameGui.Name = "PointName"
        nameGui.Adornee = dot
        nameGui.Size = UDim2.fromOffset(92, 18)
        nameGui.StudsOffset = Vector3.new(0, 0.95, 0)
        nameGui.AlwaysOnTop = true
        nameGui.MaxDistance = 1000
        nameGui.LightInfluence = 0
        nameGui.Parent = dot

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.fromScale(1, 1)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = string.format("Dot %03d", index)
        nameLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
        nameLabel.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
        nameLabel.TextStrokeTransparency = 0.35
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 10
        nameLabel.Parent = nameGui

        local glow = Instance.new("PointLight")
        glow.Color = Color3.fromRGB(245, 245, 245)
        glow.Brightness = 1.35
        glow.Range = 7
        glow.Shadows = false
        glow.Parent = dot
    end
end

function Runtime.PathProfilePath(name)
    return Runtime.pathConfigFolder .. "/" .. Runtime.SafeConfigName(name) .. ".json"
end

function Runtime.ListPathProfiles(includeBuiltIn)
    local names, seen = {}, {}
    if includeBuiltIn ~= false then
        table.insert(names, "built-in")
        seen["built-in"] = true
    end
    if not Runtime.fsAvailable or type(listfiles) ~= "function" then return names end
    Runtime.EnsureFolders()
    pcall(function()
        for _, path in ipairs(listfiles(Runtime.pathConfigFolder)) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name and not seen[name] and (includeBuiltIn ~= false or name ~= "built-in") then
                seen[name] = true
                table.insert(names, name)
            end
        end
    end)
    table.sort(names, function(a, b)
        if a == "built-in" then return true end
        if b == "built-in" then return false end
        return string.lower(a) < string.lower(b)
    end)
    return names
end

function Runtime.SetPathProfileStatus(text)
    if UI.PathProfileStatus then UI.PathProfileStatus.Text = tostring(text or "") end
end

function Runtime.FindAddedPathPoint(key)
    for index, point in ipairs(type(State.pathAddedPoints) == "table" and State.pathAddedPoints or {}) do
        if type(point) == "table" and tostring(point.id) == tostring(key) then
            return point, index
        end
    end
    return nil, nil
end

function Runtime.GetSelectedPathPoint()
    local source, key = Runtime.pathSelectedSource, Runtime.pathSelectedKey
    if source == "base" then
        local index = tonumber(key)
        local base = index and PATH_POINTS[index]
        if not base then return nil end
        local edit = Runtime.GetPathEdit(index)
        return {
            x = type(edit) == "table" and tonumber(edit.x) or nil or base.x,
            y = type(edit) == "table" and tonumber(edit.y) or nil or base.y,
            z = type(edit) == "table" and tonumber(edit.z) or nil or base.z,
            wait = type(edit) == "table" and tonumber(edit.wait) or nil or tonumber(base.wait) or 0,
            source = source,
            key = tostring(index)
        }
    elseif source == "added" then
        local point = Runtime.FindAddedPathPoint(key)
        if not point then return nil end
        return {
            x = tonumber(point.x) or 0,
            y = tonumber(point.y) or 0,
            z = tonumber(point.z) or 0,
            wait = tonumber(point.wait) or 0,
            source = source,
            key = tostring(point.id)
        }
    end
    return nil
end

function Runtime.UpdatePathEditorInputs()
    local point = Runtime.GetSelectedPathPoint()
    if not point then
        if UI.PathSelectedLabel then UI.PathSelectedLabel.Text = "No dot selected" end
        if UI.PathEditorStatus then
            UI.PathEditorStatus.Text = State.pathEditingMode and "Click a visible dot to select it." or "Enable Editing Mode to select dots."
        end
        return
    end
    if UI.PathSelectedLabel then
        local dotIndex = Runtime.pathSelectedDot and Runtime.pathSelectedDot:GetAttribute("PathRuntimeIndex")
        UI.PathSelectedLabel.Text = "Selected: Dot " .. string.format("%03d", tonumber(dotIndex) or 0)
    end
    if UI.Inputs.pathEditorX then UI.Inputs.pathEditorX.Text = tostring(point.x) end
    if UI.Inputs.pathEditorY then UI.Inputs.pathEditorY.Text = tostring(point.y) end
    if UI.Inputs.pathEditorZ then UI.Inputs.pathEditorZ.Text = tostring(point.z) end
    if UI.Inputs.pathEditorWait then UI.Inputs.pathEditorWait.Text = tostring(point.wait) end
    if UI.PathEditorStatus then UI.PathEditorStatus.Text = "Drag an arrow or edit the values, then apply." end
end

function Runtime.ClearPathSelection()
    Runtime.pathSelectedDot = nil
    Runtime.pathSelectedSource = nil
    Runtime.pathSelectedKey = nil
    Runtime.pathHandleStart = nil
    if UI.PathHandles then UI.PathHandles.Adornee = nil end
    if UI.PathSelection then UI.PathSelection.Adornee = nil end
    Runtime.UpdatePathEditorInputs()
end

function Runtime.SelectPathDot(dot)
    if not State.pathEditingMode or not dot or not dot.Parent then return end
    local source = dot:GetAttribute("PathSource")
    local key = dot:GetAttribute("PathKey")
    if not source or not key then return end
    Runtime.pathSelectedDot = dot
    Runtime.pathSelectedSource = tostring(source)
    Runtime.pathSelectedKey = tostring(key)
    if UI.PathHandles then UI.PathHandles.Adornee = dot end
    if UI.PathSelection then UI.PathSelection.Adornee = dot end
    Runtime.UpdatePathEditorInputs()
end

function Runtime.FindPathDot(source, key)
    if not Runtime.pathFolder then return nil end
    for _, dot in ipairs(Runtime.pathFolder:GetChildren()) do
        if dot:IsA("BasePart") and tostring(dot:GetAttribute("PathSource")) == tostring(source)
            and tostring(dot:GetAttribute("PathKey")) == tostring(key) then
            return dot
        end
    end
    return nil
end

function Runtime.RefreshPathEditorWorld(source, key, restart)
    Runtime.RebuildPathPoints()
    if State.showPath or State.pathEditingMode then
        Runtime.CreatePathDots()
    else
        Runtime.DestroyPathDots()
    end
    if restart and State.startPath then Runtime.RestartPath() end
    task.defer(function()
        if State.pathEditingMode and source and key then
            Runtime.SelectPathDot(Runtime.FindPathDot(source, key))
        else
            Runtime.ClearPathSelection()
        end
    end)
end

function Runtime.CommitSelectedPathPoint(position, waitTime)
    local source, key = Runtime.pathSelectedSource, Runtime.pathSelectedKey
    if not source or not key or not position then return end
    waitTime = math.max(0, tonumber(waitTime) or 0)
    if source == "base" then
        local index = tonumber(key)
        if not index or not PATH_POINTS[index] then return end
        State.pathEdits[index] = nil
        State.pathEdits[tostring(index)] = {
            x = position.X, y = position.Y, z = position.Z, wait = waitTime
        }
    elseif source == "added" then
        local point = Runtime.FindAddedPathPoint(key)
        if not point then return end
        point.x, point.y, point.z, point.wait = position.X, position.Y, position.Z, waitTime
    end
    Runtime.RefreshPathEditorWorld(source, key, true)
end

function Runtime.ApplySelectedPathValues()
    if not Runtime.GetSelectedPathPoint() then return end
    local x = tonumber(UI.Inputs.pathEditorX and UI.Inputs.pathEditorX.Text)
    local y = tonumber(UI.Inputs.pathEditorY and UI.Inputs.pathEditorY.Text)
    local z = tonumber(UI.Inputs.pathEditorZ and UI.Inputs.pathEditorZ.Text)
    local waitTime = tonumber(UI.Inputs.pathEditorWait and UI.Inputs.pathEditorWait.Text)
    if not x or not y or not z or not waitTime then
        Runtime.SetPathProfileStatus("Enter valid X, Y, Z, and Wait values.")
        return
    end
    Runtime.CommitSelectedPathPoint(Vector3.new(x, y, z), waitTime)
end

function Runtime.AddPathPoint(position)
    if not position then return end
    if type(State.pathAddedPoints) ~= "table" then State.pathAddedPoints = {} end
    local id = Services.HttpService:GenerateGUID(false)
    table.insert(State.pathAddedPoints, {id = id, x = position.X, y = position.Y, z = position.Z, wait = 0})
    Runtime.RefreshPathEditorWorld("added", id, true)
end

function Runtime.AddPathPointAtCharacter()
    local root = Runtime.GetRoot()
    if root then Runtime.AddPathPoint(root.Position) end
end

function Runtime.BeginAddPathPointAtClick()
    if not State.pathEditingMode then Runtime.SetToggle("pathEditingMode", true) end
    Runtime.pathAddClickMode = true
    if UI.PathAddClickButton then UI.PathAddClickButton.Text = "Click anywhere in the world..." end
end

function Runtime.DeleteSelectedPathPoint()
    local source, key = Runtime.pathSelectedSource, Runtime.pathSelectedKey
    if not source or not key then return end
    if source == "base" then
        Runtime.SetPathProfileStatus("Built-in dots cannot be deleted; move them instead.")
        return
    elseif source == "added" then
        local _, index = Runtime.FindAddedPathPoint(key)
        if index then table.remove(State.pathAddedPoints, index) end
    end
    Runtime.RefreshPathEditorWorld(nil, nil, true)
end

function Runtime.SavePathProfile()
    if not Runtime.fsAvailable then return Runtime.SetPathProfileStatus("File functions are unavailable.") end
    Runtime.EnsureFolders()
    local name = Runtime.SafeConfigName(UI.Inputs.pathProfileName and UI.Inputs.pathProfileName.Text or State.pathProfileName)
    State.pathProfileName = name
    local ok = pcall(function()
        writefile(Runtime.PathProfilePath(name), Services.HttpService:JSONEncode({
            pathEdits = State.pathEdits,
            pathAddedPoints = State.pathAddedPoints
        }))
    end)
    Runtime.SetPathProfileStatus(ok and ("Saved path: " .. name) or "Path save failed.")
end

function Runtime.LoadPathProfile(name, quiet)
    if not Runtime.fsAvailable then return false end
    Runtime.EnsureFolders()
    name = Runtime.SafeConfigName(name or (UI.Inputs.pathProfileName and UI.Inputs.pathProfileName.Text) or State.pathProfileName)
    local ok, data = pcall(function()
        local path = Runtime.PathProfilePath(name)
        if not isfile(path) then return nil end
        return Services.HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        if not quiet then Runtime.SetPathProfileStatus("Path not found: " .. name) end
        return false
    end
    State.pathEdits = type(data.pathEdits) == "table" and data.pathEdits or {}
    State.pathAddedPoints = type(data.pathAddedPoints) == "table" and data.pathAddedPoints or {}
    State.pathProfileName = name
    if UI.Inputs.pathProfileName then UI.Inputs.pathProfileName.Text = name end
    Runtime.RefreshPathEditorWorld(nil, nil, true)
    if not quiet then Runtime.SetPathProfileStatus("Loaded path: " .. name) end
    return true
end

function Runtime.SetDefaultPathProfile(selectedName)
    if not Runtime.fsAvailable then return end
    local name = Runtime.SafeConfigName(selectedName or (UI.Inputs.pathProfileName and UI.Inputs.pathProfileName.Text) or State.pathProfileName)
    if not isfile(Runtime.PathProfilePath(name)) then
        Runtime.SetPathProfileStatus("Save this path before setting it as default.")
        return
    end
    pcall(function()
        writefile(Runtime.pathDefaultFile, Services.HttpService:JSONEncode({name = name}))
    end)
    Runtime.LoadPathProfile(name, true)
    Runtime.SetPathProfileStatus("Default path: " .. name)
end

function Runtime.DeletePathProfile(selectedName)
    if not Runtime.fsAvailable or type(delfile) ~= "function" then return end
    local name = Runtime.SafeConfigName(selectedName or (UI.Inputs.pathProfileName and UI.Inputs.pathProfileName.Text) or State.pathProfileName)
    if name == "built-in" then
        Runtime.SetPathProfileStatus("The built-in path cannot be deleted.")
        return
    end
    UI.AskConfirm("Delete path '" .. name .. "'?", function()
        local path = Runtime.PathProfilePath(name)
        if isfile(path) then pcall(function() delfile(path) end) end
        local defaultName = "built-in"
        pcall(function()
            local marker = Services.HttpService:JSONDecode(readfile(Runtime.pathDefaultFile))
            defaultName = tostring(marker.name or "built-in")
        end)
        if Runtime.SafeConfigName(defaultName) == name then
            pcall(function()
                writefile(Runtime.pathDefaultFile, Services.HttpService:JSONEncode({name = "built-in"}))
            end)
            Runtime.LoadPathProfile("built-in", true)
        end
        Runtime.SetPathProfileStatus("Deleted path: " .. name)
    end)
end

function Runtime.LoadDefaultPathProfile()
    if not Runtime.fsAvailable then return end
    Runtime.EnsureFolders()
    local name = "built-in"
    pcall(function()
        local marker = Services.HttpService:JSONDecode(readfile(Runtime.pathDefaultFile))
        if type(marker) == "table" then name = Runtime.SafeConfigName(marker.name) end
    end)
    if not Runtime.LoadPathProfile(name, true) then Runtime.LoadPathProfile("built-in", true) end
end

UI.PathEditorLeft = UI.MakeLane(UI.Pages.Path, 0)
UI.PathEditorRight = UI.MakeLane(UI.Pages.Path, 0.5)
UI.MakeToggle(UI.PathEditorLeft, "pathEditingMode", "Editing Mode")
UI.PathSelectedLabel = UI.MakeLabel(UI.PathEditorLeft, "No dot selected", 30)
UI.PathSelectedLabel.BackgroundColor3 = Colors.Panel
UI.PathSelectedLabel.BackgroundTransparency = 0
UI.PathSelectedLabel.TextXAlignment = Enum.TextXAlignment.Center
UI.Round(UI.PathSelectedLabel, 7)
UI.Stroke(UI.PathSelectedLabel, 0.5)
UI.PathApplyButton = UI.MakeButton(UI.PathEditorLeft, "Apply Selected Dot")
UI.PathApplyButton.MouseButton1Click:Connect(Runtime.ApplySelectedPathValues)
UI.PathCharacterButton = UI.MakeButton(UI.PathEditorLeft, "Add Dot at Character")
UI.PathCharacterButton.MouseButton1Click:Connect(Runtime.AddPathPointAtCharacter)
UI.PathAddClickButton = UI.MakeButton(UI.PathEditorLeft, "Add Dot Where I Click")
UI.PathAddClickButton.MouseButton1Click:Connect(Runtime.BeginAddPathPointAtClick)
UI.PathDeleteButton = UI.MakeButton(UI.PathEditorLeft, "Delete Selected Dot")
UI.PathDeleteButton.MouseButton1Click:Connect(Runtime.DeleteSelectedPathPoint)

UI.MakeInput(UI.PathEditorRight, "pathEditorX", "X", true, true)
UI.MakeInput(UI.PathEditorRight, "pathEditorY", "Y", true, true)
UI.MakeInput(UI.PathEditorRight, "pathEditorZ", "Z", true, true)
UI.MakeInput(UI.PathEditorRight, "pathEditorWait", "Wait Time", true, false)
UI.MakeInput(UI.PathEditorRight, "pathProfileName", "Path Name", false)

local PathProfileRowOne = Instance.new("Frame")
PathProfileRowOne.Size = UDim2.new(1, 0, 0, 30)
PathProfileRowOne.BackgroundTransparency = 1
PathProfileRowOne.Parent = UI.PathEditorRight
UI.PathSaveButton = UI.MakeButton(PathProfileRowOne, "Save")
UI.PathSaveButton.Size = UDim2.new(0.5, -3, 1, 0)
UI.PathSaveButton.MouseButton1Click:Connect(Runtime.SavePathProfile)
UI.PathLoadButton = UI.MakeButton(PathProfileRowOne, "Load")
UI.PathLoadButton.Size = UDim2.new(0.5, -3, 1, 0)
UI.PathLoadButton.Position = UDim2.new(0.5, 3, 0, 0)
UI.PathLoadButton.MouseButton1Click:Connect(function()
    UI.OpenSelector("pathProfileName", "Load Path", Runtime.ListPathProfiles(true), false, function(value)
        Runtime.LoadPathProfile(value)
    end)
end)

local PathProfileRowTwo = Instance.new("Frame")
PathProfileRowTwo.Size = UDim2.new(1, 0, 0, 30)
PathProfileRowTwo.BackgroundTransparency = 1
PathProfileRowTwo.Parent = UI.PathEditorRight
UI.PathProfileDeleteButton = UI.MakeButton(PathProfileRowTwo, "Delete")
UI.PathProfileDeleteButton.Size = UDim2.new(0.5, -3, 1, 0)
UI.PathProfileDeleteButton.MouseButton1Click:Connect(function()
    UI.OpenSelector("pathProfileName", "Delete Path", Runtime.ListPathProfiles(false), false, function(value)
        Runtime.DeletePathProfile(value)
    end)
end)
UI.PathDefaultButton = UI.MakeButton(PathProfileRowTwo, "Default")
UI.PathDefaultButton.Size = UDim2.new(0.5, -3, 1, 0)
UI.PathDefaultButton.Position = UDim2.new(0.5, 3, 0, 0)
UI.PathDefaultButton.MouseButton1Click:Connect(function()
    UI.OpenSelector("pathProfileName", "Default Path", Runtime.ListPathProfiles(true), false, function(value)
        Runtime.SetDefaultPathProfile(value)
    end)
end)

UI.PathEditorStatus = UI.MakeLabel(UI.PathEditorRight, "Enable Editing Mode to select dots.", 38)
UI.PathEditorStatus.TextWrapped = true
UI.PathEditorStatus.TextColor3 = Colors.Muted
UI.PathProfileStatus = UI.MakeLabel(UI.PathEditorRight, "", 30)
UI.PathProfileStatus.TextWrapped = true
UI.PathProfileStatus.TextColor3 = Colors.Muted

UI.PathHandles = Instance.new("Handles")
UI.PathHandles.Name = "BoogaPathHandles"
UI.PathHandles.Style = Enum.HandlesStyle.Movement
UI.PathHandles.Faces = Faces.new(
    Enum.NormalId.Top, Enum.NormalId.Bottom,
    Enum.NormalId.Left, Enum.NormalId.Right,
    Enum.NormalId.Front, Enum.NormalId.Back
)
UI.PathHandles.Color3 = Colors.Accent
UI.PathHandles.Transparency = 0.05
UI.PathHandles.Parent = ScreenGui

UI.PathSelection = Instance.new("SelectionBox")
UI.PathSelection.Name = "BoogaPathSelection"
UI.PathSelection.Color3 = Colors.Accent
UI.PathSelection.LineThickness = 0.04
UI.PathSelection.SurfaceTransparency = 0.85
UI.PathSelection.Parent = ScreenGui

table.insert(Runtime.connections, UI.PathHandles.MouseButton1Down:Connect(function()
    local dot = Runtime.pathSelectedDot
    if dot and dot.Parent then Runtime.pathHandleStart = dot.Position end
end))
table.insert(Runtime.connections, UI.PathHandles.MouseDrag:Connect(function(face, distance)
    local dot = Runtime.pathSelectedDot
    if not State.pathEditingMode or not dot or not dot.Parent or not Runtime.pathHandleStart then return end
    dot.Position = Runtime.pathHandleStart + Vector3.FromNormalId(face) * distance
    if UI.Inputs.pathEditorX then UI.Inputs.pathEditorX.Text = tostring(dot.Position.X) end
    if UI.Inputs.pathEditorY then UI.Inputs.pathEditorY.Text = tostring(dot.Position.Y) end
    if UI.Inputs.pathEditorZ then UI.Inputs.pathEditorZ.Text = tostring(dot.Position.Z) end
end))
table.insert(Runtime.connections, UI.PathHandles.MouseButton1Up:Connect(function()
    local dot = Runtime.pathSelectedDot
    Runtime.pathHandleStart = nil
    if dot and dot.Parent then
        Runtime.CommitSelectedPathPoint(dot.Position, UI.Inputs.pathEditorWait and UI.Inputs.pathEditorWait.Text)
    end
end))
table.insert(Runtime.connections, Runtime.playerMouse.Button1Down:Connect(function()
    if not State.pathEditingMode then return end
    if Runtime.pathAddClickMode then
        Runtime.pathAddClickMode = false
        if UI.PathAddClickButton then UI.PathAddClickButton.Text = "Add Dot Where I Click" end
        Runtime.AddPathPoint(Runtime.playerMouse.Hit.Position)
        return
    end
    local target = Runtime.playerMouse.Target
    if target and Runtime.pathFolder and target:IsDescendantOf(Runtime.pathFolder) then
        Runtime.SelectPathDot(target)
    end
end))

Runtime.UpdatePathEditorInputs()

function Runtime.EquipSlot(slot)
    local keys = {
        [1] = Enum.KeyCode.One, [2] = Enum.KeyCode.Two, [3] = Enum.KeyCode.Three,
        [4] = Enum.KeyCode.Four, [5] = Enum.KeyCode.Five, [6] = Enum.KeyCode.Six,
        [7] = Enum.KeyCode.Seven, [8] = Enum.KeyCode.Eight, [9] = Enum.KeyCode.Nine
    }
    local key = keys[tonumber(slot)]
    if not key then return end
    Services.VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.04)
    Services.VirtualInputManager:SendKeyEvent(false, key, false, game)
    Runtime.currentSlot = tonumber(slot)
end

function Runtime.RestartPath()
    Runtime.StopPathMovement()
    if Runtime.pathControlledRoot or Runtime.pathVelocity or Runtime.pathAttachment or Runtime.pathOrientation then
        Runtime.EndPathControl()
    end
    local root = Runtime.IsCharacterSpawned() and Runtime.GetRoot() or nil
    if root then Runtime.BeginPathControl(root) end
    Runtime.pathIndex = root and Runtime.NearestPathIndex(root.Position) or nil
    Runtime.pathReached = false
    Runtime.pathWaitUntil = 0
    Runtime.pathTargetPosition = nil
    Runtime.pathWrongDirectionSince = 0
    Runtime.pathRestartCount = Runtime.pathRestartCount + 1
end

function Runtime.ResetAntiStuck()
    local root = Runtime.GetRoot()
    Runtime.antiCheckpoint = root and root.Position or nil
    Runtime.antiCheckpointAt = os.clock()
end

function Runtime.UpdateChestButton()
    local selected = false
    if Runtime.listeningForChest then
        UI.SelectChest.Text = "Click a chest..."
        selected = true
    elseif Runtime.selectedChest and Runtime.selectedChest.Parent then
        UI.SelectChest.Text = "Gold Chest Selected"
        selected = true
    else
        UI.SelectChest.Text = "Select Gold Chest"
    end
    UI.SelectChest.TextStrokeTransparency = 1
    UI.SelectChest:SetAttribute("BoogaSelected", selected)
    UI.Tween(UI.SelectChest, 0.2, {
        BackgroundColor3 = selected and Colors.Accent or Colors.Control,
        TextColor3 = selected and Colors.EnabledText or Colors.Text
    })
end

function Runtime.ClearGoldMovers()
    for part, mover in pairs(Runtime.goldMovers) do
        if mover then pcall(function() mover:Destroy() end) end
        Runtime.goldMovers[part] = nil
        Runtime.goldLastPositions[part] = nil
        Runtime.goldLastDistances[part] = nil
        Runtime.goldLastProgressAt[part] = nil
    end
    table.clear(Runtime.goldReleaseUntil)
end

function Runtime.ClearChest(preserveSelection)
    Runtime.chestRestoreToken = Runtime.chestRestoreToken + 1
    Runtime.listeningForChest = false
    Runtime.selectedChest = nil
    if not preserveSelection then
        State.selectedChestEntityId = nil
        State.selectedChestName = ""
        State.selectedChestPosition = {}
    end
    Runtime.ClearGoldMovers()
    if Runtime.selectedChestHighlight then
        pcall(function() Runtime.selectedChestHighlight:Destroy() end)
        Runtime.selectedChestHighlight = nil
    end
    Runtime.UpdateChestButton()
end

function Runtime.FindChestFromTarget(target)
    local deployables = workspace:FindFirstChild("Deployables")
    local current = target
    while current and current ~= workspace do
        if current:IsA("Model") then
            local lower = string.lower(current.Name)
            if string.find(lower, "chest", 1, true)
                and current:FindFirstChild("Contents")
                and (not deployables or current:IsDescendantOf(deployables)) then
                return current
            end
        end
        current = current.Parent
    end
    return nil
end

function Runtime.SelectChest(chest)
    Runtime.ClearChest()
    Runtime.selectedChest = chest
    State.selectedChestEntityId = chest:GetAttribute("EntityID")
    State.selectedChestName = chest.Name
    local position = chest:GetPivot().Position
    State.selectedChestPosition = {x = position.X, y = position.Y, z = position.Z}
    local highlight = Instance.new("Highlight")
    highlight.Name = "BoogaUtilitySelectedChest"
    highlight.Adornee = chest
    highlight.FillColor = Colors.Accent
    highlight.FillTransparency = 0.76
    highlight.OutlineColor = Colors.Text
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = chest
    Runtime.selectedChestHighlight = highlight
    Runtime.UpdateChestButton()
end

function Runtime.RestoreChest()
    if not State.autoSelectChest and not State.lowEnd then return end
    local saved = State.selectedChestPosition
    local hasSavedPosition = type(saved) == "table"
        and type(saved.x) == "number"
        and type(saved.y) == "number"
        and type(saved.z) == "number"
    local hadSavedChest = State.selectedChestEntityId ~= nil
        or State.selectedChestName ~= ""
        or hasSavedPosition
    if not hadSavedChest then return end
    Runtime.chestRestoreToken = Runtime.chestRestoreToken + 1
    local token = Runtime.chestRestoreToken
    local expiresAt = os.clock() + 30
    local searchPosition = hasSavedPosition and Vector3.new(saved.x, saved.y, saved.z) or nil
    repeat
        if not Runtime.running or Runtime.chestRestoreToken ~= token then return end
        local root = Runtime.GetRoot()
        local originPosition = searchPosition or (root and root.Position)
        local closest = originPosition and Runtime.GetNearbyChest({Position = originPosition}, 20) or nil
        if closest then
            Runtime.SelectChest(closest)
            return
        end
        task.wait(0.25)
    until os.clock() >= expiresAt
end

function Runtime.SetCPUProperty(object, property, value)
    pcall(function() object[property] = value end)
end

function Runtime.DisableCPUGrass()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    Runtime.SetCPUProperty(terrain, "Decoration", false)
    if type(sethiddenproperty) == "function" then
        pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
    end
end

function Runtime.ApplyCPU()
    if State.cpuMode then Runtime.DisableCPUGrass() end
    Services.RunService:Set3dRenderingEnabled(true)
    UI.CpuCover.Visible = false
end

function Runtime.ReleaseFPSCap()
    if type(setfpscap) ~= "function" then return end
    local released = pcall(function()
        setfpscap(0)
    end)
    if not released then
        pcall(function()
            setfpscap(240)
        end)
    end
end

function Runtime.ApplyLowEnd()
    if type(setfpscap) ~= "function" then return end
    if State.lowEnd then
        pcall(function()
            setfpscap(20)
        end)
    else
        Runtime.ReleaseFPSCap()
    end
end


function Runtime.RememberUltraLowProperty(object, property)
    if not object then return false end

    local saved = Runtime.ultraLowOriginals[object]
    if not saved then
        saved = {}
        Runtime.ultraLowOriginals[object] = saved
    end

    if saved[property] == nil then
        local ok, value = pcall(function()
            return object[property]
        end)
        if not ok then return false end
        saved[property] = {value = value}
    end

    return true
end

function Runtime.SetUltraLowProperty(object, property, value)
    if not Runtime.RememberUltraLowProperty(object, property) then return end
    pcall(function()
        object[property] = value
    end)
end

function Runtime.IsOtherPlayerVisual(object)
    local character = object and object:FindFirstAncestorOfClass("Model")
    if not character then return false end
    local characterPlayer = Services.Players:GetPlayerFromCharacter(character)
    return characterPlayer ~= nil and characterPlayer ~= Player
end

function Runtime.ApplyUltraLowObject(object)
    if not State.ultraLow or not object then return end

    if object:IsA("BasePart") then
        Runtime.SetUltraLowProperty(object, "CastShadow", false)
        Runtime.SetUltraLowProperty(object, "Reflectance", 0)

        if object:IsA("MeshPart") then
            Runtime.SetUltraLowProperty(object, "RenderFidelity", Enum.RenderFidelity.Performance)
        end

        if Runtime.IsOtherPlayerVisual(object) then
            Runtime.SetUltraLowProperty(object, "LocalTransparencyModifier", 1)
        end
    elseif object:IsA("Decal") or object:IsA("Texture") then
        Runtime.SetUltraLowProperty(object, "Transparency", 1)
    elseif object:IsA("ParticleEmitter")
        or object:IsA("Trail")
        or object:IsA("Beam")
        or object:IsA("Fire")
        or object:IsA("Smoke")
        or object:IsA("Sparkles")
        or object:IsA("PointLight")
        or object:IsA("SpotLight")
        or object:IsA("SurfaceLight")
        or object:IsA("PostEffect")
        or object:IsA("Highlight")
        or object:IsA("Clouds") then
        Runtime.SetUltraLowProperty(object, "Enabled", false)
    elseif object:IsA("Sound") then
        Runtime.SetUltraLowProperty(object, "Volume", 0)
    elseif object:IsA("Atmosphere") then
        Runtime.SetUltraLowProperty(object, "Density", 0)
        Runtime.SetUltraLowProperty(object, "Haze", 0)
        Runtime.SetUltraLowProperty(object, "Glare", 0)
    elseif object:IsA("Humanoid") and Runtime.IsOtherPlayerVisual(object) then
        Runtime.SetUltraLowProperty(object, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None)
        Runtime.SetUltraLowProperty(object, "HealthDisplayType", Enum.HumanoidHealthDisplayType.AlwaysOff)
        Runtime.SetUltraLowProperty(object, "NameDisplayDistance", 0)
        Runtime.SetUltraLowProperty(object, "HealthDisplayDistance", 0)
    end
end

function Runtime.DisconnectUltraLowWatchers()
    for _, connection in ipairs(Runtime.ultraLowConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Runtime.ultraLowConnections)
end

function Runtime.RestoreUltraLow()
    Runtime.ultraLowToken = Runtime.ultraLowToken + 1
    Runtime.DisconnectUltraLowWatchers()

    for object, properties in pairs(Runtime.ultraLowOriginals) do
        if object then
            for property, wrapped in pairs(properties) do
                pcall(function()
                    object[property] = wrapped.value
                end)
            end
        end
    end
    Runtime.ultraLowOriginals = setmetatable({}, {__mode = "k"})

    local quality = Runtime.ultraLowQualityState
    if quality then
        if quality.userGameSettings then
            pcall(function()
                quality.userGameSettings.SavedQualityLevel = quality.savedQualityLevel
            end)
            pcall(function()
                quality.userGameSettings.MasterVolume = quality.masterVolume
            end)
        end
        if quality.rendering then
            pcall(function()
                quality.rendering.QualityLevel = quality.renderingQualityLevel
            end)
        end
    end
    Runtime.ultraLowQualityState = nil

    if State.showPath or State.pathEditingMode then
        Runtime.CreatePathDots()
    end
end

function Runtime.ApplyUltraLow()
    Runtime.ultraLowToken = Runtime.ultraLowToken + 1
    local token = Runtime.ultraLowToken
    Runtime.DisconnectUltraLowWatchers()

    if not State.ultraLow then
        Runtime.RestoreUltraLow()
        return
    end

    if not Runtime.ultraLowQualityState then
        local userGameSettings = nil
        local rendering = nil
        pcall(function()
            userGameSettings = UserSettings():GetService("UserGameSettings")
        end)
        pcall(function()
            rendering = settings().Rendering
        end)

        Runtime.ultraLowQualityState = {
            userGameSettings = userGameSettings,
            savedQualityLevel = userGameSettings and userGameSettings.SavedQualityLevel or nil,
            masterVolume = userGameSettings and userGameSettings.MasterVolume or nil,
            rendering = rendering,
            renderingQualityLevel = rendering and rendering.QualityLevel or nil
        }
    end

    local quality = Runtime.ultraLowQualityState
    if quality and quality.userGameSettings then
        pcall(function()
            quality.userGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end)
        pcall(function()
            quality.userGameSettings.MasterVolume = 0
        end)
    end
    if quality and quality.rendering then
        pcall(function()
            quality.rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    end

    local lighting = game:GetService("Lighting")
    Runtime.SetUltraLowProperty(lighting, "GlobalShadows", false)
    Runtime.SetUltraLowProperty(lighting, "ShadowSoftness", 0)
    Runtime.SetUltraLowProperty(lighting, "EnvironmentDiffuseScale", 0)
    Runtime.SetUltraLowProperty(lighting, "EnvironmentSpecularScale", 0)

    Runtime.SetUltraLowProperty(workspace, "GlobalWind", Vector3.zero)

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        Runtime.SetUltraLowProperty(terrain, "Decoration", false)
        Runtime.SetUltraLowProperty(terrain, "WaterWaveSize", 0)
        Runtime.SetUltraLowProperty(terrain, "WaterWaveSpeed", 0)
        Runtime.SetUltraLowProperty(terrain, "WaterReflectance", 0)
        Runtime.SetUltraLowProperty(terrain, "WaterTransparency", 1)
        if type(sethiddenproperty) == "function" then
            pcall(function()
                sethiddenproperty(terrain, "Decoration", false)
            end)
        end
    end

    Runtime.DestroyPathDots()

    table.insert(Runtime.ultraLowConnections, workspace.DescendantAdded:Connect(function(object)
        if State.ultraLow and Runtime.ultraLowToken == token then
            task.defer(Runtime.ApplyUltraLowObject, object)
        end
    end))

    table.insert(Runtime.ultraLowConnections, lighting.ChildAdded:Connect(function(object)
        if State.ultraLow and Runtime.ultraLowToken == token then
            task.defer(Runtime.ApplyUltraLowObject, object)
        end
    end))

    task.spawn(function()
        local processed = 0

        for _, object in ipairs(workspace:GetDescendants()) do
            if not Runtime.running or not State.ultraLow or Runtime.ultraLowToken ~= token then
                return
            end
            Runtime.ApplyUltraLowObject(object)
            processed = processed + 1
            if processed % 250 == 0 then task.wait() end
        end

        for _, object in ipairs(lighting:GetChildren()) do
            if not Runtime.running or not State.ultraLow or Runtime.ultraLowToken ~= token then
                return
            end
            Runtime.ApplyUltraLowObject(object)
        end
    end)
end

function Runtime.ApplyCamera()
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        local humanoid = Runtime.pathHumanoid
        if humanoid and humanoid.Parent then camera.CameraSubject = humanoid end
    end
end

function Runtime.OnToggle(key, enabled)
    if key == "showPath" then
        if enabled or State.pathEditingMode then Runtime.CreatePathDots() else Runtime.DestroyPathDots() end
    elseif key == "pathEditingMode" then
        Runtime.pathAddClickMode = false
        Runtime.ClearPathSelection()
        if enabled or State.showPath then Runtime.CreatePathDots() else Runtime.DestroyPathDots() end
    elseif key == "startPath" then
        if enabled then
            Runtime.pathSlotOneEquipped = false
            Runtime.pathSlotCharacter = nil
            Runtime.pathSlotReadyAt = 0
            Runtime.RestartPath()
            Runtime.ResetAntiStuck()
        else
            Runtime.pathSlotOneEquipped = false
            Runtime.pathSlotCharacter = nil
            Runtime.pathSlotReadyAt = 0
            if Runtime.freezeConnection then
                Runtime.freezeConnection:Disconnect()
                Runtime.freezeConnection = nil
            end
            Runtime.EndPathControl()
            Runtime.pathIndex = nil
        end
        Runtime.UpdateMovementStability()
    elseif key == "sfAutoMove" or key == "autoFarm" then
        if not State.sfAutoMove or not State.autoFarm then Runtime.CancelMotion("sunfruitFarm") end
    elseif key == "bfAutoMove" or key == "bfMasterFarm" then
        if not State.bfAutoMove or not State.bfMasterFarm then Runtime.CancelMotion("bloodfruitFarm") end
    elseif key == "cpuMode" then
        Runtime.ApplyCPU()
    elseif key == "lowEnd" then
        Runtime.ApplyLowEnd()
    elseif key == "ultraLow" then
        Runtime.ApplyUltraLow()
    elseif key == "lockCamera" then
        Runtime.ApplyCamera()
    elseif key == "autoSelectChest" then
        Runtime.chestRestoreToken = Runtime.chestRestoreToken + 1
        if enabled then task.spawn(Runtime.RestoreChest) end
    elseif key == "tweenToCoins" then
        Runtime.coinTweenToken = Runtime.coinTweenToken + 1
        if enabled then
            Runtime.coinTweenStarted = false
            Runtime.coinSpawnInvoked = false
        else
            Runtime.coinTweenActive = false
            Runtime.coinTweenStarted = false
            Runtime.coinSpawnInvoked = false
            Runtime.StopPathMovement()
            if State.startPath then
                local root = Runtime.GetRoot()
                Runtime.pathIndex = root and Runtime.NearestPathIndex(root.Position) or nil
                Runtime.pathReached = false
                Runtime.pathWaitUntil = 0
            else
                Runtime.EndPathControl()
            end
        end
    elseif key == "autoloadEnabled" then
        Runtime.WriteAutoload()
    elseif key == "walkSpeedEnabled" and not enabled then
        local root = Runtime.GetRoot()
        local humanoid = root and root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
    elseif key == "pauseNearPress" and not enabled and Runtime.freezeConnection then
        Runtime.freezeConnection:Disconnect()
        Runtime.freezeConnection = nil
    end
end

UI.SelectChest.MouseButton1Click:Connect(function()
    Runtime.listeningForChest = true
    Runtime.UpdateChestButton()
end)

table.insert(Runtime.connections, Runtime.playerMouse.Button1Down:Connect(function()
    if not Runtime.listeningForChest then return end
    local chest = Runtime.FindChestFromTarget(Runtime.playerMouse.Target)
    if chest then
        Runtime.SelectChest(chest)
    else
        Runtime.ClearChest()
    end
end))

UI.HideKeyButton.MouseButton1Click:Connect(function()
    Runtime.bindingKey = true
    UI.Refresh()
end)

function UI.SetMainVisible(visible)
    Runtime.mainAnimationToken = Runtime.mainAnimationToken + 1
    local token = Runtime.mainAnimationToken
    UI.mainShown = visible == true
    if visible then
        UI.Main.Visible = true
        UI.TweenStrokes(true, 0.24)
        UI.Tween(UI.Main, 0.24, {GroupTransparency = 0})
        UI.Tween(UI.MainScale, 0.24, {Scale = 1})
    else
        UI.TweenStrokes(false, 0.18)
        UI.Tween(UI.Main, 0.18, {GroupTransparency = 1})
        UI.Tween(UI.MainScale, 0.18, {Scale = 0.97})
        task.delay(0.18, function()
            if Runtime.mainAnimationToken == token and not UI.mainShown then
                UI.Main.Visible = false
            end
        end)
    end
end

table.insert(Runtime.connections, Services.UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.One then
        Runtime.currentSlot = 1
    elseif input.KeyCode == Enum.KeyCode.Two then
        Runtime.currentSlot = 2
    end
    if Runtime.bindingKey and input.KeyCode ~= Enum.KeyCode.Unknown then
        State.hideKey = input.KeyCode.Name
        Runtime.bindingKey = false
        UI.Refresh()
        return
    end
    if not processed and input.KeyCode.Name == State.hideKey then
        UI.SetMainVisible(not UI.mainShown)
    end
end))

function Runtime.ListConfigs()
    local names = {}
    if not Runtime.fsAvailable or type(listfiles) ~= "function" then return names end
    Runtime.EnsureFolders()
    pcall(function()
        for _, path in ipairs(listfiles(Runtime.configFolder)) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name then table.insert(names, name) end
        end
    end)
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
    return names
end

function Runtime.SerializableState()
    local copy = {}
    for key, value in pairs(State) do
        local pathState = key == "pathEdits" or key == "pathAddedPoints" or key == "pathProfileName" or key == "pathEditingMode"
        if not pathState and (type(value) == "boolean" or type(value) == "number" or type(value) == "string" or type(value) == "table") then
            copy[key] = value
        end
    end
    return copy
end

function Runtime.SaveConfig()
    if not Runtime.fsAvailable then
        UI.ConfigStatus.Text = "File functions are unavailable"
        return
    end
    Runtime.EnsureFolders()
    if UI.Inputs.configName then State.configName = UI.Inputs.configName.Text end
    State.configName = Runtime.SafeConfigName(State.configName)
    if State.autoloadConfig == "" then State.autoloadConfig = State.configName end
    local ok = pcall(function()
        writefile(Runtime.ConfigPath(State.configName), Services.HttpService:JSONEncode(Runtime.SerializableState()))
    end)
    UI.ConfigStatus.Text = ok and ("Saved: " .. State.configName) or "Save failed"
    if ok then
        State.loadConfig = State.configName
        State.deleteConfig = State.configName
    end
    Runtime.WriteAutoload()
    UI.Refresh()
end

function Runtime.ApplyLoadedConfig(data, name)
    Runtime.CancelMotion()
    if Runtime.pathControlledRoot then Runtime.EndPathControl() end
    if Runtime.freezeConnection then
        Runtime.freezeConnection:Disconnect()
        Runtime.freezeConnection = nil
    end
    for key, defaultValue in pairs(Defaults) do
        local pathState = key == "pathEdits" or key == "pathAddedPoints" or key == "pathProfileName" or key == "pathEditingMode"
        if not pathState and data[key] ~= nil and type(data[key]) == type(defaultValue) then
            State[key] = data[key]
        end
    end
    if data.selectedChestEntityId ~= nil then
        State.selectedChestEntityId = data.selectedChestEntityId
    end
    State.configName = name
    State.moveSpeed = math.clamp(tonumber(State.moveSpeed) or 19, 10, 19)
    Runtime.coinTweenToken = Runtime.coinTweenToken + 1
    Runtime.coinTweenActive = false
    Runtime.coinTweenStarted = false
    Runtime.coinSpawnInvoked = false
    Runtime.pathSlotOneEquipped = false
    Runtime.pathSlotCharacter = nil
    Runtime.pathSlotReadyAt = 0
    UI.Refresh()
    Runtime.RebuildPathPoints()
    if State.showPath then Runtime.CreatePathDots() else Runtime.DestroyPathDots() end
    if State.startPath then Runtime.RestartPath() else Runtime.EndPathControl() end
    Runtime.ResetAntiStuck()
    Runtime.ApplyCPU()
    Runtime.ApplyCamera()
    Runtime.UpdateMovementStability()
    Runtime.WriteAutoload()
    if not State.walkSpeedEnabled and not State.startPath then
        local root = Runtime.GetRoot()
        local humanoid = root and root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
    end
    local chestEntityId = State.selectedChestEntityId
    local chestName = State.selectedChestName
    local chestPosition = State.selectedChestPosition
    Runtime.ClearChest()
    State.selectedChestEntityId = chestEntityId
    State.selectedChestName = chestName
    State.selectedChestPosition = chestPosition
    task.defer(Runtime.RestoreChest)
end

function Runtime.LoadConfig()
    local name = Runtime.SafeConfigName(State.loadConfig)
    if State.loadConfig == "" then
        UI.ConfigStatus.Text = "Choose a config to load"
        return
    end
    local data = Runtime.ReadConfigData(name)
    if not data then
        UI.ConfigStatus.Text = "Config not found"
        return
    end
    Runtime.ApplyLoadedConfig(data, name)
    State.loadConfig = name
    UI.ConfigStatus.Text = "Loaded: " .. name
    UI.Refresh()
end

function Runtime.DeleteConfig()
    if State.deleteConfig == "" then
        UI.ConfigStatus.Text = "Choose a config to delete"
        return
    end
    local name = Runtime.SafeConfigName(State.deleteConfig)
    UI.AskConfirm("Delete config '" .. name .. "'?", function()
        local ok = false
        if Runtime.fsAvailable and type(delfile) == "function" then
            ok = pcall(function()
                local path = Runtime.ConfigPath(name)
                if isfile(path) then delfile(path) end
            end)
        end
        if State.autoloadConfig == name then
            State.autoloadConfig = ""
            State.autoloadEnabled = false
            Runtime.WriteAutoload()
        end
        State.deleteConfig = ""
        UI.ConfigStatus.Text = ok and ("Deleted: " .. name) or "Delete failed"
        UI.Refresh()
    end)
end

UI.SaveConfig.MouseButton1Click:Connect(Runtime.SaveConfig)
UI.LoadConfig.MouseButton1Click:Connect(function()
    UI.OpenSelector("loadConfig", "Load", Runtime.ListConfigs(), false, function()
        Runtime.LoadConfig()
    end)
end)
UI.DeleteConfig.MouseButton1Click:Connect(function()
    UI.OpenSelector("deleteConfig", "Delete", Runtime.ListConfigs(), false, function()
        Runtime.DeleteConfig()
    end)
end)
UI.AutoloadConfig.MouseButton1Click:Connect(function()
    local values = {"Disabled"}
    for _, name in ipairs(Runtime.ListConfigs()) do table.insert(values, name) end
    UI.OpenSelector("autoloadConfig", "Autoload", values, false, function(value)
        if value == "Disabled" then
            State.autoloadEnabled = false
            State.autoloadConfig = ""
        else
            State.autoloadEnabled = true
            State.autoloadConfig = value
        end
        Runtime.WriteAutoload()
        UI.Refresh()
    end)
end)

function Runtime.GetInventory()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
    local rightPanel = mainGui and mainGui:FindFirstChild("RightPanel")
    local inventory = rightPanel and rightPanel:FindFirstChild("Inventory")
    return inventory and inventory:FindFirstChild("List")
end

function Runtime.GetInventoryItemNames(allowedNames)
    local inventory = Runtime.GetInventory()
    if not inventory then return {} end
    local canonicalByNormalized = {}
    for _, name in ipairs(allowedNames or {}) do
        canonicalByNormalized[Runtime.Normalized and Runtime.Normalized(name) or string.lower(name)] = name
        for _, alias in ipairs(Runtime.itemAliases[name] or {}) do
            canonicalByNormalized[Runtime.Normalized and Runtime.Normalized(alias) or string.lower(alias)] = name
        end
    end
    local found, names = {}, {}
    for _, child in ipairs(inventory:GetChildren()) do
        if child:IsA("ImageLabel") then
            local normalized = Runtime.Normalized and Runtime.Normalized(child.Name) or string.lower(child.Name)
            local canonical = allowedNames and canonicalByNormalized[normalized] or child.Name
            if canonical and not found[canonical] then
                found[canonical] = true
                table.insert(names, canonical)
            end
        end
    end
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
    return names
end

function Runtime.GetBagLayout(itemName)
    local inventory = Runtime.GetInventory()
    if not inventory then return nil end
    for _, child in ipairs(inventory:GetChildren()) do
        if child:IsA("ImageLabel") then
            if Runtime.ItemNameMatches(itemName, child.Name) then return child.LayoutOrder end
        end
    end
    return nil
end

function Runtime.GetItemQuantity(guiItem)
    for _, key in ipairs({"Amount", "Quantity", "Count", "Stack"}) do
        local attribute = guiItem:GetAttribute(key)
        if tonumber(attribute) then return tonumber(attribute) end
        local valueObject = guiItem:FindFirstChild(key)
        if valueObject and valueObject:IsA("ValueBase") and tonumber(valueObject.Value) then
            return tonumber(valueObject.Value)
        end
    end
    for _, descendant in ipairs(guiItem:GetDescendants()) do
        if descendant:IsA("TextLabel") and descendant.Visible then
            local number = tonumber(tostring(descendant.Text):match("%d+"))
            if number then return number end
        end
    end
    return 1
end

function Runtime.Normalized(name)
    return string.lower(tostring(name)):gsub("[%s_%-]", "")
end

function Runtime.ItemNameMatches(wantedName, actualName)
    if Runtime.Normalized(wantedName) == Runtime.Normalized(actualName) then return true end
    for _, alias in ipairs(Runtime.itemAliases[wantedName] or {}) do
        if Runtime.Normalized(alias) == Runtime.Normalized(actualName) then return true end
    end
    return false
end

function Runtime.IsSelected(selection, name)
    if not selection then return false end
    if selection[name] then return true end
    local normalizedName = Runtime.Normalized(name)
    for selectedName, enabled in pairs(selection) do
        if enabled and (Runtime.Normalized(selectedName) == normalizedName
            or Runtime.ItemNameMatches(selectedName, name)) then return true end
    end
    return false
end

function Runtime.IsGold(item)
    local name = Runtime.Normalized(item and item.Name)
    return name == "gold" or name == "goldbar" or name == "rawgold" or name == "goldore"
end

function Runtime.GetPart(item)
    if not item then return nil end
    if item:IsA("BasePart") then return item end
    if item:IsA("Model") then return item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") end
    return item:FindFirstChildWhichIsA("BasePart")
end

function Runtime.NormalizePercent(value, maximum)
    value, maximum = tonumber(value), tonumber(maximum)
    if not value then return nil end
    if maximum and maximum > 0 then return math.clamp(value / maximum * 100, 0, 100) end
    if value >= 0 and value <= 1 then return value * 100 end
    return math.clamp(value, 0, 100)
end

function Runtime.GetHunger()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local targetGui = playerGui and (playerGui:FindFirstChild("MainGui") or playerGui)
    if targetGui then
        for _, object in ipairs(targetGui:GetDescendants()) do
            if object:IsA("TextLabel") and object.Visible and not object:FindFirstAncestor("FloatingBarsUI") then
                local text = string.lower(tostring(object.Text))
                if string.find(text, "hunger", 1, true) then
                    local current, maximum = text:match("(%d+%.?%d*)%s*/%s*(%d+%.?%d*)")
                    if current then return Runtime.NormalizePercent(current, maximum) end
                    local number = text:match("(%d+%.?%d*)")
                    if number then return tonumber(number) end
                    if object.Parent then
                        for _, sibling in ipairs(object.Parent:GetChildren()) do
                            if sibling:IsA("TextLabel") and sibling ~= object then
                                local siblingNumber = tostring(sibling.Text):match("^%s*(%d+%.?%d*)%s*$")
                                if siblingNumber then return tonumber(siblingNumber) end
                            end
                        end
                    end
                end
            end
        end
    end

    local folder = Player:FindFirstChild("PlayerFolder")
    local stats = folder and folder:FindFirstChild("Stats")
    local hunger = stats and stats:FindFirstChild("Hunger")
    if hunger and hunger:IsA("ValueBase") then
        local maximum = stats:FindFirstChild("MaxHunger")
        return Runtime.NormalizePercent(hunger.Value, maximum and maximum.Value)
    end
    local character = Player.Character
    if character and character:GetAttribute("Hunger") ~= nil then
        return Runtime.NormalizePercent(character:GetAttribute("Hunger"), character:GetAttribute("MaxHunger"))
    end
    return 100
end

function Runtime.GetPlantBoxes(root, range)
    local results = {}
    local deployables = workspace:FindFirstChild("Deployables")
    if not deployables then return results end
    for _, model in ipairs(deployables:GetChildren()) do
        if model:IsA("Model") and model.Name == "Plant Box" then
            local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            local entityId = model:GetAttribute("EntityID")
            if part and entityId then
                local distance = (part.Position - root.Position).Magnitude
                if distance <= range then
                    table.insert(results, {model = model, part = part, entityId = entityId, distance = distance})
                end
            end
        end
    end
    table.sort(results, function(a, b) return a.distance < b.distance end)
    return results
end

function Runtime.GetBushes(root, range, fruitFilter)
    local results, seen = {}, {}
    local function inspect(model)
        if seen[model] or not model:IsA("Model") then return end
        seen[model] = true
        local normalizedName = Runtime.Normalized(model.Name)
        local matched = false
        local selectedFruit = type(fruitFilter) == "string" and fruitFilter
            or (fruitFilter == true and "Sunfruit" or nil)
        for fruitName in pairs(FruitIDs) do
            if (not selectedFruit or fruitName == selectedFruit)
                and string.find(normalizedName, Runtime.Normalized(fruitName), 1, true) then
                matched = true
                break
            end
        end
        if not matched then return end
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        local entityId = model:GetAttribute("EntityID")
        if part and entityId then
            local distance = (part.Position - root.Position).Magnitude
            if distance <= range then
                table.insert(results, {model = model, part = part, entityId = entityId, distance = distance})
            end
        end
    end
    for _, model in ipairs(workspace:GetChildren()) do inspect(model) end
    local resources = workspace:FindFirstChild("Resources")
    if resources then for _, model in ipairs(resources:GetChildren()) do inspect(model) end end
    table.sort(results, function(a, b) return a.distance < b.distance end)
    return results
end

function Runtime.EncodeFloat16(value)
    value = tonumber(value) or 0

    if value ~= value then
        return 0x7E00
    end

    local sign = value < 0 and 0x8000 or 0
    value = math.abs(value)

    if value == math.huge then
        return sign + 0x7C00
    end

    if value == 0 then
        return sign
    end

    if value < 2 ^ -14 then
        local mantissa = math.floor(value / (2 ^ -24) + 0.5)
        if mantissa <= 0 then return sign end
        if mantissa >= 1024 then return sign + 0x0400 end
        return sign + mantissa
    end

    local exponent = math.floor(math.log(value, 2))
    if exponent > 15 then
        return sign + 0x7C00
    end

    local mantissa = math.floor(((value / (2 ^ exponent)) - 1) * 1024 + 0.5)
    if mantissa >= 1024 then
        exponent = exponent + 1
        mantissa = 0
        if exponent > 15 then
            return sign + 0x7C00
        end
    end

    return sign + (exponent + 15) * 1024 + mantissa
end

function Runtime.SendGoldSwing(entityIds)
    if #entityIds == 0 then return false end
    local root = Runtime.GetRoot()
    if not root then return false end
    local sent = pcall(function()
        local rx, ry, rz = root.CFrame:ToEulerAnglesXYZ()
        local packetParts = {
            string.char(0x00, 0x42),
            string.pack(
                "<fffHHH",
                root.CFrame.X, root.CFrame.Y, root.CFrame.Z,
                Runtime.EncodeFloat16(rx), Runtime.EncodeFloat16(ry), Runtime.EncodeFloat16(rz)
            ),
            string.pack("<H", #entityIds)
        }
        for _, entityId in ipairs(entityIds) do
            table.insert(packetParts, string.char(0x00))
            table.insert(packetParts, string.pack("<I4", entityId))
        end
        table.insert(packetParts, string.pack("<d", workspace:GetServerTimeNow()))
        ByteNetReliable:FireServer(buffer.fromstring(table.concat(packetParts)), nil)
    end)
    Runtime.auraLastSendOk = sent
    return sent
end

function Runtime.GetEntityId(object)
    if not object then return nil end
    local entityId = object:GetAttribute("EntityID")
    if entityId then return entityId end
    local part = object:IsA("BasePart") and object or object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
    return part and part:GetAttribute("EntityID") or nil
end

function Runtime.SendAutoOpenChest(chest)
    if not ByteNetReliable or type(buffer) ~= "table" or type(buffer.fromstring) ~= "function" then return false end
    local entityId = tonumber(Runtime.GetEntityId(chest))
    if not entityId then return false end
    local opened = pcall(function()
        ByteNetReliable:FireServer(buffer.fromstring(string.pack("<BBI4", 0x00, 0x6C, entityId)), nil)
    end)
    return opened
end

function Runtime.GetNearbyChest(root, range)
    local deployables = workspace:FindFirstChild("Deployables")
    if not root or not deployables then return nil end
    local closest, closestDistance = nil, range
    for _, chest in ipairs(deployables:GetChildren()) do
        if chest:IsA("Model") and chest:FindFirstChild("Contents") then
            local distance = (root.Position - chest:GetPivot().Position).Magnitude
            if distance <= closestDistance then
                closest, closestDistance = chest, distance
            end
        end
    end
    return closest
end

function Runtime.GetChestDropPosition(chest)
    if not chest or not chest.Parent then return nil end
    local contents = chest:FindFirstChild("Contents")
    if contents then
        local total, count = Vector3.zero, 0
        for _, item in ipairs(contents:GetChildren()) do
            local part = Runtime.GetPart(item)
            if part then
                total = total + part.Position
                count = count + 1
            end
        end
        if count > 0 then return total / count end
    end
    local ok, center = pcall(function()
        local boxCFrame = chest:GetBoundingBox()
        return boxCFrame.Position
    end)
    if ok and center then return center end
    return chest:GetPivot().Position
end

function Runtime.ReleaseGoldPart(part)
    local mover = Runtime.goldMovers[part]
    if mover then mover:Destroy() end
    Runtime.goldMovers[part] = nil
    Runtime.goldLastPositions[part] = nil
    Runtime.goldLastDistances[part] = nil
    Runtime.goldLastProgressAt[part] = nil
    Runtime.goldReleaseUntil[part] = os.clock() + 1.15
    pcall(function()
        part.AssemblyLinearVelocity = Vector3.new(0, -1.5, 0)
        part.AssemblyAngularVelocity = Vector3.zero
    end)
end

function Runtime.GetResourceAuraTargets(root, range)
    local results, allResources = {}, {}
    local resources = workspace:FindFirstChild("Resources")
    if resources then
        for _, resource in ipairs(resources:GetChildren()) do
            table.insert(allResources, resource)
        end
    end
    for _, resource in ipairs(workspace:GetChildren()) do
        if resource:IsA("Model") and resource.Name == "Gold Node" then
            table.insert(allResources, resource)
        end
    end
    for _, resource in ipairs(allResources) do
        if resource:IsA("Model") and resource:GetAttribute("EntityID") then
            local part = resource.PrimaryPart or resource:FindFirstChildWhichIsA("BasePart")
            if not part then continue end
            local distance = (part.Position - root.Position).Magnitude
            if distance <= range then
                table.insert(results, {
                    entityId = resource:GetAttribute("EntityID"),
                    distance = distance,
                    isGold = string.find(Runtime.Normalized(resource.Name), "gold", 1, true) ~= nil
                })
            end
        end
    end
    table.sort(results, function(a, b)
        if a.isGold ~= b.isGold then return a.isGold end
        return a.distance < b.distance
    end)
    return results
end

function Runtime.UpdatePath()
    if not State.startPath or Runtime.freezeConnection or Runtime.coinTweenActive then return end
    if not Runtime.IsCharacterSpawned() then
        Runtime.StopPathMovement()
        Runtime.pathIndex = nil
        if Runtime.pathControlledRoot then Runtime.EndPathControl() end
        return
    end
    local root = Runtime.GetRoot()
    if not root then
        Runtime.StopPathMovement()
        Runtime.pathIndex = nil
        return
    end
    if Runtime.pathControlledRoot ~= root then
        Runtime.StopPathMovement()
        Runtime.pathIndex = Runtime.NearestPathIndex(root.Position)
        Runtime.pathReached = false
        Runtime.pathWaitUntil = 0
    end
    if State.autoOpenChest and not Runtime.autoOpenChestFired and Runtime.GetNearbyChest(root, 15) then
        Runtime.StopPathMovement()
        return
    end
    Runtime.SetMovementStability(true)
    local pathPoints = Runtime.GetPathPoints()
    if type(Runtime.pathIndex) ~= "number" or not pathPoints[Runtime.pathIndex] then
        Runtime.pathIndex = Runtime.NearestPathIndex(root.Position)
        Runtime.pathReached = false
        Runtime.pathWaitUntil = 0
    end
    local point = pathPoints[Runtime.pathIndex]
    local target = Vector3.new(point.x, point.y + Runtime.pathHoverOffset, point.z)
    local distance = (root.Position - target).Magnitude

    if distance <= 1.15 then
        local waitTime = math.max(tonumber(point.wait) or 0, 0)
        if not Runtime.pathReached then
            if waitTime > 0 then Runtime.StopPathMovement() end
            if waitTime <= 0 then
                Runtime.pathIndex = (Runtime.pathIndex % #pathPoints) + 1
                Runtime.pathReached = false
                local nextPoint = pathPoints[Runtime.pathIndex]
                Runtime.DrivePath(root, Vector3.new(
                    nextPoint.x,
                    nextPoint.y + Runtime.pathHoverOffset,
                    nextPoint.z
                ))
            else
                Runtime.pathReached = true
                Runtime.pathWaitUntil = os.clock() + waitTime
            end
        elseif os.clock() >= Runtime.pathWaitUntil then
            Runtime.pathIndex = (Runtime.pathIndex % #pathPoints) + 1
            Runtime.pathReached = false
            local nextPoint = pathPoints[Runtime.pathIndex]
            Runtime.DrivePath(root, Vector3.new(
                nextPoint.x,
                nextPoint.y + Runtime.pathHoverOffset,
                nextPoint.z
            ))
        end
    else
        Runtime.pathReached = false
        Runtime.DrivePath(root, target)
    end
end

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if State.startPath then
            local ok = pcall(Runtime.UpdatePath)
            if not ok and Runtime.running and State.startPath then
                pcall(Runtime.RestartPath)
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.1)
        if not State.startPath then
            Runtime.pathSlotOneEquipped = false
            Runtime.pathSlotCharacter = nil
            Runtime.pathSlotReadyAt = 0
            continue
        end
        local character = Player.Character
        if Runtime.pathSlotCharacter ~= character then
            Runtime.pathSlotOneEquipped = false
            Runtime.pathSlotCharacter = character
            Runtime.pathSlotReadyAt = 0
        end
        if not Runtime.IsCharacterSpawned() then
            Runtime.pathSlotOneEquipped = false
            Runtime.pathSlotReadyAt = 0
            continue
        end
        if not Runtime.pathSlotOneEquipped and Runtime.pathSlotReadyAt == 0 then
            Runtime.pathSlotReadyAt = os.clock() + 3
        end
        if not Runtime.pathSlotOneEquipped and os.clock() >= Runtime.pathSlotReadyAt then
            Runtime.EquipSlot(1)
            if Runtime.running and State.startPath and Player.Character == character and Runtime.IsCharacterSpawned() then
                Runtime.pathSlotOneEquipped = true
                Runtime.pathSlotCharacter = character
                Runtime.pathSlotReadyAt = 0
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(1)
        if State.startPath and State.antiStuck then
            local root = Runtime.GetRoot()
            if root then
                if not Runtime.antiCheckpoint then Runtime.ResetAntiStuck() end
                if Runtime.antiCheckpoint and (root.Position - Runtime.antiCheckpoint).Magnitude >= 10 then
                    Runtime.ResetAntiStuck()
                end
                local elapsed = os.clock() - Runtime.antiCheckpointAt
                local remaining = math.max(0, math.ceil(40 - elapsed))
                UI.AntiStuckTimer.Text = "Anti-Stuck Timer: " .. tostring(remaining) .. "s"
                if elapsed >= 40 then
                    Runtime.RestartPath()
                    Runtime.ResetAntiStuck()
                end
            else
                UI.AntiStuckTimer.Text = "Anti-Stuck Timer: waiting"
            end
        elseif not State.antiStuck then
            UI.AntiStuckTimer.Text = "Anti-Stuck Timer: paused"
            Runtime.antiCheckpoint = nil
        else
            UI.AntiStuckTimer.Text = "Anti-Stuck Timer: waiting for path"
            Runtime.antiCheckpoint = nil
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if not State.autoFarm or not Packets or not Packets.InteractStructure then continue end
        local root = Runtime.GetRoot()
        if not root then continue end
        local itemId = (ItemIDS and (ItemIDS["Sunfruit"] or ItemIDS["Sun Fruit"])) or FruitIDs.Sunfruit
        if not itemId then continue end
        for _, box in ipairs(Runtime.GetPlantBoxes(root, 45)) do
            if not box.model:FindFirstChild("Seed") then
                pcall(function()
                    Packets.InteractStructure.send({entityID = box.entityId, itemID = itemId})
                end)
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if not State.autoFarm or not Packets or not Packets.Pickup then continue end
        local root = Runtime.GetRoot()
        if not root then continue end
        local bushes = Runtime.GetBushes(root, 45, true)
        for index = 1, #bushes do
            pcall(function() Packets.Pickup.send(bushes[index].entityId) end)
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.2)
        if not State.autoEat or not Packets or not Packets.UseBagItem or not Packets.UseBagItem.send then continue end
        local root = Runtime.GetRoot()
        local character = root and root.Parent
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local health = humanoid and Runtime.NormalizePercent(humanoid.Health, humanoid.MaxHealth) or 100
        local hunger = Runtime.GetHunger()
        if (health <= Runtime.autoEatThreshold or hunger <= Runtime.autoEatThreshold)
            and os.clock() - Runtime.lastEat >= 3 then
            local layout = Runtime.GetBagLayout("Sunfruit")
            if layout then
                local ok = pcall(function() Packets.UseBagItem.send(layout) end)
                if ok then Runtime.lastEat = os.clock() end
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.1)
        if not State.autoFarm or not State.sfAutoMove or State.startPath or Runtime.freezeConnection then continue end
        local root = Runtime.GetRoot()
        if not root then continue end
        local bushes = Runtime.GetBushes(root, 20, "Sunfruit")
        if #bushes > 0 then
            Runtime.Steer(root, bushes[1].part.CFrame + Vector3.new(0, 5, 0), "sunfruitFarm")
        else
            local targetBox = nil
            for _, box in ipairs(Runtime.GetPlantBoxes(root, 20)) do
                if not box.model:FindFirstChild("Seed") then targetBox = box break end
            end
            if targetBox then
                Runtime.Steer(root, targetBox.part.CFrame + Vector3.new(0, 5, 0), "sunfruitFarm")
            else
                Runtime.CancelMotion("sunfruitFarm")
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.1)
        if not State.bfMasterFarm or not State.bfAutoMove or State.startPath or Runtime.freezeConnection then continue end
        local root = Runtime.GetRoot()
        if not root then continue end
        local bushes = Runtime.GetBushes(root, 250, "Bloodfruit")
        if #bushes > 0 then
            Runtime.Steer(root, bushes[1].part.CFrame + Vector3.new(0, 5, 0), "bloodfruitFarm")
        else
            local targetBox = nil
            for _, box in ipairs(Runtime.GetPlantBoxes(root, 250)) do
                if not box.model:FindFirstChild("Seed") then targetBox = box break end
            end
            if targetBox then
                Runtime.Steer(root, targetBox.part.CFrame + Vector3.new(0, 5, 0), "bloodfruitFarm")
            else
                Runtime.CancelMotion("bloodfruitFarm")
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if not State.bfMasterFarm or not State.bfAutoHarvest or not Packets or not Packets.Pickup then continue end
        local root = Runtime.GetRoot()
        if not root then continue end
        for _, bush in ipairs(Runtime.GetBushes(root, 30, "Bloodfruit")) do
            pcall(function() Packets.Pickup.send(bush.entityId) end)
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if not State.bfMasterFarm or not State.bfAutoPlant
            or not Packets or not Packets.InteractStructure then continue end
        local root = Runtime.GetRoot()
        if not root then continue end
        for _, box in ipairs(Runtime.GetPlantBoxes(root, 30)) do
            if not box.model:FindFirstChild("Seed") then
                pcall(function()
                    Packets.InteractStructure.send({entityID = box.entityId, itemID = 94})
                end)
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.2)
        if not State.bfAutoEat or not Packets or not Packets.UseBagItem or not Packets.UseBagItem.send then continue end
        local root = Runtime.GetRoot()
        local character = root and root.Parent
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local hunger = Runtime.GetHunger()
        local health = humanoid and humanoid.Health or 100
        if (hunger < 80 or health < 80) and os.clock() - Runtime.lastBloodfruitEat > 3 then
            local layout = Runtime.GetBagLayout("Bloodfruit")
            if layout then
                local ok = pcall(function() Packets.UseBagItem.send(layout) end)
                if ok then Runtime.lastBloodfruitEat = os.clock() end
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.2)
        if not State.switchSlots then continue end
        local character = Player.Character
        local root = character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))
        if not root then continue end
        local closestDistance = math.huge
        local deployables = workspace:FindFirstChild("Deployables")
        if deployables then
            for _, item in pairs(deployables:GetChildren()) do
                if item.Name == "Plant Box" then
                    local distance = (root.Position - item:GetPivot().Position).Magnitude
                    if distance < closestDistance then closestDistance = distance end
                end
            end
        end
        if closestDistance <= 15 and Runtime.currentSlot ~= 2 then
            Runtime.EquipSlot(2)
            Runtime.currentSlot = 2
        elseif closestDistance > 15 and Runtime.currentSlot ~= 1 then
            Runtime.EquipSlot(1)
            Runtime.currentSlot = 1
        end
    end
end)

task.spawn(function()
    local sendCredit = 0
    local pressCursor = 1
    local lowEndSendsPerSecond = 1680
    local lowEndMaximumBurst = 192

    while Runtime.running do
        if not State.lowEnd then
            sendCredit = 0
            task.wait(0.03)

            if not State.coinPress or not Packets or not Packets.InteractStructure or not ItemIDS then
                continue
            end

            local root = Runtime.GetRoot()
            local deployables = workspace:FindFirstChild("Deployables")
            local goldId = ItemIDS.Gold or ItemIDS["Gold"]
            if not root or not deployables or not goldId then continue end

            local presses = {}
            for _, item in ipairs(deployables:GetChildren()) do
                if item.Name == "Coin Press" then
                    local distance = (root.Position - item:GetPivot().Position).Magnitude
                    local entityId = item:GetAttribute("EntityID")
                    if entityId and distance <= 24 then
                        table.insert(presses, {entityId = entityId, distance = distance})
                    end
                end
            end

            table.sort(presses, function(a, b) return a.distance < b.distance end)
            for index, press in ipairs(presses) do
                if index > 3 then break end
                for _ = 1, 28 do
                    pcall(function()
                        Packets.InteractStructure.send({
                            entityID = press.entityId,
                            itemID = goldId
                        })
                    end)
                end
            end

            continue
        end

        local deltaTime = Services.RunService.Heartbeat:Wait()

        if not State.coinPress or not Packets or not Packets.InteractStructure or not ItemIDS then
            sendCredit = 0
            continue
        end

        local root = Runtime.GetRoot()
        local deployables = workspace:FindFirstChild("Deployables")
        local goldId = ItemIDS.Gold or ItemIDS["Gold"]
        if not root or not deployables or not goldId then
            sendCredit = 0
            continue
        end

        local presses = {}
        for _, item in ipairs(deployables:GetChildren()) do
            if item.Name == "Coin Press" then
                local distance = (root.Position - item:GetPivot().Position).Magnitude
                local entityId = item:GetAttribute("EntityID")
                if entityId and distance <= 24 then
                    table.insert(presses, {entityId = entityId, distance = distance})
                end
            end
        end

        if #presses == 0 then
            sendCredit = 0
            continue
        end

        table.sort(presses, function(a, b) return a.distance < b.distance end)
        while #presses > 3 do
            table.remove(presses)
        end

        sendCredit = math.min(
            sendCredit + math.min(tonumber(deltaTime) or 0, 0.1) * lowEndSendsPerSecond,
            lowEndMaximumBurst
        )

        local sendCount = math.min(math.floor(sendCredit), lowEndMaximumBurst)
        if sendCount <= 0 then continue end
        sendCredit = sendCredit - sendCount

        for _ = 1, sendCount do
            if pressCursor > #presses then pressCursor = 1 end
            local press = presses[pressCursor]
            pressCursor = pressCursor + 1

            pcall(function()
                Packets.InteractStructure.send({
                    entityID = press.entityId,
                    itemID = goldId
                })
            end)
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.1)
        if not State.pauseNearPress or os.clock() < Runtime.nextFreezeAt then continue end
        local root = Runtime.GetRoot()
        local deployables = workspace:FindFirstChild("Deployables")
        if not root or not deployables then continue end
        local nearPress = false
        for _, item in ipairs(deployables:GetChildren()) do
            if item.Name == "Coin Press" and (root.Position - item:GetPivot().Position).Magnitude <= 15 then
                nearPress = true
                break
            end
        end
        if nearPress and not Runtime.freezeConnection then
            Runtime.CancelMotion()
            Runtime.StopPathMovement()
            local lockedCFrame = root.CFrame
            Runtime.nextFreezeAt = os.clock() + 60
            Runtime.freezeConnection = Services.RunService.Heartbeat:Connect(function()
                local currentCharacter = Player.Character
                local currentRoot = currentCharacter and currentCharacter.PrimaryPart
                if Runtime.running and State.pauseNearPress and currentRoot and currentRoot == root then
                    currentRoot.CFrame = lockedCFrame
                    currentRoot.AssemblyLinearVelocity = Vector3.zero
                    currentRoot.AssemblyAngularVelocity = Vector3.zero
                    local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
                    if currentHumanoid then
                        currentHumanoid.Jump = false
                        currentHumanoid:Move(Vector3.zero, false)
                        local state = currentHumanoid:GetState()
                        if state == Enum.HumanoidStateType.Jumping
                            or state == Enum.HumanoidStateType.Freefall then
                            pcall(function()
                                currentHumanoid:ChangeState(Enum.HumanoidStateType.Running)
                            end)
                        end
                    end
                else
                    if Runtime.freezeConnection then
                        Runtime.freezeConnection:Disconnect()
                        Runtime.freezeConnection = nil
                    end
                end
            end)
            task.delay(13, function()
                if Runtime.freezeConnection then
                    Runtime.freezeConnection:Disconnect()
                    Runtime.freezeConnection = nil
                end
            end)
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.25)
        if not State.autoSelectChest then continue end
        if Runtime.selectedChest and Runtime.selectedChest.Parent then continue end
        if Runtime.selectedChest and not Runtime.selectedChest.Parent then Runtime.ClearChest() end
        local root = Runtime.GetRoot()
        local closest = Runtime.GetNearbyChest(root, 15)
        if closest then Runtime.SelectChest(closest) end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if not State.autoOpenChest or Runtime.autoOpenChestFired then continue end
        local root = Runtime.GetRoot()
        local detectedChest = Runtime.GetNearbyChest(root, 15)
        if detectedChest then
            Runtime.autoOpenChestFired = true
            Runtime.SendAutoOpenChest(detectedChest)
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if not State.pickupChestGold or not Packets or not Packets.Pickup then continue end
        local root = Runtime.GetRoot()
        local deployables = workspace:FindFirstChild("Deployables")
        if not root or not deployables then continue end
        local picked = 0
        for _, chest in ipairs(deployables:GetChildren()) do
            if (chest.Name == "Chest" or chest.Name == "Reinforced Chest")
                and (root.Position - chest:GetPivot().Position).Magnitude <= 45 then
                local contents = chest:FindFirstChild("Contents")
                if contents then
                    for _, item in ipairs(contents:GetChildren()) do
                        local name = item.Name
                        if name == "Gold" or name == "Gold Bar" or name == "Gold_Bar" then
                            local entityId = item:GetAttribute("EntityID")
                            if entityId then
                                pcall(function() Packets.Pickup.send(entityId) end)
                                picked = picked + 1
                                if picked >= 15 then break end
                            end
                        end
                    end
                end
            end
            if picked >= 15 then break end
        end
    end
end)

function Runtime.RebuildGoldMover(part, destination)
    local oldMover = Runtime.goldMovers[part]
    if oldMover then pcall(function() oldMover:Destroy() end) end

    local stale = part and part:FindFirstChild("BoogaGoldChestMover")
    if stale then pcall(function() stale:Destroy() end) end
    if not part or not part.Parent then
        Runtime.goldMovers[part] = nil
        return nil
    end

    local mover = Instance.new("BodyPosition")
    mover.Name = "BoogaGoldChestMover"
    mover.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    mover.D = 1750
    mover.P = 42000
    mover.Position = destination
    mover.Parent = part
    Runtime.goldMovers[part] = mover
    return mover
end

function Runtime.ProcessGoldToChest()
    local chest = Runtime.selectedChest
    local items = workspace:FindFirstChild("Items")

    if chest and not chest.Parent then
        Runtime.ClearChest(true)
        if State.lowEnd then task.defer(Runtime.RestoreChest) end
        return
    end

    if not chest or not items then return end

    local destination = Runtime.GetChestDropPosition(chest)
    if not destination then return end

    local now = os.clock()
    local active = {}

    for _, item in ipairs(items:GetChildren()) do
        if Runtime.IsGold(item) then
            local ok = pcall(function()
                local part = Runtime.GetPart(item)
                local entityId = item:GetAttribute("EntityID")
                if not part or not part.Parent or not entityId then return end

                active[part] = true

                local releaseUntil = Runtime.goldReleaseUntil[part]
                if releaseUntil and now < releaseUntil then
                    local mover = Runtime.goldMovers[part]
                    if mover then pcall(function() mover:Destroy() end) end
                    Runtime.goldMovers[part] = nil
                    Runtime.goldLastPositions[part] = nil
                    Runtime.goldLastDistances[part] = nil
                    Runtime.goldLastProgressAt[part] = nil
                    return
                end

                local distance = (part.Position - destination).Magnitude
                if distance <= 0.9 then
                    Runtime.ReleaseGoldPart(part)
                    return
                end

                Runtime.goldReleaseUntil[part] = nil

                local mover = Runtime.goldMovers[part]
                if not mover or not mover.Parent then
                    mover = Runtime.RebuildGoldMover(part, destination)
                else
                    mover.Position = destination
                    mover.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                end

                local lastDistance = Runtime.goldLastDistances[part]
                local progressAt = Runtime.goldLastProgressAt[part]

                if not lastDistance or distance < lastDistance - 0.12 then
                    progressAt = now
                    Runtime.goldLastProgressAt[part] = now
                elseif not progressAt then
                    progressAt = now
                    Runtime.goldLastProgressAt[part] = now
                end

                local stallLimit = State.lowEnd and 1.75 or 2.5
                local stalled = now - progressAt >= stallLimit

                if stalled then
                    if Packets and Packets.ForceInteract and Packets.ForceInteract.send then
                        pcall(function() Packets.ForceInteract.send(entityId) end)
                    end
                    Runtime.RebuildGoldMover(part, destination)
                    Runtime.goldLastProgressAt[part] = now
                    Runtime.goldMoverLastRecoveryAt = now
                else
                    local lastPosition = Runtime.goldLastPositions[part]
                    if (not lastPosition or (part.Position - lastPosition).Magnitude < 0.1)
                        and Packets and Packets.ForceInteract and Packets.ForceInteract.send then
                        pcall(function() Packets.ForceInteract.send(entityId) end)
                    end
                end

                Runtime.goldLastPositions[part] = part.Position
                Runtime.goldLastDistances[part] = distance

                if type(isnetworkowner) == "function" then
                    local teleported = false
                    pcall(function()
                        if isnetworkowner(part) then
                            item:PivotTo(item:GetPivot() + (destination - part.Position))
                            teleported = true
                        end
                    end)
                    if teleported then Runtime.ReleaseGoldPart(part) end
                end
            end)

            if not ok then
                local part = Runtime.GetPart(item)
                if part then
                    local mover = Runtime.goldMovers[part]
                    if mover then pcall(function() mover:Destroy() end) end
                    Runtime.goldMovers[part] = nil
                    Runtime.goldLastPositions[part] = nil
                    Runtime.goldLastDistances[part] = nil
                    Runtime.goldLastProgressAt[part] = nil
                end
            end
        end
    end

    for part, mover in pairs(Runtime.goldMovers) do
        if not active[part] or not part.Parent then
            if mover then pcall(function() mover:Destroy() end) end
            Runtime.goldMovers[part] = nil
            Runtime.goldLastPositions[part] = nil
            Runtime.goldLastDistances[part] = nil
            Runtime.goldLastProgressAt[part] = nil
            Runtime.goldReleaseUntil[part] = nil
        end
    end

    for part in pairs(Runtime.goldReleaseUntil) do
        if not active[part] or not part.Parent then
            Runtime.goldReleaseUntil[part] = nil
        end
    end
end

task.spawn(function()
    while Runtime.running do
        task.wait(State.lowEnd and 0.08 or 0.12)

        local ok = pcall(Runtime.ProcessGoldToChest)
        if not ok then
            pcall(Runtime.ClearGoldMovers)
            task.wait(0.15)
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if not State.pickupItem or not Packets or not Packets.Pickup then continue end
        local root = Runtime.GetRoot()
        local items = workspace:FindFirstChild("Items")
        if not root or not items then continue end
        local picked = 0
        for _, item in ipairs(items:GetChildren()) do
            if item.Name == "Gold" or item.Name == "Gold Bar" or item.Name == "Gold_Bar" then
                local part = Runtime.GetPart(item)
                local entityId = item:GetAttribute("EntityID")
                if part and entityId and (part.Position - root.Position).Magnitude <= 35 then
                    pcall(function() Packets.Pickup.send(entityId) end)
                    picked = picked + 1
                    if picked >= 15 then break end
                end
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.12)
        if not State.pickCoins or not Packets or not Packets.Pickup then continue end
        local root = Runtime.GetRoot()
        local items = workspace:FindFirstChild("Items")
        if not root or not items then continue end
        local picked = 0
        for _, item in ipairs(items:GetChildren()) do
            if item.Name == "Coin" or item.Name == "Coins" or item.Name == "Coin2" or item.Name == "Coin Stack" then
                local part = Runtime.GetPart(item)
                local entityId = item:GetAttribute("EntityID")
                if part and entityId and (part.Position - root.Position).Magnitude <= 35 then
                    pcall(function() Packets.Pickup.send(entityId) end)
                    picked = picked + 1
                    if picked >= 100 then break end
                end
            end
        end
    end
end)

local fixedDropLimits = {
    Leaves = 300,
    Leaf = 300,
    Log = 300,
    Wood = 300,
    Sunfruit = 300,
    ["Sun Fruit"] = 300
}
local pendingDrops = {
    Leaves = 0,
    Leaf = 0,
    Log = 0,
    Wood = 0,
    Sunfruit = 0,
    ["Sun Fruit"] = 0
}
local dropQueue = {}

task.spawn(function()
    while Runtime.running do
        task.wait()
        if not State.dropUntil or not Packets or not Packets.DropBagItem then
            table.clear(dropQueue)
            for name in pairs(pendingDrops) do pendingDrops[name] = 0 end
            continue
        end
        for _ = 1, 15 do
            local queued = table.remove(dropQueue, 1)
            if not queued then break end
            pcall(function() Packets.DropBagItem.send(queued.order) end)
            pendingDrops[queued.name] = math.max(0, pendingDrops[queued.name] - 1)
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.2)
        if not State.dropUntil then continue end
        local inventory = Runtime.GetInventory()
        if not inventory then continue end
        local currentCounts, itemNodes = {}, {}
        for _, item in ipairs(inventory:GetChildren()) do
            if item:IsA("ImageLabel") and fixedDropLimits[item.Name] then
                local quantity = Runtime.GetItemQuantity(item)
                currentCounts[item.Name] = (currentCounts[item.Name] or 0) + quantity
                itemNodes[item.Name] = itemNodes[item.Name] or {}
                table.insert(itemNodes[item.Name], {order = item.LayoutOrder, quantity = quantity})
            end
        end
        for name, count in pairs(currentCounts) do
            local excess = count - (pendingDrops[name] or 0) - fixedDropLimits[name]
            if excess > 0 then
                for _, item in ipairs(itemNodes[name]) do
                    if excess <= 0 then break end
                    local amount = math.min(excess, item.quantity)
                    for _ = 1, amount do
                        table.insert(dropQueue, {order = item.order, name = name})
                    end
                    pendingDrops[name] = pendingDrops[name] + amount
                    excess = excess - amount
                end
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.1)
        if not State.deleteMaterials or not Packets or not Packets.ForceInteract then continue end
        local root = Runtime.GetRoot()
        local items = workspace:FindFirstChild("Items")
        if not root or not items then continue end
        for _, item in ipairs(items:GetChildren()) do
            local name = item.Name
            local shouldDelete = name == "Leaves" or name == "Leaf" or name == "Wood"
                or name == "Log" or name == "Sunfruit" or name == "Sun Fruit"
            if shouldDelete and not Runtime.deleting[item] then
                local part = Runtime.GetPart(item)
                local entityId = item:GetAttribute("EntityID")
                if part and entityId and (part.Position - root.Position).Magnitude <= 35 then
                    Runtime.deleting[item] = true
                    task.spawn(function()
                        for _ = 1, 20 do
                            if not Runtime.running or not item.Parent then break end
                            pcall(function() Packets.ForceInteract.send(entityId) end)
                            if type(isnetworkowner) == "function" then
                                local owns = false
                                pcall(function() owns = isnetworkowner(part) end)
                                if owns then
                                    pcall(function() item:PivotTo(CFrame.new(0, -500, 0)) end)
                                    break
                                end
                            end
                            task.wait(0.05)
                        end
                        Runtime.deleting[item] = nil
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.25)
        if not State.refillCampfire or not Packets or not Packets.InteractStructure or not ItemIDS then continue end
        local root = Runtime.GetRoot()
        local deployables = workspace:FindFirstChild("Deployables")
        if not root or not deployables then continue end
        local woodId = ItemIDS["Wood"]
        local leavesId = ItemIDS["Leaves"] or ItemIDS["Leaf"]
        local refillQueue = {}
        for _, structure in ipairs(deployables:GetChildren()) do
            if string.find(Runtime.Normalized(structure.Name), "campfire", 1, true) then
                local distance = (structure:GetPivot().Position - root.Position).Magnitude
                if distance <= 45 then
                    local entityId = structure:GetAttribute("EntityID")
                    local board = structure:FindFirstChild("Board")
                    local billboard = board and board:FindFirstChild("Billboard")
                    if entityId then
                        local textLabel = billboard and billboard:FindFirstChild("Backdrop")
                            and billboard.Backdrop:FindFirstChild("TextLabel")
                        local fireValue = textLabel and tonumber(string.match(tostring(textLabel.Text), "%d+%.?%d*")) or nil
                        if not fireValue then
                            fireValue = tonumber(structure:GetAttribute("Fuel"))
                                or tonumber(structure:GetAttribute("FuelAmount"))
                                or tonumber(structure:GetAttribute("Fire"))
                        end
                        if not fireValue then
                            for _, descendant in ipairs(structure:GetDescendants()) do
                                if descendant:IsA("TextLabel") then
                                    fireValue = tonumber(string.match(tostring(descendant.Text), "%d+%.?%d*"))
                                    if fireValue then break end
                                end
                            end
                        end
                        local refillKey = tostring(entityId)
                        if fireValue and fireValue <= 200 and fireValue < 250
                            and not Runtime.campfireRefillInFlight[refillKey] then
                            Runtime.campfireRefillInFlight[refillKey] = true
                            table.insert(refillQueue, {entityId = entityId, key = refillKey})
                        end
                    end
                end
            end
        end
        if #refillQueue > 0 then
            task.spawn(function()
                for _ = 1, 15 do
                    if not Runtime.running or not State.refillCampfire then break end
                    for _, refill in ipairs(refillQueue) do
                        if woodId then
                            pcall(function()
                                Packets.InteractStructure.send({entityID = refill.entityId, itemID = woodId})
                            end)
                        end
                        if leavesId then
                            pcall(function()
                                Packets.InteractStructure.send({entityID = refill.entityId, itemID = leavesId})
                            end)
                        end
                    end
                    task.wait()
                end
                for _, refill in ipairs(refillQueue) do
                    Runtime.campfireRefillInFlight[refill.key] = nil
                end
            end)
        end
    end
end)

task.spawn(function()
    while Runtime.running do
        task.wait(0.1)
        if not State.goldHitAura then continue end
        local root = Runtime.GetRoot()
        if not root then continue end
        local nodes = Runtime.GetResourceAuraTargets(root, 20)
        local entityIds = {}
        for index = 1, math.min(#nodes, 20) do table.insert(entityIds, nodes[index].entityId) end
        local auraToggle = UI.Toggles.goldHitAura
        if auraToggle then
            auraToggle.button.Text = "Gold Hit Aura: ON [" .. tostring(#entityIds) .. "]"
        end
        Runtime.SendGoldSwing(entityIds)
    end
end)

table.insert(Runtime.connections, Services.RunService.RenderStepped:Connect(function()
    if not Runtime.running then return end
    local root = Runtime.GetRoot()
    local humanoid = root and root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid and State.startPath then
        if Runtime.pathControlledRoot ~= root then Runtime.BeginPathControl(root) end
        humanoid.WalkSpeed = 0
        humanoid.AutoRotate = false
        root.Anchored = false
        root.AssemblyAngularVelocity = Vector3.zero
        if Runtime.pathAnimate and Runtime.pathAnimate.Parent then
            Runtime.pathAnimate.Disabled = true
        end
        if Runtime.pathIdleTrack and not Runtime.pathIdleTrack.IsPlaying then
            pcall(function() Runtime.pathIdleTrack:Play(0.12, 1, 1) end)
        end
    elseif humanoid and State.walkSpeedEnabled then
        humanoid.WalkSpeed = State.moveSpeed
    end
    if State.lockCamera then
        local camera = workspace.CurrentCamera
        if camera then
            local currentPosition = camera.CFrame.Position
            camera.CFrame = CFrame.new(currentPosition)
                * CFrame.fromEulerAnglesYXZ(math.rad(-36), math.rad(120), math.rad(0))
        end
    end
end))

table.insert(Runtime.connections, Services.UserInputService.WindowFocusReleased:Connect(function()
    if State.cpuMode then
        Services.RunService:Set3dRenderingEnabled(false)
        UI.CpuCover.Visible = true
    end
end))
table.insert(Runtime.connections, Services.UserInputService.WindowFocused:Connect(function()
    Services.RunService:Set3dRenderingEnabled(true)
    UI.CpuCover.Visible = false
end))

function Runtime.IdlePulse()
    if not Runtime.running then return end
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera and camera.CFrame or CFrame.new()
    pcall(function() Services.VirtualUser:CaptureController() end)
    pcall(function() Services.VirtualUser:Button2Down(Vector2.new(0, 0), cameraCFrame) end)
    task.wait(0.1)
    pcall(function() Services.VirtualUser:Button2Up(Vector2.new(0, 0), cameraCFrame) end)
end

pcall(function()
    if type(getconnections) == "function" then
        for _, connection in ipairs(getconnections(Player.Idled)) do
            local disabled = pcall(function() connection:Disable() end)
            if disabled then table.insert(Runtime.disabledIdleConnections, connection) end
        end
    end
end)
table.insert(Runtime.connections, Player.Idled:Connect(function() task.spawn(Runtime.IdlePulse) end))
task.spawn(function()
    while Runtime.running do
        task.wait(55)
        Runtime.IdlePulse()
    end
end)

Runtime.coinNames = {Coin = true, Coins = true, Coin2 = true, ["Coin Stack"] = true}

function Runtime.GetNearestCoin(root)
    if not root then return nil, math.huge end
    local closest, closestDistance = nil, math.huge
    local seen = {}
    local function inspect(item)
        if not item or seen[item] or not Runtime.coinNames[item.Name] then return end
        seen[item] = true
        local part = Runtime.GetPart(item)
        if not part then return end
        local distance = (part.Position - root.Position).Magnitude
        if distance < closestDistance then
            closest = part
            closestDistance = distance
        end
    end
    local items = workspace:FindFirstChild("Items")
    if items then for _, item in ipairs(items:GetChildren()) do inspect(item) end end
    for _, item in ipairs(workspace:GetChildren()) do inspect(item) end
    return closest, closestDistance
end

task.spawn(function()
    while Runtime.running do
        task.wait(0.05)
        if not State.tweenToCoins then continue end
        if not Runtime.IsCharacterSpawned() then
            continue
        end
        Runtime.coinSpawnInvoked = true
        if Runtime.coinTweenStarted then continue end
        Runtime.coinTweenStarted = true
        Runtime.coinTweenToken = Runtime.coinTweenToken + 1
        local token = Runtime.coinTweenToken
        task.spawn(function()
            if not State.tweenToCoins or Runtime.coinTweenToken ~= token then return end
            Runtime.coinTweenActive = true
            local startedAt = os.clock()
            local lastTargetPosition = nil
            while Runtime.running
                and State.tweenToCoins
                and Runtime.coinTweenToken == token
                and os.clock() - startedAt < 120 do
                task.wait(0.05)
                if not State.tweenToCoins or Runtime.coinTweenToken ~= token then break end
                local root = Runtime.GetRoot()
                if not root then continue end
                local coin, distance = Runtime.GetNearestCoin(root)
                if coin and coin.Parent then
                    lastTargetPosition = coin.Position + Vector3.new(0, Runtime.pathHoverOffset, 0)
                    if distance <= 2.25 then break end
                    Runtime.DrivePath(root, lastTargetPosition)
                elseif lastTargetPosition then
                    if (root.Position - lastTargetPosition).Magnitude <= 2.25 then break end
                    Runtime.DrivePath(root, lastTargetPosition)
                end
            end
            if Runtime.coinTweenToken ~= token then return end
            Runtime.coinTweenActive = false
            Runtime.StopPathMovement()
            if not State.startPath then Runtime.EndPathControl() end
        end)
    end
end)

function Runtime.CountWorldCoins()
    local seen, total = {}, 0
    local function inspect(item)
        if item and Runtime.coinNames[item.Name] and not seen[item] then
            seen[item] = true
            total = total + 1
        end
    end
    local items = workspace:FindFirstChild("Items")
    if items then for _, item in ipairs(items:GetChildren()) do inspect(item) end end
    for _, item in ipairs(workspace:GetChildren()) do inspect(item) end
    local deployables = workspace:FindFirstChild("Deployables")
    if deployables then for _, item in ipairs(deployables:GetChildren()) do inspect(item) end end
    return total
end

Runtime.coinWebhookUrl = tostring(Global.BoogaWebhook or "")
Runtime.coinDatabaseRoot = "https://keyvalue.Immanuel.co/api/KeyVal"
Runtime.coinDatabaseNamespace = "n9ipufne"
Runtime.coinAccounts = {
    TractionSee = "Instance 1",
    LolTractionIsCool = "Instance 2",
    RealTractions = "Instance 3",
    h4wnd = "Instance 4",
    uqerqeouuu99 = "Instance 5",
    WontTraction = "Instance 6",
    TractionSeeing = "Instance 7",
    TractionXDPro = "Instance 8",
    NotEwTraction = "Instance 9",
    LordMason68 = "Instance 10"
}
Runtime.httpRequest = http_request or request or (syn and syn.request) or (http and http.request)
Runtime.instanceId = Runtime.coinAccounts[Player.Name]
Runtime.databaseKey = Runtime.instanceId and string.gsub(Runtime.instanceId, " ", "_") or nil
Runtime.databaseStatus = "DB waiting"
Runtime.reportStatus = "Report waiting"

function Runtime.GetHttpStatus(response)
    if type(response) ~= "table" then return nil end
    return tonumber(response.StatusCode or response.Status or response.status_code)
end

function Runtime.HttpSucceeded(response)
    local status = Runtime.GetHttpStatus(response)
    if status then return status >= 200 and status < 300, status end
    if type(response) == "table" and response.Success ~= nil then
        return response.Success == true, response.Success == true and "OK" or "failed"
    end
    return response ~= nil, "?"
end

function Runtime.UpdateWebhookWatcher()
    if UI.Watcher and UI.Watcher.Webhook then
        UI.Watcher.Webhook.Text = "Webhook\n" .. Runtime.reportStatus .. " | " .. Runtime.databaseStatus
    end
end

function Runtime.ToHex(value)
    return (string.gsub(value, ".", function(character)
        return string.format("%02x", string.byte(character))
    end))
end

function Runtime.FromHex(value)
    local ok, decoded = pcall(function()
        return (string.gsub(value, "..", function(pair)
            return string.char(tonumber(pair, 16))
        end))
    end)
    return ok and decoded or nil
end

function Runtime.FormatUptime(seconds)
    if seconds < 60 then return tostring(seconds) .. "s" end
    if seconds < 3600 then return tostring(math.floor(seconds / 60)) .. "m " .. tostring(seconds % 60) .. "s" end
    return tostring(math.floor(seconds / 3600)) .. "h " .. tostring(math.floor(seconds % 3600 / 60)) .. "m"
end

UI.Watcher.Instance.Text = "Instance\n" .. (Runtime.instanceId or "Account not mapped")
if not Runtime.httpRequest then
    Runtime.databaseStatus = "DB unavailable"
    Runtime.reportStatus = "HTTP unsupported"
end
Runtime.UpdateWebhookWatcher()

task.spawn(function()
    while Runtime.running do
        local coins = Runtime.CountWorldCoins()
        UI.Watcher.Coins.Text = "Coins\n" .. tostring(coins)
        UI.Watcher.Calculated.Text = "Calculated\n" .. tostring(coins * 5)
        UI.Watcher.Session.Text = "Session\n" .. Runtime.FormatUptime(os.time() - Runtime.startedAt)
        task.wait(0.25)
    end
end)

if Runtime.instanceId and Runtime.httpRequest then
    task.spawn(function()
        while Runtime.running do
            local coins = Runtime.CountWorldCoins()
            local payload = {
                name = Runtime.instanceId,
                coins = coins,
                calculated = coins * 5,
                timestamp = os.time()
            }
            local encoded = Runtime.ToHex(Services.HttpService:JSONEncode(payload))
            local ok, response = pcall(function()
                return Runtime.httpRequest({
                    Url = Runtime.coinDatabaseRoot .. "/UpdateValue/" .. Runtime.coinDatabaseNamespace .. "/" .. Runtime.databaseKey .. "/" .. encoded,
                    Method = "POST",
                    Body = ""
                })
            end)
            local accepted, status = false, "error"
            if ok then accepted, status = Runtime.HttpSucceeded(response) end
            Runtime.databaseStatus = accepted and ("DB " .. tostring(status)) or ("DB failed " .. tostring(status))
            Runtime.UpdateWebhookWatcher()
            task.wait(30)
        end
    end)

    function Runtime.SendCoinWebhook(fields)
        if Runtime.coinWebhookUrl == "" then
            Runtime.reportStatus = "Webhook not configured"
            Runtime.UpdateWebhookWatcher()
            return false
        end

        local body = Services.HttpService:JSONEncode({
            embeds = {{
                title = "Booga Booga Coin Report",
                color = 9090296,
                fields = fields
            }}
        })
        local url = Runtime.coinWebhookUrl
            .. (string.find(Runtime.coinWebhookUrl, "?", 1, true) and "&wait=true" or "?wait=true")
        local lastStatus = "request error"
        for attempt = 1, 3 do
            local called, response = pcall(function()
                return Runtime.httpRequest({
                    Url = url,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = body
                })
            end)
            if called then
                local accepted, status = Runtime.HttpSucceeded(response)
                lastStatus = "HTTP " .. tostring(status)
                if accepted then
                    Runtime.reportStatus = "Sent " .. tostring(status)
                    Runtime.UpdateWebhookWatcher()
                    return true
                end
            end
            Runtime.reportStatus = "Retry " .. tostring(attempt) .. "/3 " .. lastStatus
            Runtime.UpdateWebhookWatcher()
            if attempt < 3 then task.wait(attempt * 2) end
        end
        Runtime.reportStatus = "Failed " .. lastStatus
        Runtime.UpdateWebhookWatcher()
        return false
    end

    function Runtime.RunCoinReporterCycle()
        local fetched, activeCount, now = {}, 0, os.time()
        for index = 1, 10 do
            local key = "Instance_" .. tostring(index)
            pcall(function()
                local response = Runtime.httpRequest({
                    Url = Runtime.coinDatabaseRoot .. "/GetValue/" .. Runtime.coinDatabaseNamespace .. "/" .. key,
                    Method = "GET"
                })
                local accepted = Runtime.HttpSucceeded(response)
                if accepted and response.Body and response.Body ~= "" and response.Body ~= "null" then
                    local body = response.Body
                    if string.sub(body, 1, 1) == "\"" and string.sub(body, -1) == "\"" then
                        body = string.sub(body, 2, -2)
                    end
                    local json = Runtime.FromHex(body)
                    if json then
                        local decoded, info = pcall(function() return Services.HttpService:JSONDecode(json) end)
                        if decoded and info and info.timestamp and math.abs(now - info.timestamp) < 300 then
                            fetched[key] = info
                            activeCount = activeCount + 1
                        end
                    end
                end
            end)
        end

        UI.Watcher.Workers.Text = "Workers\n" .. tostring(activeCount) .. " / 10 online"
        local reporter = nil
        for index = 1, 10 do
            local key = "Instance_" .. tostring(index)
            if fetched[key] then reporter = key break end
        end

        if reporter ~= Runtime.databaseKey then
            Runtime.reportStatus = reporter and ("Reporter " .. string.gsub(reporter, "_", " ")) or "No active workers"
            Runtime.UpdateWebhookWatcher()
            return reporter ~= nil
        end

        local totalCoins, totalCalculated, fields, missing = 0, 0, {}, false
        for index = 1, 10 do
            local info = fetched["Instance_" .. tostring(index)]
            if info then
                totalCoins = totalCoins + (tonumber(info.coins) or 0)
                totalCalculated = totalCalculated + (tonumber(info.calculated) or 0)
                table.insert(fields, {
                    name = "Instance " .. tostring(index),
                    value = "Coins: " .. tostring(info.coins) .. "\nCalculated: " .. tostring(info.calculated),
                    inline = true
                })
            else
                missing = true
                table.insert(fields, {
                    name = "Instance " .. tostring(index),
                    value = "Not detected / crashed",
                    inline = true
                })
            end
        end
        table.insert(fields, {
            name = "System Status",
            value = missing and "Crashes found - check status." or "No crashes - farming normal.",
            inline = true
        })
        table.insert(fields, {
            name = "Combined Totals",
            value = "Coins: " .. tostring(totalCoins)
                .. " | Calculated: " .. tostring(totalCalculated)
                .. " | Workers: " .. tostring(activeCount) .. " / 10"
                .. " | Uptime: " .. Runtime.FormatUptime(os.time() - Runtime.startedAt),
            inline = false
        })
        return Runtime.SendCoinWebhook(fields)
    end

    task.spawn(function()
        task.wait(5)
        while Runtime.running do
            local ran, completed = pcall(Runtime.RunCoinReporterCycle)
            if not ran then
                Runtime.reportStatus = "Reporter cycle error"
                Runtime.UpdateWebhookWatcher()
            end
            local delay = ran and completed and 660 or 30
            local deadline = os.clock() + delay
            while Runtime.running and os.clock() < deadline do task.wait(1) end
        end
    end)
elseif not Runtime.instanceId then
    UI.Watcher.Workers.Text = "Workers\nAccount not mapped"
end

local function DestroyBoogaUi()
    local names = {
        BoogaGoldUI = true,
        BoogaUtilityUI = true,
        BoogaGoldUnfocusBlack = true
    }
    pcall(function()
        if ScreenGui then ScreenGui:Destroy() end
    end)
    local parents = {Services.CoreGui, Player:FindFirstChildOfClass("PlayerGui")}
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then table.insert(parents, hui) end
    end
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                for _, object in ipairs(parent:GetDescendants()) do
                    if object:IsA("ScreenGui") and names[object.Name] then
                        object:Destroy()
                    end
                end
            end)
        end
    end
end

function Runtime.Stop()
    if Runtime.cleaningUp then
        DestroyBoogaUi()
        return
    end
    Runtime.cleaningUp = true
    Runtime.running = false
    if Global.__BoogaUtilityStop == Runtime.Stop then Global.__BoogaUtilityStop = nil end
    DestroyBoogaUi()

    pcall(function()
        for key, value in pairs(State) do
            if type(value) == "boolean" then State[key] = false end
        end
        Runtime.confirmCallback = nil
        Runtime.bindingKey = false
        Runtime.listeningForChest = false
        Runtime.coinTweenToken = (Runtime.coinTweenToken or 0) + 1
        Runtime.coinTweenActive = false
    end)

    pcall(Runtime.CancelMotion)
    pcall(Runtime.EndPathControl)
    pcall(Runtime.SetMovementStability, false)
    pcall(Runtime.DestroyPathDots)
    pcall(Runtime.ClearGoldMovers)

    pcall(function()
        if Runtime.freezeConnection then Runtime.freezeConnection:Disconnect() end
        Runtime.freezeConnection = nil
        if Runtime.selectedChestHighlight then Runtime.selectedChestHighlight:Destroy() end
        Runtime.selectedChestHighlight = nil
    end)

    pcall(function()
        for _, connection in ipairs(Runtime.connections or {}) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(Runtime.connections)
    end)

    pcall(function()
        for _, connection in ipairs(Runtime.disabledIdleConnections or {}) do
            pcall(function() connection:Enable() end)
        end
        table.clear(Runtime.disabledIdleConnections)
    end)

    pcall(function() Services.RunService:Set3dRenderingEnabled(true) end)
    pcall(Runtime.RestoreUltraLow)
    pcall(Runtime.ReleaseFPSCap)
    pcall(function() Services.GuiService.SelectedObject = nil end)
    pcall(function()
        local camera = workspace.CurrentCamera
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            if humanoid then camera.CameraSubject = humanoid end
        end
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.Sit = false
            humanoid.Jump = false
            humanoid.AutoRotate = true
            humanoid.WalkSpeed = 16
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
        local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
        if root then
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            for _, name in ipairs({"BoogaPathAttachment", "BoogaPathVelocity", "BoogaPathOrientation"}) do
                local object = root:FindFirstChild(name)
                if object then object:Destroy() end
            end
        end
    end)

    pcall(function()
        for _, object in ipairs(workspace:GetDescendants()) do
            if object.Name == "BoogaGoldChestMover"
                or object.Name == "BoogaPathAttachment"
                or object.Name == "BoogaPathVelocity"
                or object.Name == "BoogaPathOrientation"
                or object.Name == "BoogaUtilitySelectedChest"
                or object.Name == "BoogaPathIdle" then
                object:Destroy()
            end
        end
    end)

    DestroyBoogaUi()
end

Global.__BoogaUtilityStop = Runtime.Stop

UI.ExitButton.Activated:Connect(function()
    UI.AskConfirm("Exit Script?\nThis stops every active feature.", Runtime.Stop)
end)

Runtime.ApplyCPU()
Runtime.ApplyLowEnd()
Runtime.ApplyUltraLow()
Runtime.ApplyCamera()
Runtime.UpdateMovementStability()
Runtime.LoadDefaultPathProfile()
if State.showPath then Runtime.CreatePathDots() end
if State.startPath then Runtime.RestartPath() end
Runtime.ResetAntiStuck()
task.defer(Runtime.RestoreChest)
