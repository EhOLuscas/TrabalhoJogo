-- ============================================================
-- main.lua
-- Ponto de entrada do jogo. Configura o canvas lógico (1280x720),
-- sobrescreve funções de dimensão e mouse para o espaço lógico,
-- e delega os callbacks do LÖVE ao estado atual.
-- ============================================================

io.stdout:setvbuf("no") -- Exibe prints imediatamente no console

require "constantes"

-- Salva as funções originais do LÖVE antes de sobrescrevê-las
local originalGetWidth    = love.graphics.getWidth
local originalGetHeight   = love.graphics.getHeight
local originalGetPosition = love.mouse.getPosition

-- Faz getWidth/getHeight sempre retornar a resolução lógica 1280x720,
-- independente do tamanho real da janela
function love.graphics.getWidth()  return 1280 end
function love.graphics.getHeight() return 720  end

-- Converte as coordenadas do mouse do espaço físico para o espaço lógico 1280x720
function love.mouse.getPosition()
    local mx, my   = originalGetPosition()
    local screenW  = originalGetWidth()
    local screenH  = originalGetHeight()
    local scale    = math.min(screenW / 1280, screenH / 720)
    local ox       = (screenW - 1280 * scale) / 2
    local oy       = (screenH - 720  * scale) / 2
    return (mx - ox) / scale, (my - oy) / scale
end

function love.mouse.getX()
    local x, _ = love.mouse.getPosition()
    return x
end

function love.mouse.getY()
    local _, y = love.mouse.getPosition()
    return y
end

-- Estado inicial: menu principal
estadoAtual = require "estados.menu"

-- Variáveis globais de configuração (usadas em pausa, configurações e gameover)
brilhoGlobal = 100
volumeJogo   = 100
volumeMusica = 20

local musica    = require "sistemas.musica"
local gameCanvas -- Canvas lógico onde todo o jogo é renderizado

-- Sincroniza o volume inicial com a API do LÖVE
love.audio.setVolume(volumeJogo / 100)

function love.load()
    -- Deleta save anterior para começar sempre do zero
    local save = require "sistemas.save"
    save.deletar()

    -- Cria o canvas lógico fixo em 1280x720
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
    -- Renderiza o estado atual no canvas lógico
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()

    if estadoAtual.draw then
        estadoAtual.draw()
    end

    love.graphics.setCanvas()

    -- Escala o canvas para preencher a tela mantendo a proporção (letterbox/pillarbox)
    local screenW = originalGetWidth()
    local screenH = originalGetHeight()
    local scale   = math.min(screenW / 1280, screenH / 720)
    local ox      = (screenW - 1280 * scale) / 2
    local oy      = (screenH - 720  * scale) / 2

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas, ox, oy, 0, scale, scale)

    -- Overlay de brilho: escurece a tela conforme o slider de brilho
    if brilhoGlobal and brilhoGlobal < 100 then
        local escurecimento = (1 - (brilhoGlobal / 100)) * 0.85
        love.graphics.setColor(0, 0, 0, escurecimento)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function love.keypressed(key)
    -- F11 alterna tela cheia
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end

    if estadoAtual.keypressed then
        estadoAtual.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    -- Converte coordenadas físicas para lógicas antes de passar ao estado
    local screenW = originalGetWidth()
    local screenH = originalGetHeight()
    local scale   = math.min(screenW / 1280, screenH / 720)
    local ox      = (screenW - 1280 * scale) / 2
    local oy      = (screenH - 720  * scale) / 2
    local tx      = (x - ox) / scale
    local ty      = (y - oy) / scale

    if estadoAtual.mousepressed then
        estadoAtual.mousepressed(tx, ty, button)
    end
end
