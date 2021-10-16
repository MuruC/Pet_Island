--- 客户端挖矿UI管理模块
-- @module mine ui, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_MineGui, this = {}, nil

--- 进度条类
local MineProgressBar = {}

--- 初始化进度条类
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _level int 矿种类
--- @param _posIndex int 位置索引
--- @param _obj Object 进度条类物体
function MineProgressBar:Init(_area,_zone,_level,_posIndex,_obj)
    self.area = _area
    self.zone = _zone
    self.level = _level
    self.posIndex = _posIndex
    self.obj = _obj
end

function C_MineGui:Init()
    this = self
    self:InitListeners()

    --所有进度条名
    self.allMineProgressBarName = {}
    ---储存进度条的table
    self.allProgressBarTbl = {}

    self:InitMineArchetypeName()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_MineGui:Update(dt)
    self:UpdateUnlockMineRemainTime()
end

--- 创建新的进度条
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _level int 矿种类
--- @param _posIndex int 位置索引
--- @param _obj Object 进度条类物体
local function CreateMineProgressBar(_area,_zone,_level,_posIndex,_obj)
    local o = {}
    setmetatable(o, {__index = MineProgressBar})
    o:Init(_area,_zone,_level,_posIndex,_obj)
    return o
end

--- 初始化C_MineGui自己的监听事件
function C_MineGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_MineGui, 'C_MineGui', this)
end

--- 储存进度条Archetype名
function C_MineGui:InitMineArchetypeName()
    for ii = 4, 1, -1 do
        local name = 'ProgressBar_Area' .. tostring(ii)
        self.allMineProgressBarName[ii] = name
    end
end

local constDefMineType = ConstDef.mineCategoryEnum

--- 增加进度条
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _level int 矿种类
--- @param _posIndex int 位置索引
function C_MineGui:AddNewMineProgressBar(_area,_zone,_level,_posIndex)
    -- 确定之前没有进度条
    local bars = self.allMineProgressBarName
    for ii = #bars, 1, -1 do
        if bars[ii].area == _area and bars[ii].zone == _zone and bars[ii].posIndex == _posIndex then
            return
        end
    end
    local barName = self.allMineProgressBarName[_area]
    local pos
    local mine
    local mineName
    if _level < constDefMineType.unlockMine then
        local posTbl = C_MineMgr.allMinePosTbl['a' .. tostring(_area) .. 'z' .. tostring(_zone)][_posIndex]
        pos = Vector3(posTbl.x,posTbl.y + 1,posTbl.z)
    elseif _level == constDefMineType.unlockMine then
		mineName = 'a'..tostring(_area)..'z5'
		mine = localPlayer.Local.Independent.Mine:GetChild(mineName)
        local minePos = mine:GetChild('mine').Position
        pos = Vector3(minePos.x,minePos.y,minePos.z)
    elseif _level == constDefMineType.guide then
        mine = localPlayer.Local.Independent.Guide.GuideMine
        pos = Vector3(-1514.2, 0, -75.7788)
    elseif _level == constDefMineType.boss then
        return
    end
    local obj
    local mineInfo = PlayerCsv.MineProperty[_area][_zone][_level]
    local newBar = CreateMineProgressBar(_area,_zone,_level,_posIndex,obj)
    if _level < constDefMineType.unlockMine then
        obj = world:CreateInstance(barName,barName,localPlayer.Local.Independent,pos)
		obj.Bg.TotalProgressTxt.Text = ShowAbbreviationNum(mineInfo['TotalProgress'])
        obj.MineNameTxt.Text = mineInfo['MineName']
        obj.Bg.CurProgressTxt.Text = '0'
    elseif _level == constDefMineType.unlockMine then
        obj = mine.Gui
        obj.RemainProgress.Text = ShowAbbreviationNum(mine.totalProgress.Value)
        local totalTime = 60
        obj.RemainTime.Text = tostring(totalTime)
        obj.totalTime.Value = totalTime
        obj.startTime.Value = os.time()
        C_NoticeGui:ShowUnlockMineNtc()
    elseif _level == constDefMineType.guide then
        obj = world:CreateInstance(barName,barName,localPlayer.Local.Independent,pos)
        mineInfo = PlayerCsv.MineProperty[_area][_zone][1]
        obj.Bg.TotalProgressTxt.Text = ShowAbbreviationNum(mineInfo['TotalProgress'])
        obj.MineNameTxt.Text = mineInfo['MineName']
        obj.Bg.CurProgressTxt.Text = '0'
	end
    newBar.obj = obj
    table.insert(self.allProgressBarTbl,newBar)
