local configuracoes = {}

require "constantes"

local fontTitle
local fontButton
local fontVolume
local imagemFundo
local draggingSlider = nil

local botaoVoltar = {
    label = "VOLTAR AO MENU",
    x = 0,
    y = 0,
    w = 340,
    h = 54,
    hover = false,
    acao = function()
        estadoAtual = require "estados.menu"
        if estadoAtual.load then
            estadoAtual.load()
        end
    end
}

-- Panel dimensions (centered layout)
local panelW = 460
local panelH = 520

local function carregarRecursos()
    if not fontTitle then
        fontTitle = love.graphics.newFont(26)
        fontButton = love.graphics.newFont(18)
        fontVolume = love.graphics.newFont(14)
    end
    if not imagemFundo then
        imagemFundo = love.graphics.newImage("sprites/imagem-menu.png")
    end
end

-- Helper to draw a diamond
local function drawDiamond(x, y, w, h, mode)
    love.graphics.polygon(mode, x, y - h/2, x + w/2, y, x, y + h/2, x - w/2, y)
end

-- Helper to draw the ornate top border for "CONFIGURAÇÕES"
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
    local leftEnd = cx - 140
    love.graphics.line(cx - 26, y, leftEnd + 15, y)
    
    -- Left arrowhead: <--
    love.graphics.line(leftEnd, y, leftEnd + 8, y - 4)
    love.graphics.line(leftEnd, y, leftEnd + 8, y + 4)
    love.graphics.line(leftEnd + 8, y - 4, leftEnd + 12, y)
    love.graphics.line(leftEnd + 8, y + 4, leftEnd + 12, y)
    drawDiamond(leftEnd + 16, y, 4, 4, "fill")

    -- Right horizontal line to right arrowhead
    local rightEnd = cx + 140
    love.graphics.line(cx + 26, y, rightEnd - 15, y)
    
    -- Right arrowhead: -->
    love.graphics.line(rightEnd, y, rightEnd - 8, y - 4)
    love.graphics.line(rightEnd, y, rightEnd - 8, y + 4)
    love.graphics.line(rightEnd - 8, y - 4, rightEnd - 12, y)
    love.graphics.line(rightEnd - 8, y + 4, rightEnd - 12, y)
    drawDiamond(rightEnd - 16, y, 4, 4, "fill")
end

-- Helper to draw the ornate bottom border for "CONFIGURAÇÕES"
local function desenharOrnatoInferior(x, y, w)
    love.graphics.setColor(0.75, 0.60, 0.38) -- Bronze/gold
    love.graphics.setLineWidth(1.5)
    
    local cx = x + w / 2
    
    -- Central Emblem: A diamond shape inside a square box/emblem
    love.graphics.rectangle("line", cx - 8, y - 8, 16, 16)
    drawDiamond(cx, y, 10, 10, "fill")
    
    -- Left line
    local leftEnd = cx - 110
    love.graphics.line(cx - 12, y, leftEnd + 15, y)
    love.graphics.line(leftEnd, y, leftEnd + 6, y - 3)
    love.graphics.line(leftEnd, y, leftEnd + 6, y + 3)
    drawDiamond(leftEnd + 10, y, 4, 4, "fill")
    
    -- Right line
    local rightEnd = cx + 110
    love.graphics.line(cx + 12, y, rightEnd - 15, y)
    love.graphics.line(rightEnd, y, rightEnd - 6, y - 3)
    love.graphics.line(rightEnd, y, rightEnd - 6, y + 3)
    drawDiamond(rightEnd - 10, y, 4, 4, "fill")
end

