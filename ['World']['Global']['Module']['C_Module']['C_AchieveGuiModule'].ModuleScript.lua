--- 客户端成就UI管理模块
-- @module UI manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_AchieveGui, this = {}, nil

local AchieveGui = {}   ---成就gui
local constDefActionAchieve = ConstDef.PlayerActionTypeEnum.Achieve ---玩家解锁成就行为枚举
local constDefMaxLevel = ConstDef.MAX_ACHIEVE_LEVEL     ---最高成就等级

--- 初始化成就gui的class
--- @param _id number 成就索引
--- @param _obj Object 成就ui
function AchieveGui:Init(_id,_obj)
    self.id = _id
    self.obj = _obj

    self:BindBtnEvent()
end

--- 绑定按钮事件
function AchieveGui:BindBtnEvent()
    self.obj.GetRewardBtn.OnClick:Connect(function()
        NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId,constDefActionAchieve,self.id)
    end)
end

--- 解锁成就等级领取奖励
function AchieveGui:UnlockAchieveLevel()
    local uiObj = self.obj
    local id = self.id
    local curLevel = C_PlayerDataMgr:GetAchieveLevel(id)
    local nxtLevel = curLevel + 1
    if nxtLevel < constDefMaxLevel then
        local curProgressBarName = 'Progress' .. tostring(curLevel)
        local nxtProgressBarName = 'Progress' .. tostring(nxtLevel)
        local curProgressBar = uiObj:GetChild(curProgressBarName)
        local nxtProgressBar = uiObj:GetChild(nxtProgressBarName)
        if curProgressBar then
            curProgressBar:SetActive(false)
        end
        if nxtProgressBar then
            nxtProgressBar:SetActive(true)
        end
        local achieveInfo = PlayerCsv.Achieve[id][nxtLevel]
        uiObj.RewardTxt.Text = tostring(achieveInfo['AchieveAward'])
        uiObj.TotalProgress.Text = ShowAbbreviationNum(tostring(achieveInfo['AchieveData']))
    end
    if not C_PlayerDataMgr:CheckIfPlayerCanGetReward(id) then
        uiObj.MissionCompleteBg:SetActive(false)
        uiObj.GetRewardBtn:SetActive(false)
        C_MainGui:RemoveReceivableAchieve(id)
    end
    self:UpdateProgress()
end

local constDefGetAchieveState = ConstDef.guideState.GetAchieve
local constDefGetAchieveEvent = ConstDef.guideEvent.getAchieve
local constDefCanGetAchieveEvent = ConstDef.guideEvent.canGetAchieve
local constDefExploreState = ConstDef.guideState.Explore

--- 显示可以领取奖励的ui
function AchieveGui:ShowRewardUi()
    local uiObj = self.obj
    uiObj.MissionCompleteBg:SetActive(true)
    uiObj.GetRewardBtn:SetActive(true)
    C_MainGui:AddReceivableAchieve(self.id)

    if C_Guide:CheckGuideIsInState(constDefExploreState) then
        C_Guide:ProcessGuideEvent(constDefCanGetAchieveEvent)
    end
end

--- 更新成就进度
function AchieveGui:UpdateProgress()
    local id = self.id
    local obj = self.obj
    local curProg = C_PlayerDataMgr:GetAchieveCurValue(id)
    local level = C_PlayerDataMgr:GetAchieveLevel(id)
    local totalProg = PlayerCsv.Achieve[id][level + 1]['AchieveData']
    obj.CurProgressTxt.Text = ShowAbbreviationNum(tostring(curProg))
    obj.ProgressBarImg.FillAmount = curProg/totalProg
    if obj.ProgressBarImg.FillAmount > 1 then
        obj.ProgressBarImg.FillAmount = 1
    end
    if level < constDefMaxLevel and curProg/totalProg >= 1 then
        self:ShowRewardUi()
    end
end

