--- 客户端背包UI管理模块
-- @module bag ui, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_BagGui, this = {}, nil

-- 宠物按钮class
local PetButton = {}

--- 初始化宠物按钮类
--- @param _petId string 宠物id
--- @param _btnObj Object 按钮节点
function PetButton:Init(_petId, _petListButton)
    self.id = _petId
    self.obj = _petListButton
    self.bClick = false
end

local pnlId = {    ---背包面板id
    pet = 1,
    egg = 2,
    potion = 3,
}

function C_BagGui:Init()
    this = self
    self:InitListeners()

    --- 背包gui
    self.bagGui = localPlayer.Local.BagGui
    -- 背包面板
    self.bagBg = self.bagGui.BagBg
    -- 背包中打开宠物面板
    self.checkAllPetsInBag = self.bagBg.OpenPetBtn
    -- 背包中打开蛋面板
    self.checkAllEggsInBag = self.bagBg.OpenEggBtn
    -- 背包中打开药水面板
    self.checkAllPotionsInBag = self.bagBg.OpenPotionBtn
    -- 背包中的宠物面板
    self.petPnlInBag = self.bagBg.PetBg
    -- 宠物按钮面板
    self.petBtnPnl = self.petPnlInBag.PetPnl
    -- 背包中的蛋面板
    self.eggPnlInBag = self.bagBg.EggBg
    -- 背包中的药水面板
    self.potionPnlInBag = self.bagBg.PotionBg
    -- 贩售宠物按钮
    self.sellPet = self.petPnlInBag.Sell
    -- 装备宠物按钮
    self.equipPet = self.petPnlInBag.Equip
    -- 关闭背包面板
    self.quitBag = self.bagBg.Quit
    -- 使用药水按钮
    self.usePotionBtn = self.potionPnlInBag.UsePotion
    -- 宠物当前力量文本
    self.petCurPowerTxt = self.petPnlInBag.CurPower
    -- 宠物图标
    self.petIconImg = self.petPnlInBag.PetIcon
    -- 宠物等级图标
    self.petLvlImg = self.petPnlInBag.PetLvl
    -- 宠物序号
    self.petIndexTxt = self.petPnlInBag.Index
    -- 宠物名字
    self.petNameTxt = self.petPnlInBag.PetName
    -- 蛋名字
    self.eggNameTxt = self.eggPnlInBag.EggName
    -- 蛋的场景
    self.eggAreaTxt = self.eggPnlInBag.Area
    -- 蛋的关卡
    self.eggZoneTxt = self.eggPnlInBag.Zone
    -- 蛋图标
    self.eggIcon = self.eggPnlInBag.EggIcon
    -- 将宠物按照力量排序
    self.listPetByPower = self.petPnlInBag.ListByPower
    -- 将宠物按照种类排序
    self.listPetByIndex = self.petPnlInBag.ListByIndex
    -- 宠物背包总页数
    self.allPetPageNum = self.petPnlInBag.PageBg.AllPage
    -- 宠物背包当前页数
    self.curPetPageNum = self.petPnlInBag.PageBg.CurPage
    -- 宠物面板向左翻页
    self.petLeftPage = self.petPnlInBag.LeftPage
    -- 宠物面板向右翻页
    self.petRightPage = self.petPnlInBag.RightPage
    -- 解锁药水功能提示
    self.unlockPotionHint = self.bagBg.UnlockPotionInstruct

    --- @type table 所有宠物按钮列表
    self.petBtnList = {}
    --- @type table 药水按钮列表
    self.potionBtnList = {}
    --- @type table 蛋按钮列表
    self.eggBtnList = {}

    --- @type string 背包中选择的pet按钮的Id
    self.selectPetId = nil
    --- @type int 背包中选的药水的类别
    self.selectPotionType = nil
    --- @type string 背包中选的蛋的id
    self.selectEggId = nil

    --- @type table 前一个选择的宠物按钮
    self.prevSelectPetBtn = {}
    --- @type Object 前一个选择的蛋按钮
    self.prevSelectEggBtn = nil
    --- @type table 前一个选择的药水按钮
    self.prevSelectPotionBtn = {}

    --- @type int 选择的面板id
    self.chosenPnlId = pnlId.pet

    --- 总的pet面板滑动范围
    self.allPetScrollScale = 0
    --- 每页Range
    self.eachPageScrollscale = 0

    --- 宠物是否使用power排序
    self.bPetArrangedByPower = true

    -- 全部gui
    local playerLocal = localPlayer.Local
    self.allGui = {
        playerLocal.HatchGui,playerLocal.TransGui,playerLocal.ControlGui,playerLocal.AchieveGui,playerLocal.BagGui,
        playerLocal.MergeGui,playerLocal.StoreGui
    }

    self:ConnectButtons()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_BagGui:Update(dt)
    -- TODO: 其他客户端模块Update
