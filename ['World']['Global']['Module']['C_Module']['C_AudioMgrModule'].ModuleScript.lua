--- 客户端音效管理模块
-- @module audio, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_AudioMgr, this = {}, nil

function C_AudioMgr:Init()
    this = self
    self:InitListeners()

    ---音效文件
    self.allAudios = localPlayer.Local.Audio
    ---所有bgm
    self.allBgms = {}

    self:InitAllBgm()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_AudioMgr:Update(dt)
end

--- 初始化C_AudioMgr自己的监听事件
function C_AudioMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_AudioMgr, 'C_AudioMgr', this)
end

local constDefBgmEnum = ConstDef.bgmEnum

--- 初始化所有的bgm
function C_AudioMgr:InitAllBgm()
    for ii = 1, 7, 1 do
        self.allBgms[ii] = self.allAudios:GetChild('sound_bgm_0'..tostring(ii))
    end
end

--- 播放音效
--- @param _aud object 音效节点
function C_AudioMgr:Play(_aud)
	if not _aud then return end
	--如果正在播放，先停止
	if _aud:GetAudioState() == Enum.AudioSourceState.Playing then
		_aud:Stop()
	end
	_aud:Play()
end

--- 停止播放音效
--- @param _aud object 音效节点
function C_AudioMgr:Stop(_aud)
	if not _aud then return end
	_aud:Stop()
end

--- 先设置音效位置再播放音效
--- @param _aud object 音效节点
function C_AudioMgr:SetPosAndPlay(_aud, _pos)
	if not _aud then return end
	_aud.Position = _pos
	self:Play(_aud)
end

--- 切换BGM
--- @param _bgmIndex int bgm索引
function C_AudioMgr:ChangeBgm(_bgmIndex)
    for k, v in pairs(self.allBgms) do
        if k - 1 ~= _bgmIndex then
            self:Stop(v)
        else
            if not v:GetAudioState() ~= Enum.AudioSourceState.Playing then
                v:Play()
            end
        end
    end
end

--- 初始化进入传送门音效
function C_AudioMgr:InitTransportAudio()
    self.allAudios.sound_game_07.OnComplete:Connect(function()
        self:Play(self.allAudios.sound_bgm_07)
    end)
end

--- 播放进入传送门音效
--- @param _bgmIndex int bgm索引
function C_AudioMgr:PlayTransportAudio()
    for k, v in pairs(self.allBgms) do
        self:Stop(v)
    end
    self:Play(self.allAudios.sound_game_07)
end

--- 播放挖掘音效
function C_AudioMgr:PlayDigAudio()
    local aud = self.allAudios.sound_game_14
    if not aud then return end
	if not aud:GetAudioState() ~= Enum.AudioSourceState.Playing then
		aud:Play()
	end
end

--- 播放跑步音效
function C_AudioMgr:PlayRunAudio()
    local aud = self.allAudios.sound_game_01
    if not aud then return end
	if aud:GetAudioState() ~= Enum.AudioSourceState.Playing then
		aud:Play()
	end
end

local constDefMineType = ConstDef.mineCategoryEnum
--- 播放点击矿音效
--- @param _level int 矿等级
function C_AudioMgr:PlayChooseMineAudio(_level)
    if _level == constDefMineType.primary then
        self:Play(self.allAudios.sound_game_08)
    elseif _level == constDefMineType.middle then
        self:Play(self.allAudios.sound_game_09)
    elseif _level == constDefMineType.advanced then
        self:Play(self.allAudios.sound_game_10)
    elseif _level > constDefMineType.advanced and _level < constDefMineType.unlockMine then
        self:Play(self.allAudios.sound_game_11)
    end
end

--[[
ConstDef.bgmEnum = {
	mainIsland = 0,		--主城
	forest = 1,			--森林场景
	grave = 2,			--墓地场景
	sea = 3,			--海底场景
	desert = 4,			--荒漠场景
	boss = 5,			--世界boss
	loading = 6,		--加载过场动画
}
--]]

-- 矿的类别
--[[ConstDef.mineCategoryEnum = {
	primary = 1,		--低级普通矿
	middle = 2,			--中级普通矿
	advanced = 3,		--高级普通矿
	coinMine = 4,		--金币喷泉矿
	minorEgg = 5,		--小蛋矿
	majorEgg = 6,		--大蛋矿
	unlockMine = 7,		--限时解锁关卡
	boss = 8,			--世界boss
	guide = 9,			--新手指引矿
}
--]]
return C_AudioMgr