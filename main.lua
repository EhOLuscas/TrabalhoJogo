io.stdout:setvbuf("no")
require "constantes"

-- Salva as funções originais do LÖVE para controle interno do Canvas
local originalGetWidth = love.graphics.getWidth
local originalGetHeight = love.graphics.getHeight
local originalGetPosition = love.mouse.getPosition
local originalGetX = love.mouse.getX
local originalGetY = love.mouse.getY

-- Sobrescreve funções de tamanho de tela para retornar a resolução lógica do jogo (1280x720)
function love.graphics.getWidth()
    return 1280
end

function love.graphics.getHeight()
    return 720
end

-- Sobrescreve as coordenadas do mouse para estarem no espaço de escala lógico 1280x720
function love.mouse.getPosition()
    local mx, my = originalGetPosition()
    local screenW = originalGetWidth()
    local screenH = originalGetHeight()
    
    local scale = math.min(screenW / 1280, screenH / 720)
    local ox = (screenW - 1280 * scale) / 2
    local oy = (screenH - 720 * scale) / 2
    
    local tx = (mx - ox) / scale
    local ty = (my - oy) / scale
    return tx, ty
end

function love.mouse.getX()
    local x, _ = love.mouse.getPosition()
    return x
end

function love.mouse.getY()
    local _, y = love.mouse.getPosition()
    return y
end

estadoAtual = require "estados.menu"

-- Configurações globais de opções
brilhoGlobal = 100
volumeJogo = 100
volumeMusica = 20

local musica = require "sistemas.musica"
local gameCanvas

-- Sincroniza o volume inicial com a API do Love2D
love.audio.setVolume(volumeJogo / 100)

function love.load()
    -- Reseta o save sempre que o jogo é iniciado
    local save = require "sistemas.save"
    save.deletar()

    gameCanvas = love.graphics.newCanvas(1280, 720)
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
    -- Renderiza o estado atual no canvas lógico (1280x720)
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()

    if estadoAtual.draw then
        estadoAtual.draw()
    end

    love.graphics.setCanvas()

    -- Desenha o canvas na tela com preenchimento mantendo o aspecto (Letterbox/Pillarbox)
    local screenW = originalGetWidth()
    local screenH = originalGetHeight()
    
    local scale = math.min(screenW / 1280, screenH / 720)
    local ox = (screenW - 1280 * scale) / 2
    local oy = (screenH - 720 * scale) / 2

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas, ox, oy, 0, scale, scale)

    -- Overlay de Brilho
    if brilhoGlobal and brilhoGlobal < 100 then
        -- Multiplica por 0.85 para que em 0% de brilho ainda haja um pouco de visibilidade
        local escurecimento = (1 - (brilhoGlobal / 100)) * 0.85
        love.graphics.setColor(0, 0, 0, escurecimento)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function love.keypressed(key)
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end

    if estadoAtual.keypressed then
        estadoAtual.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    local screenW = originalGetWidth()
    local screenH = originalGetHeight()
    local scale = math.min(screenW / 1280, screenH / 720)
    local ox = (screenW - 1280 * scale) / 2
    local oy = (screenH - 720 * scale) / 2
    local tx = (x - ox) / scale
    local ty = (y - oy) / scale

    if estadoAtual.mousepressed then
        estadoAtual.mousepressed(tx, ty, button)
    end
end