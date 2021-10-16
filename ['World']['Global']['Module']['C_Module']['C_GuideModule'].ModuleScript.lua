--- 客户端新手指引管理模块
-- @module guide, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_Guide, this = {}, nil

--- 初始化
function C_Guide:Init()
    --info("C_Guide:Init")
    this = self
    self:InitListeners()
    self.GuideCsv = PlayerCsv.Guide
    ---新手指引状态机
    self.guide = {}
    ---指引箭头特效节点
    self.guideFxObj = localPlayer.Local.Independent.Guide.GuideArrow

    C_GuideGui:Init()
    
    self:CreateGuide()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_Guide:Update(dt)
    local curState = self.guide.curState
    if curState and curState.OnUpdate then
        curState.OnUpdate(self.guide)
    end
end

--- 初始化C_UIMgr自己的监听事件
function C_Guide:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_Guide, "C_Guide", this)
end

--- Guide类
local Guide = {}
local guideTaskId = {
    digGuideMine = 1,
    getAchieve = 2,
    merge = 3,
}
--- 初始化Guide类
function Guide:Init()
    self.curState = nil
    self.taskProgress = 0
end

--- Guide步骤
local Introduction = {}
local GoToPortal = {}
local Transport = {}
local GivePet = {}
local IntroDig = {}
local Dig = {}
local RequestPickEgg = {}
local PickEgg = {}
local DoneDig = {}
local PressTransBtn = {}
local PressHomeBtn = {}
local IntroGen = {}
local GoToGen = {}
local PressHatchBtn = {}
local IntroHatch = {}
local RequestOpenBag = {}
local PressBagBtn = {}
local RequestEquip = {}
local PressEquipBtn = {}
local IntroBag = {}
local Explore = {}
local RequestGoToMerge = {}
local GoToMerge = {}
local TeachMerge = {}
local Merge = {}
local IntroMerge = {}
local PromptAchieve = {}
local GetAchieve = {}
local RequestGoToStore = {}
local GoToStore = {}
local IntroStore = {}
local IntroEnding = {}
local Ending = {}

--- 指引事件枚举
local constDefGuideEvent = ConstDef.guideEvent
--- 新手引导状态枚举
local constDefGuideState = ConstDef.guideState
--- 玩家行为枚举
local ConstDefPlayerAction = ConstDef.PlayerActionTypeEnum
--- 按钮枚举
local constDefBtnEnum = ConstDef.btnEnum
--- 主界面相机枚举
local constDefNormalCamEnum = ConstDef.CameraModeEnum.Normal
--- 引导按钮类别
local constDefClickGuide = GuideSystem.Enum.ClickGuide
--- 新手引导寻路枚举
local constDefGuidePathfindingType = ConstDef.pathFindingType.guide 

---更改状态
---@param nextState table 下个状态
function Guide:ChangeState(nextState)
    local curState = self.curState
	if curState and curState.OnLeave then
		curState.OnLeave(self)
	end
	
	self.curState = nextState
	if nextState.OnEnter then
		nextState.OnEnter(self)
	end
end

---检测指引是否进行到某个步骤
---@param state table 状态
function Guide:IsInState(state)
	if self.curState == state then
		return true
	end
	
	return false
end

--- 处理事件
--- @param event string 事件名称
function Guide:ProcessEvent(event)
	-- global process
    if event == constDefGuideEvent.doneDigMine then
        self:ChangeState(RequestPickEgg)
        return
    elseif event == constDefGuideEvent.getEgg then
        self:ChangeState(DoneDig)
        return
	end
	
	local curState = self.curState
	if curState and curState.OnEvent then
		curState.OnEvent(self,event)
	end
end

--- 完成任务
--- @param taskId number 任务id
function Guide:FinishTask(taskId)
    self.taskProgress = self.taskProgress | (1 << (taskId - 1))
end

--- 检测任务是否完成
--- @param taskId number 任务id
function Guide:IsTaskFinished(taskId)
    return (1 << (taskId - 1)) == self.taskProgress & (1 << (taskId - 1))
end

-- Helper to test
local function CheckIfAllTasksFinished(guide)
    local finishTaskCount = 0
    for taskName, taskId in pairs(guideTaskId) do
        if guide:IsTaskFinished(taskId) then
            finishTaskCount = finishTaskCount + 1
        end
    end

    if finishTaskCount == GetTableLength(guideTaskId) then
        return true
    end
    return false
