--- 客户端提示ui管理模块
-- @module notice ui, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_NoticeGui, this = {}, nil

--- 初始化
function C_NoticeGui:Init()
    --info("C_NoticeGui:Init")
    this = self
    self:InitListeners()

    --提示ui
    self.noticeGui = localPlayer.Local.NoticeGui
    --限时解锁场景提示背景
    self.unlockMineNtcBg = self.noticeGui.UnlockMineNotice
    --限时解锁场景提示文字
    self.unlockMineNtcTxt = self.unlockMineNtcBg.Text
    --金钱解锁关卡提示
    self.payForUnlockNtc = self.noticeGui.PayForUnlockZone
    --金钱解锁关卡提示背景
    self.payForUnlockNtcBg = self.payForUnlockNtc.Bg
    --金钱解锁关卡确定按钮
    self.payForUnlockBtn = self.payForUnlockNtcBg.Pay
    --金钱解锁关卡退出
    self.payForUnlockQuit = self.payForUnlockNtcBg.Quit
    --金钱解锁关卡数目文字
    self.payForUnlockPriceTxt = self.payForUnlockNtcBg.PriceTxt
    --世界boss奖励
    self.bossRewardNtcImg = self.noticeGui.BossReward
    --世界boss奖励图动画
    self.bossRewardNtcTweener = {}

    --所有消息
    self.allMsg = {}
    --所有消息图片
    self.allMsgImg = {}
    --消息表
    self.config = PlayerCsv.Notice
    --全部gui
    local playerLocal = localPlayer.Local
    self.allGui = {
        playerLocal.HatchGui,playerLocal.TransGui,playerLocal.ControlGui,playerLocal.AchieveGui,playerLocal.BagGui,
        playerLocal.MergeGui,playerLocal.StoreGui
    }

    self:InitConnectBtnEvent()
    self:InitBossRewardNtcTweener()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_NoticeGui:Update(dt)
end

--- 初始化C_NoticeGui自己的监听事件
function C_NoticeGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_NoticeGui, "C_NoticeGui", this)
end

local constDefCoinNum = ConstDef.ServerResTypeEnum.Coin ---金币资源数枚举
local constDefUnlockZoneAction = ConstDef.PlayerActionTypeEnum.UnlockZone   ---解锁区域枚举

--- 初始化按钮
function C_NoticeGui:InitConnectBtnEvent()
    --退出金钱解锁关卡
    self.payForUnlockQuit.OnClick:Connect(function()
        self:ClosePayForUnlock()
    end)

    --确认解锁关卡
    self.payForUnlockBtn.OnClick:Connect(function()
        local area = C_PlayerStatusMgr.areaIndex
        local zone = C_PlayerStatusMgr.zoneIndex
        local needRes = PlayerCsv.CheckpointData[area][zone]['ChallengeData']
        local condition01 = TStringNumCom(C_PlayerDataMgr:GetValue(constDefCoinNum), needRes)
        if condition01 == 0 or condition01 then
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_20)
            NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId,constDefUnlockZoneAction,area,zone)
        else
            
        end
    end)
end

--- 检测是否显示解锁矿提示
--- @param _bShow boolean 是否显示
function C_NoticeGui:CheckIfShowUnlockMineNtc(_bShow)
    if _bShow then
        if not self.unlockMineNtcBg.ActiveSelf then
            self.unlockMineNtcBg:SetActive(_bShow)
        end
    else
        if self.unlockMineNtcBg.ActiveSelf then
            self.unlockMineNtcBg:SetActive(_bShow)
        end
    end
end

--- 显示解锁矿提示
function C_NoticeGui:ShowUnlockMineNtc()
    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_23)
    self.unlockMineNtcBg.Offset = Vector2(0,1000)
    self.unlockMineNtcBg:SetActive(true)
    self:ChangeUnlockMineNtcTxt('KeepUnlock')
    local downTweener = Tween:TweenProperty(self.unlockMineNtcBg,{Offset = Vector2(0,600)},0.8,Enum.EaseCurve.BackOut)
    downTweener.OnComplete:Connect(function()
        downTweener:Destroy()
    end)
    downTweener:Play()
end

--- 改变解锁矿提示文字
--- @param _nameId string 通知索引
function C_NoticeGui:ChangeUnlockMineNtcTxt(_nameId)
    self.unlockMineNtcTxt.Text = PlayerCsv.Notice[_nameId]['Content']
end

--- 隐藏解锁矿提示
--- @param _nameId string 通知索引
function C_NoticeGui:HideUnlockMineNtc(_nameId)
    self:ChangeUnlockMineNtcTxt(_nameId)
    local upTweener = Tween:TweenProperty(self.unlockMineNtcBg,{Offset = Vector2(0,1000)},0.8,Enum.EaseCurve.BackIn)
    upTweener.OnComplete:Connect(function()
        self.unlockMineNtcBg:SetActive(false)
        upTweener:Destroy()
    end)
    local playTweener = function() upTweener:Play() end
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(1,false,os.time(),playTweener,true))
end

