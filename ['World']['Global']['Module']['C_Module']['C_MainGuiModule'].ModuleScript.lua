local C_MainGui, this = {}, nil

--- 初始化
function C_MainGui:Init()
    --info("C_MainGui:Init")
    this = self
    self:InitListeners()

    -- 主界面ui
    self.mainGui = localPlayer.Local.ControlGui
    -- 主场景panel
    self.mainScenePnl = self.mainGui.MainSceneUI
    -- 金钱数目
    self.moneyTxt = self.mainScenePnl.MoneyBg.MoneyTxt
    -- 钻石数目
    self.diamondTxt = self.mainScenePnl.DiamondBg.DiamondTxt
    -- 显示正在装备宠物icon
    self.equippedPetIcons = self.mainScenePnl.DisplayPets.Icons
    -- 打开传送面板
    self.openTransGui = self.mainScenePnl.OpenTransBtn
    -- 传送面板
    self.transGui = localPlayer.Local.TransGui
    -- 鼓励按钮
    self.encrBtn = self.mainScenePnl.BtnsBg.EncrBtn
    -- 跳跃按钮
    self.jumpBtn = self.mainScenePnl.BtnsBg.JumpBtn
    -- 自动寻找矿按钮
    self.autoFindMine = self.mainScenePnl.BtnsBg.FindMineBtn
    -- 打开成就面板
    self.openAchieveGui = self.mainScenePnl.OpenAchieveBtn
    -- 提示可领取成就
    self.achieveHint = self.mainScenePnl.AchieveHint
    -- 打开背包面板
    self.openBag = self.mainScenePnl.OpenBagBtn
    -- 领取礼物按钮
    self.openGift = self.mainScenePnl.OpenGift

    -- 当前可领取的所有成就
    self.allReceivableAchieve = {}

    -- 金钱数目
    self.coinResNum = nil
    -- 钻石数目
    self.diamondResNum = nil

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
function C_MainGui:Update(dt)
end

--- 初始化C_MainGui自己的监听事件
function C_MainGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_MainGui, "C_MainGui", this)
end

local constDefActionEncr = ConstDef.PlayerActionTypeEnum.Encr

--- 初始绑定按钮功能
function C_MainGui:InitConnectBtnEvent()
    -- 打开传送功能面板
    self.openTransGui.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_03)
            C_TransGui:OpenTransGui()
        end
    )
    -- 打开成就面板
    self.openAchieveGui.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_03)
            C_AchieveGui:OpenAchieveGui(true)
        end
    )
    -- 鼓励按钮
    self.encrBtn.OnClick:Connect(
        function()
            local nearbyPets = C_PetMgr:ReturnNearbyWorkingPets()
            if nearbyPets == {} then
                return
            end
            NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, constDefActionEncr, 
            nearbyPets)
            localPlayer:Jump()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_12)
            C_PlayerStatusMgr:ShowEncrFx()
        end
    )
    -- 打开背包
    self.openBag.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_03)
            C_BagGui:OpenBagGui()
        end
    )
    self.mainGui.ClearDataBtn.OnClick:Connect(
        function()
            NetUtil.Fire_S('ClearPlayerDataStoreEvent',localPlayer.UserId)
        end
    )
    localPlayer.Local.LoadingGui.ClearDataBtn.OnClick:Connect(
        function()
            NetUtil.Fire_S('ClearPlayerDataStoreEvent',localPlayer.UserId)
        end
    )
end

local constDefResCoin = ConstDef.ServerResTypeEnum.Coin
local constDefResDiamond = ConstDef.ServerResTypeEnum.Diamond
--- 刷新玩家资源信息的显示
function C_MainGui:RefreshResInfo()
    --金币数
    self.moneyTxt.Text = ShowAbbreviationNum(C_PlayerDataMgr:GetValue(constDefResCoin))
    --钻石数
    self.diamondTxt.Text = ShowAbbreviationNum(C_PlayerDataMgr:GetValue(constDefResDiamond))
end

local constDefZoneItem = ConstDef.ItemCategoryEnum.Zones
--- 检测玩家金钱数量是否足够解锁下一个关卡
function C_MainGui:CheckIfHaveEnoughMoneyToUnlockNextLevel()
    local area, zone = C_PlayerStatusMgr:GetPlayerAreaAndZone()
    if zone == 5 then
        return
    end
    --- 检测下一关卡是否已经解锁
    local zones = C_PlayerDataMgr:GetItem(constDefZoneItem)
    if table.exists(zones['Area'..tostring(area)], zone + 1) then
        return
    end
    local compareResult = TStringNumCom(C_PlayerDataMgr:GetValue(constDefResCoin), PlayerCsv.CheckpointData[area][zone]['ChallengeData'])
    if compareResult or compareResult == 0 then
        C_NoticeGui:NoticeListener('EnoughMoneyToUnlockLevel')
    end
