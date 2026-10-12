
-- AUTO FARM PRO NEON | Roblox Studio
-- LocalScript: StarterPlayer > StarterPlayerScripts
-- NPCs: workspace.Enemies
--
-- Inclui:
-- Auto Aim, FOV, seleção de partes, ESP, Auto Farm,
-- órbita, movimento, informações de ferramentas e filtros.
--
-- Demo para seu próprio jogo.
-- O movimento local não substitui a validação do servidor.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    Aim = false,
    Farm = false,
    ESP = true,
    FOV = true,
    Orbit = false,

    AimRange = 300,
    FOVRadius = 140,
    AimSmoothness = 8,

    Speed = 35,
    Distance = 20,
    OrbitRadius = 20,
    OrbitSpeed = 1.5,

    BodyPart = "UpperTorso",
    NameFilter = "",
    IgnoreNames = "",
}

local COLORS = {
    Background = Color3.fromRGB(16, 12, 30),
    Panel = Color3.fromRGB(26, 19, 48),
    Button = Color3.fromRGB(48, 32, 78),
    Neon = Color3.fromRGB(0, 220, 255),
    Purple = Color3.fromRGB(175, 70, 255),
    Text = Color3.fromRGB(245, 240, 255),
    Muted = Color3.fromRGB(165, 155, 190),
    Green = Color3.fromRGB(70, 255, 170),
    Red = Color3.fromRGB(255, 90, 120),
}

local running = true
local target = nil
local orbitAngle = 0
local espObjects = {}
local connections = {}

local function track(connection)
    table.insert(connections, connection)
    return connection
end

local function getCharacter()
    return player.Character
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function getAimPart(model)
    if not model then
        return nil
    end

    local part = model:FindFirstChild(CONFIG.BodyPart)
    if part and part:IsA("BasePart") then
        return part
    end

    -- Fallbacks para rigs R6/R15
    return model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("HumanoidRootPart")
end

local function getEnemyFolder()
    return workspace:FindFirstChild("Enemies")
end

local function matchesList(name, listText)
    for item in string.gmatch(listText, "[^,]+") do
        local trimmed = string.match(item, "^%s*(.-)%s*$")
        if trimmed ~= "" and string.lower(name) == string.lower(trimmed) then
            return true
        end
    end
    return false
end

local function isValidEnemy(model)
    if not model or not model:IsA("Model") then
        return false
    end

    if not model:IsDescendantOf(workspace) then
        return false
    end

    local folder = getEnemyFolder()
    if not folder or not model:IsDescendantOf(folder) then
        return false
    end

    local humanoid = getHumanoid(model)
    local root = getRoot(model)

    if not humanoid or humanoid.Health <= 0 or not root then
        return false
    end

    if CONFIG.NameFilter ~= ""
        and not string.find(
            string.lower(model.Name),
            string.lower(CONFIG.NameFilter),
            1,
            true
        )
    then
        return false
    end

    if matchesList(model.Name, CONFIG.IgnoreNames) then
        return false
    end

    return true
end

-- INTERFACE

local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmProNeon"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(330, 475)
panel.Position = UDim2.new(0.5, -165, 0.5, -237)
panel.BackgroundColor3 = COLORS.Background
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COLORS.Purple
panelStroke.Thickness = 2
panelStroke.Parent = panel

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -85, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "✦ AUTO FARM PRO"
title.TextColor3 = COLORS.Neon
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(34, 30)
minimize.Position = UDim2.new(1, -40, 0, 6)
minimize.BackgroundColor3 = COLORS.Button
minimize.Text = "—"
minimize.TextColor3 = COLORS.Text
minimize.TextSize = 18
minimize.Parent = header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimize

-- Arrastar painel pelo cabeçalho
do
    local dragging = false
    local dragStart
    local startPosition

    track(header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = panel.Position
        end
    end))

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local content = Instance.new("ScrollingFrame")
content.Name = "Settings"
content.Position = UDim2.fromOffset(10, 50)
content.Size = UDim2.new(1, -20, 1, -60)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = COLORS.Purple
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local function makeLabel(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.Neon
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = content
    return label
end

local function makeButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 34)
    button.BackgroundColor3 = COLORS.Button
    button.BorderSizePixel = 0
    button.TextColor3 = COLORS.Text
    button.Text = text
    button.TextSize = 13
    button.Font = Enum.Font.GothamMedium
    button.Parent = content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Purple
    stroke.Transparency = 0.55
    stroke.Parent = button

    track(button.Activated:Connect(callback))
    return button