--- 根据datastore初始化成就ui
function AchieveGui:InitAchieveGui()
    local id = self.id
    local obj = self.obj
    local nxtLev = C_PlayerDataMgr:GetAchieveLevel(id) + 1
    for ii = constDefMaxLevel, 1, -1 do
        obj:GetChild('Progress'..tostring(ii)):SetActive(false)
    end
    obj:GetChild('Progress' .. tostring(nxtLev)):SetActive(true)
    obj.TotalProgress.Text = tostring(PlayerCsv.Achieve[id][nxtLev]['AchieveData'])
    self:UpdateProgress()
end

--- 初始化
function C_AchieveGui:Init()
    this = self
    self:InitListeners()

    --- 成就系统ui
    self.achieveGui = localPlayer.Local.AchieveGui
    -- 主界面ui
    self.mainGui = localPlayer.Local.ControlGui
    --- 成就面板
    self.achieveBg = self.achieveGui.AchieveBg
    --- 关闭成就面板
    self.quitAchievePnl = self.achieveBg.Quit
    --- @type table 所有成就gui对象
    self.allAchieveGui = {}
    
    -- 全部gui
    local playerLocal = localPlayer.Local
    self.allGui = {
        playerLocal.HatchGui,playerLocal.TransGui,playerLocal.ControlGui,playerLocal.AchieveGui,playerLocal.BagGui,
        playerLocal.MergeGui,playerLocal.StoreGui
    }

    self:InitConnectBtnEvent()
    self:InitAchieveGuiObj()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_AchieveGui:Update(dt)

end

--- 初始化C_AchieveGui自己的监听事件
function C_AchieveGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_AchieveGui, "C_AchieveGui", this)
end

--- 初始绑定按钮事件
function C_AchieveGui:InitConnectBtnEvent()
    -- 退出成就页面
    self.quitAchievePnl.OnClick:Connect(function()
        self:OpenAchieveGui(false)
    end)
end

--- 打开成就面板
--- @param _bShow boolean 是否显示
function C_AchieveGui:OpenAchieveGui(_bShow)
    local bgObj = self.achieveBg.AchieveBg
    local oldSize = bgObj.Size
    if _bShow then
        for k, v in pairs(self.allGui) do
            v:SetActive(false)
        end
        for _, v in pairs(self.achieveBg:GetChildren()) do
            if v ~= bgObj then
                v:SetActive(false)
            end
        end
        bgObj.Size = Vector2(0,0)
        self.achieveGui:SetActive(true)
        local objTweener = Tween:TweenProperty(bgObj, {Size = oldSize}, 0.3, Enum.EaseCurve.BackOut)
        objTweener.OnComplete:Connect(function()
            for _, v in pairs(self.achieveBg:GetChildren()) do
                if v ~= bgObj then
                    v:SetActive(true)
                end
            end
            objTweener:Destroy()
        end)
        objTweener:Play()
    else
        for _, v in pairs(self.achieveBg:GetChildren()) do
            if v ~= bgObj then
                v:SetActive(false)
            end
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

--- 初始化成就gui的对象
function C_AchieveGui:InitAchieveGuiObj()
    local allAchievementUi = self.achieveBg.AchievePnl:GetChildren()
    for _, v in pairs(allAchievementUi) do
        local num = v.Index.Value
        local o = {}
        setmetatable(o,{__index = AchieveGui})
        o:Init(num,v)
        self.allAchieveGui[num] = o
    end
end

--- 解锁成就ui
--- @param _result number 结果
--- @param _achieveId number 成就Id
function C_AchieveGui:UnlockAchieveGui(_result,_achieveId)
    self.allAchieveGui[_achieveId]:UnlockAchieveLevel()
    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_27)
end

--- 更新成就进度ui
--- @param _achieveId number 成就Id
function C_AchieveGui:UpdateAchieveProgGui(_achieveId)
    self.allAchieveGui[_achieveId]:UpdateProgress()
end

--- 根据datastore初始化所有成就Gui
function C_AchieveGui:InitAllAchieveGuis()
    for _, v in pairs(self.allAchieveGui) do
        v:InitAchieveGui()
    end
end

return C_AchieveGui
