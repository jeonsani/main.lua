getgenv().OldAimPart = "HumanoidRootPart"
getgenv().AimPart = "HumanoidRootPart" -- For R15 Games: {UpperTorso, LowerTorso, HumanoidRootPart, Head} | For R6 Games: {Head, Torso, HumanoidRootPart}  
    getgenv().AimlockKey = "q"
    getgenv().TriggerKey = "t"  -- Default triggerbot key
    getgenv().AimRadius = 50 -- How far away from someones character you want to lock on at
    getgenv().ThirdPerson = true 
    getgenv().FirstPerson = true
    getgenv().TeamCheck = false -- Check if Target is on your Team (True means it wont lock onto your teamates, false is vice versa) (Set it to false if there are no teams)
    getgenv().PredictMovement = true -- Predicts if they are moving in fast velocity (like jumping) so the aimbot will go a bit faster to match their speed 
    getgenv().PredictionVelocity = 8.7
    getgenv().CheckIfJumped = true
    getgenv().Smoothness = false
    getgenv().SmoothnessAmount = 0.2
    getgenv().TriggerBot = false
    getgenv().TriggerDelay = 0.1
    getgenv().ESP = false
    getgenv().ESPBoxes = true
    getgenv().ESPNames = true
    getgenv().ESPDistance = true
    getgenv().MaxESPDistance = 1000
    getgenv().ShowKeybindList = true
    getgenv().ShowWatermark = true
    getgenv().AntiAim = false
    getgenv().AntiAimType = "Spin" -- "Spin", "Jitter", "Random"
    getgenv().AntiAimSpeed = 100 -- Speed for spin/jitter
    getgenv().Resolver = false
    getgenv().ResolverPrediction = 0.1
    getgenv().SilentAim = false
    getgenv().SilentAimFOV = 100
    getgenv().SilentAimShowFOV = true
    getgenv().SilentAimWallCheck = true
    getgenv().SilentAimPart = "Head"
    getgenv().LegitAA = false
    getgenv().LegitAAAngle = 60 -- Default angle for legit AA
    getgenv().SpeedHack = false
    getgenv().SpeedValue = 16 -- Default walking speed
    getgenv().SpeedHackKey = "x"  -- Default speedhack key

    local Players, Uis, RService, SGui = game:GetService"Players", game:GetService"UserInputService", game:GetService"RunService", game:GetService"StarterGui";
    local Client, Mouse, Camera, CF, RNew, Vec3, Vec2 = Players.LocalPlayer, Players.LocalPlayer:GetMouse(), workspace.CurrentCamera, CFrame.new, Ray.new, Vector3.new, Vector2.new;
    local Aimlock, MousePressed, CanNotify = true, false, false;
    local AimlockTarget;
    local OldPre;
    local AntiAimAngle = 0
    local LastTargetCFrame = nil
    local ResolverOffset = Vector3.new(0, 0, 0)

    -- Remove the old ESP loading code and replace with our custom implementation
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    -- ESP Configuration
    local ESPSettings = {
        Enabled = false,
        Boxes = true,
        Names = true,
        Distance = true,
        MaxDistance = 1000,
        BoxColor = Color3.fromRGB(255, 255, 255),
        NameColor = Color3.fromRGB(255, 255, 255),
        GlowColor = Color3.fromRGB(255, 110, 48),
        ShowGlow = true,
        BoxThickness = 1,
        GlowThickness = 2,
        TextSize = 14,
        OutlineColor = Color3.fromRGB(0, 0, 0)
    }

    -- Drawing objects storage
    local ESPObjects = {}

    local function CreateDrawingObject(type, properties)
        local obj = Drawing.new(type)
        for prop, value in pairs(properties) do
            obj[prop] = value
        end
        return obj
    end

    local function CreateESPForPlayer(player)
        if ESPObjects[player] then return end
        
        ESPObjects[player] = {
            BoxGlow = CreateDrawingObject("Square", {
                Thickness = ESPSettings.GlowThickness,
                Color = ESPSettings.GlowColor,
                Filled = false,
                Transparency = 0.5,
                Visible = false
            }),
            Box = CreateDrawingObject("Square", {
                Thickness = ESPSettings.BoxThickness,
                Color = ESPSettings.BoxColor,
                Filled = false,
                Transparency = 1,
                Visible = false
            }),
            Name = CreateDrawingObject("Text", {
                Text = player.Name,
                Size = ESPSettings.TextSize,
                Center = true,
                Outline = true,
                OutlineColor = ESPSettings.OutlineColor,
                Color = ESPSettings.NameColor,
                Transparency = 1,
                Visible = false
            }),
            Distance = CreateDrawingObject("Text", {
                Size = ESPSettings.TextSize,
                Center = true,
                Outline = true,
                OutlineColor = ESPSettings.OutlineColor,
                Color = ESPSettings.NameColor,
                Transparency = 1,
                Visible = false
            })
        }
    end

    local function RemoveESP(player)
        if ESPObjects[player] then
            for _, obj in pairs(ESPObjects[player]) do
                obj:Remove()
            end
            ESPObjects[player] = nil
        end
    end

    local function UpdateESP()
        for player, objects in pairs(ESPObjects) do
            if player == LocalPlayer then continue end
            
            local character = player.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")
            
            if not character or not humanoidRootPart or not humanoid then
                for _, obj in pairs(objects) do
                    obj.Visible = false
                end
                continue
            end

            local vector, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
            local distance = (humanoidRootPart.Position - Camera.CFrame.Position).Magnitude
            
            if not onScreen or distance > ESPSettings.MaxDistance or not ESPSettings.Enabled then
                for _, obj in pairs(objects) do
                    obj.Visible = false
                end
                continue
            end

            -- Improved box size calculation
            local cframe = character:GetModelCFrame()
            local size = character:GetExtentsSize()
            
            local topPosition = Camera:WorldToViewportPoint(cframe.Position + Vector3.new(0, size.Y/1.5, 0))
            local bottomPosition = Camera:WorldToViewportPoint(cframe.Position - Vector3.new(0, size.Y/2, 0))
            local boxSize = Vector2.new(math.abs(topPosition.X - bottomPosition.X) * 3, math.abs(topPosition.Y - bottomPosition.Y))
            local boxPosition = Vector2.new(vector.X - boxSize.X / 2, vector.Y - boxSize.Y / 2)

            -- Update Box and Glow
            if ESPSettings.Boxes then
                -- Update Glow first (so it appears behind the box)
                if ESPSettings.ShowGlow then
                    objects.BoxGlow.Size = Vector2.new(boxSize.X + 6, boxSize.Y + 6)
                    objects.BoxGlow.Position = Vector2.new(boxPosition.X - 3, boxPosition.Y - 3)
                    objects.BoxGlow.Color = ESPSettings.GlowColor
                    objects.BoxGlow.Thickness = ESPSettings.GlowThickness
                    objects.BoxGlow.Transparency = 0.4
                    objects.BoxGlow.Visible = true
                else
                    objects.BoxGlow.Visible = false
                end

                -- Update Box
                objects.Box.Size = boxSize
                objects.Box.Position = boxPosition
                objects.Box.Color = ESPSettings.BoxColor
                objects.Box.Thickness = ESPSettings.BoxThickness
                objects.Box.Visible = true
            else
                objects.Box.Visible = false
                objects.BoxGlow.Visible = false
            end

            -- Update Name
            if ESPSettings.Names then
                objects.Name.Position = Vector2.new(vector.X, boxPosition.Y - 20)
                objects.Name.Color = ESPSettings.NameColor
                objects.Name.Visible = true
            else
                objects.Name.Visible = false
            end

            -- Update Distance
            if ESPSettings.Distance then
                objects.Distance.Text = math.floor(distance) .. " studs"
                objects.Distance.Position = Vector2.new(vector.X, boxPosition.Y + boxSize.Y + 5)
                objects.Distance.Color = ESPSettings.NameColor
                objects.Distance.Visible = true
            else
                objects.Distance.Visible = false
            end
        end
    end

    -- Player handling
    Players.PlayerAdded:Connect(CreateESPForPlayer)
    Players.PlayerRemoving:Connect(RemoveESP)

    -- Initialize ESP for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        CreateESPForPlayer(player)
    end

    -- Update ESP
    RunService.RenderStepped:Connect(UpdateESP)

    -- Then load the UI
    local Flux = loadstring(game:HttpGet"https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/fluxlib.txt")()

    local win = Flux:Window("Aimbot Settings", "by Flynn", Color3.fromRGB(255, 110, 48), Enum.KeyCode.RightShift)

    -- Create all tabs first
    local MainTab = win:Tab("Main", "http://www.roblox.com/asset/?id=6023426915")
    local SettingsTab = win:Tab("Settings", "http://www.roblox.com/asset/?id=6023426915")
    local VisualTab = win:Tab("Visuals", "http://www.roblox.com/asset/?id=6023426915")
    local RageTab = win:Tab("Rage", "http://www.roblox.com/asset/?id=6023426915")
    local SilentTab = win:Tab("Silent Aim", "http://www.roblox.com/asset/?id=6023426915")

    -- Now add the ESP settings to VisualTab
    VisualTab:Toggle("Enable ESP", "Toggle ESP features", false, function(Value)
        ESPSettings.Enabled = Value
    end)

    VisualTab:Toggle("Show Boxes", "Toggle ESP boxes", true, function(Value)
        ESPSettings.Boxes = Value
    end)

    VisualTab:Toggle("Show Names", "Toggle ESP names", true, function(Value)
        ESPSettings.Names = Value
    end)

    VisualTab:Toggle("Show Distance", "Toggle distance display", true, function(Value)
        ESPSettings.Distance = Value
    end)

    VisualTab:Toggle("Show Glow", "Toggle box glow effect", true, function(Value)
        ESPSettings.ShowGlow = Value
    end)

    VisualTab:Slider("Max Distance", "Maximum ESP render distance", 100, 5000, 1000, function(Value)
        ESPSettings.MaxDistance = Value
    end)

    -- Add color pickers
    VisualTab:Colorpicker("Box Color", Color3.fromRGB(255, 255, 255), function(Value)
        ESPSettings.BoxColor = Value
    end)

    VisualTab:Colorpicker("Glow Color", Color3.fromRGB(255, 110, 48), function(Value)
        ESPSettings.GlowColor = Value
    end)

    VisualTab:Colorpicker("Text Color", Color3.fromRGB(255, 255, 255), function(Value)
        ESPSettings.NameColor = Value
    end)

    -- Add thickness adjustments
    VisualTab:Slider("Box Thickness", "Adjust box line thickness", 1, 5, 1, function(Value)
        ESPSettings.BoxThickness = Value
    end)

    VisualTab:Slider("Glow Thickness", "Adjust glow thickness", 1, 10, 2, function(Value)
        ESPSettings.GlowThickness = Value
    end)

    VisualTab:Slider("Text Size", "Adjust text size", 10, 24, 14, function(Value)
        ESPSettings.TextSize = Value
    end)

    -- Main Tab
    MainTab:Toggle("Enable Aimlock", "Toggle aimlock on/off", true, function(Value)
        Aimlock = Value
    end)

    MainTab:Toggle("Team Check", "Check if target is on your team", getgenv().TeamCheck, function(Value)
        getgenv().TeamCheck = Value
    end)

    MainTab:Toggle("Predict Movement", "Predict target movement", getgenv().PredictMovement, function(Value)
        getgenv().PredictMovement = Value
    end)

    MainTab:Slider("Prediction Velocity", "Adjust prediction velocity", 0, 20, getgenv().PredictionVelocity, function(Value)
        getgenv().PredictionVelocity = Value
    end)

    MainTab:Textbox("Aimlock Key", "Enter key (e.g. q, x)", false, function(Value)
        if Value and Value ~= "" then
            getgenv().AimlockKey = string.lower(Value)
        end
    end)

    MainTab:Textbox("Triggerbot Key", "Enter key (e.g. t, v)", false, function(Value)
        if Value and Value ~= "" then
            getgenv().TriggerKey = string.lower(Value)
        end
    end)

    MainTab:Toggle("Triggerbot", "Automatically shoots when aiming at enemy", false, function(Value)
        getgenv().TriggerBot = Value
    end)

    MainTab:Slider("Trigger Delay", "Adjust trigger reaction time (seconds)", 0, 1, 0.1, function(Value)
        getgenv().TriggerDelay = Value
    end)

    -- Settings Tab
    SettingsTab:Toggle("Smoothness", "Enable aim smoothing", getgenv().Smoothness, function(Value)
        getgenv().Smoothness = Value
    end)

    SettingsTab:Slider("Smoothness Amount", "Adjust smoothness amount", 0, 100, getgenv().SmoothnessAmount * 100, function(Value)
        getgenv().SmoothnessAmount = Value / 100
    end)

    SettingsTab:Slider("Aim Radius", "Adjust aim radius", 0, 200, getgenv().AimRadius, function(Value)
        getgenv().AimRadius = Value
    end)

    SettingsTab:Dropdown("Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, function(Value)
        getgenv().OldAimPart = Value
        getgenv().AimPart = Value
    end)

    -- Move Anti-Aim settings to Rage tab
    RageTab:Toggle("Anti-Aim", "Enable anti-aim", false, function(Value)
        getgenv().AntiAim = Value
    end)

    RageTab:Dropdown("AA Type", {"Spin", "Jitter", "Random"}, function(Value)
        getgenv().AntiAimType = Value
    end)

    RageTab:Slider("AA Speed", "Adjust anti-aim speed", 1, 500, 100, function(Value)
        getgenv().AntiAimSpeed = Value
    end)

    -- Add Resolver settings to Rage tab
    RageTab:Toggle("Resolver", "Enable anti-aim resolver", false, function(Value)
        getgenv().Resolver = Value
    end)

    RageTab:Slider("Resolver Prediction", "Adjust resolver prediction", 0, 500, 100, function(Value)
        getgenv().ResolverPrediction = Value / 1000
    end)

    -- Add Legit AA settings
    RageTab:Toggle("Legit Anti-Aim", "Enable legitimate anti-aim", false, function(Value)
        getgenv().LegitAA = Value
    end)

    RageTab:Slider("Legit AA Angle", "Adjust legitimate anti-aim angle", 0, 180, 60, function(Value)
        getgenv().LegitAAAngle = Value
    end)

    -- Add Speedhack settings
    RageTab:Toggle("Speed Hack", "Enable speed hack", false, function(Value)
        getgenv().SpeedHack = Value
        UpdateSpeed()
    end)

    RageTab:Slider("Speed Value", "Adjust speed value", 16, 150, 16, function(Value)
        getgenv().SpeedValue = Value
        if getgenv().SpeedHack then
            UpdateSpeed()
        end
    end)

    RageTab:Textbox("Speed Key", "Enter key (e.g. x, v)", false, function(Value)
        if Value and Value ~= "" then
            getgenv().SpeedHackKey = string.lower(Value)
        end
    end)

    getgenv().WorldToViewportPoint = function(P)
        return Camera:WorldToViewportPoint(P)
    end
 
    getgenv().WorldToScreenPoint = function(P)
        return Camera.WorldToScreenPoint(Camera, P)
    end
 
    getgenv().GetObscuringObjects = function(T)
        if T and T:FindFirstChild(getgenv().AimPart) and Client and Client.Character:FindFirstChild("Head") then 
            local RayPos = workspace:FindPartOnRay(RNew(
                T[getgenv().AimPart].Position, Client.Character.Head.Position)
            )
            if RayPos then return RayPos:IsDescendantOf(T) end
        end
    end
 
    getgenv().GetNearestTarget = function()
        local players = {}
        local PLAYER_HOLD  = {}
        local DISTANCES = {}
        
        for i, v in pairs(Players:GetPlayers()) do
            if v ~= Client then
                table.insert(players, v)
            end
        end
        
        for i, v in pairs(players) do
            if v.Character and 
               v.Character:FindFirstChild("Head") and 
               v.Character:FindFirstChild("Humanoid") and 
               v.Character:FindFirstChild("HumanoidRootPart") then
                
                local AIM = v.Character:FindFirstChild("Head")
                if getgenv().TeamCheck == true and v.Team ~= Client.Team then
                    local DISTANCE = (v.Character:FindFirstChild("Head").Position - game.Workspace.CurrentCamera.CFrame.p).magnitude
                    local RAY = Ray.new(game.Workspace.CurrentCamera.CFrame.p, (Mouse.Hit.p - game.Workspace.CurrentCamera.CFrame.p).unit * DISTANCE)
                    local HIT,POS = game.Workspace:FindPartOnRay(RAY, game.Workspace)
                    local DIFF = math.floor((POS - AIM.Position).magnitude)
                    PLAYER_HOLD[v.Name .. i] = {}
                    PLAYER_HOLD[v.Name .. i].dist= DISTANCE
                    PLAYER_HOLD[v.Name .. i].plr = v
                    PLAYER_HOLD[v.Name .. i].diff = DIFF
                    table.insert(DISTANCES, DIFF)
                elseif getgenv().TeamCheck == false and v.Team == Client.Team then 
                    local DISTANCE = (v.Character:FindFirstChild("Head").Position - game.Workspace.CurrentCamera.CFrame.p).magnitude
                    local RAY = Ray.new(game.Workspace.CurrentCamera.CFrame.p, (Mouse.Hit.p - game.Workspace.CurrentCamera.CFrame.p).unit * DISTANCE)
                    local HIT,POS = game.Workspace:FindPartOnRay(RAY, game.Workspace)
                    local DIFF = math.floor((POS - AIM.Position).magnitude)
                    PLAYER_HOLD[v.Name .. i] = {}
                    PLAYER_HOLD[v.Name .. i].dist= DISTANCE
                    PLAYER_HOLD[v.Name .. i].plr = v
                    PLAYER_HOLD[v.Name .. i].diff = DIFF
                    table.insert(DISTANCES, DIFF)
                end
            end
        end
        
        if #DISTANCES == 0 then
            return nil
        end
        
        local L_DISTANCE = math.floor(math.min(unpack(DISTANCES)))
        if L_DISTANCE > getgenv().AimRadius then
            return nil
        end
        
        for i, v in pairs(PLAYER_HOLD) do
            if v.diff == L_DISTANCE then
                return v.plr
            end
        end
        return nil
    end
 
    -- Simplified key check function
    local function CheckKey(key)
        if not key then return false end
        return string.lower(tostring(key))
    end

    -- Update the Mouse.KeyDown function
    Mouse.KeyDown:Connect(function(Key)
        if Uis:GetFocusedTextBox() then return end
        
        local key = CheckKey(Key)
        if not key then return end

        pcall(function()
            if key == getgenv().AimlockKey then
                if not AimlockTarget then
                    MousePressed = true
                    local Target = GetNearestTarget()
                    if Target then 
                        AimlockTarget = Target
                    end
                else
                    AimlockTarget = nil
                    MousePressed = false
                end
            end

            if key == getgenv().TriggerKey then
                getgenv().TriggerBot = not getgenv().TriggerBot
            end

            if key == getgenv().SpeedHackKey then
                getgenv().SpeedHack = not getgenv().SpeedHack
                UpdateSpeed()
            end
        end)
    end)
 
    RService.RenderStepped:Connect(function()
        pcall(function()
            -- Add initial safety check
            if not AimlockTarget then return end
            
            if getgenv().ThirdPerson == true and getgenv().FirstPerson == true then 
                if (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude > 1 or (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1 then 
                    CanNotify = true 
                else 
                    CanNotify = false 
                end
            elseif getgenv().ThirdPerson == true and getgenv().FirstPerson == false then 
                if (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude > 1 then 
                    CanNotify = true 
                else 
                    CanNotify = false 
                end
            elseif getgenv().ThirdPerson == false and getgenv().FirstPerson == true then 
                if (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1 then 
                    CanNotify = true 
                else 
                    CanNotify = true
                end
            end

            -- Add comprehensive safety checks
            if Aimlock and MousePressed and AimlockTarget and 
               AimlockTarget.Character and 
               typeof(AimlockTarget.Character) == "Instance" and
               AimlockTarget.Character:FindFirstChild(getgenv().AimPart) then 
                
                -- Rest of your aiming logic here
                if getgenv().FirstPerson == true then
                    if CanNotify == true then
                        if getgenv().PredictMovement == true then
                            if getgenv().Smoothness == true then
                                --// The part we're going to lerp/smoothen \\--
                                local Main = CF(Camera.CFrame.p, AimlockTarget.Character[getgenv().AimPart].Position + AimlockTarget.Character[getgenv().AimPart].Velocity/getgenv().PredictionVelocity)
 
                                --// Making it work \\--
                                Camera.CFrame = Camera.CFrame:Lerp(Main, getgenv().SmoothnessAmount, Enum.EasingStyle.Elastic, Enum.EasingDirection.InOut)
                            else
                                Camera.CFrame = CF(Camera.CFrame.p, AimlockTarget.Character[getgenv().AimPart].Position + AimlockTarget.Character[getgenv().AimPart].Velocity/getgenv().PredictionVelocity)
                            end
                        elseif getgenv().PredictMovement == false then 
                            if getgenv().Smoothness == true then
                                --// The part we're going to lerp/smoothen \\--
                                local Main = CF(Camera.CFrame.p, AimlockTarget.Character[getgenv().AimPart].Position)
 
                                --// Making it work \\--
                                Camera.CFrame = Camera.CFrame:Lerp(Main, getgenv().SmoothnessAmount, Enum.EasingStyle.Elastic, Enum.EasingDirection.InOut)
                            else
                                Camera.CFrame = CF(Camera.CFrame.p, AimlockTarget.Character[getgenv().AimPart].Position)
                            end
                        end
                    end
                end
            end

            -- Move CheckIfJumped logic inside the safety checks
            if CheckIfJumped == true and 
               AimlockTarget and 
               AimlockTarget.Character and 
               typeof(AimlockTarget.Character) == "Instance" and
               AimlockTarget.Character:FindFirstChild("Humanoid") then
                
                if AimlockTarget.Character.Humanoid.FloorMaterial == Enum.Material.Air then
                    getgenv().AimPart = "HumanoidRootPart"
                else
                    getgenv().AimPart = getgenv().OldAimPart
                end
            end

            -- Update ESP
            if getgenv().ESP then
                for _, Player in pairs(Players:GetPlayers()) do
                    if Player ~= Client and Player.Character then
                        local Distance = (Player.Character:FindFirstChild("HumanoidRootPart").Position - Client.Character.HumanoidRootPart.Position).Magnitude
                        if Distance <= getgenv().MaxESPDistance then
                            ESP.Players[Player].Drawing.Visible = true
                        else
                            ESP.Players[Player].Drawing.Visible = false
                        end
                    end
                end
            end

            -- Anti-Aim
            if getgenv().AntiAim and Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
                local rootPart = Client.Character.HumanoidRootPart
                
                if getgenv().AntiAimType == "Spin" then
                    AntiAimAngle = AntiAimAngle + getgenv().AntiAimSpeed
                    if AntiAimAngle >= 360 then AntiAimAngle = 0 end
                    
                    rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(AntiAimAngle), 0)
                    
                elseif getgenv().AntiAimType == "Jitter" then
                    AntiAimAngle = math.random(-180, 180)
                    rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(
                        math.rad(math.random(-10, 10)),
                        math.rad(AntiAimAngle),
                        math.rad(math.random(-10, 10))
                    )
                    
                elseif getgenv().AntiAimType == "Random" then
                    rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(
                        math.rad(math.random(-180, 180)),
                        math.rad(math.random(-180, 180)),
                        math.rad(math.random(-180, 180))
                    )
                end
            end

            -- Resolver
            if getgenv().Resolver and AimlockTarget then
                ResolverOffset = CalculateResolverOffset(AimlockTarget)
                
                -- Apply resolver offset to aim position
                if AimlockTarget.Character and AimlockTarget.Character:FindFirstChild(getgenv().AimPart) then
                    local aimPart = AimlockTarget.Character[getgenv().AimPart]
                    local resolvedPosition = aimPart.Position + ResolverOffset
                    
                    if getgenv().PredictMovement then
                        resolvedPosition = resolvedPosition + (aimPart.Velocity / getgenv().PredictionVelocity)
                    end
                    
                    -- Update camera position with resolved position
                    if getgenv().Smoothness then
                        local main = CF(Camera.CFrame.p, resolvedPosition)
                        Camera.CFrame = Camera.CFrame:Lerp(main, getgenv().SmoothnessAmount, Enum.EasingStyle.Elastic, Enum.EasingDirection.InOut)
                    else
                        Camera.CFrame = CF(Camera.CFrame.p, resolvedPosition)
                    end
                end
            end

            -- Inside your RenderStepped connection
            if getgenv().LegitAA then
                DoLegitAA()
            end

            if getgenv().SpeedHack then
                UpdateSpeed()
            end
        end)
    end)

    -- Add ESP functionality
    local ESP
    local success, result = pcall(function()
        ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiriot22/ESP-Lib/main/ESP.lua"))()
    end)

    if not success then
        warn("Failed to load ESP library:", result)
        ESP = {
            Toggle = function() end,
            Players = {},
            Boxes = false,
            Names = false,
            -- Add other default values
        }
    end

    -- Initialize ESP settings
    ESP:Toggle(false)
    ESP.Boxes = true
    ESP.Names = true
    ESP.Players = true
    ESP.FaceCamera = true
    ESP.Glow = false

    -- Add Triggerbot functionality
    spawn(function()
        while true do
            wait()  -- Small wait to prevent excessive CPU usage
            
            if getgenv().TriggerBot then
                local Target = Mouse.Target
                if Target and Target.Parent then
                    -- Check if target is a player character
                    local Player = Players:GetPlayerFromCharacter(Target.Parent)
                    
                    if Player and Player ~= Client then  -- Make sure we're not targeting ourselves
                        -- Team check
                        if not getgenv().TeamCheck or Player.Team ~= Client.Team then
                            -- Ensure the target is alive and has a humanoid
                            local humanoid = Player.Character:FindFirstChild("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                -- Check if the target is within the aim radius
                                local targetPosition = Player.Character:FindFirstChild(getgenv().AimPart).Position
                                local distance = (targetPosition - Client.Character.HumanoidRootPart.Position).Magnitude
                                
                                if distance <= getgenv().AimRadius then
                                    -- Add delay if specified
                                    if getgenv().TriggerDelay > 0 then
                                        wait(getgenv().TriggerDelay)
                                    end
                                    
                                    -- Simulate mouse click
                                    local VirtualUser = game:GetService("VirtualUser")
                                    VirtualUser:Button1Down(Vector2.new(0,0))
                                    wait(0.05)
                                    VirtualUser:Button1Up(Vector2.new(0,0))
                                    
                                    -- Add a small cooldown to prevent rapid firing
                                    wait(0.1)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Make sure ESPSettings exists before using it
    if not ESPSettings then
        ESPSettings = {
            Enabled = false
        }
    end

    -- Basic UI without any dependencies
    local ScreenGui = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local KeybindList = Instance.new("TextLabel")

    pcall(function()
        if game:GetService("CoreGui"):FindFirstChild("KeybindListGui") then
            game:GetService("CoreGui").KeybindListGui:Destroy()
        end
    end)

    ScreenGui.Name = "KeybindListGui"
    ScreenGui.Parent = game:GetService("CoreGui")

    Frame.Name = "MainFrame"
    Frame.Parent = ScreenGui
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BackgroundTransparency = 0.5
    Frame.Position = UDim2.new(0, 5, 0, 5)
    Frame.Size = UDim2.new(0, 200, 0, 100)

    KeybindList.Name = "KeybindList"
    KeybindList.Parent = Frame
    KeybindList.BackgroundTransparency = 1
    KeybindList.Position = UDim2.new(0, 10, 0, 10)
    KeybindList.Size = UDim2.new(1, -20, 1, -20)
    KeybindList.Font = Enum.Font.Code
    KeybindList.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeybindList.TextSize = 14
    KeybindList.TextXAlignment = Enum.TextXAlignment.Left
    KeybindList.TextYAlignment = Enum.TextYAlignment.Top

    -- Safe update function
    local function SafeUpdate()
        pcall(function()
            local text = "Flynn's Aimbot\n\n"
            text = text .. "Aimlock: " .. string.upper(getgenv().AimlockKey) .. "\n"
            text = text .. "Triggerbot: " .. string.upper(getgenv().TriggerKey) .. " (" .. (getgenv().TriggerBot and "ON" or "OFF") .. ")\n"
            text = text .. "Target Part: " .. getgenv().AimPart
            KeybindList.Text = text
        end)
    end

    -- Connect update with error handling
    game:GetService("RunService").RenderStepped:Connect(SafeUpdate)

    -- Clean up when the script stops
    game:GetService("CoreGui").ChildRemoved:Connect(function(child)
        if child.Name == "Flux" then
            ScreenGui:Destroy()
        end
    end)

    -- Legit Anti-Aim function
    local function DoLegitAA()
        if not Client.Character or not Client.Character:FindFirstChild("HumanoidRootPart") then return end
        local rootPart = Client.Character.HumanoidRootPart
        
        -- Get mouse position relative to character
        local mousePos = Mouse.Hit.Position
        local charPos = rootPart.Position
        local angle = math.deg(math.atan2(mousePos.X - charPos.X, mousePos.Z - charPos.Z))
        
        -- Apply the anti-aim offset
        local finalAngle = angle + (getgenv().LegitAAAngle * (math.random() > 0.5 and 1 or -1))
        rootPart.CFrame = CFrame.new(charPos) * CFrame.Angles(0, math.rad(finalAngle), 0)
    end

    -- Speedhack function
    local function UpdateSpeed()
        pcall(function()
            if not Client or not Client.Character then return end
            local humanoid = Client.Character:FindFirstChild("Humanoid")
            if not humanoid then return end
            
            if getgenv().SpeedHack then
                humanoid.WalkSpeed = getgenv().SpeedValue
            else
                humanoid.WalkSpeed = 16 -- Reset to default speed
            end
        end)
    end
