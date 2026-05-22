local portais = {}

portais.lista = {}

require "constantes"

local sheet
local quads = {}
local FRAME_W = 210
local FRAME_H = 280
local totalFrames = 8
local frameAtual = 1
local timer = 0
local fps = 12

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

    -- Colisão
    for _, portal in ipairs(portais.lista) do
        local colidiu =
            jogador.x < portal.x + portal.w and
            jogador.x + jogador.w > portal.x and
            jogador.y < portal.y + portal.h and
            jogador.y + jogador.h > portal.y

        if colidiu then
            trocarMapa(portal.destino, portal.spawnX, portal.spawnY)
            break
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
            spawnY  = obj.properties.spawnY
        })
    end
end

function portais.draw()
    if not sheet then return end

    LG.setColor(1, 1, 1)
    for _, portal in ipairs(portais.lista) do
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

return portais