local save = {}

local arquivo = "save.dat"

function save.salvar(dados)
    local conteudo = ""
    for k, v in pairs(dados) do
        conteudo = conteudo .. k .. "=" .. tostring(v) .. "\n"
    end
    love.filesystem.write(arquivo, conteudo)
end

function save.carregar()
    if not love.filesystem.getInfo(arquivo) then
        return nil
    end
    local conteudo = love.filesystem.read(arquivo)
    local dados = {}
    for linha in conteudo:gmatch("[^\n]+") do
        local k, v = linha:match("(.+)=(.+)")
        if k and v then
            if v == "true" then v = true
            elseif v == "false" then v = false
            elseif tonumber(v) then v = tonumber(v)
            end
            dados[k] = v
        end
    end
    return dados
end

function save.existe()
    return love.filesystem.getInfo(arquivo) ~= nil
end

function save.deletar()
    love.filesystem.remove(arquivo)
end

return save