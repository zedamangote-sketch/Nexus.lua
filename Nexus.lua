--========================================================--
-- NEXUS PREMIUM V6
-- LocalScript - para seu próprio jogo Roblox
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--========================================================--
-- CONFIG
--========================================================--

local Config = {
	AimEnabled = true,
	ESPEnabled = true,
	WallCheck = true,

	FOV = 10,
	Smoothness = 1,

	SelectedPart = "Head",

	LineESP = true,
	BoxESP = true,
	HealthESP = true,
	NameESP = true,
	DistanceESP = true,

	SpinEnabled = false,
	SpinSpeed = 8,

	WalkSpeedEnabled = false,
	WalkSpeed = 16,

	LowGFX = false
}

-- Jogadores que o AIM deve ignorar
local ExcludedPlayers = {}

--========================================================--
-- CONTROLE DE TOQUES
--========================================================--

-- Impede que o mesmo toque seja reaproveitado depois de
-- uma troca de aba ou atualização da interface.
local UIInputLocked = false
local LastUIAction = 0
local UIActionDelay = 0.16

local function CanUIAction()
	local Now = os.clock()

	if UIInputLocked then
		return false
	end

	if Now - LastUIAction < UIActionDelay then
		return false
	end

	LastUIAction = Now
	UIInputLocked = true

	task.delay(UIActionDelay, function()
		UIInputLocked = false
	end)

	return true
end

--========================================================--
-- CREATOR
--========================================================--

local CREATOR_NAME = "girldapancada"
local CREATOR_USER_ID = 10266230805

--========================================================--
-- COLORS
--========================================================--

local RED = Color3.fromRGB(115, 0, 8)
local RED2 = Color3.fromRGB(180, 0, 15)
local RED_DARK = Color3.fromRGB(45, 0, 5)

local GREEN = Color3.fromRGB(55, 215, 115)
local GREEN_DARK = Color3.fromRGB(25, 100, 55)

local BG = Color3.fromRGB(6,6,8)
local BG2 = Color3.fromRGB(10,10,13)
local BG3 = Color3.fromRGB(18,18,22)
local BG4 = Color3.fromRGB(26,26,31)

local WHITE = Color3.fromRGB(242,242,245)
local GRAY = Color3.fromRGB(145,145,152)
local DARKGRAY = Color3.fromRGB(70,70,76)

--========================================================--
-- GUI
--========================================================--

local Gui = Instance.new("ScreenGui")
Gui.Name = "NexusPremiumV6"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- UTIL
--========================================================--

local function Corner(Object, Radius)
	local C = Instance.new("UICorner")
	C.CornerRadius = UDim.new(0, Radius)
	C.Parent = Object
	return C
end

local function Stroke(Object, Color, Thickness, Transparency)
	local S = Instance.new("UIStroke")
	S.Color = Color or RED
	S.Thickness = Thickness or 1
	S.Transparency = Transparency or 0
	S.Parent = Object
	return S
end