-- Helper to draw stylized buttons
local function desenharBotao(btn, iconType)
    local x, y, w, h = btn.x, btn.y, btn.w, btn.h
    local hover = btn.hover
    
    -- Colors matching dark bronze theme from reference
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
    
    if iconType == "back" then
        love.graphics.setColor(colorCorner)
        love.graphics.setLineWidth(2)
        -- Left arrow
        love.graphics.line(iconX + 8, iconY, iconX - 8, iconY)
        love.graphics.line(iconX - 8, iconY, iconX - 2, iconY - 6)
        love.graphics.line(iconX - 8, iconY, iconX - 2, iconY + 6)
    end
    
    -- Draw Button Text (shifted to the right of the icon)
    love.graphics.setFont(fontButton)
    
    -- Subtly shifted dark text shadow
    love.graphics.setColor(0.12, 0.08, 0.04, 0.95)
    love.graphics.printf(btn.label, x + 35, y + (h - fontButton:getHeight()) / 2 + 1, w - 45, "center")
    
    love.graphics.setColor(colorText)
    love.graphics.printf(btn.label, x + 35, y + (h - fontButton:getHeight()) / 2, w - 45, "center")
end

-- Helper to draw a stylized slider
local function desenharSlider(label, valor, sliderX, sliderY, sliderW, sliderH)
    local ly = sliderY + sliderH / 2
    local percent = math.floor(valor + 0.5)

    -- Slider Label
    love.graphics.setFont(fontVolume)
    -- Text shadow
    love.graphics.setColor(0.12, 0.08, 0.04, 0.9)
    love.graphics.printf(label .. ": " .. percent .. "%", sliderX - 70, sliderY - 26, sliderW + 140, "center")
    -- Text gold color
    love.graphics.setColor(0.85, 0.70, 0.45, 1.0)
    love.graphics.printf(label .. ": " .. percent .. "%", sliderX - 70, sliderY - 27, sliderW + 140, "center")

    -- Slider empty track background (Deep forest green/black)
    love.graphics.setColor(0.08, 0.12, 0.10, 0.9)
    love.graphics.rectangle("fill", sliderX, sliderY, sliderW, sliderH, 4)
    love.graphics.setColor(0.20, 0.32, 0.25, 0.7)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", sliderX, sliderY, sliderW, sliderH, 4)

    -- Slider filled track progress (Vibrant green/teal)
    local valorFrac = valor / 100
    if valorFrac > 0 then
        love.graphics.setColor(0.30, 0.52, 0.40, 1.0)
        love.graphics.rectangle("fill", sliderX, sliderY, sliderW * valorFrac, sliderH, 4)
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
    local handleX = sliderX + valorFrac * sliderW
    
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
end

local function atualizarVolumeOuBrilho(mx, sliderX, sliderW)
    local val = (mx - sliderX) / sliderW
    val = math.max(0, math.min(1, val))
    local percent = math.floor(val * 100 + 0.5)

    if draggingSlider == "brilho" then
        brilhoGlobal = percent
    elseif draggingSlider == "volumeJogo" then
        volumeJogo = percent
        love.audio.setVolume(val)
    elseif draggingSlider == "volumeMusica" then
        volumeMusica = percent
    end
end

function configuracoes.update(dt)
    carregarRecursos()
    love.mouse.setVisible(true)

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    botaoVoltar.x = panelX + (panelW - botaoVoltar.w) / 2
    botaoVoltar.y = panelY + 420

    local mx, my = love.mouse.getPosition()
    local sobreInterface = false

    -- Check hover on Voltar button
    botaoVoltar.hover = mx >= botaoVoltar.x and mx <= botaoVoltar.x + botaoVoltar.w and my >= botaoVoltar.y and my <= botaoVoltar.y + botaoVoltar.h
    if botaoVoltar.hover then
        sobreInterface = true
    end

    -- Check hover on slider handles
    local sliderW = 320
    local sliderX = panelX + 70

    local handleBrilhoX = sliderX + (brilhoGlobal / 100) * sliderW
    local handleVolJogoX = sliderX + (volumeJogo / 100) * sliderW
    local handleVolMusicaX = sliderX + (volumeMusica / 100) * sliderW

    local distBrilho = math.sqrt((mx - handleBrilhoX)^2 + (my - (panelY + 160 + 4))^2)
    local distVolJogo = math.sqrt((mx - handleVolJogoX)^2 + (my - (panelY + 250 + 4))^2)
    local distVolMusica = math.sqrt((mx - handleVolMusicaX)^2 + (my - (panelY + 340 + 4))^2)

    if sobreInterface or distBrilho < 14 or distVolJogo < 14 or distVolMusica < 14 then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end

    -- Handle Dragging
    if draggingSlider then
        if love.mouse.isDown(1) then
            atualizarVolumeOuBrilho(mx, sliderX, sliderW)
        else
            draggingSlider = nil
        end
    end
