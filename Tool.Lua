local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = PlayerService.LocalPlayer
local Camera = Workspace.CurrentCamera

local Tool = Instance.new("Tool")
Tool.RequiresHandle = false
Tool.Name = "Telekinesis J V2"
Tool.Parent = LocalPlayer.Backpack

local CurrentSettings = {
	["CloserKey"] = Enum.KeyCode.Q,
	["FartherAwayKey"] = Enum.KeyCode.E,
	["StabilizeKey"] = Enum.KeyCode.R,
	["ThrowKey"] = Enum.KeyCode.Z
}

for SettingName, SettingValue in pairs(CurrentSettings) do
	if not ReplicatedStorage:GetAttribute(SettingName) then
		ReplicatedStorage:SetAttribute(SettingName, SettingValue)
	else
		CurrentSettings[SettingName] = ReplicatedStorage:GetAttribute(SettingName)
	end
end

local SelectedObjects = {}
local ToolEquipped = false

local function GetToolPosition()
	local Character = LocalPlayer.Character
	if not Character then return Camera.CFrame.Position end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then return Camera.CFrame.Position end

	return HumanoidRootPart.Position + Vector3.new(0, 2, 0)
end

local function SetupObject(Object)
	if not Object:IsA("BasePart") then return end

	local SelectionBox = Instance.new("SelectionBox")
	SelectionBox.Color3 = Color3.fromRGB(0, 170, 255)
	SelectionBox.LineThickness = 0.05
	SelectionBox.SurfaceTransparency = 0.7
	SelectionBox.SurfaceColor3 = Color3.fromRGB(0, 170, 255)
	SelectionBox.Adornee = Object
	SelectionBox.Parent = Object

	Object.Anchored = false

	local BodyPosition = Instance.new("BodyPosition")
	BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	BodyPosition.P = 40000
	BodyPosition.D = 700
	BodyPosition.Position = Object.Position
	BodyPosition.Parent = Object

	local BodyGyro = Instance.new("BodyGyro")
	BodyGyro.MaxTorque = Vector3.zero
	BodyGyro.P = 10000
	BodyGyro.D = 200
	BodyGyro.CFrame = CFrame.new(Object.CFrame.Position)
	BodyGyro.Parent = Object

	local ToolPos = GetToolPosition()
	local InitialDistance = (Object.Position - ToolPos).Magnitude

	return SelectionBox, BodyPosition, BodyGyro, InitialDistance
end

local function Raycast()
	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParameters.IgnoreWater = true
	RaycastParameters.RespectCanCollide = false

	local FilterInstances = {Tool}

	if LocalPlayer.Character then
		table.insert(FilterInstances, LocalPlayer.Character)
	end

	for _, Player in pairs(PlayerService:GetPlayers()) do
		if Player ~= LocalPlayer and Player.Character then
			table.insert(FilterInstances, Player.Character)
		end
	end

	RaycastParameters.FilterDescendantsInstances = FilterInstances

	local MouseLocation = UserInputService:GetMouseLocation()
	local MouseRay = Camera:ViewportPointToRay(MouseLocation.X, MouseLocation.Y)

	local RaycastResult = Workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 2048, RaycastParameters)

	return RaycastResult
end

local function FindTarget(Object)
	for I, Data in pairs(SelectedObjects) do
		if Data["Object"] == Object then
			return SelectedObjects[I], I
		end
	end
	return nil, nil
end

local function GetMouseHitPosition()
	local RaycastResult = Raycast()
	return RaycastResult and RaycastResult.Position or Camera.CFrame.Position + Camera.CFrame.LookVector * 1000
end

local function RemoveSelectedData(SelectedDataIndex)
	if not SelectedObjects[SelectedDataIndex] then return end

	local Data = SelectedObjects[SelectedDataIndex]

	if Data["SelectionBox"] then
		Data["SelectionBox"]:Destroy()
	end

	if Data["BodyPosition"] then
		Data["BodyPosition"]:Destroy()
	end

	if Data["BodyGyro"] then
		Data["BodyGyro"]:Destroy()
	end

	table.remove(SelectedObjects, SelectedDataIndex)
end

UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then return end

	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		local RaycastResult = Raycast()

		if RaycastResult and RaycastResult.Instance then
			local Target = RaycastResult.Instance

			if not Target:IsA("BasePart") then return end
			if Target.Anchored then return end
			if not ToolEquipped then return end

			local TargetData, Index = FindTarget(Target)
			if TargetData then
				RemoveSelectedData(Index)
			else
				local SelectionBox, BodyPosition, BodyGyro, InitialDistance = SetupObject(Target)
				if SelectionBox and BodyPosition and BodyGyro then
					table.insert(SelectedObjects, {
						["Object"] = Target,
						["SelectionBox"] = SelectionBox,
						["BodyPosition"] = BodyPosition,
						["BodyGyro"] = BodyGyro,
						["Distance"] = InitialDistance,
						["IsStabilized"] = false
					})
				end
			end
		end
	elseif Input.KeyCode == CurrentSettings.CloserKey then
		for _, Data in pairs(SelectedObjects) do
			Data["Distance"] = math.max(3, Data["Distance"] - 3)
		end
	elseif Input.KeyCode == CurrentSettings.FartherAwayKey then
		for _, Data in pairs(SelectedObjects) do
			Data["Distance"] = Data["Distance"] + 3
		end
	elseif Input.KeyCode == CurrentSettings.ThrowKey then
		for _, Data in pairs(SelectedObjects) do
			if Data["Object"] and Data["BodyPosition"] then
				local ThrowDirection = Camera.CFrame.LookVector
				Data["Object"].Velocity = ThrowDirection * 250
				Data["SelectionBox"]:Destroy()
				Data["BodyPosition"]:Destroy()
				Data["BodyGyro"]:Destroy()
				Data = nil
			end
		end
		SelectedObjects = {}
	elseif Input.KeyCode == CurrentSettings.StabilizeKey then
		for _, Data in pairs(SelectedObjects) do
			if Data["BodyGyro"] then
				Data["Object"].AssemblyLinearVelocity = Vector3.zero
				Data["Object"].AssemblyAngularVelocity = Vector3.zero
				Data["IsStabilized"] = not Data["IsStabilized"]
				Data["BodyGyro"].MaxTorque = Data["IsStabilized"] and 
					Vector3.new(math.huge, 0, math.huge) or Vector3.zero
			end
		end
	end
end)

local Gui = nil

local function GetKeycodeText(Keycode)
	local Success, Result = pcall(function()
		return string.char(Keycode.Value)
	end)

	if Success then
		return string.upper(Result)
	else
		return string.upper(Keycode.Name)
	end
end

local OnButton =  false

local function KeyButton(SettingName, Button, DisplayText)
	if not CurrentSettings[SettingName] then return end

	Button.Text = string.format("%s : %s",DisplayText , GetKeycodeText(CurrentSettings[SettingName]))

	Button.MouseButton1Click:Connect(function()
		if OnButton then return end
		OnButton = true
		local Input = UserInputService.InputBegan:Wait()
		local KeyCode = Input.KeyCode
		if KeyCode == Enum.KeyCode.Unknown then
			OnButton = false
			return
		end
		CurrentSettings[SettingName] = KeyCode
		ReplicatedStorage:SetAttribute(SettingName, KeyCode)
		Button.Text = string.format("%s : %s",DisplayText , GetKeycodeText(KeyCode))
		OnButton = false
	end)
end

