local colisao = {}

function colisao.carregar(world, mapa)

    local paredes = {}

    local camada = mapa.layers["colisoes"]

    if camada then

        for _, obj in ipairs(camada.objects) do

            local parede = {
                x = obj.x,
                y = obj.y,
                w = obj.width,
                h = obj.height
            }

            table.insert(paredes, parede)

            world:add(
                parede,
                parede.x,
                parede.y,
                parede.w,
                parede.h
            )
        end
    end

    return paredes
end

return colisao