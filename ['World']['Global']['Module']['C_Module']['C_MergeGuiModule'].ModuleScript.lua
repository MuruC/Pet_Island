--- 客户端合成UI管理模块
-- @module merge room ui, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_MergeGui, this = {}, nil

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

function C_MergeGui:Init()
    this = self
    self:InitListeners()

    -- 合成gui
    self.mergeGui = localPlayer.Local.MergeGui
    -- 合成宠物panel
    self.mergePetPanel = self.mergeGui.MergePnl
    -- 合成宠物背景图
    self.mergePetBg = self.mergePetPanel.PetListBg
    -- 合成宠物列表pnl
    self.mergePetListPnl = self.mergePetBg.PetListPnl
    -- 关闭合成宠物
    self.quitMergePet = self.mergePetPanel.Quit
    -- 说明面板
    self.helpPnl = self.mergePetPanel.HelpPnl
    -- 选择普通合成按钮
    self.normalMergeBtn = self.mergePetPanel.Compose
    -- 打开普通合成说明
    self.openNormalMergeHelp = self.normalMergeBtn.HelpBtn
    -- 普通合成说明
    self.normalFuseHelp = self.helpPnl.NormalFuseHelp
    -- 选择限时合成按钮
    self.limitMergeBtn = self.mergePetPanel.MagicCompose
    -- 打开限时合成说明
    self.openLimitMergeHelp = self.limitMergeBtn.HelpBtn
    -- 限时合成说明
    self.magicFuseHelp = self.helpPnl.MagicFuseHelp
    -- 限时合成当日次数
    self.remainLimitMergeCountTxt = self.limitMergeBtn.RemainUseCountTxt
    -- 当日无法限时合成的图片
    self.outOfLimitMergeUseImg = self.limitMergeBtn.OutOfUseImg
    -- 退出合成动画按钮
    self.quitFuseAnimBtn = self.mergeGui.QuitFuseAnim
    -- 宠物面板向左翻页
    self.petPnlLeftPage = self.mergePetBg.LeftPage
    -- 宠物面板向右翻页
    self.petPnlRightPage = self.mergePetBg.RightPage
    -- 将宠物按照力量排序
    self.listPetByPower = self.mergePetBg.ListByPower
    -- 将宠物按照种类排序
    self.listPetByType = self.mergePetBg.ListByIndex
    -- 合成宠物按钮总页数
    self.allPageNum = self.mergePetBg.AllPageNum
    -- 合成宠物按钮当前页数
    self.curPageNum = self.mergePetBg.CurPageNum
    -- 刷新魔法合成CD图
    self.RefreshMagicFuseCDImg = self.limitMergeBtn.CD
    -- 刷新魔法合成CD文字
    self.RefreshMagicFuseCDTxt = self.RefreshMagicFuseCDImg.CDTime

    -- 总的滑动范围
    self.allScrollScale = 0
    -- 每页的滑动范围
    self.eachPageScrollRange = 0
    --- @type Object 上一个选择合成的按钮
    self.preMergeBtn = nil
    -- 是否用power排序
    self.bArrangedByPower = true

    -- 合成列表所有按钮
    self.petBtnList = {}
    -- 合成所选择的宠物table
    self.mergePetTbl = {}

    -- 倒计时恢复魔法合成事件id
    self.refreshMagicMergeEventId = nil
    --开始读魔法合成cd时间，剩余时间
    self.refreshMagicMergeTimeTbl = {}

    -- 全部gui
    local playerLocal = localPlayer.Local
    self.allGui = {
        playerLocal.HatchGui,playerLocal.TransGui,playerLocal.ControlGui,playerLocal.AchieveGui,playerLocal.BagGui,
        playerLocal.MergeGui,playerLocal.StoreGui
    }

    self:ConnectBtns()
    self:InitRefreshMagicMergeCDGuiEvent()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_MergeGui:Update(dt)
    -- TODO: 其他客户端模块Update
