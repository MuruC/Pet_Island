--- 客户端时间管理模块
-- @module Time manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_TimeMgr, this = {}, nil

-- 事件类
local Event = {}
-- 事件id
local eventId = 1

--- 初始化事件类
--- @param _delay float 延迟多久触发
--- @param _loop bool 是否循环
--- @param _startTime float 开始时间
--- @param _handler function 被触发的函数
function Event:Init(_delay,_loop,_startTime,_handler,_bSecond)
    self.delay = _delay
    self.loop = _loop
    self.startTime = _startTime
    self.id = eventId
    eventId = eventId + 1
    self.handler = _handler
    self.bSecond = _bSecond
end

-- 初始化
function C_TimeMgr:Init()
    --info('C_TimeMgr:Init')
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
    -- 开局秒数，单位: 秒
    self.startGameTime = os.time() + 1
end

--- Update函数
-- @param dt delta time 每帧时间
function C_TimeMgr:Update(dt)
    self.curTime = self.curTime + 0.03
    self.curSecond = os.time()
    
    -- 当事件的触发时间到了，将事件加入active event表
    for k,v in pairs(self.allEvent) do
        -- 按帧数处理事件
		if self.curTime >= v.startTime + v.delay and not v.bSecond then
			self.activeEvent[k] = v
			if v.loop == false then
				self.allEvent[k] = nil
			else
				v.startTime = self.curTime
			end
        end
        -- 按秒数处理事件
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
end

--- 初始化C_UIMgr自己的监听事件
function C_TimeMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_TimeMgr, 'C_TimeMgr', this)
end

--- 添加新的事件
--- @param _newEvent table 新事件
function C_TimeMgr:AddEvent(_newEvent)
	self.allEvent[_newEvent.id] = _newEvent
end

--- 创造新的事件
--- @param _delay float 延迟多久触发
--- @param _loop bool 是否循环
--- @param _startTime float 开始时间
--- @param _handler function 被触发的函数
function C_TimeMgr:CreateNewEvent(_delay,_loop,_startTime,_handler,_bSecond)
    local o = {}
    setmetatable(o, {__index = Event})
    o:Init(_delay,_loop,_startTime,_handler,_bSecond)
    return o
end

--- 移除事件
--- @param _id int 事件id
function C_TimeMgr:RemoveEvent(_id)
    self.allEvent[_id] = nil
end

return C_TimeMgr