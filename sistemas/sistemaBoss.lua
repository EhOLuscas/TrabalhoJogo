require "constantes"
local gerenciadorMapas = require "sistemas.gerenciadorMapas"

local sistemaBoss      = {}

-- ─────────────────────────────────────────────
-- Sprites
-- ─────────────────────────────────────────────
local spritesPolvo     = {}
local spritesRato      = {}

-- Shader de flash branco (dano recebido)
local shaderBranco

-- ─────────────────────────────────────────────
-- Estado do boss ativo
-- ─────────────────────────────────────────────
local boss             = {
    ativo                  = false,
    tipo                   = "", -- "polvo" | "rato"
    x                      = 0,
    y                      = 0,
    w                      = 80,
    h                      = 80,

    -- Vida
    vida                   = 0,
    vidaMax                = 0,

    -- Fase (1 ou 2; muda em 50 % de vida)
    fase                   = 1,

    -- Animação
    frame                  = 1,
    timer                  = 0,
    fps                    = 8,
    totalFrames            = 16,

    -- Direção (vira para o jogador)
    virandoDireita         = false,

    -- Flash de dano
    flashTimer             = 0,
    flashDuracao           = 0.12,

    -- Invencibilidade pós-dano
    invencivel             = false,
    timerInvencivel        = 0,
    duracaoInvencivel      = 0.35,

    -- Cooldown de ataque do boss
    timerAtaque            = 0,
    cooldownAtaque         = 2.0,

    -- Projéteis do boss (rato)
    projeteis              = {},

    -- Ataque de tentáculo (polvo) – hitbox temporária
    tentaculoAtivo         = false,
    tentaculoTimer         = 0,
    tentaculoDuracao       = 0.35,
    tentaculoCooldownTotal = 2.2,

    -- Dano de espada: janela de frames válidos
    janelaEspadaAtivo      = false,
    janelaEspadaTimer      = 0,

    -- Derrotado
    derrotado              = false,
    timerDerrota           = 0,

    -- Escala de desenho
    escala                 = 1.5,

    tentaculosHitbox       = {},
}

-- Projétil do boss
local velProjetilBoss  = 240

-- ─────────────────────────────────────────────
-- Carregamento
-- ─────────────────────────────────────────────
function sistemaBoss.carregar()
    spritesPolvo = {}
    for i = 1, 16 do
        local path = "sprites/BOSS/polvo/image_" .. i .. ".png"
        local ok, img = pcall(LG.newImage, path)
        if ok then table.insert(spritesPolvo, img) end
    end

    spritesRato = {}
    for i = 1, 16 do
        local path = "sprites/BOSS/rato/image_" .. i .. ".png"
        local ok, img = pcall(LG.newImage, path)
        if ok then table.insert(spritesRato, img) end
    end

    shaderBranco = LG.newShader([[
        vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screenCoords) {
            vec4 pixel = Texel(tex, texCoords);
            if (pixel.a < 0.01) discard;
            return vec4(1.0, 1.0, 1.0, pixel.a);
        }
    ]])
end

-- ─────────────────────────────────────────────
-- Inicializar boss
-- ─────────────────────────────────────────────
function sistemaBoss.iniciar(tipo, x, y)
    boss.ativo             = true
    boss.tipo              = tipo
    boss.x                 = x
    boss.y                 = y
    boss.frame             = 1
    boss.timer             = 0
    boss.fase              = 1
    boss.derrotado         = false
    boss.timerDerrota      = 0
    boss.invencivel        = false
    boss.timerInvencivel   = 0
    boss.flashTimer        = 0
    boss.projeteis         = {}
    boss.timerAtaque       = 1.5
    boss.tentaculoAtivo    = false
    boss.tentaculoTimer    = 0
    boss.janelaEspadaAtivo = false
    boss.janelaEspadaTimer = 0

    if tipo == "polvo" then
        boss.vida                   = 300
        boss.vidaMax                = 300
        boss.w                      = 90
        boss.h                      = 90
        boss.cooldownAtaque         = 2.2
        boss.tentaculoCooldownTotal = 2.2
        boss.fps                    = 8
        boss.escala                 = 1.6
        boss.totalFrames            = #spritesPolvo
    else -- rato
        boss.vida           = 220
        boss.vidaMax        = 220
        boss.w              = 70
        boss.h              = 70
        boss.cooldownAtaque = 1.5
        boss.fps            = 10
        boss.escala         = 1.4
        boss.totalFrames    = #spritesRato
    end
