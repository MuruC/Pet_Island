--- 游戏服务器主逻辑
-- @module Game Manager, Server-side
-- @copyright Lilith Games, Avatar Team
-- @author Yuancheng Zhang
local GameMgr, this =
    {
        isRun = false,
        baseTime = 0, -- 游戏开始的时间戳
        dt = 0, -- delta time 每帧时间
        tt = 0 -- total time 游戏总时间
    },
    nil

local now = os.time -- 用于lua优化

--- 初始化
function GameMgr:Init()
    --info('GameMgr:Init')
    this = self
    self.baseTime = now()
    self:InitListeners()

    S_TimeMgr:Init()
    GameCsv:Init()
    S_MineMgr:Init()
    S_Store:Init()
    S_PlayerStatusMgr:Init()
    S_PlayerDataMgr:Init()
    S_PetMgr:Init()
    S_RequestMgr:Init()
    S_Achieve:Init()
    S_GiftMgr:Init()

    world.OnPlayerAdded:Connect(function(_player) self:PlayerAdded(_player) end)
	world.OnPlayerRemoved:Connect(function(_player) self:PlayerRemoved(_player) end)
end

--- 初始化Game Manager自己的监听事件
function GameMgr:InitListeners()
    EventUtil.LinkConnects(world.S_Event, GameMgr, 'GameMgr', this)
end

--- Update函数
-- @param dt delta time 每帧时间
function GameMgr:Update(dt, tt)
    S_MineMgr:Update(dt)
    S_TimeMgr:Update(dt)
    S_Store:Update(dt)
    S_PlayerDataMgr:Update(dt)
end

--- 开始Update
function GameMgr:StartUpdate()
    --info('GameMgr:StartUpdate')
    if self.isRun then
        warn('GameMgr:StartUpdate 正在运行')
        return
    end

    self.isRun = true

    local prevTime, nowTime = now(), nil -- two timestamps
    while (self.isRun and wait()) do
        nowTime = now()
        self.dt = nowTime - prevTime
        self.tt = nowTime - self.baseTime
        self:Update(self.dt, self.tt)
        prevTime = nowTime
    end
end

--- 停止Update
function GameMgr:StopUpdate()
    --info('GameMgr:StopUpdate')
    self.isRun = false
end

--- 玩家加入处理
-- @param playerInstance _player 玩家对象
function GameMgr:PlayerAdded(_player)
	wait()
    print("玩家加入：",_player)
    S_PlayerStatusMgr:GeneratePlayerIndex(_player.UserId)
    S_PlayerDataMgr:LoadGameDataAsync(_player.UserId)  --读取数据
    S_TimeMgr:AddPlayerEnterTime(_player.UserId)
end

--- 玩家退出处理
-- @param playerInstance _player 玩家对象
function GameMgr:PlayerRemoved(_player)
    print("玩家退出",_player)
    S_MineMgr:PlayerLeaveGameHandler(_player.UserId)
    S_PlayerDataMgr:SaveGameDataAsync(_player.UserId)
    S_PlayerStatusMgr:HidePlayerIsland(_player.UserId)
end

return GameMgr
