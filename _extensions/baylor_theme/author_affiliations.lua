function Meta(meta)
  local authors = {}
  local institutions = {}

  if meta.author then
    for _, a in ipairs(meta.author) do
      table.insert(authors, pandoc.utils.stringify(a))
    end
  end

  -- NOTE: Quarto uses 'institute' not 'institution'
  if meta.institute then
    for _, i in ipairs(meta.institute) do
      table.insert(institutions, pandoc.utils.stringify(i))
    end
  end

  if #authors == 0 or #institutions == 0 then
    return meta
  end

  -- Build sorted unique institution list (alphabetical)
  local unique = {}
  local seen = {}
  for _, inst in ipairs(institutions) do
    if not seen[inst] then
      seen[inst] = true
      table.insert(unique, inst)
    end
  end
  table.sort(unique)

  -- Map institution -> letter
  local inst_letter = {}
  for i, inst in ipairs(unique) do
    inst_letter[inst] = string.char(64 + i)
  end

  -- Build author string
  local author_parts = {}
  for i, author in ipairs(authors) do
    local inst = institutions[i]
    local letter = inst and inst_letter[inst] or ""
    if letter ~= "" then
      table.insert(author_parts, author .. "<sup>" .. letter .. "</sup>")
    else
      table.insert(author_parts, author)
    end
  end

  -- Build affiliation string
  local affil_parts = {}
  for i, inst in ipairs(unique) do
    table.insert(affil_parts, "<sup>" .. string.char(64 + i) .. "</sup>" .. inst)
  end

  local author_html = table.concat(author_parts, ", ")
  local affil_html  = table.concat(affil_parts,  " &ensp; ")

  local script = string.format([[
<script>
document.addEventListener("DOMContentLoaded", function() {
  var container = document.querySelector(".quarto-title-authors");
  if (!container) return;
  container.innerHTML =
    '<div class="quarto-title-author">' +
      '<div class="quarto-title-author-name">%s</div>' +
      '<div class="affiliation-line">%s</div>' +
    '</div>';
});
</script>
]], author_html, affil_html)

  local includes = meta["header-includes"] or pandoc.MetaList({})
  table.insert(includes, pandoc.MetaBlocks({ pandoc.RawBlock("html", script) }))
  meta["header-includes"] = includes

  meta.author = pandoc.MetaList({
    pandoc.MetaInlines({ pandoc.Str("placeholder") })
  })
  meta.institute = nil

  return meta
end