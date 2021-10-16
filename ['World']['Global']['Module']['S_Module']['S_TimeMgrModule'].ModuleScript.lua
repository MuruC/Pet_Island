--- 服务端时间管理器模块
-- @module Module Time Manager
-- @copyright Lilith Games, Avatar Team
-- @author Muru Chen
local S_TimeMgr = {}

-- 事件类
local Event = {}
-- 事件id
local eventId = 1

--- 初始化事件类
--- @param float _delay 延迟多久触发
--- @param bool _loop 是否循环
--- @param float _startTime 开始时间
--- @param function _handler 被触发的函数
--- @param bool _bSecond 是否按照秒数计时
function Event:Init(_delay,_loop,_startTime,_handler,_bSecond)
    self.delay = _delay
    self.loop = _loop
    self.startTime = _startTime
    self.handler = _handler
    self.bSecond = _bSecond

    self.id = eventId
    eventId = eventId + 1
end


-- 初始化S_TimeMgr
function S_TimeMgr:Init()
    --info('S_TimeMgr:Init')
    this = self
    self:InitListeners()

    -- 所有待触发的事件
    self.allEvent = {}
    -- 所有正在触发的事件
    self.activeEvent = {}
    -- 当前帧数，单位：秒
    self.curTime = 0
    -- 当前秒数，单位：秒
    self.curSecond = os.time()
    
    ---玩家进来的时间
    self.playerEnterTimeTbl = {}
end

-- Update函数
function S_TimeMgr:Update(dt)
    self.curTime = self.curTime + 0.03
    self.curSecond = os.time()

    -- 当事件的触发时间到了，将事件加入active event表
    for k,v in pairs(self.allEvent) do
        -- 按照帧数处理
		if self.curTime >= v.startTime + v.delay and not v.bSecond then
			self.activeEvent[k] = v
			if v.loop == false then
				self.allEvent[k] = nil
			else
				v.startTime = self.curTime
			end
        end
        -- 按照秒数触发
        if self.curSecond >= v.startTime + v.delay and v.bSecond then
            self.activeEvent[k] = v
			if v.loop == false then
				self.allEvent[k] = nil
			else
				v.startTime = self.curSecond
			end
        end
	end  
	
	for k,v in pairs(self.activeEvent) do
		v.handler()
		self.activeEvent[k] = nil
    end
    
    self:CheckPlayerEnterTimeEveryMin()
end

--- 初始化S_MineMgr自己的监听事件
function S_TimeMgr:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_TimeMgr, 'S_TimeMgr', this)
end

--- 创造新的事件
--- @param _delay float 延迟多久触发
--- @param _loop bool 是否循环
--- @param _startTime float 开始时间
--- @param _handler function 被触发的函数
--- @param _bSecond bool 是否按照秒数计时
function S_TimeMgr:CreateNewEvent(_delay,_loop,_startTime,_handler,_bSecond)
    local o = {}
    setmetatable(o,{__index = Event})
    o:Init(_delay,_loop,_startTime,_handler,_bSecond)
    return o
end

--- 将事件添加到allEvent表里
--- @param _newEvent table 新事件
function S_TimeMgr:AddEvent(_newEvent)
    self.allEvent[_newEvent.id] = _newEvent
end

--- 将事件从allEvent表里删除
--- @param id number 事件id
function S_TimeMgr:RemoveEvent(id)
    self.allEvent[id] = nil
end

--- 添加玩家进入游戏时间
--- @param _userId string 玩家的UserId
function S_TimeMgr:AddPlayerEnterTime(_userId)
    self.playerEnterTimeTbl[_userId] = os.time()
end

local constDefPlayTime = ConstDef.achieveCategoryEnum.playTime  ---玩家游玩时间枚举
--- 每分钟增加玩家游戏时长
function S_TimeMgr:CheckPlayerEnterTimeEveryMin()
    for userId, v in pairs(self.playerEnterTimeTbl) do
        if os.time() - v >= 60 then
            if not world:GetPlayerByUserId(userId) then
                self.playerEnterTimeTbl[userId] = nil
            else
                self.playerEnterTimeTbl[userId] = os.time()
                S_Achieve:PlayerChangeAchieveVal(userId,constDefPlayTime,1)
            end    
        end
    end
end

return S_TimeMgr
