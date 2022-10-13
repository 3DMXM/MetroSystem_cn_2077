local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

settings = {
    nativeOptions = {},
    nativeSettings = nil
}

function settings.setupNative(ts)
    local nativeSettings = GetMod("nativeSettings")
    settings.nativeSettings = nativeSettings
    if not nativeSettings then
        print("[MetroSystem] Error: NativeSettings lib not found, switching to ImGui UI!")
        ts.settings.showImGui = true
        config.saveFile("data/config.json", ts.settings)
        return
    end

    local cetVer = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip) -- <-- This has been made by psiberx, all credits to him
        return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
    end)))

    if cetVer < 1.18 then
        print("[MetroSystem] Error: CET version below recommended, switched to ImGui settings UI!")
        ts.settings.showImGui = true
        config.saveFile("data/config.json", ts.settings)
        return
    end

    nativeSettings.addTab("/trainSystem", "地铁系统")
    nativeSettings.addSubcategory("/trainSystem/train", "地铁设置")
    nativeSettings.addSubcategory("/trainSystem/station", "车站设置")
    nativeSettings.addSubcategory("/trainSystem/misc", "其他设置")

    settings.nativeOptions["trainSpeed"] = nativeSettings.addRangeInt("/trainSystem/train", "地铁速度", "这里设置地铁的速度, 下次进入/离开车站时应用", 1, 50, 1, ts.settings.trainSpeed, ts.defaultSettings.trainSpeed, function(value)
        ts.settings.trainSpeed = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainTPPDist"] = nativeSettings.addRangeInt("/trainSystem/train", "地铁第三人称视角距离", "这里设置第三人称视角时视角的距离,下此进入/离开 车站时应用", 6, 30, 1, ts.settings.camDist, ts.defaultSettings.camDist, function(value)
        ts.settings.camDist = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = "右前方", [2] = "右后方", [3] = "左后方", [4] = "左前方"}
    settings.nativeOptions["trainSeat"] = nativeSettings.addSelectorString("/trainSystem/train", "默认 FPP 位置", "切换到第一人称后,决定玩家的默认位置", list, ts.settings.defaultSeat, ts.defaultSettings.defaultSeat, function(value)
        ts.settings.defaultSeat = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["noHudTrain"] = nativeSettings.addSwitch("/trainSystem/train", "在地铁上隐藏游戏界面", "这里可以设置当玩家进入地铁后, 可隐藏整个HUD界面", ts.settings.noHudTrain, ts.defaultSettings.noHudTrain, function(state)
        ts.settings.noHudTrain = state
        config.saveFile("data/config.json", ts.settings)

        if ts.stationSys.activeTrain then
            if ts.stationSys.activeTrain.playerMounted then
                utils.toggleHUD(not state)
            end
        end
    end)

    settings.nativeOptions["trainTPPOnly"] = nativeSettings.addSwitch("/trainSystem/train", "仅第三人称视角", "禁用第一人称视角. 当你遇到FPV问题时, 请启用它", ts.settings.tppOnly, ts.defaultSettings.tppOnly, function(state)
        ts.settings.tppOnly = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["stationHold"] = nativeSettings.addRangeFloat("/trainSystem/station", "车辆停靠时间", "通过这个设置可以 增加/减少 地铁在车站的停靠时间.", 0.05, 5, 0.05, "%.2f", ts.settings.holdMult, 1, function(value)
        ts.settings.holdMult = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["stationPrice"] = nativeSettings.addRangeInt("/trainSystem/station", "每站价格", "这里设置您每经过一个站需要支付多少的费用.", 1, 50, 1, ts.settings.moneyPerStation, ts.defaultSettings.moneyPerStation, function(value)
        ts.settings.moneyPerStation = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["elevatorTime"] = nativeSettings.addRangeFloat("/trainSystem/station", "电梯时间", "这里设置您在乘坐电梯时所需要的时间 (单位:秒) .", 3, 15, 0.5, "%.2f", ts.settings.elevatorTime, ts.defaultSettings.elevatorTime, function(value)
        ts.settings.elevatorTime = value
        config.saveFile("data/config.json", ts.settings)
    end)

    local list = {[1] = "默认", [2] = "Spicy's E3 HUD", [3] = "Superior UI"}
    settings.nativeOptions["uiLayout"] = nativeSettings.addSelectorString("/trainSystem/misc", "HUD Mod修复", "如果你使用了 E3 HUD mod 或 Superior UI mod, 请在这里选择它, 以确保 \"下一站\" 的文本位置和颜色正常", list, ts.settings.uiLayout, ts.defaultSettings.uiLayout, function(value)
        ts.settings.uiLayout = value
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end)

    settings.nativeOptions["unlockAllTracks"] = nativeSettings.addSwitch("/trainSystem/misc", "强制解锁所有轨道", "启用后即使在序章完成之前, 也能将整个地铁路线解锁.", ts.settings.unlockAllTracks, ts.defaultSettings.unlockAllTracks, function(state)
        ts.settings.unlockAllTracks = state
        ts.trackSys:load()
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["elevatorGlitch"] = nativeSettings.addSwitch("/trainSystem/misc", "电梯场景切换动画", "设置在进出电梯时是否显示切换动画 .", ts.settings.elevatorGlitch, ts.defaultSettings.elevatorGlitch, function(state)
        ts.settings.elevatorGlitch = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["trainGlitch"] = nativeSettings.addSwitch("/trainSystem/misc", "地铁场景切换动画", "设置在进出地铁时是否显示切换动画 .", ts.settings.trainGlitch, ts.defaultSettings.trainGlitch, function(state)
        ts.settings.trainGlitch = state
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["tppOffset"] = nativeSettings.addRangeFloat("/trainSystem/misc", "第三人称视角玩家偏移", "用于解决在第三人称视角时, 玩家将头露出的罕见问题, 降低这个值以降低玩家位置", 1, 2, 0.1, "%.1f", ts.settings.tppOffset, ts.defaultSettings.tppOffset, function(value)
        ts.settings.tppOffset = value
        config.saveFile("data/config.json", ts.settings)
    end)

    settings.nativeOptions["showImGui"] = nativeSettings.addSwitch("/trainSystem/misc", "显示 ImGui 设置UI", "在单独的 ImGui 窗口中显示此处的所有设置, 当CET 界面打开时可以看到, 当CET 版本对于 NativeSettings 来说太低时, 建议打开这个选项", ts.settings.showImGui, ts.defaultSettings.showImGui, function(state)
        ts.settings.showImGui = state
        config.saveFile("data/config.json", ts.settings)
    end)
end

function settings.draw(ts) -- Draw alternative ImGui window
    ts.CPS:setThemeBegin()
    ImGui.Begin("Metro System Config", ImGuiWindowFlags.AlwaysAutoResize)

    if ts.observers.noSave then
        ImGui.PushStyleColor(ImGuiCol.Button, 0xff777777)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0xff777777)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0xff777777)
        ImGui.Button("地图速度目前不可用")
        ImGui.PopStyleColor(3)
    else
        ts.settings.trainSpeed, changed = ImGui.InputInt("地铁速度", ts.settings.trainSpeed)
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSpeed"], ts.settings.trainSpeed) end
        if changed then config.saveFile("data/config.json", ts.settings) end
    end

    ts.settings.camDist, changed = ImGui.InputInt("地铁第三人称视角距离", ts.settings.camDist)
    ts.settings.camDist = math.min(math.max(ts.settings.camDist, 6), 22)
    if changed then
        config.saveFile("data/config.json", ts.settings)
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainTPPDist"], ts.settings.camDist) end
    end

    ImGui.Text("默认座位:")

    if ImGui.RadioButton("右前方", ts.settings.defaultSeat == 1) then
        ts.settings.defaultSeat = 1
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("右后方", ts.settings.defaultSeat == 2) then
        ts.settings.defaultSeat = 2
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("左后方", ts.settings.defaultSeat == 3) then
        ts.settings.defaultSeat = 3
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.SameLine()

    if ImGui.RadioButton("左前方", ts.settings.defaultSeat == 4) then
        ts.settings.defaultSeat = 4
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainSeat"], ts.settings.defaultSeat) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.noHudTrain, changed = ImGui.Checkbox("在地铁上隐藏游戏界面", ts.settings.noHudTrain)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["noHudTrain"], ts.settings.noHudTrain) end
        config.saveFile("data/config.json", ts.settings)

        if ts.stationSys.activeTrain then
            if ts.stationSys.activeTrain.playerMounted then
                utils.toggleHUD(not ts.settings.noHudTrain)
            end
        end
    end

    ts.settings.tppOnly, changed = ImGui.Checkbox("仅第三人称视角", ts.settings.tppOnly)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainTPPOnly"], ts.settings.tppOnly) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ts.settings.holdMult, changed = ImGui.InputFloat("车辆停靠时间", ts.settings.holdMult, 1, 1000, "%.2f")
    ts.settings.holdMult = math.min(math.max(ts.settings.holdMult, 0.2), 5)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["stationHold"], ts.settings.holdMult) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.moneyPerStation, changed = ImGui.InputInt("每站价格", ts.settings.moneyPerStation)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["stationPrice"], ts.settings.moneyPerStation) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.elevatorTime, changed = ImGui.InputFloat("电梯时间", ts.settings.elevatorTime, 3, 15, "%.1f")
    ts.settings.elevatorTime = math.min(math.max(ts.settings.elevatorTime, 3), 15)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["elevatorTime"], ts.settings.elevatorTime) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Separator()

    ts.settings.tppOffset, changed = ImGui.InputFloat("第三人称视角玩家偏移", ts.settings.tppOffset, 1, 2, "%.1f")
    ts.settings.tppOffset = math.min(math.max(ts.settings.tppOffset, 1), 2)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["tppOffset"], ts.settings.tppOffset) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.Text("HUD Mod 修复:")

    if ImGui.RadioButton("默认", ts.settings.uiLayout == 1) then
        ts.settings.uiLayout = 1
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Spicy's E3 HUD", ts.settings.uiLayout == 2) then
        ts.settings.uiLayout = 2
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ImGui.SameLine()

    if ImGui.RadioButton("Superior UI", ts.settings.uiLayout == 3) then
        ts.settings.uiLayout = 3
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["uiLayout"], ts.settings.uiLayout) end
        config.saveFile("data/config.json", ts.settings)
        if ts.observers.hudText then
            ts.observers.hudText:SetMargin(utils.generateHUDMargin(ts.settings.uiLayout))
            ts.observers.hudText:SetTintColor(utils.generateHUDColor(ts.settings.uiLayout))
        end
    end

    ts.settings.unlockAllTracks, changed = ImGui.Checkbox("强制解锁所有轨道", ts.settings.unlockAllTracks)
    if changed then
        ts.trackSys:load()
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["unlockAllTracks"], ts.settings.unlockAllTracks) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.elevatorGlitch, changed = ImGui.Checkbox("电梯故障效果", ts.settings.elevatorGlitch)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["elevatorGlitch"], ts.settings.elevatorGlitch) end
        config.saveFile("data/config.json", ts.settings)
    end

    ts.settings.trainGlitch, changed = ImGui.Checkbox("地铁故障效果", ts.settings.trainGlitch)
    if changed then
        if settings.nativeSettings then settings.nativeSettings.setOption(settings.nativeOptions["trainGlitch"], ts.settings.trainGlitch) end
        config.saveFile("data/config.json", ts.settings)
    end

    ImGui.End()
    ts.CPS:setThemeEnd()
end

return settings