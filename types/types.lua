---@meta


---@class Line
---@field start_time integer
---@field end_time integer
---@field duration number
---@field text string
---@field effect string
---@field style string
---@field margin_l integer

---@class Meta
---@field res_x integer|nil
---@field res_y integer|nil

---@class Style
---@field align integer
---@field name string

---@class Styles
---@field n integer
---@field [string] Style

---@class karaskel
karaskel = {}

---Collect styles and metadata from the subs
---@param subs Subs
---@param generate_furigana boolean?
---@return Meta, Styles
function karaskel.collect_head(subs, generate_furigana) end
