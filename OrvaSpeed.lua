-- [ORVA] +1 Speed - Auto Farm Mejorado (Recorre Etapas 1..15 con Auto-Delete Obstacles y botones GUI para móvil)

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local speedEnabled = true
local autoWalkEnabled = true
local autoFarmEnabled = true
local autoDeleteDuringFarm = true -- eliminar obstáculos mientras hace farm (ahora más selectivo)
local multiplier = 9

local function getHum() return player.Character and player.Character:FindFirstChild("Humanoid") end
local function getRoot() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end

-- UI base
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OrvaFixedGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 120)
MainFrame.Position = UDim2.new(0.02, 0, 0.72, 0)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,20)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "Orva AutoFarm (World 2)"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = MainFrame

local function makeTouchButton(text, pos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 96, 0, 36)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    return btn
end

local BtnAutoFarm = makeTouchButton("AutoFarm ON", UDim2.new(0, 8, 0, 36))
local BtnAutoDelete = makeTouchButton("AutoDelete ON", UDim2.new(0, 110, 0, 36))
local BtnDeleteNow = makeTouchButton("Delete Now", UDim2.new(0, 212, 0, 36))

-- Speed Loop Fuerte
RunService.Heartbeat:Connect(function()
    if speedEnabled then
        local hum = getHum()
        if hum then
            hum.WalkSpeed = 16 * multiplier
        end
    end
end)

-- Auto Walk + Jump (fallback if not farming)
local walkConn
if autoWalkEnabled then
    walkConn = RunService.Heartbeat:Connect(function()
        local hum = getHum()
        if hum then
            hum:Move(Vector3.new(0, 0, -1), true)
            if hum:GetState() ~= Enum.HumanoidStateType.Jumping and math.random(1,6) == 1 then
                hum.Jump = true
            end
        end
    end)
end

-- FIND STAGE PARTS
local function findStages()
    local stages = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("stage") or name:find("checkpoint") or name:find("finish") or name:find("win") then
                local num = tonumber(name:match("(%d+)%s*$")) or tonumber(name:match("stage[_%s]*(%d+)")) or tonumber(name:match("checkpoint[_%s]*(%d+)"))
                if num then
                    stages[num] = stages[num] or {}
                    table.insert(stages[num], obj)
                end
            end
        end
    end
    return stages
end

-- Helper: get nearest part from list
local function nearestPart(parts, pos)
    local best, bestD = nil, math.huge
    for _, p in ipairs(parts) do
        if p and p.Parent then
            local ok, d = pcall(function() return (p.Position - pos).Magnitude end)
            if ok and d and d < bestD then
                bestD = d
                best = p
            end
        end
    end
    return best, bestD
end

-- BUSCAR FOLDER DEL MAPA (World 2) si existe (detección automática)
local function findWorldFolder()
    local candidates = {"World 2", "World2", "World_2", "WorldTwo", "Map", "Maps", "World", "CandyAndChocolate", "CandyWorld", "Worlds"}
    for _, name in ipairs(candidates) do
        local f = workspace:FindFirstChild(name)
        if f and (f:IsA("Model") or f:IsA("Folder")) then
            return f
        end
    end
    -- heurística: buscar el modelo con más partes que contenga la palabra "world" o "candy"
    for _, v in ipairs(workspace:GetChildren()) do
        if (v:IsA("Model") or v:IsA("Folder")) then
            local score = 0
            for _, d in ipairs(v:GetDescendants()) do
                if d:IsA("BasePart") then
                    local n = d.Name:lower()
                    if n:find("stage") or n:find("win") then score = score + 1 end
                    if n:find("candy") or n:find("chocolate") then score = score + 1 end
                end
            end
            if score > 6 then return v end
        end
    end
    return nil
end

local worldFolder = findWorldFolder()

