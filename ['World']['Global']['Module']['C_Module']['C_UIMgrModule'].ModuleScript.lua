--- 客户端UI管理模块
-- @module UI manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_UIMgr, this = {}, nil

--- 创建新的egg对象
--- @param _pet table  宠物
--- @param _petListButton Object  宠物列表的按钮
--- @param _mergeButton Object  合成列表的按钮
local function CreateNewPetButton(_pet, _petListButton, _mergeButton)
    local o = {}
    setmetatable(o, {__index = PetButton})
    o:Init(_pet, _petListButton, _mergeButton)
    return o
end

--- 初始化
function C_UIMgr:Init()
    --info("C_UIMgr:Init")
    this = self
    self:InitListeners()

    local indGui = localPlayer.Local.ControlGui
    -- 本地UI
    self.indGui = indGui
    -- 主场景panel
    self.mainScenePnl = indGui.MainSceneUI
    

    -- 金钱解锁大场景背景图
    self.unlockAreaBg = indGui.UnlockAreaBg
    -- 解锁场景所需金钱数
    self.unlockAreaMoneyTxt = self.unlockAreaBg.MoneyTxt
    -- 确认解锁场景按钮
    self.confirmUnlockAreaBtn = self.unlockAreaBg.ConfirmBtn
    -- 取消解锁场景按钮
    self.cancelUnlockAreaBtn = self.unlockAreaBg.CancelBtn

    -- 合成按钮
    --self.mergeBtn = self.mergePetPanel.MergeBtn

    -- 回城按钮
    self.homeBtn = indGui.HomeBtn

    -- 上一个选择合成的按钮
    self.preMergeBtn = nil

    -- 便捷传送门按钮
    self.portalBtn = indGui.PortalBtn

    -- 是否显示鼓励ui
    self.bShowEncrUI = false
    -- 是否选择普通合成
    self.bChooseNormalMerge = false
    -- 是否选择限时合成
    self.bChooseLimitMerge = false
    -- 限时合成按钮是否处于倒计时状态
    self.bLimitMergeTimer = false
    -- 是否打开了宠物信息面板
    self.bOpenPetInfo = false

    --- @type int 总共购买药水数量
    self.buyPotionBtnNum = 0

    --- @type int 限时合成开始倒计时的时间,单位：秒
    self.startLimitMergeTime = 0

    --- @type int 使用限时合成的次数
    self.limitMergeUseCount = 5

    -- 每行按钮数量
    self.BUTTON_NUM_IN_ROW = 3
    -- 按钮隔行间隔
    self.BUTTON_ROW_INTERVAL = 200
    -- 按钮隔列间隔
    self.BUTTON_COLUMN_INTERVAL = 200
    -- 按钮行开头的x位置
    self.FIRST_BTN_XPOS_IN_ROW = 300
    -- 按钮列开头的y位置
    self.FIRST_BTN_YPOS_IN_COLUMN = -300
    -- 限时合成按钮启动间隔时间,单位：秒
    self.LIMIT_MERGE_INTERVAL = 20

    -- 宠物按钮tbl
    self.petButtonTbl = {}
    -- 普通合成所选择的宠物table
    self.normalMergePetTbl = {}
    -- 限时合成所选择的宠物table
    self.limitMergePetTbl = {}
    -- 合成所选择的宠物table
    self.mergePetTbl = {}
    -- 背包里蛋的按钮列表
    self.eggBtnInBagList = {}
    -- 背包里的药水的按钮列表
    self.potionBtnInBagList = {}
    self:ConnectButtons()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_UIMgr:Update(dt)

end

--- 初始化C_UIMgr自己的监听事件
function C_UIMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_UIMgr, "C_UIMgr", this)
end

--- 当下载完长期储存的数据后初始化ui
function C_UIMgr:InitClientUI()
    -- 是否购买任意探索的
    --if C_PlayerDataMgr:GetValue(ConstDef.PlayerAttributeEnum.CanExplore) then
    --    C_UIMgr.exploreBtn.LockBtn:SetActive(false)
    --else
    --    C_UIMgr.exploreBtn.LockBtn:SetActive(true)
    --end
end



-- 绑定按钮
function C_UIMgr:ConnectButtons()
    ---- 关闭合成宠物
    --self.quitMergePet.OnDown:Connect(
    --    function()
    --        self.mainScenePnl:SetActive(true)
    --        self.mergePetPanel:SetActive(false)
    --        ClearTable(self.mergePetTbl)
    --        self:ListChosenMergePet()
    --    end
    --)
    -- 解锁场景按钮
    self.confirmUnlockAreaBtn.OnDown:Connect(
        function()
            C_PlayerStatusMgr:UnlockNewArea()
            self.unlockAreaBg:SetActive(false)
            self.mainScenePnl:SetActive(true)
        end
    )
    -- 取消解锁场景
    self.cancelUnlockAreaBtn.OnDown:Connect(
        function()
            self.unlockAreaBg:SetActive(false)
            self.mainScenePnl:SetActive(true)
        end
    )
