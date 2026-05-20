require "constantes"

local projeteis = {}
projeteis.lista = {}

local velocidade = 600

function projeteis.disparar(origemX, origemY, mouseX, mouseY, cameraX, cameraY)
    -- Converte mouse de coordenadas de tela para coordenadas de mundo
    local alvoX = mouseX + cameraX
    local alvoY = mouseY + cameraY
    local dx = alvoX - origemX
    local dy = alvoY - origemY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return end

    table.insert(projeteis.lista, {
        x = origemX,
        y = origemY,
        dx = (dx / dist) * velocidade,
        dy = (dy / dist) * velocidade,
    })
end

function projeteis.update(dt)
    for i = #projeteis.lista, 1, -1 do
        local p = projeteis.lista[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt

        if p.x < -500 or p.x > 10000 or
           p.y < -500 or p.y > 10000 then
            table.remove(projeteis.lista, i)
        end
    end
end

function projeteis.draw()
    LG.setColor(1, 0.4, 0)
    for _, p in ipairs(projeteis.lista) do
        LG.circle("fill", p.x, p.y, 5)
        -- rastro
        LG.setColor(1, 0.4, 0, 1)
        LG.circle("fill", p.x - p.dx * 0.03, p.y - p.dy * 0.03, 3)
    end
    LG.setColor(1, 1, 1)
end

return projeteis