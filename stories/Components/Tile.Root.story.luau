local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

--* Plugin-only services: present in Studio, where UI Labs runs, and missing in a game.
local hasInsertService, insertService = pcall(function()
	return game:GetService("InsertService")
end)
local hasStudioService, studioService = pcall(function()
	return game:GetService("StudioService")
end)
local InsertService: InsertService? = if hasInsertService then insertService else nil
local StudioService: StudioService? = if hasStudioService then studioService else nil

local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs
local create = foundation.create

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local ColorMode = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ColorMode")
local ControlState = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ControlState")
local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local IconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/IconSize")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local MediaShape = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/MediaShape")
local MediaType = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/MediaType")
local Motion = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/Motion")
local TileHeader = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Tile/Header/TileHeader")

type ColorStyleValue = VideFoundation.ColorStyleValue
type ControlState = ControlState.ControlState
type TileTypography = TileHeader.TileTypography

local Tile = VF.UNSTABLE.Tile
local IconName = VF.Enums.IconName

local PLACE_TO_UNIVERSE: { [number]: number } = {
	[2727067538] = 985731078,
	[1537690962] = 601130232,
}

local playerTileSize = UDim2.fromOffset(150, 225)
local itemTileSize = UDim2.fromOffset(150, 240)
local experienceTileSize = UDim2.fromOffset(150, 250)
local wideTileSize = UDim2.fromOffset(300, 280)
local BORDER_OFFSET = UDim2.fromOffset(2, 2)

local PLAYER_COUNT = "82% 👍 92k 👤"
--* Foundation shows the loading state for two seconds before it fetches.
local FETCH_DELAY = 2
local FIELD_OF_VIEW = 70
local ROTATION_SPEED = 0.01
local SPRING_OPTIONS: Motion.SpringOptions = { frequency = 4 }

local buttons = {
	{
		icon = IconName.PersonClock,
		onActivated = function()
			print("Button Pressed")
		end,
		variant = ButtonVariant.SubEmphasis,
	},
}

type Tokens = () -> any
type ItemInfo = { Name: string?, PriceText: string? }

local function renderButtons()
	local children = {}
	for index, button in buttons do
		children[index] = VF.Button({
			onActivated = button.onActivated,
			variant = button.variant,
			size = InputSize.Medium,
			icon = button.icon,
			LayoutOrder = index,
		})
	end
	return children
end

local function PlayButton()
	return VF.Button({
		text = "Play",
		size = InputSize.Medium,
		variant = ButtonVariant.Emphasis,
		fillBehavior = FillBehavior.Fill,
		onActivated = function()
			print("play pressed!")
		end,
	})
end

