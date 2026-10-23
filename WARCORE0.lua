--[[
    ╔════════════════════════════════════════════════════════════╗
    ║       PROJECT: WARCORE v2.0.0 (CUSTOM UI EDITION)          ║
    ║       STUDIO: WARCORE LABS                                 ║
    ║------------------------------------------------------------║
    ║       INTERFACE PRÓPRIA - SEM RAYFIELD/KAVO/ORION           ║
    ║       MOBILE-FIRST • ARRASTÁVEL • ANIMADA                   ║
    ╚════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

--// =============================================
--// CONFIGURAÇÃO GLOBAL
--// =============================================
getgenv().SystemConfig = {
    -- Combate
    MiraAtiva = false,
    FovRadius = 500,
    Smoothness = 0.35,
    TeamCheck = true,

    -- Vida / Habilidades
    HealthRegenEnabled = false,
    HealthRegenRate = 25,
    CooldownReduceEnabled = false,

    -- Instinto Superior V2 (auto esquiva de golpes/poderes/ataques)
    InstinctV2Enabled = false,
    InstinctRadius = 45,
    InstinctDodgeDistance = 12,
    InstinctCooldown = 0.35,

    -- Invisibilidade (local)
    InvisibleEnabled = false,

    -- Visual / Raio-X
    HighlightEnabled = false,
    HlDepthMode = "AlwaysOnTop",
    HlFillTransparency = 0.5,
    HlEnemyColor = Color3.fromRGB(255, 0, 0),
    DotEnabled = false,
    DotShape = "●",               -- ● ▲ ■ ◆ ★
    LineEnabled = false,
    LineColor = Color3.fromRGB(0, 255, 255),
    LineThickness = 1.5,
    LineOrigin = "Crosshair (centro)",   -- Crosshair (centro) | Baixo (base da tela) | Personagem (pés)
    LineTarget = "Cabeça",               -- Cabeça | Corpo
    LineOutline = false,
    LinePulse = false,

    -- Micro-HUD
    MicroHpEnabled = false,
    MicroDistEnabled = false,
    MicroTextSize = 8,
    MicroWidth = 35,
    DistColor = Color3.fromRGB(255, 255, 255),

    -- Iluminação
    FullBright = false,
    NoShadows = false,
    ClarezaMod = false,

    -- Monitor
    ShowFPS = false,
    ShowPlayers = false,

    -- Movimento
    FlyEnabled = false,
    FlySpeed = 50,
    FlyInfinite = false,
    SpeedEnabled = false,
    SpeedValue = 50,
    JumpEnabled = false,
    JumpPower = 100,
    InfiniteJump = false,

    -- Sistemas
    NoClipEnabled = false,
    TeleportEnabled = false,

    -- Keybinds (nome da tecla; "Nenhuma" = desativado)
    Keybinds = {
        ToggleMenu = "RightShift",
        MiraAtiva = "Nenhuma",
        FlyEnabled = "Nenhuma",
        SpeedEnabled = "Nenhuma",
        NoClipEnabled = "Nenhuma",
        TeleportEnabled = "Nenhuma",
        InstinctV2Enabled = "Nenhuma",
        InvisibleEnabled = "Nenhuma",
    },

    -- ESP (Caixa 2D)
    EspBoxEnabled = false,
    EspHealthEnabled = false,
    EspBoxColor = Color3.fromRGB(255, 0, 0),

    -- Circulo de FOV (raio = FovRadius, em pixels, igual a mira)
    FovCircleEnabled = false,
    FovCircleColor = Color3.fromRGB(255, 255, 255),

    -- Destino salvo (persistido no autosave)
    SavedDestinationActive = false,
    SavedDestinationX = 0,
    SavedDestinationY = 0,
    SavedDestinationZ = 0,
    SavedDestinationName = "",

    -- Anti-Void / Recuperação de posição
    AntiVoidEnabled = false,

    -- Utilidade
    AntiAfkEnabled = false,
    ClockOverrideEnabled = false,
    ClockTime = 14,
}

--// =============================================
--// VARIÁVEIS AUXILIARES
--// =============================================
local NoClipAtivo = false
local isTeleportOpen = false
local NoClipConnection = nil
local flyVelocity = nil
local flyConnection = nil
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50

local OriginalSettings = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    Exposure = Lighting.ExposureCompensation,
}

--// =============================================
--// SISTEMA DE PERSISTÊNCIA (AUTOSAVE / AUTOLOAD)
--// Salva tudo que o usuário deixou ligado e recarrega no próximo uso
--// =============================================
local CONFIG_FILE = "WARCORE0_autosave.json"

local ColorKeys = {}
for _, k in ipairs({ "HlEnemyColor", "LineColor", "DistColor", "EspBoxColor", "FovCircleColor" }) do
    ColorKeys[k] = true
end

local SaveEnabled = (type(writefile) == "function")
local LoadEnabled = (type(readfile) == "function" and type(isfile) == "function")

local function serializeConfig()
    local out = {}
    for k, v in pairs(getgenv().SystemConfig) do
        if typeof(v) == "Color3" then
            out[k] = { __color = true, r = v.R, g = v.G, b = v.B }
        else
            out[k] = v
        end
    end
    return out
end

local function loadConfig()
    if not LoadEnabled or not isfile(CONFIG_FILE) then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not ok or type(data) ~= "table" then return false end
    for k, v in pairs(data) do
        if ColorKeys[k] and type(v) == "table" and v.r then
            getgenv().SystemConfig[k] = Color3.new(v.r, v.g, v.b)
        elseif k == "Keybinds" and type(v) == "table" then
            for kk, vv in pairs(v) do
                if getgenv().SystemConfig.Keybinds[kk] ~= nil then
                    getgenv().SystemConfig.Keybinds[kk] = vv
                end
            end
        elseif getgenv().SystemConfig[k] ~= nil then
            getgenv().SystemConfig[k] = v
        end
    end
    return true
end

local ConfigCarregada = loadConfig()

task.spawn(function()
    if not SaveEnabled then return end
    local last = nil
    while true do
        task.wait(2)
        local snap = HttpService:JSONEncode(serializeConfig())
        if snap ~= last then
            last = snap
            pcall(writefile, CONFIG_FILE, snap)
        end
    end
end)

--// =============================================
--// FUNÇÕES AUXILIARES DE JOGO
--// =============================================

-- Busca o alvo mais próximo
local function getTarget()
    local closest, shortest = nil, getgenv().SystemConfig.FovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                if not (isTeam and getgenv().SystemConfig.TeamCheck) then
                    local pos, vis = Camera:WorldToViewportPoint(head.Position)
                    if vis and pos.Z > 0 then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = head
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- Verifica se o alvo está atrás de parede
local function IsBehindWall(targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {Player.Character, targetPart.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
    return result ~= nil
end

-- Cor da vida conforme a porcentagem (verde -> amarelo -> vermelho)
local function HealthColor(ratio)
    if ratio > 0.6 then
        return Color3.fromRGB(0, 255, 120)
    elseif ratio > 0.3 then
        return Color3.fromRGB(255, 205, 0)
    else
        return Color3.fromRGB(255, 45, 45)
    end
end

-- Redução de cooldown das habilidades (Tools)
local CooldownNamePatterns = {
    "cooldown", "cool_down", "cool down", "recharge", "recarga",
    "recarregar", "reload", "lastuse", "lastused", "nextuse", "nextused",
    "last_use", "next_use", "last_used", "next_used", "waittime", "espera",
    "cooldownend", "cooldownstart", "cooldowntime",
}

local function isCooldownName(name)
    local n = string.lower(tostring(name))
    if n == "cd" or n:sub(1, 3) == "cd_" or n:sub(-3) == "_cd" or n:sub(-2) == "cd" then
        return true
    end
    for _, pattern in ipairs(CooldownNamePatterns) do
        if string.find(n, pattern, 1, true) then
            return true
        end
    end
    return false
end

local function clearCooldownAttributes(instance)
    local ok, attrs = pcall(function() return instance:GetAttributes() end)
    if not ok or type(attrs) ~= "table" then return end
    for name, value in pairs(attrs) do
        if type(value) == "number" and value ~= 0 and isCooldownName(name) then
            pcall(function() instance:SetAttribute(name, 0) end)
        end
    end
end

local function resetToolCooldowns()
    clearCooldownAttributes(Player)
    local char = Player.Character
    local containers = { Player:FindFirstChildOfClass("Backpack"), char }
    local seen = {}
    for _, container in ipairs(containers) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and not seen[tool] then
                    seen[tool] = true
                    clearCooldownAttributes(tool)
                    for _, d in ipairs(tool:GetDescendants()) do
                        if (d:IsA("NumberValue") or d:IsA("IntValue"))
                            and d.Value ~= 0 and isCooldownName(d.Name) then
                            d.Value = 0
                        end
                    end
                    if not tool.Enabled then tool.Enabled = true end
                end
            end
        end
    end
end

-- Cria / atualiza o Micro-HUD (vida + nome + distância)
local function CreateMicroDisplay(char, playerName)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not root then return nil end

    local billboard = root:FindFirstChild("Aguia_MicroHUD")
    if not billboard then
        billboard = Instance.new("BillboardGui", root)
        billboard.Name = "Aguia_MicroHUD"
        billboard.AlwaysOnTop = true
        billboard.ExtentsOffset = Vector3.new(0, -3.9, 0)
        billboard.LightInfluence = 0

        local bgBar = Instance.new("Frame", billboard)
        bgBar.Name = "BackgroundBar"
        bgBar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
        bgBar.BorderSizePixel = 0
        Instance.new("UICorner", bgBar).CornerRadius = UDim.new(1, 0)
        local barStroke = Instance.new("UIStroke", bgBar)
        barStroke.Name = "BarStroke"
        barStroke.Thickness = 1
        barStroke.Color = Color3.fromRGB(0, 0, 0)
        barStroke.Transparency = 0.25

        local mainBar = Instance.new("Frame", bgBar)
        mainBar.Name = "MainBar"
        mainBar.Size = UDim2.new(1, 0, 1, 0)
        mainBar.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
        mainBar.BorderSizePixel = 0
        Instance.new("UICorner", mainBar).CornerRadius = UDim.new(1, 0)

        local gloss = Instance.new("Frame", mainBar)
        gloss.Name = "Gloss"
        gloss.Size = UDim2.new(1, 0, 0.5, 0)
        gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        gloss.BackgroundTransparency = 0.75
        gloss.BorderSizePixel = 0
        Instance.new("UICorner", gloss).CornerRadius = UDim.new(1, 0)

        local label = Instance.new("TextLabel", billboard)
        label.Name = "DistLabel"
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.4
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
    end

    local cfg = getgenv().SystemConfig
    local width = math.max(cfg.MicroWidth, 60)
    local textSize = cfg.MicroTextSize
    local barHeight = 5

    billboard.Size = UDim2.new(0, width, 0, textSize + barHeight + 8)

    local bar = billboard.BackgroundBar
    bar.Size = UDim2.new(0, width, 0, barHeight)
    bar.Position = UDim2.new(0, 0, 0, textSize + 2)
    bar.Visible = cfg.MicroHpEnabled

    local label = billboard.DistLabel
    label.Size = UDim2.new(1, 0, 0, textSize + 4)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.TextSize = textSize

    return billboard
end

-- Obtém o DepthMode seguro para Highlight
local function getDepthMode()
    local mode = getgenv().SystemConfig.HlDepthMode
    if mode == "AlwaysOnTop" then
        return Enum.HighlightDepthMode.AlwaysOnTop
    elseif mode == "Occluded" then
        return Enum.HighlightDepthMode.Occluded
    else
        return Enum.HighlightDepthMode.AlwaysOnTop
    end
end

--// =============================================
--// WARCORE UI - BIBLIOTECA DE INTERFACE PRÓPRIA
--// Sem Rayfield / Kavo / Orion. Mobile-first.
--// =============================================

local Theme = {
    -- WARCORE // TACTICAL EMBER
    Bg = Color3.fromRGB(9, 11, 8),
    Bg2 = Color3.fromRGB(14, 17, 12),
    Card = Color3.fromRGB(19, 23, 16),
    CardHover = Color3.fromRGB(29, 35, 22),
    Accent = Color3.fromRGB(183, 255, 61),
    Accent2 = Color3.fromRGB(255, 106, 26),
    Accent3 = Color3.fromRGB(92, 255, 214),
    Text = Color3.fromRGB(235, 243, 224),
    SubText = Color3.fromRGB(132, 146, 114),
    Stroke = Color3.fromRGB(38, 46, 31),
    Grid = Color3.fromRGB(120, 150, 90),
    Good = Color3.fromRGB(124, 255, 90),
    Warn = Color3.fromRGB(255, 196, 64),
    Bad = Color3.fromRGB(255, 77, 61),
    Title = Enum.Font.GothamBlack,
    Body = Enum.Font.GothamMedium,
    Strong = Enum.Font.GothamBold,
    Mono = Enum.Font.Code,
}

local UIParent
do
    local ok, parent = pcall(function() return CoreGui end)
    if ok and parent then
        UIParent = parent
    else
        UIParent = Player:WaitForChild("PlayerGui")
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WarcoreUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
do
    local ok = pcall(function() screenGui.Parent = UIParent end)
    if not ok then screenGui.Parent = Player:WaitForChild("PlayerGui") end
end
local ScreenGui = screenGui

local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

-- Cantos de HUD (brackets) - assinatura visual WARCORE
local function AddBrackets(parent, color, size, thickness, inset, transparency, zIndex)
    color = color or Theme.Accent
    size = size or 14
    thickness = thickness or 2
    inset = inset or 0
    transparency = transparency or 0
    zIndex = zIndex or 15
    local function arm(pos, dim)
        return New("Frame", {
            Size = dim,
            Position = pos,
            BackgroundColor3 = color,
            BackgroundTransparency = transparency,
            BorderSizePixel = 0,
            ZIndex = zIndex,
        }, parent)
    end
    local s = size
    local t = thickness
    -- topo-esquerda
    arm(UDim2.new(0, inset, 0, inset), UDim2.new(0, s, 0, t))
    arm(UDim2.new(0, inset, 0, inset), UDim2.new(0, t, 0, s))
    -- topo-direita
    arm(UDim2.new(1, -inset - s, 0, inset), UDim2.new(0, s, 0, t))
    arm(UDim2.new(1, -inset - t, 0, inset), UDim2.new(0, t, 0, s))
    -- base-esquerda
    arm(UDim2.new(0, inset, 1, -inset - t), UDim2.new(0, s, 0, t))
    arm(UDim2.new(0, inset, 1, -inset - s), UDim2.new(0, t, 0, s))
    -- base-direita
    arm(UDim2.new(1, -inset - s, 1, -inset - t), UDim2.new(0, s, 0, t))
    arm(UDim2.new(1, -inset - t, 1, -inset - s), UDim2.new(0, t, 0, s))
end

-- Linhas de varredura (efeito CRT/HUD)
local function AddScanlines(parent, spacing, color, transparency, zIndex)
    spacing = spacing or 5
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = zIndex or 12,
    }, parent)
    for y = 0, 720, spacing do
        New("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, y),
            BackgroundColor3 = color or Theme.Text,
            BackgroundTransparency = transparency or 0.95,
            BorderSizePixel = 0,
            ZIndex = zIndex or 12,
        }, holder)
    end
    return holder
