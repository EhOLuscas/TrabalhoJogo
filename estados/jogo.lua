require "constantes"

local bump = require "libs.bump"
local jogador = require "entidades.jogador"
local colisao = require "sistemas.colisao"
local movimento = require "sistemas.movimento"
local render = require "sistemas.render"
local camera = require "sistemas.camera"
local gerenciadorMapas = require "sistemas.gerenciadorMapas"
local pausa = require "estados.pausa"
local portais = require "sistemas.portais"

local jogo = {}

local world
local paredesAtuais = {}

-- Declarada antes de ser usada em jogo.update e jogo.load
local function trocarMapa(nomeMapa, spawnX, spawnY)
    gerenciadorMapas.trocar(nomeMapa)

    local mapaAtual = gerenciadorMapas.atual

    -- Remove paredes antigas do mundo de física
    for _, parede in ipairs(paredesAtuais) do
        if world:hasItem(parede) then
            world:remove(parede)
        end
    end

    -- Recarrega colisões do novo mapa
    paredesAtuais = colisao.carregar(world, mapaAtual.mapa)

    -- Posiciona jogador no spawn definido pelo portal (ou posição padrão)
    jogador.x = spawnX or 100
    jogador.y = spawnY or (mapaAtual.imagem:getHeight() / 2)

    world:update(
        jogador,
        jogador.x,
        jogador.y
    )

    -- Recarrega portais do novo mapa
    portais.carregar(mapaAtual.mapa)

    camera.atualizar(
        jogador,
        mapaAtual.imagem
    )
end

function jogo.load()
    world = bump.newWorld(32)

    gerenciadorMapas.carregar()

    local mapaAtual = gerenciadorMapas.atual

    -- Spawn inicial no centro-esquerda do mapa
    jogador.x = 400
    jogador.y = mapaAtual.imagem:getHeight() / 2

    world:add(
        jogador,
        jogador.x,
        jogador.y,
        jogador.w,
        jogador.h
    )

    -- Carrega colisões da fase1
    paredesAtuais = colisao.carregar(world, mapaAtual.mapa)

    -- Carrega portais definidos no Tiled (camada "portais")
    portais.carregar(mapaAtual.mapa)
end

function jogo.update(dt)
    movimento.atualizar(
        dt,
        jogador,
        world
    )

    camera.atualizar(
        jogador,
        gerenciadorMapas.atual.imagem
    )

    portais.update(
        jogador,
        trocarMapa
    )
end

function jogo.draw()

    camera.aplicar()

    render.desenharMapa(
        gerenciadorMapas.atual.imagem
    )

    portais.draw()

    render.desenharJogador(jogador)

    camera.remover()
end

function jogo.keypressed(key)
    if key == "escape" then
        estadoAtual = pausa
    end
end

return jogo
