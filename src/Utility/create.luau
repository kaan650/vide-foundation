local Vide = require("../Packages/Vide")

-- Vide 0.4.1 types only 19 classes in `create`; these types come from centau/vide#92 and #93.
--TODO: use Vide's own create type once a Vide release includes those PRs.
export type Instances = {
	Folder: Folder,
	ScreenGui: ScreenGui,
	SurfaceGui: SurfaceGui,
	BillboardGui: BillboardGui,

	Frame: Frame,
	CanvasGroup: CanvasGroup,
	ImageButton: ImageButton,
	ImageLabel: ImageLabel,
	ScrollingFrame: ScrollingFrame,
	TextBox: TextBox,
	TextButton: TextButton,
	TextLabel: TextLabel,
	VideoFrame: VideoFrame,
	ViewportFrame: ViewportFrame,
	Path2D: Path2D,

	UIAspectRatioConstraint: UIAspectRatioConstraint,
	UICorner: UICorner,
	UIGradient: UIGradient,
	UISizeConstraint: UISizeConstraint,
	UITextSizeConstraint: UITextSizeConstraint,
	UIScale: UIScale,
	UIPadding: UIPadding,
	UIStroke: UIStroke,
	UIFlexItem: UIFlexItem,
	UIShadow: UIShadow,
	UIDragDetector: UIDragDetector,

	UIGridLayout: UIGridLayout,
	UIListLayout: UIListLayout,
	UIPageLayout: UIPageLayout,
	UITableLayout: UITableLayout,

	Camera: Camera,
	WorldModel: WorldModel,

	StyleSheet: StyleSheet,
	StyleRule: StyleRule,
	StyleLink: StyleLink,
	StyleDerive: StyleDerive,
}

--- A writable property takes a value or a function returning one; an event takes a listener.
export type function Properties(instance: type?)
	local properties = types.newtable()

	while instance do
		for i, v in instance:properties() do
			local connector = v.read and v.read.tag == "table" and v.read:readproperty(types.singleton("Connect"))
			if connector then
				local params = connector:parameters().head
				if not params then
					continue
				end
				local listener = params[2]
				if not listener then
					continue
				end
				properties:setproperty(i, types.optional(listener))
			elseif v.write then
				properties:setproperty(
					i,
					types.optional(types.unionof(v.write, types.newfunction({}, { head = { v.write } })))
				)
			end
		end

		instance = instance:readparent()
	end

	properties:setindexer(types.number, types.any)

	return properties
end

type Create = <Name>(Name | keyof<Instances> | "") -> (Properties<index<Instances, Name>>) -> index<Instances, Name>

--- Vide.create with full types and without Vide's class defaults.
local function create(class: string)
	local construct = (Vide.create :: any)(class)
	return function(properties: { [any]: any })
		--! Vide's class defaults count as set in code and would block Foundation's style rules for those properties.
		--! The flag is global and the game's own UI may share this Vide, so it is off only for this call.
		local previous = Vide.defaults
		Vide.defaults = false
		local ok, result = pcall(construct, properties)
		Vide.defaults = previous
		if not ok then
			error(result, 0)
		end
		return result
	end
end

return (create :: any) :: Create