end

-- Grade tática de fundo
local function AddGrid(parent, step, color, transparency, zIndex)
    step = step or 44
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = zIndex or 9,
    }, parent)
    for x = step, 920, step do
        New("Frame", {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(0, x, 0, 0),
            BackgroundColor3 = color or Theme.Grid,
            BackgroundTransparency = transparency or 0.95,
            BorderSizePixel = 0,
            ZIndex = zIndex or 9,
        }, holder)
    end
    for y = step, 920, step do
        New("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, y),
            BackgroundColor3 = color or Theme.Grid,
            BackgroundTransparency = transparency or 0.95,
            BorderSizePixel = 0,
            ZIndex = zIndex or 9,
        }, holder)
    end
    return holder
end

-- Marca lateral dos controles
local function AddRowMark(row, color, transparency)
    local mark = New("Frame", {
        Size = UDim2.new(0, 3, 1, -20),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundColor3 = color or Theme.Stroke,
        BackgroundTransparency = transparency or 0,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, row)
    New("UICorner", mark).CornerRadius = UDim.new(1, 0)
    return mark
end

local function fmtNum(v)
    if v % 1 == 0 then
        return tostring(math.floor(v))
    end
    return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
end

-- Notificações
local NotifyContainer = New("Frame", {
    Name = "Notifications",
    Size = UDim2.new(0, 270, 0, 0),
    Position = UDim2.new(1, -282, 0, 58),
    BackgroundTransparency = 1,
    ZIndex = 50,
}, ScreenGui)
New("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, NotifyContainer)

local function Notify(_, cfg)
    cfg = cfg or {}
    local card = New("Frame", {
        Name = "Notify",
        Size = UDim2.new(0, 270, 0, 62),
        BackgroundColor3 = Theme.Bg2,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 30, 0, 0),
        LayoutOrder = os.time(),
    }, NotifyContainer)
    Corner(card, 5)
    local stroke = Stroke(card, Theme.Accent, 1.5, 1)

    local bar = New("Frame", {
        Size = UDim2.new(0, 3, 1, -24),
        Position = UDim2.new(0, 10, 0, 12),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
    }, card)
    Corner(bar, 2)

    local title = New("TextLabel", {
        Size = UDim2.new(1, -28, 0, 22),
        Position = UDim2.new(0, 21, 0, 8),
        BackgroundTransparency = 1,
        Text = "// " .. (cfg.Title or "WARCORE"),
        TextColor3 = Theme.Text,
        Font = Theme.Mono,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
    }, card)

    local content = New("TextLabel", {
        Size = UDim2.new(1, -28, 0, 24),
        Position = UDim2.new(0, 21, 0, 30),
        BackgroundTransparency = 1,
        Text = cfg.Content or "",
        TextColor3 = Theme.SubText,
        Font = Theme.Mono,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTransparency = 1,
    }, card)

    local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(card, info, {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(stroke, info, {Transparency = 0.25}):Play()
    TweenService:Create(bar, info, {BackgroundTransparency = 0}):Play()
    TweenService:Create(title, info, {TextTransparency = 0}):Play()
    TweenService:Create(content, info, {TextTransparency = 0}):Play()

    task.delay(cfg.Duration or 3, function()
        if not card.Parent then return end
        local out = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(card, out, {BackgroundTransparency = 1, Position = UDim2.new(1, 30, 0, 0)}):Play()
        TweenService:Create(stroke, out, {Transparency = 1}):Play()
        TweenService:Create(bar, out, {BackgroundTransparency = 1}):Play()
        TweenService:Create(title, out, {TextTransparency = 1}):Play()
        TweenService:Create(content, out, {TextTransparency = 1}):Play()
        task.delay(0.3, function() card:Destroy() end)
    end)
end

-- Controle central de sliders (evita conexões por slider)
local ActiveSlider = nil
UserInputService.InputChanged:Connect(function(input)
    if ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        ActiveSlider.update(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        if ActiveSlider.scroll then ActiveSlider.scroll.ScrollingEnabled = true end
        ActiveSlider = nil
    end
end)

-- Slider (usado nas abas e no seletor de cor)
local function CreateSliderControl(parent, opts, order)
    local row = New("Frame", {
        Name = "Slider_" .. (opts.Name or ""),
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
    }, parent)
    Corner(row, 10)
    Stroke(row, Theme.Stroke, 1, 0.35)

    New("TextLabel", {
        Size = UDim2.new(1, -90, 0, 22),
        Position = UDim2.new(0, 14, 0, 8),
        BackgroundTransparency = 1,
        Text = opts.Name or "",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local valueLbl = New("TextLabel", {
        Size = UDim2.new(0, 76, 0, 22),
        Position = UDim2.new(1, -88, 0, 8),
        BackgroundTransparency = 1,
        Text = fmtNum(opts.CurrentValue or opts.Range[1]),
        TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local track = New("Frame", {
        Size = UDim2.new(1, -28, 0, 8),
        Position = UDim2.new(0, 14, 0, 42),
        BackgroundColor3 = Color3.fromRGB(38, 43, 60),
        BorderSizePixel = 0,
        Active = true,
    }, row)
    Corner(track, 4)

    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, track)
    Corner(fill, 4)

    local knob = New("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(240, 245, 255),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, track)
    Corner(knob, 10)
    Stroke(knob, Theme.Accent, 2, 0)

    local minV, maxV = opts.Range[1], opts.Range[2]
    local inc = opts.Increment or 1
    local value = opts.CurrentValue or minV

    local function setValue(v, trigger)
        v = math.clamp(v, minV, maxV)
        value = v
        local rel = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valueLbl.Text = fmtNum(v)
        if trigger and opts.Callback then opts.Callback(v) end
    end

    local function updateFromX(x)
        local rel = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
        rel = math.clamp(rel, 0, 1)
        local raw = minV + (maxV - minV) * rel
        raw = math.floor(raw / inc + 0.5) * inc
        setValue(raw, true)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local scroll = parent:IsA("ScrollingFrame") and parent or nil
            if scroll then scroll.ScrollingEnabled = false end
            ActiveSlider = { update = updateFromX, scroll = scroll }
            updateFromX(input.Position.X)
        end
    end)

    setValue(value, false)
    return {
        Set = function(_, v) setValue(v, false) end,
        Now = function(v) setValue(v, false) end,
    }
end

-- Toggle
local ToggleControls = {}
local function CreateToggleControl(parent, opts, order)
    local row = New("Frame", {
        Name = "Toggle_" .. (opts.Name or ""),
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
    }, parent)
    Corner(row, 10)
    Stroke(row, Theme.Stroke, 1, 0.35)

    New("TextLabel", {
        Size = UDim2.new(1, -92, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = opts.Name or "",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, row)

    local track = New("Frame", {
        Size = UDim2.new(0, 48, 0, 26),
        Position = UDim2.new(1, -62, 0.5, -13),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, row)
    Corner(track, 13)

    local knob = New("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(240, 245, 255),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, track)
    Corner(knob, 10)

    local state = opts.CurrentValue and true or false
    local function render(animate)
        local info = TweenInfo.new(animate and 0.16 or 0)
        TweenService:Create(track, info, {BackgroundColor3 = state and Theme.Accent or Theme.Stroke}):Play()
        TweenService:Create(knob, info, {Position = state and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}):Play()
    end

    local click = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
    }, row)
    click.MouseButton1Click:Connect(function()
        state = not state
        render(true)
        if opts.Callback then opts.Callback(state) end
    end)

    render(false)
    local control = { Set = function(_, v) state = v and true or false; render(true) end }
    table.insert(ToggleControls, control)
    return control
end

--// ----- KEYBINDS -----
-- Estado central: captura de tecla + ações registradas + teclas ativas
local KeybindState = {
    capturing = nil,   -- controle que está aguardando uma tecla
    handlers = {},     -- [controle] = function(keyName)
    actions = {},      -- [actionName] = function()
    keys = {},         -- [actionName] = "NomeDaTecla" | "Nenhuma"
}
local UIRefs = {}      -- referências de controles para sincronizar com keybinds
KeybindState.NONE = "Nenhuma"

local function CreateKeybindControl(parent, opts, order)
    local row = New("Frame", {
        Name = "Keybind_" .. (opts.Name or ""),
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
    }, parent)
    Corner(row, 10)
    Stroke(row, Theme.Stroke, 1, 0.35)

    New("TextLabel", {
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = opts.Name or "",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, row)

    local value = opts.Key or KeybindState.NONE
    local keyBtn = New("TextButton", {
        Size = UDim2.new(0, 116, 0, 32),
        Position = UDim2.new(1, -128, 0.5, -16),
        BackgroundColor3 = Theme.Bg2,
        Text = value,
        TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        ZIndex = 2,
    }, row)
    Corner(keyBtn, 8)
    local keyStroke = Stroke(keyBtn, Theme.Accent, 1, 0.4)

    local function render()
        keyBtn.Text = value
        local active = (value ~= KeybindState.NONE)
        keyBtn.TextColor3 = active and Theme.Accent or Theme.SubText
        keyStroke.Color = active and Theme.Accent or Theme.Stroke
    end

    local control = {}
    keyBtn.MouseButton1Click:Connect(function()
        if KeybindState.capturing == control then
            KeybindState.capturing = nil
            render()
            return
        end
        KeybindState.capturing = control
        keyBtn.Text = "Pressione..."
        keyBtn.TextColor3 = Color3.fromRGB(255, 205, 0)
    end)

    KeybindState.handlers[control] = function(keyName)
        if keyName == "__cancel" then
            render()
            return
        end
        value = (keyName == value) and KeybindState.NONE or keyName
        render()
        if opts.Callback then opts.Callback(value) end
    end

    render()
    control.Set = function(_, k) value = k or KeybindState.NONE; render() end
    return control
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = input.KeyCode and input.KeyCode.Name
    if not keyName then return end

    -- Captura de tecla (prioridade máxima)
    if KeybindState.capturing then
        local handler = KeybindState.handlers[KeybindState.capturing]
        KeybindState.capturing = nil
        if handler then
            handler(keyName == "Escape" and "__cancel" or keyName)
        end
        return
    end

    if gameProcessed then return end
    for actionName, fn in pairs(KeybindState.actions) do
        local bound = KeybindState.keys[actionName]
        if bound and bound ~= KeybindState.NONE and bound == keyName then
            fn()
        end
    end
end)

-- Registra uma ação vinculável (chamado após as funções existirem)
local function RegisterKeybind(actionName, defaultKey, onTrigger)
    KeybindState.actions[actionName] = onTrigger
    local saved = getgenv().SystemConfig.Keybinds and getgenv().SystemConfig.Keybinds[actionName]
    KeybindState.keys[actionName] = saved or defaultKey or KeybindState.NONE
end

-- Modal reutilizável (dropdown / color picker)
local function ShowModal(title, builder)
    local vp = Camera.ViewportSize
    local overlay = New("TextButton", {
        Name = "ModalOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 200,
    }, ScreenGui)

    local cardW = math.clamp(math.floor(vp.X * 0.86), 260, 340)
    local cardH = math.clamp(math.floor(vp.Y * 0.68), 240, 440)
    local card = New("Frame", {
        Name = "Card",
        Size = UDim2.new(0, cardW, 0, cardH),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Bg2,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 201,
    }, overlay)
    Corner(card, 14)
    Stroke(card, Theme.Stroke, 1.5, 0.15)

    New("TextLabel", {
        Size = UDim2.new(1, -60, 0, 40),
        Position = UDim2.new(0, 16, 0, 6),
        BackgroundTransparency = 1,
        Text = title or "",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local closeBtn = New("TextButton", {
        Size = UDim2.new(0, 34, 0, 34),
        Position = UDim2.new(1, -42, 0, 8),
        BackgroundColor3 = Theme.Bad,
        BackgroundTransparency = 0.15,
        Text = "✕",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoButtonColor = false,
        ZIndex = 202,
    }, card)
    Corner(closeBtn, 9)

    local content = New("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, -24, 1, -60),
        Position = UDim2.new(0, 12, 0, 50),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, card)
    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    local function updateCanvas()
        content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
    updateCanvas()

    local function close() overlay:Destroy() end
    closeBtn.MouseButton1Click:Connect(close)
    overlay.MouseButton1Click:Connect(close)

    builder(content, close)
    return overlay
end

-- Janela principal
local FullShutdown
local Window = {}
Window.__index = Window

local function MakeDraggable(handle, target, onTap)
    local dragging, startInput, startPos, moved = false, nil, nil, false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            startInput = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging and not moved and onTap then onTap() end
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then moved = true end
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function CreateWindow(cfg)
    cfg = cfg or {}
    local vp = Camera.ViewportSize
    local winW = math.clamp(math.floor(vp.X * 0.94), 300, 520)
    local winH = math.clamp(math.floor(vp.Y * 0.82), 360, 660)
    local baseSize = UDim2.new(0, winW, 0, winH)

    local main = New("Frame", {
        Name = "WarcoreWindow",
        Size = baseSize,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
    }, ScreenGui)
    Corner(main, 16)
    Stroke(main, Theme.Stroke, 1.5, 0.2)

    -- Cabeçalho
    local header = New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Theme.Bg2,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, main)
    Corner(header, 16)
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 1, -16),
        BackgroundColor3 = Theme.Bg2,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, header)
    -- Linha de acento (gradiente) embaixo do cabeçalho
    local accentLine = New("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 13,
    }, header)
    New("UIGradient", {
        Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
    }, accentLine)

    local titleLbl = New("TextLabel", {
        Size = UDim2.new(1, -120, 0, 26),
        Position = UDim2.new(0, 16, 0, 8),
        BackgroundTransparency = 1,
        Text = cfg.Name or "WARCORE",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    }, header)

    New("TextLabel", {
        Size = UDim2.new(1, -120, 0, 16),
        Position = UDim2.new(0, 16, 0, 32),
        BackgroundTransparency = 1,
        Text = cfg.Subtitle or "WARCORE LABS • CUSTOM UI",
        TextColor3 = Theme.SubText,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    }, header)

    local minBtn = New("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -76, 0, 12),
        BackgroundColor3 = Theme.Card,
        Text = "─",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = false,
        ZIndex = 12,
    }, header)
    Corner(minBtn, 9)

    local closeBtn = New("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -40, 0, 12),
        BackgroundColor3 = Theme.Bad,
        BackgroundTransparency = 0.15,
        Text = "✕",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoButtonColor = false,
        ZIndex = 12,
    }, header)
    Corner(closeBtn, 9)

    local sidebarW = 62
    local sidebar = New("ScrollingFrame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarW, 1, -56),
        Position = UDim2.new(0, 0, 0, 56),
        BackgroundColor3 = Theme.Bg2,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 10,
    }, main)
    local sidebarLayout = New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, sidebar)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 16),
    }, sidebar)
    local function updateSidebarCanvas()
        sidebar.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 28)
    end
    sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSidebarCanvas)
    updateSidebarCanvas()

    -- Área de conteúdo
    local contentHolder = New("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -sidebarW, 1, -56),
        Position = UDim2.new(0, sidebarW, 0, 56),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 11,
    }, main)
    New("Frame", {
        Name = "SidebarEdge",
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, contentHolder)

    local function cleanCategoryLabel(name)
        return (name:gsub("^[^%w]+%s*", ""))
    end
    local function getCategoryMeta(name)
        local label = cleanCategoryLabel(name)
        local key = label:lower()
        if key:find("combate") then return "combat", "COMBATE", label end
        if key:find("visual") then return "visual", "VISUAL", label end
        if key:find("rx") then return "rx", "RX", label end
        if key:find("ilum") then return "light", "LUZ", label end
        if key:find("mov") then return "move", "MOVE", label end
        if key:find("teleport") then return "teleport", "TP", label end
        if key:find("monitor") then return "monitor", "MON", label end
        if key:find("key") then return "keybind", "KEYS", label end
        return "generic", label:upper():sub(1, 6), label
    end
    local function buildCategoryIcon(parent, kind)
        local parts = {}
        local function track(obj, prop)
            table.insert(parts, { obj = obj, prop = prop })
            return obj
        end
        local function fill(x, y, w, h, radius)
            local f = New("Frame", {
                Size = UDim2.new(0, w, 0, h),
                Position = UDim2.new(0, x, 0, y),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 14,
            }, parent)
            if radius then Corner(f, radius) end
            return track(f, "BackgroundColor3")
        end
        local function outline(x, y, w, h, radius, thickness)
            local f = New("Frame", {
                Size = UDim2.new(0, w, 0, h),
                Position = UDim2.new(0, x, 0, y),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 14,
            }, parent)
            if radius then Corner(f, radius) end
            return track(Stroke(f, Color3.fromRGB(255, 255, 255), thickness or 1.7, 0), "Color")
        end

        if kind == "combat" then
            outline(15, 6, 20, 20, 999, 1.7)
            fill(23, 14, 4, 4, 2)
            fill(24, 3, 2, 6, 1)
            fill(24, 23, 2, 6, 1)
            fill(10, 15, 6, 2, 1)
            fill(34, 15, 6, 2, 1)
        elseif kind == "visual" then
            outline(14, 10, 22, 13, 999, 1.7)
            fill(23, 14, 5, 5, 3)
        elseif kind == "rx" then
            fill(17, 12, 3, 11, 1)
            fill(23, 7, 3, 16, 1)
            fill(29, 3, 3, 20, 1)
        elseif kind == "light" then
            outline(18, 4, 14, 14, 999, 1.7)
            fill(21, 19, 8, 3, 1)
            fill(23, 23, 4, 2, 1)
        elseif kind == "move" then
            outline(15, 6, 20, 20, 5, 1.7)
            fill(23, 13, 4, 6, 2)
        elseif kind == "teleport" then
            local diamond = New("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, 17, 0, 6),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Rotation = 45,
                ZIndex = 14,
            }, parent)
            Corner(diamond, 2)
            track(Stroke(diamond, Color3.fromRGB(255, 255, 255), 1.7, 0), "Color")
            fill(23, 12, 5, 5, 3)
        elseif kind == "monitor" then
            outline(13, 6, 24, 15, 3, 1.7)
            fill(19, 23, 12, 2, 1)
            fill(18, 14, 2, 5, 0)
            fill(23, 11, 2, 8, 0)
            fill(28, 8, 2, 11, 0)
        elseif kind == "keybind" then
            outline(13, 12, 11, 11, 999, 1.7)
            fill(23, 16, 15, 3, 1)
            fill(30, 19, 3, 5, 1)
            fill(34, 19, 3, 5, 1)
        else
            outline(17, 8, 16, 16, 999, 1.7)
            fill(23, 14, 4, 4, 2)
        end

        return function(color)
            for _, p in ipairs(parts) do p.obj[p.prop] = color end
        end
    end

    local tabs = {}
    local function selectTab(index)
        for i, t in ipairs(tabs) do
            local active = (i == index)
            t.page.Visible = active
            t.paintIcon(active and Theme.Accent or Theme.SubText)
            t.caption.TextColor3 = active and Theme.Accent or Theme.SubText
            t.indicator.Visible = active
            TweenService:Create(t.button, TweenInfo.new(0.15), {
                BackgroundColor3 = active and Theme.CardHover or Theme.Card,
                BackgroundTransparency = active and 0.05 or 0.35,
            }):Play()
            TweenService:Create(t.buttonStroke, TweenInfo.new(0.15), {
                Color = active and Theme.Accent or Theme.Stroke,
                Transparency = active and 0 or 0.45,
            }):Play()
        end
    end

    local function newTab(name)
        local tab = {}
        local orderState = { n = 0 }
        local function nextOrder()
            orderState.n = orderState.n + 1
            return orderState.n
        end

        local page = New("ScrollingFrame", {
            Name = "Page_" .. name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            ZIndex = 11,
        }, contentHolder)
        local layout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 24),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        }, page)
        local function updateCanvas()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 40)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        updateCanvas()

        local iconKind, captionText, label = getCategoryMeta(name)

        local button = New("TextButton", {
            Name = "Tab_" .. label,
            Size = UDim2.new(0, 50, 0, 54),
            BackgroundColor3 = Theme.Card,
            BackgroundTransparency = 0.35,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 12,
        }, sidebar)
        Corner(button, 12)
        local buttonStroke = Stroke(button, Theme.Stroke, 1, 0.45)

        local indicator = New("Frame", {
            Name = "Indicator",
            Size = UDim2.new(0, 3, 0, 20),
            Position = UDim2.new(0, -1, 0.5, -10),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 15,
        }, button)
        Corner(indicator, 2)

        local paintIcon = buildCategoryIcon(button, iconKind)

        local caption = New("TextLabel", {
            Name = "Caption",
            Size = UDim2.new(1, 0, 0, 12),
            Position = UDim2.new(0, 0, 1, -15),
            BackgroundTransparency = 1,
            Text = captionText,
            TextColor3 = Theme.SubText,
            Font = Enum.Font.GothamBold,
            TextSize = 8,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 15,
        }, button)

        table.insert(tabs, {
            page = page,
            button = button,
            buttonStroke = buttonStroke,
            indicator = indicator,
            paintIcon = paintIcon,
            caption = caption,
        })

        button.MouseButton1Click:Connect(function()
            for i, t in ipairs(tabs) do
                if t.page == page then selectTab(i); break end
            end
        end)

        function tab:CreateSection(text)
            return New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.SubText,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = nextOrder(),
            }, page)
        end

        function tab:CreateToggle(o)
            return CreateToggleControl(page, o, nextOrder())
        end

        function tab:CreateKeybind(o)
            return CreateKeybindControl(page, o, nextOrder())
        end

        function tab:CreateSlider(o)
            return CreateSliderControl(page, o, nextOrder())
        end

        function tab:CreateButton(o)
            local row = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 48),
                BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0,
                Text = o.Name or "Botão",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                AutoButtonColor = false,
                LayoutOrder = nextOrder(),
            }, page)
            Corner(row, 10)
            local st = Stroke(row, Theme.Accent, 1, 0.4)
            row.MouseEnter:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Theme.CardHover}):Play()
            end)
            row.MouseLeave:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Card}):Play()
            end)
            row.MouseButton1Click:Connect(function()
                if o.Callback then o.Callback() end
            end)
            return row
        end

        function tab:CreateDropdown(o)
            local row = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = nextOrder(),
            }, page)
            Corner(row, 10)
            Stroke(row, Theme.Stroke, 1, 0.35)

            New("TextLabel", {
                Size = UDim2.new(1, -110, 0, 20),
                Position = UDim2.new(0, 14, 0, 8),
                BackgroundTransparency = 1,
                Text = o.Name or "",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local valLbl = New("TextLabel", {
                Size = UDim2.new(1, -110, 0, 18),
                Position = UDim2.new(0, 14, 0, 28),
                BackgroundTransparency = 1,
                Text = o.CurrentOption or "",
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            New("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -30, 0, 0),
                BackgroundTransparency = 1,
                Text = "▾",
                TextColor3 = Theme.SubText,
                Font = Enum.Font.GothamBold,
                TextSize = 16,
            }, row)

            local current = o.CurrentOption

            row.MouseButton1Click:Connect(function()
                ShowModal(o.Name, function(content, close)
                    for i, opt in ipairs(o.Options) do
                        local ob = New("TextButton", {
                            Size = UDim2.new(1, 0, 0, 46),
                            BackgroundColor3 = (opt == current) and Theme.Accent or Theme.Card,
                            Text = opt,
                            TextColor3 = Theme.Text,
                            Font = Enum.Font.GothamMedium,
                            TextSize = 14,
                            AutoButtonColor = false,
                            LayoutOrder = i,
                        }, content)
                        Corner(ob, 9)
                        ob.MouseButton1Click:Connect(function()
                            current = opt
                            valLbl.Text = opt
                            if o.Callback then o.Callback(opt) end
                            close()
                        end)
                    end
                end)
            end)

            return {
                Set = function(_, opt)
                    current = opt
                    valLbl.Text = opt
                end,
            }
        end

        function tab:CreateColorPicker(o)
            local row = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = nextOrder(),
            }, page)
            Corner(row, 10)
            Stroke(row, Theme.Stroke, 1, 0.35)

            New("TextLabel", {
                Size = UDim2.new(1, -80, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = o.Name or "",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            local swatch = New("Frame", {
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -44, 0.5, -15),
                BackgroundColor3 = o.Color or Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            }, row)
            Corner(swatch, 8)
            Stroke(swatch, Theme.Stroke, 1, 0)

            local color = o.Color or Color3.fromRGB(255, 255, 255)
            local function applyColor(c, trigger)
                color = c
                swatch.BackgroundColor3 = c
                if trigger and o.Callback then o.Callback(c) end
            end
            applyColor(color, false)

            row.MouseButton1Click:Connect(function()
                ShowModal(o.Name, function(content, close)
                    local preview = New("Frame", {
                        Size = UDim2.new(1, 0, 0, 44),
                        BackgroundColor3 = color,
                        BorderSizePixel = 0,
                        LayoutOrder = 0,
                    }, content)
                    Corner(preview, 10)
                    Stroke(preview, Theme.Stroke, 1, 0)

                    local r = math.floor(color.R * 255 + 0.5)
                    local g = math.floor(color.G * 255 + 0.5)
                    local b = math.floor(color.B * 255 + 0.5)

                    local function refresh()
                        local c = Color3.fromRGB(r, g, b)
                        preview.BackgroundColor3 = c
                        applyColor(c, true)
                    end

                    CreateSliderControl(content, { Name = "R (vermelho)", Range = {0, 255}, Increment = 1, CurrentValue = r, Callback = function(v) r = v; refresh() end }, 1)
                    CreateSliderControl(content, { Name = "G (verde)", Range = {0, 255}, Increment = 1, CurrentValue = g, Callback = function(v) g = v; refresh() end }, 2)
                    CreateSliderControl(content, { Name = "B (azul)", Range = {0, 255}, Increment = 1, CurrentValue = b, Callback = function(v) b = v; refresh() end }, 3)
                    refresh()
                end)
            end)

            return { Set = function(_, c) applyColor(c, false) end }
        end

        return tab
    end

    Window.newTab = newTab
    Window.selectTab = selectTab
    Window.main = main
    Window.header = header

    -- Abrir/fechar
    local isOpen = true
    local function openWin()
        if isOpen then return end
        isOpen = true
        main.Visible = true
        main.Size = UDim2.new(0, winW * 0.9, 0, winH * 0.9)
        main.BackgroundTransparency = 1
        TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = baseSize,
            BackgroundTransparency = 0,
        }):Play()
    end
    local function closeWin()
        if not isOpen then return end
        isOpen = false
        local t = TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, winW * 0.9, 0, winH * 0.9),
            BackgroundTransparency = 1,
        })
        t:Play()
        t.Completed:Connect(function()
            if not isOpen then main.Visible = false end
        end)
    end

    Window.open = openWin
    Window.close = closeWin
    Window.toggle = function()
        if isOpen then closeWin() else openWin() end
    end
    Window.isOpen = function() return isOpen end

    minBtn.MouseButton1Click:Connect(closeWin)
    closeBtn.MouseButton1Click:Connect(function()
        if FullShutdown then
            FullShutdown()
        else
            closeWin()
        end
    end)
    MakeDraggable(header, main)

    return Window
