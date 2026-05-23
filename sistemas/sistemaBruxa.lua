require "constantes"
local gerenciadorMapas = require "sistemas.gerenciadorMapas"
local som = require "sistemas.som"

local sistemaBruxa = {}

local spritesBruxa = {}
local spritesGarrafa = {}

-- Witch state
local bruxa = {
    ativa = false,
    x = 0,
    y = 0,
    w = 40,
    h = 50,
    vx = 0,
    frame = 1,
    timer = 0,
    fps = 12,
    viradaDireita = true
}

-- Active potions list
local garrafas = {}

-- Health tracking for transition below 50 HP
local vidaAnterior = 100

-- Scales for drawing
local escalaWitch = 1.2
local escalaGarrafa = 1.0

function sistemaBruxa.carregar()
    spritesBruxa = {}
    for i = 1, 16 do
        local path = "sprites/bruxa-cura/image_" .. i .. ".png"
        local success, img = pcall(LG.newImage, path)
        if success then
            table.insert(spritesBruxa, img)
        end
    end

    spritesGarrafa = {}
    for i = 1, 16 do
        local path = "sprites/garrafa-cura/image_" .. i .. ".png"
        local success, img = pcall(LG.newImage, path)
        if success then
            table.insert(spritesGarrafa, img)
        end
    end
end

function sistemaBruxa.reset()
    bruxa.ativa = false
    garrafas = {}
    -- Initialize vidaAnterior so we don't immediately trigger on level load if health is already low
    local jogador = require "entidades.jogador"
    vidaAnterior = jogador.vida
end

function sistemaBruxa.dropPotion(x, y)
    table.insert(garrafas, {
        x = x - 12, -- Center the 24w potion box
        y = y - 16, -- Center the 32h potion box
        w = 24,
        h = 32,
        frame = 1,
        timer = 0,
        fps = 12
    })
end

function sistemaBruxa.atualizar(dt, jogador, camera, projeteis)
    local mapa = gerenciadorMapas.atual
    if not mapa or (mapa.nome ~= "fase1" and mapa.nome ~= "fase2") then
        -- Only active on fase1 and fase2
        vidaAnterior = jogador.vida
        return
    end

    local larguraTela = LG.getWidth()

    -- 1. Check health transition: drops to below 50 HP (from >= 50 HP)
    if vidaAnterior >= 50 and jogador.vida < 50 and not bruxa.ativa then
        -- Spawn the witch
        if jogador.virandoDireita then
            -- Spawn on the right of the screen running left
            bruxa.x = camera.x + larguraTela + 40
            bruxa.vx = -220
            bruxa.viradaDireita = false
        else
            -- Spawn on the left of the screen running right
            bruxa.x = camera.x - 100
            bruxa.vx = 220
            bruxa.viradaDireita = true
        end
        -- Spawn at the player's Y level
        bruxa.y = jogador.y
        bruxa.ativa = true
        bruxa.frame = 1
        bruxa.timer = 0
        som.tocar("bruxa")
    end

    vidaAnterior = jogador.vida

    -- 2. Update Witch
    if bruxa.ativa then
        bruxa.x = bruxa.x + bruxa.vx * dt

        -- Update Witch animation
        if #spritesBruxa > 0 then
            bruxa.timer = bruxa.timer + dt
            if bruxa.timer >= 1.0 / bruxa.fps then
                bruxa.timer = bruxa.timer - (1.0 / bruxa.fps)
                bruxa.frame = bruxa.frame + 1
                if bruxa.frame > #spritesBruxa then
                    bruxa.frame = 1
                end
            end
        end

        -- Check if Witch is off-screen
        if (bruxa.vx > 0 and bruxa.x > camera.x + larguraTela + 120) or
           (bruxa.vx < 0 and bruxa.x < camera.x - 120) then
            bruxa.ativa = false
        end

        -- Check if Witch got hit by player's attacks
        local bx, by, bw, bh = bruxa.x, bruxa.y, bruxa.w, bruxa.h
        local hit = false

        -- Check Cannon Projectiles
        if projeteis and projeteis.lista then
            for i = #projeteis.lista, 1, -1 do
                local p = projeteis.lista[i]
                if p.x >= bx and p.x <= bx + bw and p.y >= by and p.y <= by + bh then
                    table.remove(projeteis.lista, i)
                    hit = true
                    break
                end
            end
        end

        -- Check Sword Attack (if jogador is in "atacando" state and wielding "espada")
        if not hit and jogador.anim.estado == "atacando" and jogador.arma == "espada" then
            local sx, sy, sw, sh
            if jogador.virandoDireita then
                sx = jogador.x + jogador.w
                sy = jogador.y - 12
                sw = 50
                sh = jogador.h + 24
            else
                sx = jogador.x - 50
                sy = jogador.y - 12
                sw = 50
                sh = jogador.h + 24
            end

            -- AABB collision overlap check
            if sx < bx + bw and bx < sx + sw and sy < by + bh and by < sy + sh then
                hit = true
            end
        end

        -- Handle Witch hit event
        if hit then
            sistemaBruxa.dropPotion(bx + bw / 2, by + bh / 2)
            bruxa.ativa = false
        end
    end

    -- 3. Update active potions
    for i = #garrafas, 1, -1 do
        local g = garrafas[i]

        -- Update potion animation
        if #spritesGarrafa > 0 then
            g.timer = g.timer + dt
            if g.timer >= 1.0 / g.fps then
                g.timer = g.timer - (1.0 / g.fps)
                g.frame = g.frame + 1
                if g.frame > #spritesGarrafa then
                    g.frame = 1
                end
            end
        end

        -- Check player pickup collision (AABB overlap)
        if jogador.x < g.x + g.w and g.x < jogador.x + jogador.w and
           jogador.y < g.y + g.h and g.y < jogador.y + jogador.h then
            -- Heal the player
            jogador.vida = math.min(jogador.vidaMax, jogador.vida + 40)
            table.remove(garrafas, i)
        end
    end
end

function sistemaBruxa.draw()
    -- Render Witch
    if bruxa.ativa then
        local img = spritesBruxa[bruxa.frame]
        if img then
            local sw = img:getWidth() * escalaWitch
            local sh = img:getHeight() * escalaWitch
            local ox = (sw - bruxa.w) / 2
            local oy = (sh - bruxa.h) / 2

            LG.setColor(1, 1, 1)
            if not bruxa.viradaDireita then
                -- Facing left, flip horizontally
                LG.draw(img, bruxa.x + bruxa.w + ox, bruxa.y - oy, 0, -escalaWitch, escalaWitch)
            else
                -- Facing right
                LG.draw(img, bruxa.x - ox, bruxa.y - oy, 0, escalaWitch, escalaWitch)
            end
        end
    end

    -- Render Potions
    for _, g in ipairs(garrafas) do
        local img = spritesGarrafa[g.frame]
        if img then
            local sw = img:getWidth() * escalaGarrafa
            local sh = img:getHeight() * escalaGarrafa
            local ox = (sw - g.w) / 2
            local oy = (sh - g.h) / 2

            LG.setColor(1, 1, 1)
            LG.draw(img, g.x - ox, g.y - oy, 0, escalaGarrafa, escalaGarrafa)
        end
    end
end

return sistemaBruxa
