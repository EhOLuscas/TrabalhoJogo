io.stdout:setvbuf("no")
require "constantes"

estadoAtual = require "estados.menu"

function love.load()
    if estadoAtual.load then
        estadoAtual.load()
    end
end

function love.update(dt)

    if estadoAtual.update then
        estadoAtual.update(dt)
    end
end

function love.draw()

    if estadoAtual.draw then
        estadoAtual.draw()
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