end

local WarcoreUI = {
    CreateWindow = CreateWindow,
    Notify = Notify,
    Theme = Theme,
    ScreenGui = ScreenGui,
}

--// =============================================
--// BOTÃO ABRIR MENU + TAGS + BOTÃO FLUTUANTE DA MIRA
--// =============================================

-- Tags (FPS / Players)
local TagContainer = New("Frame", {
    Size = UDim2.new(0, 90, 0, 50),
    Position = UDim2.new(0, 6, 0, 46),
    BackgroundTransparency = 1,
    ZIndex = 20,
}, ScreenGui)
New("UIListLayout", { Padding = UDim.new(0, 3) }, TagContainer)

local function CreateTag(color)
    local f = New("Frame", {
        Size = UDim2.new(0, 84, 0, 20),
        BackgroundColor3 = Color3.fromRGB(15, 18, 28),
        BackgroundTransparency = 0.15,
        Visible = false,
        ZIndex = 20,
    }, TagContainer)
    Corner(f, 6)
    Stroke(f, color, 1, 0.4)
    local l = New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
    }, f)
    return f, l
end

local fpsF, fpsL = CreateTag(Color3.fromRGB(0, 240, 255))
local countF, countL = CreateTag(Color3.fromRGB(255, 0, 120))

-- Botão flutuante da mira
local FloatingBtn = New("TextButton", {
    Visible = false,
    Size = UDim2.new(0, 74, 0, 40),
    Position = UDim2.new(0.06, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(11, 14, 24),
    Text = "⚡ OFF",
    TextColor3 = Color3.fromRGB(130, 140, 160),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    Active = true,
    AutoButtonColor = false,
    ZIndex = 20,
}, ScreenGui)
Corner(FloatingBtn, 10)
local StrokeMira = Stroke(FloatingBtn, Color3.fromRGB(35, 42, 65), 2, 0)

local function UpdateBtnVisual(active)
    if active then
        TweenService:Create(FloatingBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(16, 28, 48)}):Play()
        TweenService:Create(StrokeMira, TweenInfo.new(0.25), {Color = Color3.fromRGB(0, 240, 255)}):Play()
        FloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        FloatingBtn.Text = "⚡ ON"
    else
        TweenService:Create(FloatingBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(11, 14, 24)}):Play()
        TweenService:Create(StrokeMira, TweenInfo.new(0.25), {Color = Color3.fromRGB(35, 42, 65)}):Play()
        FloatingBtn.TextColor3 = Color3.fromRGB(130, 140, 160)
        FloatingBtn.Text = "⚡ OFF"
    end
