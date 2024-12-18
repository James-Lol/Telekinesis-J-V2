local ReplicatedStorage = game:GetService("ReplicatedStorage")

if ReplicatedStorage:GetAttribute("TelekinesisJV2") then
	warn("Telekinesis-J-V2 Already loaded!")
	return
end

ReplicatedStorage:SetAttribute("TelekinesisJV2",true)

local TelekinesisGui = Instance.new("ScreenGui")
TelekinesisGui.DisplayOrder = 2147483647
TelekinesisGui.IgnoreGuiInset = true
TelekinesisGui.ResetOnSpawn = false
TelekinesisGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
TelekinesisGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
TelekinesisGui.Name = "TelekinesisGui"

local Button = Instance.new("TextButton")
Button.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
Button.Text = "T"
Button.TextColor = BrickColor.new("Institutional white")
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextScaled = true
Button.TextWrapped = true
Button.AutoButtonColor = false
Button.AnchorPoint = Vector2.new(0, 1)
Button.BackgroundColor3 = Color3.fromRGB(47, 47, 53)
Button.BorderColor = BrickColor.new("Really black")
Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
Button.BorderSizePixel = 0
Button.Position = UDim2.new(0.01, 0, 0.98, 0)
Button.Size = UDim2.new(0.075, 0, 0.082, 0)
Button.Name = "Button"

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.25, 0)

TelekinesisGui.Parent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
Button.Parent = TelekinesisGui
UIAspectRatioConstraint.Parent = Button
UICorner.Parent = Button

Button.MouseButton1Click:Connect(function()
	local Code = game:HttpGet("https://raw.githubusercontent.com/James-Lol/Telekinesis-J-V2/refs/heads/main/Tool.Lua")
	local Success, ErrorMsg = pcall(function()
		loadstring(Code)()
	end)
end)
