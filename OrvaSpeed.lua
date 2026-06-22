-- [ORVA] +1 Speed - Auto Farm Mejorado (Recorre Etapas 1..15 con Auto-Delete Obstacles)

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local speedEnabled = true
local autoWalkEnabled = true
local autoFarmEnabled = true
local autoDeleteDuringFarm = true -- nuevo: eliminar obstáculos mientras hace farm
local multiplier = 9

local function getHum() return player.Character and player.Character:FindFirstChild("Humanoid") end
local function getRoot() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end

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

-- NUEVO: Eliminar obstáculos cercanos dentro de un radio
local function deleteNearbyObstacles(origin, radius)
    local count = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide and v.Parent then
            local ok, pos = pcall(function() return v.Position end)
            if ok and pos and (pos - origin).Magnitude <= radius and v.Size.Y < 80 then
                local n = v.Name:lower()
                if n:find("wall") or n:find("spike") or n:find("trap") or n:find("kill") or n:find("obstacle") or n:find("barrier") then
                    pcall(function()
                        v.CanCollide = false
                        v.Transparency = 0.85
                        -- destruir si muy pequeño o peligro de bloqueo
                        if v.Size.Magnitude <= 30 then
                            v:Destroy()
                        end
                    end)
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- AUTO FARM: recorre etapas 1..15 en orden con eliminación opcional de obstáculos
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
                        -- eliminar obstáculos cercanos si está activado
                        if autoDeleteDuringFarm then
                            pcall(function()
                                deleteNearbyObstacles(root.Position, 50) -- radio 50 studs alrededor
                            end)
                        end

                        local dir = (target.Position - root.Position)
                        if dir.Magnitude > 0 then
                            local vel = dir.Unit * 140 + Vector3.new(0, 30, 0)
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
                -- Si no hay partes con número exacto, intentar buscar parts cuyo nombre contenga "stage" sin número
                -- Además podemos eliminar obstáculos en esa zona para intentar pasar
                if autoDeleteDuringFarm and root then
                    pcall(function() deleteNearbyObstacles(root.Position, 60) end)
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

-- Delete Obstacles manual (ejecútalo con G o botón)
local function deleteObstacles()
    local count = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide and v.Size.Y < 80 then
            local n = v.Name:lower()
            if n:find("wall") or n:find("spike") or n:find("trap") or n:find("kill") or n:find("obstacle") or n:find("barrier") then
                pcall(function()
                    v.CanCollide = false
                    v.Transparency = 0.75
                end)
                count = count + 1
            end
        end
    end
    print("Obstáculos eliminados: " .. count)
end

-- Teclas para controlar
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then
        deleteObstacles()
    elseif input.KeyCode == Enum.KeyCode.F then
        -- alternar autoFarm
        autoFarmEnabled = not autoFarmEnabled
        if autoFarmEnabled then
            farmStages(15)
            print("[OrvaFarm] AutoFarm toggled ON")
        else
            stopFarm()
            print("[OrvaFarm] AutoFarm toggled OFF")
        end
    elseif input.KeyCode == Enum.KeyCode.H then
        -- alternar auto-delete during farm
        autoDeleteDuringFarm = not autoDeleteDuringFarm
        print("[OrvaFarm] autoDeleteDuringFarm = ", tostring(autoDeleteDuringFarm))
    end
end)

print("✅ [ORVA] Auto Farm cargado - Recorriendo etapas 1..15 (Presiona F para alternar, G para eliminar obstáculos, H para toggle auto-delete)")
pcall(function()
    game.StarterGui:SetCore("SendNotification", {Title="Orva Auto Farm", Text="AutoFarm: etapas 1..15 activado. F toggle, G delete, H toggle auto-delete", Duration=6})
end)