end

--- 初始化C_ReplyRequest自己的监听事件
function C_MergeGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_MergeGui, 'C_MergeGui', this)
end

local constDefNormalCam = ConstDef.CameraModeEnum.Normal    ---主场景相机
local constDefFuseRoomCam = ConstDef.CameraModeEnum.FuseRoom ---合成室相机
local constDefScrollScaleEachPage = 82      --- 宠物按钮面板每页滑动范围
--- 初始化按钮
function C_MergeGui:ConnectBtns()
    -- 关闭合成宠物
    self.quitMergePet.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_05)
            C_Camera:ChangeMode(constDefNormalCam)
            self:ShowMergeGui(false)
            --ClearTable(self.mergePetTbl)
            self:ClearChosenPetsImgInMergeRoom()
            for k, v in pairs(self.petBtnList) do
                for ii = #self.mergePetTbl, 1, -1 do
                    if self.mergePetTbl[ii] == v.id then
                        v.bClick = false
                        v.obj.BeChosenBg:SetActive(false)
                        v.obj.CheckIcon:SetActive(false)
                        table.remove(self.mergePetTbl,ii)
                    end
                end
            end
            if self.preMergeBtn and self.preMergeBtn.obj then
                self.preMergeBtn.obj.BeChosenBg:SetActive(false)
            end
        end
    )
    
    -- 点击普通合成
    self.normalMergeBtn.OnClick:Connect(
        function()
            self:NormalMergePet()
        end
    )
    -- 点击限时合成
    self.limitMergeBtn.OnClick:Connect(
        function()
            self:LimitMergePet()
        end
    )
    -- 退出合成动画
    self.quitFuseAnimBtn.OnClick:Connect(function()
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_05)
        localPlayer.Local.Independent.FusePlat.FuseNewPetFx:SetActive(false)
        C_Camera:ChangeMode(constDefFuseRoomCam)
        --C_MainGui:CheckIfShowMainGui(true)
        self.mergePetPanel:SetActive(true)
        self:ShowMergeGui(true)
        for k, v in pairs(localPlayer.Local.Independent.FusePlat.NewPet:GetChildren()) do
            v:Destroy()
        end
        self.quitFuseAnimBtn:SetActive(false)

    end)
    self:BindChosenMergePetCallback()
    -- 宠物面板向左翻页
    self.petPnlLeftPage.OnClick:Connect(function()
        self.mergePetListPnl.ScrollScale = self.mergePetListPnl.ScrollScale - self.eachPageScrollRange
        if self.mergePetListPnl.ScrollScale < 0 then
            self.mergePetListPnl.ScrollScale = 0
        end
    end)
    -- 宠物面板向右翻页
    self.petPnlRightPage.OnClick:Connect(function()
        self.mergePetListPnl.ScrollScale = self.mergePetListPnl.ScrollScale + self.eachPageScrollRange
        if self.mergePetListPnl.ScrollScale > self.allScrollScale then
            self.mergePetListPnl.ScrollScale = self.allScrollScale
        end
    end)
    -- 打开普通合成说明
    self.openNormalMergeHelp.OnClick:Connect(function()
        self.normalFuseHelp:SetActive(not self.normalFuseHelp.ActiveSelf)
    end)
    -- 打开魔法合成说明
    self.openLimitMergeHelp.OnClick:Connect(function()
        self.magicFuseHelp:SetActive(not self.magicFuseHelp.ActiveSelf)
    end)
    -- 将宠物按照力量排序
    self.listPetByPower.OnClick:Connect(function()
        self.bArrangedByPower = true
        self:ArrangeBtnInMerge(self.petBtnList)
        self.listPetByPower:SetActive(false)
        self.listPetByType:SetActive(true)
    end)
    -- 将宠物按照种类排序
    self.listPetByType.OnClick:Connect(function()
        self.bArrangedByPower = false
        self:ArrangeBtnInMerge(self.petBtnList)
        self.listPetByPower:SetActive(true)
        self.listPetByType:SetActive(false)
    end)
