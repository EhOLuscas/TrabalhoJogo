require "constantes"
local musica = require "sistemas.musica"

local cutscene = {}

cutscene.videoPath = "sprites/cutscene-inicial.ogv"
cutscene.proximoEstado = nil

local video
local terminado = false
local frameCount = 0

function cutscene.load()
    musica.parar()
    terminado = false
    frameCount = 0
    local path = cutscene.videoPath or "sprites/cutscene-inicial.ogv"
    video = love.graphics.newVideo(path)
    video:play()
end

function cutscene.update(dt)
    frameCount = frameCount + 1
    
    if not video or terminado then
        terminado = true
        local proximo = cutscene.proximoEstado or require "estados.jogo"
        
        -- Restaura padrões para a próxima execução
        cutscene.videoPath = "sprites/cutscene-inicial.ogv"
        cutscene.proximoEstado = nil
        
        estadoAtual = proximo
        if proximo.load then proximo.load() end
        return
    end

    -- Espera pelo menos 10 frames para que o vídeo tenha tempo de inicializar e começar a reprodução
    if frameCount > 10 then
        if not video:isPlaying() then
            terminado = true
            local proximo = cutscene.proximoEstado or require "estados.jogo"
            
            -- Restaura padrões para a próxima execução
            cutscene.videoPath = "sprites/cutscene-inicial.ogv"
            cutscene.proximoEstado = nil
            
            estadoAtual = proximo
            if proximo.load then proximo.load() end
        end
    end
end

function cutscene.draw()
    if not video then return end
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
        if video then video:pause() end
        terminado = true
    end
end

function cutscene.mousepressed(x, y, button)
    -- Pula com clique
    if video then video:pause() end
    terminado = true
end

return cutscene