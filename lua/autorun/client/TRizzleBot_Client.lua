-- This is thr flashlight check for the bots
net.Receive("TRizzleBotFlashlight", function()
    local flashlights = {}
    for _, ply in pairs(player.GetBots()) do
        flashlights[ply] = render.GetLightColor(ply:EyePos())
    end

    net.Start("TRizzleBotFlashlight")
    net.WriteTable(flashlights)
    net.SendToServer()
end)

-- This checks the fog level and sends it back to the server
-- This will only be run every few seconds, Currently W.I.P
net.Receive("TRizzleBotFogCheck", function()
    local flashlights = {}
    for _, ply in pairs(player.GetBots()) do
        flashlights[ply] = render.GetLightColor(ply:EyePos())
    end

    net.Start("TRizzleBotFogCheck")
    net.WriteTable(flashlights)
    net.SendToServer()
end)
