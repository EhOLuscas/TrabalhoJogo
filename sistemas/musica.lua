local musica = {}

local tracks = {}
local trackAtual = nil
local nomeTrackAtual = nil
musica.bossAtivo = false

function musica.carregar()
    local pathTrilha1 = "sprites/musica fundo/music1.ogv"
    local pathTrilha2 = "sprites/musica fundo/music2.ogv"

    local ok1, res1 = pcall(love.audio.newSource, pathTrilha1, "stream")
    if ok1 then
        tracks.musica1 = res1
        tracks.musica1:setLooping(true)
    else
        print("Erro ao carregar musica Trilha 1 (music1.ogv): ", res1)
    end

    local ok2, res2 = pcall(love.audio.newSource, pathTrilha2, "stream")
    if ok2 then
        tracks.musica2 = res2
        tracks.musica2:setLooping(true)
    else
        print("Erro ao carregar musica Trilha 2 (music2.ogv): ", res2)
    end
end

function musica.tocar(nome)
    if nomeTrackAtual == nome then
        if trackAtual and not trackAtual:isPlaying() then
            trackAtual:play()
        end
        return
    end

    musica.parar()

    local novaTrack = tracks[nome]
    if novaTrack then
        trackAtual = novaTrack
        nomeTrackAtual = nome
        local mult = musica.bossAtivo and 1.5 or 1.0
        local vol = math.min(1.0, ((volumeMusica or 20) / 100) * mult)
        trackAtual:setVolume(vol)
        trackAtual:play()
    end
end

function musica.seek(segundos)
    if trackAtual then
        pcall(function() trackAtual:seek(segundos, "seconds") end)
    end
end

function musica.parar()
    if trackAtual then
        trackAtual:stop()
    end
    trackAtual = nil
    nomeTrackAtual = nil
    musica.bossAtivo = false
end

function musica.setBossAtivo(ativo)
    musica.bossAtivo = ativo
    if trackAtual then
        local mult = musica.bossAtivo and 1.5 or 1.0
        local vol = math.min(1.0, ((volumeMusica or 20) / 100) * mult)
        trackAtual:setVolume(vol)
    end
end

function musica.update(dt)
    if trackAtual then
        local mult = musica.bossAtivo and 1.5 or 1.0
        local vol = math.min(1.0, ((volumeMusica or 20) / 100) * mult)
        trackAtual:setVolume(vol)
    end
end

return musica
