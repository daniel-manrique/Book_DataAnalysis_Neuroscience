-- Figure size rule.
-- Every figure drawn by an R chunk is displayed at a width proportional to the
-- width it was drawn at: FULL inches fill the text column, so a figure drawn at
-- 6.5 inches fills 65% of it, and one drawn at 10 inches fills all of it. All
-- figures then share one magnification, which keeps the text inside them the
-- same size from figure to figure, in the web and the PDF editions.
-- Only images made by knitr (a PNG with a pHYs chunk, in a "figure-*" folder)
-- are touched. Sketches in images/ and any image that already carries an
-- explicit percentage or unit width are left alone.

local FULL = 10        -- inches drawn that correspond to the full text column
local MIN_PCT = 35     -- never display a figure narrower than this
local MAX_PCT = 100

-- Width of a PNG in inches, from its pixel width and its pHYs (dots per metre).
local function png_inches(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local head = f:read(4096)
  f:close()
  if not head or #head < 33 or head:sub(2, 4) ~= "PNG" then return nil end
  local px = string.unpack(">I4", head, 17)
  local at = head:find("pHYs", 1, true)
  if not at then return nil end
  local ppu, _, unit = string.unpack(">I4I4B", head, at + 4)
  if unit ~= 1 or ppu == 0 then return nil end
  return px / (ppu * 0.0254)
end

function Image(img)
  if not img.src:find("/figure%-[%a]+/") then return nil end
  -- Quarto fills in the drawn size as plain pixels; a width the author wrote
  -- (a percentage or a unit) is respected and left alone.
  local w = img.attributes["width"]
  if w and not w:match("^%d+$") then return nil end
  local inches = png_inches(img.src)
  if not inches then return nil end
  local pct = math.floor(100 * inches / FULL + 0.5)
  pct = math.max(MIN_PCT, math.min(MAX_PCT, pct))
  img.attributes["width"] = string.format("%d%%", pct)
  img.attributes["height"] = nil
  return img
end