end

MakeDraggable(FloatingBtn, FloatingBtn)
FloatingBtn.MouseButton1Click:Connect(function()
    getgenv().SystemConfig.MiraAtiva = not getgenv().SystemConfig.MiraAtiva
    UpdateBtnVisual(getgenv().SystemConfig.MiraAtiva)
end)

-- Janela principal instanciada
local Win = WarcoreUI.CreateWindow({
    Name = "👑 WARCORE v2.0.0",
    Subtitle = "WARCORE LABS • INTERFACE PRÓPRIA",
})

-- Botão flutuante para abrir/minimizar o menu
local OpenBtn = New("TextButton", {
    Size = UDim2.new(0, 54, 0, 54),
    Position = UDim2.new(1, -70, 0.5, -27),
    BackgroundColor3 = Theme.Bg,
    Text = "☰",
    TextColor3 = Theme.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 26,
    AutoButtonColor = false,
    ZIndex = 30,
}, ScreenGui)
Corner(OpenBtn, 27)
Stroke(OpenBtn, Theme.Accent, 1.5, 0.5)
MakeDraggable(OpenBtn, OpenBtn, function() Win.toggle() end)

--// =============================================
--// SISTEMA DE TELEPORTE (mantido)
--// =============================================
local tpGui = New("ScreenGui", {
    Name = "WarcoreTeleporte",
    Enabled = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, UIParent)

local function hover(btn, baseColor, hoverColor, textHover)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor, BackgroundTransparency = 0.1}):Play()
        if textHover then TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = textHover}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = baseColor, BackgroundTransparency = 0.3}):Play()
        if textHover then TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(220,230,240)}):Play() end
    end)
end

local tpFrame = Instance.new("Frame", tpGui)
tpFrame.Size = UDim2.new(0, 360, 0, 540)
tpFrame.Position = UDim2.new(0.5, -180, 0.5, -270)
tpFrame.BackgroundColor3 = Color3.fromRGB(30, 33, 45)
tpFrame.BackgroundTransparency = 0.05
tpFrame.BorderSizePixel = 0
tpFrame.ClipsDescendants = true
tpFrame.Visible = false
tpFrame.ZIndex = 10

local frameCorner = Instance.new("UICorner", tpFrame)
frameCorner.CornerRadius = UDim.new(0, 18)
local shadow1 = Instance.new("UIStroke", tpFrame)
shadow1.Thickness = 6
shadow1.Color = Color3.fromRGB(0, 0, 0)
shadow1.Transparency = 0.7
shadow1.Name = "Shadow1"
local shadow2 = Instance.new("UIStroke", tpFrame)
shadow2.Thickness = 2
shadow2.Color = Color3.fromRGB(0, 0, 0)
shadow2.Transparency = 0.5
shadow2.Name = "Shadow2"
local border = Instance.new("UIStroke", tpFrame)
border.Thickness = 1
border.Color = Color3.fromRGB(60, 70, 90)
border.Transparency = 0.2

local titleBar = Instance.new("Frame", tpFrame)
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
titleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 18)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0, 20)
titleFix.Position = UDim2.new(0, 0, 0, 22)
titleFix.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
titleFix.BorderSizePixel = 0

local icon = Instance.new("ImageLabel", titleBar)
icon.Size = UDim2.new(0, 26, 0, 26)
icon.Position = UDim2.new(0, 10, 0, 8)
icon.BackgroundTransparency = 1
icon.Image = "rbxassetid://10734951477"
icon.ImageColor3 = Color3.fromRGB(0, 240, 255)
icon.ScaleType = Enum.ScaleType.Fit

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -110, 1, 0)
titleLabel.Position = UDim2.new(0, 42, 0, 0)
titleLabel.Text = "Teleporte Rápido"
titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.BackgroundTransparency = 1

local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
minimizeBtn.Position = UDim2.new(1, -68, 0, 5)
minimizeBtn.Text = "─"
minimizeBtn.TextColor3 = Color3.fromRGB(220, 230, 240)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
minimizeBtn.BackgroundTransparency = 0.3
minimizeBtn.AutoButtonColor = false
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 10)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -32, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
closeBtn.BackgroundTransparency = 0.2
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

hover(minimizeBtn, Color3.fromRGB(50,55,65), Color3.fromRGB(70,75,85), Color3.fromRGB(255,255,255))
hover(closeBtn, Color3.fromRGB(190,60,60), Color3.fromRGB(230,80,80), Color3.fromRGB(255,255,255))

local winDragging = false
local winStart, winFrameStart
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        winDragging = true
        winStart = input.Position
        winFrameStart = tpFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then winDragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if winDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - winStart
        tpFrame.Position = UDim2.new(winFrameStart.X.Scale, winFrameStart.X.Offset + delta.X, winFrameStart.Y.Scale, winFrameStart.Y.Offset + delta.Y)
    end
end)

local posPanel = Instance.new("Frame", tpFrame)
posPanel.Size = UDim2.new(1, -24, 0, 46)
posPanel.Position = UDim2.new(0, 12, 0, 52)
posPanel.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
posPanel.BorderSizePixel = 0
Instance.new("UICorner", posPanel).CornerRadius = UDim.new(0, 10)
local posStroke = Instance.new("UIStroke", posPanel)
posStroke.Thickness = 1
posStroke.Color = Color3.fromRGB(0, 240, 255)
posStroke.Transparency = 0.7

local posLabel = Instance.new("TextLabel", posPanel)
posLabel.Size = UDim2.new(1, -10, 1, 0)
posLabel.Position = UDim2.new(0, 5, 0, 0)
posLabel.BackgroundTransparency = 1
posLabel.Text = "📍 Posição: --, --, --"
posLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
posLabel.Font = Enum.Font.GothamMedium
posLabel.TextSize = 15

local inputName = Instance.new("TextBox", tpFrame)
inputName.Size = UDim2.new(1, -24, 0, 48)
inputName.Position = UDim2.new(0, 12, 0, 110)
inputName.PlaceholderText = "Nome do Local"
inputName.PlaceholderColor3 = Color3.fromRGB(180, 190, 210)
inputName.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
inputName.TextColor3 = Color3.fromRGB(255, 255, 255)
inputName.Font = Enum.Font.Gotham
inputName.TextSize = 16
inputName.ClearTextOnFocus = false
Instance.new("UICorner", inputName).CornerRadius = UDim.new(0, 10)
local inputStroke = Instance.new("UIStroke", inputName)
inputStroke.Thickness = 1
inputStroke.Color = Color3.fromRGB(80, 90, 110)
inputStroke.Transparency = 0.3

local saveBtn = Instance.new("TextButton", tpFrame)
saveBtn.Size = UDim2.new(1, -24, 0, 48)
saveBtn.Position = UDim2.new(0, 12, 0, 170)
saveBtn.Text = "💾 Salvar Local"
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 17
saveBtn.AutoButtonColor = false
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)
local saveStroke = Instance.new("UIStroke", saveBtn)
saveStroke.Thickness = 1
saveStroke.Color = Color3.fromRGB(255, 255, 255)
saveStroke.Transparency = 0.4
hover(saveBtn, Color3.fromRGB(0,140,255), Color3.fromRGB(0,170,255), Color3.fromRGB(255,255,255))

local container = Instance.new("ScrollingFrame", tpFrame)
container.Size = UDim2.new(1, -24, 0, 250)
container.Position = UDim2.new(0, 12, 0, 230)
container.BackgroundColor3 = Color3.fromRGB(40, 43, 55)
container.BorderSizePixel = 0
container.ScrollBarThickness = 5
container.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder

local clearBtn = Instance.new("TextButton", tpFrame)
clearBtn.Size = UDim2.new(1, -24, 0, 46)
clearBtn.Position = UDim2.new(0, 12, 0, 492)
clearBtn.Text = "🗑 Limpar Tudo (meus locais)"
clearBtn.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 15
clearBtn.AutoButtonColor = false
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 10)
local clearStroke = Instance.new("UIStroke", clearBtn)
clearStroke.Thickness = 1
clearStroke.Color = Color3.fromRGB(255, 255, 255)
clearStroke.Transparency = 0.4
hover(clearBtn, Color3.fromRGB(170,50,50), Color3.fromRGB(210,70,70), Color3.fromRGB(255,255,255))

local FixedLocations = {
    {name = "👑 Bandeira de Captura", x = -463.30, y = 261.15, z = -1013.22},
    {name = "👑 Local do Barril", x = 1706.69, y = 120.95, z = 3773.69}
}
local savedLocations = {}

local function refreshContainer()
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    for i, loc in ipairs(FixedLocations) do
        local btn = Instance.new("TextButton", container)
        btn.Name = "Fixed_" .. loc.name
        btn.Size = UDim2.new(1, -10, 0, 44)
        btn.Text = loc.name .. "\n" .. string.format("%.1f, %.1f, %.1f", loc.x, loc.y, loc.z)
        btn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        btn.TextColor3 = Color3.fromRGB(30, 30, 30)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.LayoutOrder = i
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        hover(btn, Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 220, 50))
        btn.MouseButton1Click:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(loc.x, loc.y, loc.z)
                WarcoreUI:Notify({Title = "✅ Teleportado", Content = "Você foi para: " .. loc.name, Duration = 2})
            end
        end)
    end

    for i, loc in ipairs(savedLocations) do
        local itemFrame = Instance.new("Frame", container)
        itemFrame.Name = "User_" .. loc.name
        itemFrame.Size = UDim2.new(1, -10, 0, 44)
        itemFrame.BackgroundTransparency = 1
        itemFrame.LayoutOrder = 100 + i

        local itemLayout = Instance.new("UIListLayout", itemFrame)
        itemLayout.FillDirection = Enum.FillDirection.Horizontal
        itemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        itemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        itemLayout.Padding = UDim.new(0, 4)

        local btn = Instance.new("TextButton", itemFrame)
        btn.Size = UDim2.new(1, -30, 1, 0)
        btn.Text = loc.name .. "\n" .. string.format("%.1f, %.1f, %.1f", loc.x, loc.y, loc.z)
        btn.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        hover(btn, Color3.fromRGB(50,55,70), Color3.fromRGB(70,75,90))
        btn.MouseButton1Click:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(loc.x, loc.y, loc.z)
                WarcoreUI:Notify({Title = "✅ Teleportado", Content = "Você foi para: " .. loc.name, Duration = 2})
            end
        end)

        local delBtn = Instance.new("TextButton", itemFrame)
        delBtn.Size = UDim2.new(0, 24, 0, 24)
        delBtn.Text = "✕"
        delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 14
        delBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        delBtn.AutoButtonColor = false
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 6)
        hover(delBtn, Color3.fromRGB(200,60,60), Color3.fromRGB(240,80,80), Color3.fromRGB(255,255,255))

        local index = i
        delBtn.MouseButton1Click:Connect(function()
            table.remove(savedLocations, index)
            refreshContainer()
            WarcoreUI:Notify({Title = "🗑️ Removido", Content = loc.name .. " foi deletado.", Duration = 2})
        end)
    end
    container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end

saveBtn.MouseButton1Click:Connect(function()
    if inputName.Text == "" then
        WarcoreUI:Notify({Title = "⚠️ Erro", Content = "Digite um nome para o local!", Duration = 2})
        return
    end
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local pos = char.HumanoidRootPart.Position
    local x, y, z = math.floor(pos.X * 100) / 100, math.floor(pos.Y * 100) / 100, math.floor(pos.Z * 100) / 100
    table.insert(savedLocations, {name = inputName.Text, x = x, y = y, z = z})
    inputName.Text = ""
    refreshContainer()
    WarcoreUI:Notify({Title = "💾 Salvo", Content = "Local salvo com sucesso!", Duration = 2})
end)

clearBtn.MouseButton1Click:Connect(function()
    if #savedLocations == 0 then
        WarcoreUI:Notify({Title = "⚠️ Aviso", Content = "Nenhum local do usuário para limpar.", Duration = 2})
        return
    end
    savedLocations = {}
    refreshContainer()
    WarcoreUI:Notify({Title = "🗑️ Limpo", Content = "Todos os seus locais foram removidos.", Duration = 2})
end)

RunService.RenderStepped:Connect(function()
    if tpFrame.Visible and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local p = Player.Character.HumanoidRootPart.Position
        posLabel.Text = string.format("📍 Posição: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
    end
end)
refreshContainer()

local function toggleMenu(show)
    if show then
        tpFrame.Visible = true
        tpFrame.Size = UDim2.new(0, 0, 0, 540)
        tpFrame.BackgroundTransparency = 1
        TweenService:Create(tpFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 360, 0, 540),
            BackgroundTransparency = 0.05
        }):Play()
    else
        local tween = TweenService:Create(tpFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 540),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function() tpFrame.Visible = false end)
    end
end

local function animateBtn(btn, visible)
    if visible then
        btn.Visible = true
        btn.Size = UDim2.new(0, 0, 0, 0)
        btn.BackgroundTransparency = 1
        TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 58, 0, 58),
            BackgroundTransparency = 0.1,
            TextSize = 30
        }):Play()
    else
        local tween = TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function() btn.Visible = false end)
    end
end

local TpFloatingBtn = Instance.new("TextButton", tpGui)
TpFloatingBtn.Size = UDim2.new(0, 58, 0, 58)
TpFloatingBtn.Position = UDim2.new(0.8, 0, 0.7, 0)
TpFloatingBtn.BackgroundColor3 = Color3.fromRGB(11, 13, 23)
TpFloatingBtn.BackgroundTransparency = 0.1
TpFloatingBtn.Text = "📍"
TpFloatingBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
TpFloatingBtn.Font = Enum.Font.GothamBold
TpFloatingBtn.TextSize = 30
TpFloatingBtn.AutoButtonColor = false
TpFloatingBtn.Visible = false
TpFloatingBtn.Active = true
TpFloatingBtn.ZIndex = 10

Instance.new("UICorner", TpFloatingBtn).CornerRadius = UDim.new(0, 22)
local floatShadow = Instance.new("UIStroke", TpFloatingBtn)
floatShadow.Thickness = 3
floatShadow.Color = Color3.fromRGB(0, 0, 0)
floatShadow.Transparency = 0.5
local floatStroke = Instance.new("UIStroke", TpFloatingBtn)
floatStroke.Thickness = 1.5
floatStroke.Color = Color3.fromRGB(0, 240, 255)
floatStroke.Transparency = 0.6

