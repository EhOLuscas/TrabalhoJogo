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
local teletransporte = require "sistemas.teletransporte"
local dialogo = require "sistemas.dialogo"
local bossPolvo = require "entidades.bossPolvo"
local bossRato = require "entidades.bossRato"
local hudBoss = require "sistemas.hudBoss"
local gc = require "npc.guerreiro-canhao"
local ge = require "npc.guerreiro-energia"
local ga = require "npc.guerreiro-aviso"
local som = require "sistemas.som"
local musica = require "sistemas.musica"
local save = require "sistemas.save"

local jogo = {}

local world
local paredesAtuais = {}
local npcGuardiaoImg
local npcEspadaImg
local npcCanhaoImg
local npcEnergiaImg
local npcAvisoImg

-- Declarada antes de ser usada em jogo.update e jogo.load
local function trocarMapa(nomeMapa, spawnX, spawnY)
    if nomeMapa == "passagem" then
        jogador.vida = jogador.vidaMax
    end

    gerenciadorMapas.trocar(nomeMapa)
    local mapaAtual = gerenciadorMapas.atual

    -- Salva ao chegar no inicio ou passagem
    if nomeMapa == "inicio" or nomeMapa == "passagem" then
        save.salvar({
            mapa = nomeMapa,
            canhaoDesbloqueado = jogador.canhaoDesbloqueado,
            arma = jogador.arma,
        })
    end

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

    -- Reseta bosses ao trocar de mapa
    bossPolvo.reset()
    bossRato.reset()

    camera.atualizar(
        jogador,
        mapaAtual.imagem
    )
end

function jogo.load()
    world = bump.newWorld(32)

    gerenciadorMapas.carregar()

    jogador.carregarSprites()
    teletransporte.carregar()
    dialogo.carregar()
    som.carregar()

    jogador.vida = 100
    jogador.energia = 100

    -- Carrega save se existir
    local dadosSave = save.carregar()
    if dadosSave then
        jogador.canhaoDesbloqueado = dadosSave.canhaoDesbloqueado or false
        jogador.arma = dadosSave.arma or "espada"
        if dadosSave.mapa and dadosSave.mapa ~= gerenciadorMapas.atual.nome then
            gerenciadorMapas.trocar(dadosSave.mapa)
        end
    end

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

    -- Carrega e reseta bosses
    bossPolvo.carregar()
    bossPolvo.reset()
    bossRato.carregar()
    bossRato.reset()

    -- Carrega imagem dos guardiões
    npcGuardiaoImg = LG.newImage("sprites/npc/Guardiao-teletransporte.png")
    npcEspadaImg = LG.newImage("sprites/npc/Guardião-espada.png")
    npcCanhaoImg = LG.newImage(gc.retrato)
    npcEnergiaImg = LG.newImage(ge.retrato)
    npcAvisoImg = LG.newImage(ga.retrato)

    -- Salva o mapa inicial se ainda não houver save
    local mapaAtual = gerenciadorMapas.atual
    if not save.existe() then
        save.salvar({
            mapa = mapaAtual.nome,
            canhaoDesbloqueado = jogador.canhaoDesbloqueado or false,
            arma = jogador.arma or "espada",
        })
    end
end