end

-- 创建新的宠物按钮对象
function C_MergeGui:CreateNewPetButton(_petId, _petListButton)
    local o = {}
    setmetatable(o, {__index = PetButton})
    o:Init(_petId, _petListButton)
    return o
end

--- 选择宠物之后显示图标
function C_MergeGui:ListChosenMergePet()
    local chosenPetPnl = self.mergePetPanel.CompositionBar.ChosenPetPnl
    local imgs = chosenPetPnl:GetChildren()
    for k, v in pairs(chosenPetPnl:GetChildren()) do
        v:SetActive(false)
    end
    for k, v in pairs(self.mergePetTbl) do
        local pet = C_PlayerDataMgr:GetPetInformation(v)
        local imgPath = 'UI/petIcon/PetIcon_'..pet.index..'0'..tostring(pet.level)
        local btnObj = chosenPetPnl:GetChild("Btn" .. tostring(k))
        if btnObj then
            btnObj.Texture = ResourceManager.GetTexture(imgPath)
            btnObj:SetActive(true)
            btnObj.petId.Value = v
        end
    end
    if #self.mergePetTbl >= 5 then
        self.mergePetPanel.CompositionBar.Texture = ResourceManager.GetTexture('UI/fuse/fullFuse')
        if self:CheckIfChosenFiveSamePet() then
            self:CheckIfChangeNormalFuseUi(true)
        else
            self:CheckIfChangeMagicFuseUi(true)
        end
    elseif self.mergePetTbl == 4 then
        self:CheckIfChangeMagicFuseUi(false)
        self:CheckIfChangeNormalFuseUi(false)
    end
end

--- 绑定已选择宠物按钮回调事件
function C_MergeGui:BindChosenMergePetCallback()
    local chosenPetPnl = self.mergePetPanel.CompositionBar.ChosenPetPnl
    for k, v in pairs(chosenPetPnl:GetChildren()) do
        v.OnClick:Connect(function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_02)
            for ii = #self.petBtnList, 1, -1 do
                local petBtn = self.petBtnList[ii]
                if petBtn.id == v.petId.Value then
                    petBtn.obj.BeChosenBg:SetActive(false)
                    petBtn.bClick = false
                    petBtn.obj.CheckIcon:SetActive(false)
                end
            end

            if v.petId.Value then
                for ii = #self.mergePetTbl, 1, -1 do
                    if v.petId.Value == self.mergePetTbl[ii] then
                        v.petId.Value = ''
                        table.remove(self.mergePetTbl,ii)
                    end
                end
            end
            for k, v in pairs(chosenPetPnl:GetChildren()) do
                v:SetActive(false)
            end
            for k, v in pairs(self.mergePetTbl) do
                local pet = C_PlayerDataMgr:GetPetInformation(v)
                local imgPath = 'UI/petIcon/PetIcon_'..pet.index..'0'..tostring(pet.level)
                local btnObj = chosenPetPnl:GetChild("Btn" .. tostring(k))
                if btnObj then
                    btnObj.Texture = ResourceManager.GetTexture(imgPath)
                    btnObj:SetActive(true)
                    btnObj.petId.Value = v
                end
            end
            self.mergePetPanel.CompositionBar.Texture = ResourceManager.GetTexture('UI/fuse/notFullFuse')
        end)
    end
end

--- 清空合成室选择宠物之后的图标
function C_MergeGui:ClearChosenPetsImgInMergeRoom()
    local chosenPetPnl = self.mergePetPanel.CompositionBar.ChosenPetPnl
    local btns = chosenPetPnl:GetChildren()
    for k, v in pairs(btns) do
        v:SetActive(false)
        v.petId.Value = ''
    end
    self.mergePetPanel.CompositionBar.Texture = ResourceManager.GetTexture('UI/fuse/notFullFuse')
    self:CheckIfChangeMagicFuseUi(false)
    self:CheckIfChangeNormalFuseUi(false)
