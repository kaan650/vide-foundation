local create = require("../../Utility/create")
local withInteractable = require("./withInteractable")

export type InteractableProps = {
	-- The class to create. Defaults to ImageButton.
	component: string?,
	-- Every other key is passed to the created instance.
	[any]: any,
} & withInteractable.WithInteractableProps

local OWN_KEYS = {
	component = true,
	isDisabled = true,
	onActivated = true,
	onSecondaryActivated = true,
	onStateChanged = true,
	stateLayer = true,
	cursor = true,
}

--- A GuiObject with Foundation's state layer: hover, press and selection tint its background.
local function Interactable(props: InteractableProps): GuiObject
	local properties: { [any]: any } = {}
	for key, value in props do
		if not OWN_KEYS[key] then
			properties[key] = value
		end
	end
	withInteractable(props, properties)
	return (create :: any)(props.component or "ImageButton")(properties)
end

return Interactable