local function Tween(Object, Time, Properties)
	return TweenService:Create(
		Object,
		TweenInfo.new(
			Time,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		Properties
	)
end

local function Label(Parent, Text, Position, Size, TextSize)
	local L = Instance.new("TextLabel")

	L.BackgroundTransparency = 1
	L.Position = Position
	L.Size = Size

	L.Text = Text
	L.TextColor3 = WHITE
	L.TextSize = TextSize or 12
	L.Font = Enum.Font.GothamBold

	L.TextXAlignment = Enum.TextXAlignment.Left
	L.TextYAlignment = Enum.TextYAlignment.Center

	L.ZIndex = 10
	L.Parent = Parent

	return L
end

local function Button(Parent, Text, Position, Size)
	local B = Instance.new("TextButton")

	B.Position = Position
	B.Size = Size

	B.BackgroundColor3 = BG3
	B.BorderSizePixel = 0

	B.Text = Text
	B.TextColor3 = GRAY
	B.TextSize = 10
	B.Font = Enum.Font.GothamBold

	B.AutoButtonColor = false
	B.ZIndex = 10
	B.Active = true
	B.Parent = Parent

	Corner(B,9)
	Stroke(B,Color3.fromRGB(45,45,50),1)

	return B
end

--========================================================--
-- ON / OFF
--========================================================--

local function UpdateToggleVisual(ButtonObject, State)

	if State then
		ButtonObject.BackgroundColor3 = GREEN
		ButtonObject.TextColor3 = Color3.fromRGB(10,30,15)

		ButtonObject.Text = ButtonObject:GetAttribute("ToggleName")
			.. "  •  ON"
	else
		ButtonObject.BackgroundColor3 = RED_DARK
		ButtonObject.TextColor3 = RED2

		ButtonObject.Text = ButtonObject:GetAttribute("ToggleName")
			.. "  •  OFF"
	end
end

local function Toggle(
	Parent,
	Name,
	Position,
	State,
	Callback
)

	local B = Button(
		Parent,
		"",
		Position,
		UDim2.fromOffset(350,42)
	)

	B:SetAttribute("ToggleName",Name)

	UpdateToggleVisual(B,State)

	B.Activated:Connect(function()

		if not CanUIAction() then
			return
		end

		State = not State

		UpdateToggleVisual(B,State)

		Callback(State)
	end)

	return B
end

--========================================================--
-- FOV
--========================================================--

local FOVCircle = Instance.new("Frame")

FOVCircle.AnchorPoint = Vector2.new(.5,.5)
FOVCircle.Position = UDim2.fromScale(.5,.5)

FOVCircle.Size = UDim2.fromOffset(
	Config.FOV*3,
	Config.FOV*3
)

FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0

FOVCircle.ZIndex = 2
FOVCircle.Parent = Gui

Corner(FOVCircle,999)
Stroke(FOVCircle,RED2,2,.15)

local function UpdateFOV()

	FOVCircle.Size = UDim2.fromOffset(
		math.max(Config.FOV*3,2),
		math.max(Config.FOV*3,2)
	)

	FOVCircle.Visible =
		Config.AimEnabled
		and Config.FOV > 0
end

--========================================================--
-- HUB
--========================================================--

local HUB_WIDTH = 550
local HUB_HEIGHT = 385

local Hub = Instance.new("Frame")

Hub.Size = UDim2.fromOffset(
	HUB_WIDTH,
	HUB_HEIGHT
)

Hub.Position =
	UDim2.new(
		.5,
		-HUB_WIDTH/2,
		.5,
		-HUB_HEIGHT/2
	)

Hub.BackgroundColor3 = BG
Hub.BorderSizePixel = 0

Hub.Visible = false
Hub.ClipsDescendants = true

Hub.Parent = Gui

Corner(Hub,17)
Stroke(Hub,RED,1.5,.15)

--========================================================--
-- BACKGROUND ANIMADO
--========================================================--

local Background = Instance.new("Frame")

Background.Size = UDim2.fromScale(1,1)
Background.BackgroundTransparency = 1
Background.ClipsDescendants = true
Background.ZIndex = 1
Background.Parent = Hub

local BackgroundLayer = Instance.new("Frame")

BackgroundLayer.Size = UDim2.fromScale(1,1)
BackgroundLayer.BackgroundTransparency = 1
BackgroundLayer.BorderSizePixel = 0
BackgroundLayer.ZIndex = 1
BackgroundLayer.Parent = Background

--========================================================--
-- GLOW
--========================================================--

local function Glow(Size,Position)

	local G = Instance.new("Frame")

	G.Size = UDim2.fromOffset(Size,Size)
	G.Position = Position

	G.BackgroundColor3 = RED
	G.BackgroundTransparency = .95

	G.BorderSizePixel = 0
	G.ZIndex = 1

	G.Parent = BackgroundLayer

	Corner(G,999)

	return G
end

local Glow1 = Glow(
	320,
	UDim2.new(-.3,0,-.35,0)
)

local Glow2 = Glow(
	350,
	UDim2.new(.72,0,.58,0)
)

local Glow3 = Glow(
	240,
	UDim2.new(.30,0,.35,0)
)

--========================================================--
-- FORMAS
--========================================================--

local function CreateShape(
	Size,
	Position,
	Rotation,
	Transparency,
	Type
)

	local Shape = Instance.new("Frame")

	Shape.Size =
		UDim2.fromOffset(Size,Size)

	Shape.Position = Position

	Shape.BackgroundColor3 = RED2
	Shape.BackgroundTransparency = Transparency

	Shape.BorderSizePixel = 0
	Shape.Rotation = Rotation
	Shape.ZIndex = 2
	Shape.Active = false

	Shape.Parent = BackgroundLayer

	if Type == "Circle" then
		Corner(Shape,999)

	elseif Type == "Square" then
		Corner(Shape,10)

	elseif Type == "Diamond" then
		Corner(Shape,8)
		Shape.Rotation = 45
	end

	Stroke(
		Shape,
		RED2,
		1,
		.75
	)

	return Shape
end

local Shape1 = CreateShape(
	105,
	UDim2.new(-.15,0,.05,0),
	20,
	.93,
	"Circle"
)

local Shape2 = CreateShape(
	70,
	UDim2.new(.78,0,.12,0),
	35,
	.94,
	"Diamond"
)

local Shape3 = CreateShape(
	135,
	UDim2.new(.72,0,.68,0),
	15,
	.95,
	"Circle"
)

local Shape4 = CreateShape(
	62,
	UDim2.new(.15,0,.78,0),
	55,
	.94,
	"Square"
)

local Shape5 = CreateShape(
	45,
	UDim2.new(.45,0,.18,0),
	30,
	.92,
	"Diamond"
)

--========================================================--
-- PONTOS
--========================================================--

local FloatingObjects = {}

local Positions = {
	{.08,.18,7},
	{.22,.38,6},
	{.36,.12,5},
	{.52,.32,7},
	{.67,.17,6},
	{.87,.32,8},
	{.12,.67,6},
	{.31,.82,7},
	{.49,.67,5},
	{.68,.84,7},
	{.89,.70,6},
	{.57,.52,5}
}

for _,Data in ipairs(Positions) do

	local Dot = Instance.new("Frame")

	Dot.Size =
		UDim2.fromOffset(
			Data[3],
			Data[3]
		)

	Dot.Position =
		UDim2.new(
			Data[1],
			0,
			Data[2],
			0
		)

	Dot.BackgroundColor3 = RED2
	Dot.BackgroundTransparency = .55
	Dot.BorderSizePixel = 0
	Dot.ZIndex = 2
	Dot.Active = false
	Dot.Parent = BackgroundLayer

	Corner(Dot,999)

	table.insert(
		FloatingObjects,
		Dot
	)
end

--========================================================--
-- LINHAS
--========================================================--

local function CreateLine(
	Position,
	Size,
	Rotation
)

	local Line = Instance.new("Frame")

	Line.Size = Size
	Line.Position = Position

	Line.BackgroundColor3 = RED
	Line.BackgroundTransparency = .88

	Line.BorderSizePixel = 0
	Line.Rotation = Rotation

	Line.ZIndex = 2
	Line.Active = false
	Line.Parent = BackgroundLayer

	Corner(Line,999)

	return Line
end

local Line1 = CreateLine(
	UDim2.new(.05,0,.30,0),
	UDim2.fromOffset(180,2),
	-25
)

local Line2 = CreateLine(
	UDim2.new(.63,0,.55,0),
	UDim2.fromOffset(220,2),
	25
)

local Line3 = CreateLine(
	UDim2.new(.28,0,.88,0),
	UDim2.fromOffset(160,2),
	-15
)

--========================================================--
-- ANIMAÇÃO BACKGROUND
--========================================================--

task.spawn(function()

	while Hub.Parent do

		Tween(
			Glow1,
			5,
			{
				Position = UDim2.new(-.08,0,-.12,0),
				BackgroundTransparency = .90
			}
		):Play()

		Tween(
			Glow2,
			6,
			{
				Position = UDim2.new(.58,0,.42,0),
				BackgroundTransparency = .92
			}
		):Play()

		Tween(
			Glow3,
			5,
			{
				Position = UDim2.new(.18,0,.28,0),
				BackgroundTransparency = .96
			}
		):Play()

		Tween(
			Shape1,
			7,
			{
				Position = UDim2.new(-.04,0,.15,0),
				Rotation = 70,
				BackgroundTransparency = .88
			}
		):Play()

		Tween(
			Shape2,
			6,
			{
				Position = UDim2.new(.70,0,.25,0),
				Rotation = 120,
				BackgroundTransparency = .90
			}
		):Play()

		Tween(
			Shape3,
			8,
			{
				Position = UDim2.new(.62,0,.55,0),
				Rotation = 100,
				BackgroundTransparency = .91
			}
		):Play()

		Tween(
			Shape4,
			7,
			{
				Position = UDim2.new(.22,0,.67,0),
				Rotation = 130,
				BackgroundTransparency = .90
			}
		):Play()

		Tween(
			Shape5,
			6,
			{
				Position = UDim2.new(.52,0,.28,0),
				Rotation = 100,
				BackgroundTransparency = .88
			}
		):Play()

		task.wait(6)

		Tween(
			Glow1,
			5,
			{
				Position = UDim2.new(-.30,0,-.35,0),
				BackgroundTransparency = .95
			}
		):Play()

		Tween(
			Glow2,
			6,
			{
				Position = UDim2.new(.72,0,.58,0),
				BackgroundTransparency = .95
			}
		):Play()

		Tween(
			Glow3,
			5,
			{
				Position = UDim2.new(.30,0,.35,0),
				BackgroundTransparency = .95
			}
		):Play()

		Tween(
			Shape1,
			7,
			{
				Position = UDim2.new(-.15,0,.05,0),
				Rotation = 20,
				BackgroundTransparency = .93
			}
		):Play()

		Tween(
			Shape2,
			6,
			{
				Position = UDim2.new(.78,0,.12,0),
				Rotation = 35,
				BackgroundTransparency = .94
			}
		):Play()

		Tween(
			Shape3,
			8,
			{
				Position = UDim2.new(.72,0,.68,0),
				Rotation = 15,
				BackgroundTransparency = .95
			}
		):Play()

		Tween(
			Shape4,
			7,
			{
				Position = UDim2.new(.15,0,.78,0),
				Rotation = 55,
				BackgroundTransparency = .94
			}
		):Play()

		Tween(
			Shape5,
			6,
			{
				Position = UDim2.new(.45,0,.18,0),
				Rotation = 30,
				BackgroundTransparency = .92
			}
		):Play()

		task.wait(6)
	end
end)

--========================================================--
-- ANIMAÇÃO DOS PONTOS
--========================================================--

task.spawn(function()

	while Hub.Parent do

		for I,Dot in ipairs(FloatingObjects) do

			if Dot and Dot.Parent then

				local Offset =
					(I % 2 == 0)
					and .018
					or -.018

				Tween(
					Dot,
					2.5 + (I % 3),
					{
						Position =
							UDim2.new(
								Dot.Position.X.Scale,
								0,
								Dot.Position.Y.Scale + Offset,
								0
							),

						BackgroundTransparency = .25
					}
				):Play()
			end
		end

		task.wait(2.5)

		for I,Dot in ipairs(FloatingObjects) do

			if Dot and Dot.Parent then

				local Offset =
					(I % 2 == 0)
					and -.018
					or .018

				Tween(
					Dot,
					2.5 + (I % 3),
					{
						Position =
							UDim2.new(
								Dot.Position.X.Scale,
								0,
								Dot.Position.Y.Scale + Offset,
								0
							),

						BackgroundTransparency = .65
					}
				):Play()
			end
		end

		task.wait(2.5)
	end
end)

--========================================================--
-- TOP BAR
--========================================================--

local TopBar = Instance.new("Frame")

TopBar.Size = UDim2.new(1,0,0,55)
TopBar.BackgroundColor3 = BG2
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 5
TopBar.Parent = Hub

Label(
	TopBar,
	"♛  NEXUS",
	UDim2.fromOffset(17,0),
	UDim2.fromOffset(180,55),
	19
).TextColor3 = RED2

Label(
	TopBar,
	"PREMIUM  V6",
	UDim2.fromOffset(150,0),
	UDim2.fromOffset(100,55),
	8
).TextColor3 = GRAY

local OnlineDot = Instance.new("Frame")

OnlineDot.Size = UDim2.fromOffset(8,8)
OnlineDot.Position = UDim2.new(1,-88,.5,-4)
OnlineDot.BackgroundColor3 = GREEN
OnlineDot.BorderSizePixel = 0
OnlineDot.ZIndex = 10
OnlineDot.Parent = TopBar

Corner(OnlineDot,999)

Label(
	TopBar,
	"ONLINE",
	UDim2.new(1,-74,0,0),
	UDim2.fromOffset(55,55),
	8
).TextColor3 = GREEN

local Close = Button(
	TopBar,
	"×",
	UDim2.new(1,-47,0,7),
	UDim2.fromOffset(38,38)
)

Close.TextSize = 22
Close.BackgroundTransparency = 1

Close.Activated:Connect(function()

	if not CanUIAction() then
		return
	end

	Hub.Visible = false
end)

--========================================================--
-- SIDEBAR
--========================================================--

local Sidebar = Instance.new("Frame")

Sidebar.Size =
	UDim2.fromOffset(
		116,
		HUB_HEIGHT-68
	)

Sidebar.Position = UDim2.fromOffset(8,61)
Sidebar.BackgroundColor3 = BG2
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 5
Sidebar.Parent = Hub

Corner(Sidebar,12)

local Tabs = {}

local function CreateTab(Name,Text,Y)

	local B = Button(
		Sidebar,
		Text,
		UDim2.fromOffset(6,Y),
		UDim2.new(1,-12,0,38)
	)

	B.Name = Name
	Tabs[Name] = B

	return B
end

local HomeTab =
	CreateTab("Home","⌂  HOME",8)

local AimTab =
	CreateTab("Aim","◎  AIM",51)

local VisualTab =
	CreateTab("Visual","◉  ESP",94)

local PlayerTab =
	CreateTab("Player","♙  PLAYER",137)

local LowGFXTab =
	CreateTab("LowGFX","⚡  LOW GFX",180)

local SettingsTab =
	CreateTab("Settings","⚙  SETTINGS",223)

--========================================================--
-- CONTENT
--========================================================--

local Content = Instance.new("ScrollingFrame")

Content.Size =
	UDim2.new(1,-134,1,-68)

Content.Position =
	UDim2.fromOffset(126,61)

Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0

Content.ScrollBarThickness = 5
Content.ScrollBarImageColor3 = RED
Content.ScrollBarImageTransparency = 0

Content.ScrollingDirection =
	Enum.ScrollingDirection.Y

Content.CanvasSize =
	UDim2.fromOffset(0,500)

Content.ZIndex = 5
Content.Parent = Hub

local function SetScrollHeight(Height)

	Content.CanvasSize =
		UDim2.fromOffset(0,Height)

	-- Só reseta quando uma página realmente foi aberta.
	Content.CanvasPosition =
		Vector2.new(0,0)
end

local function ClearContent()

	for _,Object in ipairs(Content:GetChildren()) do
		Object:Destroy()
	end

	Content.CanvasPosition =
		Vector2.new(0,0)
end

local function Activate(Tab)

	for _,B in pairs(Tabs) do

		B.BackgroundColor3 = BG3
		B.TextColor3 = GRAY
	end

	Tab.BackgroundColor3 = RED
	Tab.TextColor3 = WHITE
end

--========================================================--
-- SLIDER
--========================================================--

local SliderConnections = {}

local function Slider(
	Parent,
	Name,
	Position,
	Min,
	Max,
	Value,
	Callback
)

	local Holder = Instance.new("Frame")

	Holder.Size = UDim2.fromOffset(350,62)
	Holder.Position = Position
	Holder.BackgroundTransparency = 1
	Holder.ZIndex = 10
	Holder.Parent = Parent

	Label(
		Holder,
		Name,
		UDim2.fromOffset(0,0),
		UDim2.fromOffset(200,20),
		8
	).TextColor3 = GRAY

	local ValueLabel = Label(
		Holder,
		tostring(Value),
		UDim2.new(1,-70,0,0),
		UDim2.fromOffset(70,20),
		9
	)

	ValueLabel.TextXAlignment =
		Enum.TextXAlignment.Right

	ValueLabel.TextColor3 = RED2

	local Bar = Instance.new("Frame")

	Bar.Size = UDim2.new(1,0,0,7)
	Bar.Position = UDim2.fromOffset(0,29)
	Bar.BackgroundColor3 =
		Color3.fromRGB(38,38,43)

	Bar.BorderSizePixel = 0
	Bar.ZIndex = 11
	Bar.Parent = Holder

	Corner(Bar,999)

	local Fill = Instance.new("Frame")

	Fill.BackgroundColor3 = RED
	Fill.BorderSizePixel = 0
	Fill.ZIndex = 12
	Fill.Parent = Bar

	Corner(Fill,999)

	local Knob = Instance.new("Frame")

	Knob.Size = UDim2.fromOffset(14,14)
	Knob.AnchorPoint = Vector2.new(.5,.5)
	Knob.BackgroundColor3 = RED2
	Knob.BorderSizePixel = 0
	Knob.ZIndex = 13
	Knob.Parent = Bar

	Corner(Knob,999)

	local Dragging = false

	local function SetValue(X)

		if not Bar.Parent then
			return
		end

		local Percent =
			math.clamp(
				(X-Bar.AbsolutePosition.X)
				/Bar.AbsoluteSize.X,
				0,
				1
			)

		local NewValue =
			Min+(Max-Min)*Percent

		if Max-Min > 20 then
			NewValue =
				math.floor(NewValue+.5)
		else
			NewValue =
				math.floor(NewValue*100+.5)/100
		end

		Value = NewValue

		local P =
			(Value-Min)/(Max-Min)

		Fill.Size =
			UDim2.new(P,0,1,0)

		Knob.Position =
			UDim2.new(P,0,.5,0)

		ValueLabel.Text =
			tostring(Value)

		Callback(Value)
	end

	local function Begin(Input)

		if UIInputLocked then
			return
		end

		if Input.UserInputType ==
			Enum.UserInputType.Touch

			or Input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			Dragging = true
			SetValue(Input.Position.X)
		end
	end

	Bar.InputBegan:Connect(Begin)
	Knob.InputBegan:Connect(Begin)

	local ChangedConnection =
		UserInputService.InputChanged:Connect(function(Input)

			if not Dragging then
				return
			end

			if Input.UserInputType ==
				Enum.UserInputType.Touch

				or Input.UserInputType ==
				Enum.UserInputType.MouseMovement then

				SetValue(Input.Position.X)
			end
		end)

	local EndedConnection =
		UserInputService.InputEnded:Connect(function(Input)

			if Input.UserInputType ==
				Enum.UserInputType.Touch

				or Input.UserInputType ==
				Enum.UserInputType.MouseButton1 then

				Dragging = false
			end
		end)

	table.insert(SliderConnections,ChangedConnection)
	table.insert(SliderConnections,EndedConnection)

	Holder.Destroying:Connect(function()
		Dragging = false
	end)

	task.defer(function()

		if not Bar.Parent then
			return
		end

		local P =
			(Value-Min)/(Max-Min)

		Fill.Size =
			UDim2.new(P,0,1,0)

		Knob.Position =
			UDim2.new(P,0,.5,0)
	end)

	return Holder
end

--========================================================--
-- AIM
--========================================================--

local function GetTargetPart(Character)

	if Config.SelectedPart == "Head" then

		return Character:FindFirstChild("Head")

	elseif Config.SelectedPart == "Torso" then

		return Character:FindFirstChild("UpperTorso")
			or Character:FindFirstChild("Torso")
			or Character:FindFirstChild("HumanoidRootPart")

	elseif Config.SelectedPart == "Legs" then

		return Character:FindFirstChild("LeftUpperLeg")
			or Character:FindFirstChild("Left Leg")
			or Character:FindFirstChild("RightUpperLeg")
			or Character:FindFirstChild("Right Leg")
	end
end

local function CanSee(Part)

	if not Config.WallCheck then
		return true
	end

	local Character = LocalPlayer.Character

	if not Character then
		return false
	end

	local Params = RaycastParams.new()

	Params.FilterType =
		Enum.RaycastFilterType.Exclude

	Params.FilterDescendantsInstances =
		{Character}

	local Direction =
		Part.Position-Camera.CFrame.Position

	local Result =
		workspace:Raycast(
			Camera.CFrame.Position,
			Direction,
			Params
		)

	if not Result then
		return true
	end

	return Result.Instance:IsDescendantOf(
		Part.Parent
	)
end

local function GetBestTarget()

	local BestPlayer
	local BestPart
	local BestDistance = math.huge

	local View =
		Camera.ViewportSize

	local Center =
		Vector2.new(
			View.X/2,
			View.Y/2
		)

	for _,Player in ipairs(
		Players:GetPlayers()
	) do

		if Player ~= LocalPlayer
			and not ExcludedPlayers[Player] then

			local Character =
				Player.Character

			if Character then

				local Humanoid =
					Character:FindFirstChildOfClass(
						"Humanoid"
					)

				local Part =
					GetTargetPart(Character)

				if Humanoid
					and Humanoid.Health > 0
					and Part then

					local Position,Visible =
						Camera:WorldToViewportPoint(
							Part.Position
						)

					if Visible then

						local Screen =
							Vector2.new(
								Position.X,
								Position.Y
							)

						local Distance =
							(Screen-Center).Magnitude

						if Distance <= Config.FOV*3
							and Distance < BestDistance
							and CanSee(Part) then

							BestDistance = Distance
							BestPlayer = Player
							BestPart = Part
						end
					end
				end
			end
		end
	end

	return BestPlayer,BestPart
end

RunService.RenderStepped:Connect(function()

	if not Config.AimEnabled then
		return
	end

	local Player,Part =
		GetBestTarget()

	if Player and Part then

		local Current =
			Camera.CFrame

		local Target =
			CFrame.lookAt(
				Current.Position,
				Part.Position
			)

		Camera.CFrame =
			Current:Lerp(
				Target,
				Config.Smoothness
			)
	end
end)

--========================================================--
-- ESP
--========================================================--

local ESPObjects = {}

local function RemoveESP(Player)

	local Data =
		ESPObjects[Player]

	if not Data then
		return
	end

	if Data.Connection then
		Data.Connection:Disconnect()
	end

	if Data.Highlight then
		Data.Highlight:Destroy()
	end

	if Data.Billboard then
		Data.Billboard:Destroy()
	end

	if Data.Line then
		Data.Line:Remove()
	end

	if Data.Box then
		Data.Box:Remove()
	end

	if Data.HealthBar then
		Data.HealthBar:Remove()
	end

	ESPObjects[Player] = nil
end

local function CreateESP(Player)

	if Player == LocalPlayer then
		return
	end

	RemoveESP(Player)

	if not Config.ESPEnabled then
		return
	end

	local Character =
		Player.Character

	if not Character then
		return
	end

	local Humanoid =
		Character:FindFirstChildOfClass(
			"Humanoid"
		)

	local Root =
		Character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not Humanoid or not Root then
		return
	end

	local Highlight =
		Instance.new("Highlight")

	Highlight.Adornee =
		Character

	Highlight.FillColor = RED
	Highlight.FillTransparency = .9

	Highlight.OutlineColor =
		RED2

	Highlight.OutlineTransparency = .1

	Highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	Highlight.Parent =
		Character

	local Billboard =
		Instance.new("BillboardGui")

	Billboard.Size =
		UDim2.fromOffset(220,40)

	Billboard.StudsOffset =
		Vector3.new(0,3.8,0)

	Billboard.AlwaysOnTop = true
	Billboard.Adornee = Root
	Billboard.Parent = Character

	local Text =
		Instance.new("TextLabel")

	Text.Size =
		UDim2.fromScale(1,1)

	Text.BackgroundTransparency = 1
	Text.TextColor3 = WHITE
	Text.TextStrokeTransparency = .2
	Text.TextSize = 10
	Text.Font = Enum.Font.GothamBold
	Text.Parent = Billboard

	local Line
	local Box
	local HealthBar

	pcall(function()

		if Config.LineESP then

			Line = Drawing.new("Line")

			Line.Thickness = 1.5
			Line.Color = RED2
			Line.Transparency = 1
			Line.Visible = true
		end

		if Config.BoxESP then

			Box = Drawing.new("Square")

			Box.Thickness = 1.5
			Box.Color = RED2
			Box.Filled = false
			Box.Transparency = 1
			Box.Visible = true
		end

		if Config.HealthESP then

			HealthBar =
				Drawing.new("Line")

			HealthBar.Thickness = 3
			HealthBar.Color = GREEN
			HealthBar.Transparency = 1
			HealthBar.Visible = true
		end
	end)

	local Connection

	Connection =
		RunService.RenderStepped:Connect(
			function()

				if not Player.Parent
					or not Character.Parent
					or Humanoid.Health <= 0 then

					RemoveESP(Player)
					return
				end

				local Position,Visible =
					Camera:WorldToViewportPoint(
						Root.Position
					)

				if not Visible then

					if Line then
						Line.Visible = false
					end

					if Box then
						Box.Visible = false
					end

					if HealthBar then
						HealthBar.Visible = false
					end

					return
				end

				local Parts = {}

				if Config.NameESP then
					table.insert(
						Parts,
						Player.DisplayName
					)
				end

				if Config.DistanceESP then

					local MyCharacter =
						LocalPlayer.Character

					local MyRoot =
						MyCharacter
						and MyCharacter:FindFirstChild(
							"HumanoidRootPart"
						)

					if MyRoot then

						local Distance =
							math.floor(
								(
									MyRoot.Position
									-Root.Position
								).Magnitude
							)

						table.insert(
							Parts,
							Distance.."m"
						)
					end
				end

				Text.Text =
					table.concat(
						Parts,
						"  •  "
					)

				if Box then

					Box.Visible =
						Config.BoxESP

					if Config.BoxESP then

						local Head =
							Character:FindFirstChild(
								"Head"
							)

						local HeadPosition =
							Head
							and Camera:WorldToViewportPoint(
								Head.Position+
								Vector3.new(0,0.5,0)
							)

						local RootPosition =
							Camera:WorldToViewportPoint(
								Root.Position-
								Vector3.new(0,3,0)
							)

						if HeadPosition then

							local Height =
								math.abs(
									RootPosition.Y-
									HeadPosition.Y
								)

							local Width =
								Height*.55

							Box.Size =
								Vector2.new(
									Width,
									Height
								)

							Box.Position =
								Vector2.new(
									Position.X-Width/2,
									HeadPosition.Y
								)
						end
					end
				end

				if Line then

					Line.Visible =
						Config.LineESP

					if Config.LineESP then

						local View =
							Camera.ViewportSize

						Line.From =
							Vector2.new(
								View.X/2,
								View.Y
							)

						Line.To =
							Vector2.new(
								Position.X,
								Position.Y
							)
					end
				end

				if HealthBar then

					HealthBar.Visible =
						Config.HealthESP

					if Config.HealthESP then

						local Head =
							Character:FindFirstChild(
								"Head"
							)

						local Top =
							Head
							and Camera:WorldToViewportPoint(
								Head.Position+
								Vector3.new(-.8,.7,0)
							)

						local Bottom =
							Camera:WorldToViewportPoint(
								Root.Position-
								Vector3.new(0,3,0)
							)

						if Top then

							local Ratio =
								math.clamp(
									Humanoid.Health/
									math.max(
										Humanoid.MaxHealth,
										1
									),
									0,
									1
								)

							local Height =
								math.abs(
									Bottom.Y-Top.Y
								)

							local X =
								Top.X-6

							HealthBar.From =
								Vector2.new(
									X,
									Bottom.Y
								)

							HealthBar.To =
								Vector2.new(
									X,
									Bottom.Y-
									Height*Ratio
								)

							if Ratio > .5 then
								HealthBar.Color = GREEN

							elseif Ratio > .25 then
								HealthBar.Color =
									Color3.fromRGB(
										255,190,50
									)
							else
								HealthBar.Color = RED2
							end
						end
					end
				end
			end
		)

	ESPObjects[Player] = {
		Highlight = Highlight,
		Billboard = Billboard,
		Line = Line,
		Box = Box,
		HealthBar = HealthBar,
		Connection = Connection
	}
end

local function UpdateESP()

	for _,Player in ipairs(
		Players:GetPlayers()
	) do

		if Player ~= LocalPlayer then

			if Config.ESPEnabled then
				CreateESP(Player)
			else
				RemoveESP(Player)
			end
		end
	end
end

--========================================================--
-- HOME
--========================================================--

local function HomePage()

	ClearContent()
	Activate(HomeTab)
	SetScrollHeight(390)

	Label(
		Content,
		"WELCOME BACK",
		UDim2.fromOffset(10,5),
		UDim2.fromOffset(300,22),
		8
	).TextColor3 = GRAY

	Label(
		Content,
		"NEXUS PREMIUM",
		UDim2.fromOffset(10,26),
		UDim2.fromOffset(350,34),
		21
	).TextColor3 = RED2

	Label(
		Content,
		"V6  •  MOBILE EDITION",
		UDim2.fromOffset(10,60),
		UDim2.fromOffset(300,20),
		8
	).TextColor3 = GRAY

	local Avatar = Instance.new("ImageLabel")

	Avatar.Size =
		UDim2.fromOffset(58,58)

	Avatar.Position =
		UDim2.fromOffset(285,12)

	Avatar.BackgroundColor3 = BG3
	Avatar.BorderSizePixel = 0

	Avatar.ZIndex = 12
	Avatar.Parent = Content

	Avatar.ScaleType =
		Enum.ScaleType.Crop

	Corner(Avatar,999)
	Stroke(Avatar,RED,2)

	task.spawn(function()

		local Success,Image =
			pcall(function()

				return Players:GetUserThumbnailAsync(
					CREATOR_USER_ID,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size150x150
				)

			end)

		if Success and Image then
			Avatar.Image = Image
		end
	end)

	local CreatorLabel =
		Label(
			Content,
			"Criador: "..CREATOR_NAME,
			UDim2.fromOffset(10,88),
			UDim2.fromOffset(350,22),
			10
		)

	CreatorLabel.TextColor3 = RED2

	local Data = {
		{"AIM",function()
			return Config.AimEnabled and "ON" or "OFF"
		end},

		{"ESP",function()
			return Config.ESPEnabled and "ON" or "OFF"
		end},

		{"PLAYER",function()
			return Config.SpinEnabled and "SPIN ON" or "READY"
		end},

		{"LOW GFX",function()
			return Config.LowGFX and "ON" or "OFF"
		end}
	}

	for I,Item in ipairs(Data) do

		local X =
			((I-1)%2)*180

		local Y =
			125+
			math.floor((I-1)/2)*82

		local Card =
			Instance.new("Frame")

		Card.Size =
			UDim2.fromOffset(168,68)

		Card.Position =
			UDim2.fromOffset(
				10+X,
				Y
			)

		Card.BackgroundColor3 = BG2
		Card.BorderSizePixel = 0
		Card.Parent = Content

		Corner(Card,10)

		Stroke(
			Card,
			Color3.fromRGB(40,40,45),
			1
		)

		Label(
			Card,
			Item[1],
			UDim2.fromOffset(12,7),
			UDim2.fromOffset(130,18),
			8
		).TextColor3 = GRAY

		local Value =
			Label(
				Card,
				Item[2](),
				UDim2.fromOffset(12,28),
				UDim2.fromOffset(140,25),
				13
			)

		task.spawn(function()

			while Value.Parent do

				Value.Text =
					Item[2]()

				if string.find(
					Value.Text,
					"ON"
				) then

					Value.TextColor3 = GREEN

				else

					Value.TextColor3 = RED2
				end

				task.wait(.15)
			end
		end)
	end
end

--========================================================--
-- AIM PAGE
--========================================================--

local function AimPage()

	ClearContent()
	Activate(AimTab)

	SetScrollHeight(760)

	Label(
		Content,
		"AIM CONTROL",
		UDim2.fromOffset(10,5),
		UDim2.fromOffset(300,28),
		18
	).TextColor3 = RED2

	Label(
		Content,
		"TARGETING SYSTEM",
		UDim2.fromOffset(10,33),
		UDim2.fromOffset(250,18),
		8
	).TextColor3 = GRAY

	Toggle(
		Content,
		"AIM ASSIST",
		UDim2.fromOffset(10,58),
		Config.AimEnabled,
		function(Value)

			Config.AimEnabled = Value
			UpdateFOV()
		end
	)

	Toggle(
		Content,
		"WALL CHECK",
		UDim2.fromOffset(10,108),
		Config.WallCheck,
		function(Value)

			Config.WallCheck = Value
		end
	)

	Slider(
		Content,
		"FOV",
		UDim2.fromOffset(10,164),
		0,
		170,
		Config.FOV,
		function(Value)

			Config.FOV = Value
			UpdateFOV()
		end
	)

	Slider(
		Content,
		"SMOOTHNESS",
		UDim2.fromOffset(10,232),
		.05,
		1,
		Config.Smoothness,
		function(Value)

			Config.Smoothness = Value
		end
	)

	Label(
		Content,
		"TARGET REGION",
		UDim2.fromOffset(10,302),
		UDim2.fromOffset(150,20),
		8
	).TextColor3 = GRAY

	local Parts = {
		"Head",
		"Torso",
		"Legs"
	}

	for I,Part in ipairs(Parts) do

		local B =
			Button(
				Content,
				Part,
				UDim2.fromOffset(
					10+(I-1)*116,
					325
				),
				UDim2.fromOffset(
					105,
					34
				)
			)

		if Config.SelectedPart == Part then

			B.BackgroundColor3 = RED
			B.TextColor3 = WHITE

		else

			B.BackgroundColor3 = BG3
			B.TextColor3 = GRAY
		end

		B.Activated:Connect(function()

			if not CanUIAction() then
				return
			end

			Config.SelectedPart = Part

			-- Atualiza somente os três botões.
			-- NÃO recria a página.
			for _,Child in ipairs(Content:GetChildren()) do

				if Child:IsA("TextButton") then

					if Child.Text == "Head"
						or Child.Text == "Torso"
						or Child.Text == "Legs" then

						if Child.Text == Config.SelectedPart then
							Child.BackgroundColor3 = RED
							Child.TextColor3 = WHITE
						else
							Child.BackgroundColor3 = BG3
							Child.TextColor3 = GRAY
						end
					end
				end
			end
		end)
	end

	--====================================================--
	-- MULTI-SELEÇÃO SEM REBUILD
	--====================================================--

	Label(
		Content,
		"IGNORE PLAYERS",
		UDim2.fromOffset(10,380),
		UDim2.fromOffset(250,24),
		13
	).TextColor3 = RED2

	Label(
		Content,
		"Selecione quem o AIM deve ignorar",
		UDim2.fromOffset(10,405),
		UDim2.fromOffset(330,20),
		8
	).TextColor3 = GRAY

	local CountLabel =
		Label(
			Content,
			"",
			UDim2.fromOffset(10,425),
			UDim2.fromOffset(350,18),
			8
		)

	CountLabel.TextColor3 = GRAY

	local PlayerButtons = {}

	local function UpdateIgnoreCount()

		local Count = 0

		for Player,_ in pairs(ExcludedPlayers) do

			if Player and Player.Parent then
				Count += 1
			end
		end

		CountLabel.Text =
			"Ignorados: "..tostring(Count)
	end

	local function UpdatePlayerButton(B,Player)

		if not B or not B.Parent then
			return
		end

		if ExcludedPlayers[Player] then

			B.BackgroundColor3 =
				RED_DARK

			B.TextColor3 =
				RED2

			B.Text =
				Player.DisplayName
				.."  •  IGNORADO"

		else

			B.BackgroundColor3 =
				GREEN_DARK

			B.TextColor3 =
				GREEN

			B.Text =
				Player.DisplayName
				.."  •  AIM"
		end
	end

	local Y = 450

	for _,Player in ipairs(
		Players:GetPlayers()
	) do

		if Player ~= LocalPlayer then

			local B =
				Button(
					Content,
					"",
					UDim2.fromOffset(10,Y),
					UDim2.fromOffset(350,38)
				)

			B:SetAttribute(
				"TargetPlayer",
				Player.UserId
			)

			UpdatePlayerButton(B,Player)

			PlayerButtons[Player] = B

			B.Activated:Connect(function()

				-- IMPORTANTE:
				-- não chama AimPage()
				-- não destrói a lista
				-- não altera CanvasPosition

				if not CanUIAction() then
					return
				end

				if not Player.Parent then
					return
				end

				if ExcludedPlayers[Player] then
					ExcludedPlayers[Player] = nil
				else
					ExcludedPlayers[Player] = true
				end

				UpdatePlayerButton(B,Player)
				UpdateIgnoreCount()
			end)

			Y += 45
		end
	end

	if Y == 450 then

		Label(
			Content,
			"Nenhum outro jogador na partida",
			UDim2.fromOffset(10,460),
			UDim2.fromOffset(350,25),
			9
		).TextColor3 = GRAY
	end

	local ClearIgnored =
		Button(
			Content,
			"LIMPAR IGNORADOS",
			UDim2.fromOffset(10,Y+8),
			UDim2.fromOffset(350,38)
		)

	ClearIgnored.BackgroundColor3 = BG4
	ClearIgnored.TextColor3 = RED2

	ClearIgnored.Activated:Connect(function()

		if not CanUIAction() then
			return
		end

		table.clear(ExcludedPlayers)

		-- Atualiza os botões sem recriar a página
		for Player,B in pairs(PlayerButtons) do

			if Player and B and B.Parent then
				UpdatePlayerButton(B,Player)
			end
		end

		UpdateIgnoreCount()
	end)

	UpdateIgnoreCount()
end

--========================================================--
-- ESP PAGE
--========================================================--

local function VisualPage()

	ClearContent()
	Activate(VisualTab)
	SetScrollHeight(400)

	Label(
		Content,
		"ESP VISUALS",
		UDim2.fromOffset(10,5),
		UDim2.fromOffset(300,28),
		18
	).TextColor3 = RED2

	Label(
		Content,
		"PLAYER OVERLAY SYSTEM",
		UDim2.fromOffset(10,34),
		UDim2.fromOffset(300,18),
		8
	).TextColor3 = GRAY

	Toggle(
		Content,
		"ESP",
		UDim2.fromOffset(10,62),
		Config.ESPEnabled,
		function(Value)

			Config.ESPEnabled = Value
			UpdateESP()
		end
	)

	Toggle(
		Content,
		"LINE ESP",
		UDim2.fromOffset(10,112),
		Config.LineESP,
		function(Value)

			Config.LineESP = Value
			UpdateESP()
		end
	)

	Toggle(
		Content,
		"BOX ESP",
		UDim2.fromOffset(10,162),
		Config.BoxESP,
		function(Value)

			Config.BoxESP = Value
			UpdateESP()
		end
	)

	Toggle(
		Content,
		"HEALTH BAR",
		UDim2.fromOffset(10,212),
		Config.HealthESP,
		function(Value)

			Config.HealthESP = Value
			UpdateESP()
		end
	)

	Toggle(
		Content,
		"NAME",
		UDim2.fromOffset(10,262),
		Config.NameESP,
		function(Value)

			Config.NameESP = Value
		end
	)

	Toggle(
		Content,
		"DISTANCE",
		UDim2.fromOffset(10,312),
		Config.DistanceESP,
		function(Value)

			Config.DistanceESP = Value
		end
	)
end

--========================================================--
-- PLAYER PAGE
--========================================================--

local SpinConnection

local function UpdateSpin()

	if SpinConnection then
		SpinConnection:Disconnect()
		SpinConnection = nil
	end

	if not Config.SpinEnabled then
		return
	end

	SpinConnection =
		RunService.RenderStepped:Connect(
			function()

				local Character =
					LocalPlayer.Character

				if not Character then
					return
				end

				local Root =
					Character:FindFirstChild(
						"HumanoidRootPart"
					)

				if Root then

					Root.CFrame =
						Root.CFrame *
						CFrame.Angles(
							0,
							math.rad(
								Config.SpinSpeed
							),
							0
						)
				end
			end
		)
end

local function ApplyWalkSpeed()

	local Character =
		LocalPlayer.Character

	if not Character then
		return
	end

	local Humanoid =
		Character:FindFirstChildOfClass(
			"Humanoid"
		)

	if Humanoid then

		if Config.WalkSpeedEnabled then

			Humanoid.WalkSpeed =
				Config.WalkSpeed

		else

			Humanoid.WalkSpeed = 16
		end
	end
end

local function PlayerPage()

	ClearContent()
	Activate(PlayerTab)
	SetScrollHeight(390)

	Label(
		Content,
		"PLAYER",
		UDim2.fromOffset(10,5),
		UDim2.fromOffset(300,28),
		18
	).TextColor3 = RED2

	Label(
		Content,
		"CHARACTER CONTROL",
		UDim2.fromOffset(10,34),
		UDim2.fromOffset(250,18),
		8
	).TextColor3 = GRAY

	Toggle(
		Content,
		"SPIN",
		UDim2.fromOffset(10,62),
		Config.SpinEnabled,
		function(Value)

			Config.SpinEnabled = Value
			UpdateSpin()
		end
	)

	Slider(
		Content,
		"SPIN SPEED",
		UDim2.fromOffset(10,115),
		1,
		40,
		Config.SpinSpeed,
		function(Value)

			Config.SpinSpeed = Value
		end
	)

	Toggle(
		Content,
		"WALKSPEED",
		UDim2.fromOffset(10,185),
		Config.WalkSpeedEnabled,
		function(Value)

			Config.WalkSpeedEnabled = Value
			ApplyWalkSpeed()
		end
	)

	Slider(
		Content,
		"WALKSPEED VALUE",
		UDim2.fromOffset(10,238),
		16,
		100,
		Config.WalkSpeed,
		function(Value)

			Config.WalkSpeed = Value
			ApplyWalkSpeed()
		end
	)

	Label(
		Content,
		"PLAYER SPEED",
		UDim2.fromOffset(10,310),
		UDim2.fromOffset(150,20),
		8
	).TextColor3 = GRAY

	Label(
		Content,
		"Current: "..tostring(Config.WalkSpeed),
		UDim2.fromOffset(10,332),
		UDim2.fromOffset(250,20),
		10
	).TextColor3 = RED2
end

--========================================================--
-- LOW GFX
--========================================================--

local LowGFXBackup = {}

local function SetLowGFX(State)

	Config.LowGFX = State

	if State then

		LowGFXBackup = {}

		for _,Object in ipairs(
			workspace:GetDescendants()
		) do

			if Object:IsA("BasePart") then

				LowGFXBackup[Object] = {
					Material = Object.Material,
					Reflectance = Object.Reflectance
				}

				Object.Material =
					Enum.Material.SmoothPlastic

				Object.Reflectance = 0

			elseif Object:IsA("Decal")
				or Object:IsA("Texture") then

				LowGFXBackup[Object] = {
					Transparency =
						Object.Transparency
				}

				Object.Transparency = 1

			elseif Object:IsA("ParticleEmitter")
				or Object:IsA("Trail")
				or Object:IsA("Beam") then

				LowGFXBackup[Object] = {
					Enabled =
						Object.Enabled
				}

				Object.Enabled = false
			end
		end

		Lighting.GlobalShadows = false

		for _,Object in ipairs(
			Lighting:GetChildren()
		) do

			if Object:IsA("PostEffect") then

				LowGFXBackup[Object] = {
					Enabled =
						Object.Enabled
				}

				Object.Enabled = false
			end
		end

	else

		for Object,Data in pairs(
			LowGFXBackup
		) do

			if Object and Object.Parent then

				for Property,Value in pairs(Data) do

					pcall(function()
						Object[Property] = Value
					end)
				end
			end
		end

		LowGFXBackup = {}

		Lighting.GlobalShadows = true
	end
end

local function LowGFXPage()

	ClearContent()
	Activate(LowGFXTab)
	SetScrollHeight(320)

	Label(
		Content,
		"LOW GFX",
		UDim2.fromOffset(10,5),
		UDim2.fromOffset(300,28),
		18
	).TextColor3 = RED2

	Label(
		Content,
		"PERFORMANCE MODE",
		UDim2.fromOffset(10,34),
		UDim2.fromOffset(250,18),
		8
	).TextColor3 = GRAY

	Toggle(
		Content,
		"LOW GRAPHICS",
		UDim2.fromOffset(10,62),
		Config.LowGFX,
		function(Value)

			SetLowGFX(Value)
		end
	)

	Label(
		Content,
		"LOW GFX FEATURES",
		UDim2.fromOffset(10,125),
		UDim2.fromOffset(200,20),
		8
	).TextColor3 = GRAY

	Label(
		Content,
		"◆ Remove textures",
		UDim2.fromOffset(10,153),
		UDim2.fromOffset(250,20),
		10
	)

	Label(
		Content,
		"◆ Smooth materials",
		UDim2.fromOffset(10,180),
		UDim2.fromOffset(250,20),
		10
	)

	Label(
		Content,
		"◆ Disable particles",
		UDim2.fromOffset(10,207),
		UDim2.fromOffset(250,20),
		10
	)

	Label(
		Content,
		"◆ Disable post effects",
		UDim2.fromOffset(10,234),
		UDim2.fromOffset(250,20),
		10
	)

	Label(
		Content,
		"◆ Disable global shadows",
		UDim2.fromOffset(10,261),
		UDim2.fromOffset(280,20),
		10
	).TextColor3 = RED2
end

--========================================================--
-- SETTINGS
--========================================================--

local function SettingsPage()

	ClearContent()
	Activate(SettingsTab)
	SetScrollHeight(280)

	Label(
		Content,
		"SETTINGS",
		UDim2.fromOffset(10,5),
		UDim2.fromOffset(300,28),
		18
	).TextColor3 = RED2

	Label(
		Content,
		"NEXUS PREMIUM V6",
		UDim2.fromOffset(10,45),
		UDim2.fromOffset(300,25),
		14
	).TextColor3 = RED2

	Label(
		Content,
		"Mobile optimized interface",
		UDim2.fromOffset(10,72),
		UDim2.fromOffset(300,20),
		9
	).TextColor3 = GRAY

	local Reset =
		Button(
			Content,
			"RESET UI",
			UDim2.fromOffset(10,115),
			UDim2.fromOffset(350,42)
		)

	Reset.Activated:Connect(
		function()

			if not CanUIAction() then
				return
			end

			HomePage()
		end
	)

	Label(
		Content,
		"SYSTEM STATUS",
		UDim2.fromOffset(10,185),
		UDim2.fromOffset(200,20),
		8
	).TextColor3 = GRAY

	Label(
		Content,
		"AIM  •  "..(
			Config.AimEnabled
			and "ON"
			or "OFF"
		),
		UDim2.fromOffset(10,215),
		UDim2.fromOffset(250,20),
		10
	).TextColor3 =
		Config.AimEnabled
		and GREEN
		or RED2

	Label(
		Content,
		"ESP  •  "..(
			Config.ESPEnabled
			and "ON"
			or "OFF"
		),
		UDim2.fromOffset(10,242),
		UDim2.fromOffset(250,20),
		10
	).TextColor3 =
		Config.ESPEnabled
		and GREEN
		or RED2
end

--========================================================--
-- TAB EVENTS
--========================================================--

local function SafePageChange(PageFunction)

	if not CanUIAction() then
		return
	end

	PageFunction()

	-- Mantém a proteção por mais um instante para que o
	-- toque que abriu a aba não seja reaproveitado.
	task.delay(.08,function()
		UIInputLocked = true

		task.delay(.12,function()
			UIInputLocked = false
		end)
	end)
end

HomeTab.Activated:Connect(function()
	SafePageChange(HomePage)
end)

AimTab.Activated:Connect(function()
	SafePageChange(AimPage)
end)

VisualTab.Activated:Connect(function()
	SafePageChange(VisualPage)
end)

PlayerTab.Activated:Connect(function()
	SafePageChange(PlayerPage)
end)

LowGFXTab.Activated:Connect(function()
	SafePageChange(LowGFXPage)
end)

SettingsTab.Activated:Connect(function()
	SafePageChange(SettingsPage)
end)

--========================================================--
-- OPEN BUTTON
--========================================================--

local OpenButton =
	Instance.new("TextButton")

OpenButton.Size =
	UDim2.fromOffset(62,62)

OpenButton.Position =
	UDim2.new(0,18,.5,-31)

OpenButton.BackgroundColor3 = BG
OpenButton.BorderSizePixel = 0

OpenButton.Text = "N"
OpenButton.TextColor3 = RED2
OpenButton.TextSize = 28
OpenButton.Font = Enum.Font.GothamBlack

OpenButton.AutoButtonColor = false

OpenButton.ZIndex = 50
OpenButton.Parent = Gui

Corner(OpenButton,999)
Stroke(OpenButton,RED,2)

OpenButton.Activated:Connect(
	function()

		if not CanUIAction() then
			return
		end

		Hub.Visible =
			not Hub.Visible

		if Hub.Visible then
			HomePage()
		end
	end
)

--========================================================--
-- DRAG HUB
--========================================================--

local DragHub = false
local DragStart
local HubStart

TopBar.InputBegan:Connect(
	function(Input)

		if Input.UserInputType ==
			Enum.UserInputType.Touch

			or Input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			DragHub = true
			DragStart = Input.Position
			HubStart = Hub.Position
		end
	end
)

UserInputService.InputChanged:Connect(
	function(Input)

		if not DragHub then
			return
		end

		if Input.UserInputType ==
			Enum.UserInputType.Touch

			or Input.UserInputType ==
			Enum.UserInputType.MouseMovement then

			local Delta =
				Input.Position-DragStart

			Hub.Position =
				UDim2.new(
					HubStart.X.Scale,
					HubStart.X.Offset+Delta.X,

					HubStart.Y.Scale,
					HubStart.Y.Offset+Delta.Y
				)
		end
	end
)

UserInputService.InputEnded:Connect(
	function(Input)

		if Input.UserInputType ==
			Enum.UserInputType.Touch

			or Input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			DragHub = false
		end
	end
)

--========================================================--
-- DRAG OPEN BUTTON
--========================================================--

local DragButton = false
local ButtonStart
local ButtonPosition

OpenButton.InputBegan:Connect(
	function(Input)

		if Input.UserInputType ==
			Enum.UserInputType.Touch

			or Input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			DragButton = true
			ButtonStart = Input.Position
			ButtonPosition = OpenButton.Position
		end
	end
)

UserInputService.InputChanged:Connect(
	function(Input)

		if not DragButton then
			return
		end

		if Input.UserInputType ==
			Enum.UserInputType.Touch

			or Input.UserInputType ==
			Enum.UserInputType.MouseMovement then

			local Delta =
				Input.Position-ButtonStart

			OpenButton.Position =
				UDim2.new(
					ButtonPosition.X.Scale,
					ButtonPosition.X.Offset+Delta.X,

					ButtonPosition.Y.Scale,
					ButtonPosition.Y.Offset+Delta.Y
				)
		end
	end
)

UserInputService.InputEnded:Connect(
	function(Input)

		if Input.UserInputType ==
			Enum.UserInputType.Touch

			or Input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			DragButton = false
		end
	end
)

--========================================================--
-- PLAYER EVENTS
--========================================================--

Players.PlayerAdded:Connect(
	function(Player)

		Player.CharacterAdded:Connect(
			function()

				task.wait(.5)

				if Config.ESPEnabled then
					CreateESP(Player)
				end
			end
		)

		-- NÃO recria mais a AimPage aqui.
		-- Isso evitava que a interface mudasse durante um toque.
	end
)

Players.PlayerRemoving:Connect(
	function(Player)

		ExcludedPlayers[Player] = nil
		RemoveESP(Player)

		-- NÃO chama AimPage().
		-- A lista atual será atualizada quando a aba for aberta novamente.
	end
)

LocalPlayer.CharacterAdded:Connect(
	function()

		task.wait(.5)

		ApplyWalkSpeed()
		UpdateSpin()
	end
)

--========================================================--
-- INITIAL
--========================================================--

UpdateFOV()
UpdateESP()
ApplyWalkSpeed()

HomePage()

--========================================================--
-- NEXUS LOADING SCREEN
--========================================================--

local Loading = Instance.new("Frame")

Loading.Name = "NexusLoading"
Loading.Size = UDim2.fromScale(1,1)
Loading.Position = UDim2.fromScale(0,0)

Loading.BackgroundColor3 =
	Color3.fromRGB(3,3,5)

Loading.BorderSizePixel = 0
Loading.ZIndex = 1000
Loading.Active = true
Loading.Parent = Gui

--========================================================--
-- NEXUS
--========================================================--

local LoadingTitle = Instance.new("TextLabel")

LoadingTitle.Name = "NexusTitle"
LoadingTitle.Parent = Loading

LoadingTitle.BackgroundTransparency = 1

LoadingTitle.Position =
	UDim2.new(0,0,.5,-100)

LoadingTitle.Size =
	UDim2.new(1,0,0,65)

LoadingTitle.Text = "neXus"

LoadingTitle.TextColor3 = RED2
LoadingTitle.TextSize = 46
LoadingTitle.Font = Enum.Font.GothamBlack

LoadingTitle.TextXAlignment =
	Enum.TextXAlignment.Center

LoadingTitle.TextYAlignment =
	Enum.TextYAlignment.Center

LoadingTitle.TextStrokeTransparency = .65
LoadingTitle.TextStrokeColor3 = RED_DARK

LoadingTitle.ZIndex = 1005

--========================================================--
-- FRASE
--========================================================--

local LoadingSub = Instance.new("TextLabel")

LoadingSub.Name = "NexusSlogan"
LoadingSub.Parent = Loading

LoadingSub.BackgroundTransparency = 1

LoadingSub.Position =
	UDim2.new(0,0,.5,-38)

LoadingSub.Size =
	UDim2.new(1,0,0,32)

LoadingSub.Text =
	"Quem não xita não brilha 🌟"

LoadingSub.TextColor3 = WHITE
LoadingSub.TextSize = 16
LoadingSub.Font = Enum.Font.GothamBold

LoadingSub.TextXAlignment =
	Enum.TextXAlignment.Center

LoadingSub.TextYAlignment =
	Enum.TextYAlignment.Center

LoadingSub.ZIndex = 1005

--========================================================--
-- PORCENTAGEM
--========================================================--

local LoadingPercent = Instance.new("TextLabel")

LoadingPercent.Name = "LoadingPercent"
LoadingPercent.Parent = Loading

LoadingPercent.BackgroundTransparency = 1

LoadingPercent.Position =
	UDim2.new(0,0,.5,4)

LoadingPercent.Size =
	UDim2.new(1,0,0,25)

LoadingPercent.Text = "0%"

LoadingPercent.TextColor3 = RED2
LoadingPercent.TextSize = 13
LoadingPercent.Font = Enum.Font.GothamBold

LoadingPercent.TextXAlignment =
	Enum.TextXAlignment.Center

LoadingPercent.TextYAlignment =
	Enum.TextYAlignment.Center

LoadingPercent.ZIndex = 1005

--========================================================--
-- ÚNICA BARRA
--========================================================--

local LoadingBar = Instance.new("Frame")

LoadingBar.Name = "LoadingBar"
LoadingBar.Parent = Loading

LoadingBar.Size =
	UDim2.fromOffset(300,8)

LoadingBar.Position =
	UDim2.new(.5,-150,.5,43)

LoadingBar.BackgroundColor3 =
	Color3.fromRGB(28,28,33)

LoadingBar.BorderSizePixel = 0
LoadingBar.ZIndex = 1005

Corner(LoadingBar,999)

local LoadingFill = Instance.new("Frame")

LoadingFill.Name = "Fill"
LoadingFill.Parent = LoadingBar

LoadingFill.Size =
	UDim2.new(0,0,1,0)

LoadingFill.BackgroundColor3 = RED2
LoadingFill.BorderSizePixel = 0
LoadingFill.ZIndex = 1006

Corner(LoadingFill,999)

--========================================================--
-- CARREGAMENTO
--========================================================--

Hub.Visible = false
OpenButton.Visible = false
FOVCircle.Visible = false

task.spawn(function()

	for I = 0,100 do

		local Progress =
			I / 100

		LoadingPercent.Text =
			tostring(I).."%"

		LoadingFill.Size =
			UDim2.new(
				Progress,
				0,
				1,
				0
			)

		task.wait(.025)
	end

	LoadingPercent.Text = "100%"

	task.wait(.35)

	Tween(
		Loading,
		.45,
		{
			BackgroundTransparency = 1
		}
	):Play()

	Tween(
		LoadingTitle,
		.45,
		{
			TextTransparency = 1
		}
	):Play()

	Tween(
		LoadingSub,
		.45,
		{
			TextTransparency = 1
		}
	):Play()

	Tween(
		LoadingPercent,
		.45,
		{
			TextTransparency = 1
		}
	):Play()

	Tween(
		LoadingBar,
		.45,
		{
			BackgroundTransparency = 1
		}
	):Play()

	Tween(
		LoadingFill,
		.45,
		{
			BackgroundTransparency = 1
		}
	):Play()

	task.wait(.5)

	Loading:Destroy()

	Hub.Visible = true
	OpenButton.Visible = true

	UpdateFOV()
	HomePage()
end)

--========================================================--
-- END NEXUS PREMIUM V6
--========================================================--
