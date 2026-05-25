-- ============================================================
-- estados/jogo.lua
-- Estado principal do jogo. Gerencia o loop de gameplay:
-- carregamento, atualização e desenho de todos os sistemas
-- (jogador, câmera, colisão, combate, bosses, HUD, portais).
-- ============================================================

require "constantes"

local bump             = require "libs.bump"
local jogador          = require "entidades.jogador"
local colisao          = require "sistemas.colisao"
local movimento        = require "sistemas.movimento"
local render           = require "sistemas.render"
local camera           = require "sistemas.camera"
local gerenciadorMapas = require "sistemas.gerenciadorMapas"
local portais          = require "sistemas.portais"
local projeteis        = require "sistemas.projeteis"
local combate          = require "sistemas.combate"
local hud              = require "sistemas.hud"
local sistemaBruxa     = require "sistemas.sistemaBruxa"
local teletransporte   = require "sistemas.teletransporte"
local dialogo          = require "sistemas.dialogo"
local bossPolvo        = require "entidades.bossPolvo"
local bossRato         = require "entidades.bossRato"
local hudBoss          = require "sistemas.hudBoss"
local gc               = require "npc.guerreiro-canhao"
local ge               = require "npc.guerreiro-energia"
local ga               = require "npc.guerreiro-aviso"
local som              = require "sistemas.som"
local musica           = require "sistemas.musica"
local save             = require "sistemas.save"

local jogo = {}

-- Mundo de física bump (colisões AABB)
local world
-- Lista de paredes carregadas do mapa atual (para remoção ao trocar de mapa)
local paredesAtuais = {}

-- Imagens dos NPCs (carregadas uma vez em jogo.load)
local npcGuardiaoImg
local npcEspadaImg
local npcCanhaoImg
local npcEnergiaImg
local npcAvisoImg

-- Liga/desliga sobreposição de hitboxes para debug (F1)
local debugHitbox = false

-- ── trocarMapa ────────────────────────────────────────────────
-- Troca o mapa ativo, reposiciona o jogador, recarrega colisões,
-- portais e bosses. Também salva o progresso nos mapas-chave.
local function trocarMapa(nomeMapa, spawnX, spawnY)
    -- Cura total ao entrar no mapa de passagem (área segura)
    if nomeMapa == "passagem" then
        jogador.vida = jogador.vidaMax
    end

    gerenciadorMapas.trocar(nomeMapa)
    local mapaAtual = gerenciadorMapas.atual

    -- Salva progresso ao chegar nos pontos de checkpoint
    if nomeMapa == "inicio" or nomeMapa == "passagem" then
        save.salvar({
            mapa               = nomeMapa,
            canhaoDesbloqueado = jogador.canhaoDesbloqueado,
            arma               = jogador.arma,
        })
    end

    -- Remove todas as paredes do mapa anterior do mundo de física
    for _, parede in ipairs(paredesAtuais) do
        if world:hasItem(parede) then
            world:remove(parede)
        end
    end

    -- Recarrega colisões e portais do novo mapa
    paredesAtuais = colisao.carregar(world, mapaAtual.mapa)
    portais.carregar(mapaAtual.mapa)

    -- Reposiciona o jogador no spawn definido pelo portal
    jogador.x = spawnX
    jogador.y = spawnY
    world:update(jogador, jogador.x, jogador.y)

    -- Reseta sistemas dependentes do mapa
    sistemaBruxa.reset()
    bossPolvo.reset()
    bossRato.reset()

    camera.atualizar(jogador, mapaAtual.imagem)
end

