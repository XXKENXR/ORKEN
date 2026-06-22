-- [ORVA] +1 Speed - Auto Farm Mejorado (Recorre Etapas 1..15 con Auto-Delete Obstacles y botones GUI para móvil)

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local speedEnabled = true
local autoWalkEnabled = true
local autoFarmEnabled = true
local autoDeleteDuringFarm = true -- eliminar obstáculos mientras hace farm (ahora más selectivo)
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

-- BUSCAR FOLDER DEL MAPA (World 2) si existe
local function findWorldFolder()
    local candidates = {"World 2", "World2", "World_2", "WorldTwo", "Map", "Maps", "World", "CandyAndChocolate", "CandyWorld"}
    for _, name in ipairs(candidates) do
        local f = workspace:FindFirstChild(name)
        if f and (f:IsA("Model") or f:IsA("Folder")) then
            return f
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

{