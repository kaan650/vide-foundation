--* The Wally dependency, a sibling of this package's root in Packages/_Index or in the dev place's Packages.
local VideRipple = require(script.Parent.Parent.Parent.VideRipple)

export type Spring<T = any> = VideRipple.Spring<T>
export type Tween<T = any> = VideRipple.Tween<T>
export type Motion<T = any> = VideRipple.Motion<T>

return VideRipple
