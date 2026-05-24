function love.load()
    local results = {}
    table.insert(results, "Sampling X values at Y = 540 (middle of button 1)...")
    local ok, imgData = pcall(love.image.newImageData, "sprites/imagem-menu.png")
    if not ok then
        table.insert(results, "Failed to load image: " .. tostring(imgData))
        local f = io.open("c:/Users/ypedr/TrabalhoJogo/scratch/tool/results.txt", "w")
        if f then f:write(table.concat(results, "\n")) f:close() end
        love.event.quit()
        return
    end

    local w, h = imgData:getDimensions()
    -- Scan X from 50 to 700
    for x = 50, 700, 5 do
        local r, g, b, a = imgData:getPixel(x, 540)
        table.insert(results, string.format("x=%3d: R=%.3f G=%.3f B=%.3f", x, r, g, b))
    end

    local f = io.open("c:/Users/ypedr/TrabalhoJogo/scratch/tool/results.txt", "w")
    if f then
        f:write(table.concat(results, "\n"))
        f:close()
    end
    love.event.quit()
end
