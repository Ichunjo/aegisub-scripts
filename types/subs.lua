---@meta subs

---@class Subs: userdata
subs = {}

---@param i number
function subs.delete(i) end

---@generic T
---@param i number
---@param v T
function subs.insert(i, v) end

return subs