end

--- 根据datastore
--- @param _stateName string 状态
--- @param _stateTaskProgress number 任务完成进度
function Guide:InitState(_stateName, _stateTaskProgress)
    local transToZone = function()       
        local pos = C_PlayerStatusMgr.explorePos['a1z1']
        localPlayer.Position = Vector3(pos.x, pos.y, pos.z)
        C_PlayerStatusMgr.zoneIndex = 1
        C_PlayerStatusMgr.areaIndex = 1
    end
    if CheckIfAllTasksFinished(self) then
        self:ChangeState(Ending)
    end
    self.taskProgress = _stateTaskProgress
    --当已经完成新手矿开采时，从客户端删去新手矿的节点
    if self:IsTaskFinished(guideTaskId.digGuideMine) then
        C_MainGui:BindBtnEventCallback(constDefBtnEnum.findMine,C_PetMgr.AssignNearestMineToPet)
        local guideMine = localPlayer.Local.Independent.Guide.GuideMine
        if guideMine then
            guideMine:Destroy()
        end
    end

    if _stateName == constDefGuideState.Introduction then
        self:ChangeState(Introduction)
    elseif _stateName == constDefGuideState.Transport then
        transToZone()
        self:ChangeState(Transport)
    elseif _stateName == constDefGuideState.IntroDig then
        transToZone()
        self:ChangeState(IntroDig)
    elseif _stateName == constDefGuideState.DoneDig then
        transToZone()
        self:ChangeState(DoneDig)
    elseif _stateName == constDefGuideState.PressHatchBtn then
        C_HatchGui:ShowHatchGenUi()
        self:ChangeState(PressHatchBtn)
    elseif _stateName == constDefGuideState.IntroHatch then
        self:ChangeState(IntroHatch)
    elseif _stateName == constDefGuideState.RequestOpenBag then
        self:ChangeState(RequestOpenBag)
    elseif _stateName == constDefGuideState.IntroBag then
        self:ChangeState(IntroBag)
    elseif _stateName == constDefGuideState.Explore then
        self:ChangeState(Explore)
    elseif _stateName == constDefGuideState.Ending then
        self:ChangeState(Ending)
    end
end

-- 介绍宠物岛
Introduction.OnEnter = function(guide)
    print('Introduction.OnEnter')
    Introduction.count = 1
    Introduction.maxCount = #C_Guide.GuideCsv['Introduction']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_Guide.guideFxObj:SetActive(false)
    C_GuideGui:SetDialogueText(constDefGuideState.Introduction,1)
end

Introduction.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        Introduction.count = Introduction.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.Introduction,Introduction.count)
        if Introduction.count > Introduction.maxCount then
            guide:ChangeState(GoToPortal)
        end
    end
end

Introduction.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
end

-- 进入传送门
GoToPortal.OnEnter = function(guide)
    print('GoToPortal.OnEnter')
    C_Guide.guideFxObj.Position = Vector3(-27.4915, 17.5257, -317.507)
    C_Guide.guideFxObj:SetActive(true)
    local enterPortalCallback = function(hitObject, hitPoint, hitNormal)
        if hitObject == localPlayer then
            guide:ChangeState(Transport)
        end
    end
    GoToPortal.handler = enterPortalCallback
    C_PlayerStatusMgr.fstPortal.OnCollisionBegin:Connect(
        enterPortalCallback
    )
    GoToPortal.eventId = C_Guide:UpdateWayPoint(C_CollisionMgr:GetPortalPos(1))
end

GoToPortal.OnEvent = function(guide,event)
    if event == constDefGuideEvent.goToPortal then
        guide:ChangeState(Transport)
    end
end

GoToPortal.OnLeave = function(guide)
    C_PlayerStatusMgr.fstPortal.OnCollisionBegin:Disconnect(
        GoToPortal.handler
    )
    C_Guide.guideFxObj:SetActive(false)
    C_Guide:UpdateGuideStateInData(constDefGuideState.Transport)
    C_TimeMgr:RemoveEvent(GoToPortal.eventId)
    PathFinding:DestroyGuideWayPoint()