--- 显示金钱解锁关卡页面
--- @param _area int 场景
--- @param _zone int 关卡
function C_NoticeGui:ShowPayForUnlock(_area,_zone)
    for _, gui in pairs(self.allGui) do
        gui:SetActive(false)
    end
    local bgObj = self.payForUnlockNtcBg
    local oldSize = bgObj.Size
    bgObj.Size = Vector2(0,0)
    for _, gui in pairs(bgObj:GetChildren()) do
        gui:SetActive(false)
    end
    self.payForUnlockNtc:SetActive(true)
    local objTweener = Tween:TweenProperty(bgObj, {Size = oldSize}, 0.3, Enum.EaseCurve.BackOut)
    objTweener.OnComplete:Connect(function()
        self.payForUnlockPriceTxt.Text = PlayerCsv.CheckpointData[_area][_zone]['ChallengeData']
        for _, gui in pairs(bgObj:GetChildren()) do
            gui:SetActive(true)
        end
        objTweener:Destroy()
    end)
    objTweener:Play()
end

--- 关闭金钱解锁关卡页面
function C_NoticeGui:ClosePayForUnlock()
    local bgObj = self.payForUnlockNtcBg
    local oldSize = bgObj.Size
    for _, gui in pairs(bgObj:GetChildren()) do
        gui:SetActive(false)
    end
    local objTweener = Tween:TweenProperty(bgObj, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)
    objTweener.OnComplete:Connect(function()
        self.payForUnlockNtc:SetActive(false)
        bgObj.Size = oldSize
        C_MainGui:CheckIfShowMainGui(true)
        objTweener:Destroy()
    end)
    objTweener:Play()
end

---消息事件监听
---@param _msgID string 提示消息的ID
function C_NoticeGui:NoticeListener(_msgID)
    local msgContent = self.config[_msgID].Content
    local msgObj = world:CreateInstance('MsgImg','MsgImg',self.noticeGui)
    local anchorY = 0.05 + #self.allMsg * 0.08
    msgObj.AnchorsY = Vector2(anchorY, anchorY)
    msgObj.Content.Text = msgContent
    table.insert(self.allMsg, msgObj)

    if #self.allMsg == 1 then
        local event = C_TimeMgr:CreateNewEvent(1,true,C_TimeMgr.curTime,nil,false)
        local eventId = event.id
        local handler = function()
            local obj = self.allMsg[1]
            table.remove(self.allMsg,1)
            obj:Destroy()
            if #self.allMsg < 1 then
                C_TimeMgr:RemoveEvent(eventId)
                return
            end
            for ii = 1, #self.allMsg, 1 do
                local obj = self.allMsg[ii]
                local newAnchorY = 0.05 + (ii - 1) * 0.08
                local tweener = Tween:TweenProperty(obj, {AnchorsY = Vector2(newAnchorY,newAnchorY)}, 0.1, Enum.EaseCurve.Linear)
                tweener.OnComplete:Connect(function()
                    tweener:Destroy()
                end)
                tweener:Play()
            end
        end
        event.handler = handler
        C_TimeMgr:AddEvent(event)
    end
end

--- 图片提示监听
--- @param _msgImgName string 提示图片的Archetype名称
function C_NoticeGui:ImgNoticeListener(_msgImgName)
    table.insert(self.allMsgImg, _msgImgName)
    if #self.allMsgImg == 1 then
        self:ImgNoticeTweener(_msgImgName)
        local event = C_TimeMgr:CreateNewEvent(3,true,C_TimeMgr.curTime,nil,false)
        local eventId = event.id
        local handler = function()
            table.remove(self.allMsgImg,1)
            if #self.allMsgImg < 1 then
                C_TimeMgr:RemoveEvent(eventId)
                return
            end
            self:ImgNoticeTweener(self.allMsgImg[1])
        end
        event.handler = handler
        C_TimeMgr:AddEvent(event)
    end
end

--- 图片提示动画
--- @param _msgImgName string 提示图片的Archetype名称
function C_NoticeGui:ImgNoticeTweener(_msgImgName)
    local obj = world:CreateInstance(_msgImgName,'MsgImg',self.noticeGui)
	print(_msgImgName)
    obj.AnchorsY = Vector2(1.1, 1.1)
    local tweener01 = Tween:TweenProperty(obj, {AnchorsY = Vector2(0.78, 0.78)}, 0.3, Enum.EaseCurve.BackOut)
    tweener01.OnComplete:Connect(function()
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(2,false,os.time(),function() 
                                                        local tweener02 = Tween:TweenProperty(obj, {AnchorsY = Vector2(1.2, 1.2)}, 0.3, Enum.EaseCurve.BackIn)                           
                                                        tweener02.OnComplete:Connect(function()
                                                            tweener02:Destroy()
                                                            obj:Destroy()
                                                        end)
                                                        tweener02:Play()
                                                    end,true))
        tweener01:Destroy()
    end)
    tweener01:Play()
end

