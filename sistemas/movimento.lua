-- ============================================================
-- sistemas/movimento.lua
-- Processa a entrada do teclado (WASD) para mover o jogador,
-- atualiza sua direção com base na posição do mouse,
-- e resolve colisões via bump.
-- Pausa o movimento durante diálogos ou teletransporte.
-- ============================================================

require "constantes"

local movimento = {}

function movimento.atualizar(dt, jogador, world, camera)
    -- Congela movimento durante diálogo ou animação de teletransporte
    local dialogo = require "sistemas.dialogo"
    if dialogo.ativo or jogador.teleportando then
        jogador.updateAnim(dt, false, false)
        return
    end

    local dx     = 0
    local dy     = 0
    local movendo = false

    if LK.isDown("d") or LK.isDown("right") then dx =  jogador.velocidade * dt; movendo = true end
    if LK.isDown("a") or LK.isDown("left") then dx = -jogador.velocidade * dt; movendo = true end
    if LK.isDown("w") or LK.isDown("up") then dy = -jogador.velocidade * dt; movendo = true end
    if LK.isDown("s") or LK.isDown("down") then dy =  jogador.velocidade * dt; movendo = true end

    -- Vira o sprite para o lado em que o mouse está em relação ao jogador
    local mx          = love.mouse.getX()
    local jogadorTelX = jogador.x - camera.x
    jogador.virandoDireita = (mx > jogadorTelX)

    -- Move o jogador resolvendo colisões com bump
    local actualX, actualY = world:move(jogador, jogador.x + dx, jogador.y + dy)
    jogador.x = actualX
    jogador.y = actualY

    -- Atualiza a animação (idle, andando ou atacando)
    jogador.updateAnim(dt, movendo, jogador.anim.estado == "atacando")
end

return movimento
