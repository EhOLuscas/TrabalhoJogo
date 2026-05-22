local utf8 = require("utf8")
local gerenciadorMapas = require "sistemas.gerenciadorMapas"

local dialogo = {}

dialogo.ativo = false
dialogo.pertoDoMago = false
dialogo.textoExibido = ""
dialogo.indice = 1
dialogo.charIndex = 0
dialogo.charTimer = 0
dialogo.autoAdvanceTimer = 0

local videoAudio
local portraitImg
local fonteDialogo
local fonteTag
local fontePrompt

local falas = {
    "“Então… você finalmente despertou o eco do Fragmento Ômega.”",
    "“Os fundadores de Solaria sabiam que um dia os Abissais retornariam.\nPor isso criaram técnicas proibidas… poderes capazes de rasgar o próprio espaço.”",
    "“O que vou lhe ensinar agora não é magia.\nÉ uma ruptura momentânea da realidade.”",
    "“As Runas de Deslocamento do Pacto: Umbra Æternum permitem atravessar matéria e ignorar ataques por um breve instante…\nmas cada salto aproxima sua mente da corrupção.”",
    "“Use esse poder apenas quando necessário, descendente.”",
    "“Para usar o Teletransporte, clique com o botão direito do mouse no local desejado.”",
    "“Seu corpo será deslocado instantaneamente até a posição do cursor, atravessando projéteis e distorções.”",
    "“Mas lembre-se: cada uso consome 35 de energia… e a habilidade precisa de alguns segundos para estabilizar novamente.”",
    "“Domine o espaço… antes que o Abismo domine você.”"
}

function dialogo.carregar()
    print("dialogo.carregar chamando...")
    local success, res = pcall(love.audio.newSource, "sprites/mago-audio/fala-mago.ogv", "stream")
    if success then
        videoAudio = res
        print("Audio do mago carregado com sucesso!")
    else
        print("Erro ao carregar o audio do mago: " .. tostring(res))
    end

    local portraitSuccess, portraitRes = pcall(LG.newImage, "sprites/npc/Guardiao-teletransporte.png")
    if portraitSuccess then
        portraitImg = portraitRes
        print("Imagem de retrato carregada com sucesso!")
    else
        print("Erro ao carregar imagem do retrato: " .. tostring(portraitRes))
    end
    
    fonteDialogo = love.graphics.newFont(16)
    fonteTag = love.graphics.newFont(14)
    fontePrompt = love.graphics.newFont(12)
end

function dialogo.podeInteragir(jogador)
    if dialogo.ativo then return false end
    
    local mapa = gerenciadorMapas.atual
    if mapa then
        if mapa.nome == "inicio" then
            local px = jogador.x + jogador.w / 2
            local py = jogador.y + jogador.h / 2
            local mx = 920 + (128 * 1.35) / 2
            local my = 610 + (128 * 1.35) / 2
            local dx = px - mx
            local dy = py - my
            local dist = math.sqrt(dx * dx + dy * dy)
            print("podeInteragir - Distancia: " .. dist .. ", Jogador: (" .. px .. ", " .. py .. "), Mago: (" .. mx .. ", " .. my .. ")")
            return dist < 140
        else
            print("podeInteragir - Nao esta no mapa inicio, esta em: " .. tostring(mapa.nome))
        end
    else
        print("podeInteragir - Mapa atual nulo")
    end
    return false
end

function dialogo.iniciar()
    print("dialogo.iniciar() chamado.")
    dialogo.ativo = true
    dialogo.indice = 1
    dialogo.charIndex = 0
    dialogo.charTimer = 0
    dialogo.autoAdvanceTimer = 0
    dialogo.textoExibido = ""
    
    if videoAudio then
        print("Iniciando playback do videoAudio...")
        videoAudio:seek(0)
        videoAudio:play()
    else
        print("videoAudio nao esta carregado!")
    end
end

function dialogo.atualizar(dt, jogador)
    if not dialogo.ativo then
        dialogo.pertoDoMago = dialogo.podeInteragir(jogador)
        return
    end

    local textoAtual = falas[dialogo.indice]
    if textoAtual then
        local maxLen = utf8.len(textoAtual)
        if dialogo.charIndex < maxLen then
            dialogo.charTimer = dialogo.charTimer + dt
            local vel = 0.025 -- velocidade de escrita
            if dialogo.charTimer >= vel then
                dialogo.charTimer = dialogo.charTimer - vel
                dialogo.charIndex = dialogo.charIndex + 1
                local byteOffset = utf8.offset(textoAtual, dialogo.charIndex + 1)
                if byteOffset then
                    dialogo.textoExibido = string.sub(textoAtual, 1, byteOffset - 1)
                else
                    dialogo.textoExibido = textoAtual
                end
            end
        else
            -- Avanço automático após o texto ser totalmente exibido
            dialogo.autoAdvanceTimer = dialogo.autoAdvanceTimer + dt
            local delayAvanco = 2.0 -- 2 segundos para o jogador ler
            if dialogo.autoAdvanceTimer >= delayAvanco then
                dialogo.autoAdvanceTimer = 0
                dialogo.indice = dialogo.indice + 1
                if dialogo.indice > #falas then
                    dialogo.fechar()
                else
                    dialogo.charIndex = 0
                    dialogo.charTimer = 0
                    dialogo.textoExibido = ""
                end
            end
        end
    end
end

function dialogo.fechar()
    dialogo.ativo = false
    if videoAudio then
        videoAudio:pause()
    end
end