function jogo.update(dt)
    love.mouse.setVisible(false)

    -- Recupera o HP durante o mapa de passagem
    if gerenciadorMapas.atual.nome == "passagem" then
        jogador.vida = jogador.vidaMax
    end

    teletransporte.atualizar(dt, jogador, world)
    dialogo.atualizar(dt, jogador)

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

    -- Bosses
    local mapaNome = gerenciadorMapas.atual.nome
    if mapaNome == "fase1" then
        bossPolvo.atualizar(dt, jogador, combate)
        bossPolvo.verificarDanoProjeteis(projeteis.lista)
        bossPolvo.verificarDanoEspada(jogador)
    elseif mapaNome == "fase2" then
        bossRato.atualizar(dt, jogador, combate)
        bossRato.verificarDanoProjeteis(projeteis.lista)
        bossRato.verificarDanoEspada(jogador)

        if bossRato.fimJogo then
            bossRato.reset()
            save.deletar()
            local cutscene = require "estados.cutscene"
            cutscene.videoPath = "sprites/cutscine-final.ogv"
            cutscene.proximoEstado = require "estados.menu"
            estadoAtual = cutscene
            if cutscene.load then
                cutscene.load()
            end
            return
        end
    end

    -- HUD
    hud.update(dt)

    -- Gameover
    if jogador.vida <= 0 then
        musica.parar()
        love.mouse.setVisible(true)
        estadoAtual = require "estados.gameover"
        return
    end

    -- Atualiza música de fundo (BGM)
    if mapaNome == "inicio" or mapaNome == "fase1" then
        musica.tocar("colten")
    elseif mapaNome == "passagem" then
        musica.tocar("michael")
    elseif mapaNome == "fase2" then
        if bossRato.derrotado then
            musica.parar()
        else
            musica.tocar("michael")
        end
    end

    camera.atualizar(jogador, gerenciadorMapas.atual.imagem)

    -- Sempre atualiza portais, permitindo transição da fase 1 mesmo sem derrotar o boss
    -- portais.update(jogador, trocarMapa, dt)

    -- Atualiza o portal apenas quando o boss é morto
    if mapaNome ~= "fase1" or bossPolvo.morto then
        portais.update(jogador, trocarMapa, dt)
    end

    -- Atualiza sons de boss
    som.atualizarBossSons(
        mapaNome,
        bossPolvo.ativo and not bossPolvo.morto,
        bossRato.ativo and not bossRato.derrotado
    )
end

