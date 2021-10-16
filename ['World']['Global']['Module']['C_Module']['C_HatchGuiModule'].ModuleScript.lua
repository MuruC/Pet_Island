--- 客户端孵化UI管理模块
-- @module hatch gui, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_HatchGui, this = {}, nil

function C_HatchGui:Init()
    this = self
    self:InitListeners()

    -- 主场景UI
    self.mainGui = localPlayer.Local.ControlGui
    -- 孵化面板
    self.hatchGui = localPlayer.Local.HatchGui
    -- 孵蛋面板
    self.hatchPnl = self.hatchGui.HatchPnl
    -- 孵蛋按钮
    self.hatchButton = self.hatchPnl.HatchBtn
    -- 五连抽孵蛋按钮
    self.hatchFiveBtn = self.hatchPnl.HatchFiveBtn
    -- 退出孵蛋面板
    self.quitHatchPnl = self.hatchPnl.Quit
    -- 某个蛋概率图片
    self.singleEggProbImg = self.hatchPnl.ProbImg
    -- 宠物概率面板
    self.petProbPnl = self.hatchGui.PetProbBg
    -- 退出宠物概率面板
    self.quitPetProbPnl = self.petProbPnl.Quit
    -- 宠物概率面板向左翻页
    --self.petProbLeftPage = self.petProbPnl.LeftBtn
    -- 宠物概率面板向右翻页
    --self.petProbRightPage = self.petProbPnl.RightBtn
    -- 继续孵蛋gui
    self.continueHatchGui = self.hatchGui.ContinueHatch
    -- 继续孵蛋按钮
    self.continueHatchBtn = self.continueHatchGui.ContinueHatchBtn
    -- 继续五连孵按钮
    self.continueHatchFiveBtn = self.continueHatchGui.HatchFiveBtn

    -- 关闭继续孵蛋界面
    self.quitContinueHatch = self.continueHatchGui.QuitBtn
    -- 宠物概率面板当前页数
    self.petProbPage = 1


    -- 全部gui
    local playerLocal = localPlayer.Local
    self.allGui = {
        playerLocal.HatchGui,playerLocal.TransGui,playerLocal.ControlGui,playerLocal.AchieveGui,playerLocal.BagGui,
        playerLocal.MergeGui,playerLocal.StoreGui
    }

    self:InitConnectBtnEvent()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_HatchGui:Update(dt)
end

--- 初始化C_HatchGui自己的监听事件
function C_HatchGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_HatchGui, 'C_HatchGui', this)
end

