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
local sistemaBruxa = require "sistemas.sistemaBruxa"

local jogo = {}

local world
local paredesAtuais = {}
local npcGuardiaoImg
local npcEspadaImg

-- Declarada antes de ser usada em jogo.update e jogo.load
local function trocarMapa(nomeMapa, spawnX, spawnY)
    if nomeMapa == "fase2" then
        jogador.canhaoDesbloqueado = true
        jogador.arma = "canhao"
    end

    if nomeMapa == "passagem" then
        jogador.vida = jogador.vidaMax
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

    -- Reseta sistema da bruxa para a nova fase
    sistemaBruxa.reset()

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

    if mapaAtual.nome == "passagem" then
        jogador.x = 114
        jogador.y = 512
    else
        -- Spawn inicial no centro do circulo
        jogador.x = mapaAtual.imagem:getWidth() / 2 - 30
        jogador.y = mapaAtual.imagem:getHeight() - 250
    end

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

    -- Inicializa e reseta o sistema da bruxa
    sistemaBruxa.carregar()
    sistemaBruxa.reset()

    -- Carrega imagem dos guardiões
    npcGuardiaoImg = LG.newImage("sprites/npc/Guardiao-teletransporte.png")
    npcEspadaImg = LG.newImage("sprites/npc/Guardião-espada.png")
end

function jogo.update(dt)
    -- Recupera o HP durante o mapa de passagem
    if gerenciadorMapas.atual.nome == "passagem" then
        jogador.vida = jogador.vidaMax
    end

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

    -- Atualiza sistema da bruxa e cura
    sistemaBruxa.atualizar(dt, jogador, camera, projeteis)

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
    -- Desenha jogador e guardiões com ordenação Y no mapa inicial
    if gerenciadorMapas.atual.nome == "inicio" and npcGuardiaoImg and npcEspadaImg then
        -- VALORES DE AJUSTE DO GUARDIAO TELETRANSPORTE:
        local guardiaoEscala = 1.35  -- <-- Altere o tamanho/escala aqui (ex: 1.0, 1.2, 1.5)
        local guardiaoX = 920        -- <-- Posição X
        local guardiaoY = 610        -- <-- Posição Y
        local guardianBottomY = guardiaoY + (128 * guardiaoEscala) * 0.85

        -- VALORES DE AJUSTE DO GUARDIAO ESPADA:
        local guardiaoEspadaEscala = 1.35  -- <-- Altere o tamanho/escala aqui (ex: 1.0, 1.2, 1.5)
        local guardiaoEspadaX = 730        -- <-- Posição X (diminuir move para esquerda, aumentar move para direita)
        local guardiaoEspadaY = 130        -- <-- Posição Y (diminuir move para cima, aumentar move para baixo)
        local guardianEspadaBottomY = guardiaoEspadaY + (128 * guardiaoEspadaEscala) * 0.85

        -- Tabela com as entidades e seus Ys para ordenação de profundidade
        local entidades = {
            {
                y = jogador.y + jogador.h,
                draw = function() render.desenharJogador(jogador) end
            },
            {
                y = guardianBottomY,
                draw = function()
                    LG.setColor(1, 1, 1)
                    LG.draw(npcGuardiaoImg, guardiaoX, guardiaoY, 0, guardiaoEscala, guardiaoEscala)
                end
            },
            {
                y = guardianEspadaBottomY,
                draw = function()
                    LG.setColor(1, 1, 1)
                    LG.draw(npcEspadaImg, guardiaoEspadaX, guardiaoEspadaY, 0, guardiaoEspadaEscala, guardiaoEspadaEscala)
                end
            }
        }

        -- Ordena do menor Y ao maior Y (de trás para a frente)
        table.sort(entidades, function(a, b) return a.y < b.y end)

        -- Executa o desenho de cada entidade na ordem correta
        for _, ent in ipairs(entidades) do
            ent.draw()
        end
    else
        render.desenharJogador(jogador)
    end
    projeteis.draw()
    sistemaBruxa.draw()
    camera.remover()
    if gerenciadorMapas.atual.nome ~= "inicio" then
        hud.draw(jogador)
    end
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

    -- Tecla de debug para testar dano (20 de dano por hit)
    if key == "h" then
        combate.receberDano(jogador, 20)
    end
end

function jogo.mousepressed(x, y, button)
    combate.mousepressed(button, jogador, camera, projeteis)
end

return jogo