function jogo.draw()
    camera.aplicar()
    render.desenharMapa(gerenciadorMapas.atual.imagem)
    local mapaNome = gerenciadorMapas.atual.nome

    -- Sempre desenha portais
    -- portais.draw()

    -- Desenha o portal apenas quando o boss estiver morto
    if mapaNome ~= "fase1" or bossPolvo.morto then
        portais.draw()
    end

    -- Desenha jogador e guardiões com ordenação Y no mapa inicial
    if gerenciadorMapas.atual.nome == "inicio" and npcGuardiaoImg and npcEspadaImg then
        -- VALORES DE AJUSTE DO GUARDIAO TELETRANSPORTE:
        local guardiaoEscala = 1.35 -- <-- Altere o tamanho/escala aqui (ex: 1.0, 1.2, 1.5)
        local guardiaoX = 920       -- <-- Posição X
        local guardiaoY = 610       -- <-- Posição Y
        local guardianBottomY = guardiaoY + (128 * guardiaoEscala) * 0.85

        -- VALORES DE AJUSTE DO GUARDIAO ESPADA:
        local guardiaoEspadaEscala = 1.35 -- <-- Altere o tamanho/escala aqui (ex: 1.0, 1.2, 1.5)
        local guardiaoEspadaX = 730       -- <-- Posição X (diminuir move para esquerda, aumentar move para direita)
        local guardiaoEspadaY = 130       -- <-- Posição Y (diminuir move para cima, aumentar move para baixo)
        local guardianEspadaBottomY = guardiaoEspadaY + (128 * guardiaoEspadaEscala) * 0.85

        -- VALORES DE AJUSTE DO GUARDIAO ENERGIA:
        local guardiaoEnergiaEscala = ge.escala
        local guardiaoEnergiaX = ge.x
        local guardiaoEnergiaY = ge.y
        local guardianEnergiaBottomY = guardiaoEnergiaY + (128 * guardiaoEnergiaEscala) * 0.85

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
            },
            {
                y = guardianEnergiaBottomY,
                draw = function()
                    LG.setColor(1, 1, 1)
                    LG.draw(npcEnergiaImg, guardiaoEnergiaX, guardiaoEnergiaY, 0, guardiaoEnergiaEscala,
                        guardiaoEnergiaEscala)
                end
            }
        }

        -- Ordena do menor Y ao maior Y (de trás para a frente)
        table.sort(entidades, function(a, b) return a.y < b.y end)

        -- Executa o desenho de cada entidade na ordem correta
        for _, ent in ipairs(entidades) do
            ent.draw()
        end
        teletransporte.draw(jogador)
    elseif gerenciadorMapas.atual.nome == "passagem" and npcCanhaoImg and npcAvisoImg then
        -- VALORES DE AJUSTE DO GUARDIAO CANHAO:
        local guardiaoCanhaoEscala = gc.escala
        local guardiaoCanhaoX = gc.x
        local guardiaoCanhaoY = gc.y
        local guardianCanhaoBottomY = guardiaoCanhaoY + (128 * guardiaoCanhaoEscala) * 0.85

        -- VALORES DE AJUSTE DO GUARDIAO AVISO:
        local guardiaoAvisoEscala = ga.escala
        local guardiaoAvisoX = ga.x
        local guardiaoAvisoY = ga.y
        local guardianAvisoBottomY = guardiaoAvisoY + (128 * guardiaoAvisoEscala) * 0.85

        local entidades = {
            {
                y = jogador.y + jogador.h,
                draw = function() render.desenharJogador(jogador) end
            },
            {
                y = guardianCanhaoBottomY,
                draw = function()
                    LG.setColor(1, 1, 1)
                    LG.draw(npcCanhaoImg, guardiaoCanhaoX, guardiaoCanhaoY, 0, guardiaoCanhaoEscala, guardiaoCanhaoEscala)
                end
            },
            {
                y = guardianAvisoBottomY,
                draw = function()
                    LG.setColor(1, 1, 1)
                    LG.draw(npcAvisoImg, guardiaoAvisoX, guardiaoAvisoY, 0, guardiaoAvisoEscala, guardiaoAvisoEscala)
                end
            }
        }

        table.sort(entidades, function(a, b) return a.y < b.y end)

        for _, ent in ipairs(entidades) do
            ent.draw()
        end
        teletransporte.draw(jogador)
    else
        render.desenharJogador(jogador)
        teletransporte.draw(jogador)
    end
    projeteis.draw()
    sistemaBruxa.draw()
    -- Bosses
    local mapaNome = gerenciadorMapas.atual.nome
    if mapaNome == "fase1" then bossPolvo.draw() end
    if mapaNome == "fase2" then bossRato.draw() end
    dialogo.drawWorld()
    camera.remover()
    if gerenciadorMapas.atual.nome ~= "inicio" then
        hud.draw(jogador)
    end
    -- HUD dos bosses
    if gerenciadorMapas.atual.nome == "fase1" then
        hudBoss.draw(bossPolvo, "Nyx'Thalor")
    elseif gerenciadorMapas.atual.nome == "fase2" then
        hudBoss.draw(bossRato, "Vorl'Guth")
    end
    dialogo.drawScreen()

    -- Desenha cursor personalizado (cruz)
    local mx, my = love.mouse.getPosition()
    LG.setColor(0, 0.9, 0.9, 0.9) -- ciano
    LG.setLineWidth(2)
    LG.line(mx - 10, my, mx - 3, my)
    LG.line(mx + 3, my, mx + 10, my)
    LG.line(mx, my - 10, mx, my - 3)
    LG.line(mx, my + 3, mx, my + 10)
    LG.circle("line", mx, my, 3)
    LG.setColor(1, 1, 1, 1)
end

function jogo.keypressed(key)
    if dialogo.ativo then
        dialogo.keypressed(key)
        return
    end

    if key == "e" then
        local pode = dialogo.podeInteragir(jogador)
        if pode then
            dialogo.iniciar()
            return
        end
    end

    if key == "escape" then
        love.mouse.setVisible(true)
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
    if dialogo.ativo then return end

    if button == 2 then
        teletransporte.tentarTeletransporte(jogador, camera, x, y)
    else
        combate.mousepressed(button, jogador, camera, projeteis)
    end
end

return jogo