end

--- 初始化C_ReplyRequest自己的监听事件
function C_BagGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_BagGui, 'C_BagGui', this)
end

local constDefScrollScaleEachPage = 100     ---宠物按钮面板每页的scale

--- 绑定背包界面按钮
function C_BagGui:ConnectButtons()
    -- 绑定装备宠物按钮
    self:BindEquipBtnCallback()
    -- 绑定装备药水按钮
    self:BindUsePotionCallback()
    self:BindSellBtnCallback()
    -- 退出背包
    self.quitBag.OnClick:Connect(
        function()
            local bagObj
            if self.chosenPnlId == pnlId.pet then
                bagObj = self.petPnlInBag
            elseif self.chosenPnlId == pnlId.egg then
                bagObj = self.eggPnlInBag
            elseif self.chosenPnlId == pnlId.potion then
                bagObj = self.potionPnlInBag
            end
            local titleObj = bagObj:GetChild('Title')
            local bagOldSize = bagObj.Size
            local ttlOldSize = titleObj.Size
            for _, gui in pairs(bagObj:GetChildren()) do
                gui:SetActive(false)
            end
            self.quitBag:SetActive(false)
            titleObj:SetActive(true)
            local bagTweener = Tween:TweenProperty(bagObj, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)    --构造一个值插值器
            bagTweener.OnComplete:Connect(function()
                C_MainGui:CheckIfShowMainGui(true)
                bagObj.Size = bagOldSize
                bagTweener:Destroy()
            end)
            bagTweener:Play()
            local titleTweener = Tween:TweenProperty(titleObj, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)
            titleTweener.OnComplete:Connect(function()
                titleObj.Size = ttlOldSize
                titleTweener:Destroy()
            end)
            titleTweener:Play()
            self.selectPetId = nil
            self.prevSelectEggBtn = nil
        end
    )
    -- 背包中打开宠物面板
    self.checkAllPetsInBag.OnClick:Connect(
        function()
            self.chosenPnlId = pnlId.pet
            self.petPnlInBag:SetActive(true)
            self.eggPnlInBag:SetActive(false)
            self.potionPnlInBag:SetActive(false)
            self:ShowEquippedPets()
            if not self.selectPetId then
                self:RestorePetBag()

                self:RestorePrevSelectPetBtnTexture()
                self.prevSelectPetBtn = {}
            end
        end
    )
    -- 背包中打开蛋面板
    self.checkAllEggsInBag.OnClick:Connect(
        function()
            self.chosenPnlId = pnlId.egg

            self.petPnlInBag:SetActive(false)
            self.eggPnlInBag:SetActive(true)
            self.potionPnlInBag:SetActive(false)

            self.selectPetId = nil
            self:RestorePrevSelectPetBtnTexture()
            self.prevSelectPetBtn = {}

            self:RestorePrevSelectEggBtnTexture()
            self.prevSelectEggBtn = nil
            self:RestoreEggBag()
        end
    )
    -- 背包中打开药水面板
    self.checkAllPotionsInBag.OnClick:Connect(
        function()
            self.unlockPotionHint:SetActive(true)
            C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(5,false,os.time(),function() self.unlockPotionHint:SetActive(false) end,true))
        end
    )
    -- 将宠物按照力量排序
    self.listPetByPower.OnClick:Connect(function()
        self.bPetArrangedByPower = true
        self:ArrangeBtnInBag()
        self.listPetByIndex:SetActive(true)
        self.listPetByPower:SetActive(false)
    end)
    -- 将宠物按照种类排序
    self.listPetByIndex.OnClick:Connect(function()
        self.bPetArrangedByPower = false
        self:ArrangeBtnInBag()
        self.listPetByIndex:SetActive(false)
        self.listPetByPower:SetActive(true)
    end)
    -- 宠物面板向左翻
    self.petLeftPage.OnClick:Connect(function()
        self.petBtnPnl.ScrollScale = self.petBtnPnl.ScrollScale - self.eachPageScrollscale
        if self.petBtnPnl.ScrollScale < 0 then
            self.petBtnPnl.ScrollScale = 0
        end
        local pageNum = tonumber(self.curPetPageNum.Text) - 1
        if pageNum < 1 then
            pageNum = 1
        end
        self.curPetPageNum.Text = tostring(pageNum)
    end)
    -- 宠物面板向右翻
    self.petRightPage.OnClick:Connect(function()
        self.petBtnPnl.ScrollScale = self.petBtnPnl.ScrollScale + self.eachPageScrollscale
        if self.petBtnPnl.ScrollScale > self.allPetScrollScale then
            self.petBtnPnl.ScrollScale = self.allPetScrollScale
        end
        local pageNum = tonumber(self.curPetPageNum.Text) + 1
        if pageNum > tonumber(self.allPetPageNum.Text) then
            pageNum = tonumber(self.allPetPageNum.Text)
        end
        self.curPetPageNum.Text = tostring(pageNum)
    end)

