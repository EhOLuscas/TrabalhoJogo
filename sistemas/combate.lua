-- ============================================================
-- sistemas/combate.lua
-- Gerencia o combate do jogador: regeneração de energia,
-- disparo contínuo do canhão, ataque com espada e recebimento
-- de dano (com invencibilidade temporária e efeito de piscar).
-- ============================================================

require "constantes"

local som    = require "sistemas.som"
local combate = {}

-- Custo de energia por disparo do canhão (tiro contínuo ao segurar mouse1)
local CUSTO_CANHAO_CONTINUO = 25

function combate.atualizar(dt, jogador, camera, projeteis)
    -- Atualiza o timer de invencibilidade e piscar do jogador
    jogador.updateDano(dt)

    -- Regenera energia passivamente
    if jogador.energia < jogador.energiaMax then
        jogador.energia = math.min(
            jogador.energiaMax,
            jogador.energia + jogador.energiaRegen * dt
        )
    end

    -- Não processa combate se o diálogo estiver ativo ou o jogador estiver teleportando
    local dialogo = require "sistemas.dialogo"
    if dialogo.ativo or jogador.teleportando then return end

    -- Disparo contínuo do canhão ao segurar o botão esquerdo do mouse
    if jogador.arma == "canhao" and love.mouse.isDown(1) then
        if jogador.anim.estado ~= "atacando" and jogador.energia >= CUSTO_CANHAO_CONTINUO then
            jogador.anim.estado = "atacando"
            jogador.anim.frame  = 1
            jogador.anim.timer  = 0
            jogador.energia     = jogador.energia - CUSTO_CANHAO_CONTINUO

            if projeteis then
                local mx, my         = love.mouse.getPosition()
                local origemX, origemY = jogador.getMuzzlePosition()
                projeteis.disparar(origemX, origemY, mx, my, camera.x, camera.y)
                som.tocar("disparoCanhao")
            end
        end
    end
end

-- Chamado em mousepressed para um clique único de ataque
function combate.mousepressed(button, jogador, camera, projeteis)
    local dialogo = require "sistemas.dialogo"
    if dialogo.ativo or jogador.teleportando then return end

    -- Custo de energia varia por arma
    local custo = (jogador.arma == "canhao") and 20 or 15

    if button == 1 and jogador.anim.estado ~= "atacando" and jogador.energia >= custo then
        jogador.anim.estado = "atacando"
        jogador.anim.frame  = 1
        jogador.anim.timer  = 0
        jogador.energia     = jogador.energia - custo

        if jogador.arma == "canhao" then
            if projeteis then
                local mx, my         = love.mouse.getPosition()
                local origemX, origemY = jogador.getMuzzlePosition()
                projeteis.disparar(origemX, origemY, mx, my, camera.x, camera.y)
            end
            som.tocar("disparoCanhao")
        else
            som.tocar("swordAttack")
        end
    end
end

-- Aplica dano ao jogador, ativando invencibilidade temporária e efeito de piscar
function combate.receberDano(jogador, quantidade)
    if jogador.invencivel then return end

    jogador.vida          = math.max(0, jogador.vida - quantidade)
    jogador.invencivel    = true
    jogador.timerInvencivel = jogador.duracaoInvencivel
    jogador.timerPiscar   = jogador.intervaloPiscar
    jogador.mostrarSprite = true
end

return combate
