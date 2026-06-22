-- [+1 Speed Keyboard Escape] GUI Simple y Estable - Estilo Orva

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Crear GUI con protección
local success, err = pcall(function()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OrvaGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player:WaitForChild("PlayerGui", 5)

    -- Frame Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
    TitleBar.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ +1 Speed - World 2"
    Title.TextColor3 = Color3.fromRGB(0, 0, 0)
    Title.TextSize = 17
    Title.Font = Enum.Font.GothamBold
    Title.Parent = TitleBar

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 70, 0, 30)
    MinBtn.Position = UDim2.new(1, -75, 0.5, -15)
    MinBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    MinBtn.Text = "▼"
    MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
    MinBtn.Parent = TitleBar

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, -45)
    Content.Position = UDim2.new(0, 0, 0, 45)
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame

    -- Variables
    local speedEnabled = false
    local autoWalkEnabled = false
    local baseSpeed = 16
    local multiplier = 4
    local autoWalkConn = nil
    local minimized = false

    local function getHum()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            return player.Character.Humanoid
        end
        return nil
    end

    local function updateSpeed()
        local hum = getHum()
        if hum then
            hum.WalkSpeed = speedEnabled and baseSpeed * multiplier or baseSpeed
        end
    end

    local function toggleAutoWalk(state)
        autoWalkEnabled = state
        if state then
            if autoWalkConn then autoWalkConn:Disconnect() end
            autoWalkConn = RunService.Heartbeat:Connect(function()
                local hum = getHum()
                if hum then
                    hum:Move(Vector3.new(0,0,-1), true)
                end
            end)
        else
            if autoWalkConn then
                autoWalkConn:Disconnect()
                autoWalkConn = nil
            end
        end
    end

    local function deleteObstacles()
        local count = 0
        for _, v in ipairs(game.Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide and v.Size.Y < 25 then
                local n = v.Name:lower()
                if n:find("wall") or n:find("spike") or n:find("trap") or n:find("kill") or n:find("obstacle") then
                    v.CanCollide = false
                    v.Transparency = 0.6
                    count += 1
                end
            end
        end
        game.StarterGui:SetCore("SendNotification", {
            Title = "Delete Obstacles";
            Text = "Eliminados: " .. count;
            Duration = 3;
        })
    end

    -- Toggles
    local function makeToggle(posY, text, callback)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -20, 0, 50)
        f.Position = UDim2.new(0, 10, 0, posY)
        f.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        f.Parent = Content
        Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.6,0,1,0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.new(1,1,1)
        l.TextSize = 16
        l.Font = Enum.Font.GothamSemibold
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 85, 0, 35)
        b.Position = UDim2.new(1, -95, 0.5, -17.5)
        b.BackgroundColor3 = Color3.fromRGB(60,60,70)
        b.Text = "OFF"
        b.TextColor3 = Color3.fromRGB(255,80,80)
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)

        local on = false
        b.MouseButton1Click:Connect(function()
            on = not on
            if on then
                b.Text = "ON"
                b.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            else
                b.Text = "OFF"
                b.BackgroundColor3 = Color3.fromRGB(60,60,70)
            end
            callback(on)
        end)
    end

    makeToggle(10, "🚀 Speed Boost (x4)", function(s) speedEnabled = s; updateSpeed() end)
    makeToggle(70, "🚶 Auto Walk", toggleAutoWalk)

    local delBtn = Instance.new("TextButton")
    delBtn.Size = UDim2.new(1, -20, 0, 55)
    delBtn.Position = UDim2.new(0,10,0,140)
    delBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    delBtn.Text = "🗑️ DELETE OBSTACLES (World 2)"
    delBtn.TextColor3 = Color3.new(1,1,1)
    delBtn.TextSize = 15
    delBtn.Font = Enum.Font.GothamBold
    delBtn.Parent = Content
    Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0,10)

    delBtn.MouseButton1Click:Connect(deleteObstacles)

    -- Minimize
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        MainFrame.Size = minimized and UDim2.new(0,320,0,45) or UDim2.new(0,320,0,420)
        MinBtn.Text = minimized and "▲" or "▼"
    end)

    -- Draggable
    local dragging, dragInput, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Updates
    player.CharacterAdded:Connect(function() task.wait(1); updateSpeed() end)
    RunService.Heartbeat:Connect(updateSpeed)

    print("✅ GUI cargada correctamente!")
end)

if not success then
    warn("Error al crear GUI: " .. tostring(err))
    -- Fallback: Notificación
    game.StarterGui:SetCore("SendNotification", {
        Title = "Error";
        Text = "No se pudo crear la GUI. Intenta de nuevo.";
        Duration = 5;
    })
end
