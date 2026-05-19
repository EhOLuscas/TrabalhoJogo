require "constantes"

local sti = require "libs.sti"

local gerenciadorMapas = {}

gerenciadorMapas.atual = nil

gerenciadorMapas.mapas = {}

function gerenciadorMapas.carregar()

    gerenciadorMapas.mapas = {

        fase1 = {
            mapa = sti("mapas/fase1/mapa_polvo.lua"),
            imagem = LG.newImage("mapas/fase1/mapa_polvo.png")
        },

        fase2 = {
            mapa = sti("mapas/fase2/mapa_rato.lua"),
            imagem = LG.newImage("mapas/fase2/mapa_rato.png")
        }
    }

    gerenciadorMapas.atual = gerenciadorMapas.mapas.fase1
end

function gerenciadorMapas.trocar(nomeMapa)

    gerenciadorMapas.atual = gerenciadorMapas.mapas[nomeMapa]
end

return gerenciadorMapas