end

local function makeInput(placeholder, initial, callback)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -4, 0, 34)
    box.BackgroundColor3 = COLORS.Panel
    box.BorderSizePixel = 0
    box.TextColor3 = COLORS.Text
    box.PlaceholderColor3 = COLORS.Muted
    box.PlaceholderText = placeholder
    box.Text = initial
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.Parent = content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = box

    track(box.FocusLost:Connect(function()
        callback(box.Text)
    end))

    return box
end

local function makeStatus()
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 42)
    label.BackgroundColor3 = COLORS.Panel
    label.TextColor3 = COLORS.Green
    label.TextWrapped = true
    label.Text = "Pronto | Nenhum alvo"
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = content
    return label
end

local status = makeStatus()

-- FOV: círculo de interface, não uma função de disparo
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(
    CONFIG.FOVRadius * 2,
    CONFIG.FOVRadius * 2
)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = CONFIG.FOV
fovCircle.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = COLORS.Neon
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.15
fovStroke.Parent = fovCircle

-- ESP
local function clearESP(model)
    local entry = espObjects[model]
    if not entry then
        return
    end

    if entry.highlight then
        entry.highlight:Destroy()
    end

    if entry.billboard then
        entry.billboard:Destroy()
    end

    espObjects[model] = nil
end

local function createESP(model)
    if espObjects[model] or not isValidEnemy(model) then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "DemoESPHighlight"
    highlight.Adornee = model
    highlight.FillColor = COLORS.Purple
    highlight.OutlineColor = COLORS.Neon
    highlight.FillTransparency = 0.8
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = gui

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DemoESPLabel"
    billboard.Adornee = getRoot(model)
    billboard.Size = UDim2.fromOffset(180, 32)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = COLORS.Neon
    label.TextStrokeTransparency = 0.35
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Text = model.Name
    label.Parent = billboard

    espObjects[model] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
    }
end

local function refreshESP()
    local folder = getEnemyFolder()
    if not folder then
        for model in pairs(espObjects) do
            clearESP(model)
        end
        return
    end

    for model in pairs(espObjects) do
        if not CONFIG.ESP or not isValidEnemy(model) then
            clearESP(model)
        end
    end

    if not CONFIG.ESP then
        return
    end

    for _, model in ipairs(folder:GetChildren()) do
        if isValidEnemy(model) then
            createESP(model)

            local entry = espObjects[model]
            local root = getRoot(model)
            local characterRoot = getRoot(getCharacter())

            if entry and root and characterRoot then
                local distance =
                    (root.Position - characterRoot.Position).Magnitude
                entry.label.Text = string.format(
                    "%s | %.0f studs",
                    model.Name,
                    distance
                )
            end
        end
    end
end

-- Seleção de alvo
local function getNearestEnemy(maxDistance, useFOV)
    local folder = getEnemyFolder()
    local root = getRoot(getCharacter())
    local camera = workspace.CurrentCamera

    if not folder or not root or not camera then
        return nil
    end

    local nearest
    local bestScore = math.huge
    local viewport = camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X / 2, viewport.Y / 2)

    for _, model in ipairs(folder:GetChildren()) do
        if isValidEnemy(model) then
            local part = getAimPart(model)
            local distance = (root.Position - part.Position).Magnitude

            if distance <= maxDistance then
                local screenPoint, onScreen =
                    camera:WorldToViewportPoint(part.Position)

                local screenDistance = (
                    Vector2.new(screenPoint.X, screenPoint.Y)
                    - screenCenter
                ).Magnitude

                if not useFOV or (
                    onScreen and screenDistance <= CONFIG.FOVRadius
                ) then
                    local score = useFOV
                        and screenDistance
                        or distance

                    if score < bestScore then
                        bestScore = score
                        nearest = model
                    end
                end
            end
        end
    end

    return nearest
end

-- Botões e controles
makeLabel("COMBATE / MIRA")

local aimButton
aimButton = makeButton("AUTO AIM: OFF", function()
    CONFIG.Aim = not CONFIG.Aim
    aimButton.Text = "AUTO AIM: " .. (CONFIG.Aim and "ON" or "OFF")
    aimButton.BackgroundColor3 = CONFIG.Aim and COLORS.Purple or COLORS.Button
end)

