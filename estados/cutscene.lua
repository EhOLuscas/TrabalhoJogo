require "constantes"

local cutscene = {}

local video
local terminado = false

function cutscene.load()
    terminado = false
    video = love.graphics.newVideo("sprites/cutscene-inicial.ogv")
    video:play()
end

function cutscene.update(dt)
    if not video:isPlaying() or terminado then
        terminado = true
        local jogo = require "estados.jogo"
        estadoAtual = jogo
        if jogo.load then jogo.load() end
    end
end

function cutscene.draw()
    local sw = LG.getWidth()
    local sh = LG.getHeight()
    local vw = video:getWidth()
    local vh = video:getHeight()
    local escX = sw / vw
    local escY = sh / vh

    LG.setColor(1, 1, 1)
    LG.draw(video, 0, 0, 0, escX, escY)
end

function cutscene.keypressed(key)
    -- Pula a cutscene com qualquer tecla ou ESC
    if key == "escape" or key == "return" or key == "space" then
        video:pause()
        terminado = true
    end
end

function cutscene.mousepressed(x, y, button)
    -- Pula com clique
    video:pause()
    terminado = true
end

return cutscene