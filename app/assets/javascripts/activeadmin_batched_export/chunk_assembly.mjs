export function concatJsonArrayChunks(texts) {
  const inners = []
  for (const text of texts) {
    const trimmed = text.trim()
    if (trimmed === "" || trimmed === "[]") continue
    inners.push(trimmed.slice(1, -1))
  }
  if (inners.length === 0) return "[]"
  return `[${inners.join(",")}]`
}

export function wrapXmlChunks(parts) {
  return `<?xml version="1.0" encoding="UTF-8"?>\n<export>\n${parts.join("\n")}\n</export>\n`
}

export function assembleExportParts(exportFmt, parts) {
  if (exportFmt === "json") return [concatJsonArrayChunks(parts)]
  if (exportFmt === "xml") return [wrapXmlChunks(parts)]
  return parts
}

export function appendExportColumnParams(urlString, columnValues, origin) {
  const parsed = new URL(urlString, origin)
  parsed.searchParams.delete("export_columns[]")
  parsed.searchParams.delete("export_columns")
  for (const value of columnValues) {
    parsed.searchParams.append("export_columns[]", value)
  }
  return parsed.toString()
}
