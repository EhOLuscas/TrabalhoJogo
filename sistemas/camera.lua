require "constantes"

local camera = {}

camera.x = 0
camera.y = 0

camera.escala = 1

function camera.atualizar(jogador, imagemMapa)

    local larguraTela = LG.getWidth()
    local alturaTela = LG.getHeight()

    local larguraMapa = imagemMapa:getWidth()
    local alturaMapa = imagemMapa:getHeight()

    -- posição da câmera
    camera.x =
        jogador.x - larguraTela / 2 / camera.escala

    camera.y =
        jogador.y - alturaTela / 2 / camera.escala

    -- Limites horizontais
    if camera.x < 0 then
        camera.x = 0
    end

    local maxX =
        larguraMapa - larguraTela / camera.escala

    if camera.x > maxX then
        camera.x = maxX
    end

    -- Limites verticais
    if camera.y < 0 then
        camera.y = 0
    end

    local maxY =
        alturaMapa - alturaTela / camera.escala

    if camera.y > maxY then
        camera.y = maxY
    end
end

function camera.aplicar()

    LG.push()

    LG.scale(camera.escala)

    LG.translate(
        -camera.x,
        -camera.y
    )
end

function camera.remover()

    LG.pop()
end

return camera