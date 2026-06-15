--!optimize 2

__activethreadname = "reanimate.lua"

local nonFinite = math.huge
local table_insert = table.insert
local assert = assert
local pcall = pcall
local game = game
local cached = cached
local import = import
local declare = declare
local assert = assert
local scriptproto = scriptproto
local sethiddenproperty = import("sethiddenproperty")
local settings = assert("settings", "settings isn't implemented in you're enviorment!")

local Instance = Instance
local PhysicalProperties = PhysicalProperties

local task_wait = task.wait
local task_defer = task.defer

local Vector3 = Vector3
local VecZero = Vector3.zero

local connect = function(connection: RBXScriptSignal): ()
    table_insert(scriptproto.Events, connection)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace, Workspace = workspace, game:FindService("Workspace")

local Camera = Workspace.CurrentCamera
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local new = Workspace.CurrentCamera
    if new then
        Camera = new
    end
end))

local ReAnimate = {
    R6Enabled = true,
    NoReset = true,
    NoRagdoll = false,
}

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalHumanoid = LocalCharacter:FindFirstChildOfClass("Humanoid")
connect(Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
    local new = Players.LocalPlayer
    if new then
        LocalPlayer = new
    end
end))
connect(LocalPlayer.CharacterAdded:Connect(function()
    local new = LocalPlayer.Character
    if new then
        local newHum = new:FindFirstChildOfClass("Humanoid")
        LocalCharacter = new
        LocalHumanoid = newHum
    end
end))
connect(RunService.Heartbeat:Connect(function()
    sethiddenproperty(LocalPlayer, "SimulationRadius", nonFinite)
    pcall(function()
        setsimulationradius(0, nonFinite)
    end)
end))

local MainModel, CharacterClone
local RespawnTime = Players.RespawnTime + 0.5

local function validate_character(Character: Model): ()
    assert(Character and Character.Parent and Character.HumanoidRootPart and Character:IsA("Model"), "Character Isn't Valid")
end

settings().Physics.AllowSleep = false
settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled

function ReAnimate:Respawn(): ()
    local CameraCF = Camera.CFrame
    LocalPlayer.Character = nil
    task_wait(0)
    LocalPlayer.Character = LocalCharacter
    Camera.CFrame = CameraCF
end

function ReAnimate:MakeArchivable(Object: Instance): ()
    Object.Archivable = true
    for _, v in next, Object:GetDescendants() do
        v.Archivable = true
    end
end

function ReAnimate:AllignLimbs(serverpart: BasePart, clientpart: BasePart): ()
    serverpart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)

    local attachment_1 = Instance.new("Attachment")
    attachment_1.Position = VecZero
    attachment_1.Orientation = VecZero
    attachment_1.Parent = serverpart

    local attachment_2 = Instance.new("Attachment")
    attachment_2.Position = VecZero
    attachment_2.Orientation = VecZero
    attachment_2.Parent = clientpart

    local AlignPosition = Instance.new("AlignPosition")
    AlignPosition.MaxForce = nonFinite
    AlignPosition.MaxVelocity = nonFinite
    AlignPosition.Responsiveness = 200
    AlignPosition.RigidityEnabled = true
    AlignPosition.Attachment0 = attachment_1
    AlignPosition.Attachment1 = attachment_2
    AlignPosition.Parent = serverpart

    local AlignOrientation = Instance.new("AlignOrientation")
    AlignOrientation.MaxTorque = nonFinite
    AlignOrientation.MaxAngularVelocity = nonFinite
    AlignOrientation.Responsiveness = 200
    AlignOrientation.RigidityEnabled = false
    AlignOrientation.Attachment0 = attachment_1
    AlignOrientation.Attachment1 = attachment_2
    AlignOrientation.Parent = serverpart
end

function ReAnimate:Load(Character: Model)
    assert(Character == LocalCharacter, "Character Isn't Client")
    validate_character(Character)
    self:MakeArchivable(LocalCharacter)

    MainModel = Instance.new("Model")
    CharacterClone = LocalCharacter:Clone()

    for _, v in next, CharacterClone:GetDescendants() do
        if v:IsA("BasePart") then
            v.Transparency = 1
            v.Anchored = false
        end
    end

    CharacterClone.Name = LocalPlayer.Name
    CharacterClone.Parent = LocalCharacter

    MainModel.Parent = LocalCharacter.Parent
	LocalCharacter.Parent = MainModel

    if self.NoRagdoll == true then
        for _, v in next, LocalCharacter:GetDescendants() do
            for _1, socket in next, v:GetChildren() do
                if socket:IsA("HingeConstraint") or socket:IsA("BallSocketConstraint") then
                    socket:Destroy()
                end
            end
        end
    end

    MainModel:BreakJoints()

    for _, ragdollPart in next, MainModel:GetDescendants() do
        if ragdollPart:IsA("BasePart") then
            local clonePart = CharacterClone:FindFirstChild(ragdollPart.Name, true)
            if clonePart and clonePart:IsA("BasePart") then
                self:AllignLimbs(ragdollPart, clonePart)
            end
        end
    end

    task_wait(RespawnTime)
    self:Respawn()
end

ReAnimate:Load(LocalCharacter)