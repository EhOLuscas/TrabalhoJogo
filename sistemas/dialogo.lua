local utf8 = require("utf8")
local gerenciadorMapas = require "sistemas.gerenciadorMapas"
local gc = require "npc.guerreiro-canhao"
local ge = require "npc.guerreiro-energia"
local ga = require "npc.guerreiro-aviso"
local save = require "sistemas.save"

local dialogo = {}

dialogo.ativo = false
dialogo.pertoDoMago = false
dialogo.textoExibido = ""
dialogo.indice = 1
dialogo.charIndex = 0
dialogo.charTimer = 0
dialogo.autoAdvanceTimer = 0
dialogo.interagirCom = nil
dialogo.falasAtuais = {}

local audiosMago = {}
local audiosGuerreiro = {}
local audiosCanhao = {}
local audiosEnergia = {}
local audiosAviso = {}
local portraitImg
local portraitGImg
local portraitCImg
local portraitEImg
local portraitAImg
local fonteDialogo
local fonteTag
local fontePrompt

local falasMago = {
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

local falasGuerreiro = {
    "“Antes de enfrentar os horrores além desta passagem… você precisa aprender a sobreviver.”",
    "“O Canhão Axiom ainda não pertence a você.\nPor enquanto… sua única defesa será o aço.”",
    "“Esta lâmina foi forjada pelos antigos guardiões de Solaria para enfrentar criaturas corrompidas.”",
    "“Ataque usando sua espada, mas cuidado… cada golpe consome energia do seu núcleo.”",
    "“Se desperdiçar força, ficará vulnerável diante das criaturas do Abismo.”",
    "*Sons estranhos ecoam das profundezas da caverna...*",
    "“Está ouvindo isso…?”",
    "“A corrupção já alcançou as profundezas dessa caverna.\nAlgo se move na escuridão… algo faminto.”",
    "“Depois dessa passagem, não haverá mais segurança.\nApenas sombras… carne deformada… e ecos dos Abissais.”",
    "“Mantenha sua guarda alta, descendente.”",
    "“Na escuridão, até o silêncio tenta te matar.”"
}

local falasCanhao = gc.falas
local falasEnergia = ge.falas
local falasAviso = ga.falas

local mapeamentoAudiosMago = {
    [1] = "pt1.ogv",
    [2] = "pt2.ogv",
    [3] = "pt3.ogv",
    [4] = "pt9.ogv",
    [5] = "pt4.ogv",
    [6] = "pt5.ogv",
    [7] = "pt6.ogv",
    [8] = "pt7.ogv",
    [9] = "pt8.ogv"
}

local mapeamentoAudiosGuerreiro = {
    [1] = "pt1.ogv",
    [2] = "pt2.ogv",
    [3] = "pt3.ogv",
    [4] = "pt4.ogv",
    [5] = "pt5.ogv",
    [6] = "barulhoCavernaGUERREIRO-ESPADA.ogv",
    [7] = "pt6.ogv",
    [8] = "pt7.ogv",
    [9] = "pt8.ogv",
    [10] = "pt9.ogv",
    [11] = "pt10.ogv"
}

function dialogo.pararAudios()
    for _, src in pairs(audiosMago) do
        if src and src:isPlaying() then src:stop() end
    end
    for _, src in pairs(audiosGuerreiro) do
        if src and src:isPlaying() then src:stop() end
    end
    for _, src in pairs(audiosCanhao) do
        if src and src:isPlaying() then src:stop() end
    end
    for _, src in pairs(audiosEnergia) do
        if src and src:isPlaying() then src:stop() end
    end
    for _, src in pairs(audiosAviso) do
        if src and src:isPlaying() then src:stop() end
    end
end

function dialogo.tocarAudio(index)
    dialogo.pararAudios()
    
    local listaAudios
    if dialogo.interagirCom == "guerreiro" then
        listaAudios = audiosGuerreiro
    elseif dialogo.interagirCom == "canhao" then
        listaAudios = audiosCanhao
    elseif dialogo.interagirCom == "energia" then
        listaAudios = audiosEnergia
    elseif dialogo.interagirCom == "guerreiroAviso" then
        listaAudios = audiosAviso
    else
        listaAudios = audiosMago
    end
    
    if listaAudios then
        local audio = listaAudios[index]
        if audio then
            audio:seek(0)
            audio:play()
        end
    end
end

function dialogo.carregar()
    -- Carrega áudios do Mago
    for i = 1, #mapeamentoAudiosMago do
        local nomeArquivo = mapeamentoAudiosMago[i]
        local path = "sprites/mago-audio/" .. nomeArquivo
        local success, res = pcall(love.audio.newSource, path, "stream")
        if success then
            audiosMago[i] = res
        end
    end

    -- Carrega áudios do Guerreiro
    for i = 1, #mapeamentoAudiosGuerreiro do
        local nomeArquivo = mapeamentoAudiosGuerreiro[i]
        local path = "sprites/guerreiroEspada-audio/" .. nomeArquivo
        local success, res = pcall(love.audio.newSource, path, "stream")
        if success then
            audiosGuerreiro[i] = res
        end
    end

    -- Carrega áudios do Guerreiro Canhao
    if gc.audios and gc.audioDir then
        for i = 1, #gc.audios do
            local nomeArquivo = gc.audios[i]
            local path = gc.audioDir .. nomeArquivo
            local success, res = pcall(love.audio.newSource, path, "stream")
            if success then
                audiosCanhao[i] = res
            end
        end
    end

    -- Carrega áudios do Guerreiro Energia
    if ge.audios and ge.audioDir then
        for i = 1, #ge.audios do
            local nomeArquivo = ge.audios[i]
            local path = ge.audioDir .. nomeArquivo
            local success, res = pcall(love.audio.newSource, path, "stream")
            if success then
                audiosEnergia[i] = res
            end
        end
    end

    -- Carrega áudios do Guerreiro Aviso
    if ga.audios and ga.audioDir then
        for i = 1, #ga.audios do
            local nomeArquivo = ga.audios[i]
            local path = ga.audioDir .. nomeArquivo
            local success, res = pcall(love.audio.newSource, path, "stream")
            if success then
                audiosAviso[i] = res
            end
        end
    end

    local portraitSuccess, portraitRes = pcall(LG.newImage, "sprites/npc/Guardiao-teletransporte.png")
    if portraitSuccess then
        portraitImg = portraitRes
    end
    
    local portraitGSuccess, portraitGRes = pcall(LG.newImage, "sprites/npc/Guardião-espada.png")
    if portraitGSuccess then
        portraitGImg = portraitGRes
    end

    local portraitCSuccess, portraitCRes = pcall(LG.newImage, gc.retrato)
    if portraitCSuccess then
        portraitCImg = portraitCRes
    end
    
    local portraitESuccess, portraitERes = pcall(LG.newImage, ge.retrato)
    if portraitESuccess then
        portraitEImg = portraitERes
    end

    local portraitASuccess, portraitARes = pcall(LG.newImage, ga.retrato)
    if portraitASuccess then
        portraitAImg = portraitARes
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
            
            -- Mago
            local mx = 920 + (128 * 1.35) / 2
            local my = 610 + (128 * 1.35) / 2
            local dx = px - mx
            local dy = py - my
            local distMago = math.sqrt(dx * dx + dy * dy)
            
            -- Guerreiro
            local gx = 730 + (128 * 1.35) / 2
            local gy = 130 + (128 * 1.35) / 2
            local gdx = px - gx
            local gdy = py - gy
            local distGuerreiro = math.sqrt(gdx * gdx + gdy * gdy)
            
            -- Guerreiro Energia
            local ex = ge.x + (128 * ge.escala) / 2
            local ey = ge.y + (128 * ge.escala) / 2
            local edx = px - ex
            local edy = py - ey
            local distEnergia = math.sqrt(edx * edx + edy * edy)
            
            if distMago < 140 then
                dialogo.interagirCom = "mago"
                return true
            elseif distGuerreiro < 140 then
                dialogo.interagirCom = "guerreiro"
                return true
            elseif distEnergia < 140 then
                dialogo.interagirCom = "energia"
                return true
            end
        elseif mapa.nome == "passagem" then
            local px = jogador.x + jogador.w / 2
            local py = jogador.y + jogador.h / 2

            -- Guerreiro Canhao
            local kx = gc.x + (128 * gc.escala) / 2
            local ky = gc.y + (128 * gc.escala) / 2
            local kdx = px - kx
            local kdy = py - ky
            local distCanhao = math.sqrt(kdx * kdx + kdy * kdy)

            -- Guerreiro Aviso
            local ax = ga.x + (128 * ga.escala) / 2
            local ay = ga.y + (128 * ga.escala) / 2
            local adx = px - ax
            local ady = py - ay
            local distAviso = math.sqrt(adx * adx + ady * ady)

            if distCanhao < 140 then
                dialogo.interagirCom = "canhao"
                return true
            elseif distAviso < 140 then
                dialogo.interagirCom = "guerreiroAviso"
                return true
            end
        end
    end
    dialogo.interagirCom = nil
    return false
end

function dialogo.iniciar()
    dialogo.ativo = true
    dialogo.indice = 1
    dialogo.charIndex = 0
    dialogo.charTimer = 0
    dialogo.autoAdvanceTimer = 0
    dialogo.textoExibido = ""
    
    if dialogo.interagirCom == "guerreiro" then
        dialogo.falasAtuais = falasGuerreiro
    elseif dialogo.interagirCom == "canhao" then
        dialogo.falasAtuais = falasCanhao
    elseif dialogo.interagirCom == "energia" then
        dialogo.falasAtuais = falasEnergia
    elseif dialogo.interagirCom == "guerreiroAviso" then
        dialogo.falasAtuais = falasAviso
    else
        dialogo.falasAtuais = falasMago
    end
    
    dialogo.tocarAudio(dialogo.indice)
end

function dialogo.atualizar(dt, jogador)
    if not dialogo.ativo then
        dialogo.pertoDoMago = dialogo.podeInteragir(jogador)
        return
    end

    local textoAtual = dialogo.falasAtuais[dialogo.indice]
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
            -- Só avança automaticamente depois que o áudio terminar (se houver áudio) e passar o delay de 2 segundos
            local audioTocando = false
            if dialogo.interagirCom == "guerreiro" then
                local audioAtual = audiosGuerreiro[dialogo.indice]
                audioTocando = audioAtual and audioAtual:isPlaying()
            elseif dialogo.interagirCom == "canhao" then
                local audioAtual = audiosCanhao[dialogo.indice]
                audioTocando = audioAtual and audioAtual:isPlaying()
            elseif dialogo.interagirCom == "energia" then
                local audioAtual = audiosEnergia[dialogo.indice]
                audioTocando = audioAtual and audioAtual:isPlaying()
            elseif dialogo.interagirCom == "guerreiroAviso" then
                local audioAtual = audiosAviso[dialogo.indice]
                audioTocando = audioAtual and audioAtual:isPlaying()
            elseif dialogo.interagirCom == "mago" then
                local audioAtual = audiosMago[dialogo.indice]
                audioTocando = audioAtual and audioAtual:isPlaying()
            end
            
            if not audioTocando then
                dialogo.autoAdvanceTimer = dialogo.autoAdvanceTimer + dt
                local delayAvanco = 2.0 -- 2 segundos para o jogador ler depois do áudio acabar
                if dialogo.autoAdvanceTimer >= delayAvanco then
                    dialogo.autoAdvanceTimer = 0
                    dialogo.indice = dialogo.indice + 1
                    if dialogo.indice > #dialogo.falasAtuais then
                        dialogo.fechar()
                    else
                        dialogo.charIndex = 0
                        dialogo.charTimer = 0
                        dialogo.textoExibido = ""
                        dialogo.tocarAudio(dialogo.indice)
                    end
                end
            else
                dialogo.autoAdvanceTimer = 0
            end
        end
    end
end

function dialogo.fechar()
    -- Desbloqueia o canhão ao terminar o diálogo com Korvath
    if dialogo.interagirCom == "canhao" then
        local jogador = require "entidades.jogador"
        jogador.canhaoDesbloqueado = true
        -- Persiste o desbloqueio imediatamente no save
        local dadosSave = save.carregar() or {}
        save.salvar({
            mapa = dadosSave.mapa or "passagem",
            canhaoDesbloqueado = true,
            arma = jogador.arma or "espada",
        })
    end
    dialogo.ativo = false
    dialogo.pararAudios()
end

function dialogo.keypressed(key)
    if not dialogo.ativo then return end

    if key == "e" or key == "return" or key == "space" then
        local textoAtual = dialogo.falasAtuais[dialogo.indice]
        if textoAtual then
            local maxLen = utf8.len(textoAtual)
            if dialogo.charIndex < maxLen then
                dialogo.charIndex = maxLen
                dialogo.textoExibido = textoAtual
                dialogo.autoAdvanceTimer = 0 -- Inicia o delay de 2 segundos a partir de agora
            else
                dialogo.indice = dialogo.indice + 1
                dialogo.autoAdvanceTimer = 0
                if dialogo.indice > #dialogo.falasAtuais then
                    dialogo.fechar()
                else
                    dialogo.charIndex = 0
                    dialogo.charTimer = 0
                    dialogo.textoExibido = ""
                    dialogo.tocarAudio(dialogo.indice)
                end
            end
        end
    end
end

-- Desenho em coordenadas de mundo (prompt flutuante)
function dialogo.drawWorld()
    if not dialogo.ativo and dialogo.pertoDoMago then
        local bx, by
        if dialogo.interagirCom == "guerreiro" then
            bx = 730 + (128 * 1.35) / 2
            by = 130 - 20
        elseif dialogo.interagirCom == "canhao" then
            bx = gc.x + (128 * gc.escala) / 2
            by = gc.y - 20
        elseif dialogo.interagirCom == "energia" then
            bx = ge.x + (128 * ge.escala) / 2
            by = ge.y - 20
        elseif dialogo.interagirCom == "guerreiroAviso" then
            bx = ga.x + (128 * ga.escala) / 2
            by = ga.y - 20
        else
            bx = 920 + (128 * 1.35) / 2
            by = 610 - 20
        end
        
        local oldFont = love.graphics.getFont()
        love.graphics.setFont(fontePrompt)
        
        local texto = "[E] Falar"
        local textW = fontePrompt:getWidth(texto)
        local textH = fontePrompt:getHeight()
        local paddingX = 8
        local paddingY = 4
        local boxW = textW + paddingX * 2
        local boxH = textH + paddingY * 2
        local boxX = bx - boxW / 2
        local boxY = by - boxH / 2
        
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
        
        LG.setColor(1, 1, 1)
        love.graphics.setFont(oldFont)
    end
end

-- Desenho em coordenadas de tela (caixa estilo Stardew Valley)
function dialogo.drawScreen()
    if not dialogo.ativo then return end

    local screenW = LG.getWidth()
    local screenH = LG.getHeight()

    -- 0. Filtro de escurecimento de tela
    LG.setColor(0, 0, 0, 0.5)
    LG.rectangle("fill", 0, 0, screenW, screenH)
    
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
    love.graphics.setFont(fonteTag)
    local tagTexto = "Mago"
    if dialogo.interagirCom == "guerreiro" then
        tagTexto = "Dravik Menyrr"
    elseif dialogo.interagirCom == "canhao" then
        tagTexto = gc.nome
    elseif dialogo.interagirCom == "energia" then
        tagTexto = ge.nome
    elseif dialogo.interagirCom == "guerreiroAviso" then
        tagTexto = ga.nome
    else
        tagTexto = "Sael’Nyth Sultharyn"
    end
    
    local tagW = fonteTag:getWidth(tagTexto) + 30
    local tagH = 26
    local tagX = boxX + 25
    local tagY = boxY - 18
    
    LG.setColor(0.12, 0.08, 0.06, 0.98)
    LG.rectangle("fill", tagX, tagY, tagW, tagH, 4)
    
    LG.setColor(0.85, 0.65, 0.12)
    LG.setLineWidth(2)
    LG.rectangle("line", tagX, tagY, tagW, tagH, 4)
    
    LG.setColor(0.95, 0.9, 0.85)
    LG.print(tagTexto, tagX + 15, tagY + 4)
    
    -- 3. Retrato do NPC
    local portraitImgAtu = portraitImg
    if dialogo.interagirCom == "guerreiro" then
        portraitImgAtu = portraitGImg
    elseif dialogo.interagirCom == "canhao" then
        portraitImgAtu = portraitCImg
    elseif dialogo.interagirCom == "energia" then
        portraitImgAtu = portraitEImg
    elseif dialogo.interagirCom == "guerreiroAviso" then
        portraitImgAtu = portraitAImg
    end
    
    if portraitImgAtu then
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
        
        -- Sprite do npc
        LG.setColor(1, 1, 1)
        local esc = pSize / 128
        LG.draw(portraitImgAtu, pX, pY, 0, esc, esc)
    end
    
    -- 4. Texto
    love.graphics.setFont(fonteDialogo)
    LG.setColor(0.95, 0.9, 0.85)
    local textX = boxX + 140
    local textY = boxY + 25
    local textW = boxW - 165
    LG.printf(dialogo.textoExibido, textX, textY, textW, "left")
    
    -- 5. Bouncing arrow
    local textoAtual = dialogo.falasAtuais[dialogo.indice]
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
    
    LG.setColor(1, 1, 1)
    love.graphics.setFont(oldFont)
end

return dialogo