end

--- 移除进度条
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _posIndex int 位置索引
function C_MineGui:RemoveMineProgressBar(_area,_zone,_posIndex)
    local bars = self.allProgressBarTbl
	printTable(bars)
    for ii = #bars, 1, -1 do
        if bars[ii].area == _area and bars[ii].zone == _zone and bars[ii].posIndex == _posIndex then
            if bars[ii].obj then
                bars[ii].obj:Destroy()
            end
            table.remove(bars,ii)
        end
    end
end

--- 移除所有进度条
function C_MineGui:RemoveAllProgressBars()
----****************技术债：这里有多个obj******************----
    for k, v in pairs(self.allProgressBarTbl) do
        v.obj:Destroy()
        self.allProgressBarTbl[k] = nil
    end
end

local constDefLevelMinePosIndex = ConstDef.LEVEL_MINE_POS_INDEX --- 关卡矿的posIndex
local constDefGuideMinePosIndex = ConstDef.GUIDE_MINE_POS_INDEX --- 新手矿的posIndex

--- 改变进度条
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _posIndex int 位置索引
--- @param _result int 结果
function C_MineGui:ChangeMineProgressBar(_result,_area,_zone,_posIndex)
    local bars = self.allProgressBarTbl
    for ii = #bars, 1, -1 do
        if bars[ii].area == _area and bars[ii].zone == _zone and bars[ii].posIndex == _posIndex then
            local barObj = bars[ii].obj
            if _posIndex ~= constDefLevelMinePosIndex then
                local barBg = barObj.Bg
                barBg.progress.FillAmount = _result / 10
                -- 计算当前进度
                local totalProgress
                if _posIndex == constDefGuideMinePosIndex then
                    totalProgress = PlayerCsv.MineProperty[1][1][1]['TotalProgress']
                else
                    totalProgress = PlayerCsv.MineProperty[_area][_zone][bars[ii].level]['TotalProgress']
                end

                local proportion = TStringNumDiv(totalProgress, tostring(10))
                local curProgress = TStringNumMul(proportion, tostring(_result))
                barBg.CurProgressTxt.Text = ShowAbbreviationNum(curProgress)
            else
                local totalProgress = PlayerCsv.CheckpointData[_area][5]['ChallengeData']
                local proportion = TStringNumDiv(totalProgress, tostring(10))
                local curProgress = TStringNumMul(proportion, tostring(_result))
                barObj.RemainProgress.Text = TStringNumSub(totalProgress, curProgress)
            end
        end
    end
end

--- 重置解锁关卡进度
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _posIndex int 坐标
function C_MineGui:ResetUnlockMineProgress(_area,_zone,_posIndex)
    local bars = self.allProgressBarTbl
    for ii = #bars, 1, -1 do
        if bars[ii].area == _area and bars[ii].zone == _zone and bars[ii].posIndex == _posIndex then
            local barObj = bars[ii].obj
            barObj.RemainProgress.Text = ShowAbbreviationNum(PlayerCsv.CheckpointData[_area][5]['ChallengeData']) 
            barObj.RemainTime.Text = ''
            table.remove(bars,ii)
        end
    end
end

--- 更新解锁关卡剩余时间
function C_MineGui:UpdateUnlockMineRemainTime()
    local bars = self.allProgressBarTbl
    for ii = #bars, 1, -1 do
        if bars[ii].level == constDefMineType.unlockMine then
            local obj = bars[ii].obj
            if not obj then
                return
            end
            obj.RemainTime.Text = tostring(obj.totalTime.Value - os.difftime(os.time(),obj.startTime.Value))
        end
    end
end

return C_MineGui