end

--- 获得新的宠物按钮
--- @param _newPetButton table 新宠物按钮表
function C_MergeGui:AddNewPetButton(_newPetButton)
    local id = _newPetButton.id
    table.insert(self.petBtnList,_newPetButton)
    local pet = C_PlayerDataMgr:GetPetInformation(id)
    -- 生成按钮
    local mergeObj = world:CreateInstance("MergePetBtn"..tostring(pet.rarity), "MergeButton", self.mergePetListPnl)
    mergeObj.BtnIndex.Value = id
    _newPetButton.obj = mergeObj
    
    local PetInfo = PlayerCsv.PetProperty
    local imgPath = 'UI/petIcon/PetIcon_'..pet.index..'0'..tostring(pet.level)
    mergeObj.PetIcon.Texture = ResourceManager.GetTexture(imgPath)
    mergeObj.PowerBg.Power.Text = pet.realPower
    mergeObj.levelImg.Texture = ResourceManager.GetTexture("UI/fuse/level"..tostring(pet.level))

    -- 绑定合成按钮事件
    mergeObj.Btn.OnClick:Connect(
        function()
            if not _newPetButton.bClick then
                if #self.mergePetTbl >= 5 then
                    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_07)
                    return
                end
                local pet = C_PlayerDataMgr:GetPetInformation(id)
                local newBtnPetIndex = pet.index
                local newBtnPetLevel = pet.level
                table.insert(self.mergePetTbl, id)
                if #self.mergePetTbl <= 1 then
                    -- 记录按钮当前所在位置
                    local curPos
                    for ii = #self.mergePetTbl, 1, -1 do
                        if self.mergePetTbl[ii] == id then
                            curPos = ii
                        end
                    end

                    local tbl = {}
                    for k, v in pairs(self.petBtnList) do
                        local pet = C_PlayerDataMgr:GetPetInformation(v.id)
                        local petIndex = pet.index
                        local petLevel = pet.level
                        if petIndex ~= newBtnPetIndex or petLevel ~= newBtnPetLevel then
                            table.insert(tbl, v)
                        end
                    end
                    self:ArrangeBtnInMerge(tbl)
                    local samePetNum = 0
                    for k, v in pairs(self.petBtnList) do
                        local pet = C_PlayerDataMgr:GetPetInformation(v.id)
                        local petIndex = pet.index
                        local petLevel = pet.level
                        if petIndex == newBtnPetIndex and id ~= v.id and petLevel == newBtnPetLevel then
                            table.insert(tbl, 1, v)
                            samePetNum = samePetNum + 1
                        end
                    end
                    if curPos > samePetNum then
                        curPos = 1
                    end
                    table.insert(tbl,curPos,_newPetButton)
                    self.petBtnList = tbl
                    self.mergePetListPnl.ScrollScale = 0
                    -- 合成室的排序
                    C_UIMgr:ArrangeBtns(self.petBtnList, 180, 230, 255, -230, 3, ConstDef.btnCategoryEnum.petInMerge)
                    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_06)
                end
                _newPetButton.bClick = true
                _newPetButton.obj.CheckIcon:SetActive(true)
                self:ListChosenMergePet()
            else
                for ii = #self.mergePetTbl, 1, -1 do
                    if self.mergePetTbl[ii] == _newPetButton.id then
                        table.remove(self.mergePetTbl, ii)
                    end
                end
                _newPetButton.bClick = false
                self:ListChosenMergePet()
                _newPetButton.obj.CheckIcon:SetActive(false)
                C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_02)
            end
            if self.preMergeBtn and self.preMergeBtn.obj then
                if self.preMergeBtn ~= _newPetButton then
                    self.preMergeBtn.obj.BeChosenBg:SetActive(false)
                end
                
            end
            self.preMergeBtn = _newPetButton
            self.preMergeBtn.obj.BeChosenBg:SetActive(true)
        end
    )
