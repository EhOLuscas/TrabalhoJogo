local musica = {}

local tracks = {}
local trackAtual = nil
local nomeTrackAtual = nil

function musica.carregar()
    local pathTrilha1 = "sprites/musica fundo/Dark Horror DmitryTaras.ogv"
    local pathTrilha2 = "sprites/musica fundo/Horror Train By SUNRIZISH.ogv"

    local ok1, res1 = pcall(love.audio.newSource, pathTrilha1, "stream")
    if ok1 then
        tracks.trilha1 = res1
        tracks.trilha1:setLooping(true)
    else
        print("Erro ao carregar musica Trilha 1 (Dark Horror): ", res1)
    end

    local ok2, res2 = pcall(love.audio.newSource, pathTrilha2, "stream")
    if ok2 then
        tracks.trilha2 = res2
        tracks.trilha2:setLooping(true)
    else
        print("Erro ao carregar musica Trilha 2 (Horror Train): ", res2)
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
        local vol = (volumeMusica or 100) / 100
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
end

function musica.update(dt)
    if trackAtual then
        local vol = (volumeMusica or 100) / 100
        trackAtual:setVolume(vol)
    end
end

return musica
