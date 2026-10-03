-- Index marker filter (see planning/glossary-index-method.md).
-- A span is an index mark when it has the class "ix" or when it is one of the
-- green key-term spans that introduce a term. It gets a stable anchor id
-- (ix-<slug>-<n>, n counted per document) so the generated index can link to
-- it, and in PDF it also emits \index{} for makeindex.
-- The cleaning rule (clean_term) and the exclusion list must match
-- scripts/build-index.R, which builds the index page from the same marks.

local counts = {}
local excluded = {}

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function clean_term(s)
  s = s:lower()
  for _, q in ipairs({ '"', "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}", "`", "*" }) do
    s = s:gsub(q:gsub("%p", "%%%0"), "")
  end
  s = trim(s)
  s = s:gsub("^a%s+", ""):gsub("^an%s+", ""):gsub("^the%s+", "")
  return s
end

local function slugify(s)
  s = s:gsub("[^%w]+", "-")
  s = s:gsub("^%-+", ""):gsub("%-+$", "")
  return s
end

local function word_count(s)
  local _, n = s:gsub("%S+", "")
  return n
end

local function load_excluded()
  local f = io.open("scripts/index-exclude.txt", "r")
  if not f then return end
  for line in f:lines() do
    line = trim(line)
    if line ~= "" and line:sub(1, 1) ~= "#" then excluded[line] = true end
  end
  f:close()
end
load_excluded()

function Pandoc(doc)
  counts = {}
  return doc
end

function Span(el)
  local explicit = el.classes:includes("ix")
  local st = el.attributes["style"]
  local green = st ~= nil and st:find("color:%s*green") ~= nil
  if not explicit and not green then return nil end

  local term = clean_term(el.attributes["ix"] or pandoc.utils.stringify(el.content))
  local slug = slugify(term)
  if slug == "" then return nil end
  if not explicit and word_count(term) > 4 then return nil end
  if excluded[term] then return nil end

  counts[slug] = (counts[slug] or 0) + 1
  if el.identifier == "" then
    el.identifier = "ix-" .. slug .. "-" .. counts[slug]
  end
  if FORMAT:match("latex") or FORMAT:match("pdf") then
    local entry = term:gsub("[!@|{}\\]", "")
    return { el, pandoc.RawInline("latex", "\\index{" .. entry .. "}") }
  end
  return el
end
