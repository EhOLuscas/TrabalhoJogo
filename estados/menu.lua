require "constantes"

local menu = {}

local imagemFundo
local botoes = {}
local devs = {}

-- Fontes locais
local fontTitle
local fontButton
local fontVolume

-- Estados e controles
menu.mostrarPainelDevs = false
local hoverI = false
local botaoFecharHover = false

-- Dimensões do painel de desenvolvedores
local panelW = 820
local panelH = 510

local function carregarRecursos()
    if not fontTitle then
        fontTitle = love.graphics.newFont(26)
        fontButton = love.graphics.newFont(18)
        fontVolume = love.graphics.newFont(14)
    end
end

-- Auxiliar para desenhar diamante
local function drawDiamond(x, y, w, h, mode)
    love.graphics.polygon(mode, x, y - h/2, x + w/2, y, x, y + h/2, x - w/2, y)
end

-- Auxiliar para desenhar ornato superior
local function desenharOrnatoSuperior(x, y, w)
    love.graphics.setColor(0.75, 0.60, 0.38) -- Bronze/gold
    love.graphics.setLineWidth(1.5)
    
    local cx = x + w / 2
    
    drawDiamond(cx, y, 8, 8, "fill")
    love.graphics.line(cx - 18, y, cx - 6, y)
    love.graphics.line(cx + 6, y, cx + 18, y)
    drawDiamond(cx - 22, y, 4, 4, "fill")
    drawDiamond(cx + 22, y, 4, 4, "fill")

    local leftEnd = cx - 110
    love.graphics.line(cx - 26, y, leftEnd + 15, y)
    love.graphics.line(leftEnd, y, leftEnd + 8, y - 4)
    love.graphics.line(leftEnd, y, leftEnd + 8, y + 4)
    love.graphics.line(leftEnd + 8, y - 4, leftEnd + 12, y)
    love.graphics.line(leftEnd + 8, y + 4, leftEnd + 12, y)
    drawDiamond(leftEnd + 16, y, 4, 4, "fill")

    local rightEnd = cx + 110
    love.graphics.line(cx + 26, y, rightEnd - 15, y)
    love.graphics.line(rightEnd, y, rightEnd - 8, y - 4)
    love.graphics.line(rightEnd, y, rightEnd - 8, y + 4)
    love.graphics.line(rightEnd - 8, y - 4, rightEnd - 12, y)
    love.graphics.line(rightEnd - 8, y + 4, rightEnd - 12, y)
    drawDiamond(rightEnd - 16, y, 4, 4, "fill")
end

-- Auxiliar para desenhar ornato inferior
local function desenharOrnatoInferior(x, y, w)
    love.graphics.setColor(0.75, 0.60, 0.38) -- Bronze/gold
    love.graphics.setLineWidth(1.5)
    
    local cx = x + w / 2
    
    love.graphics.rectangle("line", cx - 8, y - 8, 16, 16)
    drawDiamond(cx, y, 10, 10, "fill")
    
    local leftEnd = cx - 90
    love.graphics.line(cx - 12, y, leftEnd + 15, y)
    love.graphics.line(leftEnd, y, leftEnd + 6, y - 3)
    love.graphics.line(leftEnd, y, leftEnd + 6, y + 3)
    drawDiamond(leftEnd + 10, y, 4, 4, "fill")
    
    local rightEnd = cx + 90
    love.graphics.line(cx + 12, y, rightEnd - 15, y)
    love.graphics.line(rightEnd, y, rightEnd - 6, y - 3)
    love.graphics.line(rightEnd, y, rightEnd - 6, y + 3)
    drawDiamond(rightEnd - 10, y, 4, 4, "fill")
end

