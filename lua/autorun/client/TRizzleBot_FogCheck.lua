net.Receive("TRizzleBotFogCheck", function()
    local flashlights = {}
    for _, ply in pairs(player.GetBots()) do
        flashlights[ply] = render.GetLightColor(ply:EyePos())
    end

    net.Start("TRizzleBotFogCheck")
    net.WriteTable(flashlights)
    net.SendToServer()
end)
