net.Receive("TRizzleBotFlashlight", function()
    local flashlights = {}
    for _, ply in pairs(player.GetBots()) do
        flashlights[ply] = render.GetLightColor(ply:EyePos())
    end

    net.Start("TRizzleBotFlashlight")
    net.WriteTable(flashlights)
    net.SendToServer()
end)