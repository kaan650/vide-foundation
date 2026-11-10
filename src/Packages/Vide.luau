--* The Wally dependency, a sibling of this package's root in Packages/_Index or in the dev place's Packages.
local Vide = require(script.Parent.Parent.Parent.Vide)

export type Source<T> = Vide.Source<T>
export type Context<T> = Vide.Context<T>

return Vide