end

--介绍挖矿场景
Transport.OnEnter = function(guide)
    print('Transport.OnEnter')
    Transport.count = 1
    Transport.maxCount = #C_Guide.GuideCsv['Transport']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_Guide.guideFxObj:SetActive(false)
    C_GuideGui:SetDialogueText(constDefGuideState.Transport,1)
end

Transport.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        Transport.count = Transport.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.Transport,Transport.count)
        if Transport.count > Transport.maxCount then
            guide:ChangeState(GivePet)
        end
    end
end

Transport.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
end

--给玩家一个宠物
GivePet.OnEnter = function(guide)
    print('GivePet.OnEnter')
    NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId,ConstDefPlayerAction.Guide,constDefGuideState.GivePet)
end

GivePet.OnEvent = function(guide,event)
    if event == constDefGuideEvent.givePet then
        guide:ChangeState(IntroDig)
    end
end

GivePet.OnLeave = function(guide)
    C_Guide:UpdateGuideStateInData(constDefGuideState.IntroDig)
end

--介绍挖矿
IntroDig.OnEnter = function(guide)
    print('IntroDig.OnEnter')
    IntroDig.count = 1
    IntroDig.maxCount = #C_Guide.GuideCsv['IntroDig']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_Guide.guideFxObj:SetActive(false)
    C_GuideGui:SetDialogueText(constDefGuideState.IntroDig,1)
end

IntroDig.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        IntroDig.count = IntroDig.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.IntroDig,IntroDig.count)
        if IntroDig.count > IntroDig.maxCount then
            guide:ChangeState(Dig)
        end
    end
end

IntroDig.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
end

--开始挖矿
Dig.OnEnter = function(guide)
    print('Dig.OnEnter')
    GuideSystem:ShowGuide(constDefClickGuide, Vector2(0.805,0.2), Vector2(50,50), nil, true, PathFinding.AssignGuideMine)
    C_MainGui:BindBtnEventCallback(constDefBtnEnum.findMine,PathFinding.AssignGuideMine)
end
Dig.OnLeave = function(guide)
    C_MainGui:BindBtnEventCallback(constDefBtnEnum.findMine,C_PetMgr.AssignNearestMineToPet)
    C_MainGui:DisconnectBtnEvent(constDefBtnEnum.findMine,PathFinding.AssignGuideMine)
end

--要求捡起蛋
RequestPickEgg.OnEnter = function(guide)
    print('RequestPickEgg.OnEnter')
    RequestPickEgg.count = 1
    RequestPickEgg.maxCount = #C_Guide.GuideCsv['RequestPickEgg']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_GuideGui:SetDialogueText(constDefGuideState.RequestPickEgg,1)
end

RequestPickEgg.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        RequestPickEgg.count = RequestPickEgg.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.RequestPickEgg,RequestPickEgg.count)
        if RequestPickEgg.count > RequestPickEgg.maxCount then
            guide:ChangeState(PickEgg)
        end
    end
end

RequestPickEgg.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
end

--捡蛋
PickEgg.OnEnter = function(guide)
    print('PickEgg.OnEnter')
end

PickEgg.OnUpdate = function(guide)
    if C_PlayerDataMgr:GetEggInHandNum() > 0 then
        guide:ChangeState(DoneDig)
    end
end

PickEgg.OnLeave = function(guide)
    C_Guide:UpdateGuideStateInData(constDefGuideState.DoneDig)
    --更新任务进度
    guide:FinishTask(guideTaskId.digGuideMine)
    C_Guide:UpdateGuideTaskInData(guide.taskProgress)
end

--结束挖矿
DoneDig.OnEnter = function(guide)
    print('DoneDig.OnEnter')
    DoneDig.count = 1
    DoneDig.maxCount = #C_Guide.GuideCsv['DoneDig']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_GuideGui:SetDialogueText(constDefGuideState.DoneDig,1)
end

DoneDig.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        DoneDig.count = DoneDig.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.DoneDig,DoneDig.count)
        if DoneDig.count > DoneDig.maxCount then
            guide:ChangeState(PressTransBtn)
        end
    end
end

DoneDig.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
end

