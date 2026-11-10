--- Asserts only in development (`_G.__DEV__`): prop misuse fails loudly for developers, never for players.
local function devAssert(condition: unknown, message: string): ()
	if _G.__DEV__ == true then
		assert(condition, message)
	end
end

return devAssert
