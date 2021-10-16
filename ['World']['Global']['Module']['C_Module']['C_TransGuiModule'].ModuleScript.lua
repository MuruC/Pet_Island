--- 客户端传送Gui模块
-- @module transport gui, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru

local C_TransGui, this = {}, nil

--- 初始化
function C_TransGui:Init()
    --info("C_MainGui:Init")
    this = self
    self:InitListeners()
    -- 主界面ui
    self.mainGui = localPlayer.Local.ControlGui
    -- 传送面板ui
    self.transGui = localPlayer.Local.TransGui
    -- 传送面板背景
    self.transBg = self.transGui.TransBg
    -- 退出传送面板
    self.quitTransPnl = self.transBg.Quit
    -- 传送按钮面板
    self.transBtnPnl = self.transBg.BtnPnl
    -- 打开便捷传送面板
    self.exploreBtn = self.transBtnPnl.OpenExplore
    -- 传送到主城
    self.transToMainLand = self.transBtnPnl.TransToMainLand
    -- 传送到家园
    self.transToHome = self.transBtnPnl.TransToHome
    -- 便捷传送按钮面板
    self.exploreBtnsPnl = self.transBg.ExplorePosPnl
    -- 从便捷传送返回按钮面板
    self.backToBtns = self.exploreBtnsPnl.BackToTransBg
    -- 便捷传送按钮
    self.exploreBtns = {}

    -- 全部gui
    local playerLocal = localPlayer.Local
    self.allGui = {
        playerLocal.HatchGui,playerLocal.TransGui,playerLocal.ControlGui,playerLocal.AchieveGui,playerLocal.BagGui,
        playerLocal.MergeGui,playerLocal.StoreGui
    }

    self:InitConnectBtnEvent()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_TransGui:Update(dt)
end

--- 初始化C_UIMgr自己的监听事件
function C_TransGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_TransGui, "C_TransGui", this)
end

local constDefHomeBgm = ConstDef.bgmEnum.mainIsland

--- 初始绑定按钮事件
function C_TransGui:InitConnectBtnEvent()
        -- 关闭传送功能面板
        self.quitTransPnl.OnDown:Connect(
            function()
                C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_05)
                self:CloseTransGui()
            end
        )
      -- 回家按钮
      self.transToHome.OnDown:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_01)
            C_LoadGui:EnterTransportEvent(constDefHomeBgm)
            C_PlayerStatusMgr:ReturnHome()
            C_PetMgr:RemoveAllWorkingPets()
            C_MineGui:RemoveAllProgressBars()
            C_PetMgr:CurPetsMoveToPlayerPos()
			C_Guide:ProcessGuideEvent('pressHomeBtn')
            self:CloseTransGui()
            -- 玩家不可以使用自动寻矿的功能
            C_MainGui.autoFindMine.CantFindMine:SetActive(true)
        end
    )
    -- 打开便捷传送面板
    self.exploreBtn.OnDown:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_03)
            self.transBtnPnl:SetActive(false)
            self.exploreBtnsPnl:SetActive(true)
        end
    )
    -- 从便捷传送返回传送按钮面板
    self.backToBtns.OnDown:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_05)
            self.transBtnPnl:SetActive(true)
            self.exploreBtnsPnl:SetActive(false)
        end
    )
    -- 传送到主城按钮
    self.transToMainLand.OnDown:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_01)
            C_LoadGui:EnterTransportEvent(constDefHomeBgm)
            self:CloseTransGui()
            C_PlayerStatusMgr:ReturnMainLand()
            C_MineGui:RemoveAllProgressBars()
            C_PetMgr:CurPetsMoveToPlayerPos()
        end
    )
end

