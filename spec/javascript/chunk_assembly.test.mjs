import test from "node:test"
import assert from "node:assert/strict"
import {
  appendExportColumnParams,
  assembleExportParts,
  concatJsonArrayChunks,
  wrapXmlChunks,
} from "../../app/assets/javascripts/activeadmin_batched_export/chunk_assembly.js"

test("concatJsonArrayChunks joins array inners into one array", () => {
  const combined = concatJsonArrayChunks(['[{"Id":1}]', '[{"Id":2}]'])
  assert.equal(combined, '[{"Id":1},{"Id":2}]')
})

test("concatJsonArrayChunks skips empty arrays", () => {
  assert.equal(concatJsonArrayChunks(["[]", ""]), "[]")
})

test("wrapXmlChunks wraps fragments in one export root", () => {
  const xml = wrapXmlChunks(["<row/>", "<row/>"])
  assert.equal(
    xml,
    '<?xml version="1.0" encoding="UTF-8"?>\n<export>\n<row/>\n<row/>\n</export>\n',
  )
})

test("assembleExportParts concatenates json and leaves csv parts", () => {
  assert.deepEqual(assembleExportParts("json", ["[1]", "[2]"]), ["[1,2]"])
  assert.deepEqual(assembleExportParts("csv", ["a", "b"]), ["a", "b"])
})

test("appendExportColumnParams writes export_columns", () => {
  const url = appendExportColumnParams("/export", ["0", "2"], "http://example.test")
  assert.match(url, /export_columns%5B%5D=0/)
  assert.match(url, /export_columns%5B%5D=2/)
})
