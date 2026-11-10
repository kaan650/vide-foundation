local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local InputLabelSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputLabelSize")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local InternalTextInput = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/InternalTextInput")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")
local useTextInputVariants =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Components/TextInput/useTextInputVariants")

type InternalTextInputRef = Types.InternalTextInputRef

local function PlaygroundStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()
	local variantProps = Vide.derive(function()
		return useTextInputVariants(tokens(), controls.size())
	end)
	local function horizontalPadding(): UDim
		return variantProps().container.horizontalPadding
	end

	local text = Vide.source("")

	return VF.View({
		tag = "gap-large auto-xy padding-xlarge",
		children = VF.UNSTABLE.InputField({
			label = controls.label,
			size = controls.labelSize,
			hint = controls.hint,
			isDisabled = controls.isDisabled,
			input = function(textBoxRef: (InternalTextInputRef?) -> ())
				return InternalTextInput({
					textBoxRef = textBoxRef,
					text = text,
					hasError = controls.hasError,
					isDisabled = controls.isDisabled,
					size = controls.size,
					horizontalPadding = {
						left = horizontalPadding,
						right = horizontalPadding,
					},
					onChanged = function(newText: string)
						text(newText)
					end,
					placeholder = controls.placeholder,
				})
			end,
		}),
	})
end

return foundation.sections({
	summary = "Input field",
	controls = {
		label = "Field label",
		hint = "Hint",
		hasError = false,
		isDisabled = false,
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		labelSize = UILabs.Choose(Dash.values(InputLabelSize :: any)),
		placeholder = "Placeholder text",
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
	},
})
