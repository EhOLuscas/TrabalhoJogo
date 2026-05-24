require "constantes"
local som = require "sistemas.som"

local bossRato = {}

bossRato.ativo = false
bossRato.vida = 500
bossRato.vidaMax = 500
bossRato.w = 360
bossRato.h = 360
bossRato.derrotado = false
bossRato.timerDerrota = 0
bossRato.fimJogo = false


local DESTINO_X = 1344 / 2 - 180
local DESTINO_Y = 10
local LARGURA_MAPA2 = 1344

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

-- Dano / piscar
local invencivel = false
local timerInvencivel = 0
local duracaoInvencivel = 0.4
local timerPiscar = 0
local intervaloPiscar = 0.05
local mostrarSprite = true
local timerCooldownEspada = 0
local cooldownEspada = 0.3
local shaderBranco

-- Gosmas
local gosmas = {}
local timerGosma = 0
local intervaloGosma = 2.0
local intervaloGosmaFase2 = 0.8
local velocidadeGosma = 220
local gosmasFase2 = false

-- Poças
local pocas = {}
local timerPoca = 0
local intervaloPoca = 3.0
local gosmasFase3 = false

function bossRato.carregar()
    frames = {}
    for i = 1, 16 do
        local path = "sprites/BOSS/rato/image_" .. i .. ".png"
        local ok, img = pcall(LG.newImage, path)
        if ok then frames[#frames + 1] = img end
    end
    totalFrames = #frames

    shaderBranco = LG.newShader([[
        vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screenCoords) {
            vec4 pixel = Texel(tex, texCoords);
            if (pixel.a < 0.01) discard;
            return vec4(1.0, 1.0, 1.0, pixel.a);
        }
    ]])
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
    invencivel = false
    timerInvencivel = 0
    mostrarSprite = true
    timerCooldownEspada = 0
    pocas = {}
    timerPoca = 0
    gosmasFase3 = false
    bossRato.derrotado = false
    bossRato.timerDerrota = 0
    bossRato.fimJogo = false
end

function bossRato.receberDano(qtd)
    if not bossRato.ativo or invencivel then return end
    bossRato.vida = math.max(0, bossRato.vida - qtd)
    invencivel = true
    timerInvencivel = duracaoInvencivel
    timerPiscar = intervaloPiscar
    mostrarSprite = true
end

local function dispararGosmas(cx, cy, jx, jy, quantidade)
    local dx = jx - cx
    local dy = jy - cy
    local angBase = math.atan2(dy, dx)
    local spread = math.pi / 8
    for i = 0, quantidade - 1 do
        local ang = angBase - spread * (quantidade - 1) / 2 + spread * i
        table.insert(gosmas, {
            x = cx,
            y = cy,
            dx = math.cos(ang) * velocidadeGosma,
            dy = math.sin(ang) * velocidadeGosma,
            r = 10,
        })
    end
end

