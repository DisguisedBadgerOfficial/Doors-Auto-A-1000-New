-- Auto A-1000 Script developed by DisguisedBagderOfficial
-- Github https://github.com/DisguisedBadgerOfficial
-- Includes Advanced Pathfinding and Intelligent Features

if game.PlaceId ~= 6839171747 or game.ReplicatedStorage.GameData.Floor.Value ~= "Rooms" then
	game.StarterGui:SetCore("SendNotification", { Title = "Invalid Place", Text = "This script must be executed in Rooms!" })
	
	local Sound = Instance.new("Sound", game.SoundService)
	Sound.SoundId = "rbxassetid://550209561"
	Sound.Volume = 5
	Sound.PlayOnRemove = true
	Sound:Destroy()
	return
elseif workspace:FindFirstChild("PathFindPartsFolder") then
	game.StarterGui:SetCore("SendNotification", { Title = "Warning", Text = "Pathfinding parts folder already exists. If issues persist, contact geodude#2619." })
	
	local Sound = Instance.new("Sound", game.SoundService)
	Sound.SoundId = "rbxassetid://550209561"
	Sound.Volume = 5
	Sound.PlayOnRemove = true
	Sound:Destroy()
	return
end

-- Services and Variables
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local RunService = game:GetService("RunService")

local Folder = Instance.new("Folder", workspace)
Folder.Name = "PathFindPartsFolder"

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local RoomLabel = Instance.new("TextLabel", ScreenGui)
RoomLabel.Size = UDim2.new(0, 350, 0, 100)
RoomLabel.TextSize = 48
RoomLabel.TextStrokeColor3 = Color3.new(1, 1, 1)
RoomLabel.TextStrokeTransparency = 0
RoomLabel.BackgroundTransparency = 1
RoomLabel.Text = "Room: Loading..."

-- Anti-AFK
local GC = getconnections or get_signal_cons
if GC then
	for _, conn in pairs(GC(LocalPlayer.Idled)) do
		if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
	end
end

-- Handle A90
if LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules:FindFirstChild("A90") then
	LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.A90.Name = "lol"
end

-- Utility Functions
local function notify(title, text)
	game.StarterGui:SetCore("SendNotification", { Title = title, Text = text })
end

local function playSound(soundId, volume)
	local Sound = Instance.new("Sound", game.SoundService)
	Sound.SoundId = soundId
	Sound.Volume = volume or 3
	Sound.PlayOnRemove = true
	Sound:Destroy()
end

local function distance(vec1, vec2)
	return (vec1 - vec2).Magnitude
end

local function sortByDistance(objects, referencePoint)
	table.sort(objects, function(a, b)
		return distance(a.Position, referencePoint) < distance(b.Position, referencePoint)
	end)
	return objects
end

local function getLocker()
	local lockers = {}
	for _, obj in ipairs(workspace.CurrentRooms:GetDescendants()) do
		if obj.Name == "Rooms_Locker" and obj:FindFirstChild("Door") and obj:FindFirstChild("HiddenPlayer") then
			if not obj.HiddenPlayer.Value and obj.Door.Position.Y > -3 then
				table.insert(lockers, obj.Door)
			end
		end
	end
	local sortedLockers = sortByDistance(lockers, LocalPlayer.Character.HumanoidRootPart.Position)
	return sortedLockers[1]
end

local function getPath()
	local entity = workspace:FindFirstChild("A60") or workspace:FindFirstChild("A120")
	if entity and entity.Main.Position.Y > -4 then
		return getLocker()
	else
		return workspace.CurrentRooms[LatestRoom.Value].Door.Door
	end
end

-- Intelligent Pathfinding
local function computePath(destination)
	local path = PathfindingService:CreatePath({
		AgentRadius = 1,
		AgentHeight = 5,
		AgentCanJump = false,
		WaypointSpacing = 2,
		AgentMaxSlope = 45
	})
	
	local success, errorMsg = pcall(function()
		path:ComputeAsync(LocalPlayer.Character.HumanoidRootPart.Position, destination.Position)
	end)
	
	if not success then
		warn("Pathfinding failed: " .. errorMsg)
		return nil
	end
	
	if path.Status == Enum.PathStatus.Complete then
		return path:GetWaypoints()
	else
		warn("No valid path found.")
		return nil
	end
end

local function renderPath(waypoints)
	Folder:ClearAllChildren()
	for _, waypoint in ipairs(waypoints) do
		local part = Instance.new("Part", Folder)
		part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.Position = waypoint.Position
		part.Shape = "Cylinder"
		part.Rotation = Vector3.new(0, 0, 90)
		part.Material = "Neon"
		part.BrickColor = BrickColor.new("Bright green")
		part.Anchored = true
		part.CanCollide = false
	end
end

local function followPath(waypoints)
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	
	for _, waypoint in ipairs(waypoints) do
		if char.HumanoidRootPart.Anchored == false then
			char.Humanoid:MoveTo(waypoint.Position)
			char.Humanoid.MoveToFinished:Wait()
		end
	end
end

-- Room Update Listener
LatestRoom:GetPropertyChangedSignal("Value"):Connect(function()
	RoomLabel.Text = "Room: " .. math.clamp(LatestRoom.Value, 1, 1000)
	if LatestRoom.Value == 1000 then
		LocalPlayer.DevComputerMovementMode = Enum.DevComputerMovementMode.KeyboardMouse
		Folder:ClearAllChildren()
		playSound("rbxassetid://4590662766", 3)
		notify("youtube.com/geoduude", "Thank you for using my script!")
		return
	end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	
	char.HumanoidRootPart.CanCollide = false
	char.Collision.CanCollide = false
	char.Collision.Size = Vector3.new(8, char.Collision.Size.Y, 8)
	char.Humanoid.WalkSpeed = 25
	
	local destination = getPath()
	if destination then
		local waypoints = computePath(destination)
		if waypoints then
			renderPath(waypoints)
			followPath(waypoints)
		end
	end
end)
