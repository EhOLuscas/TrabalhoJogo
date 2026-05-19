require "constantes"

local configuracoes = {}

local menu = require "estados.menu"

function configuracoes.draw()

    LG.printf(
        "CONFIGURACOES",
        0,
        200,
        LG.getWidth(),
        "center"
    )

    LG.printf(
        "ESC - Voltar",
        0,
        350,
        LG.getWidth(),
        "center"
    )
end

function configuracoes.keypressed(key)

    if key == "escape" then

        estadoAtual = menu
    end
end

return configuracoes