-- ── jogo.load ─────────────────────────────────────────────────
-- Inicializa todos os sistemas, carrega assets e restaura save.
function jogo.load()
    world = bump.newWorld(32)

    gerenciadorMapas.carregar()

    -- Carrega sprites e sistemas
    jogador.carregarSprites()
    teletransporte.carregar()
    dialogo.carregar()
    som.carregar()

    -- Vida e energia iniciais
    jogador.vida    = 100
    jogador.energia = 100

    -- Restaura progresso do save (mapa, arma e canhão desbloqueado)
    local dadosSave = save.carregar()
    if dadosSave then
        jogador.canhaoDesbloqueado = dadosSave.canhaoDesbloqueado or false
        jogador.arma               = dadosSave.arma or "espada"
        if dadosSave.mapa and dadosSave.mapa ~= gerenciadorMapas.atual.nome then
            gerenciadorMapas.trocar(dadosSave.mapa)
        end
    end

    hud.carregar()

    -- Define posição inicial do jogador conforme o mapa carregado
    local mapaAtual = gerenciadorMapas.atual
    if mapaAtual.nome == "passagem" then
        jogador.x = 114
        jogador.y = 512
    else
        jogador.x = mapaAtual.imagem:getWidth() / 2 - 30
        jogador.y = mapaAtual.imagem:getHeight() - 250
    end

    -- Adiciona o jogador ao mundo de física
    world:add(jogador, jogador.x, jogador.y, jogador.w, jogador.h)

    -- Carrega colisões e portais do mapa inicial
    paredesAtuais = colisao.carregar(world, mapaAtual.mapa)
    portais.carregar(mapaAtual.mapa)
    portais.carregarSprite()

    -- Inicializa sistema da bruxa e bosses
    sistemaBruxa.carregar()
    sistemaBruxa.reset()
    bossPolvo.carregar()
    bossPolvo.reset()
    bossRato.carregar()
    bossRato.reset()

    -- Carrega imagens dos NPCs
    npcGuardiaoImg = LG.newImage("sprites/npc/Guardiao-teletransporte.png")
    npcEspadaImg   = LG.newImage("sprites/npc/Guardião-espada.png")
    npcCanhaoImg   = LG.newImage(gc.retrato)
    npcEnergiaImg  = LG.newImage(ge.retrato)
    npcAvisoImg    = LG.newImage(ga.retrato)

    -- Cria save inicial se ainda não existir
    if not save.existe() then
        save.salvar({
            mapa               = mapaAtual.nome,
            canhaoDesbloqueado = jogador.canhaoDesbloqueado or false,
            arma               = jogador.arma or "espada",
        })
    end
end

-- ── jogo.update ───────────────────────────────────────────────
function jogo.update(dt)
    love.mouse.setVisible(false) -- Usa cursor personalizado desenhado em jogo.draw

    -- Cura contínua no mapa de passagem (área segura entre fases)
    if gerenciadorMapas.atual.nome == "passagem" then
        jogador.vida = jogador.vidaMax
    end

    -- Atualiza sistemas de jogabilidade
    teletransporte.atualizar(dt, jogador, world)
    dialogo.atualizar(dt, jogador)
    movimento.atualizar(dt, jogador, world, camera)
    combate.atualizar(dt, jogador, camera, projeteis)
    projeteis.update(dt)
    sistemaBruxa.atualizar(dt, jogador, camera, projeteis)

    -- Atualiza boss do mapa atual
    local mapaNome = gerenciadorMapas.atual.nome
    if mapaNome == "fase1" then
        bossPolvo.atualizar(dt, jogador, combate)
        bossPolvo.verificarDanoProjeteis(projeteis.lista)
        bossPolvo.verificarDanoEspada(jogador)
    elseif mapaNome == "fase2" then
        bossRato.atualizar(dt, jogador, combate)
        bossRato.verificarDanoProjeteis(projeteis.lista)
        bossRato.verificarDanoEspada(jogador)

        -- Ao derrotar o rato, inicia cutscene final
        if bossRato.fimJogo then
            bossRato.reset()
            save.deletar()
            local cutscene         = require "estados.cutscene"
            cutscene.videoPath     = "sprites/cutscine-final.ogv"
            cutscene.proximoEstado = require "estados.menu"
            estadoAtual            = cutscene
            if cutscene.load then cutscene.load() end
            return
        end
    end

    hud.update(dt)

    -- Game over ao zerar vida
    if jogador.vida <= 0 then
        musica.parar()
        love.mouse.setVisible(true)
        estadoAtual = require "estados.gameover"
        return
    end

    -- Controle de música por mapa/estado do boss
    if mapaNome == "inicio" or (mapaNome == "fase1" and not bossPolvo.morto) then
        musica.tocar("musica1")
    elseif mapaNome == "passagem" or (mapaNome == "fase1" and bossPolvo.morto) then
        musica.tocar("musica2")
    elseif mapaNome == "fase2" then
        if bossRato.derrotado then
            musica.parar()
        else
            musica.tocar("musica2")
        end
    end

    camera.atualizar(jogador, gerenciadorMapas.atual.imagem)

    -- Portal só é atualizado após a morte do boss na fase 1
    if mapaNome ~= "fase1" or bossPolvo.morto then
        portais.update(jogador, trocarMapa, dt)
    end

    -- Atualiza sons ambiente dos bosses
    local polvoBossAtivo = bossPolvo.ativo and not bossPolvo.morto and not bossPolvo.derrotado
    local ratoBossAtivo  = bossRato.ativo  and not bossRato.derrotado
    som.atualizarBossSons(mapaNome, polvoBossAtivo, ratoBossAtivo)
    musica.setBossAtivo(polvoBossAtivo or ratoBossAtivo)