--- 初始化便捷传送按钮
function C_TransGui:InitExploreBtns()
    for a = 4, 1, -1 do
        local pnl
        if a == 1 then
            pnl = self.exploreBtnsPnl.ForestBg
        elseif a == 2 then
            pnl = self.exploreBtnsPnl.HouseBg
        elseif a == 3 then
            pnl = self.exploreBtnsPnl.SeaBg
        else
            pnl = self.exploreBtnsPnl.DesertBg
        end

        for z = 5, 1, -1 do
            local btnName = "z" .. tostring(z) .. "Btn"
            local btn = pnl:GetChild(btnName)
            local index = "a" .. tostring(a) .. "z" .. tostring(z)
            self.exploreBtns[index] = btn
            btn.OnDown:Connect(
                function()
                    C_AudioMgr:Stop(C_AudioMgr.allAudios.sound_game_06)
                    C_LoadGui:EnterTransportEvent(a)
                    C_PlayerStatusMgr:SetIfPlayerInMainLand(false)
                    C_PlayerStatusMgr.bInHome = false
                    C_PlayerStatusMgr:ExploreTheLevels(index)
                    C_PetMgr:CurPetsMoveToPlayerPos()
                    C_PlayerStatusMgr.areaIndex = a
                    C_PlayerStatusMgr.zoneIndex = z
                    -- 玩家可以使用自动寻矿的功能
                    C_MainGui.autoFindMine.CantFindMine:SetActive(false)
                    -- 计算自动寻路
                    --PathFinding:CreateNavMap(a, z)
                    C_MainGui:CheckIfShowMainGui(true)
                end
            )
        end
    end
end

local constDefBtnEnum = ConstDef.btnEnum

--- 绑定按钮函数
--- @param _btn string 按钮
--- @param _func function 函数
function C_TransGui:BindBtnEventCallback(_btn,_func)
    if _btn == constDefBtnEnum.home then
        self.transToHome.OnClick:Connect(_func)
    end
end

--- 按钮和函数断开连接
--- @param _btn string 按钮
--- @param _func function 函数
function C_TransGui:DisconnectBtnEvent(_btn,_func)
    if _btn == constDefBtnEnum.home then
        self.transToHome.OnClick:Disconnect(_func)
    end
end

--- 打开传送面板
function C_TransGui:OpenTransGui()
    for _, gui in pairs(self.allGui) do
        gui:SetActive(false)
    end
    local bgObj = self.transBg.TransBg
    local oldSize = bgObj.Size
    bgObj.Size = Vector2(0,0)
    self.transBtnPnl:SetActive(false)
    self.quitTransPnl:SetActive(false)
    self.exploreBtnsPnl:SetActive(false)
    self.transGui:SetActive(true)
    bgObj:SetActive(true)
    local bgObjTweener = Tween:TweenProperty(bgObj, {Size = oldSize}, 0.3, Enum.EaseCurve.BackOut)    --构造一个值插值器
    bgObjTweener.OnComplete:Connect(function()
        self.transBtnPnl:SetActive(true)
        self.quitTransPnl:SetActive(true)
        bgObjTweener:Destroy()
    end)
    bgObjTweener:Play()
end

--- 关闭传送面板
function C_TransGui:CloseTransGui()
    local bgObj = self.transBg.TransBg
    local oldSize = bgObj.Size
    self.transBtnPnl:SetActive(false)
    self.quitTransPnl:SetActive(false)
    self.exploreBtnsPnl:SetActive(false)
    local bgObjTweener = Tween:TweenProperty(bgObj, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)    --构造一个值插值器
    bgObjTweener.OnComplete:Connect(function()
        C_MainGui:CheckIfShowMainGui(true)
        bgObj.Size = oldSize
        bgObjTweener:Destroy()
    end)
    bgObjTweener:Play()
end

local constDefZoneItemEnum = ConstDef.ItemCategoryEnum.Zones   --- 玩家物品中的区域枚举
--- 刷新便捷传送按钮
function C_TransGui:RefrshExploreBtns()
    local zones = C_PlayerDataMgr:GetItem(constDefZoneItemEnum)
    if zones['Area1'] then
        for k, v in pairs(zones['Area1']) do
            if v <= 5 then
                self.exploreBtnsPnl.ForestBg:GetChild('z'..tostring(v)..'Btn'):SetActive(true)
            end
        end
    end
    if zones['Area2']then
        for k, v in pairs(zones['Area2']) do
            if v <= 5 then
                self.exploreBtnsPnl.HouseBg:GetChild('z'..tostring(v)..'Btn'):SetActive(true)
            end
        end
    end
    if zones['Area3']then
        for k, v in pairs(zones['Area3']) do
            if v <= 5 then
                self.exploreBtnsPnl.SeaBg:GetChild('z'..tostring(v)..'Btn'):SetActive(true)
            end
        end
    end
    if zones['Area4']then
        for k, v in pairs(zones['Area4']) do
            if v <= 5 then
                self.exploreBtnsPnl.DesertBg:GetChild('z'..tostring(v)..'Btn'):SetActive(true)
            end
        end
    end
end

return C_TransGui