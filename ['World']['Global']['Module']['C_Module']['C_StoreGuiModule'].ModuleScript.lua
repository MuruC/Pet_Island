--- 客户端商店UI管理模块
-- @module Store GUI manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_StoreGui, this = {}, nil

local pnlId = {
    good = 1,
    potion = 2,
}

--- 初始化
function C_StoreGui:Init()
    --info("C_StoreGui:Init")
    this = self
    self:InitListeners()

    -- 商店gui
    self.storeGui = localPlayer.Local.StoreGui
    -- 商店界面
    self.storeBg = self.storeGui.StoreBg
    -- 商品界面
    self.goodsBg = self.storeBg.GoodsBg
    -- 药水界面
    self.potionBg = self.storeBg.PotionBg
    -- 商品面板
    self.goodsPanel = self.goodsBg.GoodsPanel
    -- 药水面板
    self.potionPanel = self.potionBg.PotionPanel
    -- 退出商店界面
    self.quitStore = self.storeBg.Quit
    -- 转换成药水面板
    --self.switchPotion = self.storeBg.SwitchPotion
    -- 转换成商品面板
    self.swicthGoods = self.storeBg.SwitchGoods
    -- 商品界面左页
    --self.goodsLeftPage = self.goodsBg.LeftBtn
    -- 商品界面右页
    --self.goodsRightPage = self.goodsBg.RightBtn

    -- 商品界面页数
    self.goodsPage = 1
    -- 药水商店锁
    self.potionLockBtn = self.storeBg.PotionLock
    -- 解锁药水商店提示
    self.unlockPotionInstruct = self.storeBg.UnlockPotion

    -- 已选择的页面
    self.chosenPnlId = pnlId.good

    -- 全部gui
    local playerLocal = localPlayer.Local
    self.allGui = {
        playerLocal.HatchGui,playerLocal.TransGui,playerLocal.ControlGui,playerLocal.AchieveGui,playerLocal.BagGui,
        playerLocal.MergeGui,playerLocal.StoreGui
    }

    self:InitConnectBtns()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_StoreGui:Update(dt)
end

--- 初始化C_StoreGui自己的监听事件
function C_StoreGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_StoreGui, "C_StoreGui", this)
end

--- 初始绑定按钮
function C_StoreGui:InitConnectBtns()
    -- 退出商店界面
    self.quitStore.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_05)
            self:CheckIfShowStoreGui(false)
        end
    )
    -- 商店中切换成药水页面
    --self.switchPotion.OnClick:Connect(
    --    function()
    --        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_04)
    --        self.goodsBg:SetActive(false)
    --        self.potionBg:SetActive(true)
    --        self.chosenPnlId = pnlId.potion
    --    end
    --)
    -- 商店中切换成商品页面
    self.swicthGoods.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_04)
            self.goodsBg:SetActive(true)
            self.potionBg:SetActive(false)
            self.chosenPnlId = pnlId.good
        end
    )
    local goodsTbl = {}
    goodsTbl[1] = {
        self.goodsPanel.PortalGoods,
        self.goodsPanel.AddRarePetProb,
        self.goodsPanel.AddPetsInOneEgg
    }
    goodsTbl[2] = {
        self.goodsPanel.AddPetBagCapacity,
        self.goodsPanel.AddCoinNumAfterMine,
        self.goodsPanel.AddPlayerSpd
    }
    goodsTbl[3] = {
        self.goodsPanel.OneMoreFollowPets
    }
    -- 商品界面左页
    --self.goodsLeftPage.OnClick:Connect(
    --    function()
    --        if self.goodsPage > 1 then
    --            self.goodsPage = self.goodsPage - 1
    --            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_04)
    --        end
    --        for k, v in pairs(goodsTbl) do
    --            for k_, v_ in pairs(v) do
    --                v_:SetActive(false)
    --            end
    --        end
    --        for k, v in pairs(goodsTbl[self.goodsPage]) do
    --            v:SetActive(true)
    --        end
    --    end
    --)
    ---- 商品界面右页
    --self.goodsRightPage.OnClick:Connect(
    --    function()
    --        if self.goodsPage < 3 then
    --            self.goodsPage = self.goodsPage + 1
    --            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_04)
    --        end
    --        for k, v in pairs(goodsTbl) do
    --            for k_, v_ in pairs(v) do
    --                v_:SetActive(false)
    --            end
    --        end
    --        for k, v in pairs(goodsTbl[self.goodsPage]) do
    --            v:SetActive(true)
    --        end
    --    end
    --)

    -- 点击解锁药水商店按钮
    self.potionLockBtn.OnClick:Connect(function()
        self.unlockPotionInstruct:SetActive(true)
    end)
end

--- 检测商店界面是否显示
--- @param _bShow boolean 是否显示
function C_StoreGui:CheckIfShowStoreGui(_bShow)
    if _bShow then
        for _, gui in pairs(self.allGui) do
            gui:SetActive(false)
        end
        local bgObj
        if self.chosenPnlId == pnlId.good then
            bgObj = self.goodsBg
        elseif self.chosenPnlId == pnlId.potion then
            bgObj = self.potionBg
        end
        local oldSize = bgObj.Size
        for _, gui in pairs(self.storeBg:GetChildren()) do
            gui:SetActive(false)
        end
        for _, gui in pairs(bgObj:GetChildren()) do
            gui:SetActive(false)
        end
        bgObj.Size = Vector2(0,0)
        self.storeGui:SetActive(true)
        bgObj:SetActive(true)
        local objTweener = Tween:TweenProperty(bgObj, {Size = oldSize}, 0.3, Enum.EaseCurve.BackOut)
        objTweener.OnComplete:Connect(function()
            self.quitStore:SetActive(true)
            --self.switchPotion:SetActive(true)
            self.swicthGoods:SetActive(true)
            self.potionLockBtn:SetActive(true)
            for _, gui in pairs(bgObj:GetChildren()) do
                gui:SetActive(true)
            end
            objTweener:Destroy()
        end)
        objTweener:Play()
    else
        local bgObj
        if self.chosenPnlId == pnlId.good then
            bgObj = self.goodsBg
        elseif self.chosenPnlId == pnlId.potion then
            bgObj = self.potionBg
        end
        local oldSize = bgObj.Size
        for _, gui in pairs(self.storeBg:GetChildren()) do
            if gui ~= bgObj then gui:SetActive(false) end
        end
        for _, gui in pairs(bgObj:GetChildren()) do
            gui:SetActive(false)
        end
        local objTweener = Tween:TweenProperty(bgObj, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)
        objTweener.OnComplete:Connect(function()
            C_MainGui:CheckIfShowMainGui(true)
            bgObj.Size = oldSize
            objTweener:Destroy()
        end)
        objTweener:Play()
    end
end

return C_StoreGui