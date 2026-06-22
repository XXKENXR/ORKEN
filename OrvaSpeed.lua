-- [ORVA] +1 Speed - Auto Farm Mejorado (Recorre Mapa + 200M Wins)

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local speedEnabled = true
local autoWalkEnabled = true
local autoFarmEnabled = true
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

-- Auto Walk + Jump
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

-- Auto Farm hacia Win Blocks (mejorado)
local farmConn
if autoFarmEnabled then
    farmConn = RunService.Heartbeat:Connect(function()
        local root = getRoot()
        if not root then return end
        
        local closest = nil
        local minDist = math.huge
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("win") or name:find("victory") or name:find("finish") or name:find("goal") then
                    local dist = (obj.Position - root.Position).Magnitude
                    if dist < minDist and dist < 800 then
                        minDist = dist
                        closest = obj
                    end
                end
            end
        end
        
        if closest then
            local dir = (closest.Position - root.Position).Unit
            -- Impulso fuerte hacia el win, con componente vertical para sortear obstáculos
            root.Velocity = dir * 150 + Vector3.new(0, 25, 0)
        else
            -- Si no encuentra win block, sigue caminando recto
            local hum = getHum()
            if hum then hum:Move(Vector3.new(0,0,-1), true) end
        end
    end)
end

-- Delete Obstacles (ejecútalo manualmente con G o botón)
local function deleteObstacles()
    local count = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide and v.Size.Y < 50 then
            local n = v.Name:lower()
            if n:find("wall") or n:find("spike") or n:find("trap") or n:find("kill") or n:find("obstacle") then
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

-- Tecla para Delete
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.G then
        deleteObstacles()
    end
end)

print("✅ [ORVA] Auto Farm cargado - Recorriendo mapa hacia Wins")
pcall(function()
    game.StarterGui:SetCore("SendNotification", {Title="Orva Auto Farm", Text="Activado - Presiona G para Delete Obstacles", Duration=6})
end)
