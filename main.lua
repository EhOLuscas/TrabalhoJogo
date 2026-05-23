io.stdout:setvbuf("no")
require "constantes"

estadoAtual = require "estados.menu"

-- Configurações globais de opções
brilhoGlobal = 100
volumeJogo = 100
volumeMusica = 100

local musica = require "sistemas.musica"

-- Sincroniza o volume inicial com a API do Love2D
love.audio.setVolume(volumeJogo / 100)

function love.load()
    -- Reseta o save sempre que o jogo é iniciado
    local save = require "sistemas.save"
    save.deletar()

    musica.carregar()
    if estadoAtual.load then
        estadoAtual.load()
    end
end

function love.update(dt)
    musica.update(dt)
    if estadoAtual.update then
        estadoAtual.update(dt)
    end
end

function love.draw()

    if estadoAtual.draw then
        estadoAtual.draw()
    end

    -- Overlay de Brilho
    if brilhoGlobal and brilhoGlobal < 100 then
        -- Multiplica por 0.85 para que em 0% de brilho ainda haja um pouco de visibilidade
        local escurecimento = (1 - (brilhoGlobal / 100)) * 0.85
        love.graphics.setColor(0, 0, 0, escurecimento)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function love.keypressed(key)

    if estadoAtual.keypressed then
        estadoAtual.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if estadoAtual.mousepressed then
        estadoAtual.mousepressed(x, y, button)
    end
end