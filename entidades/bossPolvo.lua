require "constantes"

local bossPolvo = {}

bossPolvo.ativo = false
bossPolvo.vida = 500
bossPolvo.vidaMax = 500
bossPolvo.x = 0
bossPolvo.y = 0
bossPolvo.w = 300
bossPolvo.h = 300

-- Animação
local frames = {}
local frameAtual = 1
local timerAnim = 0
local fpsAnim = 10
local totalFrames = 0

-- Dano / piscar
local invencivel = false
local timerInvencivel = 0
local duracaoInvencivel = 0.4
local timerPiscar = 0
local intervaloPiscar = 0.05
local mostrarSprite = true
local shaderBranco

-- Cooldown espada
local timerCooldownEspada = 0
local cooldownEspada = 0.6

-- Laser
local FASE_ALERTA = "alerta"
local FASE_LASER  = "laser"
local FASE_PAUSA  = "pausa"

local laser = {
    fase = FASE_PAUSA,
    timer = 0,
    duracaoAlerta = 1.5,
    duracaoLaser  = 0.8,
    duracaoPausa  = 2.0,
    alvoX = 0, alvoY = 0,
    origemX = 0, origemY = 0,
}

local LARGURA_MAPA = 1316

function bossPolvo.carregar()
    frames = {}
    for i = 1, 16 do
        local path = "sprites/BOSS/polvo/image_" .. i .. ".png"
        local ok, img = pcall(LG.newImage, path)
        if ok then frames[#frames + 1] = img end
    end
    totalFrames = #frames

    bossPolvo.x = LARGURA_MAPA / 2 - bossPolvo.w / 2
    bossPolvo.y = 60

    shaderBranco = LG.newShader([[
        vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screenCoords) {
            vec4 pixel = Texel(tex, texCoords);
            if (pixel.a < 0.01) discard;
            return vec4(1.0, 1.0, 1.0, pixel.a);
        }
    ]])
end

function bossPolvo.reset()
    bossPolvo.ativo = false
    bossPolvo.vida = bossPolvo.vidaMax
    frameAtual = 1
    timerAnim = 0
    invencivel = false
    timerInvencivel = 0
    mostrarSprite = true
    timerCooldownEspada = 0
    laser.fase = FASE_PAUSA
    laser.timer = laser.duracaoPausa
end

function bossPolvo.receberDano(qtd)
    if not bossPolvo.ativo or invencivel then return end
    bossPolvo.vida = math.max(0, bossPolvo.vida - qtd)
    invencivel = true
    timerInvencivel = duracaoInvencivel
    timerPiscar = intervaloPiscar
    mostrarSprite = true
end

local function centroJogador(jogador)
    return jogador.x + jogador.w / 2, jogador.y + jogador.h / 2
end

function bossPolvo.atualizar(dt, jogador, combate)
    if not bossPolvo.ativo then
        if jogador.x > LARGURA_MAPA / 2 - 200 then
            bossPolvo.ativo = true
            laser.fase = FASE_PAUSA
            laser.timer = 1.5
        end
        return
    end

    if bossPolvo.vida <= 0 then
        bossPolvo.ativo = false
        invencivel = false
        mostrarSprite = false
        return
    end

    -- Piscar
    if invencivel then
        timerInvencivel = timerInvencivel - dt
        timerPiscar = timerPiscar - dt
        if timerPiscar <= 0 then
            timerPiscar = intervaloPiscar
            mostrarSprite = not mostrarSprite
        end
        if timerInvencivel <= 0 then
            invencivel = false
            mostrarSprite = true
        end
    end

    -- Cooldown espada
    if timerCooldownEspada > 0 then
        timerCooldownEspada = timerCooldownEspada - dt
    end

    -- Animação
    timerAnim = timerAnim + dt
    if timerAnim >= 1 / fpsAnim then
        timerAnim = 0
        frameAtual = frameAtual % totalFrames + 1
    end

    laser.origemX = bossPolvo.x + bossPolvo.w / 2 - 15
    laser.origemY = bossPolvo.y + bossPolvo.h * 0.30

    local jx, jy = centroJogador(jogador)
    laser.timer = laser.timer - dt

    if laser.fase == FASE_PAUSA then
        if laser.timer <= 0 then
            laser.fase = FASE_ALERTA
            laser.timer = laser.duracaoAlerta
        end
    elseif laser.fase == FASE_ALERTA then
        laser.alvoX = jx
        laser.alvoY = jy
        if laser.timer <= 0 then
            laser.fase = FASE_LASER
            laser.timer = laser.duracaoLaser
        end
    elseif laser.fase == FASE_LASER then
        local lx1, ly1 = laser.origemX, laser.origemY
        local dx = laser.alvoX - lx1
        local dy = laser.alvoY - ly1
        local dist = math.sqrt(dx*dx + dy*dy)
        local lx2, ly2 = lx1, ly1
        if dist > 0 then
            lx2 = lx1 + (dx/dist) * 1200
            ly2 = ly1 + (dy/dist) * 1200
        end
        local px, py = jx, jy
        local t = ((px-lx1)*(lx2-lx1) + (py-ly1)*(ly2-ly1)) /
                  ((lx2-lx1)^2 + (ly2-ly1)^2 + 0.0001)
        t = math.max(0, math.min(1, t))
        local cx2 = lx1 + t*(lx2-lx1)
        local cy2 = ly1 + t*(ly2-ly1)
        if math.sqrt((px-cx2)^2 + (py-cy2)^2) < 20 then
            combate.receberDano(jogador, 20)
        end
        if laser.timer <= 0 then
            laser.fase = FASE_PAUSA
            laser.timer = laser.duracaoPausa
        end
    end