end

-- 创建新的宠物按钮对象
function C_BagGui:CreateNewPetButton(_petId, _petListButton)
    local o = {}
    setmetatable(o, {__index = PetButton})
    o:Init(_petId, _petListButton)
    return o
end

local constDefUnequipAction = ConstDef.PlayerActionTypeEnum.Unequip ---宠物待机行为枚举
local constDefEquipAction = ConstDef.PlayerActionTypeEnum.Equip     ---装备宠物行为枚举

--- 绑定装备宠物按钮
function C_BagGui:BindEquipBtnCallback()
    -- 点击equip按钮
    self.equipPet.OnClick:Connect(
        function()
            -- After sold, self.selectPetId should be nil.
            if not self.selectPetId then
                C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_07)
                return
            end

            ---@type bool 宠物是否已经处于跟随中
            local bPetEquipped = C_PlayerDataMgr:CheckIfPetIsEquipped(self.selectPetId)

            if bPetEquipped then
                NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, constDefUnequipAction, 
                self.selectPetId)
                -- 改变装备按钮texture
                self.equipPet.Texture = ResourceManager.GetTexture("UI/Bag/Take")
                for _, v in pairs(self.petBtnList) do
                    if v.id == self.selectPetId then
                        v.obj.CheckIcon:SetActive(false)
                    end
                end
                C_PetMgr:UnequipPetHandler(self.selectPetId)
                C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_02)
            else
                -- 请求服务器装备宠物
                C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_01)
                NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, constDefEquipAction, 
                ConstDef.EquipmentTypeEnum.Pet, self.selectPetId)
            end
        end
    )
end

local constDefSellAction = ConstDef.PlayerActionTypeEnum.SellPet     ---出售宠物行为枚举

--- 绑定贩售宠物按钮
function C_BagGui:BindSellBtnCallback()
    self.sellPet.OnClick:Connect(function()
        -- After sold, self.selectPetId should be nil.
        if not self.selectPetId then
            return
        end
        -- 无法出售正在装备宠物
        if C_PlayerDataMgr:CheckIfPetIsEquipped(self.selectPetId) then
            return
        end

        -- 请求服务器出售宠物
        NetUtil.Fire_S('PlayerRequestEvent', localPlayer.UserId, constDefSellAction, self.selectPetId)

        self.selectPetId = nil
        self:RestorePetBag()
    end)
end

