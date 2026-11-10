local Vide = require("../../Packages/Vide")

local BottomSheet = require("./BottomSheet")
local CenterSheet = require("./CenterSheet")
local SheetType = require("./SheetType")
local SheetTypes = require("./Types")
local SideSheet = require("./SideSheet")
local Value = require("../../Utility/Value")
local Wrappers = require("../../Utility/Wrappers")
local useScreen = require("../../Providers/Overlay/useScreen")
local withDefaults = require("../../Utility/withDefaults")

local GuiService = Wrappers.Services.GuiService

type SheetType = SheetType.SheetType
export type SheetProps = SheetTypes.SheetProps

local defaultProps = {
	testId = "--foundation-sheet",
}

--- A modal panel: a bottom sheet on small portrait screens, otherwise a side sheet (or a center sheet with
--- `preferCenterSheet`). It renders into the overlay and returns nothing. Setting `isOpen` to false plays the
--- close animation; `onClose` runs when it ends.
local function Sheet(sheetProps: SheetProps)
	local props = withDefaults(sheetProps, defaultProps)
	local function isOpenProp(): boolean?
		return Value.read(props.isOpen)
	end

	local isOpen = Vide.source(Vide.untrack(function()
		local value = isOpenProp()
		return if value == nil then true else value
	end))
	local screen = useScreen()
	local isLandscape = Vide.source(Vide.untrack(function()
		local current = screen()
		return if current then current.AbsoluteSize.X > current.AbsoluteSize.Y else true
	end))
	local displaySize = Vide.source(GuiService.ViewportDisplaySize)

	local close: (() -> ())? = nil
	local function setClose(value: () -> ())
		close = value
	end
	if props.sheetRef then
		props.sheetRef({
			close = function()
				if close then
					close()
				end
			end,
		})
	end

	Vide.effect(function()
		local value = isOpenProp()
		Vide.untrack(function()
			if value == false and isOpen() and close then
				close()
			elseif value then
				isOpen(true)
			end
		end)
	end)

	Vide.cleanup(GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(function()
		displaySize(GuiService.ViewportDisplaySize)
	end))

	Vide.effect(function()
		local current = screen()
		if not current then
			return
		end
		local function update()
			isLandscape(current.AbsoluteSize.X > current.AbsoluteSize.Y)
		end
		Vide.untrack(update)
		Vide.cleanup(current:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
	end)

	local function sheetType(): SheetType
		if displaySize() == Enum.DisplaySize.Small and not isLandscape() then
			return SheetType.Bottom
		elseif Value.read(props.preferCenterSheet) then
			return SheetType.Center
		end
		return SheetType.Side
	end

	local function onClose()
		close = nil
		if props.onClose then
			props.onClose()
		end
		isOpen(false)
		--* Opens again when the prop still asks for it.
		if isOpenProp() then
			isOpen(true)
		end
	end

	local function childProps(): any
		local result: any = table.clone(props)
		result.isOpen = nil
		result.sheetRef = nil
		result.onClose = onClose
		result.setClose = setClose
		result.displaySize = function()
			return displaySize()
		end
		return result
	end

	Vide.show(function()
		return isOpen()
	end, function()
		return Vide.switch(sheetType)({
			[SheetType.Bottom] = function()
				BottomSheet(childProps())
				return nil
			end,
			[SheetType.Center] = function()
				CenterSheet(childProps())
				return nil
			end,
			[SheetType.Side] = function()
				SideSheet(childProps())
				return nil
			end,
		})
	end)
end

return Sheet
