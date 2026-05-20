require "constantes"

local jogador = {}

jogador.x = 0
jogador.y = 0
jogador.w = 32
jogador.h = 48
jogador.velocidade = 175

jogador.arma = "espada"
jogador.canhaoDesbloqueado = false
jogador.virandoDireita = true

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
    idle_canhao     = 5,
    andando_canhao  = 6,
    atirando_canhao = 4,
    ataque_espada   = 6,
    andando_espada  = 5,
    idle_espada = 5,
}

function jogador.carregarSprites()
    for nome, _ in pairs(frameCount) do
        sheets[nome] = LG.newImage("sprites/" .. nome .. ".png")
    end
end

function jogador.getAnimAtual()
    local arma = jogador.arma
    local estado = jogador.anim.estado
    if arma == "canhao" then
        if estado == "andando" then return "andando_canhao"
        elseif estado == "atacando" then return "atirando_canhao"
        else return "idle_canhao" end
    else
        if estado == "andando" then return "andando_espada"
        elseif estado == "atacando" then return "ataque_espada"
        else return "idle_espada" end
    end
end

function jogador.updateAnim(dt, movendo, atacando)
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

    anim.timer = anim.timer + dt
    if anim.timer >= 1 / anim.fps then
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

function jogador.draw()
    local nomeAnim = jogador.getAnimAtual()
    local sheet = sheets[nomeAnim]
    if not sheet then return end

    local escala = 0.45
    local sw = FRAME_W * escala
    local sh = FRAME_H * escala
    local ox = (sw - jogador.w) / 2
    local oy = (sh - jogador.h) / 2

    local quad = LG.newQuad(
        (jogador.anim.frame - 1) * FRAME_W, 0,
        FRAME_W, FRAME_H,
        sheet:getWidth(), sheet:getHeight()
    )

    LG.setColor(1, 1, 1)
    if jogador.virandoDireita then
        LG.draw(sheet, quad, jogador.x - ox, jogador.y - oy, 0, escala, escala)
    else
        LG.draw(sheet, quad, jogador.x + jogador.w + ox, jogador.y - oy, 0, -escala, escala)
    end
end

return jogador