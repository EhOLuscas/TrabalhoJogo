local gameover = {}

local menu = require "estados.menu"
local save = require "sistemas.save"
require "constantes"

local fontTitle
local fontButton
local fontVolume
local draggingVolume = false

local botoes = {}

-- Panel dimensions (centered layout)
local panelW = 460
local panelH = 520

local function carregarRecursos()
    if not fontTitle then
        fontTitle = love.graphics.newFont(26)
        fontButton = love.graphics.newFont(18)
        fontVolume = love.graphics.newFont(14)
    end
    volumeJogo = math.floor(love.audio.getVolume() * 100 + 0.5)
end

-- Helper to draw a diamond
local function drawDiamond(x, y, w, h, mode)
    love.graphics.polygon(mode, x, y - h/2, x + w/2, y, x, y + h/2, x - w/2, y)
end

-- Helper to draw the ornate top border for "GAME OVER"
local function desenharOrnatoSuperior(x, y, w)
    love.graphics.setColor(0.75, 0.60, 0.38) -- Bronze/gold
    love.graphics.setLineWidth(1.5)
    
    local cx = x + w / 2
    
    -- Central small diamond
    drawDiamond(cx, y, 8, 8, "fill")
    
    -- Two tiny horizontal lines flanking center
    love.graphics.line(cx - 18, y, cx - 6, y)
    love.graphics.line(cx + 6, y, cx + 18, y)
    
    -- Small diamond dots next to flanking lines
    drawDiamond(cx - 22, y, 4, 4, "fill")
    drawDiamond(cx + 22, y, 4, 4, "fill")

    -- Left horizontal line to left arrowhead
    local leftEnd = cx - 110
    love.graphics.line(cx - 26, y, leftEnd + 15, y)
    
    -- Left arrowhead: <--
    love.graphics.line(leftEnd, y, leftEnd + 8, y - 4)
    love.graphics.line(leftEnd, y, leftEnd + 8, y + 4)
    love.graphics.line(leftEnd + 8, y - 4, leftEnd + 12, y)
    love.graphics.line(leftEnd + 8, y + 4, leftEnd + 12, y)
    drawDiamond(leftEnd + 16, y, 4, 4, "fill")

    -- Right horizontal line to right arrowhead
    local rightEnd = cx + 110
    love.graphics.line(cx + 26, y, rightEnd - 15, y)
    
    -- Right arrowhead: -->
    love.graphics.line(rightEnd, y, rightEnd - 8, y - 4)
    love.graphics.line(rightEnd, y, rightEnd - 8, y + 4)
    love.graphics.line(rightEnd - 8, y - 4, rightEnd - 12, y)
    love.graphics.line(rightEnd - 8, y + 4, rightEnd - 12, y)
    drawDiamond(rightEnd - 16, y, 4, 4, "fill")
end

-- Helper to draw the ornate bottom border for "GAME OVER"
local function desenharOrnatoInferior(x, y, w)
    love.graphics.setColor(0.75, 0.60, 0.38) -- Bronze/gold
    love.graphics.setLineWidth(1.5)
    
    local cx = x + w / 2
    
    -- Central Emblem: A diamond shape inside a square box/emblem
    love.graphics.rectangle("line", cx - 8, y - 8, 16, 16)
    drawDiamond(cx, y, 10, 10, "fill")
    
    -- Left line
    local leftEnd = cx - 90
    love.graphics.line(cx - 12, y, leftEnd + 15, y)
    love.graphics.line(leftEnd, y, leftEnd + 6, y - 3)
    love.graphics.line(leftEnd, y, leftEnd + 6, y + 3)
    drawDiamond(leftEnd + 10, y, 4, 4, "fill")
    
    -- Right line
    local rightEnd = cx + 90
    love.graphics.line(cx + 12, y, rightEnd - 15, y)
    love.graphics.line(rightEnd, y, rightEnd - 6, y - 3)
    love.graphics.line(rightEnd, y, rightEnd - 6, y + 3)
    drawDiamond(rightEnd - 10, y, 4, 4, "fill")
end