--按下trans按钮
PressTransBtn.OnEnter = function(guide)
    print('PressTransBtn.OnEnter')
    local pressBtnCallback = function()
        guide:ChangeState(PressHomeBtn)
    end
    C_MainGui:OnlyShowTransportBtn()
    PressTransBtn.handler = pressBtnCallback
    GuideSystem:ShowGuide(constDefClickGuide, Vector2(0.83,0.62), Vector2(30,30), nil, true, 
                          function() pressBtnCallback()  
                                     C_TransGui:OpenTransGui() end)
    C_MainGui:BindBtnEventCallback(constDefBtnEnum.trans,pressBtnCallback)    
end

PressTransBtn.OnLeave = function(guide)
    C_MainGui:DisconnectBtnEvent(constDefBtnEnum.trans,PressTransBtn.handler)
end

--按下home按钮
PressHomeBtn.OnEnter = function(guide)
    print('PressHomeBtn.OnEnter')
    local pressBtnCallback = function()
        guide:ChangeState(IntroGen)
    end
    PressHomeBtn.handler = pressBtnCallback
    GuideSystem:ShowGuide(constDefClickGuide, Vector2(0.67,0.48), Vector2(50,50), nil, true, 
                          function()
                            pressBtnCallback()
                            C_PlayerStatusMgr:ReturnHome()
                            C_PetMgr:RemoveAllWorkingPets()
                            C_MineGui:RemoveAllProgressBars()
                            C_PetMgr:CurPetsMoveToPlayerPos()
                            C_TransGui:CloseTransGui()
                            -- 玩家不可以使用自动寻矿的功能
                            C_MainGui.autoFindMine.CantFindMine:SetActive(true)
                          end)
	localPlayer.Local.TransGui.TransBg.BtnPnl.TransToHome.OnClick:Connect(pressBtnCallback)
    --C_TransGui:BindBtnEventCallback(constDefBtnEnum.home,pressBtnCallback)
end
PressHomeBtn.OnEvent = function(guide,event)
		if event == 'pressHomeBtn' then
		    guide:ChangeState(IntroGen)
	    end
end
PressHomeBtn.OnLeave = function(guide)
    C_MainGui:ShowAllUi()
	localPlayer.Local.TransGui.TransBg.BtnPnl.TransToHome.OnClick:Disconnect(PressHomeBtn.handler)
    --C_TransGui:DisconnectBtnEvent(constDefBtnEnum.home,PressHomeBtn.handler)
end

--介绍孵蛋器
IntroGen.OnEnter = function(guide)
    print('IntroGen.OnEnter')
    IntroGen.count = 1
    IntroGen.maxCount = #C_Guide.GuideCsv['IntroGen']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_GuideGui:SetDialogueText(constDefGuideState.IntroGen,1)
end

IntroGen.OnUpdate = function(guide)
end

IntroGen.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        IntroGen.count = IntroGen.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.IntroGen,IntroGen.count)
        if IntroGen.count > IntroGen.maxCount then
            guide:ChangeState(GoToGen)
        end
    end
end

IntroGen.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
end

--靠近孵蛋器
GoToGen.OnEnter = function(guide)
    print('GoToGen.OnEnter')
    local goToGenCallBack = function(hitObject, hitPoint, hitNormal)
        if hitObject == localPlayer then
            guide:ChangeState(PressHatchBtn)
        end
		if hitObject.Name == 'EggInstance' and hitObject.Parent == localPlayer.Eggs then
            guide:ChangeState(PressHatchBtn)
         end
    end
    GoToGen.handler = goToGenCallBack
    C_PlayerStatusMgr.fstGen.OnCollisionBegin:Connect(
        goToGenCallBack
    )
    GoToGen.eventId = C_Guide:UpdateWayPoint(C_CollisionMgr:GetEggGenPos(1))
end

GoToGen.OnUpdate = function(guide)
end

GoToGen.OnEvent = function(guide,event)
end

GoToGen.OnLeave = function(guide)
    C_PlayerStatusMgr.fstGen.OnCollisionBegin:Disconnect(
        GoToGen.handler
    )
    C_Guide:UpdateGuideStateInData(constDefGuideState.PressHatchBtn)
    C_TimeMgr:RemoveEvent(GoToGen.eventId)
    PathFinding:DestroyGuideWayPoint()
end

