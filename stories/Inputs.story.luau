local foundation = require("./foundation")
local VF = foundation.VF
local Vide = foundation.Vide

return {
	summary = "Controlled inputs: TextInput, NumberInput, Checkbox, Toggle, Slider",
	vide = Vide,
	controls = foundation.controls({
		isDisabled = false,
		size = foundation.UILabs.Choose({ "Medium", "Small", "Large", "XSmall" }),
	}),
	story = function(props: { controls: { [string]: any } })
		local controls = props.controls
		local text = Vide.source("")
		local amount = Vide.source(5)
		local checked = Vide.source(true)
		local enabled = Vide.source(false)
		local volume = Vide.source(40)

		return foundation.story(props, function()
			return {
				VF.TextInput({
					text = text,
					onChanged = function(value)
						text(value)
					end,
					label = "Display name",
					placeholder = "Type here",
					hint = function()
						return `{#text()} characters`
					end,
					size = controls.size,
					isDisabled = controls.isDisabled,
					LayoutOrder = 1,
				}),
				VF.NumberInput({
					value = amount,
					onChanged = function(value)
						amount(value)
					end,
					label = "Amount",
					minimum = 0,
					maximum = 10,
					size = controls.size,
					isDisabled = controls.isDisabled,
					LayoutOrder = 2,
				} :: any),
				VF.Checkbox({
					label = "Remember me",
					isChecked = checked,
					onActivated = function(value)
						checked(value)
					end,
					size = controls.size,
					isDisabled = controls.isDisabled,
					LayoutOrder = 3,
				}),
				VF.Toggle({
					label = function()
						return if enabled() then "Notifications on" else "Notifications off"
					end,
					isChecked = enabled,
					onActivated = function(value)
						enabled(value)
					end,
					size = controls.size,
					isDisabled = controls.isDisabled,
					LayoutOrder = 4,
				}),
				VF.Slider({
					value = volume,
					range = NumberRange.new(0, 100),
					onValueChanged = function(value)
						volume(value)
					end,
					size = controls.size,
					isDisabled = controls.isDisabled,
					width = UDim.new(0, 300),
					LayoutOrder = 5,
				}),
				VF.Text({
					Text = function()
						return `text={text()} amount={amount()} checked={checked()} toggle={enabled()} volume={math.round(volume())}`
					end,
					tag = "auto-xy text-body-medium content-default",
					LayoutOrder = 6,
				}),
			}
		end)
	end,
}