-- Helper to draw stylized buttons
local function desenharBotao(btn, iconType)
    local x, y, w, h = btn.x, btn.y, btn.w, btn.h
    local hover = btn.hover
    
    -- Colors matching dark bronze theme
    local colorBg = {0.18, 0.11, 0.07} -- Rich dark bronze-brown
    local colorBorderOuter = {0.10, 0.06, 0.04}
    local colorBorderInner = {0.48, 0.35, 0.20} -- Lighter bronze frame
    local colorCorner = {0.75, 0.60, 0.38} -- Bright metallic gold/bronze
    local colorText = {0.85, 0.70, 0.45} -- Gold text
    
    if hover then
        colorBg = {0.24, 0.16, 0.10} -- Brighter warm brown
        colorBorderInner = {0.65, 0.50, 0.30}
        colorCorner = {0.90, 0.75, 0.48}
        colorText = {0.98, 0.85, 0.60}
    end
    
    -- Draw button shadow
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x + 2, y + 3, w, h, 6)
    
    -- Draw button background
    love.graphics.setColor(colorBg)
    love.graphics.rectangle("fill", x, y, w, h, 6)
    
    -- Inner light accent (3D Bevel effect)
    if hover then
        love.graphics.setColor(0.85, 0.65, 0.35, 0.10)
        love.graphics.rectangle("fill", x + 3, y + 3, w - 6, h - 6, 4)
    end
    
    -- Outer border
    love.graphics.setColor(colorBorderOuter)
    love.graphics.setLineWidth(2.5)
    love.graphics.rectangle("line", x, y, w, h, 6)
    
    -- Inner border
    love.graphics.setColor(colorBorderInner)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", x + 3, y + 3, w - 6, h - 6, 4)
    
    -- Corner Brackets
    local cSize = 10
    local rOffset = 6
    
    love.graphics.setColor(colorCorner)
    love.graphics.setLineWidth(2)
    
    -- Top-Left corner bracket
    love.graphics.line(x + 2, y + cSize, x + 2, y + 2, x + cSize, y + 2)
    -- Top-Right corner bracket
    love.graphics.line(x + w - 2, y + cSize, x + w - 2, y + 2, x + w - cSize, y + 2)
    -- Bottom-Left corner bracket
    love.graphics.line(x + 2, y + h - cSize, x + 2, y + h - 2, x + cSize, y + h - 2)
    -- Bottom-Right corner bracket
    love.graphics.line(x + w - 2, y + h - cSize, x + w - 2, y + h - 2, x + w - cSize, y + h - 2)
    
    -- Corner rivets (dark dot inside gold circle)
    love.graphics.setColor(colorBorderOuter)
    love.graphics.circle("fill", x + rOffset, y + rOffset, 2.5)
    love.graphics.circle("fill", x + w - rOffset, y + rOffset, 2.5)
    love.graphics.circle("fill", x + rOffset, y + h - rOffset, 2.5)
    love.graphics.circle("fill", x + w - rOffset, y + h - rOffset, 2.5)
    
    love.graphics.setColor(colorCorner)
    love.graphics.circle("fill", x + rOffset, y + rOffset, 1.5)
    love.graphics.circle("fill", x + w - rOffset, y + rOffset, 1.5)
    love.graphics.circle("fill", x + rOffset, y + h - rOffset, 1.5)
    love.graphics.circle("fill", x + w - rOffset, y + h - rOffset, 1.5)
    
    -- Draw Icon on the left side
    local iconX = x + 32
    local iconY = y + h / 2
    
    if iconType == "heart" then
        -- Red heart icon
        local hr, hg, hb = 0.85, 0.20, 0.20
        if hover then
            hr, hg, hb = 0.98, 0.35, 0.35
        end
        love.graphics.setColor(hr, hg, hb)
        love.graphics.circle("fill", iconX - 4, iconY - 3, 5)
        love.graphics.circle("fill", iconX + 4, iconY - 3, 5)
        love.graphics.polygon("fill", 
            iconX - 9, iconY - 1, 
            iconX + 9, iconY - 1, 
            iconX, iconY + 8
        )
    elseif iconType == "star" then
        -- Violet/indigo glow behind the star
        love.graphics.setColor(0.65, 0.45, 0.85, 0.35)
        love.graphics.circle("fill", iconX, iconY, 11)
        
        -- Outer diamond border
        love.graphics.setColor(0.75, 0.60, 0.90)
        love.graphics.setLineWidth(1.5)
        drawDiamond(iconX, iconY, 14, 14, "line")
        
        -- 4-pointed star spikes
        love.graphics.line(iconX - 10, iconY, iconX + 10, iconY)
        love.graphics.line(iconX, iconY - 10, iconX, iconY + 10)
        
        -- Inner star core
        love.graphics.circle("fill", iconX, iconY, 2.5)
    elseif iconType == "exit" then
        -- Exit Door Icon (SAIR DO JOGO)
        love.graphics.setColor(colorCorner)
        love.graphics.setLineWidth(2)
        
        -- Door Frame (open)
        love.graphics.line(iconX - 6, iconY + 8, iconX - 6, iconY - 8)
        love.graphics.line(iconX - 6, iconY - 8, iconX + 4, iconY - 8)
        love.graphics.line(iconX - 6, iconY + 8, iconX + 4, iconY + 8)
        
        -- Door panel swung open
        love.graphics.line(iconX + 4, iconY - 8, iconX + 8, iconY - 4)
        love.graphics.line(iconX + 4, iconY + 8, iconX + 8, iconY + 4)
        love.graphics.line(iconX + 8, iconY - 4, iconX + 8, iconY + 4)
        
        -- Arrow pointing outwards
        love.graphics.line(iconX - 10, iconY, iconX + 4, iconY)
        love.graphics.line(iconX + 4, iconY, iconX, iconY - 4)
        love.graphics.line(iconX + 4, iconY, iconX, iconY + 4)
    end
    
    -- Draw Button Text (shifted to the right of the icon)
    love.graphics.setFont(fontButton)
    
    -- Subtly shifted dark text shadow
    love.graphics.setColor(0.12, 0.08, 0.04, 0.95)
    love.graphics.printf(btn.label, x + 35, y + (h - fontButton:getHeight()) / 2 + 1, w - 45, "center")
    
    love.graphics.setColor(colorText)
    love.graphics.printf(btn.label, x + 35, y + (h - fontButton:getHeight()) / 2, w - 45, "center")
