-- ============================================================
-- sistemas/colisao.lua
-- Carrega os objetos da camada "colisoes" do mapa Tiled e os
-- adiciona ao mundo de física bump como retângulos estáticos.
-- Retorna a lista de paredes para que possam ser removidas
-- quando o mapa for trocado.
-- ============================================================

local colisao = {}

-- Carrega colisões do mapa e adiciona ao world bump.
-- Retorna a lista de paredes adicionadas.
function colisao.carregar(world, mapa)
    local paredes = {}
    local camada  = mapa.layers["colisoes"]

    if camada then
        for _, obj in ipairs(camada.objects) do
            local parede = {
                x = obj.x,
                y = obj.y,
                w = obj.width,
                h = obj.height
            }
            table.insert(paredes, parede)
            world:add(parede, parede.x, parede.y, parede.w, parede.h)
        end
    end

    return paredes
end

return colisao
