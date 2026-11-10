--* The Wally dependency, a sibling of this package's root in Packages/_Index or in the dev place's Packages.
local Ripple = require(script.Parent.Parent.Parent.Ripple)

export type Animatable = Ripple.Animatable
export type Easing = Ripple.Easing
export type Motion<T = any> = Ripple.Motion<T>
export type MotionOptions<T = any> = Ripple.MotionOptions<T>
export type Spring<T = any> = Ripple.Spring<T>
export type SpringOptions<T = any> = Ripple.SpringOptions<T>
export type Tween<T = any> = Ripple.Tween<T>
export type TweenOptions<T = any> = Ripple.TweenOptions<T>

return Ripple
