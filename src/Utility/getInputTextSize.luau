local InputSize = require("../Enums/InputSize")
type InputSize = InputSize.InputSize

local InputLabelSize = require("../Enums/InputLabelSize")
type InputLabelSize = InputLabelSize.InputLabelSize

local INPUT_TO_TEXT: { [InputSize]: InputLabelSize } = {
	[InputSize.Large] = InputLabelSize.Large,
	[InputSize.Medium] = InputLabelSize.Medium,
	[InputSize.Small] = InputLabelSize.Small,
	[InputSize.XSmall] = InputLabelSize.XSmall,
}

--- The label size that goes with an input of `inputSize`.
local function getInputTextSize(inputSize: InputSize): InputLabelSize
	return INPUT_TO_TEXT[inputSize]
end

return getInputTextSize
