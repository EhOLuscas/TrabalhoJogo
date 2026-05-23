require "constantes"

local menu = {}

local imagemFundo
local botoes = {}

function menu.load()
    love.mouse.setVisible(true)
    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    imagemFundo = LG.newImage("sprites/imagem-menu.png")

    local musica = require "sistemas.musica"
    musica.tocar("colten")

    botoes = {
        {
            label = "INICIAR JOGO",
            x = 80,
            y = 390,
            w = 360,
            h = 100,
            hover = false,
            acao = function()
                local musica = require "sistemas.musica"
                musica.parar()
                estadoAtual = require "estados.cutscene"
                if estadoAtual.load then
                    estadoAtual.load()
                end
            end
        },
        {
            label = "CONFIGURAÇÕES",
            x = 80,
            y = 530,
            w = 360,
            h = 100,
            hover = false,
            acao = function()
                estadoAtual = require "estados.configuracoes"
                if estadoAtual.load then
                    estadoAtual.load()
                end
            end
        }
    }
end

function menu.update(dt)
    local mx, my = love.mouse.getPosition()
    local sobreAlgum = false
    for _, botao in ipairs(botoes) do
        botao.hover =
            mx >= botao.x and mx <= botao.x + botao.w and
            my >= botao.y and my <= botao.y + botao.h
        if botao.hover then
            sobreAlgum = true
        end
    end

    if sobreAlgum then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end
end

function menu.draw()
    -- Fundo
    LG.setColor(1, 1, 1)
    LG.draw(imagemFundo, 0, 0)
end

function menu.mousepressed(x, y, button)
    if button == 1 then
        for _, botao in ipairs(botoes) do
            if botao.hover then
                botao.acao()
            end
        end
    end
end

function menu.keypressed(key)
    if key == "return" then
        local musica = require "sistemas.musica"
        musica.parar()
        estadoAtual = require "estados.cutscene"
        if estadoAtual.load then
            estadoAtual.load()
        end
    end

    if key == "escape" then
        estadoAtual = require "estados.configuracoes"
        if estadoAtual.load then
            estadoAtual.load()
        end
    end
end

return menu