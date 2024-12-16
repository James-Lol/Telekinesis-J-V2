local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = PlayerService.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera

local Tool = Instance.new("Tool")
Tool.RequiresHandle = false
Tool.Name = "Telekinesis J V2"
Tool.Parent = LocalPlayer.Backpack

local CurrentSettings = {
	["CloserKey"] = Enum.KeyCode.Q,
	["FartherAwayKey"] = Enum.KeyCode.E,
	["RotateKey"] = Enum.KeyCode.R,
	["ThrowKey"] = Enum.KeyCode.Z,
	["SelectType"] = 1,
}

local MinDistance = 3
local MaxForce = Vector3.new(math.huge, math.huge, math.huge)
local SelectionColor = Color3.fromRGB(0, 170, 255)

local SelectedObject = nil
local IsMouseDown = false
local GrabDistance = nil
local IsScriptActive = true
local IsObjectSelected = false

for SettingName, SettingValue in pairs(CurrentSettings) do
	if not ReplicatedStorage:GetAttribute(SettingName) then
		ReplicatedStorage:SetAttribute(SettingName, SettingValue)
	else
		CurrentSettings[SettingName] = ReplicatedStorage:GetAttribute(SettingName)
	end
end

local BodyPosition = Instance.new("BodyPosition")
BodyPosition.MaxForce = MaxForce

local SelectionBox = Instance.new("SelectionBox")
SelectionBox.Color3 = SelectionColor
SelectionBox.LineThickness = 0.05
SelectionBox.SurfaceTransparency = 0.7
SelectionBox.SurfaceColor3 = SelectionColor

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.IgnoreWater = true
RaycastParams.RespectCanCollide = false
RaycastParams.FilterDescendantsInstances = {Tool}

local function PerformRaycast()
	if LocalPlayer.Character then
		RaycastParams.FilterDescendantsInstances = {Tool, LocalPlayer.Character}
	else
		RaycastParams.FilterDescendantsInstances = {Tool}
	end

	local MouseLocation = UserInputService:GetMouseLocation()
	local CameraRay = Camera:ViewportPointToRay(MouseLocation.X, MouseLocation.Y)
	local RaycastResult = workspace:Raycast(CameraRay.Origin, CameraRay.Direction * 2048, RaycastParams)
	return RaycastResult