end

local constDefEquippedPet = ConstDef.EquipmentTypeEnum.Pet

--- 刷新已装备宠物显示的ui
function C_MainGui:RefreshEquippedPetIcon()
    local PetInfo = PlayerCsv.PetProperty
    local icons = self.equippedPetIcons:GetChildren()
    for k, v in pairs(icons) do
        v:SetActive(false)
    end
    local allCurPets = C_PlayerDataMgr:GetValue(constDefEquippedPet)
    for ii = 1, #allCurPets, 1 do
        local name = 'Pet' .. tostring(ii)
        local icon = self.equippedPetIcons:GetChild(name)
        icon:SetActive(true)
        local pet = C_PlayerDataMgr:GetPetInformation(allCurPets[ii])
        local imgPath = 'UI/petIcon/PetIcon_'..pet.index..'0'..tostring(pet.level)
        icon.Texture = ResourceManager.GetTexture(imgPath)
    end
end

--- 检测是否显示主界面
--- @param _bShow boolean 是否显示
function C_MainGui:CheckIfShowMainGui(_bShow)
    if _bShow then
        for _, v in pairs(self.allGui) do
            v:SetActive(false)
        end
        self.mainGui:SetActive(true)
    else
        self.mainGui:SetActive(_bShow)
    end
end

local constDefBtnEnum = ConstDef.btnEnum   ---按钮枚举

--- 绑定按钮函数
--- @param _btn string 按钮
--- @param _func function 函数
function C_MainGui:BindBtnEventCallback(_btn,_func)
    if _btn == constDefBtnEnum.trans then
        self.openTransGui.OnClick:Connect(_func)
    elseif _btn == constDefBtnEnum.findMine then
        self.autoFindMine.OnClick:Connect(_func)
    elseif _btn == constDefBtnEnum.bag then
        self.openBag.OnClick:Connect(_func)
    end
end

--- 按钮和函数断开连接
--- @param _btn string 按钮
--- @param _func function 函数
function C_MainGui:DisconnectBtnEvent(_btn,_func)
    if _btn == constDefBtnEnum.trans then
        self.openTransGui.OnClick:Disconnect(_func)
    elseif _btn == constDefBtnEnum.findMine then
        self.autoFindMine.OnClick:Disconnect(_func)
    elseif _btn == constDefBtnEnum.bag then
        self.openBag.OnClick:Disconnect(_func)
    end
end

--- 显示主界面
function C_MainGui:ShowMainGui()
    for _, v in pairs(self.allGui) do
        v:SetActive(false)
    end
    self.mainGui:SetActive(true)
end

--- 显示鼓励按钮
--- @param _bShow boolean 是否显示
function C_MainGui:ShowEncrBtn(_bShow)
    if _bShow then
        if not self.encrBtn.ActiveSelf then
            self.encrBtn:SetActive(_bShow)
        end
    else
        if self.encrBtn.ActiveSelf then
            self.encrBtn:SetActive(_bShow)
        end
    end
end

--- 移除可领取成就
--- @param _achieveId number 成就id
function C_MainGui:RemoveReceivableAchieve(_achieveId)
    self.allReceivableAchieve[_achieveId] = nil
    if GetTableLength(self.allReceivableAchieve) == 0 then
        self.achieveHint:SetActive(false)
    end
end

--- 判断可领取成就是否为空
function C_MainGui:CheckIfNoReceivableAchieve()
    if GetTableLength(self.allReceivableAchieve) == 0 then
        return true
    end
    return false
end

--- 增加可领取成就
--- @param _achieveId number 成就id
function C_MainGui:AddReceivableAchieve(_achieveId)
    self.allReceivableAchieve[_achieveId] = true
    self.achieveHint:SetActive(true)
end

--- 只显示成就按钮
function C_MainGui:OnlyShowAchieveBtn()
    local mainPnl = self.mainScenePnl
    mainPnl.BtnsBg:SetActive(false)
    self.mainGui.Joystick:SetActive(false)
    self.openBag:SetActive(false)
    mainPnl.DisplayPets:SetActive(false)
    self.openTransGui:SetActive(false)
    self.openGift:SetActive(false)
end

--- 只显示回家按钮
function C_MainGui:OnlyShowTransportBtn()
    local mainPnl = self.mainScenePnl
    mainPnl.BtnsBg:SetActive(false)
    self.mainGui.Joystick:SetActive(false)
    self.openBag:SetActive(false)
    mainPnl.DisplayPets:SetActive(false)
    self.openAchieveGui:SetActive(false)
    self.openGift:SetActive(false)
