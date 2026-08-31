local system = require "pandoc.system"

-- Compile tikz code blocks (thank you Owen)
local rootdir = os.getenv "QUARTO_PROJECT_DIR"
local cachedir = rootdir .. "/.svg-cache"

local thisfile = io.open(rootdir .. "/_filters.lua")
local thiscontent = thisfile:read "*all"
thisfile:close()
os.execute("mkdir -p " .. cachedir)

function make_templates(template_paths)
  local templates = {}

  for name, path in pairs(template_paths) do
    local fullpath = rootdir .. "/" .. path
    local file = io.open(fullpath, "r")
    local content = file:read "*all"
    file:close()

    local before_marker, after_marker = content:match "^(.*)@CONTENT(.*)$"
    if before_marker and after_marker then templates[name] = { before_marker, after_marker } end
  end

  return templates
end

local tikz_template_paths = {
  tikz = "_tikz_template.tex",
}

local tikz_templates = make_templates(tikz_template_paths)

local function meta_to_tex(v)
  if v == nil then return "" end

  local out = {}
  local value_type = pandoc.utils.type(v)
  if value_type == "Blocks" then
    for _, b in ipairs(v) do
      if b.t == "RawBlock" then
        local format = b.format or (b.c and b.c[1])
        local text = b.text or (b.c and b.c[2])
        if format == "tex" and text ~= nil then table.insert(out, text) end
      end
    end
  end

  return table.concat(out, "\n")
end

local function tikz_preamble_from_meta(meta)
  local preamble = meta_to_tex(meta["tikz-preamble"])
  local preamble_file = meta["tikz-preamble-file"]

  if preamble_file ~= nil then
    local path = pandoc.utils.stringify(preamble_file)
    local fullpath = pandoc.path.join({ pandoc.path.directory(quarto.doc.input_file), path })
    local file = assert(io.open(fullpath, "r"), "Could not open tikz-preamble-file: " .. fullpath)
    preamble = preamble .. file:read "*all"
    file:close()
  end

  return preamble
end

function trim(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

local function tikz2image(template)
  return function(src, outfile)
    system.with_temporary_directory("tikz2image", function(tmpdir)
      system.with_working_directory(tmpdir, function()
        local f = io.open("tikz.tex", "w")
        f:write(template[1] .. trim(src) .. template[2])
        f:close()
        print()
        print "processing:"
        print(src)
        local texres = os.execute "lualatex -interaction=nonstopmode -halt-on-error --output-format=dvi tikz.tex > texlog < /dev/null"
        if not texres then
          print "latex errored: log is"
          os.execute "cat texlog"
        else
          os.execute "dvisvgm --clipjoin --scale=1.7 --bbox=papersize --exact --font-format=woff2,autohint tikz.dvi > /dev/null"
          print("output to: " .. outfile)
          os.execute("mv tikz.svg " .. outfile)
        end
      end)
    end)
  end
end

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local function memoize_svg(input, builder, key)
  local svgdir = system.get_working_directory() .. "/_svgs"
  os.execute("mkdir -p " .. svgdir)
  local fbasename = pandoc.sha1(input .. key .. thiscontent) .. ".svg"
  local fname = svgdir .. "/" .. fbasename
  if not file_exists(fname) then builder(input, fname) end
  return pandoc.Image({}, "_svgs/" .. fbasename)
end

local tikz_user_preamble = ""

local function handle_codeblock(el)
  local tikz_template = tikz_templates[el.classes[1]]
  if tikz_template ~= nil then
    local template = { tikz_template[1]:gsub("@OPTIONAL_PREAMBLE", function() return tikz_user_preamble end), tikz_template[2] }
    return pandoc.Div(
      memoize_svg(el.text, tikz2image(template), template[1] .. template[2]),
      { class = "tikz" }
    )
  else
    return el
  end
end

function Pandoc(doc)
  tikz_user_preamble = tikz_preamble_from_meta(doc.meta)
  return doc:walk({ CodeBlock = handle_codeblock })
end

-- Just echo the content of callout blocks in pdf output
function Callout(el)
  if quarto.doc.isFormat("pdf") then
    return el.content
  end
  return el
end
