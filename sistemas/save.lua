-- ============================================================
-- sistemas/save.lua
-- Sistema simples de save em arquivo de texto (chave=valor).
-- Salva o mapa atual, a arma equipada e se o canhão foi
-- desbloqueado. Permite carregar, verificar existência e deletar.
-- ============================================================

local save    = {}
local arquivo = "save.dat" -- Nome do arquivo no diretório de save do LÖVE

-- Serializa e escreve os dados no arquivo de save
function save.salvar(dados)
    local conteudo = ""
    for k, v in pairs(dados) do
        conteudo = conteudo .. k .. "=" .. tostring(v) .. "\n"
    end
    love.filesystem.write(arquivo, conteudo)
end

-- Lê e desserializa o arquivo de save.
-- Retorna uma tabela com os dados, ou nil se o arquivo não existir.
function save.carregar()
    if not love.filesystem.getInfo(arquivo) then return nil end

    local dados   = {}
    local conteudo = love.filesystem.read(arquivo)

    for linha in conteudo:gmatch("[^\n]+") do
        local k, v = linha:match("(.+)=(.+)")
        if k and v then
            -- Converte tipos automaticamente
            if     v == "true"    then v = true
            elseif v == "false"   then v = false
            elseif tonumber(v)    then v = tonumber(v)
            end
            dados[k] = v
        end
    end

    return dados
end

-- Retorna true se um arquivo de save existe
function save.existe()
    return love.filesystem.getInfo(arquivo) ~= nil
end

-- Remove o arquivo de save (usado ao iniciar novo jogo ou após vitória)
function save.deletar()
    love.filesystem.remove(arquivo)
end

return save
