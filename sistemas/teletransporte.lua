require "constantes"
local gerenciadorMapas = require "sistemas.gerenciadorMapas"
local som = require "sistemas.som"

local teletransporte = {}

local spritesExplosao = {}
local shaderAzul

function teletransporte.carregar()
    spritesExplosao = {}
    -- Carrega as 82 sprites da animação de explosão rosa (frame0000.png a frame0081.png)
    for i = 0, 81 do
        local path = string.format("sprites/teletransporte/PNG/frame%04d.png", i)
        local success, img = pcall(LG.newImage, path)
        if success then
            table.insert(spritesExplosao, img)
        end
    end

    shaderAzul = LG.newShader([[
        vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screenCoords) {
            vec4 pixel = Texel(tex, texCoords);
            if (pixel.a < 0.01) discard;
            float r = pixel.r;
            float g = pixel.g;
            float b = pixel.b;
            // Transforma o rosa/magenta da explosão original em um azul elétrico vibrante
            vec3 corAzul = vec3(g * 0.3, g + r * 0.4, b + r * 0.1);
            float avg = (r + g + b) / 3.0;
            // Preserva o centro branco brilhante da explosão e pinta as bordas de azul
            pixel.rgb = mix(corAzul, pixel.rgb, clamp((avg - 0.65) * 3.0, 0.0, 1.0));
            return pixel * color;
        }
    ]])
end

function teletransporte.tentarTeletransporte(jogador, camera, mx, my)
    if jogador.teleportando then return end
    
    local custo = 35
    if jogador.energia >= custo then
        jogador.energia = jogador.energia - custo
        jogador.teleportando = true
        jogador.teleportandoFase = "entrada"
        jogador.teleportandoTimer = 0
        jogador.teleportandoFrame = 1
        jogador.teleportandoOrigemX = jogador.x
        jogador.teleportandoOrigemY = jogador.y

        -- Calcula a posição de destino no espaço do mundo
        local targetX = (mx / camera.escala) + camera.x - jogador.w / 2
        local targetY = (my / camera.escala) + camera.y - jogador.h / 2

        -- Garante que o jogador permaneça dentro dos limites do mapa
        local mapa = gerenciadorMapas.atual
        if mapa and mapa.imagem then
            local mapW = mapa.imagem:getWidth()
            local mapH = mapa.imagem:getHeight()
            targetX = math.max(0, math.min(mapW - jogador.w, targetX))
            targetY = math.max(0, math.min(mapH - jogador.h, targetY))
        end

        jogador.teleportandoDestinoX = targetX
        jogador.teleportandoDestinoY = targetY
        som.tocar("teletransport")
    end
end

function teletransporte.atualizar(dt, jogador, world)
    if not jogador.teleportando then return end

    -- Invencível durante o teleporte
    jogador.invencivel = true
    jogador.timerInvencivel = 0.1
    jogador.mostrarSprite = true

    jogador.teleportandoTimer = jogador.teleportandoTimer + dt
    -- Efeito bem rápido: 82 frames tocados a 150 FPS (~0.55 segundos por fase)
    local fps = 150
    local interval = 0.5 / fps

    while jogador.teleportandoTimer >= interval do
        jogador.teleportandoTimer = jogador.teleportandoTimer - interval
        jogador.teleportandoFrame = jogador.teleportandoFrame + 1

        if jogador.teleportandoFase == "entrada" then
            if jogador.teleportandoFrame > #spritesExplosao then
                -- Finaliza fase de entrada: teleporta o jogador e inicia saída
                jogador.x = jogador.teleportandoDestinoX
                jogador.y = jogador.teleportandoDestinoY
                world:update(jogador, jogador.x, jogador.y)

                jogador.teleportandoFase = "saida"
                jogador.teleportandoFrame = 1
                jogador.teleportandoTimer = 0
                break
            end
        elseif jogador.teleportandoFase == "saida" then
            if jogador.teleportandoFrame > #spritesExplosao then
                -- Finaliza o teletransporte
                jogador.teleportando = false
                jogador.invencivel = false
                break
            end
        end
    end
end

function teletransporte.draw(jogador)
    if not jogador.teleportando then return end

    local img
    local px, py

    if jogador.teleportandoFase == "entrada" then
        img = spritesExplosao[jogador.teleportandoFrame]
        px, py = jogador.teleportandoOrigemX, jogador.teleportandoOrigemY
    else
        -- Desenha a mesma animação em reverso (do frame 82 ao 1)
        local revFrame = #spritesExplosao - jogador.teleportandoFrame + 1
        img = spritesExplosao[revFrame]
        px, py = jogador.x, jogador.y
    end

    if img then
        local imgW = img:getWidth()
        local imgH = img:getHeight()
        local centerX = px + jogador.w / 2
        local centerY = py + jogador.h / 2
        
        -- Escala do efeito (1.0 por padrão, pode ser ajustado se necessário)
        local escala = 1.0
        
        if shaderAzul then
            LG.setShader(shaderAzul)
        end
        
        LG.setColor(1, 1, 1)
        LG.draw(img, centerX, centerY, 0, escala, escala, imgW / 2, imgH / 2)
        
        if shaderAzul then
            LG.setShader()
        end
    end
end

return teletransporte
