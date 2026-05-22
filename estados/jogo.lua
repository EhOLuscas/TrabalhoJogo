require "constantes"

local bump = require "libs.bump"
local jogador = require "entidades.jogador"
local colisao = require "sistemas.colisao"
local movimento = require "sistemas.movimento"
local render = require "sistemas.render"
local camera = require "sistemas.camera"
local gerenciadorMapas = require "sistemas.gerenciadorMapas"
local portais = require "sistemas.portais"
local projeteis = require "sistemas.projeteis"
local combate = require "sistemas.combate"
local hud = require "sistemas.hud"

local jogo = {}

local world
local paredesAtuais = {}

local timerDanoTeste = 10

-- Declarada antes de ser usada em jogo.update e jogo.load
local function trocarMapa(nomeMapa, spawnX, spawnY)
    if nomeMapa == "fase2" then
        jogador.canhaoDesbloqueado = true
        jogador.arma = "canhao"
    end

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
    jogador.x = spawnX
    jogador.y = spawnY

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

    jogador.carregarSprites()

    jogador.vida = 100
    jogador.energia = 100

    hud.carregar()

    local mapaAtual = gerenciadorMapas.atual

    -- Spawn inicial no centro do circulo
    jogador.x = mapaAtual.imagem:getWidth() / 2 - 30
    jogador.y = mapaAtual.imagem:getHeight() - 250

    world:add(
        jogador,
        jogador.x,
        jogador.y,
        jogador.w,
        jogador.h
    )

    -- Carrega colisões
    paredesAtuais = colisao.carregar(world, mapaAtual.mapa)

    -- Carrega portais definidos no Tiled (camada "portais")
    portais.carregar(mapaAtual.mapa)
    portais.carregarSprite()
end

function jogo.update(dt)

    movimento.atualizar(
        dt,
        jogador,
        world,
        camera
    )

    combate.atualizar(
        dt,
        jogador,
        camera,
        projeteis
    )

    projeteis.update(dt)

    -- HUD
    hud.update(dt)

    -- Gameover
    if jogador.vida <= 0 then

        estadoAtual = require "estados.gameover"

        return
    end

    camera.atualizar(jogador, gerenciadorMapas.atual.imagem)

    portais.update(jogador, trocarMapa, dt)
end

function jogo.draw()
    camera.aplicar()
    render.desenharMapa(gerenciadorMapas.atual.imagem)
    portais.draw()
    render.desenharJogador(jogador)
    projeteis.draw()
    camera.remover()
    hud.draw(jogador)
end

function jogo.keypressed(key)
    if key == "escape" then
        estadoAtual = require "estados.pausa"
    end

    if key == "q" and jogador.canhaoDesbloqueado then
        if jogador.arma == "espada" then
            jogador.arma = "canhao"
        else
            jogador.arma = "espada"
        end
    end
end

return jogo