end

--- 显示全部ui
function C_MainGui:ShowAllUi()
    local mainPnl = self.mainScenePnl
    mainPnl.BtnsBg:SetActive(true)
    self.mainGui.Joystick:SetActive(true)
    self.openBag:SetActive(true)
    mainPnl.DisplayPets:SetActive(true)
    self.openTransGui:SetActive(true)
    self.openAchieveGui:SetActive(true)
    self.openGift:SetActive(true)
end

local constDefCoinRes = ConstDef.ServerResTypeEnum.Coin
local constDefDiamondRes = ConstDef.ServerResTypeEnum.Diamond

--- 初始化资源数目
function C_MainGui:InitResNum()
    self.coinResNum = C_PlayerDataMgr:GetValue(constDefCoinRes)
    self.diamondResNum = C_PlayerDataMgr:GetValue(constDefDiamondRes)
end

--- 增加金钱动画
function C_MainGui:OnCoinChanged()
    local coinResNum = C_PlayerDataMgr:GetValue(constDefCoinRes)
    local compareResult = TStringNumCom(coinResNum,self.coinResNum)
    if compareResult and compareResult ~= 0 then
        local addingVal = TStringNumSub(coinResNum, self.coinResNum)
        local hint = world:CreateInstance('HintMoney','HintMoney',self.mainScenePnl)
        self:OnResAddedTween(hint,addingVal,Vector2(0.15,0.15),Vector2(0.55,0.55))
        self:CheckIfHaveEnoughMoneyToUnlockNextLevel()
    end
    self.coinResNum = coinResNum
end

--- 增加钻石动画
function C_MainGui:OnDiamondChanged()
    local diamondRes = C_PlayerDataMgr:GetValue(constDefDiamondRes)
    local compareResult = TStringNumCom(diamondRes,self.diamondResNum)
    if compareResult and compareResult ~= 0 then
        local addingVal = TStringNumSub(diamondRes, self.diamondResNum)
        local hint = world:CreateInstance('HintDiamond','HintDiamond',self.mainScenePnl)
        self:OnResAddedTween(hint,addingVal,Vector2(0.15,0.15),Vector2(0.68,0.68))
    end
    self.diamondResNum = diamondRes
end

--- 资源增加动画
function C_MainGui:OnResAddedTween(_obj,_addingVal,_dstAchorX,_dstAchorY)
    _obj.AnchorsY = Vector2(-1,-1)
    local ran1, ran2 = 0,0
    while ran1 == 0 or ran2 == 0 do ran1, ran2 = math.random(-1,1), math.random(-1,1) end
    local figObj = _obj.Fig
    local pnlTxtFig = _obj.PnlText.Fig
    pnlTxtFig.Text.Text = "+ " .. ShowAbbreviationNum(_addingVal)
    pnlTxtFig.BigText.Text = "+ " .. ShowAbbreviationNum(_addingVal)
    local tweener00 = Tween:TweenProperty(_obj, {AnchorsY = Vector2(0.5,0.5)}, 0.2, Enum.EaseCurve.BackOut)
    local tweener01 = Tween:TweenProperty(figObj, {Size = Vector2(ran1*400,ran2*180)}, 0.5, Enum.EaseCurve.BackOut)
    local tweener02 = Tween:TweenProperty(_obj, {AnchorsY = _dstAchorY,AnchorsX = _dstAchorX}, 0.3, 1)
    local tweener03 = Tween:TweenProperty(pnlTxtFig.Text, {Alpha = 0}, 0.3, 1)
	local tweener04 = Tween:TweenProperty(figObj, {Size = Vector2(1,1)}, 0.2, Enum.EaseCurve.BackOut)
    tweener00.OnComplete:Connect(function() tweener02:Play() tweener00:Destroy() end)
    tweener01.OnComplete:Connect(function() tweener01:Destroy() end)
    tweener02.OnComplete:Connect(function()
		tweener04:Play()
        tweener03:Play()
        tweener02:Destroy()
        for _, v in pairs(figObj:GetChildren()) do
            local tweener = Tween:TweenProperty(v, {Alpha = 0}, 0.2, 1)
            tweener.OnComplete:Connect(function()
                tweener:Destroy()
            end)
            tweener:Play()
        end
    end)
    tweener03.OnComplete:Connect(function()
        tweener03:Destroy()
        _obj:Destroy()
    end)
	tweener04.OnComplete:Connect(function() tweener04:Destroy() end)
    tweener00:Play()
	tweener01:Play()
end

return C_MainGui