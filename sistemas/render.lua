-- ============================================================
-- sistemas/render.lua
-- Funções auxiliares de desenho para o mapa e o jogador.
-- Centraliza as chamadas de renderização para facilitar
-- futuras extensões (ex: efeitos de pós-processamento).
-- ============================================================

local render = {}

-- Desenha a imagem do mapa na origem (0, 0) do espaço de mundo
function render.desenharMapa(imagemMapa)
    LG.draw(imagemMapa, 0, 0)
end

-- Delega o desenho do jogador para sua própria função (entidades/jogador.lua)
function render.desenharJogador(jogador)
    jogador.draw()
end

return render