function dialogo.keypressed(key)
    if not dialogo.ativo then return end

    if key == "e" or key == "return" or key == "space" then
        local textoAtual = falas[dialogo.indice]
        if textoAtual then
            local maxLen = utf8.len(textoAtual)
            if dialogo.charIndex < maxLen then
                dialogo.charIndex = maxLen
                dialogo.textoExibido = textoAtual
                dialogo.autoAdvanceTimer = 0 -- Inicia o delay de 2 segundos a partir de agora
            else
                dialogo.indice = dialogo.indice + 1
                dialogo.autoAdvanceTimer = 0
                if dialogo.indice > #falas then
                    dialogo.fechar()
                else
                    dialogo.charIndex = 0
                    dialogo.charTimer = 0
                    dialogo.textoExibido = ""
                end
            end
        end
    end
end

-- Desenho em coordenadas de mundo (prompt flutuante)
function dialogo.drawWorld()
    if not dialogo.ativo and dialogo.pertoDoMago then
        local mx = 920 + (128 * 1.35) / 2
        local my = 610 - 20
        
        local oldFont = love.graphics.getFont()
        love.graphics.setFont(fontePrompt)
        
        local texto = "[E] Falar"
        local textW = fontePrompt:getWidth(texto)
        local textH = fontePrompt:getHeight()
        local paddingX = 8
        local paddingY = 4
        local boxW = textW + paddingX * 2
        local boxH = textH + paddingY * 2
        local boxX = mx - boxW / 2
        local boxY = my - boxH / 2
        
        -- Fundo escuro rústico
        LG.setColor(0.12, 0.08, 0.06, 0.9)
        LG.rectangle("fill", boxX, boxY, boxW, boxH, 4)
        
        -- Borda dourada
        LG.setColor(0.85, 0.65, 0.12)
        LG.setLineWidth(1.5)
        LG.rectangle("line", boxX, boxY, boxW, boxH, 4)
        
        -- Texto
        LG.setColor(0.95, 0.9, 0.85)
        LG.print(texto, boxX + paddingX, boxY + paddingY)
        
        love.graphics.setFont(oldFont)
    end
end

-- Desenho em coordenadas de tela (caixa estilo Stardew Valley)
function dialogo.drawScreen()
    if not dialogo.ativo then return end

    local screenW = LG.getWidth()
    local screenH = LG.getHeight()
    
    local boxW = math.min(750, screenW - 80)
    local boxH = 150
    local boxX = (screenW - boxW) / 2
    local boxY = screenH - boxH - 30
    
    local oldFont = love.graphics.getFont()
    
    -- 1. Caixa Principal
    LG.setColor(0.12, 0.08, 0.06, 0.95)
    LG.rectangle("fill", boxX, boxY, boxW, boxH, 8)
    
    -- Borda externa dourada
    LG.setColor(0.85, 0.65, 0.12)
    LG.setLineWidth(3)
    LG.rectangle("line", boxX, boxY, boxW, boxH, 8)
    
    -- Borda interna marrom claro
    LG.setColor(0.5, 0.35, 0.2)
    LG.setLineWidth(1)
    LG.rectangle("line", boxX + 4, boxY + 4, boxW - 8, boxH - 8, 6)
    
    -- 2. Tag de Nome
    local tagW = 75
    local tagH = 26
    local tagX = boxX + 25
    local tagY = boxY - 18
    
    LG.setColor(0.12, 0.08, 0.06, 0.98)
    LG.rectangle("fill", tagX, tagY, tagW, tagH, 4)
    
    LG.setColor(0.85, 0.65, 0.12)
    LG.setLineWidth(2)
    LG.rectangle("line", tagX, tagY, tagW, tagH, 4)
    
    love.graphics.setFont(fonteTag)
    LG.setColor(0.95, 0.9, 0.85)
    LG.print("Mago", tagX + 18, tagY + 4)
    
    -- 3. Retrato do Mago
    if portraitImg then
        local pSize = 100
        local pX = boxX + 20
        local pY = boxY + (boxH - pSize) / 2
        
        -- Fundo do retrato
        LG.setColor(0.08, 0.05, 0.04)
        LG.rectangle("fill", pX, pY, pSize, pSize, 4)
        
        -- Borda do retrato
        LG.setColor(0.5, 0.35, 0.2)
        LG.setLineWidth(1.5)
        LG.rectangle("line", pX, pY, pSize, pSize, 4)
        
        -- Sprite do mago
        LG.setColor(1, 1, 1)
        local esc = pSize / 128
        LG.draw(portraitImg, pX, pY, 0, esc, esc)
    end
    
    -- 4. Texto
    love.graphics.setFont(fonteDialogo)
    LG.setColor(0.95, 0.9, 0.85)
    local textX = boxX + 140
    local textY = boxY + 25
    local textW = boxW - 165
    LG.printf(dialogo.textoExibido, textX, textY, textW, "left")
    
    -- 5. Bouncing arrow
    local textoAtual = falas[dialogo.indice]
    if textoAtual and dialogo.charIndex >= utf8.len(textoAtual) then
        local bob = math.sin(love.timer.getTime() * 8) * 3
        local arrowX = boxX + boxW - 30
        local arrowY = boxY + boxH - 22 + bob
        
        LG.setColor(0.85, 0.65, 0.12)
        LG.polygon("fill", 
            arrowX, arrowY,
            arrowX + 12, arrowY,
            arrowX + 6, arrowY + 8
        )
    end
    
    love.graphics.setFont(oldFont)
end

return dialogo