--点击孵化按钮
PressHatchBtn.OnEnter = function(guide)
    print('PressHatchBtn.OnEnter')
    local pressHatchBtnCallBack = function()
        guide:ChangeState(IntroHatch)
    end
    PressHatchBtn.handler = pressHatchBtnCallBack
    --C_HatchGui:BindBtnEventCallback(constDefBtnEnum.hatch,pressHatchBtnCallBack)
end

PressHatchBtn.OnUpdate = function(guide)
end

PressHatchBtn.OnEvent = function(guide,event)
    if event == constDefGuideEvent.hatchEgg then
        guide:ChangeState(IntroHatch)
    end
end

PressHatchBtn.OnLeave = function(guide)
    --C_HatchGui:DisconnectBtnEvent(constDefBtnEnum.hatch,PressHatchBtn.handler)
    C_Guide:UpdateGuideStateInData(constDefGuideState.IntroHatch)
end

--介绍孵化
IntroHatch.OnEnter = function(guide)
    print('IntroHatch.OnEnter')
    C_Camera:ChangeMode(constDefNormalCamEnum)
    IntroHatch.count = 1
    IntroHatch.maxCount = #C_Guide.GuideCsv['IntroHatch']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_GuideGui:SetDialogueText(constDefGuideState.IntroHatch,1)
end

IntroHatch.OnUpdate = function(guide)
end

IntroHatch.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        IntroHatch.count = IntroHatch.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.IntroHatch,IntroHatch.count)
        if IntroHatch.count > IntroHatch.maxCount then
            guide:ChangeState(RequestOpenBag)
        end
    end
end

IntroHatch.OnLeave = function(guide)
    C_BagGui:CheckIfShowUi(constDefBtnEnum.sell,false)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
    C_HatchGui:CheckIfShowHatchGui(false)
    C_Guide:UpdateGuideStateInData(constDefGuideState.RequestOpenBag)
end

--要求打开背包
RequestOpenBag.OnEnter = function(guide)
    print('RequestOpenBag.OnEnter')
    RequestOpenBag.count = 1
    RequestOpenBag.maxCount = #C_Guide.GuideCsv['RequestOpenBag']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_GuideGui:SetDialogueText(constDefGuideState.RequestOpenBag,1)
end

RequestOpenBag.OnUpdate = function(guide)
end

RequestOpenBag.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        RequestOpenBag.count = RequestOpenBag.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.RequestOpenBag,RequestOpenBag.count)
        if RequestOpenBag.count > RequestOpenBag.maxCount then
            guide:ChangeState(PressBagBtn)
        end
    end
end

RequestOpenBag.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)

end

--按下背包按钮
PressBagBtn.OnEnter = function(guide)
    print('PressBagBtn.OnEnter')
    local pressBagBtnCallBack = function()
        guide:ChangeState(RequestEquip)
    end
    PressBagBtn.handler = pressBagBtnCallBack
    GuideSystem:ShowGuide(constDefClickGuide, Vector2(0.92,0.62), Vector2(30,30), nil, true, 
                          function()
                            pressBagBtnCallBack() 
                            C_BagGui:OpenBagGui()
                          end)
    C_MainGui:BindBtnEventCallback(constDefBtnEnum.bag,pressBagBtnCallBack)
end

PressBagBtn.OnUpdate = function(guide)
end

PressBagBtn.OnEvent = function(guide,event)
end

PressBagBtn.OnLeave = function(guide)
    C_MainGui:DisconnectBtnEvent(constDefBtnEnum.bag,PressBagBtn.handler)
end

--要求装备宠物
RequestEquip.OnEnter = function(guide)
    print('RequestEquip.OnEnter')
    C_GuideGui.guideGui:SetActive(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    RequestEquip.count = 1
    RequestEquip.maxCount = #C_Guide.GuideCsv['RequestEquip']
    C_GuideGui:SetDialogueText(constDefGuideState.RequestEquip,1)
end

RequestEquip.OnUpdate = function(guide)
end

RequestEquip.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        RequestEquip.count = RequestEquip.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.RequestOpenBag,RequestEquip.count)
        if RequestEquip.count > RequestEquip.maxCount then
            guide:ChangeState(PressEquipBtn)
        end
    end
end

