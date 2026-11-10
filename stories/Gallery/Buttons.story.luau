local foundation = require("../foundation")
local VF = foundation.VF

local VARIANTS = { "Emphasis", "SoftEmphasis", "Standard", "Alert", "Utility", "Link" }
local SIZES = { "XSmall", "Small", "Medium", "Large" }

return {
	summary = "Button variants and sizes, IconButton and ButtonGroup",
	vide = foundation.Vide,
	controls = foundation.controls({
		isDisabled = false,
		isLoading = false,
		inputDelay = 0,
		icon = "",
	}),
	story = function(props: { controls: { [string]: any } })
		local controls = props.controls
		local function icon(): string?
			local name = controls.icon()
			return if name == "" then nil else name
		end

		return foundation.story(props, function()
			local rows = {}
			for row, size in SIZES do
				local buttons = {}
				for column, variant in VARIANTS do
					table.insert(
						buttons,
						VF.Button({
							text = variant,
							variant = variant :: any,
							size = size :: any,
							icon = icon,
							isDisabled = controls.isDisabled,
							isLoading = controls.isLoading,
							onActivated = foundation.action(`{variant} {size}`),
							LayoutOrder = column,
						})
					)
				end
				table.insert(
					buttons,
					VF.IconButton({
						icon = "heart",
						size = size :: any,
						onActivated = foundation.action("IconButton"),
						LayoutOrder = 99,
					})
				)
				table.insert(
					rows,
					VF.View({ tag = "auto-xy row gap-medium align-y-center", LayoutOrder = row, children = buttons })
				)
			end

			table.insert(
				rows,
				VF.Button({
					text = "Delayed",
					variant = "Emphasis",
					inputDelay = controls.inputDelay,
					onActivated = foundation.action("Delayed"),
					LayoutOrder = 10,
				})
			)
			return rows
		end)
	end,
}
