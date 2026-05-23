require "constantes"

local hudBoss = {}

function hudBoss.draw(boss, nome)
    if not boss.ativo or boss.vida <= 0 then return end

    local largura = 400
    local altura = 22
    local x = LG.getWidth() / 2 - largura / 2
    local y = LG.getHeight() - 60
    local pct = boss.vida / boss.vidaMax

    -- Fundo
    LG.setColor(0.1, 0.1, 0.1, 0.85)
    LG.rectangle("fill", x - 2, y - 2, largura + 4, altura + 4, 4)

    -- Barra de fundo
    LG.setColor(0.3, 0.3, 0.3)
    LG.rectangle("fill", x, y, largura, altura, 3)

    -- Barra de vida (vermelha para polvo, verde para rato)
    if nome == "Nyx'Thalor" then
        if boss.corrompido then
            local t = love.timer.getTime()
            if math.floor(t * 12) % 3 == 0 then
                LG.setColor(0.8, 0.0, 0.8)
            elseif math.floor(t * 12) % 3 == 1 then
                LG.setColor(0.0, 0.8, 0.8)
            else
                LG.setColor(0.9, 0.1, 0.1)
            end
        else
            LG.setColor(0.9, 0.1, 0.1)
        end
    else
        local fase2 = boss.vida <= boss.vidaMax * 0.75
        local fase3 = boss.vida <= boss.vidaMax * 0.50
        if fase3 then
            LG.setColor(1, 0.3, 0.0) -- laranja na fase 3
        elseif fase2 then
            LG.setColor(0.8, 0.1, 0.8)
        else
            LG.setColor(0.1, 0.8, 0.1)
        end
    end
    LG.rectangle("fill", x, y, largura * pct, altura, 3)

    -- Borda
    LG.setColor(0.8, 0.8, 0.8)
    LG.setLineWidth(1.5)
    LG.rectangle("line", x, y, largura, altura, 3)

    -- Nome do boss
    local nomeExibido = nome
    if nome == "Nyx'Thalor" and boss.corrompido then
        local t = love.timer.getTime()
        if math.floor(t * 10) % 2 == 0 then
            nomeExibido = "N¥X'THÅLØR [CØRRØMPIDØ]"
        else
            nomeExibido = "N_X'TH_L_R [C_RR_MP_D_]"
        end
    end
    LG.setColor(1, 1, 1)
    LG.printf(nomeExibido:upper(), x, y - 20, largura, "center")

    LG.setColor(1, 1, 1)
    LG.setLineWidth(1)
end

return hudBoss
