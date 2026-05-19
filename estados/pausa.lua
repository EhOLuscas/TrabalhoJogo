local pausa = {}

require "constantes"

function pausa.draw()
    LG.printf(
        "JOGO PAUSADO",
        0,
        250,
        LG.getWidth(),
        "center"
    )

    LG.printf(
        "ENTER - Continuar",
        0,
        320,
        LG.getWidth(),
        "center"
    )

    LG.printf(
        "ESC - Menu",
        0,
        370,
        LG.getWidth(),
        "center"
    )
end

function pausa.keypressed(key)
    if key == "return" then
        estadoAtual = require "estados.jogo"
    end

    if key == "escape" then
        estadoAtual = require "estados.menu"
    end
end

return pausa