end

local function voltarSave()
    love.mouse.setVisible(true)
    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    local jogo = require "estados.jogo"
    estadoAtual = jogo
    if jogo.load then jogo.load() end
end

local function irMenu()
    local som = require "sistemas.som"
    som.parar("polvoParado")
    som.parar("ratoParado")
    estadoAtual = menu
    if estadoAtual.load then
        estadoAtual.load()
    end
end

local function tentarNovamente()
    local jogo = require "estados.jogo"
    jogo.load()
    estadoAtual = jogo
end

function gameover.update(dt)
    carregarRecursos()
    love.mouse.setVisible(true)

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    local btnW = 340
    local btnH = 54
    local btnX = panelX + (panelW - btnW) / 2

    botoes = {}
    local currentY = panelY + 130
    local spacing = 70

    table.insert(botoes, {
        label = "TENTAR NOVAMENTE",
        x = btnX,
        y = currentY,
        w = btnW,
        h = btnH,
        hover = false,
        icon = "heart",
        acao = voltarSave
    })
    currentY = currentY + spacing

    table.insert(botoes, {
        label = "VOLTAR AO MENU INICIAL",
        x = btnX,
        y = currentY,
        w = btnW,
        h = btnH,
        hover = false,
        icon = "star",
        acao = irMenu
    })
    currentY = currentY + spacing

    table.insert(botoes, {
        label = "SAIR DO JOGO",
        x = btnX,
        y = currentY,
        w = btnW,
        h = btnH,
        hover = false,
        icon = "exit",
        acao = function()
            love.event.quit()
        end
    })

    local mx, my = love.mouse.getPosition()
    local sobreBotao = false

    -- Update button hovers
    for _, btn in ipairs(botoes) do
        btn.hover = mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h
        if btn.hover then
            sobreBotao = true
        end
    end

    -- Volume Slider coordinates
    local sliderX = panelX + 70
    local sliderW = 320
    local sliderY = panelY + 410

    -- Check hover on slider handle
    local volumeFrac = volumeJogo / 100
    local handleX = sliderX + volumeFrac * sliderW
    local distHandle = math.sqrt((mx - handleX)^2 + (my - sliderY - 4)^2)

    if sobreBotao or distHandle < 14 then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end

    -- Handle Dragging
    if draggingVolume then
        if love.mouse.isDown(1) then
            local val = (mx - sliderX) / sliderW
            val = math.max(0, math.min(1, val))
            love.audio.setVolume(val)
            volumeJogo = math.floor(val * 100 + 0.5)
        else
            draggingVolume = false
        end
    end
end