function bossRato.atualizar(dt, jogador, combate)
    if not bossRato.ativo then
        if jogador.x > LARGURA_MAPA2 / 2 - 200 then
            bossRato.ativo = true
            bossRato.x = -200
            bossRato.y = DESTINO_Y
            chegou = false
            local musica = require "sistemas.musica"
            musica.seek(18)
        end
        return
    end

    if bossRato.fimJogo then
        return
    end

    if bossRato.derrotado then
        bossRato.timerDerrota = bossRato.timerDerrota - dt
        if bossRato.timerDerrota <= 0 then
            bossRato.ativo = false
            bossRato.fimJogo = true
        end
        return
    end

    if bossRato.vida <= 0 then
        bossRato.derrotado = true
        bossRato.timerDerrota = 2.0
        gosmas = {}
        pocas = {}
        invencivel = false
        mostrarSprite = true
        return
    end

    -- Piscar
    if invencivel then
        timerInvencivel = timerInvencivel - dt
        timerPiscar = timerPiscar - dt
        if timerPiscar <= 0 then
            timerPiscar = intervaloPiscar
            mostrarSprite = not mostrarSprite
        end
        if timerInvencivel <= 0 then
            invencivel = false
            mostrarSprite = true
        end
    end

    -- Cooldown espada
    if timerCooldownEspada > 0 then
        timerCooldownEspada = timerCooldownEspada - dt
    end

    -- Animação
    timerAnim = timerAnim + dt
    if timerAnim >= 1 / fpsAnim then
        timerAnim = 0
        frameAtual = frameAtual % totalFrames + 1
    end

    gosmasFase2 = (bossRato.vida <= bossRato.vidaMax * 0.75)
    gosmasFase3 = (bossRato.vida <= bossRato.vidaMax * 0.50)

    -- Entrada voando
    if not chegou then
        local tx, ty = DESTINO_X, DESTINO_Y
        local dx = tx - bossRato.x
        local dy = ty - bossRato.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < 5 then
            bossRato.x = tx
            bossRato.y = ty
            chegou = true
        else
            bossRato.x = bossRato.x + (dx / dist) * velocidadeEntrada * dt
            bossRato.y = bossRato.y + (dy / dist) * velocidadeEntrada * dt
        end
        return
    end

    -- Atira gosmas a partir da base do sprite
    local intervalo = gosmasFase2 and intervaloGosmaFase2 or intervaloGosma
    timerGosma = timerGosma + dt
    if timerGosma >= intervalo then
        timerGosma = 0
        -- Origem: centro-base do sprite do rato
        local cx = bossRato.x + bossRato.w / 2
        local cy = bossRato.y + bossRato.h / 2
        local jx = jogador.x + jogador.w / 2
        local jy = jogador.y + jogador.h / 2
        local qtd = gosmasFase2 and 5 or 3
        dispararGosmas(cx, cy, jx, jy, qtd)
        som.tocar("ataqueRato")
    end

    -- Move gosmas e colisão com jogador
    for i = #gosmas, 1, -1 do
        local g = gosmas[i]
        g.x = g.x + g.dx * dt
        g.y = g.y + g.dy * dt

        local jx = jogador.x + jogador.w / 2
        local jy = jogador.y + jogador.h / 2
        local dist = math.sqrt((g.x - jx) ^ 2 + (g.y - jy) ^ 2)
        if dist < g.r + 16 then
            combate.receberDano(jogador, 15)
            table.remove(gosmas, i)
        elseif g.x < -200 or g.x > 3000 or g.y < -200 or g.y > 3000 then
            table.remove(gosmas, i)
        end
    end

    -- Atira bola de gosma que vira poça (fase 3: 50% de vida)
    if gosmasFase3 and chegou then
        timerPoca = timerPoca + dt
        if timerPoca >= intervaloPoca then
            timerPoca = 0
            local jx = jogador.x + jogador.w / 2
            local jy = jogador.y + jogador.h / 2
            -- Posição da poça atirando no jogador
            local alvoX = jx
            local alvoY = jy
            -- Bola voando
            table.insert(pocas, {
                x = bossRato.x + bossRato.w / 2,
                y = bossRato.y + bossRato.h / 2,
                alvoX = alvoX,
                alvoY = alvoY,
                chegou = false,
                timer = 2.0,
                r = 30,
                dx = 0,
                dy = 0,
            })
            -- Calcula direção
            local p = pocas[#pocas]
            local ddx = alvoX - p.x
            local ddy = alvoY - p.y
            local dist = math.sqrt(ddx * ddx + ddy * ddy)
            if dist > 0 then
                p.dx = (ddx / dist) * 400
                p.dy = (ddy / dist) * 400
            end
            som.tocar("ataqueRato")
        end
    end

    -- Atualiza poças
    for i = #pocas, 1, -1 do
        local p = pocas[i]
        if not p.chegou then
            p.x = p.x + p.dx * dt
            p.y = p.y + p.dy * dt
            local ddx = p.alvoX - p.x
            local ddy = p.alvoY - p.y
            if math.sqrt(ddx * ddx + ddy * ddy) < 20 then
                p.x = p.alvoX
                p.y = p.alvoY
                p.chegou = true
            end
        else
            p.timer = p.timer - dt
            -- Dano ao jogador
            local jx = jogador.x + jogador.w / 2
            local jy = jogador.y + jogador.h / 2
            if math.sqrt((p.x-jx)^2 + (p.y-jy)^2) < p.r * 2 + 12 then
                combate.receberDano(jogador, 8)
            end
            if p.timer <= 0 then
                table.remove(pocas, i)
            end
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
                bossRato.receberDano(p.dano or 8)
                table.remove(listaProjeteis, i)
            end
        end
    end
end

function bossRato.verificarDanoEspada(jogador)
    if not bossRato.ativo or bossRato.vida <= 0 then return end
    if jogador.arma ~= "espada" or jogador.anim.estado ~= "atacando" then return end
    if timerCooldownEspada > 0 then return end

    local sx = jogador.x + (jogador.virandoDireita and jogador.w or -40)
    local sy = jogador.y
    if sx < bossRato.x + bossRato.w and sx + 50 > bossRato.x and
        sy < bossRato.y + bossRato.h and sy + jogador.h > bossRato.y then
        bossRato.receberDano(15)
        timerCooldownEspada = cooldownEspada
    end
end

function bossRato.draw()
    if not bossRato.ativo and not bossRato.derrotado then return end

    if mostrarSprite and frames[frameAtual] then
        local img = frames[frameAtual]
        local escala = bossRato.w / img:getWidth()
        if invencivel and shaderBranco then
            LG.setShader(shaderBranco)
        end

        local drawX = bossRato.x
        local drawY = bossRato.y

        if bossRato.derrotado then
            -- Efeito de tremor (shake)
            drawX = drawX + love.math.random(-6, 6)
            drawY = drawY + love.math.random(-6, 6)

            -- Efeito de piscar vermelho/branco
            local flashRed = math.floor(love.timer.getTime() * 15) % 2 == 0
            if flashRed then
                LG.setColor(1, 0.2, 0.2, 1)
            else
                LG.setColor(1, 1, 1, 1)
            end
        else
            LG.setColor(1, 1, 1)
        end

        LG.draw(img, drawX, drawY, 0, escala, escala)
        LG.setShader()
    end

    -- Gosmas
    for _, g in ipairs(gosmas) do
        LG.setColor(0.1, 0.8, 0.1, 0.4)
        LG.circle("fill", g.x, g.y, g.r * 1.8)
        LG.setColor(0.2, 1, 0.2, 1)
        LG.circle("fill", g.x, g.y, g.r)
        LG.setColor(0.7, 1, 0.7, 0.8)
        LG.circle("fill", g.x - g.r * 0.3, g.y - g.r * 0.3, g.r * 0.35)
    end

    -- Poças
    for _, p in ipairs(pocas) do
        if not p.chegou then
            -- Bola voando
            LG.setColor(1, 0.8, 0.0, 0.9)
            LG.circle("fill", p.x, p.y, 12)
        else
            -- Poça no chão
            local alpha = math.min(1, p.timer / 0.5)
            LG.setColor(0.9, 0.7, 0.0, 0.6 * alpha)
            LG.ellipse("fill", p.x, p.y, p.r * 2, p.r)
            LG.setColor(1, 1, 0.3, 0.4 * alpha)
            LG.ellipse("fill", p.x, p.y, p.r * 1.2, p.r * 0.6)
        end
    end

    -- Explosões durante derrota
    if bossRato.derrotado then
        local t = 2.0 - bossRato.timerDerrota
        love.math.setRandomSeed(12345)
        for i = 1, 6 do
            local rx = bossRato.x + bossRato.w/2 + love.math.random(-120, 120)
            local ry = bossRato.y + bossRato.h/2 + love.math.random(-120, 120)
            local maxRadius = love.math.random(40, 80)
            local delay = (i - 1) * 0.25
            if t > delay then
                local progress = (t - delay) / 0.6
                if progress > 0 and progress < 1 then
                    local r = progress * maxRadius
                    LG.setColor(1, 0.6, 0.1, 0.7 * (1 - progress))
                    LG.circle("fill", rx, ry, r)
                    LG.setColor(1, 0.9, 0.3, 0.9 * (1 - progress))
                    LG.circle("line", rx, ry, r)
                end
            end
        end
        love.math.setRandomSeed(os.time())
    end

    LG.setColor(1, 1, 1)
end

return bossRato