-- NUEVO: Eliminar obstáculos SOLO a lo largo del camino entre A y B y preferentemente dentro del folder World2
local function deleteObstaclesAlongPath(a, b, lateralRadius)
    local count = 0
    local ab = b - a
    local abLen2 = ab:Dot(ab)
    if abLen2 == 0 then return 0 end

    local searchRoot = worldFolder or workspace
    for _, v in ipairs(searchRoot:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide and v.Parent then
            -- seguridad: no tocar partes muy grandes o ancladas que parecen suelo principal
            if v.Size.Magnitude > 200 or v.Anchored then
                goto continue
            end
            local ok, pos = pcall(function() return v.Position end)
            if not ok or not pos then goto continue end

            local ap = pos - a
            local t = ab:Dot(ap) / abLen2
            -- solo considerar proyección entre A y B (con margen) y cerca de la línea
            if t >= -0.15 and t <= 1.15 then
                local closestPoint = a + ab * math.clamp(t, 0, 1)
                local lateralDist = (pos - closestPoint).Magnitude
                if lateralDist <= lateralRadius and v.Size.Y < 80 then
                    local n = v.Name:lower()
                    if n:find("wall") or n:find("spike") or n:find("trap") or n:find("kill") or n:find("obstacle") or n:find("barrier") or n:find("spinning") or n:find("block") then
                        pcall(function()
                            v.CanCollide = false
                            v.Transparency = math.max(0.65, v.Transparency)
                            if v.Size.Magnitude <= 60 then
                                v:Destroy()
                            end
                        end)
                        count = count + 1
                    end
                end
            end
        end
        ::continue::
    end
    return count
end

-- AUTO FARM: recorre etapas 1..15 en orden con eliminación opcional de obstáculos (ahora selectivo)
local farmActive = false
local farmThread = nil

local function farmStages(maxStage)
    if farmActive then return end
    farmActive = true
    farmThread = coroutine.create(function()
        local root = getRoot()
        if not root then
            -- esperar a root
            local t = 0
            repeat
                task.wait(0.2)
                root = getRoot()
                t = t + 0.2
                if t > 5 then break end
            until root
        end
        if not root then
            farmActive = false
            return
        end

        local stages = findStages()
        -- determine highest available stage
        local highest = 0
        for k in pairs(stages) do if k > highest then highest = k end end
        local finalStage = math.min(maxStage or 15, highest > 0 and highest or 15)

        for stage = 1, finalStage do
            if not farmActive then break end
            local parts = stages[stage]
            if parts and #parts > 0 then
                local target, dist = nearestPart(parts, root.Position)
                if target then
                    -- acercarse al target hasta distancia pequeña
                    local tries = 0
                    while farmActive and target and target.Parent and root and (target.Position - root.Position).Magnitude > 8 and tries < 600 do
                        -- eliminar obstáculos selectivamente a lo largo del camino si está activado
                        if autoDeleteDuringFarm then
                            pcall(function()
                                deleteObstaclesAlongPath(root.Position, target.Position, 18) -- radio lateral reducido
                            end)
                        end

                        local dir = (target.Position - root.Position)
                        if dir.Magnitude > 0 then
                            local vel = dir.Unit * 120 + Vector3.new(0, 28, 0)
                            pcall(function() root.Velocity = vel end)
                        end

                        task.wait(0.08)
                        tries = tries + 1
                        root = getRoot()
                        if not root then break end
                    end
                    -- si llegamos, esperar un poco para registrar el win
                    task.wait(0.6)
                end
            else
                -- Si no hay parts con número exacto, intentar eliminar obstáculos cerca de la posición objetivo general
                if autoDeleteDuringFarm and root then
                    pcall(function() deleteObstaclesAlongPath(root.Position, root.Position + Vector3.new(0,0,-30), 24) end)
                end
            end
            -- pequeña pausa entre etapas
            task.wait(0.3)
        end

        print("[OrvaFarm] Finished stages up to ", finalStage)
        farmActive = false
    end)
    coroutine.resume(farmThread)
end

local function stopFarm()
    farmActive = false
    farmThread = nil
end

-- comenzar automáticamente si está activado
if autoFarmEnabled then
    task.spawn(function() farmStages(15) end)
end

-- Delete Obstacles manual (ejecútalo con botón o G) — limitado al folder World2 si existe
local function deleteObstacles()
    local count = 0
    local searchRoot = worldFolder or workspace
    for _, v in ipairs(searchRoot:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide and v.Size.Y < 80 then
            if v.Anchored then goto cont end
            local n = v.Name:lower()
            if n:find("wall") or n:find("spike") or n:find("trap") or n:find("kill") or n:find("obstacle") or n:find("barrier") then
                pcall(function()
                    v.CanCollide = false
                    v.Transparency = math.max(0.6, v.Transparency)
                end)
                count = count + 1
            end
        end
        ::cont::
    end
    print("Obstáculos eliminados: " .. count)
    return count
end

-- Teclas para controlar (PC)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then
        deleteObstacles()
    elseif input.KeyCode == Enum.KeyCode.F then
        -- alternar autoFarm
        autoFarmEnabled = not autoFarmEnabled
        if autoFarmEnabled then
            farmStages(15)
            BtnAutoFarm.Text = "AutoFarm ON"
            print("[OrvaFarm] AutoFarm toggled ON")
        else
            stopFarm()
            BtnAutoFarm.Text = "AutoFarm OFF"
            print("[OrvaFarm] AutoFarm toggled OFF")
        end
    elseif input.KeyCode == Enum.KeyCode.H then
        -- alternar auto-delete during farm
        autoDeleteDuringFarm = not autoDeleteDuringFarm
        BtnAutoDelete.Text = autoDeleteDuringFarm and "AutoDelete ON" or "AutoDelete OFF"
        print("[OrvaFarm] autoDeleteDuringFarm = ", tostring(autoDeleteDuringFarm))
    end
end)

-- Buttons (mobile / touch)
BtnAutoFarm.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        farmStages(15)
        BtnAutoFarm.Text = "AutoFarm ON"
    else
        stopFarm()
        BtnAutoFarm.Text = "AutoFarm OFF"
    end
end)

BtnAutoDelete.MouseButton1Click:Connect(function()
    autoDeleteDuringFarm = not autoDeleteDuringFarm
    BtnAutoDelete.Text = autoDeleteDuringFarm and "AutoDelete ON" or "AutoDelete OFF"
end)

BtnDeleteNow.MouseButton1Click:Connect(function()
    BtnDeleteNow.Text = "Deleting..."
    BtnDeleteNow.BackgroundColor3 = Color3.fromRGB(200,80,20)
    local ok, cnt = pcall(deleteObstacles)
    task.wait(0.6)
    BtnDeleteNow.Text = "Delete Now"
    BtnDeleteNow.BackgroundColor3 = Color3.fromRGB(40,40,50)
end)

-- Limpieza al salir/respawn
player.CharacterRemoving:Connect(function()
    stopFarm()
    if walkConn then walkConn:Disconnect() end
end)

print("✅ [ORVA] Auto Farm cargado - Recorrerá etapas 1..15. Usa botones o F/G/H.")
pcall(function()
    game.StarterGui:SetCore("SendNotification", {Title="Orva Auto Farm", Text="AutoFarm cargado. Usa botones o F/G/H.", Duration=6})
end)