--- 背包中宠物按钮排序
function C_BagGui:ArrangeBtnInBag()
    if self.bPetArrangedByPower then
        C_UIMgr:ArrangeBtns(self:GetPetArrangedByPower(self.petBtnList), 170, 225, 170, -115, 2, ConstDef.btnCategoryEnum.petInBag)
    else
        C_UIMgr:ArrangeBtns(self:GetPetArrangedByIndex(self.petBtnList), 170, 225, 170, -115, 2, ConstDef.btnCategoryEnum.petInBag)
    end
end

--- 获得新的宠物按钮
--- @param _newPetButton table 新宠物按钮表
function C_BagGui:AddNewPetButton(_newPetButton)
    local id = _newPetButton.id
    table.insert(self.petBtnList,_newPetButton)
    local PetInfo = PlayerCsv.PetProperty
    local pet = C_PlayerDataMgr:GetPetInformation(id)

    -- 生成按钮
    local petListObj = world:CreateInstance("PetInBagBtn"..tostring(pet.rarity), "PetListButton", self.petPnlInBag.PetPnl)
    petListObj.BtnIndex.Value = id
    _newPetButton.obj = petListObj

    
    local index = PetInfo[pet.area][pet.zone][pet.index]['PetIndex']
    local imgPath = 'UI/petIcon/PetIcon_'..index..'0'..tostring(pet.level)
    petListObj.PetIcon.Texture = ResourceManager.GetTexture(imgPath)
    petListObj.levelImg.Texture = ResourceManager.GetTexture('UI/fuse/level'..tostring(pet.level))
    petListObj.PowerBg.Power.Text = pet.realPower
    -- 当在主城点击宠物面板时，跳出宠物信息面板，可以选择装备或不装备
    petListObj.Btn.OnDown:Connect(
        function()
            local petId = _newPetButton.id
            local equipBtn = self.equipPet
            local pet = C_PlayerDataMgr:GetPetInformation(petId)
            local petInfo = PlayerCsv.PetProperty[pet.area][pet.zone][pet.index]
            self.selectPetId = petId
            self.petIconImg.Alpha = 1
            self.petIconImg.Texture = ResourceManager.GetTexture('UI/petIcon/PetIcon_'..pet.index..'0'..tostring(pet.level))
            self.petLvlImg.Alpha = 1
            self.petLvlImg.Texture = ResourceManager.GetTexture('UI/petLevel/L'..tostring(pet.level))
            self.petIndexTxt.Text = pet.index
            self.petNameTxt.Text = petInfo['PetChineseName']
            self.petCurPowerTxt.Text = ShowAbbreviationNum(pet.curPower)
            self:RestorePrevSelectPetBtnTexture()
            self.prevSelectPetBtn = _newPetButton
            petListObj.BeChosenBg:SetActive(true)
            ---@type bool 宠物是否已经处于跟随中
            local bPetEquipped = C_PlayerDataMgr:CheckIfPetIsEquipped(self.selectPetId)

            if bPetEquipped then
                C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_02)
                self.sellPet.CantSell:SetActive(true)
                equipBtn.Texture = ResourceManager.GetTexture("UI/Bag/cantTake")
            else
                C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_06)
                equipBtn.Texture = ResourceManager.GetTexture("UI/Bag/Take")
                self.sellPet.CantSell:SetActive(false)
            end
        end
    )
end

--- 移除宠物按钮
--- @param _petId string 宠物id
function C_BagGui:RemovePetBtn(_petId)
    for ii = #self.petBtnList, 1, -1 do
        if self.petBtnList[ii].id == _petId then
            self.petBtnList[ii].obj:Destroy()
            table.remove(self.petBtnList,ii)
        end
    end
end

--- 刷新装备按钮
--- @param _result number 
--- @param _petId string  宠物编号ConstDef.ResultMsgEnum
function C_BagGui:RefrshEquipBtn(_result,_petId)
    if not _result == ConstDef.ResultMsgEnum.Succeed then
        return
    end
    if self.selectPetId == _petId then
        self.equipPet.Texture = ResourceManager.GetTexture("UI/Bag/cantTake")
        self.sellPet.CantSell:SetActive(true)
    end
    for _, v in pairs(self.petBtnList) do
        if v.id == self.selectPetId then
            v.obj.CheckIcon:SetActive(true)
            v.obj.BeChosenBg:SetActive(true)
        end
    end
