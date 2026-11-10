local foundation = require("../foundation")
local StoryIcons = require("../Shared/StoryIcons")
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
type TextInputTrailingIcon = VideFoundation.TextInputTrailingIcon

local ICON_CONTROL_OPTIONS = StoryIcons.buildIconControlOptions()

local function PlaygroundStory(controls: { [string]: any })
	local text = Vide.source("")
	local numReturnPressed = Vide.source(0)
	local tokens = VF.Hooks.useTokens()
	local ref: TextInputRef? = nil

	local function buttonPress()
		print("press!")
	end

	local function gainFocus()
		if ref and ref.focus then
			ref.focus()
		end
	end

	local function onFocusGained()
		print("focus gained!")
	end

	local function onFocusLost(inputObject: InputObject?)
		print("focus lost!", if inputObject then `InputObject: {inputObject.UserInputType.Name}` else "no input object")
	end

	local function onReturnPressed()
		print("Return pressed!")
		numReturnPressed(numReturnPressed() + 1)
	end

	local function iconTrailing(): TextInputTrailingIcon?
		local trailingIcon = StoryIcons.parseIconControl(controls.iconTrailing())
		if trailingIcon == nil then
			return nil
		elseif controls.trailingButton() then
			return { name = trailingIcon, onActivated = buttonPress }
		end
		return trailingIcon
	end

	return VF.View({
		tag = "col gap-large auto-xy padding-xlarge",
		children = {
			--* focusBehavior and textInputType are plain props, so a change builds the input again.
			foundation.rebuildOn(function()
				return `{controls.focusBehavior()}/{controls.textInputType()}`
			end, function()
				local focusBehavior = foundation.orNil(controls.focusBehavior)()
				local textInputType = foundation.orNil(controls.textInputType)()
				return VF.TextInput({
					LayoutOrder = 1,
					text = text,
					textInputType = textInputType,
					focusBehavior = focusBehavior,
					hasClearButton = foundation.orNil(controls.hasClearButton),
					variant = controls.variant,
					hasError = controls.hasError,
					isDisabled = controls.isDisabled,
					isRequired = foundation.orNil(controls.isRequired),
					onChanged = function(newText: string)
						text(newText)
					end,
					onFocusGained = onFocusGained,
					onFocusLost = onFocusLost,
					onReturnPressed = onReturnPressed,
					label = controls.label,
					size = controls.size,
					width = function(): any
						local width: number = controls.width()
						return if width == 0 then nil else UDim.new(0, width)
					end,
					hint = function()
						local hint: string = controls.hint()
						return if hint == "" then nil else hint
					end,
					placeholder = controls.placeholder,
					leadingIcon = function()
						return StoryIcons.parseIconControl(controls.leadingIcon())
					end,
					iconTrailing = iconTrailing,
					textBoxRef = function(textBoxRef: TextInputRef)
						ref = textBoxRef
					end,
				})
			end),
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
				text = "Focus TextInput",
				onActivated = gainFocus,
				variant = ButtonVariant.Standard,
			}),
			VF.Text({
				LayoutOrder = 4,
				Text = function()
					return "Num return pressed: " .. tostring(numReturnPressed())
				end,
				textStyle = function(): ColorStyleValue
					return tokens().Color.Content.Emphasis :: ColorStyleValue
				end,
				tag = "auto-xy",
			}),
		},
	})
end

return foundation.sections({
	summary = "Text field",
	controls = {
		hasError = false,
		isDisabled = false,
		isRequired = UILabs.Choose({ foundation.NONE, false, true } :: { any }),
		focusBehavior = UILabs.Choose({ foundation.NONE, table.unpack(Dash.values(InputFocusBehavior :: any)) }),
		hasClearButton = UILabs.Choose({ foundation.NONE, false, true } :: { any }),
		--! Writing TextBox.TextInputType needs CoreGui's RobloxScript capability. Anywhere else a type other than nil
		--! errors, in Foundation's own story too.
		textInputType = UILabs.Choose({
			foundation.NONE,
			Enum.TextInputType.Default,
			Enum.TextInputType.Password,
			Enum.TextInputType.Number,
		} :: { any }),
		variant = UILabs.Choose(Dash.values(InputVariant :: any)),
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		label = "Input Label",
		hint = "Helper text goes here",
		placeholder = "Placeholder text",
		leadingIcon = UILabs.Choose(ICON_CONTROL_OPTIONS),
		iconTrailing = UILabs.Choose(ICON_CONTROL_OPTIONS),
		trailingButton = false,
		width = 0,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
	},
})