--- 特殊图片提示动画
--- @param _msgImgName string 提示图片的Archetype名称
function C_NoticeGui:SpImgNoticeTweener(_msgImgName)
    local obj = world:CreateInstance(_msgImgName,'MsgImg',self.noticeGui)
	local leftObj = obj.LeftImg
	local rightObj = obj.RightImg
	local centerObj = obj.CenterImg
	local oldCenterSize = centerObj.Size
	centerObj.Size = Vector2(0,0)
	local tweener01 = Tween:TweenProperty(leftObj, {AnchorsX = Vector2(0.5,0.5)}, 0.2, Enum.EaseCurve.CubicOut)
	local tweener02 = Tween:TweenProperty(rightObj, {AnchorsX = Vector2(0.5, 0.5)}, 0.2, Enum.EaseCurve.CubicOut)
	local tweener03 = Tween:TweenProperty(centerObj, {Size = oldCenterSize}, 0.2, Enum.EaseCurve.BackOut)
	local tweener04 = Tween:TweenProperty(leftObj, {AnchorsX = Vector2(1.5, 1.5)}, 0.2, Enum.EaseCurve.CubicIn)
	local tweener05 = Tween:TweenProperty(rightObj, {AnchorsX = Vector2(-0.5, -0.5)}, 0.2, Enum.EaseCurve.CubicIn)
	local tweener06 = Tween:TweenProperty(centerObj, {Size = Vector2(0,0)}, 0.2, Enum.EaseCurve.BackIn)
	tweener01.OnComplete:Connect(function() tweener03:Play() end)
	tweener03.OnComplete:Connect(function()
		C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(2,false,os.time(),function() 
			tweener04:Play()
			tweener05:Play()
		end,true))
	end)
	tweener05.OnComplete:Connect(function() tweener06:Play() end)
	tweener06.OnComplete:Connect(function()
		tweener01:Destroy()
		tweener02:Destroy()
		tweener03:Destroy()
		tweener04:Destroy()
		tweener05:Destroy()
		tweener06:Destroy()
		obj:Destroy()
	end)
	tweener01:Play()
	tweener02:Play()
end

---初始化定时显示消息事件
function C_NoticeGui:InitShowMsgEvent()
    local showMsg = function()
        if #self.allMsg < 1 and not self.bShowMsg then
            return
        end
        table.remove(self.allMsg,1)
        if #self.allMsg < 1 and self.bShowMsg then
            self.msgImg:SetActive(false)
            self.bShowMsg = false
            return
        end
        self.msgTxt.Text = self.allMsg[1]
    end
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(1,true,os.time(),showMsg,true))
end

---从boss获得奖励事件处理器
function C_NoticeGui:GetRewardFromBossEventHandler(_place)
    local imgObj = self.bossRewardNtcImg
    imgObj.Texture = ResourceManager.GetTexture('UI/Boss/0'..tostring(_place))
    imgObj.Size = Vector2(0,0)
    imgObj:SetActive(true)
    self.bossRewardNtcTweener[1]:Play()
end

--- 初始化boss奖励tween
function C_NoticeGui:InitBossRewardNtcTweener()
    local imgObj = self.bossRewardNtcImg
    local oldSize = imgObj.Size
    local tweener01 = Tween:TweenProperty(imgObj, {Size = oldSize}, 0.3, Enum.EaseCurve.BackOut)
    local tweener02 = Tween:TweenProperty(imgObj, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.BackIn)
    self.bossRewardNtcTweener[1] = tweener01
    self.bossRewardNtcTweener[2] = tweener02
    tweener01.OnComplete:Connect(function()
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(3,false,os.time(),function() tweener02:Play() end,true))
    end)
    tweener02.OnComplete:Connect(function()
        imgObj:SetActive(false)
        imgObj.Size = oldSize
    end)
end

--- 获得礼物奖励处理器
--- @param val string 钻石数量
function C_NoticeGui:GetGiftHandler(val)
    if val == '20' then
        self:ImgNoticeListener('Present1')
    elseif val == '50' then
        self:ImgNoticeListener('Present2')
    elseif val == '88' then
        self:ImgNoticeListener('Present3')
    elseif val == '100' then
        self:ImgNoticeListener('Present4')
    elseif val == '233' then
        self:ImgNoticeListener('Present5')
    end
end

--- 孵化结果提示
--- @param highestRarity int 宠物最高稀有度
function C_NoticeGui:HatchResultNtc(highestRarity)
	if highestRarity <= 2 then
		C_NoticeGui:ImgNoticeListener('Hatch' .. tostring(highestRarity))
	elseif highestRarity == 3 then
		C_NoticeGui:SpImgNoticeTweener('BornEpic')
	else
		C_NoticeGui:SpImgNoticeTweener('BornLegendary')
	end
end

--- 合成结果提示
--- @param _fuseResult int 宠物合成结果
function C_NoticeGui:FuseResultNtc(_fuseResult)
	if _fuseResult <= 1 then
		C_NoticeGui:ImgNoticeListener('MagicFuseResult_'..tostring(_fuseResult))
	else
		C_NoticeGui:SpImgNoticeTweener('Fuse'..tostring(_fuseResult))
	end
end

return C_NoticeGui