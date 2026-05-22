require "constantes"

local jogador = {}

jogador.x = 0
jogador.y = 0
jogador.w = 32
jogador.h = 48
jogador.velocidade = 175

jogador.vida = 100
jogador.vidaMax = 100

jogador.energia = 100
jogador.energiaMax = 100
jogador.energiaRegen = 20  -- regenera 15 por segundo

jogador.arma = "espada"
jogador.canhaoDesbloqueado = false
jogador.virandoDireita = true
jogador.movendo = false

-- Invencibilidade e piscar ao tomar dano
jogador.invencivel = false
jogador.timerInvencivel = 0
jogador.duracaoInvencivel = 0.8   -- segundos de invencibilidade
jogador.timerPiscar = 0
jogador.intervaloPiscar = 0.02    -- velocidade do piscar (segundos)
jogador.mostrarSprite = true

jogador.anim = {
    frame = 1,
    timer = 0,
    fps = 8,
    estado = "idle",
    estadoAnterior = "",
}

local FRAME_W = 256
local FRAME_H = 192

local sheets = {}
local frameCount = {
    idle_canhao     = 12,  -- 12 frames para idle com canhão (da 5 à 16)
    andando_canhao  = 16,  -- 16 frames para caminhar com canhão
    atirando_canhao = 16,  -- 16 frames para caminhar e atirar com canhão
    ataque_espada   = 16,  -- 16 frames para ataque de espada
    andando_espada  = 16,  -- 16 frames para caminhar com espada
    idle_espada     = 16,  -- 16 frames para idle com espada
}
local frameRates = {
    idle_canhao     = 8,
    andando_canhao  = 8,
    atirando_canhao = 40, -- 40 FPS para ataque do canhão ser mais rápido
    ataque_espada   = 40, -- 40 FPS para ataque de espada ser mais rápido
    andando_espada  = 8,
    idle_espada     = 8,
}

function jogador.carregarSprites()
    -- Carrega as sprites do andando-canhao
    sheets["andando_canhao"] = {}
    local idx = 1
    for i = 1, 16 do
        local path = "sprites/andando-canhao/image_" .. i .. ".png"
        local success, img = pcall(LG.newImage, path)
        if success then
            sheets["andando_canhao"][idx] = img
            idx = idx + 1
        end
    end
    frameCount["andando_canhao"] = idx - 1

    -- Tanto andando_canhao quanto atirando_canhao usam as mesmas sprites
    sheets["atirando_canhao"] = sheets["andando_canhao"]
    frameCount["atirando_canhao"] = frameCount["andando_canhao"]

    -- Carrega as sprites do andando-canhao-idle (da image_5 à image_16)
    sheets["idle_canhao"] = {}
    idx = 1
    for i = 5, 16 do
        local path = "sprites/andando-canhao-idle/image_" .. i .. ".png"
        local success, img = pcall(LG.newImage, path)
        if success then
            sheets["idle_canhao"][idx] = img
            idx = idx + 1
        end
    end
    frameCount["idle_canhao"] = idx - 1

    -- Carrega as sprites do andando-espada (trata o caso de gaps ou remoções de imagens)
    sheets["andando_espada"] = {}
    idx = 1
    for i = 1, 16 do
        local path = "sprites/andando-espada/image_" .. i .. ".png"
        local success, img = pcall(LG.newImage, path)
        if success then
            sheets["andando_espada"][idx] = img
            idx = idx + 1
        end
    end
    frameCount["andando_espada"] = idx - 1

    -- Carrega as sprites do andando-espada-idle
    sheets["idle_espada"] = {}
    idx = 1
    for i = 1, 16 do
        local path = "sprites/andando-espada-idle/image_" .. i .. ".png"
        local success, img = pcall(LG.newImage, path)
        if success then
            sheets["idle_espada"][idx] = img
            idx = idx + 1
        end
    end
    frameCount["idle_espada"] = idx - 1

    -- Carrega as sprites de espadada para o ataque com espada
    sheets["ataque_espada"] = {}
    idx = 1
    for i = 1, 16 do
        local path = "sprites/espadada/image_" .. i .. ".png"
        local success, img = pcall(LG.newImage, path)
        if success then
            sheets["ataque_espada"][idx] = img
            idx = idx + 1
        end
    end
    frameCount["ataque_espada"] = idx - 1

    shaderBranco = LG.newShader([[
        vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screenCoords) {
            vec4 pixel = Texel(tex, texCoords);
            if (pixel.a < 0.01) discard;
            return vec4(1.0, 1.0, 1.0, pixel.a);
        }
    ]])