end

--- 按钮排列
--- @param _tbl table 按钮所属的按钮表
--- @param _rowInterval int 每行间隔
--- @param _columnInterval int 每列间隔
--- @param _rowStartPoint int 行开头y坐标
--- @param _columnStartPoint int 列开头x坐标
--- @param _maxBtnInRow int 每行最多按钮的数量
--- @param _btnCategory number 按钮类别：ConstDef.btnCategoryEnum
function C_UIMgr:ArrangeBtns(
    _tbl,
    _rowInterval,
    _columnInterval,
    _rowStartPoint,
    _columnStartPoint,
    _maxBtnInRow,
    _btnCategory)
    local rowIndex = 0
    local columnIndex = -1
    for k, v in pairs(_tbl) do
        columnIndex = columnIndex + 1
        if columnIndex > _maxBtnInRow - 1 then
            columnIndex = 0
            rowIndex = rowIndex + 1
        end
        local pos =
            Vector2(_columnStartPoint + columnIndex * _columnInterval, _rowStartPoint - rowIndex * _rowInterval)
        if _btnCategory == ConstDef.btnCategoryEnum.petInBag then
            v.obj.Offset = pos
        elseif _btnCategory == ConstDef.btnCategoryEnum.petInMerge then
            v.obj.Offset = pos
        else
			print(v.Offset)
            v.Offset = pos
        end
        
    end
end

--- 选择宠物之后显示图标
function C_UIMgr:ListChosenMergePet()
    local chosenPetPnl = self.mergePetPanel.CompositionBar.ChosenPetPnl
    local imgs = chosenPetPnl:GetChildren()
    local petNum = GetTableLength(self.mergePetTbl)
    local imgNameTbl = {}
    for k, v in pairs(chosenPetPnl:GetChildren()) do
        v.Alpha = 0
    end
    for k, v in pairs(self.mergePetTbl) do
        table.insert(imgNameTbl, v.pet.index)
    end
    for k, v in pairs(imgNameTbl) do
        local path = "Texture/" .. tostring(v)
        local imgObj = chosenPetPnl:GetChild("PetImg" .. tostring(k))
        if imgObj then
            imgObj.Texture = ResourceManager.GetTexture(path)
            imgObj.Alpha = 1
        end
    end
end

--- 清空合成室选择宠物之后的图标
function C_UIMgr:ClearChosenPetsImgInMergeRoom()
    local chosenPetPnl = self.mergePetPanel.CompositionBar.ChosenPetPnl
    local imgs = chosenPetPnl:GetChildren()
    for k, v in pairs(imgs) do
        v.Alpha = 0
    end
end

--- 将新的宠物添加进合成列表
--- @param _pet table 宠物
function C_UIMgr:AddNewPetToMergeUI(_pet)
    self:AddNewPetButton(CreateNewPetButton(_pet, nil, nil))
end

--- 移除宠物的按钮
--- @param _btnTbl table 需要被移除的按钮
function C_UIMgr:RemovePetBtn(_btnTbl)
    for k, v in pairs(_btnTbl) do
        v.petListObj:Destroy()
        v.mergeObj:Destroy()
        self.petButtonTbl[v.id] = nil
    end
    ClearTable(self.mergePetTbl)
    -- 背包里的排序
    self:ArrangeBtns(self.petButtonTbl, 150, 140, 170, -150, 3, ConstDef.btnCategoryEnum.petInBag)
    -- 合成室的排序
    self:ArrangeBtns(self.petButtonTbl, 130, 120, 150, -300, 6, ConstDef.btnCategoryEnum.petInMerge)
end

--- 限时按钮进入倒计时，倒计时过程中无法点击
function C_UIMgr:DisableLimitMerge()
    self.bLimitMergeTimer = true
    self.chooseLimitMergeBtn.Clickable = false
    self.startLimitMergeTime = C_TimeMgr.curSecond
end

--- 显示孵化面板
--- @param _areaIndex int 场景序号
function C_UIMgr:ShowHatchPnl(_areaIndex)
    self.hatchPnl:SetActive(true)
    self.mainScenePnl:SetActive(false)
    local probPnl = self.hatchPnl.ProbPnl
    for k, v in pairs(probPnl:GetChildren()) do
        v:SetActive(false)
    end
    local probBg = probPnl:GetChild("Area" .. tostring(_areaIndex))
    probBg:SetActive(true)
end

--- 接收成就可以升级的UI变化处理器
--- @param _achieveId number 成就索引
--- @param _achieveLevel int 成就等级

return C_UIMgr