end

function configuracoes.draw()
    carregarRecursos()

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    local oldFont = love.graphics.getFont()

    -- 1. Draw Menu Background Image
    love.graphics.setColor(1, 1, 1)
    if imagemFundo then
        local scaleX = screenW / 1679
        local scaleY = screenH / 937
        love.graphics.draw(imagemFundo, 0, 0, 0, scaleX, scaleY)
    end

    -- 2. Dark overlay on screen (dimmed view)
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- 3. Title "CONFIGURAÇÕES" and Ornaments
    desenharOrnatoSuperior(panelX, panelY + 22, panelW)

    love.graphics.setFont(fontTitle)
    -- Shadow
    love.graphics.setColor(0.12, 0.08, 0.04, 0.95)
    love.graphics.printf("CONFIGURAÇÕES", panelX + 2, panelY + 36, panelW, "center")
    -- Main gold text
    love.graphics.setColor(0.85, 0.70, 0.45, 1.0)
    love.graphics.printf("CONFIGURAÇÕES", panelX, panelY + 34, panelW, "center")

    desenharOrnatoInferior(panelX, panelY + 80, panelW)

    -- 4. Draw Sliders
    local sliderW = 320
    local sliderX = panelX + 70

    -- Brilho (Brightness)
    desenharSlider("BRILHO", brilhoGlobal, sliderX, panelY + 160, sliderW, 8)

    -- Volume do Jogo (Game Volume)
    desenharSlider("VOLUME DO JOGO", volumeJogo, sliderX, panelY + 250, sliderW, 8)

    -- Volume da Música (Music Volume)
    desenharSlider("VOLUME DA MÚSICA", volumeMusica, sliderX, panelY + 340, sliderW, 8)

    -- 5. Draw Button "VOLTAR AO MENU"
    desenharBotao(botaoVoltar, "back")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(oldFont)
end

local function checkSliderPressed(mx, my, sliderX, sliderY, sliderW)
    return mx >= sliderX - 12 and mx <= sliderX + sliderW + 12 and my >= sliderY - 18 and my <= sliderY + 18
end

function configuracoes.mousepressed(x, y, button)
    if button == 1 then
        if botaoVoltar.hover then
            botaoVoltar.acao()
            return
        end

        local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
        local panelX = (screenW - panelW) / 2
        local panelY = (screenH - panelH) / 2
        local sliderX = panelX + 70
        local sliderW = 320

        -- Check Brilho slider
        if checkSliderPressed(x, y, sliderX, panelY + 160, sliderW) then
            draggingSlider = "brilho"
            atualizarVolumeOuBrilho(x, sliderX, sliderW)
        -- Check Game Volume slider
        elseif checkSliderPressed(x, y, sliderX, panelY + 250, sliderW) then
            draggingSlider = "volumeJogo"
            atualizarVolumeOuBrilho(x, sliderX, sliderW)
        -- Check Music Volume slider
        elseif checkSliderPressed(x, y, sliderX, panelY + 340, sliderW) then
            draggingSlider = "volumeMusica"
            atualizarVolumeOuBrilho(x, sliderX, sliderW)
        end
    end
end

function configuracoes.keypressed(key)
    if key == "escape" then
        estadoAtual = require "estados.menu"
        if estadoAtual.load then
            estadoAtual.load()
        end
    end
end

return configuracoes