local fovButton
fovButton = makeButton("FOV: ON", function()
    CONFIG.FOV = not CONFIG.FOV
    fovCircle.Visible = CONFIG.FOV
    fovButton.Text = "FOV: " .. (CONFIG.FOV and "ON" or "OFF")
end)

local smoothButton
smoothButton = makeButton("SUAVIDADE: 8", function()
    CONFIG.AimSmoothness = CONFIG.AimSmoothness + 4
    if CONFIG.AimSmoothness > 20 then
        CONFIG.AimSmoothness = 4
    end
    smoothButton.Text = "SUAVIDADE: " .. CONFIG.AimSmoothness
end)

local bodyButton
bodyButton = makeButton("PARTE: UPPER TORSO", function()
    local parts = {
        "UpperTorso",
        "Torso",
        "Head",
        "HumanoidRootPart",
    }

    local index = table.find(parts, CONFIG.BodyPart) or 1
    index = index % #parts + 1
    CONFIG.BodyPart = parts[index]
    bodyButton.Text = "PARTE: " .. string.upper(CONFIG.BodyPart)
end)

local rangeButton
rangeButton = makeButton("ALCANCE AIM: 300", function()
    CONFIG.AimRange = CONFIG.AimRange + 100
    if CONFIG.AimRange > 500 then
        CONFIG.AimRange = 100
    end
    rangeButton.Text = "ALCANCE AIM: " .. CONFIG.AimRange
end)

local radiusButton
radiusButton = makeButton("RAIO FOV: 140", function()
    CONFIG.FOVRadius = CONFIG.FOVRadius + 40
    if CONFIG.FOVRadius > 260 then
        CONFIG.FOVRadius = 60
    end

    fovCircle.Size = UDim2.fromOffset(
        CONFIG.FOVRadius * 2,
        CONFIG.FOVRadius * 2
    )
    radiusButton.Text = "RAIO FOV: " .. CONFIG.FOVRadius
end)

makeLabel("FARM / MOVIMENTO")

local farmButton
farmButton = makeButton("AUTO FARM: OFF", function()
    CONFIG.Farm = not CONFIG.Farm
    farmButton.Text = "AUTO FARM: " .. (CONFIG.Farm and "ON" or "OFF")
    farmButton.BackgroundColor3 = CONFIG.Farm and COLORS.Purple or COLORS.Button
end)

local orbitButton
orbitButton = makeButton("MODO ÓRBITA: OFF", function()
    CONFIG.Orbit = not CONFIG.Orbit
    orbitButton.Text = "MODO ÓRBITA: " .. (CONFIG.Orbit and "ON" or "OFF")
end)

local speedButton
speedButton = makeButton("VELOCIDADE: 35", function()
    CONFIG.Speed = CONFIG.Speed + 10
    if CONFIG.Speed > 65 then
        CONFIG.Speed = 15
    end
    speedButton.Text = "VELOCIDADE: " .. CONFIG.Speed
end)

local distanceButton
distanceButton = makeButton("DISTÂNCIA: 20", function()
    CONFIG.Distance = CONFIG.Distance + 10
    if CONFIG.Distance > 50 then
        CONFIG.Distance = 10
    end
    distanceButton.Text = "DISTÂNCIA: " .. CONFIG.Distance
end)

local orbitSpeedButton
orbitSpeedButton = makeButton("VELOCIDADE ÓRBITA: 1.5", function()
    CONFIG.OrbitSpeed = CONFIG.OrbitSpeed + 0.5
    if CONFIG.OrbitSpeed > 3 then
        CONFIG.OrbitSpeed = 0.5
    end
    orbitSpeedButton.Text =
        "VELOCIDADE ÓRBITA: " .. CONFIG.OrbitSpeed
end)

makeLabel("ESP / FILTROS")

local espButton
espButton = makeButton("ESP: ON", function()
    CONFIG.ESP = not CONFIG.ESP
    espButton.Text = "ESP: " .. (CONFIG.ESP and "ON" or "OFF")
    if not CONFIG.ESP then
        for model in pairs(espObjects) do
            clearESP(model)
        end
    end
end)

makeInput("Filtro de nome (vazio = todos)", "", function(value)
    CONFIG.NameFilter = value
    target = nil
end)

makeInput("Ignorar nomes separados por vírgula", "", function(value)
    CONFIG.IgnoreNames = value
    target = nil
end)

makeLabel("INFORMAÇÕES DA ARMA")