RequestEquip.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
end

--装备宠物
PressEquipBtn.OnEnter = function(guide)
    print('PressEquipBtn.OnEnter')
    local pressEquipBtnCallback = function()
        guide:ChangeState(IntroBag)
    end
    PressEquipBtn.handler = pressEquipBtnCallback
    C_BagGui:BindBtnEventCallback(constDefBtnEnum.equipPet,pressEquipBtnCallback)
end

PressEquipBtn.OnUpdate = function(guide)
end

PressEquipBtn.OnEvent = function(guide,event)
end

PressEquipBtn.OnLeave = function(guide)
    C_BagGui:DisconnectBtnEvent(constDefBtnEnum.equipPet,PressEquipBtn.handler)
    C_Guide:UpdateGuideStateInData(constDefGuideState.IntroBag)
end

--介绍背包
IntroBag.OnEnter = function(guide)
    print('IntroBag.OnEnter')
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui.guideGui:SetActive(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    IntroBag.count = 1
    IntroBag.maxCount = #C_Guide.GuideCsv['IntroBag']
    C_GuideGui:SetDialogueText(constDefGuideState.IntroBag,1)
end

IntroBag.OnUpdate = function(guide)
end

IntroBag.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        IntroBag.count = IntroBag.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.IntroBag,IntroBag.count)
        if IntroBag.count > IntroBag.maxCount then
            guide:ChangeState(Explore)
        end
    end
end

IntroBag.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
    C_Guide:UpdateGuideStateInData(constDefGuideState.Explore)
end

--自由探索
Explore.OnEnter = function(guide)
    print('Explore.OnEnter')
    C_GuideGui:CheckIfShowGuideGui(false)
    Explore.needPromptAchieve = false
	Explore.needPromptMerge = false
end

local constDefDiamond = ConstDef.ServerResTypeEnum.Diamond  ---资源中获取钻石索引

Explore.OnUpdate = function(guide)
    -- 当所有支线任务完成时，结束新手指引
    if CheckIfAllTasksFinished(guide) then
        guide:ChangeState(IntroEnding)
    end

    if Explore.needPromptAchieve then
        if C_Camera:CheckIfWorldCurCamIsNormalCam() then
            guide:ChangeState(PromptAchieve)
			Explore.needPromptAchieve = false
        end
    end
	
	if Explore.needPromptMerge then
		if C_Camera:CheckIfWorldCurCamIsNormalCam() then
            guide:ChangeState(RequestGoToMerge)
			Explore.needPromptMerge = false
        end
	end
end

local constDefGetFiveSamePetsEvent = ConstDef.guideEvent.getFiveSamePets    ---获得五个相同的宠物
local constDefGetAchieveEvent = ConstDef.guideEvent.getAchieve              ---获得成就事件
local constDefCanGetAchieveEvent = ConstDef.guideEvent.canGetAchieve        ---可以获得成就事件
Explore.OnEvent = function(guide,event)
    if event == constDefGetFiveSamePetsEvent then
        if not guide:IsTaskFinished(guideTaskId.merge) then
			Explore.needPromptMerge = true
        end
    elseif event == constDefCanGetAchieveEvent then
        if not guide:IsTaskFinished(guideTaskId.getAchieve) then
            Explore.needPromptAchieve = true
        end
    end
end

Explore.OnLeave = function(guide)
end

--要求前往合成室
RequestGoToMerge.OnEnter = function(guide)
    print('RequestGoToMerge.OnEnter')
    C_GuideGui.guideGui:SetActive(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    RequestGoToMerge.count = 1
    RequestGoToMerge.maxCount = #C_Guide.GuideCsv['RequestGoToMerge']
    C_GuideGui:SetDialogueText(constDefGuideState.RequestGoToMerge,1)
end
RequestGoToMerge.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        RequestGoToMerge.count = RequestGoToMerge.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.RequestGoToMerge,RequestGoToMerge.count)
        if RequestGoToMerge.count > RequestGoToMerge.maxCount then
            guide:ChangeState(GoToMerge)
        end
    end
end

RequestGoToMerge.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
end

--前往合成室
GoToMerge.OnEnter = function(guide)
    print('GoToMerge.OnEnter')
    GoToMerge.eventId = C_Guide:UpdateWayPoint(C_CollisionMgr:GetMergeRoomPos(1))
