-- ============================================================
-- sistemas/gerenciadorMapas.lua
-- Carrega todos os mapas do jogo (STI + imagem PNG) e mantém
-- uma referência ao mapa atualmente ativo.
-- Cada mapa tem: nome, mapa (STI), imagem (PNG).
-- ============================================================

require "constantes"

local sti              = require "libs.sti"
local gerenciadorMapas = {}

gerenciadorMapas.atual  = nil  -- Mapa atualmente ativo
gerenciadorMapas.mapas  = {}   -- Tabela com todos os mapas carregados

-- Carrega todos os mapas e define o mapa inicial como "inicio"
function gerenciadorMapas.carregar()
    gerenciadorMapas.mapas = {
        inicio = {
            nome   = "inicio",
            mapa   = sti("mapas/inicio/Mapa-Inicio.lua"),
            imagem = LG.newImage("mapas/inicio/Mapa-Inicio.png")
        },
        fase1 = {
            nome   = "fase1",
            mapa   = sti("mapas/fase1/mapa_polvo.lua"),
            imagem = LG.newImage("mapas/fase1/mapa_polvo.png")
        },
        passagem = {
            nome   = "passagem",
            mapa   = sti("mapas/passagem/passagem-mapa.lua"),
            imagem = LG.newImage("mapas/passagem/passagem-mapa.png")
        },
        fase2 = {
            nome   = "fase2",
            mapa   = sti("mapas/fase2/mapa_rato.lua"),
            imagem = LG.newImage("mapas/fase2/mapa_rato.png")
        }
    }

    gerenciadorMapas.atual = gerenciadorMapas.mapas.inicio
end

-- Troca o mapa ativo pelo mapa de nome informado
function gerenciadorMapas.trocar(nomeMapa)
    gerenciadorMapas.atual = gerenciadorMapas.mapas[nomeMapa]
end

return gerenciadorMapas