-- Auxiliar para desenhar o painel dos desenvolvedores
local function desenharPainelDevs(panelX, panelY, mx, my)
    -- Borda externa e fundo do painel (Estilo RPG)
    love.graphics.setColor(0.12, 0.08, 0.06, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8)
    love.graphics.setColor(0.75, 0.60, 0.38)
    love.graphics.setLineWidth(2.5)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8)

    -- Ornatos e Título
    desenharOrnatoSuperior(panelX, panelY + 22, panelW)
    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0.12, 0.08, 0.04, 0.95)
    love.graphics.printf("DESENVOLVEDORES", panelX + 2, panelY + 36, panelW, "center")
    love.graphics.setColor(0.85, 0.70, 0.45)
    love.graphics.printf("DESENVOLVEDORES", panelX, panelY + 34, panelW, "center")
    desenharOrnatoInferior(panelX, panelY + 80, panelW)

    -- Desenha os 5 cards de desenvolvedores
    for i, dev in ipairs(devs) do
        local cardX = panelX + 30 + (i - 1) * 154
        local cardY = panelY + 115
        local cardW = 136
        local cardH = 275

        -- Fundo e bordas do card
        love.graphics.setColor(0.18, 0.11, 0.07, 0.9)
        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 6)
        love.graphics.setColor(0.48, 0.35, 0.20)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 6)

        -- Foto
        local fotoX = cardX + 13
        local fotoY = cardY + 15
        local fotoSize = 110

        if dev.img then
            love.graphics.setColor(1, 1, 1)
            local iw = dev.img:getWidth()
            local ih = dev.img:getHeight()
            local esc = fotoSize / math.max(iw, ih)
            local dx = (fotoSize - iw * esc) / 2
            local dy = (fotoSize - ih * esc) / 2
            love.graphics.draw(dev.img, fotoX + dx, fotoY + dy, 0, esc, esc)
        else
            -- Placeholder rústico caso a imagem não exista
            love.graphics.setColor(0.08, 0.06, 0.05)
            love.graphics.rectangle("fill", fotoX, fotoY, fotoSize, fotoSize, 4)
            love.graphics.setColor(0.3, 0.22, 0.15)
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", fotoX, fotoY, fotoSize, fotoSize, 4)
            
            -- Silhueta de usuário desenhada
            love.graphics.setColor(0.45, 0.35, 0.25)
            love.graphics.circle("fill", fotoX + 55, fotoY + 45, 18)
            love.graphics.arc("fill", "open", fotoX + 55, fotoY + 85, 28, math.pi, 2 * math.pi)
            
            -- Ponto de interrogação no canto
            love.graphics.setFont(fontButton)
            love.graphics.setColor(0.85, 0.70, 0.45, 0.45)
            love.graphics.printf("?", fotoX, fotoY + 10, fotoSize, "center")
        end

        -- Nome do Desenvolvedor
        love.graphics.setFont(fontVolume)
        love.graphics.setColor(0.12, 0.08, 0.04, 0.95)
        love.graphics.printf(dev.nome, cardX + 6, cardY + 136, 124, "center")
        love.graphics.setColor(0.85, 0.70, 0.45)
        love.graphics.printf(dev.nome, cardX + 5, cardY + 135, 126, "center")

        -- Botão do LinkedIn
        local btnLknX = cardX + 13
        local btnLknY = cardY + 185
        local btnW = 110
        local btnH = 32

        local hoverLkn = dev.hoverLinkedIn
        local colorLknBg = hoverLkn and {0.05, 0.25, 0.45} or {0.02, 0.15, 0.30}
        local colorLknText = hoverLkn and {0.95, 0.98, 1.0} or {0.70, 0.85, 1.0}

        love.graphics.setColor(colorLknBg)
        love.graphics.rectangle("fill", btnLknX, btnLknY, btnW, btnH, 4)
        love.graphics.setColor(0.1, 0.35, 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", btnLknX, btnLknY, btnW, btnH, 4)

        love.graphics.setFont(fontVolume)
        love.graphics.setColor(colorLknText)
        love.graphics.printf("LINKEDIN", btnLknX, btnLknY + (btnH - fontVolume:getHeight()) / 2, btnW, "center")

        -- Botão do GitHub
        local btnGhX = cardX + 13
        local btnGhY = cardY + 225

        local hoverGh = dev.hoverGitHub
        local colorGhBg = hoverGh and {0.18, 0.18, 0.20} or {0.10, 0.10, 0.12}
        local colorGhText = hoverGh and {0.95, 0.95, 0.95} or {0.70, 0.70, 0.72}

        love.graphics.setColor(colorGhBg)
        love.graphics.rectangle("fill", btnGhX, btnGhY, btnW, btnH, 4)
        love.graphics.setColor(0.3, 0.3, 0.32)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", btnGhX, btnGhY, btnW, btnH, 4)

        love.graphics.setFont(fontVolume)
        love.graphics.setColor(colorGhText)
        love.graphics.printf("GITHUB", btnGhX, btnGhY + (btnH - fontVolume:getHeight()) / 2, btnW, "center")
    end

    -- Botão Fechar
    local closeX = panelX + (panelW - 180) / 2
    local closeY = panelY + 435
    local closeW = 180
    local closeH = 42

    local hoverClose = botaoFecharHover
    local colorCloseBg = hoverClose and {0.24, 0.16, 0.10} or {0.18, 0.11, 0.07}
    local colorCloseBorder = hoverClose and {0.65, 0.50, 0.30} or {0.48, 0.35, 0.20}
    local colorCloseText = hoverClose and {0.98, 0.85, 0.60} or {0.85, 0.70, 0.45}

    love.graphics.setColor(colorCloseBg)
    love.graphics.rectangle("fill", closeX, closeY, closeW, closeH, 6)
    love.graphics.setColor(colorCloseBorder)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", closeX, closeY, closeW, closeH, 6)

    love.graphics.setFont(fontButton)
    love.graphics.setColor(0.12, 0.08, 0.04, 0.95)
    love.graphics.printf("FECHAR", closeX + 1, closeY + (closeH - fontButton:getHeight()) / 2 + 1, closeW, "center")
    love.graphics.setColor(colorCloseText)
    love.graphics.printf("FECHAR", closeX, closeY + (closeH - fontButton:getHeight()) / 2, closeW, "center")
end

function menu.load()
    love.mouse.setVisible(true)
    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    imagemFundo = LG.newImage("sprites/imagem-menu.png")
    carregarRecursos()

    local musica = require "sistemas.musica"
    musica.tocar("musica1")

    -- Coordenadas originais dos botões principais
    botoes = {
        {
            label = "INICIAR JOGO",
            rx = 85,
            ry = 485,
            rw = 460,
            rh = 110,
            x = 0, y = 0, w = 0, h = 0,
            hover = false,
            acao = function()
                local musica = require "sistemas.musica"
                musica.parar()
                estadoAtual = require "estados.cutscene"
                if estadoAtual.load then
                    estadoAtual.load()
                end
            end
        },
        {
            label = "CONFIGURAÇÕES",
            rx = 85,
            ry = 670,
            rw = 460,
            rh = 110,
            x = 0, y = 0, w = 0, h = 0,
            hover = false,
            acao = function()
                estadoAtual = require "estados.configuracoes"
                if estadoAtual.load then
                    estadoAtual.load()
                end
            end
        }
    }

    -- Definição dos desenvolvedores
    devs = {
        {
            nome = "Lucas Passos",
            linkedin = "https://www.linkedin.com/in/lucas-passos-355500312/",
            github = "https://github.com/EhOLuscas",
            fotoPath = "sprites/devs/Foto1.jpg",
            img = nil,
            hoverLinkedIn = false,
            hoverGitHub = false
        },
        {
            nome = "Nicollas Trevisan",
            linkedin = "https://www.linkedin.com/in/nicollas-trevisan-164574378/",
            github = "https://github.com/idkNicollas1",
            fotoPath = "sprites/devs/Foto2.jpg",
            img = nil,
            hoverLinkedIn = false,
            hoverGitHub = false
        },
        {
            nome = "Otávio Vicente",
            linkedin = "https://www.linkedin.com/in/otaviovicenterodrigues/",
            github = "https://github.com/OtavioVicente",
            fotoPath = "sprites/devs/Foto3.jpg",
            img = nil,
            hoverLinkedIn = false,
            hoverGitHub = false
        },
        {
            nome = "Pedro Mënin",
            linkedin = "https://www.linkedin.com/in/pedro-afonso-menin-328030356/",
            github = "https://github.com/mvster1",
            fotoPath = "sprites/devs/Foto4.jpg",
            img = nil,
            hoverLinkedIn = false,
            hoverGitHub = false
        },
        {
            nome = "Pedro Mancini",
            linkedin = "https://www.linkedin.com/in/pedromancini19/",
            github = "https://github.com/pedromancini",
            fotoPath = "sprites/devs/Foto5.jpg",
            img = nil,
            hoverLinkedIn = false,
            hoverGitHub = false
        }
    }

    -- Carrega as fotos existentes
    for _, dev in ipairs(devs) do
        local success, res = pcall(love.graphics.newImage, dev.fotoPath)
        if success then
            dev.img = res
        end
    end
end

function menu.update(dt)
    love.mouse.setVisible(false)
    carregarRecursos()
    
    local screenW = LG.getWidth()
    local screenH = LG.getHeight()
    local scaleX = screenW / 1679
    local scaleY = screenH / 937

    -- Posição do botão "i" no canto inferior direito
    local btnIX = screenW - 50
    local btnIY = screenH - 50
    local btnIRad = 16

    local mx, my = love.mouse.getPosition()

    if menu.mostrarPainelDevs then
        hoverI = false
        local sobreAlgumPainel = false
        
        -- Hover do fechar
        local closeX = (screenW - panelW) / 2 + (panelW - 180) / 2
        local closeY = (screenH - panelH) / 2 + 435
        local closeW = 180
        local closeH = 42
        botaoFecharHover = mx >= closeX and mx <= closeX + closeW and my >= closeY and my <= closeY + closeH
        if botaoFecharHover then
            sobreAlgumPainel = true
        end

        -- Hover dos botões de LinkedIn e GitHub
        local panelX = (screenW - panelW) / 2
        local panelY = (screenH - panelH) / 2
        for i, dev in ipairs(devs) do
            local cardX = panelX + 30 + (i - 1) * 154
            local cardY = panelY + 115
            
            -- LinkedIn button coords
            local lknX = cardX + 13
            local lknY = cardY + 185
            local btnW = 110
            local btnH = 32
            
            dev.hoverLinkedIn = mx >= lknX and mx <= lknX + btnW and my >= lknY and my <= lknY + btnH
            
            -- GitHub button coords
            local ghX = cardX + 13
            local ghY = cardY + 225
            
            dev.hoverGitHub = mx >= ghX and mx <= ghX + btnW and my >= ghY and my <= ghY + btnH
            
            if dev.hoverLinkedIn or dev.hoverGitHub then
                sobreAlgumPainel = true
            end
        end

        if sobreAlgumPainel then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        else
            love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
        end
        return
    end

    -- Atualiza dinamicamente as coordenadas dos botões com base no tamanho da tela
    for _, botao in ipairs(botoes) do
        botao.x = botao.rx * scaleX
        botao.y = botao.ry * scaleY
        botao.w = botao.rw * scaleX
        botao.h = botao.rh * scaleY
    end

    -- Hover do botão "i"
    local dist = math.sqrt((mx - btnIX)^2 + (my - btnIY)^2)
    hoverI = (dist <= btnIRad)

    local sobreAlgum = hoverI
    for _, botao in ipairs(botoes) do
        botao.hover =
            mx >= botao.x and mx <= botao.x + botao.w and
            my >= botao.y and my <= botao.y + botao.h
        if botao.hover then
            sobreAlgum = true
        end
    end

    if sobreAlgum then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end
end

function menu.draw()
    local screenW = LG.getWidth()
    local screenH = LG.getHeight()
    local scaleX = screenW / 1679
    local scaleY = screenH / 937

    -- 1. Fundo
    LG.setColor(1, 1, 1)
    LG.draw(imagemFundo, 0, 0, 0, scaleX, scaleY)

    -- 2. Desenha botão "i"
    local btnIX = screenW - 50
    local btnIY = screenH - 50
    local btnIRad = 16

    local alphaI = hoverI and 0.90 or 0.35
    LG.setColor(0.18, 0.11, 0.07, alphaI)
    LG.circle("fill", btnIX, btnIY, btnIRad)
    LG.setColor(0.75, 0.60, 0.38, alphaI)
    LG.setLineWidth(2)
    LG.circle("line", btnIX, btnIY, btnIRad)

    LG.setFont(fontButton)
    LG.setColor(0.85, 0.70, 0.45, alphaI)
    LG.printf("i", btnIX - 16, btnIY - 10, 32, "center")

    -- 3. Desenha painel de desenvolvedores se estiver ativo
    local mx, my = love.mouse.getPosition()
    if menu.mostrarPainelDevs then
        local panelX = (screenW - panelW) / 2
        local panelY = (screenH - panelH) / 2
        
        -- Filtro de escurecimento
        LG.setColor(0, 0, 0, 0.70)
        LG.rectangle("fill", 0, 0, screenW, screenH)
        
        desenharPainelDevs(panelX, panelY, mx, my)
    end

    -- 4. Cursor personalizado
    local sobreAlgum = hoverI
    if menu.mostrarPainelDevs then
        sobreAlgum = botaoFecharHover
        for _, dev in ipairs(devs) do
            if dev.hoverLinkedIn or dev.hoverGitHub then
                sobreAlgum = true
            end
        end
    else
        for _, botao in ipairs(botoes) do
            if mx >= botao.x and mx <= botao.x + botao.w and
               my >= botao.y and my <= botao.y + botao.h then
                sobreAlgum = true
                break
            end
        end
    end

    if sobreAlgum then
        LG.setColor(0.90, 0.75, 0.40, 0.95)
    else
        LG.setColor(0, 0.9, 0.9, 0.9)
    end
    LG.setLineWidth(2)
    LG.line(mx - 10, my, mx - 3, my)
    LG.line(mx + 3, my, mx + 10, my)
    LG.line(mx, my - 10, mx, my - 3)
    LG.line(mx, my + 3, mx, my + 10)
    LG.circle("line", mx, my, 3)
    if sobreAlgum then
        LG.circle("fill", mx, my, 2)
    end
    LG.setColor(1, 1, 1, 1)
end

function menu.mousepressed(x, y, button)
    if button == 1 then
        if menu.mostrarPainelDevs then
            for _, dev in ipairs(devs) do
                if dev.hoverLinkedIn then
                    love.system.openURL(dev.linkedin)
                    return
                end
                if dev.hoverGitHub then
                    love.system.openURL(dev.github)
                    return
                end
            end

            if botaoFecharHover then
                menu.mostrarPainelDevs = false
                return
            end
        else
            if hoverI then
                menu.mostrarPainelDevs = true
                return
            end

            for _, botao in ipairs(botoes) do
                if botao.hover then
                    botao.acao()
                end
            end
        end
    end
end

function menu.keypressed(key)
    if menu.mostrarPainelDevs then
        if key == "escape" or key == "return" then
            menu.mostrarPainelDevs = false
            return
        end
    else
        if key == "return" then
            local musica = require "sistemas.musica"
            musica.parar()
            estadoAtual = require "estados.cutscene"
            if estadoAtual.load then
                estadoAtual.load()
            end
        end

        if key == "escape" then
            estadoAtual = require "estados.configuracoes"
            if estadoAtual.load then
                estadoAtual.load()
            end
        end
    end
end

return menu