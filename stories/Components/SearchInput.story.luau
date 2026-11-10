local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local InputVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputVariant")
local SearchInputShape = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/SearchInputShape")

type ColorStyleValue = VideFoundation.ColorStyleValue
type InputVariant = InputVariant.InputVariant
type TextInputRef = Types.TextInputRef

local function Story(controls: { [string]: any }, inputVariant: InputVariant)
	local text = Vide.source("")
	local tokens = VF.Hooks.useTokens()
	local ref: TextInputRef? = nil

	local function gainFocus()
		if ref and ref.focus then
			ref.focus()
		end
	end

	return VF.View({
		tag = "col gap-large auto-xy padding-xlarge",
		children = {
			VF.SearchInput({
				LayoutOrder = 1,
				text = text,
				placeholder = function()
					local placeholder: string = controls.placeholder()
					return if placeholder == "" then nil else placeholder
				end,
				hasClearButton = foundation.orNil(controls.hasClearButton),
				hasError = controls.hasError,
				isDisabled = controls.isDisabled,
				shape = controls.shape,
				variant = inputVariant,
				onChanged = function(newText: string)
					print(`[SearchInput] query changed: "{newText}"`)
					text(newText)
				end,
				onFocusGained = function()
					print("[SearchInput] focus gained!")
				end,
				onFocusLost = function(inputObject: InputObject?)
					print(
						"[SearchInput] focus lost!",
						if inputObject then `InputObject: {inputObject.UserInputType.Name}` else "no input object"
					)
				end,
				size = controls.size,
				width = function(): UDim?
					local width: number = controls.width()
					return if width == 0 then nil else UDim.new(0, width)
				end,
				textBoxRef = function(textBoxRef: TextInputRef)
					ref = textBoxRef
				end,
			}),
			VF.Text({
				LayoutOrder = 2,
				Text = text,
				textStyle = function(): ColorStyleValue
					return tokens().Color.System.Alert :: ColorStyleValue
				end,
				tag = "auto-xy",
			}),
			VF.Button({
				LayoutOrder = 3,
				text = "Focus SearchInput",
				onActivated = gainFocus,
				variant = ButtonVariant.Standard,
			}),
		},
	})
end

local sections: { foundation.Section } = {}
for _, inputVariant: InputVariant in { InputVariant.Standard, InputVariant.Contrast, InputVariant.Utility } do
	table.insert(sections, {
		name = inputVariant,
		story = function(controls)
			return Story(controls, inputVariant)
		end,
	})
end

return foundation.sections({
	summary = "Search input field with leading search icon",
	controls = {
		hasError = false,
		isDisabled = false,
		hasClearButton = UILabs.Choose({ foundation.NONE, false, true } :: { any }),
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		shape = UILabs.Choose(Dash.values(SearchInputShape :: any)),
		width = 0,
		placeholder = "",
	},
	sections = sections,
})
