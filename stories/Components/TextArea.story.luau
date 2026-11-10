local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local InputFocusBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputFocusBehavior")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local InputVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputVariant")

type ColorStyleValue = VideFoundation.ColorStyleValue
type TextInputRef = Types.TextInputRef

local function PlaygroundStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()
	local text = Vide.source("")
	local textBoxRef: TextInputRef? = nil

	local function gainFocus()
		if textBoxRef then
			textBoxRef.focus()
		end
	end

	return VF.View({
		tag = "col gap-large auto-xy padding-xlarge",
		children = {
			--* focusBehavior is a plain prop, so a change builds the input again.
			foundation.rebuildOn(controls.focusBehavior, function(focusBehavior: string)
				return VF.TextArea({
					LayoutOrder = 1,
					hasError = controls.hasError,
					isDisabled = controls.isDisabled,
					isRequired = foundation.orNil(controls.isRequired),
					variant = controls.variant,
					focusBehavior = if focusBehavior ~= foundation.NONE then focusBehavior :: any else nil,
					onChanged = function(newText: string)
						text(newText)
					end,
					label = controls.label,
					hint = controls.hint,
					size = controls.size,
					width = function(): any
						local width: number = controls.width()
						return if width == 0 then nil else UDim.new(0, width)
					end,
					hasClearButton = foundation.orNil(controls.hasClearButton),
					numLines = controls.numLines,
					placeholder = controls.placeholder,
					text = text,
					textBoxRef = function(ref: TextInputRef)
						textBoxRef = ref
					end,
				})
			end),
			VF.Text({
				LayoutOrder = 2,
				Text = text,
				textStyle = function(): ColorStyleValue
					return tokens().Color.System.Alert :: ColorStyleValue
				end,
				tag = "size-full-0 auto-y text-wrap text-align-x-left",
			}),
			VF.Button({
				LayoutOrder = 3,
				text = "Focus TextArea",
				onActivated = gainFocus,
				variant = ButtonVariant.Standard,
			}),
		},
	})
end

return foundation.sections({
	summary = "TextArea",
	controls = {
		hasError = false,
		isDisabled = false,
		numLines = 4,
		variant = UILabs.Choose(Dash.values(InputVariant :: any)),
		focusBehavior = UILabs.Choose({ foundation.NONE, table.unpack(Dash.values(InputFocusBehavior :: any)) }),
		hasClearButton = UILabs.Choose({ foundation.NONE, false, true } :: { any }),
		width = 0,
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		label = "Biography",
		hint = "1000 characters maximum",
		placeholder = "Tell us your life story!",
		isRequired = UILabs.Choose({ foundation.NONE, false, true } :: { any }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
	},
})