end
GoToMerge.OnEvent = function(guide,event)
    if event == constDefGuideEvent.goToMerge then
        guide:ChangeState(TeachMerge)
    end
end

GoToMerge.OnLeave = function(guide)
    C_TimeMgr:RemoveEvent(GoToMerge.eventId)
    PathFinding:DestroyGuideWayPoint()
end

--合成教学
TeachMerge.OnEnter = function(guide)
    print('TeachMerge.OnEnter')
    C_GuideGui.guideGui:SetActive(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    TeachMerge.count = 1
    TeachMerge.maxCount = #C_Guide.GuideCsv['TeachMerge']
    C_GuideGui:SetDialogueText(constDefGuideState.TeachMerge,1)
end
TeachMerge.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        TeachMerge.count = TeachMerge.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.TeachMerge,TeachMerge.count)
        if TeachMerge.count > TeachMerge.maxCount then
            guide:ChangeState(Merge)
        end
    end
end

TeachMerge.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
end

local ConstDefAskSaveAction = ConstDef.PlayerActionTypeEnum.AskSave     ---请求服务器储存数据行为
--合成
Merge.OnEnter = function(guide)
    print('Merge.OnEnter')
    local pressQuitAnimCallback = function()
        guide:ChangeState(IntroMerge)
    end
    Merge.handler = pressQuitAnimCallback
    C_MergeGui:BindBtnEventCallback(constDefBtnEnum.quitFuseAnim,pressQuitAnimCallback)
end
Merge.OnLeave = function(guide)
    C_MergeGui:DisconnectBtnEvent(constDefBtnEnum.quitFuseAnim,Merge.handler)
    --更新任务进度
    guide:FinishTask(guideTaskId.merge)
    C_Guide:UpdateGuideTaskInData(guide.taskProgress)
    NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId,ConstDefAskSaveAction)
end

--介绍合成
IntroMerge.OnEnter = function(guide)
    print('IntroMerge.OnEnter')
    C_Camera:ChangeMode(constDefNormalCamEnum)
    C_GuideGui.guideGui:SetActive(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    IntroMerge.count = 1
    IntroMerge.maxCount = #C_Guide.GuideCsv['IntroMerge']
    C_GuideGui:SetDialogueText(constDefGuideState.IntroMerge,1)
end
IntroMerge.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        IntroMerge.count = IntroMerge.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.IntroMerge,IntroMerge.count)
        if IntroMerge.count > IntroMerge.maxCount then
            guide:ChangeState(Explore)
        end
    end
end

IntroMerge.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
end

--提示解锁成就
PromptAchieve.OnEnter = function(guide)
    print('PromptAchieve.OnEnter')
    PromptAchieve.count = 1
    PromptAchieve.maxCount = #C_Guide.GuideCsv['PromptAchieve']
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui:CheckIfShowGuideGui(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    C_GuideGui:SetDialogueText(constDefGuideState.PromptAchieve,1)
end

PromptAchieve.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        PromptAchieve.count = PromptAchieve.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.PromptAchieve,PromptAchieve.count)
        if PromptAchieve.count > PromptAchieve.maxCount then
            guide:ChangeState(GetAchieve)
        end
    end
end

PromptAchieve.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
    C_MainGui:OnlyShowAchieveBtn()
end

--解锁成就
GetAchieve.OnEnter = function(guide)
    print('GetAchieve.OnEnter')
    GuideSystem:ShowGuide(constDefClickGuide, Vector2(0.74,0.62), Vector2(50,50), nil, true, 
                         function() C_AchieveGui:OpenAchieveGui(true) guide:ChangeState(Explore) end)
end
GetAchieve.OnEvent = function(guide,event)
end

GetAchieve.OnLeave = function(guide)
    C_MainGui:ShowAllUi()
    guide:FinishTask(guideTaskId.getAchieve)
    C_Guide:UpdateGuideTaskInData(guide.taskProgress)
end