local function CreateGui()
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not PlayerGui then return nil end

	local TelekinesisGui = Instance.new("ScreenGui")
	TelekinesisGui.DisplayOrder = 2147483647
	TelekinesisGui.IgnoreGuiInset = true
	TelekinesisGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	TelekinesisGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	TelekinesisGui.Name = "TelekinesisGui"

	local Settings = Instance.new("Frame")
	Settings.AnchorPoint = Vector2.new(0.5, 0.5)
	Settings.BackgroundColor3 = Color3.fromRGB(47, 47, 53)
	Settings.BorderColor = BrickColor.new("Really black")
	Settings.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Settings.BorderSizePixel = 0
	Settings.Position = UDim2.new(0.5, 0, 0.5, 0)
	Settings.Size = UDim2.new(0.28, 0, 0.7, 0)
	Settings.Name = "Settings"
	Settings.Visible = false

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0.05, 0)

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0.05, 0)
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local StabilizeKeySetting = Instance.new("TextButton")
	StabilizeKeySetting.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	StabilizeKeySetting.Text = ""
	StabilizeKeySetting.TextColor = BrickColor.new("Institutional white")
	StabilizeKeySetting.TextColor3 = Color3.fromRGB(255, 255, 255)
	StabilizeKeySetting.TextScaled = true
	StabilizeKeySetting.TextWrapped = true
	StabilizeKeySetting.TextXAlignment = Enum.TextXAlignment.Left
	StabilizeKeySetting.AutoButtonColor = false
	StabilizeKeySetting.AnchorPoint = Vector2.new(0.5, 0.5)
	StabilizeKeySetting.BackgroundColor3 = Color3.fromRGB(59, 59, 67)
	StabilizeKeySetting.BorderColor = BrickColor.new("Really black")
	StabilizeKeySetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
	StabilizeKeySetting.BorderSizePixel = 0
	StabilizeKeySetting.Selectable = false
	StabilizeKeySetting.Size = UDim2.new(1, 0, 0.1, 0)
	StabilizeKeySetting.Name = "StabilizeKeySetting"

	KeyButton("StabilizeKey", StabilizeKeySetting, "Stabilize Key")

	local UIPadding = Instance.new("UIPadding")
	UIPadding.PaddingBottom = UDim.new(0.03, 0)
	UIPadding.PaddingLeft = UDim.new(0.03, 0)
	UIPadding.PaddingRight = UDim.new(0.03, 0)
	UIPadding.PaddingTop = UDim.new(0.03, 0)

	local ThrowKeySetting = Instance.new("TextButton")
	ThrowKeySetting.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	ThrowKeySetting.Text = ""
	ThrowKeySetting.TextColor = BrickColor.new("Institutional white")
	ThrowKeySetting.TextColor3 = Color3.fromRGB(255, 255, 255)
	ThrowKeySetting.TextScaled = true
	ThrowKeySetting.TextWrapped = true
	ThrowKeySetting.TextXAlignment = Enum.TextXAlignment.Left
	ThrowKeySetting.AutoButtonColor = false
	ThrowKeySetting.AnchorPoint = Vector2.new(0.5, 0.5)
	ThrowKeySetting.BackgroundColor3 = Color3.fromRGB(59, 59, 67)
	ThrowKeySetting.BorderColor = BrickColor.new("Really black")
	ThrowKeySetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ThrowKeySetting.BorderSizePixel = 0
	ThrowKeySetting.LayoutOrder = 1
	ThrowKeySetting.Selectable = false
	ThrowKeySetting.Size = UDim2.new(1, 0, 0.1, 0)
	ThrowKeySetting.Name = "ThrowKeySetting"

	KeyButton("ThrowKey", ThrowKeySetting, "Throw Key")

	local UIPadding_2 = Instance.new("UIPadding")
	UIPadding_2.PaddingBottom = UDim.new(0.03, 0)
	UIPadding_2.PaddingLeft = UDim.new(0.03, 0)
	UIPadding_2.PaddingRight = UDim.new(0.03, 0)
	UIPadding_2.PaddingTop = UDim.new(0.03, 0)

	local CloserKeySetting = Instance.new("TextButton")
	CloserKeySetting.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	CloserKeySetting.Text = ""
	CloserKeySetting.TextColor = BrickColor.new("Institutional white")
	CloserKeySetting.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloserKeySetting.TextScaled = true
	CloserKeySetting.TextWrapped = true
	CloserKeySetting.TextXAlignment = Enum.TextXAlignment.Left
	CloserKeySetting.AutoButtonColor = false
	CloserKeySetting.AnchorPoint = Vector2.new(0.5, 0.5)
	CloserKeySetting.BackgroundColor3 = Color3.fromRGB(59, 59, 67)
	CloserKeySetting.BorderColor = BrickColor.new("Really black")
	CloserKeySetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CloserKeySetting.BorderSizePixel = 0
	CloserKeySetting.LayoutOrder = 2
	CloserKeySetting.Selectable = false
	CloserKeySetting.Size = UDim2.new(1, 0, 0.1, 0)
	CloserKeySetting.Name = "CloserKeySetting"

	KeyButton("CloserKey", CloserKeySetting, "Closer Key")

	local UIPadding_3 = Instance.new("UIPadding")
	UIPadding_3.PaddingBottom = UDim.new(0.03, 0)
	UIPadding_3.PaddingLeft = UDim.new(0.03, 0)
	UIPadding_3.PaddingRight = UDim.new(0.03, 0)
	UIPadding_3.PaddingTop = UDim.new(0.03, 0)

	local FartherAwayKeySetting = Instance.new("TextButton")
	FartherAwayKeySetting.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	FartherAwayKeySetting.Text = ""
	FartherAwayKeySetting.TextColor = BrickColor.new("Institutional white")
	FartherAwayKeySetting.TextColor3 = Color3.fromRGB(255, 255, 255)
	FartherAwayKeySetting.TextScaled = true
	FartherAwayKeySetting.TextWrapped = true
	FartherAwayKeySetting.TextXAlignment = Enum.TextXAlignment.Left
	FartherAwayKeySetting.AutoButtonColor = false
	FartherAwayKeySetting.AnchorPoint = Vector2.new(0.5, 0.5)
	FartherAwayKeySetting.BackgroundColor3 = Color3.fromRGB(59, 59, 67)
	FartherAwayKeySetting.BorderColor = BrickColor.new("Really black")
	FartherAwayKeySetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FartherAwayKeySetting.BorderSizePixel = 0
	FartherAwayKeySetting.LayoutOrder = 3
	FartherAwayKeySetting.Selectable = false
	FartherAwayKeySetting.Size = UDim2.new(1, 0, 0.1, 0)
	FartherAwayKeySetting.Name = "FartherAwayKeySetting"

	KeyButton("FartherAwayKey", FartherAwayKeySetting, "Farther Away Key")

	local UIPadding_4 = Instance.new("UIPadding")
	UIPadding_4.PaddingBottom = UDim.new(0.03, 0)
	UIPadding_4.PaddingLeft = UDim.new(0.03, 0)
	UIPadding_4.PaddingRight = UDim.new(0.03, 0)
	UIPadding_4.PaddingTop = UDim.new(0.03, 0)

	local SettingsButton = Instance.new("TextButton")
	SettingsButton.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	SettingsButton.Text = "Settings"
	SettingsButton.TextColor = BrickColor.new("Institutional white")
	SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SettingsButton.TextScaled = true
	SettingsButton.TextSize = 14
	SettingsButton.TextWrapped = true
	SettingsButton.AutoButtonColor = false
	SettingsButton.AnchorPoint = Vector2.new(1, 1)
	SettingsButton.BackgroundColor3 = Color3.fromRGB(47, 47, 53)
	SettingsButton.BorderColor = BrickColor.new("Really black")
	SettingsButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SettingsButton.BorderSizePixel = 0
	SettingsButton.Position = UDim2.new(0.99, 0, 0.98, 0)
	SettingsButton.Size = UDim2.new(0.1, 0, 0.1, 0)
	SettingsButton.Name = "SettingsButton"

	SettingsButton.MouseButton1Click:Connect(function()
		Settings.Visible = not Settings.Visible
	end)

	local UICorner_2 = Instance.new("UICorner")
	UICorner_2.CornerRadius = UDim.new(0.2, 0)

	TelekinesisGui.Parent = PlayerGui
	Settings.Parent = TelekinesisGui
	UICorner.Parent = Settings
	UIListLayout.Parent = Settings
	StabilizeKeySetting.Parent = Settings
	UIPadding.Parent = StabilizeKeySetting
	ThrowKeySetting.Parent = Settings
	UIPadding_2.Parent = ThrowKeySetting
	CloserKeySetting.Parent = Settings
	UIPadding_3.Parent = CloserKeySetting
	FartherAwayKeySetting.Parent = Settings
	UIPadding_4.Parent = FartherAwayKeySetting
	SettingsButton.Parent = TelekinesisGui
	UICorner_2.Parent = SettingsButton

	return TelekinesisGui