end

--- 限时合成
function C_MergeGui:LimitMergePet()
    -- 要选中五个宠物才能合成
    if #self.mergePetTbl < 5 then
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_07)  
        return
    end
    -- 当日的限时合成次数不能用完
    if C_PlayerDataMgr:GetValue(ConstDef.statsCategoryEnum.LimitMergeNum) <= 0 then    
        return
    end
    local petNameTbl = {}
    for k, v in pairs(self.mergePetTbl) do
        local petInfo = C_PlayerDataMgr:GetPetInformation(v)
        table.insert(petNameTbl,
                     PlayerCsv.PetProperty[petInfo.area][petInfo.zone][petInfo.index]['ModelName']..'0'..tostring(petInfo.level))
    end
    C_PetMgr:FusePetTween(petNameTbl)
    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_01)
    NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId,ConstDef.PlayerActionTypeEnum.Merge,ConstDef.MergeCategoryEnum.limitMerge,self.mergePetTbl)
end

--- 普通合成
function C_MergeGui:NormalMergePet()
    if #self.mergePetTbl < 5 then   -- 要选中五个宠物才能合成
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_07)
        return
    end
    local fstPetId = self.mergePetTbl[1]
    local fstPetInfo = C_PlayerDataMgr:GetPetInformation(fstPetId)
    local fstPetIndex = fstPetInfo.index
    local fstPetLevel = fstPetInfo.level
    local petModelName = PlayerCsv.PetProperty[fstPetInfo.area][fstPetInfo.zone][fstPetIndex]['ModelName']..'0'..tostring(fstPetLevel)
    local names = {}
    -- 必须要是等级一样、名字一样的宠物
    for ii = 5, 1, -1 do
        local petId = self.mergePetTbl[ii]
        local petInfo = C_PlayerDataMgr:GetPetInformation(petId)
        local petIndex = petInfo.index
        local petLevel = petInfo.level
        if petIndex ~= fstPetIndex or petLevel ~= fstPetLevel then
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_07)
            return
        end
        table.insert(names,petModelName)
        C_PetMgr:FusePetTween(names)
    end
    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_02)
    NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId,ConstDef.PlayerActionTypeEnum.Merge,ConstDef.MergeCategoryEnum.normalMerge,self.mergePetTbl)
end

--- 合成室排序
--- @param _tbl table 要排序的table
function C_MergeGui:ArrangeBtnInMerge(_tbl)
    if self.bArrangedByPower then
        -- 按照宠物的realPower排序
        C_UIMgr:ArrangeBtns(self:GetPetArrangedByPower(_tbl), 180, 230, 255, -230, 3, ConstDef.btnCategoryEnum.petInMerge)
    else
        C_UIMgr:ArrangeBtns(self:GetPetArrangedByType(_tbl), 180, 230, 255, -230, 3, ConstDef.btnCategoryEnum.petInMerge)
    end
end

--- 返回宠物按钮按照power排序
--- @param _tbl table 要排序的table
function C_MergeGui:GetPetArrangedByPower(_tbl)
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

--- 返回宠物按钮按照种类排序
--- @param _tbl table 要排序的table
function C_MergeGui:GetPetArrangedByType(_tbl)
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

