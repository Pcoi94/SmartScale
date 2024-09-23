--> Services
local Selection = game:GetService("Selection")
local StarterPlayer = game:GetService("StarterPlayer")
local TestService = game:GetService("TestService")

--> Plugin initialization
local plugin = (plugin or getfenv().PluginManager():CreatePlugin()) :: Plugin

--> Plugin metadata
local key = "SmartScale"
local version = "1.0"

--> UIScaleRuntime
local UIScaleRuntime = script.Parent.UIScaleRuntime

--> Create toolbar and button
local toolbar = plugin:CreateToolbar(key)
local button = toolbar:CreateButton("Menu", "Toggle Menu", "rbxassetid://78222782271233")

--> Create plugin menu
local menu = plugin:CreatePluginMenu(key, `Smart Scale`)
menu.Name = key

menu:AddNewAction("Credit", `{key}  •  v{version}`)
menu:AddSeparator()

--> Helper function to create menu actions
local function createAction(id: string, text: string, icon: string, callback: (PluginAction) -> ()): PluginAction
	local action = menu:AddNewAction(id, text, icon)

	action.Triggered:Connect(function()
		callback(action)
	end)

	return action
end

--> Function to scale an instance
local function scale(instance: Instance)
	if instance:IsA("UIScale") then
		instance:AddTag("UIScaleRuntimeObject")

		instance:SetAttribute("Multiplier", 1)
		instance:SetAttribute("Resolution", workspace.CurrentCamera.ViewportSize)
		instance:SetAttribute("ScaleRange", NumberRange.new(0, math.huge))
		return
	end

	local UIScale = instance:FindFirstChildOfClass("UIScale")

	if not UIScale or not UIScale:HasTag("UIScaleRuntimeObject") then
		UIScale = Instance.new("UIScale")
		UIScale:AddTag("UIScaleRuntimeObject")
	end

	UIScale:SetAttribute("Multiplier", 1)
	UIScale:SetAttribute("Resolution", workspace.CurrentCamera.ViewportSize)
	UIScale:SetAttribute("ScaleRange", NumberRange.new(0, math.huge))

	UIScale.Parent = instance
end

--> Action to initialize the UIScaleRuntime script
createAction("Initialize", `Insert Script "UIScaleRuntime"`, "rbxassetid://111270712950233", function()
	local clone = Instance.new("LocalScript")
	clone.Name = "UIScaleRuntime"

	clone.Source = UIScaleRuntime.Source
	clone:SetAttribute("version", version)

	clone.Parent = StarterPlayer.StarterPlayerScripts
	TestService:Warn(false, `[SmartScale]: Successfully Created UIScaleRuntime in StarterPlayerScripts.`)
end)

--> Button click handler
button.Click:Connect(function()
	local result = ""

	for index, value in Selection:Get() do
		if index > 5 then
			result = result:sub(1, #result - 2) .. " ....."
			break
		end
		result ..= `"{value}", `
	end

	result = result == "" and "<SELECTION>" or result:sub(1, #result - 2)

	--> Create dynamic action for scaling selected objects
	local action = createAction("Scale", `Scale: {result}`, "rbxassetid://128651732447741", function()
		local selection = Selection:Get()
		for _, value in selection do
			scale(value)
		end

		TestService:Warn(false, `[SmartScale]: Successfully Scaled {result}.`)
	end)

	menu:ShowAsync()
	action:Destroy()
end)

--> Cleanup on plugin unloading
plugin.Unloading:Once(function()
	toolbar:Destroy()
	menu:Destroy()

	script.Parent:Destroy()
end)