end

function jogador.getAnimAtual()
    local arma = jogador.arma
    local estado = jogador.anim.estado
    if arma == "canhao" then
        if estado == "andando" then 
            return "andando_canhao"
        elseif estado == "atacando" then 
            if jogador.movendo then
                return "atirando_canhao"
            else
                return "idle_canhao"
            end
        else 
            return "idle_canhao" 
        end
    else
        if estado == "andando" then return "andando_espada"
        elseif estado == "atacando" then return "ataque_espada"
        else return "idle_espada" end
    end
end

function jogador.updateAnim(dt, movendo, atacando)
    jogador.movendo = movendo
    local anim = jogador.anim
    local estadoAnterior = anim.estado

    if atacando then
        anim.estado = "atacando"
    elseif movendo then
        anim.estado = "andando"
    else
        anim.estado = "idle"
    end

    if anim.estado ~= estadoAnterior then
        anim.frame = 1
        anim.timer = 0
    end

    local nomeAnim = jogador.getAnimAtual()
    local total = frameCount[nomeAnim]
    local fps = frameRates[nomeAnim] or anim.fps

    anim.timer = anim.timer + dt
    if anim.timer >= 1 / fps then
        anim.timer = 0
        anim.frame = anim.frame + 1
        if anim.frame > total then
            anim.frame = 1
            if anim.estado == "atacando" then
                anim.estado = "idle"
            end
        end
    end
end

function jogador.updateDano(dt)
    if jogador.invencivel then
        jogador.timerInvencivel = jogador.timerInvencivel - dt
        jogador.timerPiscar = jogador.timerPiscar - dt

        if jogador.timerPiscar <= 0 then
            jogador.timerPiscar = jogador.intervaloPiscar
            jogador.mostrarSprite = not jogador.mostrarSprite
        end

        if jogador.timerInvencivel <= 0 then
            jogador.invencivel = false
            jogador.mostrarSprite = true
        end
    end
end

function jogador.getMuzzlePosition()
    if jogador.arma == "canhao" then
        local escala = 0.9
        local offsetX = 40 * escala
        local offsetY = 25.8
        local x = jogador.x + jogador.w / 2
        local y = jogador.y + offsetY
        if jogador.virandoDireita then
            return x + offsetX, y
        else
            return x - offsetX, y
        end
    else
        return jogador.x + jogador.w / 2, jogador.y + jogador.h / 2
    end
end

function jogador.draw()
    local nomeAnim = jogador.getAnimAtual()
    local sheet = sheets[nomeAnim]
    if not sheet then return end

    local escala = 0.45
    local frameW, frameH
    local isTable = (type(sheet) == "table")

    if isTable then
        local imgFrame = sheet[jogador.anim.frame]
        if not imgFrame then return end
        frameW = imgFrame:getWidth()
        frameH = imgFrame:getHeight()
        -- Ajusta a escala para sprites de 128x128 para ficarem com a mesma proporção
        if frameW == 128 then
            escala = 0.9
        end
    else
        frameW = FRAME_W
        frameH = FRAME_H
    end

    local sw = frameW * escala
    local sh = frameH * escala
    local ox = (sw - jogador.w) / 2
    local oy = (sh - jogador.h) / 2

    local usarBranco = jogador.invencivel and jogador.mostrarSprite

    if usarBranco and shaderBranco then
        LG.setShader(shaderBranco)
    end

    LG.setColor(1, 1, 1)

    if isTable then
        local imgFrame = sheet[jogador.anim.frame]
        if not imgFrame then return end
        if jogador.virandoDireita then
            LG.draw(imgFrame, jogador.x - ox, jogador.y - oy, 0, escala, escala)
        else
            LG.draw(imgFrame, jogador.x + jogador.w + ox, jogador.y - oy, 0, -escala, escala)
        end
    else
        local quad = LG.newQuad(
            (jogador.anim.frame - 1) * FRAME_W, 0,
            FRAME_W, FRAME_H,
            sheet:getWidth(), sheet:getHeight()
        )
        if jogador.virandoDireita then
            LG.draw(sheet, quad, jogador.x - ox, jogador.y - oy, 0, escala, escala)
        else
            LG.draw(sheet, quad, jogador.x + jogador.w + ox, jogador.y - oy, 0, -escala, escala)
        end
    end

    LG.setShader()
end

return jogador