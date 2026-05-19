-- Importações
local sti = require "libs.sti"
local bump = require "libs.bump"
local jogador = require "entidades.jogador"
local colisao = require "sistemas.colisao"
local movimento = require "sistemas.movimento"
local render = require "sistemas.render"
local camera = require "sistemas.camera"

require "constantes"

local world
local mapa
local imagemMapa

function love.load()
    -- Mundo do bump
    world = bump.newWorld(32)

    -- Carrega mapa
    mapa = sti("mapas/fase1/mapa_polvo.lua")

    -- Carrega imagem REAL do mapa
    imagemMapa = LG.newImage("mapas/fase1/mapa_polvo.png")

    -- Centro REAL da imagem
    jogador.x = imagemMapa:getWidth() / 2 - jogador.w / 2
    jogador.y = imagemMapa:getHeight() / 2 - jogador.h / 2

    -- Adiciona jogador no mundo
    world:add(
        jogador,
        jogador.x,
        jogador.y,
        jogador.w,
        jogador.h
    )

    -- Camada de colisões do Tiled
    colisao.carregar(world, mapa)
end

function love.update(dt)
    movimento.atualizar(dt, jogador, world)

    camera.atualizar(jogador, imagemMapa)
end

function love.draw()
    camera.aplicar()

    render.desenharMapa(imagemMapa)

    render.desenharJogador(jogador)

    camera.remover()
end
