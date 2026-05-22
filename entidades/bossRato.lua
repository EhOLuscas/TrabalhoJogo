require "constantes"

local bossRato = {}

bossRato.ativo = false
bossRato.vida = 500
bossRato.vidaMax = 500
bossRato.w = 130
bossRato.h = 130

-- Posição destino: pilastras no topo do mapa2 (1344x800)
local DESTINO_X = 1344 / 2 - 65
local DESTINO_Y = 80
local LARGURA_MAPA2 = 1344

-- Posição inicial (voa de fora da tela)
bossRato.x = -200
bossRato.y = -200

local chegou = false
local velocidadeEntrada = 350

-- Animação
local frames = {}
local frameAtual = 1
local timerAnim = 0
local fpsAnim = 10
local totalFrames = 0

-- Gosmas
local gosmas = {}
local timerGosma = 0
local intervaloGosma = 2.0      -- intervalo normal
local intervaloGosmaFase2 = 0.8 -- intervalo fase2 (metade da vida)
local velocidadeGosma = 220
local gosmasFase2 = false        -- flag de fase 2

function bossRato.carregar()
    frames = {}
    for i = 1, 16 do
        local path = "sprites/BOSS/rato/image_" .. i .. ".png"
        local ok, img = pcall(LG.newImage, path)
        if ok then frames[#frames + 1] = img end
    end
    totalFrames = #frames
end

function bossRato.reset()
    bossRato.ativo = false
    bossRato.vida = bossRato.vidaMax
    bossRato.x = -200
    bossRato.y = -200
    chegou = false
    gosmas = {}
    timerGosma = 0
    gosmasFase2 = false
    frameAtual = 1
end

function bossRato.receberDano(qtd)
    if not bossRato.ativo then return end
    bossRato.vida = math.max(0, bossRato.vida - qtd)
end

local function dispararGosmas(cx, cy, jx, jy, quantidade)
    -- Dispara `quantidade` gosmas em leque em direção ao jogador
    local dx = jx - cx
    local dy = jy - cy
    local angBase = math.atan2(dy, dx)
    local spread = math.pi / 8
    for i = 0, quantidade - 1 do
        local ang = angBase - spread * (quantidade-1)/2 + spread * i
        table.insert(gosmas, {
            x = cx, y = cy,
            dx = math.cos(ang) * velocidadeGosma,
            dy = math.sin(ang) * velocidadeGosma,
            r = 10, -- raio
        })
    end
end

function bossRato.atualizar(dt, jogador, combate)
    if not bossRato.ativo then
        -- Ativa quando jogador chega no meio do mapa2
        if jogador.x > LARGURA_MAPA2 / 2 - 200 then
            bossRato.ativo = true
            bossRato.x = -200
            bossRato.y = DESTINO_Y
            chegou = false
        end
        return
    end

    if bossRato.vida <= 0 then
        bossRato.ativo = false
        gosmas = {}
        return
    end

    -- Animação
    timerAnim = timerAnim + dt
    if timerAnim >= 1 / fpsAnim then
        timerAnim = 0
        frameAtual = frameAtual % totalFrames + 1
    end

    -- Fase 2: metade da vida
    gosmasFase2 = (bossRato.vida <= bossRato.vidaMax / 2)

    -- Entrada voando
    if not chegou then
        local tx, ty = DESTINO_X, DESTINO_Y
        local dx = tx - bossRato.x
        local dy = ty - bossRato.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < 5 then
            bossRato.x = tx
            bossRato.y = ty
            chegou = true
        else
            bossRato.x = bossRato.x + (dx/dist) * velocidadeEntrada * dt
            bossRato.y = bossRato.y + (dy/dist) * velocidadeEntrada * dt
        end
        return
    end

    -- Atira gosmas
    local intervalo = gosmasFase2 and intervaloGosmaFase2 or intervaloGosma
    timerGosma = timerGosma + dt
    if timerGosma >= intervalo then
        timerGosma = 0
        local cx = bossRato.x + bossRato.w / 2
        local cy = bossRato.y + bossRato.h
        local jx = jogador.x + jogador.w / 2
        local jy = jogador.y + jogador.h / 2
        local qtd = gosmasFase2 and 5 or 3
        dispararGosmas(cx, cy, jx, jy, qtd)
    end

    -- Move gosmas e verifica colisão com jogador
    for i = #gosmas, 1, -1 do
        local g = gosmas[i]
        g.x = g.x + g.dx * dt
        g.y = g.y + g.dy * dt

        -- Colisão com jogador
        local jx = jogador.x + jogador.w / 2
        local jy = jogador.y + jogador.h / 2
        local dist = math.sqrt((g.x-jx)^2 + (g.y-jy)^2)
        if dist < g.r + 16 then
            combate.receberDano(jogador, 15)
            table.remove(gosmas, i)
        elseif g.x < -200 or g.x > 3000 or g.y < -200 or g.y > 3000 then
            table.remove(gosmas, i)
        end
    end
end

function bossRato.verificarDanoProjeteis(listaProjeteis)
    if not bossRato.ativo or bossRato.vida <= 0 then return end
    for i = #listaProjeteis, 1, -1 do
        local p = listaProjeteis[i]
        if p.tipo ~= "boss" then
            if p.x > bossRato.x and p.x < bossRato.x + bossRato.w and
               p.y > bossRato.y and p.y < bossRato.y + bossRato.h then
                bossRato.receberDano(p.dano or 25)
                table.remove(listaProjeteis, i)
            end
        end
    end
end

function bossRato.verificarDanoEspada(jogador)
    if not bossRato.ativo or bossRato.vida <= 0 then return end
    if jogador.arma ~= "espada" or jogador.anim.estado ~= "atacando" then return end
    local sx = jogador.x + (jogador.virandoDireita and jogador.w or -40)
    local sy = jogador.y
    local sw, sh = 50, jogador.h
    if sx < bossRato.x + bossRato.w and sx + sw > bossRato.x and
       sy < bossRato.y + bossRato.h and sy + sh > bossRato.y then
        bossRato.receberDano(15)
    end
end

function bossRato.draw()
    if not bossRato.ativo then return end

    -- Sprite do boss
    if frames[frameAtual] then
        local img = frames[frameAtual]
        local escala = bossRato.w / img:getWidth()
        LG.setColor(1, 1, 1)
        LG.draw(img, bossRato.x, bossRato.y, 0, escala, escala)
    end

    -- Gosmas
    for _, g in ipairs(gosmas) do
        -- Bola verde com brilho
        LG.setColor(0.1, 0.8, 0.1, 0.4)
        LG.circle("fill", g.x, g.y, g.r * 1.8)
        LG.setColor(0.2, 1, 0.2, 1)
        LG.circle("fill", g.x, g.y, g.r)
        LG.setColor(0.7, 1, 0.7, 0.8)
        LG.circle("fill", g.x - g.r*0.3, g.y - g.r*0.3, g.r * 0.35)
    end

    LG.setColor(1, 1, 1)
end

return bossRato
