--- 客户端过场gui管理模块
-- @module loading gui, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_LoadGui, this = {}, nil

function C_LoadGui:Init()
    this = self
    self:InitListeners()

    self.loadGui = localPlayer.Local.LoadingGui
    --- 是否显示过场界面
    self.bShowLoading = false
    --- 过场图片
    self.loadingImgs = self.loadGui.LoadingImgs:GetChildren()
    --- 过场图片数量
    self.loadingImgNum = #self.loadingImgs
    --- 游戏开始前过场背景
    self.mainLoadingBg = self.loadGui.MainLoading
    --- 游戏开场过场界面动画
    self.mainLoadingTweener = {}
    --- 显示中的过场图
    self.showingImg = nil
    --- 当前时间
    self.curTime = 0
    self:InitLoadingTweener()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_LoadGui:Update(dt)
    if self.bShowLoading and self.showingImg then
        self.curTime = self.curTime + 1
        local progressBar01 = self.showingImg.progressBar1
        local progressBar02 = progressBar01.progressBar2
        if self.curTime % 3 == 0 then
            if progressBar02.ActiveSelf then
                progressBar02:SetActive(false)
            else
                progressBar02:SetActive(true)
            end
        end
    end
end

--- 初始化C_LoadGui自己的监听事件
function C_LoadGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_LoadGui, 'C_LoadGui', this)
end

function C_LoadGui:InitLoadingTweener()
    local obj = self.mainLoadingBg.Title
    local objTweener01 = Tween:TweenProperty(obj, {Angle = 0}, 0.8, Enum.EaseCurve.BackInOut)
	local objTweener02 = Tween:TweenProperty(obj, {Angle = 20}, 0.8, Enum.EaseCurve.BackInOut)
    objTweener01.OnComplete:Connect(function()
		objTweener02:Play()
	end)
	objTweener02.OnComplete:Connect(function()
	    objTweener01:Play()
	end)
    objTweener01:Play()
    self.mainLoadingTweener = {objTweener01,objTweener02}
    self.showingImg = self.mainLoadingBg
    self.bShowLoading = true
end

--- 停止游戏开始前的过场动画
function C_LoadGui:StopMainLoadingTweener()
    self.bShowLoading = false
    self.loadGui:SetActive(false)
    self.mainLoadingBg:SetActive(false)
    self.loadGui.LoadingImgs:SetActive(true)
    for k, v in pairs(self.mainLoadingTweener) do
        if v.Destroy then
            v:Destroy()
        end
    end
end

--- 显示传送门过场
function C_LoadGui:ShowTransportLoading()
    local imgIndex = math.random(1,self.loadingImgNum)
    local img = self.loadingImgs[imgIndex]
    self.loadGui:SetActive(true)
    img:SetActive(true)
    self.showingImg = img
    self.bShowLoading = true
end

--- 隐藏传送门过场
function C_LoadGui:HideTransportLoading()
    self.loadGui:SetActive(false)
    self.showingImg:SetActive(false)
    self.bShowLoading = false
end

--- 进入传送门
--- @param _aud int 音效编号
function C_LoadGui:EnterTransportEvent(_aud)
    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_07)
    self:ShowTransportLoading()
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(1,false,os.time(),
                       function() C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_07) end,
    true))
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(4,false,os.time(),
                       function() self:HideTransportLoading() 
                                  C_AudioMgr:ChangeBgm(_aud) end,
    true))
end


return C_LoadGui