end

function bossPolvo.verificarDanoProjeteis(listaProjeteis)
    if not bossPolvo.ativo or bossPolvo.vida <= 0 then return end
    for i = #listaProjeteis, 1, -1 do
        local p = listaProjeteis[i]
        if p.tipo ~= "boss" then
            if p.x > bossPolvo.x and p.x < bossPolvo.x + bossPolvo.w and
               p.y > bossPolvo.y and p.y < bossPolvo.y + bossPolvo.h then
                bossPolvo.receberDano(p.dano or 8)
                table.remove(listaProjeteis, i)
            end
        end
    end
end

function bossPolvo.verificarDanoEspada(jogador)
    if not bossPolvo.ativo or bossPolvo.vida <= 0 then return end
    if jogador.arma ~= "espada" or jogador.anim.estado ~= "atacando" then return end
    if timerCooldownEspada > 0 then return end

    local sx = jogador.x + (jogador.virandoDireita and jogador.w or -40)
    local sy = jogador.y
    if sx < bossPolvo.x + bossPolvo.w and sx + 50 > bossPolvo.x and
       sy < bossPolvo.y + bossPolvo.h and sy + jogador.h > bossPolvo.y then
        bossPolvo.receberDano(15)
        timerCooldownEspada = cooldownEspada
    end
end

function bossPolvo.draw()
    if not bossPolvo.ativo then return end

    if mostrarSprite and frames[frameAtual] then
        local img = frames[frameAtual]
        local escala = bossPolvo.w / img:getWidth()
        if invencivel and shaderBranco then
            LG.setShader(shaderBranco)
        end
        LG.setColor(1, 1, 1)
        LG.draw(img, bossPolvo.x, bossPolvo.y, 0, escala, escala)
        LG.setShader()
    end

    if not bossPolvo.ativo then return end

    local ox, oy = laser.origemX, laser.origemY

    if laser.fase == FASE_ALERTA then
        local dx = laser.alvoX - ox
        local dy = laser.alvoY - oy
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            local ex = ox + (dx/dist) * 1200
            local ey = oy + (dy/dist) * 1200
            local alpha = 0.4 + 0.4 * math.abs(math.sin(love.timer.getTime() * 8))
            LG.setColor(1, 0, 0, alpha)
            LG.setLineWidth(3)
            LG.line(ox, oy, ex, ey)
            LG.setColor(1, 0.2, 0.2, alpha)
            LG.circle("fill", laser.alvoX, laser.alvoY, 12)
            LG.setLineWidth(1)
        end
    elseif laser.fase == FASE_LASER then
        local dx = laser.alvoX - ox
        local dy = laser.alvoY - oy
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            local ex = ox + (dx/dist) * 1200
            local ey = oy + (dy/dist) * 1200
            LG.setColor(1, 0, 0, 0.3)
            LG.setLineWidth(20)
            LG.line(ox, oy, ex, ey)
            LG.setColor(1, 0.3, 0.3, 0.7)
            LG.setLineWidth(8)
            LG.line(ox, oy, ex, ey)
            LG.setColor(1, 1, 1, 1)
            LG.setLineWidth(3)
            LG.line(ox, oy, ex, ey)
            LG.setLineWidth(1)
        end
    end

    LG.setColor(1, 1, 1)
end

return bossPolvo