--- 初始绑定按钮事件
function C_HatchGui:InitConnectBtnEvent()
    -- 孵蛋
    self.hatchButton.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_01)
            C_PetMgr:HatchEgg()
        end
    )
    -- 五连抽孵蛋
    self.hatchFiveBtn.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_01)
            C_PetMgr:HatchFiveEgg()
        end
    )
    -- 关闭孵蛋界面
    self.quitHatchPnl.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_05)
            self:ShowHatchGenUi(false)
        end
    )

    -- 关闭宠物概率面板
    self.quitPetProbPnl.OnClick:Connect(
        function()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_05)
            self:CheckIfShowAllPetProbPnl(false)
        end
    )
    ---- 宠物概率面板向左翻页
    --self.petProbLeftPage.OnClick:Connect(
    --    function()
    --        if self.petProbPage > 1 then
    --            self.petProbPage = self.petProbPage - 1
    --            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_04)
    --        end
    --        for k, v in pairs(self.petProbPnl.AreaPnl:GetChildren()) do
    --            v:SetActive(false)
    --        end
    --        local areaProbName = "AreaProb" .. tostring(self.petProbPage)
    --        local areaProb = self.petProbPnl.AreaPnl:GetChild(areaProbName)
    --        if areaProb then
    --            areaProb:SetActive(true)
    --        end
    --    end
    --)
    ---- 宠物概率面板向右翻页
    --self.petProbRightPage.OnClick:Connect(
    --    function()
    --        if self.petProbPage < 5 then
    --            self.petProbPage = 1 + self.petProbPage
    --            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_04)
    --        end
    --        for k, v in pairs(self.petProbPnl.AreaPnl:GetChildren()) do
    --            v:SetActive(false)
    --        end
    --        local areaProbName = "AreaProb" .. tostring(self.petProbPage)
    --        local areaProb = self.petProbPnl.AreaPnl:GetChild(areaProbName)
    --        if areaProb then
    --            areaProb:SetActive(true)
    --        end
    --    end
    --)

    -- 继续孵化宠物
    self.continueHatchBtn.OnClick:Connect(function()
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_01)
        self.continueHatchGui:SetActive(false)
        C_PetMgr:ClearHatchTweeners()
        for k, v in pairs(localPlayer.Local.Independent.HatchPlat.Pets:GetChildren()) do
            v:Destroy()
        end
        C_PetMgr:HatchEgg()
    end)

    -- 继续五连抽
    self.continueHatchFiveBtn.OnClick:Connect(function()
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_01)
        self.continueHatchGui:SetActive(false)
        C_PetMgr:ClearHatchTweeners()
        for k, v in pairs(localPlayer.Local.Independent.HatchPlat.Pets:GetChildren()) do
            v:Destroy()
        end
        C_PetMgr:HatchFiveEgg()
    end)

    -- 不再继续孵化宠物
    self.quitContinueHatch.OnClick:Connect(function()
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_UI_05)
        C_PetMgr:ClearHatchTweeners()
        for k, v in pairs(localPlayer.Local.Independent.HatchPlat.Pets:GetChildren()) do
            v:Destroy()
        end
        self:CheckIfShowContinueHatchGui(false)
    end)
end

local constDefNormalCam = ConstDef.CameraModeEnum.Normal    ---主界面相机
local constDefIncubatorCam = ConstDef.CameraModeEnum.Incubator  ---孵化室相机

--- 显示孵化界面
--- @param _bShow boolean 是否显示
--- @param _area int 地区 
--- @param _eggId string 蛋的id
function C_HatchGui:ShowHatchGenUi(_bShow,_area,_eggId)
    local imgObj = self.singleEggProbImg
    local oldImgSize = Vector2(950,250)
    if _bShow then
        for _, v in pairs(self.allGui) do
            v:SetActive(false)
        end

        local imgPath = 'UI/prob/'..tostring(_area)..'.'
        if _eggId then
            imgPath = imgPath..tostring(C_PlayerDataMgr:GetEggInformation(_eggId).zone)
        else
            local zoneIndex = C_PlayerStatusMgr.zoneIndex
            if zoneIndex > 5 then
                zoneIndex = 5
            elseif zoneIndex < 1 then
                zoneIndex = 1
            end
            imgPath = imgPath..tostring(zoneIndex)
        end
        imgObj.Texture = ResourceManager.GetTexture(imgPath)        
        imgObj.Size = Vector2(0,0)
        self.hatchGui:SetActive(true)
        self.hatchPnl:SetActive(true)
        self.petProbPnl:SetActive(false)
        local objTweener = Tween:TweenProperty(imgObj, {Size = oldImgSize}, 0.3, Enum.EaseCurve.BackOut)
        objTweener.OnComplete:Connect(function()
            objTweener:Destroy()
        end)
        objTweener:Play()
        self:CheckIfShowHatchFiveBtn()
    else
        C_Camera:ChangeMode(constDefNormalCam)
        local objTweener = Tween:TweenProperty(imgObj, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)
        objTweener.OnComplete:Connect(function()
            C_MainGui:CheckIfShowMainGui(true)
            imgObj.Size = oldImgSize
            objTweener:Destroy()
        end)
        objTweener:Play()
    end
end

--- 检测是否显示孵化gui
--- @param _bShow boolean 是否显示:true显示 false隐藏
function C_HatchGui:CheckIfShowHatchGui(_bShow)
    if _bShow then
        for _, v in pairs(self.allGui) do
            v:SetActive(false)
        end
        self.hatchGui:SetActive(true)
    else
        self.hatchGui:SetActive(false)
    end