local function getPlayerCount(tokens: Tokens)
	return VF.Text({
		textStyle = function(): ColorStyleValue
			return tokens().Color.Content.Default
		end,
		fontStyle = function()
			return tokens().Typography.TitleLarge
		end,
		Text = PLAYER_COUNT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
end

local function backgroundImage(tokens: Tokens, name: string): () -> string
	return function()
		local mode = if tokens().Config.ColorMode.Name == ColorMode.Dark then "dark" else "light"
		return `component_assets/{name}_{mode}`
	end
end

local function fetchLater(fetch: () -> ())
	local thread = task.spawn(function()
		task.wait(FETCH_DELAY)
		fetch()
	end)
	Vide.cleanup(function()
		if coroutine.status(thread) ~= "dead" then
			task.cancel(thread)
		end
	end)
end

local function useItem(itemId: () -> number): () -> ItemInfo
	local item = Vide.source({} :: ItemInfo)
	Vide.effect(function()
		local id = itemId()
		item({})
		fetchLater(function()
			local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, id, Enum.InfoType.Asset)
			if not ok then
				warn(`[Story] Tile: no product info for {id}: {info}`)
				return
			end
			item({
				Name = info.Name,
				PriceText = if info.IsPublicDomain then "Free" else "\u{E002}" .. tostring(info.PriceInRobux),
			})
		end)
	end)
	return item
end

local function getCameraDistance(fov: number, extentsSize: Vector3): number
	local maxSize = math.max(extentsSize.X, extentsSize.Y, extentsSize.Z)
	local fovMultiplier = 1 / math.tan(math.rad(fov) / 2)
	return maxSize * fovMultiplier + extentsSize.Z / 2
end

--* Foundation's ObjectViewport, which only its stories use: the camera orbits `model` in a square ViewportFrame.
local function ObjectViewport(model: Model)
	local tokens: Tokens = VF.Hooks.useTokens() :: any
	local camera = create("Camera")({
		CameraType = Enum.CameraType.Scriptable,
		FieldOfView = FIELD_OF_VIEW,
	})
	local worldModel = create("WorldModel")({})
	model.Parent = worldModel

	local pivot = model:GetPivot()
	local distance = getCameraDistance(FIELD_OF_VIEW, model:GetExtentsSize())
	local rotation = 0
	Vide.cleanup(RunService.RenderStepped:Connect(function()
		rotation += ROTATION_SPEED
		local lookVector = CFrame.fromAxisAngle(Vector3.yAxis, rotation):VectorToWorldSpace(pivot.LookVector)
		camera.CFrame = CFrame.new(pivot.Position + lookVector * distance, pivot.Position)
	end))

	local function light(): Color3
		return tokens().Color.Extended.Gray.Gray_200.Color3
	end

	return create("Frame")({
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		create("UIAspectRatioConstraint")({
			AspectRatio = 1,
			AspectType = Enum.AspectType.FitWithinMaxSize,
			DominantAxis = Enum.DominantAxis.Width,
		}),
		create("ViewportFrame")({
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 25, 1, 25),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			LightColor = light,
			LightDirection = Vector3.new(1, 1, 1),
			Ambient = light,
			CurrentCamera = camera,
			camera,
			worldModel,
		}),
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local tokens: Tokens = VF.Hooks.useTokens() :: any
	local textSizeOffset = VF.Hooks.useTextSizeOffset()
	local footerTextLines = 1

	local function fillDirection(): Enum.FillDirection
		return (Enum.FillDirection :: any)[controls.fillDirection()]
	end

	return Tile.Root({
		FillDirection = fillDirection,
		Size = function()
			local tileOffset = (controls.numTitleLines() + controls.numSubtitleLines() + footerTextLines)
				* textSizeOffset()
			return if fillDirection() == Enum.FillDirection.Vertical
				then UDim2.fromOffset(150, 275 + tileOffset)
				else UDim2.fromOffset(300, 150 + tileOffset)
		end,
		isContained = controls.isContained,
		children = function()
			return {
				Tile.Media({
					id = controls.itemId,
					type = MediaType.Asset,
					shape = controls.shape,
					background = function()
						return { style = tokens().Color.Shift.Shift_200 }
					end,
				}),
				Tile.Content({
					children = {
						Tile.Header({
							title = function()
								return {
									text = controls.title(),
									isLoading = false,
									fontStyle = tokens().Typography.HeadingSmall,
									numLines = controls.numTitleLines(),
								}
							end,
							subtitle = function()
								return {
									text = controls.subtitle(),
									isLoading = false,
									fontStyle = tokens().Typography.BodyLarge,
									colorStyle = tokens().Color.Content.Muted,
									numLines = controls.numSubtitleLines(),
								}
							end,
						}),
						Tile.Footer({ children = getPlayerCount(tokens) }),
					},
				}),
			}
		end,
	})
end

local function FunTileStory(controls: { [string]: any })
	local tokens: Tokens = VF.Hooks.useTokens() :: any
	local textSizeOffset = VF.Hooks.useTextSizeOffset()
	local item = useItem(controls.itemId)
	local model = Vide.source(nil :: Model?)
	local getModel: () -> Model? = model :: any

	Vide.effect(function()
		local id: number = controls.itemId()
		local thread = task.spawn(function()
			local stored = ReplicatedStorage:FindFirstChild(`{id}`)
			--* Foundation moves a stored model into the viewport; a clone leaves ReplicatedStorage as it was.
			if stored and stored:IsA("Model") then
				model(stored:Clone())
				return
			end
			if InsertService then
				local ok, loaded = pcall(InsertService.LoadAsset, InsertService, id)
				if ok then
					model(loaded :: Model)
				else
					warn(`[Story] Tile: could not load asset {id}: {loaded}`)
				end
			end
		end)
		Vide.cleanup(function()
			if coroutine.status(thread) ~= "dead" then
				task.cancel(thread)
			end
		end)
	end)

	local titleLines = 2
	local subtitleLines = 1

	return Tile.Root({
		isContained = true,
		FillDirection = Enum.FillDirection.Horizontal,
		Size = function()
			return UDim2.fromOffset(300, 150 + (titleLines + subtitleLines) * textSizeOffset()) - BORDER_OFFSET
		end,
		children = function()
			return {
				Tile.Media({
					shape = MediaShape.Square,
					background = function()
						return { image = backgroundImage(tokens, "itemBG")() }
					end,
					children = Vide.show(getModel, function(current: () -> Model)
						return foundation.rebuildOn(current, ObjectViewport)
					end),
				}),
				Tile.Content({
					children = Tile.Header({
						title = function()
							local name = item().Name
							return {
								text = name,
								isLoading = name == nil,
								fontStyle = tokens().Typography.HeadingSmall,
								numLines = titleLines,
							}
						end,
						subtitle = function()
							local priceText = item().PriceText
							return {
								text = priceText,
								isLoading = priceText == nil,
								fontStyle = tokens().Typography.BodyLarge,
								colorStyle = tokens().Color.Content.Muted,
								numLines = subtitleLines,
							}
						end,
					}),
				}),
			}
		end,
	})
end

local function ExperienceTileStory(controls: { [string]: any })
	local tokens: Tokens = VF.Hooks.useTokens() :: any
	local textSizeOffset = VF.Hooks.useTextSizeOffset()

	local isHovering = Vide.source(false)
	local isHoveringWide = Vide.source(false)

	local place = Vide.source({} :: { Name: string? })
	Vide.effect(function()
		local placeId: number = controls.placeId()
		place({})
		fetchLater(function()
			local ok, info =
				pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, placeId, Enum.InfoType.Asset)
			if ok then
				place(info)
			else
				warn(`[Story] Tile: no product info for {placeId}: {info}`)
			end
		end)
	end)

	local function universeId(): number?
		return PLACE_TO_UNIVERSE[controls.placeId()]
	end

	local sizeOffset, setSizeOffset = Motion.useAnimatedBinding(0)
	Vide.effect(function()
		local target = if isHoveringWide() then tokens().Size.Size_200 else 0
		Vide.untrack(function()
			setSizeOffset(Motion.ease(target, { duration = 0.3, easingStyle = { 0.2, 0.0, 0.0, 1.0 } }))
		end)
	end)

	local titleLines = 2
	local footerTextLines = 1
	local buttonTextLines = 1
	local function tileOffset(): number
		return (titleLines + footerTextLines + buttonTextLines) * textSizeOffset()
	end
	local function tileNoButtonOffset(): number
		return (titleLines + footerTextLines) * textSizeOffset()
	end

	local function placeTitle(fontStyle: string): () -> TileTypography
		return function()
			local name = place().Name
			return {
				text = name,
				isLoading = name == nil,
				fontStyle = tokens().Typography[fontStyle],
				numLines = titleLines,
			}
		end
	end

	return VF.View({
		tag = "row gap-large auto-xy padding-small",
		children = {
			Tile.Root({
				isContained = true,
				onStateChanged = function(newState: ControlState)
					isHovering(newState == ControlState.Hover)
				end,
				FillDirection = Enum.FillDirection.Vertical,
				Size = function()
					return experienceTileSize + UDim2.fromOffset(0, tileNoButtonOffset()) - BORDER_OFFSET
				end,
				LayoutOrder = 1,
				children = function()
					return {
						Tile.Media({
							id = function()
								return if isHovering() then controls.placeId() else universeId()
							end,
							type = function()
								return if isHovering() then MediaType.Asset else MediaType.GameIcon
							end,
							shape = function()
								return if isHovering() then MediaShape.Landscape else MediaShape.Square
							end,
						}),
						Tile.Content({
							children = {
								Tile.Header({ title = placeTitle("HeadingSmall") }),
								Tile.Footer({ children = getPlayerCount(tokens) }),
								Tile.Actions({ Visible = isHovering, children = PlayButton() }),
							},
						}),
					}
				end,
			}),
			VF.View({
				Size = wideTileSize,
				LayoutOrder = 2,
				children = Tile.Root({
					onStateChanged = function(newState: ControlState)
						isHoveringWide(newState == ControlState.Hover)
					end,
					isContained = false,
					FillDirection = Enum.FillDirection.Vertical,
					Size = function()
						local offset = sizeOffset()
						return wideTileSize + UDim2.fromOffset(offset * 2, offset * 2 + tileOffset())
					end,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					children = function()
						return {
							Tile.Media({ id = universeId, type = MediaType.GameIcon, shape = MediaShape.Landscape }),
							Tile.Content({
								children = {
									Tile.Header({ title = placeTitle("TitleLarge"), subtitle = PLAYER_COUNT }),
									Tile.Actions({ Visible = isHoveringWide, children = PlayButton() }),
								},
							}),
						}
					end,
				}),
			}),
			VF.View({
				Size = wideTileSize,
				LayoutOrder = 3,
				children = Tile.Root({
					isContained = true,
					FillDirection = Enum.FillDirection.Vertical,
					Size = function()
						return wideTileSize + UDim2.fromOffset(0, tileOffset())
					end,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					children = function()
						return {
							Tile.Media({ id = universeId, type = MediaType.GameIcon, shape = MediaShape.Landscape }),
							Tile.Content({
								children = {
									Tile.Header({ title = placeTitle("TitleLarge"), subtitle = PLAYER_COUNT }),
									Tile.Actions({ children = PlayButton() }),
								},
							}),
						}
					end,
				}),
			}),
		},
	})
end

local function ItemTileStory(controls: { [string]: any })
	local tokens: Tokens = VF.Hooks.useTokens() :: any
	local textSizeOffset = VF.Hooks.useTextSizeOffset()
	local item = useItem(controls.itemId)
	local titleLines, subtitleLines = 2, 1

	return Tile.Root({
		isContained = true,
		FillDirection = Enum.FillDirection.Vertical,
		Size = function()
			return itemTileSize + UDim2.fromOffset(0, (titleLines + subtitleLines) * textSizeOffset()) - BORDER_OFFSET
		end,
		children = function()
			return {
				Tile.Media({
					id = controls.itemId,
					type = MediaType.Asset,
					shape = MediaShape.Square,
					background = function()
						return { image = backgroundImage(tokens, "itemBG")() }
					end,
				}),
				Tile.Content({
					children = Tile.Header({
						title = function()
							local name = item().Name
							return {
								text = name,
								isLoading = name == nil,
								fontStyle = tokens().Typography.HeadingSmall,
								numLines = titleLines,
							}
						end,
						subtitle = function()
							local priceText = item().PriceText
							return {
								text = priceText,
								isLoading = priceText == nil,
								fontStyle = tokens().Typography.BodyLarge,
								colorStyle = tokens().Color.Content.Muted,
								numLines = subtitleLines,
							}
						end,
					}),
				}),
			}
		end,
	})
end

local function getColorValues(color: Color3)
	return { R = color.R, G = color.G, B = color.B }
end

local function createColorSpring(color: Color3)
	return {
		R = Motion.spring(color.R, SPRING_OPTIONS),
		G = Motion.spring(color.G, SPRING_OPTIONS),
		B = Motion.spring(color.B, SPRING_OPTIONS),
	}
end

local function PlayerTileStory()
	local tokens: Tokens = VF.Hooks.useTokens() :: any
	local textSizeOffset = VF.Hooks.useTextSizeOffset()
	local avatarBG = backgroundImage(tokens, "avatarBG")

	local user = Vide.source({} :: { DisplayName: string?, Username: string? })
	local mouseEntered = Vide.source(false)

	local function backgroundColor(): Color3
		return tokens().Color.Extended.White.White_100.Color3
	end
	local function hoverColor(): Color3
		return tokens().Color.Extended.Gray.Gray_400.Color3
	end
	local backgroundColorValues, setColorGoal = Motion.useAnimatedBinding(getColorValues(Vide.untrack(backgroundColor)))
	Vide.effect(function()
		local target = if mouseEntered() then hoverColor() else backgroundColor()
		Vide.untrack(function()
			setColorGoal(createColorSpring(target))
		end)
	end)

	local userId: number? = if Players.LocalPlayer
		then Players.LocalPlayer.UserId
		elseif StudioService then StudioService:GetUserId()
		else nil
	Vide.effect(function()
		user({})
		local id = userId
		if id == nil then
			return
		end
		fetchLater(function()
			local ok, users = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, { id })
			if ok and users[1] then
				user(users[1] :: any)
			else
				warn(`[Story] Tile: no user info for {userId}: {users}`)
			end
		end)
	end)

	local relevancyText = "Hueblox"
	local titleLines, footerLines, subtitleLines = 1, 1, 1
	local function tileOffset(): number
		return (titleLines + footerLines + subtitleLines) * textSizeOffset()
	end
	local function oldTileOffset(): number
		return (titleLines + subtitleLines) * textSizeOffset()
	end

	return VF.View({
		tag = "row gap-large auto-xy",
		children = {
			Tile.Root({
				FillDirection = Enum.FillDirection.Vertical,
				Size = function()
					return playerTileSize + UDim2.fromOffset(0, tileOffset())
				end,
				isContained = true,
				LayoutOrder = 1,
				children = function()
					return {
						Tile.Media({
							id = userId,
							type = MediaType.Avatar,
							shape = MediaShape.Square,
							background = function()
								return {
									image = avatarBG(),
									style = function(): ColorStyleValue
										local values = backgroundColorValues()
										return { Color3 = Color3.new(values.R, values.G, values.B) }
									end,
								}
							end,
							onStateChanged = function(newState: ControlState)
								mouseEntered(newState == ControlState.Hover)
							end,
							children = VF.View({
								ZIndex = 2,
								tag = "row align-x-right align-y-bottom gap-small position-bottom-right anchor-bottom-right size-full-0 auto-y",
								children = renderButtons(),
							}),
						}),
						Tile.Content({
							children = {
								Tile.Header({
									title = function()
										local displayName = user().DisplayName
										return { text = displayName, isLoading = displayName == nil }
									end,
									subtitle = function()
										local username = user().Username
										return {
											text = if username then "@" .. username else nil,
											isLoading = username == nil,
										}
									end,
								}),
								Tile.Footer({
									children = VF.View({
										tag = "row gap-xsmall size-full-0 auto-y",
										children = {
											VF.Icon({
												name = IconName.PlayLarge,
												size = IconSize.Small,
												LayoutOrder = 1,
											}),
											VF.Text({
												textStyle = function(): ColorStyleValue
													return tokens().Color.Content.Emphasis
												end,
												fontStyle = function()
													return tokens().Typography.CaptionLarge
												end,
												Text = relevancyText,
												TextXAlignment = Enum.TextXAlignment.Left,
												Size = UDim2.fromScale(1, 0),
												AutomaticSize = Enum.AutomaticSize.Y,
												LayoutOrder = 2,
											}),
										},
									}),
								}),
							},
						}),
					}
				end,
			}),
			Tile.Root({
				FillDirection = Enum.FillDirection.Vertical,
				Size = function()
					return UDim2.fromOffset(90, 115 + oldTileOffset())
				end,
				LayoutOrder = 2,
				children = function()
					return {
						Tile.Media({
							id = userId,
							type = MediaType.AvatarHeadShot,
							shape = MediaShape.Circle,
							background = function()
								return { image = avatarBG() }
							end,
							children = VF.Image({
								tag = "position-bottom-right anchor-center-center size-700-700 stroke-emphasis radius-circle bg-system-success",
								Image = "icons/placeholder/placeholderOff",
							}),
						}),
						Tile.Content({
							children = Tile.Header({
								title = function()
									local displayName = user().DisplayName
									return { text = displayName, isLoading = displayName == nil }
								end,
								subtitle = function()
									return { text = relevancyText, isLoading = user().DisplayName == nil }
								end,
								TextXAlignment = Enum.TextXAlignment.Center,
							}),
						}),
					}
				end,
			}),
		},
	})