end

--- 生成背包里的蛋按钮
--- @param _eggTbl table 蛋数据
function C_BagGui:AddNewEggBtnInBag(_eggTbl)
    local area = _eggTbl.area
    local zone = _eggTbl.zone
    for k, v in pairs(self.eggBtnList) do
        if v.Area.Value == area and v.Zone.Value == zone then
            v.Num.Text = tostring(tonumber(v.Num.Text) + 1)
            return
        end
    end
    local eggBtnInBagObj = world:CreateInstance("EggInBagBtn", "EggInBagBtn", self.eggPnlInBag.EggPnl)
    eggBtnInBagObj.Area.Value = area
    eggBtnInBagObj.Zone.Value = zone
    eggBtnInBagObj.Num.Text = '1'
    table.insert(self.eggBtnList, eggBtnInBagObj)
    eggBtnInBagObj.Btn.OnClick:Connect(function()
        eggBtnInBagObj.BeChosen:SetActive(true)
        local eggInfo = PlayerCsv.Egg[area][zone]
        self.eggNameTxt.Text = eggInfo['EggName']
        -- 蛋图标
        self.eggIcon.Texture = ResourceManager.GetTexture("UI/Egg/"..tostring(_eggTbl.area)..'.'..tostring(_eggTbl.zone))
        self.eggIcon.Alpha = 1
		self:RestorePrevSelectEggBtnTexture()
        self.prevSelectEggBtn = eggBtnInBagObj
    end)
    -- 排序
    C_UIMgr:ArrangeBtns(self.eggBtnList, 150, 150, 150, -150, 3, ConstDef.btnCategoryEnum.eggInBag)
end

--- 移除背包里的蛋按钮
--- @param _area int 场景编号
--- @param _zone int 关卡编号
function C_BagGui:RemoveEggBtnInBag(_area, _zone)
    for k, v in pairs(self.eggBtnList) do
        if v.Area.Value == _area and v.Zone.Value == _zone then
            local btnObj = v
            table.remove(self.eggBtnList, k)
            btnObj:Destroy()
            -- 排序
            C_UIMgr:ArrangeBtns(self.eggBtnList, 150, 150, 150, -150, 3, ConstDef.btnCategoryEnum.eggInBag)
            break
        end
    end
end

--- 生成背包里的药水按钮
--- @param _potionindex int 药水种类
function C_BagGui:AddNewPotionBtn(_potionindex)
    local btnObj = world:CreateInstance('PotionInBagBtn','potionBtn',self.potionPnlInBag.PotionPnl)
    btnObj.Type.Value = _potionindex
    table.insert(self.potionBtnList,btnObj)
    btnObj.OnClick:Connect(function()
        self.selectPotionType = _potionindex
    end)

    --排列
    C_UIMgr:ArrangeBtns(self.potionBtnList, 150, 140, 150, -150, 3, ConstDef.btnCategoryEnum.potionInBag)
end

--- 初始化所有宠物按钮
function C_BagGui:InitAllPetBtn()
    local allPets = C_PlayerDataMgr:GetItem(ConstDef.ItemCategoryEnum.Pet)
    for k, v in pairs(allPets) do
        self:AddNewPetButton(self:CreateNewPetButton(k, nil))
    end
    self:ArrangeBtnInBag()
    self:ShowEquippedPets()
    self:SetPetBtnPnlRange()
end

--- 初始化所有蛋按钮
function C_BagGui:InitAllEggBtn()
    local allEggs = C_PlayerDataMgr:GetItem(ConstDef.ItemCategoryEnum.Egg)
    for k, v in pairs(allEggs) do
        self:AddNewEggBtnInBag(v)
    end    
end

--- 初始化所有的药水按钮
function C_BagGui:InitAllPotionBtn()
    local allPotions = C_PlayerDataMgr:GetItem(ConstDef.ItemCategoryEnum.Potion)
    for k, v in pairs(allPotions) do
        self:AddNewPotionBtn(v)
    end
end