local weaponInfo = makeLabel("Ferramenta: nenhuma")
weaponInfo.TextColor3 = COLORS.Text
weaponInfo.TextWrapped = true
weaponInfo.Size = UDim2.new(1, -4, 0, 40)

makeLabel("STATUS")

makeButton("LIMPAR ALVO", function()
    target = nil
end)

-- Minimizar / restaurar
local minimized = false
track(minimize.Activated:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    panel.Size = minimized
        and UDim2.fromOffset(330, 42)
        or UDim2.fromOffset(330, 475)
    minimize.Text = minimized and "+" or "—"
end))

-- Loop principal da câmera, ESP e informações
local espTimer = 0

track(RunService.RenderStepped:Connect(function(dt)
    if not running then
        return
    end

    local camera = workspace.CurrentCamera
    local character = getCharacter()
    local root = getRoot(character)
    local humanoid = getHumanoid(character)

    espTimer = espTimer + dt
    if espTimer >= 0.25 then
        espTimer = 0
        refreshESP()

        local tool = character and character:FindFirstChildOfClass("Tool")
        if tool then
            local ammo = tool:GetAttribute("Ammo")
            local magazine = tool:GetAttribute("Magazine")
            local reloading = tool:GetAttribute("Reloading")

            local details = tool.Name

            if ammo ~= nil then
                details = details .. " | Munição: " .. tostring(ammo)
            end

            if magazine ~= nil then
                details = details .. "/" .. tostring(magazine)
            end

            if reloading ~= nil then
                details = details .. (reloading and " | Recarregando" or " | Pronta")
            end

            weaponInfo.Text = "Ferramenta: " .. details
        else
            weaponInfo.Text = "Ferramenta: nenhuma equipada"
        end
    end

    if not root or not humanoid or humanoid.Health <= 0 then
        status.Text = "Aguardando personagem vivo"
        return
    end

    if CONFIG.Aim then
        if not isValidEnemy(target) then
            target = getNearestEnemy(CONFIG.AimRange, CONFIG.FOV)
        end

        if isValidEnemy(target) and camera then
            local part = getAimPart(target)
            local distance = (root.Position - part.Position).Magnitude

            if distance <= CONFIG.AimRange then
                local desired = CFrame.lookAt(
                    camera.CFrame.Position,
                    part.Position
                )

                local alpha = 1 - math.exp(-CONFIG.AimSmoothness * dt)
                camera.CFrame = camera.CFrame:Lerp(desired, alpha)
            else
                target = nil
            end
        end
    end

    if CONFIG.Farm then
        if not isValidEnemy(target) then
            target = getNearestEnemy()
        end

        if isValidEnemy(target) then
            local enemyRoot = getRoot(target)

            if enemyRoot then
                local destination

                if CONFIG.Orbit then
                    orbitAngle = orbitAngle + CONFIG.OrbitSpeed * dt

                    destination = enemyRoot.Position + Vector3.new(
                        math.cos(orbitAngle) * CONFIG.OrbitRadius,
                        2,
                        math.sin(orbitAngle) * CONFIG.OrbitRadius
                    )
                else
                    local direction = root.Position - enemyRoot.Position

                    if direction.Magnitude < 0.01 then
                        direction = Vector3.new(1, 0, 0)
                    else
                        direction = direction.Unit
                    end

                    destination = enemyRoot.Position
                        + direction * CONFIG.Distance
                        + Vector3.new(0, 2, 0)
                end

                local offset = destination - root.Position
                local step = math.min(
                    CONFIG.Speed * dt,
                    offset.Magnitude
                )

                if offset.Magnitude > 1 then
                    root.CFrame = CFrame.lookAt(
                        root.Position + offset.Unit * step,
                        enemyRoot.Position
                    )
                end
            end
        end
    end

    if isValidEnemy(target) then
        status.Text = string.format(
            "Alvo: %s | Farm: %s | Aim: %s",
            target.Name,
            CONFIG.Farm and "ON" or "OFF",
            CONFIG.Aim and "ON" or "OFF"
        )
        status.TextColor3 = COLORS.Green
    else
        status.Text = "Nenhum alvo válido"
        status.TextColor3 = COLORS.Muted
    end
end))

-- Limpeza ao remover a interface
track(gui.Destroying:Connect(function()
    running = false

    for model in pairs(espObjects) do
        clearESP(model)
    end

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
end))

track(player.CharacterAdded:Connect(function()
    target = nil
end))
