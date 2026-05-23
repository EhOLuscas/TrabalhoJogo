local som = {}

local sons = {}

local function carregarEfeitoSonoro(nomeBase)
    local extensions = { ".mp3", ".ogv", ".ogg", ".wav" }
    for _, ext in ipairs(extensions) do
        local path = "sprites/efeitos sonoros/" .. nomeBase .. ext
        local success, res = pcall(love.audio.newSource, path, "static")
        if success then
            return res
        end
    end
    -- Support spelling variants
    if nomeBase == "sordAttack" or nomeBase == "swordAttack" then
        local other = (nomeBase == "sordAttack") and "swordAttack" or "sordAttack"
        for _, ext in ipairs(extensions) do
            local path = "sprites/efeitos sonoros/" .. other .. ext
            local success, res = pcall(love.audio.newSource, path, "static")
            if success then
                return res
            end
        end
    elseif nomeBase == "disparoCanhao" or nomeBase == "Disparo de canhao" then
        local other = (nomeBase == "disparoCanhao") and "Disparo de canhao" or "disparoCanhao"
        for _, ext in ipairs(extensions) do
            local path = "sprites/efeitos sonoros/" .. other .. ext
            local success, res = pcall(love.audio.newSource, path, "static")
            if success then
                return res
            end
        end
    end
    return nil
end

function som.carregar()
    sons.ataqueRato = carregarEfeitoSonoro("ataqueRATO")
    sons.ratoParado = carregarEfeitoSonoro("ratoParado")
    sons.laser = carregarEfeitoSonoro("laser")
    sons.polvoParado = carregarEfeitoSonoro("polvoParado")
    sons.passarFase = carregarEfeitoSonoro("passar-de-fase")
    sons.disparoCanhao = carregarEfeitoSonoro("Disparo de canhao")
    sons.swordAttack = carregarEfeitoSonoro("swordAttack") or carregarEfeitoSonoro("sordAttack")
    sons.teletransport = carregarEfeitoSonoro("teletransport")
    sons.bruxa = carregarEfeitoSonoro("bruxa")

    -- Set loops for idle sounds
    if sons.ratoParado then
        sons.ratoParado:setLooping(true)
    end
    if sons.polvoParado then
        sons.polvoParado:setLooping(true)
    end
end

function som.tocar(nome)
    local s = sons[nome]
    if s then
        s:seek(0)
        s:play()
    end
end

function som.parar(nome)
    local s = sons[nome]
    if s and s:isPlaying() then
        s:stop()
    end
end

function som.atualizarBossSons(mapaNome, bossPolvoAtivo, bossRatoAtivo)
    -- Nyx'Thalor (polvo) idle loop
    if mapaNome == "fase1" and bossPolvoAtivo then
        if sons.polvoParado and not sons.polvoParado:isPlaying() then
            sons.polvoParado:play()
        end
    else
        if sons.polvoParado and sons.polvoParado:isPlaying() then
            sons.polvoParado:stop()
        end
    end

    -- Vorl'Guth (rato) idle loop
    if mapaNome == "fase2" and bossRatoAtivo then
        if sons.ratoParado and not sons.ratoParado:isPlaying() then
            sons.ratoParado:play()
        end
    else
        if sons.ratoParado and sons.ratoParado:isPlaying() then
            sons.ratoParado:stop()
        end
    end
end

return som