--新手教程结束语
IntroEnding.OnEnter = function(guide)
    print('IntroEnding.OnEnter')
    C_MainGui:CheckIfShowMainGui(false)
    C_GuideGui.guideGui:SetActive(true)
    C_GuideGui:CheckIfShowDialogueGui(true)
    IntroEnding.count = 1
    IntroEnding.maxCount = #C_Guide.GuideCsv['IntroEnding']
    C_GuideGui:SetDialogueText(constDefGuideState.IntroEnding,1)
end

IntroEnding.OnEvent = function(guide,event)
    if event == constDefGuideEvent.clickDialogue then
        IntroEnding.count = IntroEnding.count + 1
        C_GuideGui:SetDialogueText(constDefGuideState.IntroEnding,IntroEnding.count)
        if IntroEnding.count > IntroEnding.maxCount then
            guide:ChangeState(Ending)
        end
    end
end

IntroEnding.OnLeave = function(guide)
    C_GuideGui:CheckIfShowGuideGui(false)
    C_GuideGui:CheckIfShowDialogueGui(false)
    C_MainGui:CheckIfShowMainGui(true)
    C_Guide:UpdateGuideStateInData(constDefGuideState.Ending)
end

--新手教程结束
Ending.OnEnter = function(guide)
    print('Ending.OnEnter')
end


---初始化生成指引对象
function C_Guide:CreateGuide()
    local o = {}
    setmetatable(o,{__index = Guide})
    o:Init()
    self.guide = o
end

---外部检测当前是否处于某个状态
---@param _guideState number 状态枚举：constDefGuideState
function C_Guide:CheckGuideIsInState(_guideState)
    local state
    if _guideState == constDefGuideState.GoToPortal then
        state = GoToPortal
    elseif _guideState == constDefGuideState.PickEgg then
        state = PickEgg
    elseif _guideState == constDefGuideState.Dig then
        state = Dig
    elseif _guideState == constDefGuideState.GoToMerge then
        state = GoToMerge
    elseif _guideState == constDefGuideState.GetAchieve then
        state = GetAchieve
    elseif _guideState == constDefGuideState.GoToStore then
        state = GoToStore
    elseif _guideState == constDefGuideState.Explore then
        state = Explore
    elseif _guideState == constDefGuideState.Merge then
        state = Merge
    elseif _guideState == constDefGuideEvent.GivePet then
        state = GivePet
    end
    if self.guide.curState == state then
		return true
	end
	
	return false
end

---外部触发状态机事件
---@param _guideEvent number 状态事件枚举：constDefGuide
function C_Guide:ProcessGuideEvent(_event)
    self.guide:ProcessEvent(_event)
end

---更新DataStore新手引导进度
---@param _guideState string 状态枚举：constDefGuideState
function C_Guide:UpdateGuideStateInData(_guideState)
    C_PlayerDataMgr:ChangeGuideState(_guideState)
    NetUtil.Fire_S('SyncDataFromClientEvent',localPlayer.UserId,'guideState',_guideState)
end

---更新DataStore新手任务完成度
---@param _guideTaskProgress number 任务完成进度
function C_Guide:UpdateGuideTaskInData(_guideTaskProgress)
    C_PlayerDataMgr:ChangeGuideTaskProgress(_guideTaskProgress)
    NetUtil.Fire_S('SyncDataFromClientEvent',localPlayer.UserId,'guideTask',_guideTaskProgress)
end

---根据DataStore初始化新手引导进度
function C_Guide:InitGuideState()
    local curState = C_PlayerDataMgr:GetValue(ConstDef.clientResourceEnum.GuideState)
    local taskProgress = C_PlayerDataMgr:GetValue(ConstDef.clientResourceEnum.GuideTask)
    self.guide:InitState(curState,taskProgress)
end

--- 更新新手引导的寻路点
function C_Guide:UpdateWayPoint(dstPos)
    local newDstPos = Vector3(dstPos.x,localPlayer.Position.y,dstPos.z)
    PathFinding:CreatePathFindingWayPoints(localPlayer.Position,newDstPos,constDefGuidePathfindingType)
    local event = C_TimeMgr:CreateNewEvent(1,true,os.time(),
                                           function()
                                                PathFinding:DestroyGuideWayPoint()
                                                PathFinding:CreatePathFindingWayPoints(localPlayer.Position,newDstPos,constDefGuidePathfindingType)
                                           end,true)
    C_TimeMgr:AddEvent(event)
    return event.id
end

return C_Guide