--- 检测是否有可以普通合成的宠物
function C_MergeGui:MarkFiveSamePet()
    local petTypes = {}
    for _, btn in pairs(self.petBtnList) do
        local pet = C_PlayerDataMgr:GetPetInformation(btn.id)
        if pet then
            local index = pet.index
            local level = pet.level
            if not petTypes[index] then
                petTypes[index] = {}
            end
            if not petTypes[index][level] then
                petTypes[index][level] = {}
            end
            table.insert(petTypes[index][level],btn)
        end
    end
    for _, sameIndexPets in pairs(petTypes) do
        for _, sameLevelPets in pairs(sameIndexPets) do
            if #sameLevelPets >= 5 then
                for _, btn in pairs(sameLevelPets) do
                    btn.obj.CanBeFused:SetActive(true)
                end
            else
                for _, btn in pairs(sameLevelPets) do
                    btn.obj.CanBeFused:SetActive(false)
                end
            end
        end
    end
end

--- 移除宠物按钮
--- @param _petId string 宠物id
function C_MergeGui:RemovePetBtn(_petId)
    for ii = #self.petBtnList, 1, -1 do
        if self.petBtnList[ii].id == _petId then
            self.petBtnList[ii].obj:Destroy()
            table.remove(self.petBtnList,ii)
        end
    end
end

--- 刷新限时反馈的ui
function C_MergeGui:RefreshLimitMergeGui()
    local useCount = C_PlayerDataMgr:GetValue(ConstDef.statsCategoryEnum.LimitMergeNum) -- 限时合成当日次数
    self.remainLimitMergeCountTxt.Text = tostring(useCount)
    if useCount <= 0 then
        self.outOfLimitMergeUseImg:SetActive(true)
    else
		self.outOfLimitMergeUseImg:SetActive(false)
    end
end

--- 初始化宠物按钮
function C_MergeGui:InitAllPetBtn()
    local allPets = C_PlayerDataMgr:GetItem(ConstDef.ItemCategoryEnum.Pet)
    for k, v in pairs(allPets) do
        self:AddNewPetButton(self:CreateNewPetButton(k, nil))
    end
    -- 按钮布局排序
    self:ArrangeBtnInMerge(self.petBtnList)
    self:SetPetBtnPnlRange()
end

--- 检测是否显示合成ui
--- @param _bShow boolean 是否显示
function C_MergeGui:ShowMergeGui(_bShow)
    if _bShow then
        ClearTable(self.mergePetTbl)
        for _, gui in pairs(self.allGui) do
            gui:SetActive(false)
        end
        for _, gui in pairs(self.mergePetPanel:GetChildren()) do
            gui:SetActive(false)
        end
        local composeBar = self.mergePetPanel.CompositionBar
        local petBg = self.mergePetBg
        for _, gui in pairs(composeBar:GetChildren()) do
            gui:SetActive(false)
        end
        for _, gui in pairs(petBg:GetChildren()) do
            gui:SetActive(false)
        end
        local composeBarOldSize = Vector2(900, 320)
        local petBgOldSize = Vector2(831, 904)
        composeBar.Size = Vector2(0,0)
        petBg.Size = Vector2(0,0)
        composeBar:SetActive(true)
        petBg:SetActive(true)
        self.mergeGui:SetActive(true)
        for k, v in pairs(self.helpPnl:GetChildren())do
            v:SetActive(false)
        end
        local composeBarTweener = Tween:TweenProperty(composeBar, {Size = composeBarOldSize}, 0.3, Enum.EaseCurve.BackOut)
        composeBarTweener.OnComplete:Connect(function()
            for _, gui in pairs(self.mergePetPanel:GetChildren()) do
                gui:SetActive(true)
            end
            composeBar.ChosenPetPnl:SetActive(true)
            composeBarTweener:Destroy()
        end)
        composeBarTweener:Play()
        local petBgTweener = Tween:TweenProperty(petBg, {Size = petBgOldSize}, 0.3, Enum.EaseCurve.BackOut)
        petBgTweener.OnComplete:Connect(function()
            for _, gui in pairs(petBg:GetChildren()) do
                gui:SetActive(true)
            end
            petBgTweener:Destroy()
        end)
        petBgTweener:Play()
    else
        local composeBar = self.mergePetPanel.CompositionBar
        local petBg = self.mergePetBg
        for _, gui in pairs(composeBar:GetChildren()) do
            gui:SetActive(false)
        end
        for _, gui in pairs(petBg:GetChildren()) do
            gui:SetActive(false)
        end
        local composeBarOldSize = composeBar.Size
        local petBgOldSize = petBg.Size
        local composeBarTweener = Tween:TweenProperty(composeBar, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)
        composeBarTweener.OnComplete:Connect(function()
            C_MainGui:CheckIfShowMainGui(true)
            composeBar.Size = composeBarOldSize
            composeBarTweener:Destroy()
        end)
        composeBarTweener:Play()
        local petBgTweener = Tween:TweenProperty(petBg, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)
        petBgTweener.OnComplete:Connect(function()
            petBg:SetActive(false)
            petBg.Size = petBgOldSize
            petBgTweener:Destroy()
        end)
        petBgTweener:Play()
    end