end

function sistemaBoss.reset()
    boss.ativo          = false
    boss.derrotado      = false
    boss.projeteis      = {}
    boss.tentaculoAtivo = false
end

-- ─────────────────────────────────────────────
-- Disparo do rato (longa distância)
-- ─────────────────────────────────────────────
local function dispararRato(alvoX, alvoY)
    local cx = boss.x + boss.w / 2
    local cy = boss.y + boss.h / 2
    local dx = alvoX - cx
    local dy = alvoY - cy
    local d  = math.sqrt(dx * dx + dy * dy)
    if d == 0 then return end

    local qtd     = (boss.fase == 2) and 3 or 1
    local angBase = math.atan2(dy, dx)
    local spread  = math.rad(18)

    for i = 1, qtd do
        local ang = angBase + (i - (qtd + 1) / 2) * spread
        table.insert(boss.projeteis, {
            x  = cx,
            y  = cy,
            dx = math.cos(ang) * velProjetilBoss,
            dy = math.sin(ang) * velProjetilBoss,
        })
    end
end

-- ─────────────────────────────────────────────
-- Atualização principal
-- ─────────────────────────────────────────────
function sistemaBoss.atualizar(dt, jogador, combate, projeteis)
    if not boss.ativo then return end

    -- ── Animação ──────────────────────────────
    boss.timer = boss.timer + dt
    if boss.timer >= 1.0 / boss.fps then
        boss.timer = boss.timer - 1.0 / boss.fps
        boss.frame = boss.frame + 1
        if boss.frame > boss.totalFrames then
            boss.frame = 1
        end
    end

    if boss.derrotado then
        boss.timerDerrota = boss.timerDerrota + dt
        if boss.timerDerrota >= 1.5 then
            boss.ativo = false
        end
        return
    end

    -- ── Invencibilidade pós-dano ──────────────
    if boss.invencivel then
        boss.timerInvencivel = boss.timerInvencivel - dt
        if boss.timerInvencivel <= 0 then
            boss.invencivel = false
        end
    end

    -- Flash branco
    if boss.flashTimer > 0 then
        boss.flashTimer = boss.flashTimer - dt
    end

    -- ── Mudança de fase (50% HP) ──────────────
    if boss.fase == 1 and boss.vida <= boss.vidaMax * 0.5 then
        boss.fase = 2
        boss.cooldownAtaque = boss.cooldownAtaque * 0.6
        boss.tentaculoCooldownTotal = boss.tentaculoCooldownTotal * 0.6
    end

    -- ── Boss FICA PARADO – apenas vira para o jogador ──
    local cx            = boss.x + boss.w / 2
    local cy            = boss.y + boss.h / 2
    local px            = jogador.x + jogador.w / 2
    local py            = jogador.y + jogador.h / 2
    local dx            = px - cx
    local dy            = py - cy
    local d             = math.sqrt(dx * dx + dy * dy)

    boss.virandoDireita = (dx > 0)

    -- ── Ataques por tipo ──────────────────────
    boss.timerAtaque    = boss.timerAtaque - dt

    if boss.tipo == "polvo" then
        -- POLVO: ataque de tentáculo (corpo a corpo)
        if boss.timerAtaque <= 0 then
            boss.timerAtaque = boss.tentaculoCooldownTotal
            boss.tentaculoAtivo = true
            boss.tentaculoTimer = boss.tentaculoDuracao
        end

        if boss.tentaculoAtivo then
            boss.tentaculoTimer = boss.tentaculoTimer - dt
            if boss.tentaculoTimer <= 0 then
                boss.tentaculoAtivo = false
            end

            -- Hitbox das pontas: metade inferior da sprite (onde ficam os tentáculos)
            -- Cria múltiplas hitboxes dos tentáculos
            boss.tentaculosHitbox  = {}

            local e                = boss.escala

            local quantidade       = 5
            local espacamento      = 55 * e

            local larguraTentaculo = 38 * e
            local alturaTentaculo  = 65 * e

            local inicioX          = boss.x + (boss.w / 2) - ((quantidade - 1) * espacamento) / 2
            local posY             = boss.y + boss.h + 5

            for i = 1, quantidade do
                table.insert(boss.tentaculosHitbox, {
                    x = inicioX + (i - 1) * espacamento,
                    y = posY,
                    w = larguraTentaculo,
                    h = alturaTentaculo
                })
            end

            local pLeft   = jogador.x
            local pRight  = jogador.x + jogador.w
            local pTop    = jogador.y
            local pBottom = jogador.y + jogador.h

            for _, h in ipairs(boss.tentaculosHitbox) do
                if pRight >= h.x and
                    pLeft <= h.x + h.w and
                    pBottom >= h.y and
                    pTop <= h.y + h.h then
                    local dano = (boss.fase == 2) and 18 or 12
                    combate.receberDano(jogador, dano)

                    break
                end
            end
        end
    else
        -- RATO: ataque à longa distância (projéteis)
        if boss.timerAtaque <= 0 then
            boss.timerAtaque = boss.cooldownAtaque
            dispararRato(px, py)
        end
    end

    -- ── Atualiza projéteis do rato ─────────────
    for i = #boss.projeteis, 1, -1 do
        local p = boss.projeteis[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt

        if p.x >= jogador.x and p.x <= jogador.x + jogador.w and
            p.y >= jogador.y and p.y <= jogador.y + jogador.h then
            combate.receberDano(jogador, (boss.fase == 2) and 15 or 10)
            table.remove(boss.projeteis, i)
        elseif p.x < -800 or p.x > 12000 or p.y < -800 or p.y > 12000 then
            table.remove(boss.projeteis, i)
        end
    end

    -- ── Receber dano do jogador (espada) ──────
    if jogador.anim.estado == "atacando" and jogador.arma == "espada" then
        if not boss.janelaEspadaAtivo then
            boss.janelaEspadaAtivo = true
            boss.janelaEspadaTimer = 0.5
        end
    else
        boss.janelaEspadaAtivo = false
        boss.janelaEspadaTimer = 0
    end

    if boss.janelaEspadaAtivo then
        boss.janelaEspadaTimer = boss.janelaEspadaTimer - dt
        if boss.janelaEspadaTimer <= 0 then
            boss.janelaEspadaAtivo = false
        end

        if not boss.invencivel then
            local sx, sy, sw, sh
            if jogador.virandoDireita then
                sx = jogador.x + jogador.w
                sy = jogador.y - 12
                sw = 60
                sh = jogador.h + 24
            else
                sx = jogador.x - 60
                sy = jogador.y - 12
                sw = 60
                sh = jogador.h + 24
            end

            local acertouCorpo = (sx < boss.x + boss.w and boss.x < sx + sw and
                sy < boss.y + boss.h and boss.y < sy + sh)

            local acertouTentaculo = false

            if boss.tipo == "polvo" and boss.tentaculoAtivo then
                for _, h in ipairs(boss.tentaculosHitbox) do
                    if sx < h.x + h.w and
                        h.x < sx + sw and
                        sy < h.y + h.h and
                        h.y < sy + sh then
                        acertouTentaculo = true
                        break
                    end
                end
            end

            if acertouCorpo or acertouTentaculo then
                sistemaBoss.receberDano(20)
                boss.janelaEspadaAtivo = false
            end
        end
    end

    -- ── Receber dano do jogador (projéteis do canhão) ──
    if not boss.invencivel and projeteis and projeteis.lista then
        for i = #projeteis.lista, 1, -1 do
            local p = projeteis.lista[i]

            local acertouCorpo = (p.x >= boss.x and p.x <= boss.x + boss.w and
                p.y >= boss.y and p.y <= boss.y + boss.h)

            local acertouTentaculo = false

            if boss.tipo == "polvo" and boss.tentaculoAtivo then
                for _, h in ipairs(boss.tentaculosHitbox) do
                    if p.x >= h.x and
                        p.x <= h.x + h.w and
                        p.y >= h.y and
                        p.y <= h.y + h.h then
                        acertouTentaculo = true
                        break
                    end
                end
            end

            if acertouCorpo or acertouTentaculo then
                table.remove(projeteis.lista, i)
                sistemaBoss.receberDano(35)
                break
            end
        end
    end
end

-- ─────────────────────────────────────────────
-- Receber dano
-- ─────────────────────────────────────────────
function sistemaBoss.receberDano(quantidade)
    if boss.invencivel or boss.derrotado then return end

    boss.vida = math.max(0, boss.vida - quantidade)
    boss.flashTimer = boss.flashDuracao
    boss.invencivel = true
    boss.timerInvencivel = boss.duracaoInvencivel

    if boss.vida <= 0 then
        boss.derrotado      = true
        boss.timerDerrota   = 0
        boss.projeteis      = {}
        boss.tentaculoAtivo = false
    end
end

-- ─────────────────────────────────────────────
-- Verificação pública
-- ─────────────────────────────────────────────
function sistemaBoss.estaAtivo()
    return boss.ativo
end

function sistemaBoss.foiDerrotado()
    return boss.derrotado and not boss.ativo
end

-- ─────────────────────────────────────────────
-- Desenho
-- ─────────────────────────────────────────────
function sistemaBoss.draw()
    if not boss.ativo then return end

    -- Projéteis do rato
    LG.setColor(1, 0.3, 0.1)
    for _, p in ipairs(boss.projeteis) do
        LG.circle("fill", p.x, p.y, 7)
    end
    LG.setColor(1, 1, 1)

    -- Indicador visual do tentáculo: metade inferior da sprite
    if boss.tentaculoAtivo and boss.tipo == "polvo" then
        local e  = boss.escala
        local tx = boss.x - (512 * e - boss.w) / 2
        local ty = boss.y + boss.h / 2
        local tw = 512 * e
        local th = 512 * e / 2

        LG.setColor(1, 0.1, 0.1, 0.22)
        LG.setColor(1, 0.2, 0.2, 0.8)
        LG.setLineWidth(2)
        LG.setLineWidth(1)
        LG.setColor(1, 1, 1)
        for _, h in ipairs(boss.tentaculosHitbox) do
            LG.setColor(1, 0.1, 0.1, 0.22)
            LG.rectangle("fill", h.x, h.y, h.w, h.h)

            LG.setColor(1, 0.2, 0.2, 0.8)
            LG.rectangle("line", h.x, h.y, h.w, h.h)
        end
    end

    -- Sprite do boss
    local sprites = (boss.tipo == "polvo") and spritesPolvo or spritesRato
    local img = sprites[boss.frame]
    if not img then return end

    local flash = boss.flashTimer > 0
    if flash and shaderBranco then
        LG.setShader(shaderBranco)
    end

    local e  = boss.escala
    local iw = img:getWidth() * e
    local ih = img:getHeight() * e
    local ox = (iw - boss.w) / 2
    local oy = (ih - boss.h) / 2

    LG.setColor(1, 1, 1)
    if boss.virandoDireita then
        LG.draw(img, boss.x - ox, boss.y - oy, 0, e, e)
    else
        LG.draw(img, boss.x + boss.w + ox, boss.y - oy, 0, -e, e)
    end

    LG.setShader()
end

-- ─────────────────────────────────────────────
-- HUD da barra de vida do boss (chamado pelo hud.lua, fora da câmera)
-- ─────────────────────────────────────────────
function sistemaBoss.drawHudBoss()
    if not boss.ativo or boss.derrotado then return end

    local sw   = LG.getWidth()
    local sh   = LG.getHeight()
    local barW = 400
    local barH = 22
    local bx   = (sw - barW) / 2
    local by   = sh - 48

    LG.setColor(0.08, 0.08, 0.08, 0.92)
    LG.rectangle("fill", bx - 4, by - 28, barW + 8, barH + 36, 6, 6)

    local nome = (boss.tipo == "polvo") and "POLVO ABISSAL" or "RATO SOMBRIO"
    local faseLabel = (boss.fase == 2) and "  ★ FÚRIA ★" or ""
    LG.setColor(1, 1, 1, 1)
    LG.print(nome .. faseLabel, bx, by - 22)

    LG.setColor(0.25, 0.25, 0.25, 1)
    LG.rectangle("fill", bx, by, barW, barH, 4, 4)

    local pct = math.max(0, boss.vida / boss.vidaMax)
    local cor = (boss.fase == 2) and { 1, 0.25, 0.1, 1 } or { 0.85, 0.1, 0.1, 1 }
    LG.setColor(unpack(cor))
    LG.rectangle("fill", bx, by, barW * pct, barH, 4, 4)

    LG.setColor(0.75, 0.75, 0.75, 0.9)
    LG.setLineWidth(2)
    LG.rectangle("line", bx - 4, by - 28, barW + 8, barH + 36, 6, 6)
    LG.setLineWidth(1)

    LG.setColor(1, 1, 1)
end

return sistemaBoss
