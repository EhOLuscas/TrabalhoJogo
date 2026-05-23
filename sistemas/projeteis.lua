require "constantes"

local projeteis = {}
projeteis.lista = {}

local velocidade = 600

function projeteis.disparar(origemX, origemY, mouseX, mouseY, cameraX, cameraY)
    -- Converte mouse de coordenadas de tela para coordenadas de mundo
    local alvoX = mouseX + cameraX
    local alvoY = mouseY + cameraY
    local dx = alvoX - origemX
    local dy = alvoY - origemY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return end

    table.insert(projeteis.lista, {
        x = origemX,
        y = origemY,
        dx = (dx / dist) * velocidade,
        dy = (dy / dist) * velocidade,
        timer = 0,
        frame = 1,
    })
end

function projeteis.update(dt)
    for i = #projeteis.lista, 1, -1 do
        local p = projeteis.lista[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt

        -- Animação/intercalação do projétil
        p.timer = p.timer + dt
        if p.timer >= 0.06 then
            p.timer = p.timer - 0.06
            p.frame = p.frame == 1 and 2 or 1
        end

        if p.x < -500 or p.x > 10000 or
           p.y < -500 or p.y > 10000 then
            table.remove(projeteis.lista, i)
        end
    end
end

local imagemBala
local quadBala1
local quadBala2

local function obterImagemBala()
    if not imagemBala then
        -- Carrega a imagem original do tiro de canhão (Canhao_bala.png)
        local success, result = pcall(LG.newImage, "sprites/tiro-canhao/Canhao_bala.png")
        if success then
            imagemBala = result
            -- Frame 1: colunas 512-671 (w=160), linhas 336-447 (h=112)
            quadBala1 = love.graphics.newQuad(512, 336, 160, 112, 1024, 1024)
            -- Frame 2: colunas 528-687 (w=160), linhas 544-655 (h=112)
            quadBala2 = love.graphics.newQuad(528, 544, 160, 112, 1024, 1024)
        else
            -- Fallback para Cannon_bala.png se necessário
            local success2, result2 = pcall(LG.newImage, "sprites/tiro-canhao/Cannon_bala.png")
            if success2 then
                imagemBala = result2
                local fw, fh = imagemBala:getDimensions()
                quadBala1 = love.graphics.newQuad(0, 0, fw, fh, fw, fh)
                quadBala2 = quadBala1
            end
        end
    end
    return imagemBala
end

local shaderAzul

local function obterShaderAzul()
    if not shaderAzul then
        shaderAzul = LG.newShader([[
            vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screenCoords) {
                vec4 pixel = Texel(tex, texCoords);
                if (pixel.a < 0.01) discard;
                
                float r = pixel.r;
                float g = pixel.g;
                float b = pixel.b;
                
                // Converte tons de fogo para tons de plasma azul/ciano
                vec3 corPlasma = vec3(r * 0.1, r * 0.6 + g * 0.4, max(r, b) * 1.0 + g * 0.2);
                
                // Preserva o brilho central branco
                float luminosidade = (r + g + b) / 3.0;
                pixel.rgb = mix(corPlasma, pixel.rgb, clamp((luminosidade - 0.75) * 4.0, 0.0, 1.0));
                
                return pixel * color;
            }
        ]])
    end
    return shaderAzul
end

function projeteis.draw()
    local img = obterImagemBala()

    if img then
        local shader = obterShaderAzul()
        if shader then
            LG.setShader(shader)
        end

        local ox = 160 / 2
        local oy = 112 / 2
        for _, p in ipairs(projeteis.lista) do
            local r = math.atan2(p.dy, p.dx)
            local quad = (p.frame == 1) and quadBala1 or quadBala2

            -- Caso seja imagem fallback de dimensões diferentes
            local currentOx, currentOy = ox, oy
            if quadBala1 == quadBala2 then
                local fw, fh = img:getDimensions()
                currentOx, currentOy = fw / 2, fh / 2
            end

            -- Renderiza de forma perfeitamente centralizada e limpa usando o Quad
            LG.draw(img, quad, p.x, p.y, r, 0.1, 0.1, currentOx, currentOy)
        end

        if shader then
            LG.setShader()
        end
    else
        -- Fallback caso a imagem não carregue de forma alguma
        LG.setColor(0, 0.5, 1)
        for _, p in ipairs(projeteis.lista) do
            LG.circle("fill", p.x, p.y, 8)
        end
        LG.setColor(1, 1, 1)
    end
end

return projeteis