end

--- 检测是否显示退出合成动画界面按钮
--- @param _bShow boolean 是否显示
function C_MergeGui:CheckIfShowQuitFuseAnimBtn(_bShow)
    if _bShow then
        self.mergePetPanel:SetActive(false)
        self.mergeGui:SetActive(true)
        self.quitFuseAnimBtn:SetActive(true)
    else
        self.mergeGui:SetActive(false)
        self.mergePetPanel:SetActive(true)
        self.quitFuseAnimBtn:SetActive(false)
    end
end

--- 只退出合成ui界面
function C_MergeGui:QuitMergePetPanel()
    self.mergePetPanel:SetActive(false)
end

local constDefBtnEnum = ConstDef.btnEnum

--- 绑定按钮函数
--- @param _btn string 按钮
--- @param _func function 函数
function C_MergeGui:BindBtnEventCallback(_btn,_func)
    if _btn == constDefBtnEnum.quitFuseAnim then
        self.quitFuseAnimBtn.OnClick:Connect(_func)
    end
end

--- 按钮和函数断开连接
--- @param _btn string 按钮
--- @param _func function 函数
function C_MergeGui:DisconnectBtnEvent(_btn,_func)
    if _btn == constDefBtnEnum.quitFuseAnim then
        self.quitFuseAnimBtn.OnClick:Disconnect(_func)
    end
end

local btnNumInEachPage = 12
--- 设置宠物按钮列表面板范围
function C_MergeGui:SetPetBtnPnlRange()
    local allBtnNum = #self.petBtnList
    local pnlObj = self.mergePetListPnl
    if allBtnNum > 12 then
        local remainder = allBtnNum % btnNumInEachPage
        local pageNum = (allBtnNum - remainder) / btnNumInEachPage
        if remainder > 0 then
            pageNum = pageNum + 1
        end
        pnlObj.ScrollRange = 721 * pageNum
        pnlObj.ScrollScale = 0
        self.allScrollScale = 100
        self.curPageNum.Text = '1'
        self.allPageNum.Text = tostring(math.floor(pageNum))
        self.eachPageScrollRange = 100 / (pageNum - 1)
    else
        pnlObj.ScrollRange = 720
        self.allPageNum.Text = '1'
        self.curPageNum.Text = '1'
        self.allScrollScale = 0
        self.eachPageScrollRange = 0
    end
end

--- 检测选择的五个宠物是否为同一类型同一等级的宠物
function C_MergeGui:CheckIfChosenFiveSamePet()
    local pet = C_PlayerDataMgr:GetPetInformation(self.mergePetTbl[1])
    local fstIndex = pet.index
    local fstLevel = pet.level
    for ii = #self.mergePetTbl, 2, -1 do
        local pet_ = C_PlayerDataMgr:GetPetInformation(self.mergePetTbl[ii])
        if pet_.index ~= fstIndex or pet_.level ~= fstLevel then
            return false
        end
    end
    return true
end

