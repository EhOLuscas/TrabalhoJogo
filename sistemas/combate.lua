require "constantes"

local jogador = require "entidades.jogador"

local combate = {}

local custoAtaque -- energia gasta por ataque

function combate.atualizar(dt, jogador, camera, projeteis)
    jogador.updateDano(dt)
    -- Regenera energia
    if jogador.energia < jogador.energiaMax then
        jogador.energia = math.min(
            jogador.energiaMax,
            jogador.energia + jogador.energiaRegen * dt
        )
    end

    local dialogo = require "sistemas.dialogo"
    if dialogo.ativo or jogador.teleportando then return end

    -- Tiro consecutivo do canhão ao segurar mouse1 (botão 1)
    if jogador.arma == "canhao" and love.mouse.isDown(1) then
        custoAtaque = 20
        if jogador.anim.estado ~= "atacando" and jogador.energia >= custoAtaque then
            jogador.anim.estado = "atacando"
            jogador.anim.frame = 1
            jogador.anim.timer = 0
            jogador.energia = jogador.energia - custoAtaque

            if projeteis then
                local mx, my = love.mouse.getPosition()
                local origemX, origemY = jogador.getMuzzlePosition()
                projeteis.disparar(origemX, origemY, mx, my, camera.x, camera.y)
            end
        end
    end
end

function combate.mousepressed(button, jogador, camera, projeteis)
    local dialogo = require "sistemas.dialogo"
    if dialogo.ativo or jogador.teleportando then return end

    local custoAtaque = (jogador.arma == "canhao") and 20 or 15

    if button == 1 and jogador.anim.estado ~= "atacando" and jogador.energia >= custoAtaque then
        jogador.anim.estado = "atacando"
        jogador.anim.frame = 1
        jogador.anim.timer = 0
        jogador.energia = jogador.energia - custoAtaque

        if jogador.arma == "canhao" and projeteis then
            local mx, my = love.mouse.getPosition()
            local origemX, origemY = jogador.getMuzzlePosition()
            projeteis.disparar(origemX, origemY, mx, my, camera.x, camera.y)
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