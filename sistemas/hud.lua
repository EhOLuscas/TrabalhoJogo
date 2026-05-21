require "constantes"

local hud = {}

local imgVazio
local imgCheio
local imgCoracao

local frameCoracao = 1
local timerCoracao = 0
local fpsCoracao = 6

local totalFramesCoracao = 2

local HEART_W = 90
local HEART_H = 30

local escalaHud = 3

function hud.carregar()

    imgVazio = LG.newImage("sprites/Health Bar Empty.png")
    imgCheio = LG.newImage("sprites/Health Bar Full.png")
    imgCoracao = LG.newImage("sprites/HeartSpriteSheet.png")

    imgVazio:setFilter("nearest", "nearest")
    imgCheio:setFilter("nearest", "nearest")
    imgCoracao:setFilter("nearest", "nearest")
end

function hud.update(dt)

    -- Animação do coração
    timerCoracao = timerCoracao + dt

    if timerCoracao >= 1 / fpsCoracao then

        timerCoracao = 0

        frameCoracao = frameCoracao + 1

        if frameCoracao > totalFramesCoracao then
            frameCoracao = 1
        end
    end
end

function hud.draw(jogador)

    local x = 16
    local y = 16

    -- FUNDO ÚNICO
    LG.setColor(1, 1, 1)

    LG.draw(
        imgVazio,
        x,
        y,
        0,
        escalaHud,
        escalaHud
    )

    local barX = 27
    local barW = 60
    local halfH = imgCheio:getHeight() / 2

    -- VIDA
    local pVida = math.max(0, math.min(1, jogador.vida / jogador.vidaMax))
    local larguraVida = barW * pVida

    if larguraVida > 0 then
        local quadVida = LG.newQuad(
            barX,
            0,
            larguraVida,
            halfH,
            imgCheio:getWidth(),
            imgCheio:getHeight()
        )

        LG.setColor(1, 0.2, 0.2)

        LG.draw(
            imgCheio,
            quadVida,
            x + barX * escalaHud,
            y,
            0,
            escalaHud,
            escalaHud
        )
    end

    -- ENERGIA
    local pEnergia = math.max(0, math.min(1, jogador.energia / jogador.energiaMax))
    local larguraEnergia = barW * pEnergia

    if larguraEnergia > 0 then
        local quadEnergia = LG.newQuad(
            barX,
            halfH,
            larguraEnergia,
            halfH,
            imgCheio:getWidth(),
            imgCheio:getHeight()
        )

        LG.setColor(0.2, 0.5, 1)

        LG.draw(
            imgCheio,
            quadEnergia,
            x + barX * escalaHud,
            y + halfH * escalaHud,
            0,
            escalaHud,
            escalaHud
        )
    end

    -- -- CORAÇÃO
    -- LG.setColor(1, 1, 1)

    -- local quadCoracao = LG.newQuad(
    --     (frameCoracao - 1) * HEART_W,
    --     0,
    --     HEART_W,
    --     HEART_H,
    --     imgCoracao:getWidth(),
    --     imgCoracao:getHeight()
    -- )

    -- LG.draw(
    --     imgCoracao,
    --     quadCoracao,
    --     x,
    --     y,
    --     0,
    --     escalaHud,
    --     escalaHud
    -- )
end

return hud