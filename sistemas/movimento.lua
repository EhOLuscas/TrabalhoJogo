require "constantes"

local movimento = {}

function movimento.atualizar(dt, jogador, world)

    local dx = 0
    local dy = 0

    if LK.isDown("d") then
        dx = jogador.velocidade * dt
    end

    if LK.isDown("a") then
        dx = -jogador.velocidade * dt
    end

    if LK.isDown("w") then
        dy = -jogador.velocidade * dt
    end

    if LK.isDown("s") then
        dy = jogador.velocidade * dt
    end

    local goalX = jogador.x + dx
    local goalY = jogador.y + dy

    local actualX, actualY, cols, len =
        world:move(
            jogador,
            goalX,
            goalY
        )

    jogador.x = actualX
    jogador.y = actualY
end

return movimento