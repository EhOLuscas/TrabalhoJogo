require "constantes"

local combate = {}

function combate.atualizar(dt, jogador, camera, projeteis)
    if love.mouse.isDown(1) and jogador.anim.estado ~= "atacando" then
        jogador.anim.estado = "atacando"
        jogador.anim.frame = 1
        jogador.anim.timer = 0

        if jogador.arma == "canhao" and projeteis then
            local mx, my = love.mouse.getPosition()
            local centroX = jogador.x + jogador.w / 2
            local centroY = jogador.y + jogador.h / 2
            projeteis.disparar(centroX, centroY, mx, my, camera.x, camera.y)
        end
    end
end

return combate