function gameover.draw()
    carregarRecursos()

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    local oldFont = love.graphics.getFont()

    -- 1. Dark red/crimson tinted overlay on screen
    love.graphics.setColor(0.12, 0.02, 0.02, 0.72)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- 2. Title "GAME OVER" and Ornaments
    desenharOrnatoSuperior(panelX, panelY + 22, panelW)

    love.graphics.setFont(fontTitle)
    -- Shadow
    love.graphics.setColor(0.06, 0.01, 0.01, 0.95)
    love.graphics.printf("GAME OVER", panelX + 2, panelY + 36, panelW, "center")
    -- Main red text
    love.graphics.setColor(0.90, 0.15, 0.15, 1.0)
    love.graphics.printf("GAME OVER", panelX, panelY + 34, panelW, "center")

    desenharOrnatoInferior(panelX, panelY + 80, panelW)

    -- 3. Draw Buttons
    for _, btn in ipairs(botoes) do
        desenharBotao(btn, btn.icon)
    end

    -- 4. Volume Slider
    local sliderX = panelX + 70
    local sliderW = 320
    local sliderY = panelY + 410
    local sliderH = 8
    local ly = sliderY + sliderH / 2

    -- Volume Label
    love.graphics.setFont(fontVolume)
    -- Text shadow
    love.graphics.setColor(0.12, 0.08, 0.04, 0.9)
    love.graphics.printf("SINTONIA DE VOLUME: " .. volumeJogo .. "%", panelX + 1, panelY + 373, panelW, "center")
    -- Text gold color
    love.graphics.setColor(0.85, 0.70, 0.45, 1.0)
    love.graphics.printf("SINTONIA DE VOLUME: " .. volumeJogo .. "%", panelX, panelY + 372, panelW, "center")

    -- Slider empty track background (Deep forest green/black)
    love.graphics.setColor(0.08, 0.12, 0.10, 0.9)
    love.graphics.rectangle("fill", sliderX, sliderY, sliderW, sliderH, 4)
    love.graphics.setColor(0.20, 0.32, 0.25, 0.7)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", sliderX, sliderY, sliderW, sliderH, 4)

    -- Slider filled track progress (Vibrant green/teal)
    local volumeFrac = volumeJogo / 100
    if volumeFrac > 0 then
        love.graphics.setColor(0.30, 0.52, 0.40, 1.0)
        love.graphics.rectangle("fill", sliderX, sliderY, sliderW * volumeFrac, sliderH, 4)
    end

    -- Slider left decorative flourish (gold/bronze swirl)
    love.graphics.setColor(0.75, 0.60, 0.38)
    love.graphics.setLineWidth(2)
    -- Lower scroll
    love.graphics.line(sliderX - 2, ly, sliderX - 10, ly, sliderX - 16, ly + 4, sliderX - 18, ly + 10, sliderX - 14, ly + 14, sliderX - 8, ly + 12, sliderX - 8, ly + 8)
    -- Upper small curl
    love.graphics.line(sliderX - 10, ly, sliderX - 14, ly - 4, sliderX - 12, ly - 8, sliderX - 8, ly - 6)

    -- Slider right decorative cap (green/teal diamond with gold border)
    local rightCapX = sliderX + sliderW + 8
    -- Outer Gold Diamond Border
    love.graphics.setColor(0.75, 0.60, 0.38)
    drawDiamond(rightCapX, ly, 16, 16, "line")
    -- Inner Teal Fill
    love.graphics.setColor(0.30, 0.52, 0.40)
    drawDiamond(rightCapX, ly, 12, 12, "fill")
    -- Center Mint Point
    love.graphics.setColor(0.60, 0.85, 0.70)
    drawDiamond(rightCapX, ly, 4, 4, "fill")

    -- Slider Handle (diamond knob)
    local handleX = sliderX + volumeFrac * sliderW
    
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.55)
    drawDiamond(handleX, ly + 1, 20, 20, "fill")
    
    -- Knob Outer Gold Border
    love.graphics.setColor(0.75, 0.60, 0.38)
    drawDiamond(handleX, ly, 18, 18, "fill")
    
    -- Knob Teal fill
    love.graphics.setColor(0.35, 0.60, 0.46)
    drawDiamond(handleX, ly, 14, 14, "fill")
    
    -- Knob Center Mint shine
    love.graphics.setColor(0.75, 0.95, 0.85)
    drawDiamond(handleX, ly, 6, 6, "fill")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(oldFont)
end

local function checkSliderPressed(mx, my, screenW, screenH)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2
    local sliderX = panelX + 70
    local sliderW = 320
    local sliderY = panelY + 410

    return mx >= sliderX - 12 and mx <= sliderX + sliderW + 12 and my >= sliderY - 18 and my <= sliderY + 18
end

function gameover.mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(botoes) do
            if btn.hover then
                btn.acao()
                return
            end
        end

        local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
        if checkSliderPressed(x, y, screenW, screenH) then
            draggingVolume = true
            local panelX = (screenW - panelW) / 2
            local sliderX = panelX + 70
            local sliderW = 320
            local val = (x - sliderX) / sliderW
            val = math.max(0, math.min(1, val))
            love.audio.setVolume(val)
            volumeJogo = math.floor(val * 100 + 0.5)
        end
    end
end

function gameover.keypressed(key)
    if key == "return" then
        tentarNovamente()
    elseif key == "escape" then
        irMenu()
    elseif key == "r" and save.existe() then
        voltarSave()
    end
end

return gameover