--- 绑定使用药水按钮
function C_BagGui:BindUsePotionCallback()
    self.usePotionBtn.OnClick:Connect(function()
        NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, ConstDef.PlayerActionTypeEnum.Equip, 
        ConstDef.EquipmentTypeEnum.Potion, self.selectPotionType)
    end)
end

local constDefBtnEnum = ConstDef.btnEnum

--- 绑定按钮函数
--- @param _btn string 按钮
--- @param _func function 函数
function C_BagGui:BindBtnEventCallback(_btn,_func)
    if _btn == constDefBtnEnum.equipPet then
        self.equipPet.OnClick:Connect(_func)
    end
end

--- 按钮和函数断开连接
--- @param _btn string 按钮
--- @param _func function 函数
function C_BagGui:DisconnectBtnEvent(_btn,_func)
    if _btn == constDefBtnEnum.equipPet then
        self.equipPet.OnClick:Disconnect(_func)
    end
end

--- 显示或隐藏ui
--- @param _ui string ui
--- @param _bShow boolean 是否显示 true显示 false隐藏
function C_BagGui:CheckIfShowUi(_ui,_bShow)
    if _ui == constDefBtnEnum.sell then
        self.sellPet:SetActive(_bShow)
    end
end

--- 打开背包
function C_BagGui:OpenBagGui()
    for _, gui in pairs(self.allGui) do
        gui:SetActive(false)
    end
    local bagBg = self.bagBg
    for _, gui in pairs(bagBg:GetChildren()) do
        gui:SetActive(false)
    end
    local bagObj
    if self.chosenPnlId == pnlId.pet then
        bagObj = self.petPnlInBag
    elseif self.chosenPnlId == pnlId.egg then
        bagObj = self.eggPnlInBag
    elseif self.chosenPnlId == pnlId.potion then
        bagObj = self.potionPnlInBag
    end
    local titleObj = bagObj:GetChild('Title')
    local oldSize = bagObj.Size
    local ttlOldSize = titleObj.Size
    bagObj.Size = Vector2(0,0)
    titleObj.Size = Vector2(0,0)
    for _, gui in pairs(bagObj:GetChildren()) do
        gui:SetActive(false)
    end
    self.bagGui:SetActive(true)
    titleObj:SetActive(true)
    bagObj:SetActive(true)
    local objTweener = Tween:TweenProperty(bagObj, {Size = oldSize}, 0.3, Enum.EaseCurve.BackOut)    --构造一个值插值器
    objTweener.OnComplete:Connect(function()
        for _, gui in pairs(bagObj:GetChildren()) do
            gui:SetActive(true)
        end
        self.checkAllPetsInBag:SetActive(true)
        self.checkAllEggsInBag:SetActive(true)
        self.checkAllPotionsInBag:SetActive(true)
        self.quitBag:SetActive(true)
        objTweener:Destroy()
    end)
    local titleTweener = Tween:TweenProperty(titleObj,{Size = ttlOldSize},0.3,Enum.EaseCurve.BackOut)
    titleTweener.OnComplete:Connect(function()
        titleTweener:Destroy()
    end)
    titleTweener:Play()
    objTweener:Play()--播放

    self:ShowEquippedPets()
    if not self.selectPetId then
        self:RestorePetBag()
    end
    self.selectPetId = nil
    self:RestorePrevSelectPetBtnTexture()
    self:RestorePetBag()
    self.prevSelectPetBtn = {}
       
    self:RestorePrevSelectEggBtnTexture()
    self.prevSelectEggBtn = nil
    self:RestoreEggBag()
end

local contDefEquipPet = ConstDef.EquipmentTypeEnum.Pet  ---宠物装备枚举

--- 显示所有已装备的宠物
function C_BagGui:ShowEquippedPets()
    local curPetIds = C_PlayerDataMgr:GetEquipmentTable(contDefEquipPet)
    for _, v in pairs(self.petBtnList) do
        if table.exists(curPetIds,v.id) then
            v.obj.CheckIcon:SetActive(true)
        end
    end
end

--- 前一个选择的宠物按钮恢复底图
function C_BagGui:RestorePrevSelectPetBtnTexture()
    local btn = self.prevSelectPetBtn.obj
    if btn then
       btn.BeChosenBg:SetActive(false)
    end