end

local function MarketplaceTileStory(controls: { [string]: any })
	return VF.View({
		tag = "row gap-large auto-xy",
		children = Tile.Root({
			FillDirection = Enum.FillDirection.Horizontal,
			Size = UDim2.fromOffset(300, 150),
			children = function()
				return {
					Tile.Content({
						LayoutOrder = 1,
						children = {
							Tile.Header({
								title = { text = "Try out studio!" },
								subtitle = { text = "Do something exciting in studio." },
							}),
							Tile.Footer({}),
						},
					}),
					Tile.Media({
						id = controls.placeId,
						type = MediaType.Asset,
						shape = MediaShape.Square,
						LayoutOrder = 2,
					}),
				}
			end,
		}),
	})
end

return foundation.sections({
	summary = "Tile",
	controls = {
		fillDirection = UILabs.Choose({ "Vertical", "Horizontal" }),
		itemId = UILabs.Choose({ 21070012, 125378389, 14825332446, 3360689775 }),
		isContained = true,
		shape = UILabs.Choose({ MediaShape.Square, MediaShape.Landscape, MediaShape.Portrait, MediaShape.Circle }),
		title = "Build a Boat for Treasure",
		numTitleLines = 2,
		numSubtitleLines = 1,
		subtitle = "By Koi Koi Studios",
		placeId = UILabs.Choose({ 2727067538, 1537690962 }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Fun Tile", story = FunTileStory },
		{ name = "Experience Tile", story = ExperienceTileStory },
		{ name = "Item Tile", story = ItemTileStory },
		{ name = "Player Tile", story = PlayerTileStory },
		{ name = "Marketplace Tile (work in progress)", story = MarketplaceTileStory },
	},
})
