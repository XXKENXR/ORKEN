-- [+1 Speed Keyboard Escape] GUI Mejorada - World 2 (Fix Speed + Auto Walk)

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OrvaFixedGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 420)
MainFrame.Position = UDim2.new(0.5, -170, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ +1 Speed - World 2"
Title.TextColor3 = Color3.fromRGB(0,0,0)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 70, 0, 35)
MinBtn.Position = UDim2.new(1, -80, 0.5, -17.5)
MinBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
MinBtn.Text = "▼"
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -50)
Content.Position = UDim2.new(0,0,0,50)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Content UI: botones simples
local function makeButton(name, text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 260, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.Parent = Content
    local cr = Instance.new("UICorner", btn)
    cr.CornerRadius = UDim.new(0,8)
    return btn
end

local SpeedBtn = makeButton("SpeedBtn", "Enable Speed (+1)", 20)
local AutoBtn = makeButton("AutoBtn", "Enable Auto Walk", 80)
local DeleteBtn = makeButton("DeleteBtn", "Delete Obstacles (Aggressive)", 140)

-- Variables
local speedEnabled = false
local autoWalkEnabled = false
local baseSpeed = 16
local multiplier = 6  -- Más alto
local autoConn = nil
local speedLoop = nil
local minimized = false

local function getHum()
    return player.Character and player.Character:FindFirstChild("Humanoid")
end

-- SPEED FIJA (más confiable)
local function toggleSpeed(state)
    speedEnabled = state
    if speedLoop then speedLoop:Disconnect() speedLoop = nil end
    if state then
        speedLoop = RunService.Heartbeat:Connect(function()
            local hum = getHum()
            if hum then
                hum.WalkSpeed = baseSpeed * multiplier
                -- Extra boost (suave)
                local root = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")
                if root then
                    -- evitar valores NaN o exponenciales: aplicar una pequeña corrección
                    local vel = root.Velocity
                    root.Velocity = Vector3.new(vel.X * 1.02, vel.Y, vel.Z * 1.02)
                end
            end
        end)
    else
        local hum = getHum()
        if hum then
            hum.WalkSpeed = baseSpeed
        end
    end
end

-- AUTO WALK MEJORADO
local function toggleAutoWalk(state)
    autoWalkEnabled = state
    if autoConn then autoConn:Disconnect() autoConn = nil end
    if state then
        autoConn = RunService.Heartbeat:Connect(function()
            local hum = getHum()
            if hum then
                -- Mover hacia adelante relativo al root's lookVector
                local root = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")
                if root then
                    local look = root.CFrame.LookVector
                    hum:Move(Vector3.new(look.X, 0, look.Z), true)
                else
                    hum:Move(Vector3.new(0,0,-1), true)
                end
                -- Pequeño salto automático para obstáculos bajos
                if hum:GetState() == Enum.HumanoidStateType.Running and math.random(1,15) == 1 then
                    hum.Jump = true
                end
            end
        end)
    end
end

-- DELETE OBSTACLES MÁS AGRESIVO
local function deleteObstacles()
    local count = 0
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanCollide then
            local n = obj.Name:lower()
            if n:find("wall") or n:find("spike") or n:find("trap") or n:find("kill") or n:find("obstacle") or n:find("brain") then
                if obj.Size.Y < 40 then
                    -- Desactivar colisiones y hacer casi invisible
                    pcall(function()
                        obj.CanCollide = false
                        obj.Transparency = 0.95
                        -- Si es muy pequeño, destruimos para asegurar paso
                        if obj.Size.Magnitude <= 20 then
                            obj:Destroy()
                        end
                    end)
                    count = count + 1
                end
            end
        end
    end
    -- Notificar al jugador
    pcall(function()
        if player and player:FindFirstChild("PlayerGui") then
            local msg = Instance.new("Message")
            msg.Text = "OrvaFix: Removed/disabled " .. tostring(count) .. " obstacles"
            msg.Parent = player.PlayerGui
            delay(2, function() pcall(function() msg:Destroy() end) end)
        end
    end)
end

-- Botones
SpeedBtn.MouseButton1Click:Connect(function()
    toggleSpeed(not speedEnabled)
    SpeedBtn.Text = speedEnabled and "Disable Speed (On)" or "Enable Speed (+1)"
    SpeedBtn.BackgroundColor3 = speedEnabled and Color3.fromRGB(30,160,50) or Color3.fromRGB(40,40,50)
end)

AutoBtn.MouseButton1Click:Connect(function()
    toggleAutoWalk(not autoWalkEnabled)
    AutoBtn.Text = autoWalkEnabled and "Disable Auto Walk (On)" or "Enable Auto Walk"
    AutoBtn.BackgroundColor3 = autoWalkEnabled and Color3.fromRGB(30,160,50) or Color3.fromRGB(40,40,50)
end)

DeleteBtn.MouseButton1Click:Connect(function()
    DeleteBtn.Text = "Deleting..."
    DeleteBtn.BackgroundColor3 = Color3.fromRGB(200,80,20)
    -- Ejecutar en pcall para evitar errores
    local ok, err = pcall(deleteObstacles)
    if not ok then
        DeleteBtn.Text = "Error"
    else
        DeleteBtn.Text = "Delete Obstacles (Aggressive)"
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    end
end)

-- Minimizar (manteniendo la TitleBar visible)
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MinBtn.Text = minimized and "▲" or "▼"
end)

-- Esc para minimizar/restaurar
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Escape then
        minimized = not minimized
        Content.Visible = not minimized
        MinBtn.Text = minimized and "▲" or "▼"
    end
end)

-- Dragging the window by TitleBar
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Limpieza al salir/respawn
player.CharacterRemoving:Connect(function()
    toggleSpeed(false)
    toggleAutoWalk(false)
end)

-- Inicialización: aplicar estado por defecto (apagado)
toggleSpeed(false)
toggleAutoWalk(false)

