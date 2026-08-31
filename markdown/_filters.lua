-- Just echo the content of callout blocks in pdf output
function Callout(el)
  if quarto.doc.isFormat("pdf") then
    return el.content
  end
  return el
end
