local render = {}

function render.desenharMapa(imagemMapa)
    LG.draw(imagemMapa, 0, 0)
end

function render.desenharJogador(jogador)
    jogador.draw()
end

return render