--- 检测是否替换魔法合成按钮ui
--- @param _val boolean 是否替换魔法合成ui
function C_MergeGui:CheckIfChangeMagicFuseUi(_val)
    if _val then
        self.limitMergeBtn = ResourceManager.GetTexture("UI/fuse/MagicFuseFull")
    else
        self.limitMergeBtn = ResourceManager.GetTexture("UI/fuse/MagicFuseNoFull")
    end
end
--- 检测是否替换普通合成ui
--- @param _val boolean 是否替换普通合成ui
function C_MergeGui:CheckIfChangeNormalFuseUi(_val)
    if _val then
        self.normalMergeBtn.Texture = ResourceManager.GetTexture("UI/fuse/NormalFuseFull")
    else
        self.normalMergeBtn.Texture = ResourceManager.GetTexture("UI/fuse/NormalFuseNoFull")
    end
end

--- 添加魔法合成刷新cd时间
function C_MergeGui:AddRefreshMagicMergeTime()
    local refreshMagicMergeTimeTbl = self.refreshMagicMergeTimeTbl
    if not refreshMagicMergeTimeTbl[1] then
        table.insert(refreshMagicMergeTimeTbl,{startTime = os.time(), remain = 300})
    else
        table.insert(refreshMagicMergeTimeTbl,
                     {startTime = refreshMagicMergeTimeTbl[#refreshMagicMergeTimeTbl].startTime + 300, remain = 300})
    end
end

--- 根据DataStore初始化魔法合成时间表
--- @param _remainTime int 第一个cd剩余时间
function C_MergeGui:InitRefreshMagicMergeTimeEventHandler(_remainTime)
    local refreshTimeTbl = C_PlayerDataMgr:GetValue(ConstDef.statsCategoryEnum.RefreshMagicMergeStartTime)
    local newTable = {}
    newTable[1] = {startTime = os.time(), remain = _remainTime}
    for ii = 2, #refreshTimeTbl, 1 do
        table.insert(newTable,ii,{startTime = os.time() + (ii - 1) * 300, remain = 300})
    end
    self.refreshMagicMergeTimeTbl = newTable
end

local constDefAskForFstCdTimeAction = ConstDef.PlayerActionTypeEnum.AskFstCdTime    ---请求第一个魔法合成cd时间
--- 请求获得第一个魔法合成cd剩余时间
function C_MergeGui:RequestFstMagicMergeCDTime()
    NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId,constDefAskForFstCdTimeAction)
end

--- 初始化魔法合成刷新cd的ui变化
function C_MergeGui:InitRefreshMagicMergeCDGuiEvent()
    local RefreshCDGui = function()
        local refreshMagicMergeTimeTbl = self.refreshMagicMergeTimeTbl
        if #refreshMagicMergeTimeTbl < 1 then
            self.RefreshMagicFuseCDTxt.Text = ' '
            return
        else
            if refreshMagicMergeTimeTbl[1].remain <= 0 then
                if refreshMagicMergeTimeTbl[2] then
                    refreshMagicMergeTimeTbl[2].startTime = os.time()
                end
                table.remove(refreshMagicMergeTimeTbl,1)
            end
            if refreshMagicMergeTimeTbl[1] then
                local fstRefreshTime = refreshMagicMergeTimeTbl[1]
                local passTime = os.time() - fstRefreshTime.startTime
                fstRefreshTime.remain = 300 - passTime
                self.RefreshMagicFuseCDTxt.Text = tostring(fstRefreshTime.remain)
                self.RefreshMagicFuseCDImg.FillAmount = passTime / 300
            end
        end
    end
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(1,true,os.time(),RefreshCDGui,true))
    RefreshCDGui()
end

--- 售出宠物处理器
function C_MergeGui:SellPetHandler(_petId)
    self:RemovePetBtn(_petId)
    self:ArrangeBtnInMerge(self.petBtnList)
    self:MarkFiveSamePet()
end

return C_MergeGui