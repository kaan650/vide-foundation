local PREFIX = "[VideFoundation]"

local Logger = {}

function Logger:warning(message: string)
	warn(`{PREFIX} {message}`)
end

function Logger:error(message: string)
	warn(`{PREFIX} {message}`)
end

function Logger:info(message: string)
	print(`{PREFIX} {message}`)
end

function Logger:debug(_message: string) end

return Logger
