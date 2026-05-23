local musica = {}

local tracks = {}
local trackAtual = nil
local nomeTrackAtual = nil

function musica.carregar()
    local pathColten = "sprites/musica fundo/Colten Tyler Williams - Gathering - Creative Cut - Distorted.ogv"
    local pathMichael = "sprites/musica fundo/Michael Oates - Outrunner - Creative Cut - Minimal.ogv"

    local ok1, res1 = pcall(love.audio.newSource, pathColten, "stream")
    if ok1 then
        tracks.colten = res1
        tracks.colten:setLooping(true)
    else
        print("Erro ao carregar musica Colten: ", res1)
    end

    local ok2, res2 = pcall(love.audio.newSource, pathMichael, "stream")
    if ok2 then
        tracks.michael = res2
        tracks.michael:setLooping(true)
    else
        print("Erro ao carregar musica Michael: ", res2)
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
