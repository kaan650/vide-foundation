--!nocheck
-- Mounts a Vide port and the React original side by side in StarterGui and diffs their instance trees: class, name,
-- tags and the effective (styled) value of every compared property. Used from Studio MCP execute_luau, Edit mode.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Compare = {}

local PROPERTIES = {
	GuiObject = {
		"Visible", "Size", "Position", "AnchorPoint", "AutomaticSize", "LayoutOrder", "ZIndex", "Rotation",
		"BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "ClipsDescendants", "Active", "Interactable",
		"AbsoluteSize", "AbsolutePosition",
	},
	CanvasGroup = { "GroupTransparency" },
	TextLabel = {
		"Text", "TextColor3", "TextTransparency", "TextSize", "FontFace", "LineHeight", "RichText", "TextWrapped",
		"TextTruncate", "TextXAlignment", "TextYAlignment", "TextScaled",
	},
	TextButton = {
		"Text", "TextColor3", "TextTransparency", "TextSize", "FontFace", "LineHeight", "RichText", "TextWrapped",
		"TextTruncate", "TextXAlignment", "TextYAlignment", "TextScaled", "AutoButtonColor",
	},
	TextBox = {
		"Text", "TextColor3", "TextTransparency", "TextSize", "FontFace", "PlaceholderText", "PlaceholderColor3",
		"TextXAlignment", "TextYAlignment", "ClearTextOnFocus", "MultiLine", "TextEditable",
	},
	ImageLabel = {
		"ImageContent", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType",
		"SliceCenter", "SliceScale",
	},
	ImageButton = {
		"ImageContent", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType",
		"SliceCenter", "SliceScale", "AutoButtonColor",
	},
	ScrollingFrame = { "CanvasSize", "AutomaticCanvasSize", "ScrollBarThickness", "ScrollingDirection", "ScrollingEnabled" },
	UICorner = { "CornerRadius", "TopLeftRadius", "TopRightRadius", "BottomLeftRadius", "BottomRightRadius" },
	UIStroke = { "Color", "Thickness", "Transparency", "ApplyStrokeMode", "LineJoinMode", "BorderStrokePosition" },
	UIPadding = { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" },
	UIListLayout = {
		"FillDirection", "HorizontalAlignment", "VerticalAlignment", "HorizontalFlex", "VerticalFlex", "Padding",
		"SortOrder", "Wraps", "ItemLineAlignment",
	},
	UIFlexItem = { "FlexMode", "GrowRatio", "ShrinkRatio", "ItemLineAlignment" },
	UISizeConstraint = { "MinSize", "MaxSize" },
	UIAspectRatioConstraint = { "AspectRatio", "AspectType", "DominantAxis" },
	UIScale = { "Scale" },
	UIGradient = { "Color", "Transparency", "Rotation", "Offset", "Enabled" },
	Path2D = { "Color3", "Thickness", "Visible", "ZIndex" },
}

local function propertiesOf(instance: Instance): { string }
	local list = {}
	local seen = {}
	for class, names in PROPERTIES do
		if instance:IsA(class) then
			for _, name in names do
				if not seen[name] then
					seen[name] = true
					table.insert(list, name)
				end
			end
		end
	end
	table.sort(list)
	return list
end

local function read(instance: Instance, property: string, origin: Vector2): any
	local ok, value = pcall(function()
		if property == "AbsolutePosition" then
			return (instance :: any).AbsolutePosition - origin
		elseif property == "AbsoluteSize" then
			return (instance :: any).AbsoluteSize
		end
		return instance:GetStyled(property)
	end)
	if not ok then
		ok, value = pcall(function()
			return (instance :: any)[property]
		end)
	end
	return if ok then value else "<unreadable>"
end

local function format(value: any): string
	if typeof(value) == "Vector2" then
		return string.format("(%.1f, %.1f)", value.X, value.Y)
	elseif typeof(value) == "Color3" then
		return string.format("rgb(%d, %d, %d)", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
	elseif typeof(value) == "number" then
		return string.format("%.4g", value)
	end
	return tostring(value)
end

local function equal(a: any, b: any): boolean
	if typeof(a) ~= typeof(b) then
		return false
	elseif typeof(a) == "number" then
		return math.abs(a - b) < 1e-3
	elseif typeof(a) == "Vector2" then
		return (a - b).Magnitude < 0.6
	elseif typeof(a) == "Color3" then
		return math.abs(a.R - b.R) < 2e-3 and math.abs(a.G - b.G) < 2e-3 and math.abs(a.B - b.B) < 2e-3
	end
	return a == b
end

local function sortedTags(instance: Instance): string
	local tags = instance:GetTags()
	table.sort(tags)
	return table.concat(tags, " ")
end

local IGNORED_CHILDREN = { StyleLink = true, StyleSheet = true, Folder = true }

local function childrenOf(instance: Instance): { Instance }
	local list = {}
	for _, child in instance:GetChildren() do
		if not IGNORED_CHILDREN[child.ClassName] and child.Name ~= "FoundationCursorContainer" then
			table.insert(list, child)
		end
	end
	table.sort(list, function(a, b)
		local la = if a:IsA("GuiObject") then a.LayoutOrder else 0
		local lb = if b:IsA("GuiObject") then b.LayoutOrder else 0
		if la ~= lb then
			return la < lb
		elseif a.ClassName ~= b.ClassName then
			return a.ClassName < b.ClassName
		end
		return a.Name < b.Name
	end)
	return list
end

local function diff(vide: Instance, react: Instance, path: string, origins: { Vector2 }, out: { string }, options)
	if vide.ClassName ~= react.ClassName then
		table.insert(out, `{path}: class {vide.ClassName} vs {react.ClassName}`)
		return
	end
	if vide.Name ~= react.Name and not options.ignoreNames then
		table.insert(out, `{path}: name {vide.Name} vs {react.Name}`)
	end
	local videTags, reactTags = sortedTags(vide), sortedTags(react)
	if videTags ~= reactTags then
		table.insert(out, `{path}: tags [{videTags}] vs [{reactTags}]`)
	end
	for _, property in propertiesOf(vide) do
		if options.ignore and options.ignore[property] then
			continue
		end
		local a, b = read(vide, property, origins[1]), read(react, property, origins[2])
		if not equal(a, b) then
			table.insert(out, `{path}.{property}: {format(a)} vs {format(b)}`)
		end
	end

	local videChildren, reactChildren = childrenOf(vide), childrenOf(react)
	if #videChildren ~= #reactChildren then
		local names = function(list)
			local n = {}
			for _, c in list do
				table.insert(n, `{c.ClassName}:{c.Name}`)
			end
			return table.concat(n, ", ")
		end
		table.insert(out, `{path}: children [{names(videChildren)}] vs [{names(reactChildren)}]`)
	end
	for i = 1, math.min(#videChildren, #reactChildren) do
		local child = videChildren[i]
		diff(child, reactChildren[i], `{path}/{child.Name}`, origins, out, options)
	end
end

local function waitFrames(count: number)
	for _ = 1, count do
		RunService.Heartbeat:Wait()
	end
end

--- Mounts both sides and returns the diff report. `spec.vide(VF, Vide)` and `spec.react(F, React)` return the UI
--- to place inside each provider. `spec.size` sets each side's frame (default 600x400).
function Compare.run(spec)
	for _, name in { "VFCompare", "VFComparePackages" } do
		local old = StarterGui:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	if _G.VFCompareCleanup then
		pcall(_G.VFCompareCleanup)
		_G.VFCompareCleanup = nil
	end

	--* Fresh copies of the Vide packages, so changes Rojo just synced are used.
	local packages = ReplicatedStorage.Packages:Clone()
	packages.Name = "VFComparePackages"
	packages.Parent = ReplicatedStorage
	local Vide = require(packages.Vide)
	local VF = require(packages.VideFoundation)

	local index = ReplicatedStorage.ReferencePackages._Index
	local F = require(index.Foundation.Foundation)
	local React = require(index.Foundation.React)
	local ReactRoblox = require(index.Foundation.ReactRoblox)

	local size = spec.size or Vector2.new(600, 400)
	local gui = Instance.new("ScreenGui")
	gui.Name = "VFCompare"
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = StarterGui

	local function side(name: string, x: number): Frame
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = UDim2.fromOffset(size.X, size.Y)
		frame.Position = UDim2.fromOffset(x, 40)
		frame.BackgroundTransparency = 1
		frame.Parent = gui
		return frame
	end
	local videFrame = side("Vide", 20)
	local reactFrame = side("React", 40 + size.X)

	local colorMode = spec.colorMode or "Dark"
	local destroyVide = Vide.mount(function()
		return VF.FoundationProvider({
			colorMode = colorMode,
			children = function()
				return spec.vide(VF, Vide)
			end,
		})
	end, videFrame)

	local root = ReactRoblox.createRoot(reactFrame)
	root:render(React.createElement(F.FoundationProvider, { theme = colorMode }, {
		Content = spec.react(F, React),
	}))

	_G.VFCompareCleanup = function()
		destroyVide()
		root:unmount()
	end

	waitFrames(spec.frames or 6)
	if spec.before then
		spec.before(videFrame, reactFrame)
		waitFrames(spec.frames or 6)
	end

	local out = {}
	local videRoots, reactRoots = childrenOf(videFrame), childrenOf(reactFrame)
	if #videRoots ~= #reactRoots then
		table.insert(out, `roots: {#videRoots} vs {#reactRoots}`)
	end
	local options = { ignore = spec.ignore, ignoreNames = spec.ignoreNames }
	for i = 1, math.min(#videRoots, #reactRoots) do
		diff(
			videRoots[i],
			reactRoots[i],
			videRoots[i].Name,
			{ videFrame.AbsolutePosition, reactFrame.AbsolutePosition },
			out,
			options
		)
	end

	if not spec.keep then
		_G.VFCompareCleanup()
		_G.VFCompareCleanup = nil
		gui:Destroy()
		packages:Destroy()
	end

	if #out == 0 then
		return "MATCH"
	end
	return `{#out} differences\n` .. table.concat(out, "\n")
end

return Compare