local isDragging = false
local dragStartPos = nil
local btnStartPos = nil
local hasMoved = false
local lastDragTime = 0
local dragThreshold = 10
local clickThreshold = 0.25

TpFloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        hasMoved = false
        dragStartPos = input.Position
        btnStartPos = TpFloatingBtn.Position
        lastDragTime = tick()
        local curSize = TpFloatingBtn.Size.X.Offset
        TweenService:Create(TpFloatingBtn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, curSize + 8, 0, curSize + 8),
            BackgroundTransparency = 0.2
        }):Play()
    end
end)

TpFloatingBtn.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        local distance = math.sqrt(delta.X * delta.X + delta.Y * delta.Y)
        if distance > dragThreshold then hasMoved = true end
        if hasMoved then
            TpFloatingBtn.Position = UDim2.new(
                btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X,
                btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

TpFloatingBtn.InputEnded:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local elapsedTime = tick() - lastDragTime
        TweenService:Create(TpFloatingBtn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 58, 0, 58),
            BackgroundTransparency = 0.1
        }):Play()
        if not hasMoved and elapsedTime < clickThreshold then
            isTeleportOpen = not isTeleportOpen
            toggleMenu(isTeleportOpen)
        elseif hasMoved then
            local screenSize = tpGui.AbsoluteSize
            local btnSize = TpFloatingBtn.Size.X.Offset
            local delta = input.Position - dragStartPos
            local newX = math.max(5, math.min(btnStartPos.X.Offset + delta.X, screenSize.X - btnSize - 5))
            local newY = math.max(5, math.min(btnStartPos.Y.Offset + delta.Y, screenSize.Y - btnSize - 5))
            TweenService:Create(TpFloatingBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, newX, 0, newY)
            }):Play()
        end
        isDragging = false
        hasMoved = false
    end
end)

minimizeBtn.MouseButton1Click:Connect(function()
    isTeleportOpen = false
    toggleMenu(false)
end)
closeBtn.MouseButton1Click:Connect(function()
    isTeleportOpen = false
    toggleMenu(false)
end)

--// =============================================
--// ABA MOVIMENTO - FUNÇÕES (Fly / No-Clip)
--// =============================================
local function stopFly()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    getgenv().SystemConfig.FlyEnabled = false
end

local function startFly()
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
    end

    if flyVelocity then flyVelocity:Destroy() end
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "FlyVelocity"
    flyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    flyVelocity.Parent = hrp
    getgenv().SystemConfig.FlyEnabled = true

    if flyConnection then flyConnection:Disconnect() end
    flyConnection = RunService.RenderStepped:Connect(function()
        if not getgenv().SystemConfig.FlyEnabled then stopFly(); return end
        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if not flyVelocity then return end

        local speed = getgenv().SystemConfig.FlySpeed
        local targetVel = Vector3.zero

        if getgenv().SystemConfig.FlyInfinite then
            targetVel = Camera.CFrame.LookVector * speed
        else
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                local flatLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
                if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                local flatCamCFrame = CFrame.lookAt(Vector3.zero, flatLook)
                local rawInput = flatCamCFrame:VectorToObjectSpace(moveDir)
                targetVel = Camera.CFrame:VectorToWorldSpace(rawInput) * speed
            else
                targetVel = Vector3.zero
            end
        end
        flyVelocity.Velocity = targetVel
    end)
end

local function startNoClip()
    NoClipAtivo = true
    if NoClipConnection then NoClipConnection:Disconnect() end
    NoClipConnection = RunService.Stepped:Connect(function()
        local char = Player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end

local function stopNoClip()
    NoClipAtivo = false
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
    local char = Player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

--// =============================================
--// INVISIBILIDADE (LOCAL)
--// =============================================
local InvisibleState = { saved = {}, active = false }

local function applyInvisiblePart(part)
    if InvisibleState.saved[part] == nil then
        InvisibleState.saved[part] = part.Transparency
    end
    part.LocalTransparencyModifier = 1
    part.Transparency = 1
end

local function setInvisibility(v)
    InvisibleState.active = v and true or false
    getgenv().SystemConfig.InvisibleEnabled = InvisibleState.active

    local char = Player.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then
                if InvisibleState.active then
                    applyInvisiblePart(d)
                elseif InvisibleState.saved[d] ~= nil then
                    d.Transparency = InvisibleState.saved[d]
                    d.LocalTransparencyModifier = 0
                    InvisibleState.saved[d] = nil
                else
                    d.Transparency = 0
                    d.LocalTransparencyModifier = 0
                end
            end
        end
    end

    if UIRefs.Invisible then UIRefs.Invisible:Set(InvisibleState.active) end
end

local function refreshInvisibility()
    if not InvisibleState.active then return end
    local char = Player.Character
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            applyInvisiblePart(d)
        end
    end
end

--// =============================================
--// INSTINTO SUPERIOR V2 (AUTO ESQUIVA)
--// Detecta projéteis, golpes e poderes próximos e desvia.
--// =============================================
local InstinctState = { last = 0 }
local InstinctKeywords = {
    "bullet", "projectile", "attack", "spell", "orb", "hitbox",
    "damage", "punch", "slash", "magic", "proj", "skill",
    "fireball", "beam", "shot", "strike", "power",
}

local function nameIsThreat(name)
    local n = string.lower(tostring(name))
    for _, kw in ipairs(InstinctKeywords) do
        if string.find(n, kw, 1, true) then return true end
    end
    return false
end

local function findAllThreat()
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local cfg = getgenv().SystemConfig
    local ok, parts = pcall(function()
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char }
        params.MaxParts = 80
        return workspace:GetPartBoundsInRadius(root.Position, cfg.InstinctRadius, params)
    end)
    if not ok or type(parts) ~= "table" then return nil end

    local best, bestDist = nil, math.huge
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            local pos = part.Position
            local dist = (root.Position - pos).Magnitude
            local vel
            local okv, v = pcall(function() return part.AssemblyLinearVelocity end)
            if okv then vel = v end

            local threat = false
            if not part.Anchored and vel and typeof(vel) == "Vector3" and vel.Magnitude > 20 then
                local toMe = root.Position - pos
                if toMe.Magnitude > 0.1 and vel.Unit:Dot(toMe.Unit) > 0.4 then
                    threat = true
                end
            end
            if not threat and nameIsThreat(part.Name) then
                if vel == nil or (typeof(vel) == "Vector3" and vel.Magnitude > 3) then
                    threat = true
                end
            end
            if not threat then
                local model = part:FindFirstAncestorOfClass("Model")
                if model and model ~= char and model:FindFirstChildOfClass("Humanoid") then
                    if dist < 14 and model:FindFirstChildOfClass("Tool") then
                        threat = true
                    end
                end
            end

            if threat and dist < bestDist then
                bestDist = dist
                best = part
            end
        end
    end
    return best
end

local function doInstinctDodge(threat)
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and hum and hum.Health > 0) then return end

    local cfg = getgenv().SystemConfig
    local dir
    local okv, vel = pcall(function() return threat.AssemblyLinearVelocity end)
    if okv and typeof(vel) == "Vector3" and vel.Magnitude > 0.1 then
        dir = Vector3.new(vel.X, 0, vel.Z)
    end
    if not dir or dir.Magnitude < 0.1 then
        dir = Vector3.new(root.Position.X - threat.Position.X, 0, root.Position.Z - threat.Position.Z)
    end
    if dir.Magnitude < 0.1 then
        dir = root.CFrame.LookVector
    end
    dir = dir.Unit

    local side = Vector3.new(-dir.Z, 0, dir.X)
    if side.Magnitude < 0.1 then side = Vector3.new(1, 0, 0) end
    side = side.Unit

    local newPos = root.Position + side * cfg.InstinctDodgeDistance + Vector3.new(0, 1.5, 0)
    root.CFrame = CFrame.new(newPos, newPos + dir)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end

local function updateInstinct()
    local cfg = getgenv().SystemConfig
    if not cfg.InstinctV2Enabled then return end
    local now = os.clock()
    if now - InstinctState.last < cfg.InstinctCooldown then return end
    local threat = findAllThreat()
    if threat then
        InstinctState.last = now
        doInstinctDodge(threat)
    end
end

--// =============================================
--// AÇÕES VINCULÁVEIS (KEYBINDS) + SINCRONIZAÇÃO
--// Reutiliza as MESMAS funções usadas pelos toggles existentes,
--// então comportamento continua idêntico.
--// =============================================
local Actions = {}

function Actions.setMira(v)
    getgenv().SystemConfig.MiraAtiva = v
    FloatingBtn.Visible = v
    UpdateBtnVisual(v)
    if UIRefs.MiraAtiva then UIRefs.MiraAtiva:Set(v) end
end

function Actions.setFly(v)
    getgenv().SystemConfig.FlyEnabled = v
    if v then startFly() else stopFly() end
    if UIRefs.FlyEnabled then UIRefs.FlyEnabled:Set(v) end
end

function Actions.setNoClip(v)
    getgenv().SystemConfig.NoClipEnabled = v
    if v then startNoClip() else stopNoClip() end
    if UIRefs.NoClipEnabled then UIRefs.NoClipEnabled:Set(v) end
end

function Actions.setSpeed(v)
    getgenv().SystemConfig.SpeedEnabled = v
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v and getgenv().SystemConfig.SpeedValue or OriginalWalkSpeed end
    if UIRefs.SpeedEnabled then UIRefs.SpeedEnabled:Set(v) end
end

function Actions.setInvisible(v)
    setInvisibility(v)
end

function Actions.setInstinct(v)
    getgenv().SystemConfig.InstinctV2Enabled = v
    InstinctState.last = 0
    if UIRefs.InstinctV2 then UIRefs.InstinctV2:Set(v) end
end

function Actions.setTeleport(v)
    getgenv().SystemConfig.TeleportEnabled = v
    if v then
        animateBtn(TpFloatingBtn, true)
    else
        animateBtn(TpFloatingBtn, false)
        if isTeleportOpen then
            isTeleportOpen = false
            toggleMenu(false)
        end
    end
    if UIRefs.TeleportEnabled then UIRefs.TeleportEnabled:Set(v) end
end

RegisterKeybind("ToggleMenu", "RightShift", function() Win.toggle() end)
RegisterKeybind("MiraAtiva", KeybindState.NONE, function() Actions.setMira(not getgenv().SystemConfig.MiraAtiva) end)
RegisterKeybind("FlyEnabled", KeybindState.NONE, function() Actions.setFly(not getgenv().SystemConfig.FlyEnabled) end)
RegisterKeybind("SpeedEnabled", KeybindState.NONE, function() Actions.setSpeed(not getgenv().SystemConfig.SpeedEnabled) end)
RegisterKeybind("NoClipEnabled", KeybindState.NONE, function() Actions.setNoClip(not getgenv().SystemConfig.NoClipEnabled) end)
RegisterKeybind("TeleportEnabled", KeybindState.NONE, function() Actions.setTeleport(not getgenv().SystemConfig.TeleportEnabled) end)
RegisterKeybind("InstinctV2Enabled", KeybindState.NONE, function() Actions.setInstinct(not getgenv().SystemConfig.InstinctV2Enabled) end)
RegisterKeybind("InvisibleEnabled", KeybindState.NONE, function() Actions.setInvisible(not getgenv().SystemConfig.InvisibleEnabled) end)

--// =============================================
--// ABAS E CONTROLES (nova interface)
--// =============================================
local CombatTab = Win.newTab("🔫 Combate")
local VisualTab = Win.newTab("👁️ Visual")
local RxTab = Win.newTab("🛸 Opções RX")
local LightTab = Win.newTab("💡 Iluminação")
local MovimentTab = Win.newTab("🧱 Movimento")
local TeleportTab = Win.newTab("📍 Teleporte")
local MonitorTab = Win.newTab("📊 Monitor")

--// ----- ABA COMBATE -----
UIRefs.MiraAtiva = CombatTab:CreateToggle({
    Name = "Ativar Mira Assistida",
    CurrentValue = getgenv().SystemConfig.MiraAtiva,
    Callback = Actions.setMira,
})
CombatTab:CreateSlider({
    Name = "Raio de Alcance da Mira (FOV)",
    Range = {50, 800},
    Increment = 10,
    CurrentValue = getgenv().SystemConfig.FovRadius,
    Callback = function(v) getgenv().SystemConfig.FovRadius = v end
})
CombatTab:CreateSlider({
    Name = "Suavidade de Resposta",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = getgenv().SystemConfig.Smoothness,
    Callback = function(v) getgenv().SystemConfig.Smoothness = v end
})

CombatTab:CreateSection("❤️ Vida")
CombatTab:CreateToggle({
    Name = "Regeneração Rápida de Vida",
    CurrentValue = getgenv().SystemConfig.HealthRegenEnabled,
    Callback = function(v)
        getgenv().SystemConfig.HealthRegenEnabled = v
        WarcoreUI:Notify({
            Title = v and "✅ Regeneração de Vida" or "⛔ Regeneração de Vida",
            Content = v and "LIGADO. Sua vida vai encher automaticamente." or "DESLIGADO.",
            Duration = 2.5,
        })
    end
})
CombatTab:CreateSlider({
    Name = "Velocidade de Regeneração (HP/s)",
    Range = {1, 200},
    Increment = 1,
    CurrentValue = getgenv().SystemConfig.HealthRegenRate,
    Callback = function(v) getgenv().SystemConfig.HealthRegenRate = v end
})

CombatTab:CreateSection("⚡ Habilidades (Tools)")
CombatTab:CreateToggle({
    Name = "Reduzir Cooldown das Habilidades (Tools)",
    CurrentValue = getgenv().SystemConfig.CooldownReduceEnabled,
    Callback = function(v)
        getgenv().SystemConfig.CooldownReduceEnabled = v
        WarcoreUI:Notify({
            Title = v and "✅ Cooldown Reduzido" or "⛔ Cooldown Reduzido",
            Content = v and "LIGADO. Cooldowns das Tools serão zerados enquanto possível." or "DESLIGADO.",
            Duration = 2.5,
        })
    end
})

CombatTab:CreateSection("🥋 Instinto Superior V2")
UIRefs.InstinctV2 = CombatTab:CreateToggle({
    Name = "Instinto Superior V2 (Auto Esquiva)",
    CurrentValue = getgenv().SystemConfig.InstinctV2Enabled,
    Callback = Actions.setInstinct
})
CombatTab:CreateSlider({
    Name = "Raio de Detecção (studs)",
    Range = {10, 120},
    Increment = 5,
    CurrentValue = getgenv().SystemConfig.InstinctRadius,
    Callback = function(v) getgenv().SystemConfig.InstinctRadius = v end
})
CombatTab:CreateSlider({
    Name = "Distância da Esquiva (studs)",
    Range = {4, 40},
    Increment = 1,
    CurrentValue = getgenv().SystemConfig.InstinctDodgeDistance,
    Callback = function(v) getgenv().SystemConfig.InstinctDodgeDistance = v end
})
CombatTab:CreateSlider({
    Name = "Cooldown da Esquiva (s)",
    Range = {0.1, 2},
    Increment = 0.05,
    CurrentValue = getgenv().SystemConfig.InstinctCooldown,
    Callback = function(v) getgenv().SystemConfig.InstinctCooldown = v end
})

