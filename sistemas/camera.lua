-- ============================================================
-- sistemas/camera.lua
-- Câmera 2D que centraliza o jogador na tela e respeita os
-- limites do mapa para evitar mostrar áreas fora do mapa.
-- Suporta escala (zoom) via camera.escala.
-- ============================================================

require "constantes"

local camera   = {}

camera.x      = 0  -- Posição X da câmera no espaço de mundo
camera.y      = 0  -- Posição Y da câmera no espaço de mundo
camera.escala = 1  -- Fator de zoom (1 = sem zoom)

-- Atualiza a posição da câmera para centralizar no jogador,
-- respeitando os limites do mapa
function camera.atualizar(jogador, imagemMapa)
    local larguraTela  = LG.getWidth()
    local alturaTela   = LG.getHeight()
    local larguraMapa  = imagemMapa:getWidth()
    local alturaMapa   = imagemMapa:getHeight()

    -- Centraliza a câmera no jogador (ajustado pela escala)
    camera.x = jogador.x - larguraTela  / 2 / camera.escala
    camera.y = jogador.y - alturaTela   / 2 / camera.escala

    -- Limita horizontalmente para não sair do mapa
    camera.x = math.max(0, math.min(camera.x, larguraMapa - larguraTela / camera.escala))

    -- Limita verticalmente para não sair do mapa
    camera.y = math.max(0, math.min(camera.y, alturaMapa  - alturaTela  / camera.escala))
end

-- Aplica a transformação da câmera (deve ser chamado antes de desenhar objetos do mundo)
function camera.aplicar()
    LG.push()
    LG.scale(camera.escala)
    LG.translate(-camera.x, -camera.y)
end

-- Remove a transformação da câmera (deve ser chamado após desenhar objetos do mundo)
function camera.remover()
    LG.pop()
end

return camera
