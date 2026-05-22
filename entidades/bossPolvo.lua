require "constantes"

local bossPolvo = {}

-- Estado
bossPolvo.ativo = false
bossPolvo.vida = 500
bossPolvo.vidaMax = 500
bossPolvo.x = 0
bossPolvo.y = 0
bossPolvo.w = 120
bossPolvo.h = 120

-- Animação
local frames = {}
local frameAtual = 1
local timerAnim = 0
local fpsAnim = 10
local totalFrames = 0

-- Laser
local FASE_ALERTA = "alerta"   -- mira seguindo o player
local FASE_LASER  = "laser"    -- dispara
local FASE_PAUSA  = "pausa"    -- descansa

local laser = {
    fase = FASE_PAUSA,
    timer = 0,
    duracaoAlerta = 1.5,  -- segundos mostrando alerta
    duracaoLaser  = 0.8,  -- segundos do laser ativo
    duracaoPausa  = 2.0,  -- segundos entre ataques
    alvoX = 0,
    alvoY = 0,
    origemX = 0,
    origemY = 0,
}

local LARGURA_MAPA = 1316

function bossPolvo.carregar()
    frames = {}
    for i = 1, 16 do
        local path = "sprites/BOSS/polvo/image_" .. i .. ".png"
        local ok, img = pcall(LG.newImage, path)
        if ok then
            frames[#frames + 1] = img
        end
    end
    totalFrames = #frames

    -- Posição: meio do buraco na parte de cima do mapa (fase1: 1316x1195)
    bossPolvo.x = LARGURA_MAPA / 2 - bossPolvo.w / 2
    bossPolvo.y = 60
end

function bossPolvo.reset()
    bossPolvo.ativo = false
    bossPolvo.vida = bossPolvo.vidaMax
    frameAtual = 1
    timerAnim = 0
    laser.fase = FASE_PAUSA
    laser.timer = laser.duracaoPausa
end

function bossPolvo.receberDano(qtd)
    if not bossPolvo.ativo then return end
    bossPolvo.vida = math.max(0, bossPolvo.vida - qtd)
end

local function centroJogador(jogador)
    return jogador.x + jogador.w / 2, jogador.y + jogador.h / 2
end

function bossPolvo.atualizar(dt, jogador, combate)
    if not bossPolvo.ativo then
        -- Ativa quando jogador chega no meio do mapa (x > metade)
        if jogador.x > LARGURA_MAPA / 2 - 200 then
            bossPolvo.ativo = true
            laser.fase = FASE_PAUSA
            laser.timer = 1.5
        end
        return
    end

    if bossPolvo.vida <= 0 then
        bossPolvo.ativo = false
        return
    end

    -- Animação
    timerAnim = timerAnim + dt
    if timerAnim >= 1 / fpsAnim then
        timerAnim = 0
        frameAtual = frameAtual % totalFrames + 1
    end

    -- Centro do boss (boca do laser)
    laser.origemX = bossPolvo.x + bossPolvo.w / 2
    laser.origemY = bossPolvo.y + bossPolvo.h

    local jx, jy = centroJogador(jogador)

    -- Máquina de estado do laser
    laser.timer = laser.timer - dt

    if laser.fase == FASE_PAUSA then
        if laser.timer <= 0 then
            laser.fase = FASE_ALERTA
            laser.timer = laser.duracaoAlerta
        end

    elseif laser.fase == FASE_ALERTA then
        -- Alvo segue o jogador durante o alerta
        laser.alvoX = jx
        laser.alvoY = jy
        if laser.timer <= 0 then
            laser.fase = FASE_LASER
            laser.timer = laser.duracaoLaser
        end

    elseif laser.fase == FASE_LASER then
        -- Verifica colisão do laser com o jogador
        -- O laser é uma linha do origem ao alvo
        local lx1, ly1 = laser.origemX, laser.origemY
        local lx2, ly2 = laser.alvoX, laser.alvoY
        -- Extende o laser além do alvo
        local dx = lx2 - lx1
        local dy = ly2 - ly1
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            lx2 = lx1 + (dx/dist) * 1200
            ly2 = ly1 + (dy/dist) * 1200
        end

        -- Colisão simples: distância do centro do jogador à linha do laser
        local px, py = jx, jy
        local t = ((px-lx1)*(lx2-lx1) + (py-ly1)*(ly2-ly1)) /
                  ((lx2-lx1)^2 + (ly2-ly1)^2 + 0.0001)
        t = math.max(0, math.min(1, t))
        local cx = lx1 + t*(lx2-lx1)
        local cy = ly1 + t*(ly2-ly1)
        local distJogador = math.sqrt((px-cx)^2 + (py-cy)^2)

        if distJogador < 20 then
            combate.receberDano(jogador, 1) -- dano contínuo enquanto no laser
        end

        if laser.timer <= 0 then
            laser.fase = FASE_PAUSA
            laser.timer = laser.duracaoPausa
        end
    end
end

function bossPolvo.verificarDanoProjeteis(listaProjeteis)
    if not bossPolvo.ativo or bossPolvo.vida <= 0 then return end
    for i = #listaProjeteis, 1, -1 do
        local p = listaProjeteis[i]
        if p.tipo ~= "boss" then -- não acerta a si mesmo
            if p.x > bossPolvo.x and p.x < bossPolvo.x + bossPolvo.w and
               p.y > bossPolvo.y and p.y < bossPolvo.y + bossPolvo.h then
                bossPolvo.receberDano(p.dano or 25)
                table.remove(listaProjeteis, i)
            end
        end
    end
end

function bossPolvo.verificarDanoEspada(jogador)
    if not bossPolvo.ativo or bossPolvo.vida <= 0 then return end
    if jogador.arma ~= "espada" or jogador.anim.estado ~= "atacando" then return end
    -- Hitbox da espada: área próxima ao jogador
    local sx = jogador.x + (jogador.virandoDireita and jogador.w or -40)
    local sy = jogador.y
    local sw, sh = 50, jogador.h
    if sx < bossPolvo.x + bossPolvo.w and sx + sw > bossPolvo.x and
       sy < bossPolvo.y + bossPolvo.h and sy + sh > bossPolvo.y then
        bossPolvo.receberDano(15)
    end
end

function bossPolvo.draw()
    if not bossPolvo.ativo then return end

    -- Sprite do boss
    if frames[frameAtual] then
        local img = frames[frameAtual]
        local escala = bossPolvo.w / img:getWidth()
        LG.setColor(1, 1, 1)
        LG.draw(img, bossPolvo.x, bossPolvo.y, 0, escala, escala)
    end

    -- Laser
    local ox, oy = laser.origemX, laser.origemY

    if laser.fase == FASE_ALERTA then
        -- Linha de alerta vermelha tracejada e semi-transparente seguindo o jogador
        local dx = laser.alvoX - ox
        local dy = laser.alvoY - oy
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            local ex = ox + (dx/dist) * 1200
            local ey = oy + (dy/dist) * 1200
            -- Pulsa com o tempo
            local alpha = 0.4 + 0.4 * math.abs(math.sin(love.timer.getTime() * 8))
            LG.setColor(1, 0, 0, alpha)
            LG.setLineWidth(3)
            LG.line(ox, oy, ex, ey)

            -- Círculo no alvo
            LG.setColor(1, 0.2, 0.2, alpha)
            LG.circle("fill", laser.alvoX, laser.alvoY, 12)
            LG.setLineWidth(1)
        end

    elseif laser.fase == FASE_LASER then
        -- Laser real: linha brilhante grossa
        local dx = laser.alvoX - ox
        local dy = laser.alvoY - oy
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            local ex = ox + (dx/dist) * 1200
            local ey = oy + (dy/dist) * 1200
            -- Camadas do laser (glow)
            LG.setColor(1, 0, 0, 0.3)
            LG.setLineWidth(20)
            LG.line(ox, oy, ex, ey)
            LG.setColor(1, 0.3, 0.3, 0.7)
            LG.setLineWidth(8)
            LG.line(ox, oy, ex, ey)
            LG.setColor(1, 1, 1, 1)
            LG.setLineWidth(3)
            LG.line(ox, oy, ex, ey)
            LG.setLineWidth(1)
        end
    end

    LG.setColor(1, 1, 1)
end

return bossPolvo