end

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

	local RotateKeySetting = Instance.new("TextButton")
	RotateKeySetting.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	RotateKeySetting.Text = ""
	RotateKeySetting.TextColor = BrickColor.new("Institutional white")
	RotateKeySetting.TextColor3 = Color3.fromRGB(255, 255, 255)
	RotateKeySetting.TextScaled = true
	RotateKeySetting.TextWrapped = true
	RotateKeySetting.TextXAlignment = Enum.TextXAlignment.Left
	RotateKeySetting.AutoButtonColor = false
	RotateKeySetting.AnchorPoint = Vector2.new(0.5, 0.5)
	RotateKeySetting.BackgroundColor3 = Color3.fromRGB(59, 59, 67)
	RotateKeySetting.BorderColor = BrickColor.new("Really black")
	RotateKeySetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
	RotateKeySetting.BorderSizePixel = 0
	RotateKeySetting.Selectable = false
	RotateKeySetting.Size = UDim2.new(1, 0, 0.1, 0)
	RotateKeySetting.Name = "RotateKeySetting"

	KeyButton("RotateKey", RotateKeySetting, "Rotate Key")

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

	local SelectTypeSetting = Instance.new("TextButton")
	SelectTypeSetting.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	SelectTypeSetting.Text = "Select Type : Hold"
	SelectTypeSetting.TextColor = BrickColor.new("Institutional white")
	SelectTypeSetting.TextColor3 = Color3.fromRGB(255, 255, 255)
	SelectTypeSetting.TextScaled = true
	SelectTypeSetting.TextWrapped = true
	SelectTypeSetting.TextXAlignment = Enum.TextXAlignment.Left
	SelectTypeSetting.AutoButtonColor = false
	SelectTypeSetting.AnchorPoint = Vector2.new(0.5, 0.5)
	SelectTypeSetting.BackgroundColor3 = Color3.fromRGB(59, 59, 67)
	SelectTypeSetting.BorderColor = BrickColor.new("Really black")
	SelectTypeSetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SelectTypeSetting.BorderSizePixel = 0
	SelectTypeSetting.LayoutOrder = 4
	SelectTypeSetting.Selectable = false
	SelectTypeSetting.Size = UDim2.new(1, 0, 0.1, 0)
	SelectTypeSetting.Name = "SelectTypeSetting"

	local UIPadding_5 = Instance.new("UIPadding")
	UIPadding_5.PaddingBottom = UDim.new(0.03, 0)
	UIPadding_5.PaddingLeft = UDim.new(0.03, 0)
	UIPadding_5.PaddingRight = UDim.new(0.03, 0)
	UIPadding_5.PaddingTop = UDim.new(0.03, 0)

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

	local PickUpButton = Instance.new("TextButton")
	PickUpButton.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	PickUpButton.Text = "Pick Up"
	PickUpButton.TextColor = BrickColor.new("Institutional white")
	PickUpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	PickUpButton.TextScaled = true
	PickUpButton.TextSize = 14
	PickUpButton.TextWrapped = true
	PickUpButton.AutoButtonColor = false
	PickUpButton.AnchorPoint = Vector2.new(1, 1)
	PickUpButton.BackgroundColor3 = Color3.fromRGB(47, 47, 53)
	PickUpButton.BorderColor = BrickColor.new("Really black")
	PickUpButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PickUpButton.BorderSizePixel = 0
	PickUpButton.Position = UDim2.new(0.88, 0, 0.98, 0)
	PickUpButton.Size = UDim2.new(0.22, 0, 0.08, 0)
	PickUpButton.Name = "PickUpButton"
	
	PickUpButton.Visible = false
	
	SelectTypeSetting.MouseButton1Click:Connect(function()
		if CurrentSettings.SelectType == 1 then
			CurrentSettings.SelectType = 2
			ReplicatedStorage:SetAttribute("SelectType", 2)
			PickUpButton.Visible = false
			SelectTypeSetting.Text = "Select Type : Click Select / Unselect"
		elseif CurrentSettings.SelectType == 2 then
			CurrentSettings.SelectType = 3
			ReplicatedStorage:SetAttribute("SelectType", 3)
			PickUpButton.Visible = true
			SelectTypeSetting.Text = "Select Type : Button"
		elseif CurrentSettings.SelectType == 3 then
			CurrentSettings.SelectType = 1
			ReplicatedStorage:SetAttribute("SelectType", 1)
			PickUpButton.Visible = false
			SelectTypeSetting.Text = "Select Type : Hold"
		end
	end)

	local UICorner_3 = Instance.new("UICorner")
	UICorner_3.CornerRadius = UDim.new(0.2, 0)

	TelekinesisGui.Parent = PlayerGui
	Settings.Parent = TelekinesisGui
	UICorner.Parent = Settings
	UIListLayout.Parent = Settings
	RotateKeySetting.Parent = Settings
	UIPadding.Parent = RotateKeySetting
	ThrowKeySetting.Parent = Settings
	UIPadding_2.Parent = ThrowKeySetting
	CloserKeySetting.Parent = Settings
	UIPadding_3.Parent = CloserKeySetting
	FartherAwayKeySetting.Parent = Settings
	UIPadding_4.Parent = FartherAwayKeySetting
	SelectTypeSetting.Parent = Settings
	UIPadding_5.Parent = SelectTypeSetting
	SettingsButton.Parent = TelekinesisGui
	UICorner_2.Parent = SettingsButton
	PickUpButton.Parent = TelekinesisGui
	UICorner_3.Parent = PickUpButton

	return TelekinesisGui
end

local function GetMouseHitPosition()
	local RaycastResult = PerformRaycast()
	return RaycastResult and RaycastResult.Position or Camera.CFrame.Position + Camera.CFrame.LookVector * 1000
end

local function GetMouseTarget()
	local RaycastResult = PerformRaycast()
	return RaycastResult and RaycastResult.Instance or nil
end

local function UpdateSelectionHighlight(Object)
	if Object then
		SelectionBox.Adornee = Object
		SelectionBox.Parent = Object
	else
		SelectionBox.Adornee = nil
		SelectionBox.Parent = nil
	end
end

local function RemoveBodyGyro(object)
	if object then
		for _, Child in ipairs(object:GetChildren()) do
			if Child:IsA("BodyGyro") then
				Child:Destroy()
			end
		end
	end
end

local PendingObject = nil
local TextButton = nil

local function CleanupObject()
	if SelectedObject then
		BodyPosition.Parent = nil
		RemoveBodyGyro(SelectedObject)
		UpdateSelectionHighlight(nil)
		SelectedObject = nil
		IsObjectSelected = false
		PendingObject = nil
		if TextButton then
			TextButton.Text = "Pick Up"
		end
	end
end

local function GetToolPosition()
	local Character = LocalPlayer.Character

	if Character then
		local ToolCFrame = Character:GetPivot() * CFrame.new(0, 1, 0)
		return ToolCFrame.Position
	end

	return Vector3.new(0,0,0)
end