--// ----- ABA VISUAL -----
VisualTab:CreateSection("Elementos de Rastreamento")
VisualTab:CreateToggle({
    Name = "Ativar Scanner Raio-X (RX)",
    CurrentValue = getgenv().SystemConfig.HighlightEnabled,
    Callback = function(v) getgenv().SystemConfig.HighlightEnabled = v end
})
VisualTab:CreateToggle({
    Name = "Fixar Ponto na Cabeça",
    CurrentValue = getgenv().SystemConfig.DotEnabled,
    Callback = function(v) getgenv().SystemConfig.DotEnabled = v end
})
VisualTab:CreateToggle({
    Name = "Linha de Mira (trajeto)",
    CurrentValue = getgenv().SystemConfig.LineEnabled,
    Callback = function(v) getgenv().SystemConfig.LineEnabled = v end
})
VisualTab:CreateToggle({
    Name = "Micro-HUD: Exibir Vida nos Pés",
    CurrentValue = getgenv().SystemConfig.MicroHpEnabled,
    Callback = function(v) getgenv().SystemConfig.MicroHpEnabled = v end
})
VisualTab:CreateToggle({
    Name = "Micro-HUD: Exibir Distância + Nome",
    CurrentValue = getgenv().SystemConfig.MicroDistEnabled,
    Callback = function(v) getgenv().SystemConfig.MicroDistEnabled = v end
})

VisualTab:CreateSection("Ajuste de Escala (Tamanho)")
VisualTab:CreateSlider({
    Name = "Tamanho do Texto (Distância)",
    Range = {6, 24},
    Increment = 1,
    CurrentValue = getgenv().SystemConfig.MicroTextSize,
    Callback = function(v) getgenv().SystemConfig.MicroTextSize = v end
})
VisualTab:CreateSlider({
    Name = "Largura da Barra de Vida",
    Range = {20, 100},
    Increment = 5,
    CurrentValue = getgenv().SystemConfig.MicroWidth,
    Callback = function(v) getgenv().SystemConfig.MicroWidth = v end
})

VisualTab:CreateSection("ESP • Caixa 2D")
VisualTab:CreateToggle({
    Name = "Ativar ESP Box (contorno)",
    CurrentValue = getgenv().SystemConfig.EspBoxEnabled,
    Callback = function(v) getgenv().SystemConfig.EspBoxEnabled = v end
})
VisualTab:CreateToggle({
    Name = "Barra de Vida no ESP",
    CurrentValue = getgenv().SystemConfig.EspHealthEnabled,
    Callback = function(v) getgenv().SystemConfig.EspHealthEnabled = v end
})
VisualTab:CreateColorPicker({
    Name = "Cor da Caixa ESP",
    Color = getgenv().SystemConfig.EspBoxColor,
    Callback = function(Value) getgenv().SystemConfig.EspBoxColor = Value end
})

VisualTab:CreateSection("🫥 Invisibilidade")
UIRefs.Invisible = VisualTab:CreateToggle({
    Name = "Ficar Invisível (Local)",
    CurrentValue = getgenv().SystemConfig.InvisibleEnabled,
    Callback = Actions.setInvisible
})

--// ----- ABA OPÇÕES RX -----
RxTab:CreateSection("Configurações Avançadas do Raio-X")
RxTab:CreateDropdown({
    Name = "Modo de Visibilidade (Parede)",
    Options = {"Ver através (AlwaysOnTop)", "Ocultar atrás (Occluded)"},
    CurrentOption = (getgenv().SystemConfig.HlDepthMode == "Occluded") and "Ocultar atrás (Occluded)" or "Ver através (AlwaysOnTop)",
    Callback = function(Option)
        if Option == "Ver através (AlwaysOnTop)" then
            getgenv().SystemConfig.HlDepthMode = "AlwaysOnTop"
        else
            getgenv().SystemConfig.HlDepthMode = "Occluded"
        end
    end,
})
RxTab:CreateSlider({
    Name = "Transparência do Brilho (Fill)",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = getgenv().SystemConfig.HlFillTransparency,
    Callback = function(v) getgenv().SystemConfig.HlFillTransparency = v end
})
RxTab:CreateColorPicker({
    Name = "Cor do Contorno (Inimigos)",
    Color = getgenv().SystemConfig.HlEnemyColor,
    Callback = function(Value) getgenv().SystemConfig.HlEnemyColor = Value end
})

RxTab:CreateSection("Personalização de Mira")
RxTab:CreateColorPicker({
    Name = "Cor da Linha de Mira",
    Color = getgenv().SystemConfig.LineColor,
    Callback = function(Value) getgenv().SystemConfig.LineColor = Value end
})
RxTab:CreateSlider({
    Name = "Espessura da Linha",
    Range = {0.5, 5},
    Increment = 0.5,
    CurrentValue = getgenv().SystemConfig.LineThickness,
    Callback = function(v) getgenv().SystemConfig.LineThickness = v end
})
RxTab:CreateDropdown({
    Name = "Origem da Linha (trajeto)",
    Options = {"Crosshair (centro)", "Baixo (base da tela)", "Personagem (pés)"},
    CurrentOption = getgenv().SystemConfig.LineOrigin,
    Callback = function(Option) getgenv().SystemConfig.LineOrigin = Option end
})
RxTab:CreateDropdown({
    Name = "Ponto de Mira (alvo)",
    Options = {"Cabeça", "Corpo"},
    CurrentOption = getgenv().SystemConfig.LineTarget,
    Callback = function(Option) getgenv().SystemConfig.LineTarget = Option end
})
RxTab:CreateToggle({
    Name = "Contorno de Destaque na Linha",
    CurrentValue = getgenv().SystemConfig.LineOutline,
    Callback = function(v) getgenv().SystemConfig.LineOutline = v end
})
RxTab:CreateToggle({
    Name = "Linha Pulsante (animada)",
    CurrentValue = getgenv().SystemConfig.LinePulse,
    Callback = function(v) getgenv().SystemConfig.LinePulse = v end
})
RxTab:CreateColorPicker({
    Name = "Cor da Distância (Micro-HUD)",
    Color = getgenv().SystemConfig.DistColor,
    Callback = function(Value) getgenv().SystemConfig.DistColor = Value end
})
RxTab:CreateDropdown({
    Name = "Forma do Ponto na Cabeça",
    Options = {"Círculo ●", "Triângulo ▲", "Quadrado ■", "Losango ◆", "Estrela ★"},
    CurrentOption = ({
        ["●"] = "Círculo ●", ["▲"] = "Triângulo ▲", ["■"] = "Quadrado ■",
        ["◆"] = "Losango ◆", ["★"] = "Estrela ★"
    })[getgenv().SystemConfig.DotShape] or "Círculo ●",
    Callback = function(Option)
        local shapeMap = {
            ["Círculo ●"] = "●",
            ["Triângulo ▲"] = "▲",
            ["Quadrado ■"] = "■",
            ["Losango ◆"] = "◆",
            ["Estrela ★"] = "★"
        }
        getgenv().SystemConfig.DotShape = shapeMap[Option] or "●"
    end
})
RxTab:CreateToggle({
    Name = "Exibir Círculo de FOV (alcance da mira)",
    CurrentValue = getgenv().SystemConfig.FovCircleEnabled,
    Callback = function(v) getgenv().SystemConfig.FovCircleEnabled = v end
})
RxTab:CreateColorPicker({
    Name = "Cor do Círculo de FOV",
    Color = getgenv().SystemConfig.FovCircleColor,
    Callback = function(Value) getgenv().SystemConfig.FovCircleColor = Value end
})

--// ----- ABA ILUMINAÇÃO -----
LightTab:CreateToggle({
    Name = "Filtro FullBright Ambiência",
    CurrentValue = getgenv().SystemConfig.FullBright,
    Callback = function(v)
        getgenv().SystemConfig.FullBright = v
        if not v then
            Lighting.Ambient = OriginalSettings.Ambient
            Lighting.Brightness = OriginalSettings.Brightness
            Lighting.ClockTime = OriginalSettings.ClockTime
            Lighting.FogEnd = OriginalSettings.FogEnd
            Lighting.OutdoorAmbient = OriginalSettings.OutdoorAmbient
        end
    end
})
LightTab:CreateToggle({
    Name = "Clareza Técnico Aprimorada",
    CurrentValue = getgenv().SystemConfig.ClarezaMod,
    Callback = function(v) getgenv().SystemConfig.ClarezaMod = v end
})
LightTab:CreateToggle({
    Name = "Otimizar: Remover Sombras",
    CurrentValue = getgenv().SystemConfig.NoShadows,
    Callback = function(v)
        getgenv().SystemConfig.NoShadows = v
        Lighting.GlobalShadows = not v
    end
})
LightTab:CreateSection("🕐 Horário Fixo")
LightTab:CreateToggle({
    Name = "Forçar Horário do Jogo",
    CurrentValue = getgenv().SystemConfig.ClockOverrideEnabled,
    Callback = function(v)
        getgenv().SystemConfig.ClockOverrideEnabled = v
        if not v then
            Lighting.ClockTime = OriginalSettings.ClockTime
        end
    end
})
LightTab:CreateSlider({
    Name = "Hora do Dia (0-24)",
    Range = {0, 24},
    Increment = 1,
    CurrentValue = getgenv().SystemConfig.ClockTime,
    Callback = function(v) getgenv().SystemConfig.ClockTime = v end
})

--// ----- ABA MOVIMENTO -----
MovimentTab:CreateSection("🕊️ Fly")
UIRefs.FlyEnabled = MovimentTab:CreateToggle({
    Name = "Ativar Fly",
    CurrentValue = getgenv().SystemConfig.FlyEnabled,
    Callback = Actions.setFly,
})
MovimentTab:CreateToggle({
    Name = "Modo Infinito (câmera)",
    CurrentValue = getgenv().SystemConfig.FlyInfinite,
    Callback = function(v) getgenv().SystemConfig.FlyInfinite = v end
})
MovimentTab:CreateSlider({
    Name = "Velocidade do Fly",
    Range = {1, 500},
    Increment = 1,
    CurrentValue = getgenv().SystemConfig.FlySpeed,
    Callback = function(v) getgenv().SystemConfig.FlySpeed = v end
})

MovimentTab:CreateSection("🧱 No-Clip")
UIRefs.NoClipEnabled = MovimentTab:CreateToggle({
    Name = "Ativar Matriz No-Clip",
    CurrentValue = getgenv().SystemConfig.NoClipEnabled,
    Callback = Actions.setNoClip,
})

