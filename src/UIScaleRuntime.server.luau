--!strict

--> Services
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

--> Constants
local DEFAULT_RESOLUTION = Vector2.new(1280, 720)
local DEFAULT_SCALE_RANGE = NumberRange.new(0, math.huge)
local DEFAULT_MULTIPLIER = 1

--> Types
type ScaleInfo = {
	source: Instance,
	signal: RBXScriptConnection,
	textConstraints: { UITextSizeConstraint },
}

type Params = {
	Resolution: Vector2,
	ScaleRange: NumberRange,
	Multiplier: number,
}

--> Variables
local scaleInfoMap = {} :: { [UIScale]: ScaleInfo }

--> Helper Functions
local function getViewportSize(gui: GuiBase2d?): Vector2
	if not gui or (gui:IsA("ScreenGui") and (gui.IgnoreGuiInset or gui.ScreenInsets == Enum.ScreenInsets.None)) then
		return workspace.CurrentCamera.ViewportSize
	end

	return gui.AbsoluteSize
end

local function calculateScale(size: Vector2, params: Params): number
	local axis = math.min(size.X, size.Y)
	local reference = (1 / params.Resolution.Y)
		* math.clamp((1 / params.Resolution.X * size.X) / (1 / params.Resolution.Y * axis), 0, 1)

	local baseScale = math.clamp(reference * axis, params.ScaleRange.Min, params.ScaleRange.Max)

	return baseScale * params.Multiplier
end

local function getScaleParams(scale: UIScale): Params
	local resolution = scale:GetAttribute("Resolution")
	local scaleRange = scale:GetAttribute("ScaleRange")
	local multiplier = scale:GetAttribute("Multiplier")

	return {
		Resolution = typeof(resolution) == "Vector2" and resolution or DEFAULT_RESOLUTION,
		ScaleRange = typeof(scaleRange) == "NumberRange" and scaleRange or DEFAULT_SCALE_RANGE,
		Multiplier = typeof(multiplier) == "number" and multiplier or DEFAULT_MULTIPLIER,
	}
end

--> Main Functions
local function updateScale(scale: UIScale)
	if
		not scale:IsA("UIScale")
		or (scale:IsDescendantOf(StarterGui) and RunService:IsRunning())
		or not scale.Parent
	then
		return
	end

	local params = getScaleParams(scale)
	local gui = scale.Parent:FindFirstAncestorWhichIsA("GuiBase2d")
	local size = getViewportSize(gui)

	scale.Scale = calculateScale(size, params)
	local scaleInfo = scaleInfoMap[scale]

	if scaleInfo then
		for _, constraint in scaleInfo.textConstraints do
			local refRange = constraint:GetAttribute("ReferenceRange")
			if typeof(refRange) == "NumberRange" then
				constraint.MinTextSize = refRange.Min * scale.Scale
				constraint.MaxTextSize = refRange.Max * scale.Scale
			end
		end
	end
end

local function setupScaleInfo(scale: UIScale)
	if scaleInfoMap[scale] or not scale.Parent then
		return
	end

	local gui = scale.Parent:FindFirstAncestorWhichIsA("GuiBase2d")
	if not gui then
		return
	end

	local source = gui:IsA("ScreenGui") and workspace.CurrentCamera or gui
	local scaleInfo = {
		source = source,
		textConstraints = {},

		signal = RunService.Heartbeat:Connect(function()
			updateScale(scale)
		end),
	}

	local function addTextConstraint(constraint: UITextSizeConstraint)
		table.insert(scaleInfo.textConstraints, constraint)

		if not constraint:GetAttribute("ReferenceRange") then
			constraint:SetAttribute("ReferenceRange", NumberRange.new(constraint.MinTextSize, constraint.MaxTextSize))
		end
	end

	for _, desc in gui:GetDescendants() do
		if desc:IsA("UITextSizeConstraint") then
			addTextConstraint(desc)
		end
	end

	gui.DescendantAdded:Connect(function(desc)
		if desc:IsA("UITextSizeConstraint") then
			addTextConstraint(desc)
		end
	end)

	scaleInfoMap[scale] = scaleInfo
end

local function cleanupScale(scale: UIScale)
	local scaleInfo = scaleInfoMap[scale]

	if scaleInfo then
		scaleInfo.signal:Disconnect()
		scaleInfoMap[scale] = nil
	end

	scale.Scale = 1
end

--> Event Connections
CollectionService:GetInstanceAddedSignal("UIScaleRuntimeObject"):Connect(function(scale)
	if scale:IsA("UIScale") then
		setupScaleInfo(scale)
		updateScale(scale)
	end
end)

CollectionService:GetInstanceRemovedSignal("UIScaleRuntimeObject"):Connect(cleanupScale)

--> Initial Update
for _, scale in CollectionService:GetTagged("UIScaleRuntimeObject") do
	if scale:IsA("UIScale") then
		setupScaleInfo(scale)
		updateScale(scale)
	end
end
