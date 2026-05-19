local render = {}

function render.desenharMapa(imagemMapa)
    LG.draw(imagemMapa, 0, 0)
end

function render.desenharJogador(jogador)
    function render.desenharJogador(jogador)
        LG.setColor(1, 0.2, 0.2)

        LG.rectangle(
            "fill",
            jogador.x,
            jogador.y,
            jogador.w,
            jogador.h
        )

        LG.setColor(1, 1, 1)
    end
end

return render
