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
    if nome == "polvo" then
        LG.setColor(0.9, 0.1, 0.1)
    else
        local fase2 = boss.vida <= boss.vidaMax / 2
        if fase2 then
            LG.setColor(0.8, 0.1, 0.8) -- roxo na fase2
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
    LG.setColor(1, 1, 1)
    LG.printf(nome:upper(), x, y - 20, largura, "center")

    -- Vida
    LG.printf(math.ceil(boss.vida) .. " / " .. boss.vidaMax, x, y + 2, largura, "center")

    LG.setColor(1, 1, 1)
    LG.setLineWidth(1)
end

return hudBoss
