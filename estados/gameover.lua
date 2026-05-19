local gameover = {}

local menu = require "estados.menu"
require "constantes"

function gameover.draw()

    LG.printf(
        "GAME OVER",
        0,
        250,
        LG.getWidth(),
        "center"
    )

    LG.printf(
        "ENTER - Menu",
        0,
        320,
        LG.getWidth(),
        "center"
    )
end

function gameover.keypressed(key)

    if key == "return" then

        estadoAtual = menu
    end
end

return gameover