end

--- 复原宠物背包界面
function C_BagGui:RestorePetBag()
    self.petIconImg.Alpha = 0
    self.petLvlImg.Alpha = 0
    self.petIndexTxt.Text = ' '
    self.petNameTxt.Text = ' '
    self.petCurPowerTxt.Text = ' '
    self.equipPet.Texture = ResourceManager.GetTexture("UI/Bag/Take")
    self.sellPet.CantSell:SetActive(false)
end

--- 复原蛋背包界面
function C_BagGui:RestoreEggBag()
    self.eggNameTxt.Text = ' '
    self.eggIcon.Alpha = 0
end

--- 前一个选择的蛋按钮恢复底图
function C_BagGui:RestorePrevSelectEggBtnTexture()
    local btn = self.prevSelectEggBtn
    if btn then
        btn.BeChosen:SetActive(false)
    end
end

--- 服务器反馈出售宠物处理器
--- @param _petId string 宠物id
function C_BagGui:SellPetHandler(_petId)
    if self.prevSelectPetBtn.id == _petId then
        self.prevSelectPetBtn = {}
    end
    self:RemovePetBtn(_petId)
    self:ArrangeBtnInBag()
end

--- 返回宠物按钮按照power排序
--- @param _tbl table 要排序的table
function C_BagGui:GetPetArrangedByPower(_tbl)
    local function compare(a, b)
        --1. a,b不允许为空
        local aPetPower = C_PlayerDataMgr:GetPetInformation(a.id).realPower
        local bPetPower = C_PlayerDataMgr:GetPetInformation(b.id).realPower
        if not aPetPower or not bPetPower then
            return false
        end
        local result = TStringNumCom(aPetPower, bPetPower)
        if result == 0 then
            return false
        end
        -- 降序
        return result
    end
    table.sort(_tbl,compare)
    return _tbl
end

--- 返回宠物按钮按照index排序
--- @param _tbl table 要排序的table
function C_BagGui:GetPetArrangedByIndex(_tbl)
    local petTypes = {}
    local newTbl = {}
    for _, btn in pairs(_tbl) do
        local pet = C_PlayerDataMgr:GetPetInformation(btn.id)
        local index = pet.index
        if not petTypes[index] then
            petTypes[index] = {}
        end
        table.insert(petTypes[index],btn)
    end
    for index, v in pairs(petTypes) do
        local sameIndexBtnTbl = self:GetPetArrangedByPower(v)
        for _, btn in pairs(sameIndexBtnTbl) do
            table.insert(newTbl,btn)
        end
    end
    return newTbl
end

local btnNumInEachPage = 6
--- 设置宠物按钮列表面板范围
function C_BagGui:SetPetBtnPnlRange()
    local allBtnNum = #self.petBtnList
    local pnlObj = self.petPnlInBag.PetPnl
    
    if allBtnNum > btnNumInEachPage then
        local remainder = allBtnNum % btnNumInEachPage
        local pageNum = (allBtnNum - remainder) / btnNumInEachPage
        if remainder > 0 then
            pageNum = pageNum + 1
        end
        pnlObj.ScrollRange = 510 * pageNum
        pnlObj.ScrollScale = 0
        self.allPetScrollScale = constDefScrollScaleEachPage * (pageNum - 1)
        self.curPetPageNum.Text = '1'
        self.allPetPageNum.Text = tostring(math.floor(pageNum))
        self.eachPageScrollscale = 100 / (pageNum - 1) 
    else
        pnlObj.ScrollRange = 510
        self.allPetPageNum.Text = '1'
        self.curPetPageNum.Text = '1'
        self.allPetScrollScale = 0
        self.eachPageScrollscale = 0
    end
end

--- 卸除最弱宠物处理器
--- @param _petId string 宠物id
function C_BagGui:UnequipWeakestPetHandler(_petId)
    for _, v in pairs(self.petBtnList) do
        if v.id == _petId then
            v.obj.CheckIcon:SetActive(false)
        end
    end
end

return C_BagGui