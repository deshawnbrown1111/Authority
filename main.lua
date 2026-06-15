--!optimize 2

if not scriptproto or not getgenv().scriptproto then
    return error("scriptproto missing from stack") and error("load init.lua first!")
end

__activethreadname = "main.lua"

local nonFinite = math.huge

local string_lower = string.lower
local string_format = string.format
local string_find = string.find
local string_match = string.match

local table_insert = table.insert
local table_remove = table.remove
local table_clear = table.clear

local assert = assert
local pcall = pcall

local print = print

local tick = tick

local Instance = Instance
local Instance_new = Instance.new
local Vector3 = Vector3
local Vector3_new = Vector3.new
local Enum = Enum

local ipairs = ipairs
local pairs = pairs
local next = next

local game = game
local cached = cached
local import = import
local declare = declare
local scriptproto = scriptproto
local settings = (assert("settings", "settings isn't implemented in you're enviorment!") and settings())

local sethiddenproperty = import("sethiddenproperty")
local readfile = import("readfile")
local isfile = import("isfile")

local Players = game:service("Players")
local RunService = game:service("RunService")
local workspace, Workspace = workspace or game:service("Workspace"), game:service("Workspace")

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = LocalCharacter:FindFirstChildWhichIsA("Humanoid")
local Hrp = LocalCharacter:WaitForChild("HumanoidRootPart")

local partconnection = nil
local stopconnection = false
local drop_parts = true

local resdelay = .5
local commands = 0
local lastcommand = nil

settings.Physics.AllowSleep = false
settings.Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled

local function connect(connection: RBXScriptSignal): ()
    table_insert(scriptproto.Events, connection)
end

connect(Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
    local new = Players.LocalPlayer
    if new then
        LocalPlayer = new
    end
end))

connect(LocalPlayer.CharacterAdded:Connect(function()
    local a = LocalPlayer.Character
    local b = a:FindFirstChildWhichIsA("Humanoid")
    local c = a:WaitForChild("HumanoidRootPart")
    if a then
        LocalCharacter = a
        if b then
            Humanoid = b
        end
        if c then
            Hrp = c
        end
    end
end))

local function setsimulationrad(): ()
    local current, max = 100000, 1000000
    connect(RunService.Heartbeat:Connect(function()
        sethiddenproperty(LocalPlayer, "MaximumSimulationRadius", max)
        sethiddenproperty(LocalPlayer, "SimulationRadius", current)
    end))
end

setsimulationrad()

local bodypositions = {}

local function adjustProperties(obj: Instance, props: table): ()
	for i, v in pairs(props) do
		pcall(function()
			obj[i] = v
		end)
	end
end

local function setbodyposition(obj: BasePart): ()
    local toremove = obj:FindFirstChildWhichIsA("BodyPosition")
	if toremove then pcall(function() toremove:Destroy() end) end

    local p = Instance_new("BodyPosition")

	adjustProperties(p, {
		D = 0,
		P = 10000,
		MaxForce = Vector3_new(nonFinite, nonFinite, nonFinite);
	})

    p.Parent = obj

	table_insert(bodypositions, p)
end

local function seedparts(): ()
    for _, basepart in pairs(workspace:GetDescendants()) do
        if basepart:IsA("BasePart") then
            if basepart.Anchored == false then
                if not basepart:IsDescendantOf(LocalCharacter) then
                    adjustProperties(basepart, {
                        CanCollide = false
                    })

                    setbodyposition(basepart)
                end
            end
        end
    end

    connect(workspace.DescendantAdded:Connect(function(new)
        if new:IsA("BasePart") then
            if not new:IsDescendantOf(LocalCharacter) then
                adjustProperties(new, {
                    CanCollide = false
                })

                setbodyposition(new)
            end
        end
    end))
end

local function bringparts(time: number): ()
    if drop_parts == false then
        time = nonFinite
    end

    local start = tick()
    local max = time

    local onpartconnection = function()
        if stopconnection or (tick() - start) > max then
            pcall(function()
                for i, v in next, bodypositions do
                    i:Destroy()
                end
            end)
            table_clear(bodypositions)
            if partconnection then
                partconnection:Disconnect()
                partconnection = nil
            end
            return
        end

        if Hrp then
            for i = 1, #bodypositions do
                local bp = bodypositions[i]
                if bp and bp.Parent then
                    bp.Position = Hrp.Position
                end
            end
        end
    end

    partconnection = RunService.Heartbeat:Connect(onpartconnection)
end

local patch = function(cmd: string, find: string)
    local a = string_lower(cmd)
    local b = string_find(a, "$")
    local c = (b and a)

    if c then
        local d = string_find(a, find)
        if d then
            return true
        end
    end
    return false
end

local onSpeak = function(Message: string): ()
    if lastcommand and (tick() - lastcommand) < resdelay then
        return
    end

    if patch(Message, "bring") then
        local timeArg = string_match(Message, "<(.-)>")
        if timeArg then timeArg = tonumber(timeArg) end

        seedparts()
        drop_parts = not string_find(Message, "--nodrop")
        bringparts(timeArg or 10)
        return
    end

    if patch(Message, "void") then
        seedparts()
        local max = 5
        local start = tick()
        local conn; conn = RunService.RenderStepped:Connect(function()
            if (tick() - start) > max then
                pcall(function()
                    for i = #bodypositions, 1, -1 do
                        if bodypositions[i] then
                            bodypositions[i]:Destroy()
                        end
                    end
                end)
                table_clear(bodypositions)
                if conn then
                    conn:Disconnect()
                    conn = nil
                end
                return
            end

            for i = 1, #bodypositions do
                local bp = bodypositions[i]
                if bp and bp.Parent then
                    bp.Position = Vector3_new(Hrp.Position.X, -99999, Hrp.Position.Z)
                end
            end
        end)
        return
    end
end

connect(LocalPlayer.Chatted:Connect(onSpeak))