-- Настройки ESP (можно менять вручную true/false)
local Flags = { 
    MurdererESP = true, 
    SheriffESP = true, 
    InnocentESP = true, 
    SelfESP = false, -- Подсвечивать ли себя
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local highlights = {}

-- Функция создания/обновления подсветки
local function createHighlight(player, color) 
    local char = player.Character 
    if not char then return end

    local existing = highlights[player]
    if existing and existing.Parent == char then
        -- Если подсветка уже есть на персонаже, просто обновляем цвет (защита от лагов)
        existing.FillColor = color
        existing.OutlineColor = color
        return
    elseif existing then
        existing:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5 -- Сделано чуть прозрачным, чтобы видеть персонажа
    highlight.OutlineTransparency = 0
    highlight.Parent = char
    highlights[player] = highlight
end

-- Удаление подсветки
local function removeHighlight(player) 
    if highlights[player] then 
        highlights[player]:Destroy() 
        highlights[player] = nil 
    end 
end

-- Проверка роли игрока (по оружию в руках или инвентаре)
local function getRole(player) 
    if not player.Character then return nil end

    local hasKnife = false
    local hasGun = false

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("knife") or name:find("murderer") then 
                    hasKnife = true 
                end
                if name:find("gun") or name:find("revolver") or name:find("sheriff") then 
                    hasGun = true 
                end
            end
        end
    end

    local charTool = player.Character:FindFirstChildOfClass("Tool")
    if charTool then
        local name = charTool.Name:lower()
        if name:find("knife") or name:find("murderer") then 
            hasKnife = true 
        end
        if name:find("gun") or name:find("revolver") or name:find("sheriff") then 
            hasGun = true 
        end
    end

    if hasKnife then return "Murderer" end
    if hasGun then return "Sheriff" end
    return "Innocent"
end

-- Основное обновление ESP
local function updateESP() 
    for _, player in ipairs(Players:GetPlayers()) do 
        if player == LocalPlayer and not Flags.SelfESP then 
            removeHighlight(player)
            continue 
        end

        local role = getRole(player)
        
        if Flags.MurdererESP and role == "Murderer" then
            createHighlight(player, Color3.fromRGB(255, 0, 0)) -- Красный для Убийцы
        elseif Flags.SheriffESP and role == "Sheriff" then
            createHighlight(player, Color3.fromRGB(0, 0, 255)) -- Синий для Шерифа
        elseif Flags.InnocentESP and role == "Innocent" then
            createHighlight(player, Color3.fromRGB(0, 255, 0)) -- Зеленый для Мирного
        else
            removeHighlight(player)
        end
    end
end

-- Постоянное обновление ролей (каждый кадр)
RunService.RenderStepped:Connect(updateESP)

-- Очистка при выходе игрока
Players.PlayerRemoving:Connect(function(player) 
    removeHighlight(player) 
end)

-- Отслеживание спавна персонажей (для новых и текущих игроков)
local function onCharacterAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3) -- Небольшая задержка, чтобы персонаж успел загрузиться
        updateESP()
    end)
end

for _, player in ipairs(Players:GetPlayers()) do 
    onCharacterAdded(player)
end

Players.PlayerAdded:Connect(onCharacterAdded)