end

-- ── Desenha NPCs e jogador com ordenação por Y (depth sorting) ──
local function desenharEntidadesOrdenadas(entidades, incluiTeletransporte)
    table.sort(entidades, function(a, b) return a.y < b.y end)
    for _, ent in ipairs(entidades) do
        ent.draw()
    end
    if incluiTeletransporte then
        teletransporte.draw(jogador)
    end
end

-- ── jogo.draw ─────────────────────────────────────────────────
function jogo.draw()
    camera.aplicar()

    render.desenharMapa(gerenciadorMapas.atual.imagem)

    local mapaNome = gerenciadorMapas.atual.nome

    -- Portal visível apenas após morte do boss na fase 1
    if mapaNome ~= "fase1" or bossPolvo.morto then
        portais.draw()
    end

    -- Desenha jogador e NPCs com ordenação de profundidade por Y
    if mapaNome == "inicio" and npcGuardiaoImg and npcEspadaImg then
        -- Mapa início: guardião teletransporte, guardião espada, guardião energia
        local gEscala  = 1.35
        local gX, gY   = 920, 610

        local eEscala  = 1.35
        local eX, eY   = 730, 130

        desenharEntidadesOrdenadas({
            { y = jogador.y + jogador.h,
              draw = function() render.desenharJogador(jogador) end },
            { y = gY + (128 * gEscala) * 0.85,
              draw = function()
                  LG.setColor(1,1,1)
                  LG.draw(npcGuardiaoImg, gX, gY, 0, gEscala, gEscala)
              end },
            { y = eY + (128 * eEscala) * 0.85,
              draw = function()
                  LG.setColor(1,1,1)
                  LG.draw(npcEspadaImg, eX, eY, 0, eEscala, eEscala)
              end },
            { y = ge.y + (128 * ge.escala) * 0.85,
              draw = function()
                  LG.setColor(1,1,1)
                  LG.draw(npcEnergiaImg, ge.x, ge.y, 0, ge.escala, ge.escala)
              end },
        }, true)

    elseif mapaNome == "passagem" and npcCanhaoImg and npcAvisoImg then
        -- Mapa passagem: guardião canhão e guardião aviso
        desenharEntidadesOrdenadas({
            { y = jogador.y + jogador.h,
              draw = function() render.desenharJogador(jogador) end },
            { y = gc.y + (128 * gc.escala) * 0.85,
              draw = function()
                  LG.setColor(1,1,1)
                  LG.draw(npcCanhaoImg, gc.x, gc.y, 0, gc.escala, gc.escala)
              end },
            { y = ga.y + (128 * ga.escala) * 0.85,
              draw = function()
                  LG.setColor(1,1,1)
                  LG.draw(npcAvisoImg, ga.x, ga.y, 0, ga.escala, ga.escala)
              end },
        }, true)

    else
        -- Demais mapas: apenas jogador e efeito de teletransporte
        render.desenharJogador(jogador)
        teletransporte.draw(jogador)
    end

    -- Projéteis do jogador e efeitos da bruxa
    projeteis.draw()
    sistemaBruxa.draw()

    -- Bosses (apenas no mapa correspondente)
    if mapaNome == "fase1" then bossPolvo.draw() end
    if mapaNome == "fase2" then bossRato.draw()  end

    -- Prompts de diálogo (balões no mundo)
    dialogo.drawWorld()

    -- ── Overlay de debug: hitboxes ──────────────────────
    if debugHitbox then
        LG.setColor(1, 0, 0, 0.3)
        if bossPolvo.ativo then
            LG.rectangle("fill", bossPolvo.x, bossPolvo.y, bossPolvo.w, bossPolvo.h)
        end
        if bossRato.ativo then
            LG.rectangle("fill", bossRato.x, bossRato.y, bossRato.w, bossRato.h)
        end
        if jogador.arma == "espada" and jogador.anim.estado == "atacando" then
            local sx = jogador.x + (jogador.virandoDireita and jogador.w or -40)
            LG.setColor(0, 1, 0, 0.4)
            LG.rectangle("fill", sx, jogador.y, 50, jogador.h)
        end
        LG.setColor(1, 0.5, 0, 0.5)
        for _, p in ipairs(projeteis.lista) do
            LG.circle("fill", p.x, p.y, 8)
        end
        LG.setColor(1, 1, 1)
    end

    camera.remover()

    -- ── HUD (fora da câmera, espaço de tela) ────────────
    if mapaNome ~= "inicio" then
        hud.draw(jogador)
    end

    -- Barra de vida dos bosses
    if mapaNome == "fase1" then
        hudBoss.draw(bossPolvo, "Nyx'Thalor")
    elseif mapaNome == "fase2" then
        hudBoss.draw(bossRato, "Vorl'Guth")
    end

    -- Caixas de diálogo na tela
    dialogo.drawScreen()

    -- Cursor personalizado (mira em cruz ciano)
    local mx, my = love.mouse.getPosition()
    LG.setColor(0, 0.9, 0.9, 0.9)
    LG.setLineWidth(2)
    LG.line(mx - 10, my,   mx - 3,  my)
    LG.line(mx + 3,  my,   mx + 10, my)
    LG.line(mx, my - 10,   mx,      my - 3)
    LG.line(mx, my + 3,    mx,      my + 10)
    LG.circle("line", mx, my, 3)
    LG.setColor(1, 1, 1, 1)