MovimentTab:CreateSection("⚡ Velocidade de Caminhada")
UIRefs.SpeedEnabled = MovimentTab:CreateToggle({
    Name = "Ativar Speed Hack",
    CurrentValue = getgenv().SystemConfig.SpeedEnabled,
    Callback = Actions.setSpeed,
})
MovimentTab:CreateSlider({
    Name = "Velocidade",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = getgenv().SystemConfig.SpeedValue,
    Callback = function(v)
        getgenv().SystemConfig.SpeedValue = v
        if getgenv().SystemConfig.SpeedEnabled then
            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

MovimentTab:CreateSection("🦘 Super Pulo")
MovimentTab:CreateToggle({
    Name = "Ativar Super Pulo",
    CurrentValue = getgenv().SystemConfig.JumpEnabled,
    Callback = function(v)
        getgenv().SystemConfig.JumpEnabled = v
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v and getgenv().SystemConfig.JumpPower or OriginalJumpPower end
    end
})
MovimentTab:CreateSlider({
    Name = "Altura do Pulo",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = getgenv().SystemConfig.JumpPower,
    Callback = function(v)
        getgenv().SystemConfig.JumpPower = v
        if getgenv().SystemConfig.JumpEnabled then
            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end
    end
})

MovimentTab:CreateSection("🔄 Pulo Infinito")
MovimentTab:CreateToggle({
    Name = "Pulo Infinito (pular no ar)",
    CurrentValue = getgenv().SystemConfig.InfiniteJump,
    Callback = function(v) getgenv().SystemConfig.InfiniteJump = v end
})

MovimentTab:CreateSection("🛡️ Utilidade")
MovimentTab:CreateToggle({
    Name = "Anti-AFK (não ser kickado por inatividade)",
    CurrentValue = getgenv().SystemConfig.AntiAfkEnabled,
    Callback = function(v) getgenv().SystemConfig.AntiAfkEnabled = v end
})

--// ----- ABA TELEPORTE -----
TeleportTab:CreateSection("Painel de Teleporte")
UIRefs.TeleportEnabled = TeleportTab:CreateToggle({
    Name = "Ativar Sistema de Teleporte",
    CurrentValue = getgenv().SystemConfig.TeleportEnabled,
    Callback = Actions.setTeleport,
})
TeleportTab:CreateButton({
    Name = "Abrir Painel de Teleporte",
    Callback = function()
        isTeleportOpen = true
        toggleMenu(true)
    end
})

TeleportTab:CreateSection("🎯 Teleporte Rápido")
TeleportTab:CreateButton({
    Name = "Teleportar até o Inimigo Mais Próximo",
    Callback = function()
        local target = getTarget()
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (target and hrp) then
            WarcoreUI:Notify({ Title = "🎯 Teleporte", Content = "Nenhum inimigo encontrado no alcance.", Duration = 3 })
            return
        end
        local tRoot = target.Parent and target.Parent:FindFirstChild("HumanoidRootPart")
        hrp.CFrame = tRoot and (tRoot.CFrame * CFrame.new(0, 0, 3)) or CFrame.new(target.Position)
        WarcoreUI:Notify({ Title = "🎯 Teleporte", Content = "Teleportado até o inimigo mais próximo.", Duration = 3 })
    end
})

--// ----- ABA MONITOR -----
MonitorTab:CreateToggle({
    Name = "Monitorar Taxa de FPS",
    CurrentValue = getgenv().SystemConfig.ShowFPS,
    Callback = function(v) getgenv().SystemConfig.ShowFPS = v; fpsF.Visible = v end
})
MonitorTab:CreateToggle({
    Name = "Contador Ativo de Players",
    CurrentValue = getgenv().SystemConfig.ShowPlayers,
    Callback = function(v) getgenv().SystemConfig.ShowPlayers = v; countF.Visible = v end
})

--// ----- ABA KEYBINDS -----
local KeybindTab = Win.newTab("⌨️ Keybinds")
KeybindTab:CreateSection("Teclas de Atalho (toque e pressione a tecla)")

local function makeBind(actionName, label)
    local control
    control = KeybindTab:CreateKeybind({
        Name = label,
        Key = KeybindState.keys[actionName] or KeybindState.NONE,
        Callback = function(k)
            KeybindState.keys[actionName] = k
            if getgenv().SystemConfig.Keybinds then
                getgenv().SystemConfig.Keybinds[actionName] = k
            end
        end,
    })
    return control
end

makeBind("ToggleMenu", "Abrir / Fechar Menu")
makeBind("MiraAtiva", "Alternar Mira Assistida")
makeBind("FlyEnabled", "Alternar Fly")
makeBind("SpeedEnabled", "Alternar Speed Hack")
makeBind("NoClipEnabled", "Alternar No-Clip")
makeBind("TeleportEnabled", "Alternar Sistema de Teleporte")
makeBind("InstinctV2Enabled", "Alternar Instinto Superior V2")
makeBind("InvisibleEnabled", "Alternar Invisibilidade")

Win.selectTab(1)

--// =============================================
--// SISTEMA DE LINHA DE MIRA (TRAJETO 2D - OVERHAUL V2)
--// Rastro formado por segmentos: afinado e desvanecido,
--// com contorno, pulso animado, escala por distância e
--// checagem de time. Visual de "feixe" bem mais visível.
--// =============================================
local SEGMENTS = 12
local Lines = {} -- { segs = {...}, outline = Drawing } por jogador
local hasDrawing = (type(Drawing) == "table" and type(Drawing.new) == "function")

local function destroyTracer(player)
    local tracer = Lines[player]
    if tracer then
        if tracer.segs then
            for _, seg in ipairs(tracer.segs) do seg:Remove() end
        end
        if tracer.outline then tracer.outline:Remove() end
        Lines[player] = nil
    end
end

local function createTracer(player)
    if not hasDrawing then return end
    if player == Player then return end
    if Lines[player] then return end

    local segs = {}
    for i = 1, SEGMENTS do
        local seg = Drawing.new("Line")
        seg.Visible = false
        seg.Transparency = 1
        seg.ZIndex = 2
        segs[i] = seg
    end

    local outline = Drawing.new("Line")
    outline.Visible = false
    outline.Transparency = 1
    outline.ZIndex = 1

    Lines[player] = { segs = segs, outline = outline }

    player.AncestryChanged:Connect(function()
        if not player.Parent then destroyTracer(player) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do createTracer(p) end
Players.PlayerAdded:Connect(createTracer)
Players.PlayerRemoving:Connect(destroyTracer)

--// =============================================
--// ESP (CAIXA 2D) + BARRA DE VIDA + CIRCULO DE FOV
--// =============================================
local Visuals = { Boxes = {} }

if hasDrawing then
    local okCircle, circle = pcall(Drawing.new, "Circle")
    if okCircle and circle then
        circle.Thickness = 1.5
        circle.NumSides = 64
        circle.Filled = false
        circle.Transparency = 0.7
        circle.Visible = false
        Visuals.FovCircle = circle
    end
end

function Visuals.destroyEsp(p)
    local b = Visuals.Boxes[p]
    if b then
        for _, d in pairs(b) do d:Remove() end
        Visuals.Boxes[p] = nil
    end
end

local function createEsp(p)
    if not hasDrawing then return end
    if p == Player or Visuals.Boxes[p] then return end
    local okBox, box = pcall(Drawing.new, "Square")
    if not okBox or not box then return end
    box.Filled = false
    box.Thickness = 1.5
    box.Visible = false
    local _, hpBg = pcall(Drawing.new, "Square")
    hpBg.Filled = true
    hpBg.Color = Color3.fromRGB(0, 0, 0)
    hpBg.Transparency = 0.6
    hpBg.Visible = false
    local _, hpFill = pcall(Drawing.new, "Square")
    hpFill.Filled = true
    hpFill.Color = Color3.fromRGB(0, 255, 120)
    hpFill.Visible = false
    local _, nameText = pcall(Drawing.new, "Text")
    nameText.Size = 13
    nameText.Center = true
    nameText.Outline = true
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Visible = false
    Visuals.Boxes[p] = { box = box, hpBg = hpBg, hpFill = hpFill, nameText = nameText }
    p.AncestryChanged:Connect(function()
        if not p.Parent then Visuals.destroyEsp(p) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do createEsp(p) end
Players.PlayerAdded:Connect(createEsp)
Players.PlayerRemoving:Connect(Visuals.destroyEsp)

function Visuals.updateBoxes()
    if not hasDrawing then return end
    local cfg = getgenv().SystemConfig
    for p, b in pairs(Visuals.Boxes) do
        local char = p.Character
        local head = char and char:FindFirstChild("Head")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
        local blocked = isTeam and cfg.TeamCheck
        local show = cfg.EspBoxEnabled and head and root and hum and hum.Health > 0 and not blocked

        local top, bottom, left, width
        if show then
            local hp, on1 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
            local fp, on2 = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            if on1 and on2 and hp.Z > 0 and fp.Z > 0 then
                top = hp.Y
                bottom = fp.Y
                local height = math.max(bottom - top, 8)
                width = height * 0.55
                left = ((hp.X + fp.X) / 2) - width / 2
            else
                show = false
            end
        end

        if show then
            local color = isTeam and Color3.fromRGB(0, 255, 0) or cfg.EspBoxColor
            b.box.Position = Vector2.new(left, top)
            b.box.Size = Vector2.new(width, bottom - top)
            b.box.Color = color
            b.box.Visible = true

            if cfg.EspHealthEnabled and b.hpBg and b.hpFill then
                local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local barH = bottom - top
                local bx = left - 6
                b.hpBg.Position = Vector2.new(bx, top)
                b.hpBg.Size = Vector2.new(3, barH)
                b.hpBg.Visible = true
                b.hpFill.Position = Vector2.new(bx, top + barH * (1 - ratio))
                b.hpFill.Size = Vector2.new(3, barH * ratio)
                b.hpFill.Visible = true
            else
                if b.hpBg then b.hpBg.Visible = false end
                if b.hpFill then b.hpFill.Visible = false end
            end

            if b.nameText then
                b.nameText.Position = Vector2.new(left + width / 2, top - 16)
                b.nameText.Text = p.Name
                b.nameText.Color = color
                b.nameText.Visible = true
            end
        else
            b.box.Visible = false
            if b.hpBg then b.hpBg.Visible = false end
            if b.hpFill then b.hpFill.Visible = false end
            if b.nameText then b.nameText.Visible = false end
        end
    end
end

function Visuals.updateFov()
    local circle = Visuals.FovCircle
    if not circle then return end
    local cfg = getgenv().SystemConfig
    if cfg.FovCircleEnabled then
        local vp = Camera.ViewportSize
        circle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        circle.Radius = cfg.FovRadius
        circle.Color = cfg.FovCircleColor
        circle.Visible = true
    else
        circle.Visible = false
    end
end

--// =============================================
--// TELEPORTE UTILITÁRIO + ANTI-AFK
--// =============================================
local function notifyTp(title, content)
    WarcoreUI:Notify({ Title = title, Content = content, Duration = 2.5 })
end

local function teleportToPosition(target)
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    return (pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.new(target)
    end))
end

local function isDestinationBlocked(target, ignoreList)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Blacklist
    local list = { Player.Character }
    if ignoreList then
        for _, item in ipairs(ignoreList) do
            if item then table.insert(list, item) end
        end
    end
    overlap.FilterDescendantsInstances = list
    overlap.MaxParts = 25
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInBox(CFrame.new(target), Vector3.new(2, 3.6, 2), overlap)
    end)
    if ok and type(parts) == "table" then
        for _, part in ipairs(parts) do
            if part:IsA("BasePart") and part.CanCollide then
                return true
            end
        end
    end
    return false
end

local function validateDestinationPoint(target)
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hum and root) or hum.Health <= 0 then
        return false, "Personagem indisponível."
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { char }
    local probe = target + Vector3.new(0, 8, 0)
    local ground = workspace:Raycast(probe, Vector3.new(0, -30, 0), params)
    if not ground then
        return false, "Sem piso válido nesse destino."
    end
    if ground.Material == Enum.Material.Water then
        return false, "Destino sobre a água."
    end
    if probe.Y - ground.Position.Y > 14 then
        return false, "Destino alto demais ou sem chão próximo."
    end

    if isDestinationBlocked(target, { ground.Instance }) then
        return false, "Destino bloqueado por um prédio ou obstáculo."
    end

    return true
end


Player.Idled:Connect(function()
    if not getgenv().SystemConfig.AntiAfkEnabled then return end
    local vu = game:GetService("VirtualUser")
    pcall(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

--// =============================================
--// DESTINO SALVO + ANTI-VOID (RECUPERAÇÃO DE POSIÇÃO)
--// =============================================
local tpSavedUI = { info = nil, lastAt = 0 }

local function getSavedDestination()
    local cfg = getgenv().SystemConfig
    if not cfg.SavedDestinationActive then return nil end
    return Vector3.new(cfg.SavedDestinationX or 0, cfg.SavedDestinationY or 0, cfg.SavedDestinationZ or 0)
end

local function setSavedDestination(pos, name)
    local cfg = getgenv().SystemConfig
    cfg.SavedDestinationX = pos.X
    cfg.SavedDestinationY = pos.Y
    cfg.SavedDestinationZ = pos.Z
    cfg.SavedDestinationName = name or "Destino salvo"
    cfg.SavedDestinationActive = true
end

local function clearSavedDestination()
    local cfg = getgenv().SystemConfig
    cfg.SavedDestinationActive = false
    cfg.SavedDestinationX = 0
    cfg.SavedDestinationY = 0
    cfg.SavedDestinationZ = 0
    cfg.SavedDestinationName = ""
end

local function renderSavedDestinationUI(force)
    if not tpSavedUI.info then return end
    local now = os.clock()
    if not force and now - tpSavedUI.lastAt < 0.25 then return end
    tpSavedUI.lastAt = now

    local target = getSavedDestination()
    if not target then
        tpSavedUI.info.Text = "📌 Nenhum destino salvo."
        return
    end

    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local text = string.format("📌 Salvo: %.1f, %.1f, %.1f", target.X, target.Y, target.Z)
    if root then
        text = text .. string.format("  •  %.0f studs", (target - root.Position).Magnitude)
    end
    tpSavedUI.info.Text = text
end

local function getVoidThreshold()
    local height = workspace.FallenPartsDestroyHeight
    if type(height) ~= "number" then return nil end
    if height <= -100000 then return nil end
    return height + 50
end

local antiVoid = {
    lastSafe = nil,
    lastSaveAt = 0,
    cooldownUntil = 0,
    warned = false,
}

local function resetAntiVoidState()
    antiVoid.lastSafe = nil
    antiVoid.lastSaveAt = 0
    antiVoid.cooldownUntil = 0
    antiVoid.warned = false
end

local function updateAntiVoidRecovery()
    if not getgenv().SystemConfig.AntiVoidEnabled then return end
    if getgenv().SystemConfig.FlyEnabled then return end

    local threshold = getVoidThreshold()
    if not threshold then return end

    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) or hum.Health <= 0 then return end

    local now = os.clock()
    local pos = root.Position

    if pos.Y > threshold then
        if now - antiVoid.lastSaveAt >= 0.5 then
            antiVoid.lastSaveAt = now
            local velocity = root.AssemblyLinearVelocity
            local fallSpeed = velocity and math.abs(velocity.Y) or 0
            local grounded = hum.FloorMaterial ~= Enum.Material.Air
            if pos.Y > threshold + 15 and (grounded or fallSpeed < 25) then
                antiVoid.lastSafe = pos
            end
        end
        return
    end

    if now < antiVoid.cooldownUntil then return end

    if not antiVoid.lastSafe then
        if not antiVoid.warned then
            antiVoid.warned = true
            notifyTp("🛟 Anti-Void", "Sem posição segura registrada para recuperação.")
        end
        return
    end

    antiVoid.cooldownUntil = now + 3
    antiVoid.warned = false
    if teleportToPosition(antiVoid.lastSafe + Vector3.new(0, 2, 0)) then
        notifyTp("🛟 Anti-Void", "Você foi recuperado para a última posição segura.")
    else
        notifyTp("⚠️ Anti-Void", "Não foi possível recuperar (o jogo pode ter bloqueado).")
    end
end

local function saveCurrentDestination()
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) or hum.Health <= 0 then
        notifyTp("⚠️ Destino Salvo", "Personagem indisponível para salvar a posição.")
        return
    end

    local pos = root.Position
    local threshold = getVoidThreshold()
    if threshold and pos.Y <= threshold + 5 then
        notifyTp("⚠️ Destino Salvo", "A posição está na zona de queda e não foi salva.")
        return
    end

    setSavedDestination(pos, "Destino salvo")
    renderSavedDestinationUI(true)
    notifyTp("📌 Destino Salvo", string.format("Guardado em %.1f, %.1f, %.1f.", pos.X, pos.Y, pos.Z))
end

local function goToSavedDestination()
    local target = getSavedDestination()
    if not target then
        notifyTp("⚠️ Destino Salvo", "Nenhum destino salvo ainda.")
        return
    end

    local ok, err = validateDestinationPoint(target)
    if not ok then
        notifyTp("⚠️ Destino Salvo", (err or "Destino inválido.") .. " Tente outro local.")
        return
    end

    if teleportToPosition(target) then
        notifyTp("✅ Destino Salvo", "Você foi para o destino salvo.")
    else
        notifyTp("⚠️ Destino Salvo", "Não foi possível teleportar (o jogo pode ter bloqueado).")
    end
end

local function deleteSavedDestination()
    if not getSavedDestination() then
        notifyTp("⚠️ Destino Salvo", "Nenhum destino salvo para apagar.")
        return
    end
    clearSavedDestination()
    renderSavedDestinationUI(true)
    notifyTp("🗑️ Destino Salvo", "Destino salvo removido.")
end

TeleportTab:CreateSection("📌 Destino Salvo")
tpSavedUI.info = TeleportTab:CreateSection("📌 Nenhum destino salvo.")
TeleportTab:CreateButton({
    Name = "SALVAR DESTINO",
    Callback = saveCurrentDestination,
})
TeleportTab:CreateButton({
    Name = "IR PARA DESTINO SALVO",
    Callback = goToSavedDestination,
})
TeleportTab:CreateButton({
    Name = "APAGAR DESTINO",
    Callback = deleteSavedDestination,
})
renderSavedDestinationUI(true)

TeleportTab:CreateSection("🛟 ANTI-VOID • Recuperação de Posição")
TeleportTab:CreateToggle({
    Name = "Ativar ANTI-VOID (recupera a última posição segura)",
    CurrentValue = getgenv().SystemConfig.AntiVoidEnabled,
    Callback = function(v)
        getgenv().SystemConfig.AntiVoidEnabled = v
        resetAntiVoidState()
        if v then
            WarcoreUI:Notify({ Title = "🛟 Anti-Void", Content = "LIGADO. Monitorando quedas para fora do mapa.", Duration = 2.5 })
        else
            WarcoreUI:Notify({ Title = "🛟 Anti-Void", Content = "DESLIGADO.", Duration = 2 })
        end
    end
})

local function getLineOrigin()
    local vp = Camera.ViewportSize
    local mode = getgenv().SystemConfig.LineOrigin

    if mode == "Baixo (base da tela)" then
        return Vector2.new(vp.X / 2, vp.Y)
    elseif mode == "Personagem (pés)" then
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local p, on = Camera:WorldToViewportPoint(hrp.Position)
            if on and p.Z > 0 then return Vector2.new(p.X, p.Y) end
        end
        return Vector2.new(vp.X / 2, vp.Y)
    else
        return Vector2.new(vp.X / 2, vp.Y / 2) -- Crosshair
    end
end

local function getLineTarget(char)
    if getgenv().SystemConfig.LineTarget == "Corpo" then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function updateLines()
    if not hasDrawing then return end
    local cfg = getgenv().SystemConfig
    local enabled = cfg.LineEnabled
    local origin = getLineOrigin()
    local pulse = cfg.LinePulse and (0.55 + 0.45 * math.abs(math.sin(tick() * 3))) or 1

    for player, tracer in pairs(Lines) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local target = char and getLineTarget(char)

        local isTeam = (player.Team == Player.Team and Player.Team ~= nil)
        local blocked = isTeam and cfg.TeamCheck

        local show, tipX, tipY = false, nil, nil
        if enabled and target and hum and hum.Health > 0 and not blocked then
            local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
            if onScreen and pos.Z > 0 then
                show = true
                tipX, tipY = pos.X, pos.Y
            end
        end

        if show then
            local dx, dy = tipX - origin.X, tipY - origin.Y
            local distance = Player:DistanceFromCharacter(target.Position)
            local scale = math.clamp(1 - (distance / (cfg.FovRadius * 4)), 0.4, 1)
            local baseThickness = math.max(0.5, cfg.LineThickness * scale)

            for i = 1, SEGMENTS do
                local seg = tracer.segs[i]
                local t0 = (i - 1) / SEGMENTS
                local t1 = i / SEGMENTS
                seg.From = Vector2.new(origin.X + dx * t0, origin.Y + dy * t0)
                seg.To = Vector2.new(origin.X + dx * t1, origin.Y + dy * t1)
                seg.Color = cfg.LineColor
                seg.Thickness = math.max(0.4, baseThickness * (1 - t0 * 0.65))
                seg.Transparency = (0.15 + 0.7 * t0) * pulse
                seg.Visible = true
            end

            local outline = tracer.outline
            outline.From = origin
            outline.To = Vector2.new(tipX, tipY)
            outline.Color = Color3.fromRGB(0, 0, 0)
            outline.Thickness = baseThickness + 1.5
            outline.Transparency = 0.55 * pulse
            outline.Visible = cfg.LineOutline
        else
            for i = 1, SEGMENTS do tracer.segs[i].Visible = false end
            tracer.outline.Visible = false
        end
    end
end

--// =============================================
--// LOOP PRINCIPAL
--// =============================================
RunService.RenderStepped:Connect(function(dt)
    if getgenv().SystemConfig.InfiniteJump then
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Freefall and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end

    if getgenv().SystemConfig.ShowFPS then
        fpsL.Text = " ⚡ FPS: " .. math.floor(1 / dt)
    end
    if getgenv().SystemConfig.ShowPlayers then
        countL.Text = " 👥 Players: " .. #Players:GetPlayers()
    end

    updateLines()
    updateAntiVoidRecovery()
    renderSavedDestinationUI()
    Visuals.updateBoxes()
    Visuals.updateFov()
    updateInstinct()

    if getgenv().SystemConfig.MiraAtiva then
        local target = getTarget()
        if target then
            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, getgenv().SystemConfig.Smoothness * math.clamp(60 * dt, 0, 1))
        end
    end

    if getgenv().SystemConfig.FullBright then
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.ClockTime = 14
    end
    if getgenv().SystemConfig.ClarezaMod then
        Lighting.Brightness = 3
        Lighting.ExposureCompensation = 0.5
    else
        if not getgenv().SystemConfig.FullBright then
            Lighting.Brightness = OriginalSettings.Brightness
            Lighting.ExposureCompensation = OriginalSettings.Exposure
        end
    end

    if getgenv().SystemConfig.ClockOverrideEnabled then
        Lighting.ClockTime = getgenv().SystemConfig.ClockTime
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local char = p.Character
            local head = char:FindFirstChild("Head")
            if head then
                local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                local statusColor = isTeam and Color3.fromRGB(0, 255, 0) or getgenv().SystemConfig.HlEnemyColor

                local hl = char:FindFirstChild("System_HL")
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "System_HL"
                    hl.Parent = char
                end
                hl.Enabled = getgenv().SystemConfig.HighlightEnabled
                hl.FillColor = statusColor
                hl.OutlineColor = statusColor
                hl.FillTransparency = getgenv().SystemConfig.HlFillTransparency
                hl.OutlineTransparency = 0
                hl.Adornee = char
                pcall(function()
                    hl.DepthMode = getDepthMode()
                end)

                local behind = IsBehindWall(head)
                local dotColor = isTeam and Color3.fromRGB(0, 255, 0) or (behind and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(255, 0, 0))
                local dot = head:FindFirstChild("System_Dot")
                if not dot then
                    local bill = Instance.new("BillboardGui", head)
                    bill.Name = "System_Dot"
                    bill.Size = UDim2.new(0, 24, 0, 24)
                    bill.AlwaysOnTop = true
                    bill.ExtentsOffset = Vector3.new(0, 1.5, 0)
                    local label = Instance.new("TextLabel", bill)
                    label.Size = UDim2.new(1,0,1,0)
                    label.BackgroundTransparency = 1
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 18
                    label.TextColor3 = dotColor
                    label.Text = getgenv().SystemConfig.DotShape
                    label.TextStrokeTransparency = 0.3
                    label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
                    label.TextXAlignment = Enum.TextXAlignment.Center
                    label.TextYAlignment = Enum.TextYAlignment.Center
                    dot = bill
                end
                dot.Enabled = getgenv().SystemConfig.DotEnabled
                local label = dot:FindFirstChildOfClass("TextLabel")
                if label then
                    label.TextColor3 = dotColor
                    label.Text = getgenv().SystemConfig.DotShape
                    local shape = getgenv().SystemConfig.DotShape
                    if shape == "●" then label.TextSize = 18
                    elseif shape == "▲" then label.TextSize = 20
                    elseif shape == "■" then label.TextSize = 18
                    elseif shape == "◆" then label.TextSize = 20
                    elseif shape == "★" then label.TextSize = 20
                    end
                end
            end

            -- Micro-HUD: barra de vida e/ou nome + distância (independentes)
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and root then
                local hud = root:FindFirstChild("Aguia_MicroHUD")
                local cfg = getgenv().SystemConfig
                if (cfg.MicroHpEnabled or cfg.MicroDistEnabled) and hum.Health > 0 then
                    local currentHud = CreateMicroDisplay(char, p.Name)
                    if currentHud then
                        local isTeam = (p.Team == Player.Team and Player.Team ~= nil)
                        local healthRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)

                        if cfg.MicroHpEnabled then
                            local bar = currentHud.BackgroundBar.MainBar
                            bar.Size = bar.Size:Lerp(UDim2.new(healthRatio, 0, 1, 0), 0.35)
                            bar.BackgroundColor3 = isTeam and Color3.fromRGB(0, 200, 255) or HealthColor(healthRatio)
                            currentHud.BackgroundBar.Visible = true
                        else
                            currentHud.BackgroundBar.Visible = false
                        end

                        if cfg.MicroDistEnabled then
                            local distance = math.floor(Player:DistanceFromCharacter(root.Position))
                            currentHud.DistLabel.Text = string.format("%s  %dm", p.Name, distance)
                            currentHud.DistLabel.TextColor3 = cfg.DistColor
                            currentHud.DistLabel.Visible = true
                            currentHud.BackgroundBar.Position = UDim2.new(0, 0, 0, cfg.MicroTextSize + 2)
                        else
                            currentHud.DistLabel.Visible = false
                            currentHud.BackgroundBar.Position = UDim2.new(0, 0, 0, 0)
                        end
                        currentHud.Enabled = true
                    end
                else
                    if hud then hud.Enabled = false end
                end
            end
        end
    end
