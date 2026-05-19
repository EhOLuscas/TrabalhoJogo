local portais = {}

portais.lista = {}

require "constantes"

function portais.carregar(mapa)

    portais.lista = {}

    local camada =
        mapa.layers["portais"]

    if not camada then
        return
    end

    for _, obj in ipairs(camada.objects) do

        table.insert(
            portais.lista,
            {
                x = obj.x,
                y = obj.y,
                w = obj.width,
                h = obj.height,

                destino =
                    obj.properties.destino,

                spawnX =
                    obj.properties.spawnX,

                spawnY =
                    obj.properties.spawnY
            }
        )
    end
end

function portais.update(
    jogador,
    trocarMapa
)

    for _, portal in ipairs(portais.lista) do

        local colidiu =

            jogador.x < portal.x + portal.w

            and

            jogador.x + jogador.w > portal.x

            and

            jogador.y < portal.y + portal.h

            and

            jogador.y + jogador.h > portal.y

        if colidiu then

            trocarMapa(
                portal.destino,
                portal.spawnX,
                portal.spawnY
            )

            break
        end
    end
end

function portais.draw()

    LG.setColor(1,0,0)

    for _, portal in ipairs(portais.lista) do

        LG.rectangle(
            "line",
            portal.x,
            portal.y,
            portal.w,
            portal.h
        )
    end

    LG.setColor(1,1,1)
end

return portais