end

-- ── jogo.keypressed ───────────────────────────────────────────
function jogo.keypressed(key)
    -- F1 liga/desliga debug de hitboxes
    if key == "f1" then
        debugHitbox = not debugHitbox
    end

    -- Repassa teclas ao diálogo quando ativo
    if dialogo.ativo then
        dialogo.keypressed(key)
        return
    end

    -- Inicia diálogo ao pressionar E perto de um NPC
    if key == "e" then
        if dialogo.podeInteragir(jogador) then
            dialogo.iniciar()
            return
        end
    end

    -- Abre menu de pausa
    if key == "escape" then
        love.mouse.setVisible(true)
        estadoAtual = require "estados.pausa"
    end

    -- Troca de arma (Q) — apenas se o canhão foi desbloqueado
    if key == "q" and jogador.canhaoDesbloqueado then
        jogador.arma = (jogador.arma == "espada") and "canhao" or "espada"
    end

    -- Tecla de debug: aplica 20 de dano ao jogador
    if key == "h" then
        combate.receberDano(jogador, 20)
    end
end

-- ── jogo.mousepressed ─────────────────────────────────────────
function jogo.mousepressed(x, y, button)
    if dialogo.ativo then return end

    if button == 2 then
        -- Botão direito: teletransporte
        teletransporte.tentarTeletransporte(jogador, camera, x, y)
    else
        -- Botão esquerdo/outros: combate
        combate.mousepressed(button, jogador, camera, projeteis)
    end
end

return jogo
