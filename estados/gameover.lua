local gameover = {}

local menu = require "estados.menu"
local save = require "sistemas.save"
require "constantes"

local botoes = {
    { label = "VOLTAR AO SAVE", y = 300 },
    { label = "MENU PRINCIPAL", y = 370 },
}

function gameover.draw()
    LG.setColor(0, 0, 0, 0.7)
    LG.rectangle("fill", 0, 0, LG.getWidth(), LG.getHeight())

    LG.setColor(1, 0.2, 0.2)
    LG.printf("GAME OVER", 0, 180, LG.getWidth(), "center")

    local mx, my = love.mouse.getPosition()
    local bw, bh = 300, 50
    local bx = LG.getWidth() / 2 - bw / 2

    for i, botao in ipairs(botoes) do
        -- Esconde "Voltar ao Save" se não houver save
        if i == 1 and not save.existe() then
            goto continue
        end

        local hover = mx >= bx and mx <= bx + bw and
                      my >= botao.y and my <= botao.y + bh

        if hover then
            LG.setColor(0.9, 0.7, 0.2)
        else
            LG.setColor(0.6, 0.4, 0.1)
        end
        LG.rectangle("fill", bx, botao.y, bw, bh, 6)
        LG.setColor(0.9, 0.75, 0.3)
        LG.setLineWidth(2)
        LG.rectangle("line", bx, botao.y, bw, bh, 6)
        LG.setColor(1, 1, 1)
        LG.printf(botao.label, bx, botao.y + 15, bw, "center")

        ::continue::
    end

    LG.setColor(1, 1, 1)
end

local function voltarSave()
    love.mouse.setVisible(true)
    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    local jogo = require "estados.jogo"
    estadoAtual = jogo
    if jogo.load then jogo.load() end
end

local function irMenu()
    love.mouse.setVisible(true)
    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    estadoAtual = menu
end

function gameover.update(dt)
    local mx, my = love.mouse.getPosition()
    local bw, bh = 300, 50
    local bx = LG.getWidth() / 2 - bw / 2
    local sobreAlgum = false
    for _, botao in ipairs(botoes) do
        if mx >= bx and mx <= bx + bw and
           my >= botao.y and my <= botao.y + bh then
            sobreAlgum = true
        end
    end
    if sobreAlgum then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end
end

function gameover.mousepressed(x, y, button)
    if button ~= 1 then return end
    local bw, bh = 300, 50
    local bx = LG.getWidth() / 2 - bw / 2

    if save.existe() and x >= bx and x <= bx + bw and
       y >= botoes[1].y and y <= botoes[1].y + bh then
        voltarSave()
    elseif x >= bx and x <= bx + bw and
           y >= botoes[2].y and y <= botoes[2].y + bh then
        irMenu()
    end
end

function gameover.keypressed(key)
    if key == "return" then irMenu() end
    if key == "r" and save.existe() then voltarSave() end
end

return gameover