local function HandleObjectMovement()
	if not SelectedObject or not SelectedObject.Parent then return end

	local MouseHitPos = GetMouseHitPosition()
	local ToolPosition = GetToolPosition()
	local AimCFrame = CFrame.new(ToolPosition, MouseHitPos)

	BodyPosition.Parent = SelectedObject
	BodyPosition.Position = ToolPosition + AimCFrame.LookVector * GrabDistance
end

local function HandleSelection()
	if CurrentSettings.SelectType == 1 then
		if IsMouseDown and not SelectedObject then
			local HitObject = GetMouseTarget()
			if HitObject and not HitObject.Anchored then
				SelectedObject = HitObject
				GrabDistance = (SelectedObject.Position - Camera.CFrame.Position).Magnitude
				UpdateSelectionHighlight(SelectedObject)
			end
		elseif not IsMouseDown and SelectedObject then
			CleanupObject()
		end
	elseif CurrentSettings.SelectType == 2 then
		if not IsMouseDown then return end

		if not IsObjectSelected then
			local HitObject = GetMouseTarget()
			if HitObject and not HitObject.Anchored then
				SelectedObject = HitObject
				GrabDistance = (SelectedObject.Position - Camera.CFrame.Position).Magnitude
				UpdateSelectionHighlight(SelectedObject)
				IsObjectSelected = true
			end
		else
			CleanupObject()
		end
		IsMouseDown = false

	elseif CurrentSettings.SelectType == 3 then
		if not IsMouseDown then return end

		if not IsObjectSelected then
			local hitObject = GetMouseTarget()
			if hitObject and not hitObject.Anchored then
				PendingObject = hitObject
				UpdateSelectionHighlight(PendingObject)
			end
		end
		IsMouseDown = false
	end
end

local function HandleTextButtonClick()
	if CurrentSettings.SelectType ~= 3 then return end

	if not IsObjectSelected and PendingObject then
		SelectedObject = PendingObject
		GrabDistance = (SelectedObject.Position - Camera.CFrame.Position).Magnitude
		IsObjectSelected = true
		PendingObject = nil
		TextButton.Text = "Drop"
	else
		CleanupObject()
		TextButton.Text = "Pick Up"
	end
end

UserInputService.InputBegan:Connect(function(Input, Processed)
	if not IsScriptActive then return end

	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		IsMouseDown = true
		HandleSelection()
	elseif Input.UserInputType == Enum.UserInputType.Keyboard then
		if Input.KeyCode == CurrentSettings.CloserKey and GrabDistance and GrabDistance >= MinDistance then
			GrabDistance = GrabDistance - 7
		elseif Input.KeyCode == CurrentSettings.FartherAwayKey then
			GrabDistance = (GrabDistance or 10) + 7
		elseif Input.KeyCode == CurrentSettings.RotateKey and SelectedObject then
			if SelectedObject:FindFirstChildWhichIsA("BodyGyro") then
				RemoveBodyGyro(SelectedObject)
			else
				RemoveBodyGyro(SelectedObject)
				local BodyGyro = Instance.new("BodyGyro")
				BodyGyro.MaxTorque = Vector3.new(math.huge, 0, math.huge)
				BodyGyro.D = 100
				BodyGyro.CFrame = CFrame.new(SelectedObject.CFrame.Position)
				BodyGyro.Parent = SelectedObject
			end
		elseif Input.KeyCode == CurrentSettings.ThrowKey and SelectedObject then
			local ThrowDirection = Camera.CFrame.LookVector * 100
			SelectedObject.Velocity = ThrowDirection
			CleanupObject()
		end
	end
end)

UserInputService.InputEnded:Connect(function(Input, Processed)
	if not IsScriptActive then return end

	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		IsMouseDown = false
		if CurrentSettings.SelectType == 1 then
			CleanupObject()
		end
	end
end)

game:GetService("RunService").RenderStepped:Connect(function()
	if SelectedObject and IsScriptActive then
		HandleObjectMovement()
	end
end)

Tool.Destroying:Connect(function()
	if Gui then
		Gui:Destroy()
		Gui = nil
	end
	
	IsScriptActive = false
	CleanupObject()
	SelectionBox:Destroy()
	BodyPosition:Destroy()
end)

Tool.Equipped:Connect(function()
	IsScriptActive = true
	if Gui then
		Gui:Destroy()
		Gui = nil
	end

	Gui = CreateGui()
	
	TextButton = Gui:FindFirstChild("PickUpButton")
	
	if TextButton then
		TextButton.MouseButton1Click:Connect(HandleTextButtonClick)
	end
end)

Tool.Unequipped:Connect(function()
	IsScriptActive = false
	CleanupObject()
	if not Gui then
		return
	end
	Gui:Destroy()
	Gui = nil
end)
