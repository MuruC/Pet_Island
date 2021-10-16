--- 客户端相机管理模块
-- @module Camara, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_Camera, this = {}, nil

function C_Camera:Init()
    this = self
    self:InitListeners()
    self.config = {}
    local camFolder = localPlayer.Local.Independent
    self.gameCam = camFolder.GameCam
    self.hatchCam = camFolder.HatchCam
    self.incubatorCam = camFolder.IncubatorCam
    self.fuseCam = camFolder.FuseCam
    self.fuseRoomCam = camFolder.FuseRoomCam
    self.islandAnimCam = camFolder.IslandAnimCam

    self.allCams = {
        self.gameCam,self.hatchCam,self.incubatorCam,self.fuseCam,self.fuseRoomCam,self.islandAnimCam
    }

    ---孵蛋相机动画
    self.hatchAnimCamTweener = nil
    ---岛屿浮起相机动画
    self.islandAnimCamTweener = nil

    self:InitCamTweener()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_Camera:Update(dt)
end

--- 切换相机
--- @param _camMode int 相机模式 ConstDef.CameraModeEnum
--- @param _area int 场景
function C_Camera:ChangeMode(_camMode,_area)
    for k, cam in pairs(self.allCams) do
        if k ~= _camMode then
            cam:SetActive(false)
        else
            local camtypeConfig = self.config[_camMode]
            if camtypeConfig and camtypeConfig[_area] then
                cam.Position = camtypeConfig[_area].Pos
                cam.Rotation = camtypeConfig[_area].Rot
            end
            cam:SetActive(true)
            world.CurrentCamera = cam
        end
    end
    print('world.CurrentCamera: ', world.CurrentCamera)
end

--- 初始化C_HatchGui自己的监听事件
function C_Camera:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_Camera, 'C_Camera', this)
end

--- 初始化相机表
--- @param _index int 玩家编号
function C_Camera:SetCamConfig(_index)
    self.config = PlayerCsv.Cam[_index]
end

--- 初始化孵蛋相机
function C_Camera:ResetHatchCam()
    self.hatchCam.Position = Vector3(478.724, 33.2092, -367.636)
    self.hatchCam.Rotation = EulerDegree(322.5, 90, 0)
end

--- 孵蛋相机动画
function C_Camera:HatchCamTween()
    self.hatchAnimCamTweener:Play()
end

--- 岛屿浮起相机动画
function C_Camera:IslandAnimCamTween()
    self.islandAnimCamTweener:Play()
end

--- 初始化相机动画
function C_Camera:InitCamTweener()
    self.hatchAnimCamTweener = Tween:TweenProperty(self.hatchCam, 
                                                  {Position = Vector3(478.5, 32.7092, -367.636), 
                                                   Rotation = EulerDegree(360,90,0)}, 0.4, Enum.EaseCurve.Linear)
    self.islandAnimCamTweener = Tween:ShakeProperty(self.islandAnimCam, {"Position","Rotation"}, 3, 0.01 * Enum.EaseCurve.SinInOut)
end

--- 判断当前相机是否为普通相机
function C_Camera:CheckIfWorldCurCamIsNormalCam()
    if world.CurrentCamera == self.gameCam then
        return true
    end
    return false
end

function C_Camera:TestIslandAnimCamTween()
    Input.OnKeyDown:Connect(function()
        if Input.GetPressKeyData(Enum.KeyCode.E) == Enum.KeyState.KeyStatePress then
            self:ChangeMode(6)
            self:IslandAnimCamTween()
        end
    end)
end


return C_Camera