end

Tool.Equipped:Connect(function()
	for SettingName, SettingValue in pairs(CurrentSettings) do
		if not ReplicatedStorage:GetAttribute(SettingName) then
			ReplicatedStorage:SetAttribute(SettingName, SettingValue)
		else
			CurrentSettings[SettingName] = ReplicatedStorage:GetAttribute(SettingName)
		end
	end

	ToolEquipped = true

	if Gui then
		Gui:Destroy()
		Gui = nil
	end

	Gui = CreateGui()
end)

Tool.Unequipped:Connect(function()
	if Gui then
		Gui:Destroy()
		Gui = nil
	end

	ToolEquipped = false
	
	for Index = #SelectedObjects, 1, -1 do
		RemoveSelectedData(Index)
	end
end)

Tool.Destroying:Connect(function()
	if Gui then
		Gui:Destroy()
		Gui = nil
	end

	for Index = #SelectedObjects, 1, -1 do
		RemoveSelectedData(Index)
	end
end)

RunService.RenderStepped:Connect(function()
	for Index , Data in pairs(SelectedObjects) do
		if Data["Object"] and Data["BodyPosition"] then
			local MouseHitPos = GetMouseHitPosition()
			local ToolPosition = GetToolPosition()

			if not MouseHitPos or not ToolPosition then continue end

			local AimCFrame = CFrame.new(ToolPosition, MouseHitPos)
			local TargetPosition = ToolPosition + (AimCFrame.LookVector * Data["Distance"])

			Data["BodyPosition"].Position = TargetPosition
			if Data["BodyGyro"] then
				Data["BodyGyro"].CFrame = CFrame.new(AimCFrame.Position)
			end
		end
		
		if not Data["Object"] then
			RemoveSelectedData(Index)
		end
	end
end)
