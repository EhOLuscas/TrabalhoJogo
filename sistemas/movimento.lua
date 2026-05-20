require "constantes"

local movimento = {}

function movimento.atualizar(dt, jogador, world, camera)
    local dx = 0
    local dy = 0
    local movendo = false

    if LK.isDown("d") then
        dx = jogador.velocidade * dt
        movendo = true
    end

    if LK.isDown("a") then
        dx = -jogador.velocidade * dt
        movendo = true
    end

    if LK.isDown("w") then
        dy = -jogador.velocidade * dt
        movendo = true
    end

    if LK.isDown("s") then
        dy = jogador.velocidade * dt
        movendo = true
    end

    -- Vira o personagem em direção ao mouse
    local mx = love.mouse.getX()
    local jogadorTelX = jogador.x - camera.x
    jogador.virandoDireita = mx > jogadorTelX

    local goalX = jogador.x + dx
    local goalY = jogador.y + dy
    local actualX, actualY = world:move(jogador, goalX, goalY)
    jogador.x = actualX
    jogador.y = actualY

    jogador.updateAnim(dt, movendo, jogador.anim.estado == "atacando")
end

return movimento