end

local constDefBtnEnum = ConstDef.btnEnum

--- 绑定按钮函数
--- @param _btn string 按钮
--- @param _func function 函数
function C_HatchGui:BindBtnEventCallback(_btn,_func)
    if _btn == constDefBtnEnum.hatch then
        self.hatchButton.OnClick:Connect(_func)
    elseif _btn == constDefBtnEnum.quitContinueHatch then
        self.quitContinueHatch.OnClick:Connect(_func)
    end
end

--- 按钮和函数断开连接
--- @param _btn string 按钮
--- @param _func function 函数
function C_HatchGui:DisconnectBtnEvent(_btn,_func)
    if _btn == constDefBtnEnum.hatch then
        self.hatchButton.OnClick:Disconnect(_func)
    elseif _btn == constDefBtnEnum.quitContinueHatch then
        self.quitContinueHatch.OnClick:Disconnect(_func)
    end
end

--- 显示当前场景孵化概率面板
--- @param _bShow boolean 是否显示
--- @param _area int 场景编号
function C_HatchGui:CheckIfShowAllPetProbPnl(_bShow,_area)
    if _bShow then
        for _, gui in pairs(self.allGui) do
            gui:SetActive(false)
        end
        local areaPnl = self.petProbPnl.AreaPnl
        areaPnl:GetChild('AreaProb1').Texture = ResourceManager.GetTexture('UI/prob/'..tostring(_area))
        for _, v in pairs(self.petProbPnl:GetChildren()) do
            v:SetActive(false)
        end
        self.petProbPnl:SetActive(false)
        self.hatchPnl:SetActive(false)
        local bgObj = self.petProbPnl.PetProbBg
        local oldSize = bgObj.Size
        bgObj.Size = Vector2(0,0)
        self.petProbPnl:SetActive(true)
        self.hatchGui:SetActive(true)
		bgObj:SetActive(true)
        local objTweener = Tween:TweenProperty(bgObj, {Size = oldSize}, 0.3, Enum.EaseCurve.BackOut)
        objTweener.OnComplete:Connect(function()
            for _, v in pairs(self.petProbPnl:GetChildren()) do
                v:SetActive(true)
            end
            objTweener:Destroy()
        end)
        objTweener:Play()
    else
        local bgObj = self.petProbPnl.PetProbBg
        local oldSize = bgObj.Size
        for _, v in pairs(self.petProbPnl:GetChildren()) do
            if v ~= bgObj then v:SetActive(false) end
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

--- 只退出孵蛋界面
function C_HatchGui:QuitHatchGui()
    local imgObj = self.singleEggProbImg
    local oldImgSize = imgObj.Size
    local objTweener = Tween:TweenProperty(imgObj, {Size = Vector2(0,0)}, 0.1, Enum.EaseCurve.Linear)
    objTweener.OnComplete:Connect(function()
        self.hatchPnl:SetActive(false)
        --self.continueHatchBtn:SetActive(true)
        imgObj.Size = oldImgSize
        objTweener:Destroy()
    end)
    objTweener:Play()
end

--- 检测是否显示继续孵蛋界面
--- @param _bShow boolean 是否显示
function C_HatchGui:CheckIfShowContinueHatchGui(_bShow)
    if _bShow then
        self.continueHatchGui:SetActive(true)
        self:CheckIfShowHatchFiveBtn()
    else
        self.continueHatchGui:SetActive(false)
        C_MainGui:CheckIfShowMainGui(true)
        C_Camera:ChangeMode(constDefNormalCam)
    end
end

--- 检测是否显示五连抽按钮
function C_HatchGui:CheckIfShowHatchFiveBtn()
    if #C_PetMgr.hitIncubator.eggTbl >= 5 then
        self.continueHatchFiveBtn:SetActive(true)
        self.hatchFiveBtn:SetActive(true)
    else
        self.continueHatchFiveBtn:SetActive(false)
        self.hatchFiveBtn:SetActive(false)
    end
end

return C_HatchGui