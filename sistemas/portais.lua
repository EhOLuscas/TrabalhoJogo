local portais = {}

portais.lista = {}

require "constantes"
local som = require "sistemas.som"

local sheet
local quads = {}
local FRAME_W = 210
local FRAME_H = 280
local totalFrames = 8
local frameAtual = 1
local timer = 0
local fps = 12

local function isPortalAtivo(portal)
    local gerenciadorMapas = require "sistemas.gerenciadorMapas"
    local mapaNome = gerenciadorMapas.atual and gerenciadorMapas.atual.nome
    if mapaNome == "fase1" and portal.destino == "passagem" then
        local bossPolvo = require "entidades.bossPolvo"
        return bossPolvo.morto
    end
    return true
end

function portais.carregarSprite()
    sheet = LG.newImage("sprites/portal-spritesheet.png")
    local sw = sheet:getWidth()
    local sh = sheet:getHeight()

    for i = 0, totalFrames - 1 do
        quads[i + 1] = LG.newQuad(
            i * FRAME_W, 0,
            FRAME_W, FRAME_H,
            sw, sh
        )
    end
end

function portais.update(jogador, trocarMapa, dt)
    -- Animação
    timer = timer + dt
    if timer >= 1 / fps then
        timer = 0
        frameAtual = frameAtual + 1
        if frameAtual > totalFrames then
            frameAtual = 1
        end
    end

    -- Colisão (apenas se o portal estiver ativo)
    for _, portal in ipairs(portais.lista) do
        if isPortalAtivo(portal) then
            local colidiu =
                jogador.x < portal.x + portal.w and
                jogador.x + jogador.w > portal.x and
                jogador.y < portal.y + portal.h and
                jogador.y + jogador.h > portal.y

            if colidiu then
                som.tocar("passarFase")
                trocarMapa(portal.destino, portal.spawnX, portal.spawnY)
                break
            end
        end
    end
end

function portais.carregar(mapa)
    portais.lista = {}
    local camada = mapa.layers["portais"]
    if not camada then return end

    for _, obj in ipairs(camada.objects) do
        table.insert(portais.lista, {
            x = obj.x,
            y = obj.y,
            w = obj.width,
            h = obj.height,
            destino = obj.properties.destino,
            spawnX  = obj.properties.spawnX,
            spawnY  = obj.properties.spawnY,
            invisivel = obj.properties.invisivel or (obj.properties.destino == "fase1")
        })
    end
end

function portais.draw()
    if not sheet then return end

    -- Salva o blend mode atual
    local oldBlend, oldAlpha = LG.getBlendMode()
    
    -- Define blend mode aditivo para o efeito de brilho mágico
    LG.setBlendMode("add")

    for _, portal in ipairs(portais.lista) do
        if not portal.invisivel and isPortalAtivo(portal) then
            -- Efeito pulsar de opacidade (respiração mágica)
            local pulse = 0.82 + 0.18 * math.sin(love.timer.getTime() * 4.5)
            LG.setColor(1, 1, 1, pulse)

            local escalaX = portal.w / FRAME_W
            local escalaY = portal.h / FRAME_H
            LG.draw(
                sheet,
                quads[frameAtual],
                portal.x,
                portal.y,
                0,
                escalaX,
                escalaY
            )
        end
    end

    -- Restaura o blend mode e cor originais
    LG.setBlendMode(oldBlend, oldAlpha)
    LG.setColor(1, 1, 1, 1)
end

return portais