end)

-- Forçar Speed, Jump, Vida e Cooldowns no Heartbeat
local cooldownAccum = 0
RunService.Heartbeat:Connect(function(dt)
    local cfg = getgenv().SystemConfig

    if cfg.CooldownReduceEnabled then
        cooldownAccum = cooldownAccum + dt
        if cooldownAccum >= 0.05 then
            cooldownAccum = 0
            resetToolCooldowns()
        end
    else
        cooldownAccum = 0
    end

    refreshInvisibility()

    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if cfg.HealthRegenEnabled and hum.Health > 0 and hum.Health < hum.MaxHealth then
        local rate = tonumber(cfg.HealthRegenRate) or 25
        if rate > 0 then
            hum.Health = math.min(hum.MaxHealth, hum.Health + rate * dt)
        end
    end

    if cfg.SpeedEnabled then
        if hum.WalkSpeed ~= cfg.SpeedValue then
            hum.WalkSpeed = cfg.SpeedValue
        end
    else
        if hum.WalkSpeed ~= OriginalWalkSpeed then hum.WalkSpeed = OriginalWalkSpeed end
    end

    if cfg.JumpEnabled then
        if hum.JumpPower ~= cfg.JumpPower then
            hum.JumpPower = cfg.JumpPower
        end
    else
        if hum.JumpPower ~= OriginalJumpPower then hum.JumpPower = OriginalJumpPower end
    end
end)

-- CharacterAdded
Player.CharacterAdded:Connect(function(char)
    resetAntiVoidState()
    task.wait(0.6)
    if getgenv().SystemConfig.InvisibleEnabled then
        InvisibleState.saved = {}
        setInvisibility(true)
    end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        OriginalWalkSpeed = hum.WalkSpeed
        OriginalJumpPower = hum.JumpPower
    end
    if NoClipAtivo then
        if NoClipConnection then NoClipConnection:Disconnect() end
        NoClipConnection = RunService.Stepped:Connect(function()
            local chr = Player.Character
            if chr then
                for _, part in ipairs(chr:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
    if getgenv().SystemConfig.FlyEnabled then startFly() end
end)

--// =============================================
--// APLICA O ESTADO SALVO AO INICIAR
--// =============================================
local function applyRuntimeState()
    local cfg = getgenv().SystemConfig

    FloatingBtn.Visible = cfg.MiraAtiva
    UpdateBtnVisual(cfg.MiraAtiva)

    fpsF.Visible = cfg.ShowFPS
    countF.Visible = cfg.ShowPlayers

    Lighting.GlobalShadows = not cfg.NoShadows

    if cfg.FlyEnabled then task.spawn(startFly) end
    if cfg.NoClipEnabled then startNoClip() end
    if cfg.InvisibleEnabled then setInvisibility(true) end

    animateBtn(TpFloatingBtn, cfg.TeleportEnabled)
end

--// =============================================
--// DESLIGAMENTO TOTAL (BOTÃO ×)
--// Fecha o menu, desativa todos os sistemas e restaura o jogo.
--// =============================================
FullShutdown = function()
    local cfg = getgenv().SystemConfig

    -- Fecha painéis abertos
    isTeleportOpen = false
    toggleMenu(false)
    for _, child in ipairs(NotifyContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Encerra sistemas ativos
    Actions.setMira(false)
    Actions.setFly(false)
    Actions.setNoClip(false)
    Actions.setSpeed(false)
    Actions.setTeleport(false)
    Actions.setInvisible(false)
    Actions.setInstinct(false)

    -- Desliga todas as flags de recurso
    local featureKeys = {
        "MiraAtiva",
        "HighlightEnabled", "DotEnabled", "LineEnabled",
        "LineOutline", "LinePulse",
        "MicroHpEnabled", "MicroDistEnabled",
        "EspBoxEnabled", "EspHealthEnabled", "FovCircleEnabled",
        "FullBright", "NoShadows", "ClarezaMod", "ClockOverrideEnabled",
        "ShowFPS", "ShowPlayers",
        "FlyEnabled", "FlyInfinite", "SpeedEnabled",
        "JumpEnabled", "InfiniteJump", "NoClipEnabled",
        "TeleportEnabled",
        "HealthRegenEnabled", "CooldownReduceEnabled",
        "InstinctV2Enabled", "InvisibleEnabled",
        "AntiAfkEnabled",
    }
    for _, key in ipairs(featureKeys) do
        cfg[key] = false
    end

    -- Limpa overlays imediatamente
    for _, tracer in pairs(Lines) do
        for _, seg in ipairs(tracer.segs) do seg.Visible = false end
        if tracer.outline then tracer.outline.Visible = false end
    end
    for _, box in pairs(Visuals.Boxes) do
        for _, drawing in pairs(box) do
            if drawing.Visible ~= nil then drawing.Visible = false end
        end
    end
    if Visuals.FovCircle then Visuals.FovCircle.Visible = false end
    fpsF.Visible = false
    countF.Visible = false

    -- Remove marcações dos personagens
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if char then
            local hl = char:FindFirstChild("System_HL")
            if hl then hl.Enabled = false end
            local head = char:FindFirstChild("Head")
            local dot = head and head:FindFirstChild("System_Dot")
            if dot then dot.Enabled = false end
            local root = char:FindFirstChild("HumanoidRootPart")
            local hud = root and root:FindFirstChild("Aguia_MicroHUD")
            if hud then hud.Enabled = false end
        end
    end

    -- Restaura iluminação original
    Lighting.Ambient = OriginalSettings.Ambient
    Lighting.OutdoorAmbient = OriginalSettings.OutdoorAmbient
    Lighting.Brightness = OriginalSettings.Brightness
    Lighting.ExposureCompensation = OriginalSettings.Exposure
    Lighting.ClockTime = OriginalSettings.ClockTime
    Lighting.GlobalShadows = OriginalSettings.GlobalShadows

    -- Restaura o personagem
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = OriginalWalkSpeed
        hum.JumpPower = OriginalJumpPower
        hum.PlatformStand = false
    end

    ActiveSlider = nil

    -- Sincroniza todos os toggles da interface
    for _, control in ipairs(ToggleControls) do
        pcall(function() control:Set(false) end)
    end

    -- Minimiza/oculta o menu
    Win.close()
end

applyRuntimeState()

WarcoreUI:Notify({
    Title = "👑 WARCORE v2.0.0",
    Content = ConfigCarregada
        and "Configurações restauradas! Interface própria carregada."
        or "Interface própria carregada. Configurações serão salvas automaticamente.",
    Duration = 5,
})
