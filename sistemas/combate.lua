require "constantes"

local jogador = require "entidades.jogador"

local combate = {}

local custoAtaque = 20  -- energia gasta por ataque

function combate.atualizar(dt, jogador, camera, projeteis)
    jogador.updateDano(dt)
    -- Regenera energia
    if jogador.energia < jogador.energiaMax then
        jogador.energia = math.min(
            jogador.energiaMax,
            jogador.energia + jogador.energiaRegen * dt
        )
    end

    if jogador.arma == "canhao" then
        custoAtaque = 10
    else
        custoAtaque = 20
    end

    if love.mouse.isDown(1) and jogador.anim.estado ~= "atacando" and jogador.energia >= custoAtaque then
        jogador.anim.estado = "atacando"
        jogador.anim.frame = 1
        jogador.anim.timer = 0
        jogador.energia = jogador.energia - custoAtaque

        if jogador.arma == "canhao" and projeteis then
            local mx, my = love.mouse.getPosition()
            local centroX = jogador.x + jogador.w / 2
            local centroY = jogador.y + jogador.h / 2
            projeteis.disparar(centroX, centroY, mx, my, camera.x, camera.y)
        end
    end
end

function combate.receberDano(jogador, quantidade)
    if jogador.invencivel then return end

    jogador.vida = math.max(0, jogador.vida - quantidade)
    jogador.invencivel = true
    jogador.timerInvencivel = jogador.duracaoInvencivel
    jogador.timerPiscar = jogador.intervaloPiscar
    jogador.mostrarSprite = true
end

return combate