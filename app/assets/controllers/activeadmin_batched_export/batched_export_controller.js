import { Controller } from "@hotwired/stimulus"
import {
  appendExportColumnParams,
  assembleExportParts,
} from "activeadmin_batched_export/chunk_assembly"

// Progressive ActiveAdmin export: sequential cursor fetches + single client-side save.
export default class extends Controller {
  static targets = [
    "progressWrap",
    "status",
    "fraction",
    "bar",
    "error",
    "start",
    "save",
    "cancel",
    "columnCheckbox",
  ]
  static values = {
    metaUrl: String,
    meta: Object,
    batchBaseUrl: String,
    format: String,
    preparingMessage: String,
    loadingBatchTemplate: String,
    emptyMessage: String,
    failedBatchTemplate: String,
    readyMessage: String,
    needsColumnMessage: String,
    cancelledMessage: String,
    incompleteMessage: String,
    overMaxMessage: String,
  }

  connect() {
    this.parts = []
    this.filename = null
    this.mime = "application/octet-stream"
    this.readyBlob = null
    this.abortController = null
    this.hideError()
  }

  hideError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.classList.add("hidden")
    this.errorTarget.textContent = ""
  }

  showError(message) {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  loadingLabel(current, total) {
    return this.loadingBatchTemplateValue
      .replace("%{current}", String(current))
      .replace("%{total}", String(total))
  }

  /** Appends export_columns[]=… from checked column checkboxes (all checked by default). */
  urlWithExportColumns(urlString) {
    if (!this.hasColumnCheckboxTarget) {
      return appendExportColumnParams(urlString, [], window.location.origin)
    }

    const checked = this.columnCheckboxTargets.filter((cb) => cb.checked)
    if (checked.length === 0) {
      throw new Error(this.needsColumnMessageValue)
    }
    return appendExportColumnParams(
      urlString,
      checked.map((cb) => cb.value),
      window.location.origin,
    )
  }

  mimeFor(exportFmt) {
    if (exportFmt === "csv") return "text/csv;charset=utf-8"
    if (exportFmt === "json") return "application/json;charset=utf-8"
    if (exportFmt === "xml") return "application/xml;charset=utf-8"
    return "application/octet-stream"
  }

  offerSave(filename) {
    this.filename = filename
    this.readyBlob = new Blob(assembleExportParts(this.exportFmt, this.parts), { type: this.mime })
    if (this.hasSaveTarget) {
      this.saveTarget.classList.remove("hidden")
      this.saveTarget.disabled = false
    }
  }

  setBusy(busy) {
    if (this.hasStartTarget) this.startTarget.disabled = busy
    if (this.hasCancelTarget) {
      this.cancelTarget.classList.toggle("hidden", !busy)
      this.cancelTarget.disabled = !busy
    }
  }

  cancel() {
    if (this.abortController) this.abortController.abort()
  }

  async start() {
    this.hideError()
    this.parts = []
    this.readyBlob = null
    this.filename = null
    this.baseFilename = null
    this.exportFmt = this.formatValue
    this.abortController = new AbortController()
    const { signal } = this.abortController

    this.setBusy(true)
    if (this.hasSaveTarget) {
      this.saveTarget.disabled = true
      this.saveTarget.classList.add("hidden")
    }
    if (this.hasProgressWrapTarget) this.progressWrapTarget.classList.remove("hidden")
    if (this.hasBarTarget) {
      this.barTarget.value = 0
      this.barTarget.max = 100
    }
    if (this.hasStatusTarget) this.statusTarget.textContent = this.preparingMessageValue
    if (this.hasFractionTarget) this.fractionTarget.textContent = ""

    try {
      await this.runExport(signal)
    } catch (err) {
      this.keepPartialFile(err)
    } finally {
      this.setBusy(false)
      this.abortController = null
    }
  }

  async runExport(signal) {
    const batchBaseUrl = this.urlWithExportColumns(this.batchBaseUrlValue)
    const metaUrl = this.urlWithExportColumns(this.metaUrlValue)
    const metaRes = await fetch(metaUrl, {
      credentials: "same-origin",
      signal,
      headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
    })
    if (!metaRes.ok) throw new Error(this.failedBatchTemplateValue.replace("%{page}", "1").replace("%{message}", "metadata"))
    const meta = await metaRes.json()

    this.exportFmt = meta.export_format || this.formatValue
    this.mime = this.mimeFor(this.exportFmt)
    const total = meta.total_batches
    this.baseFilename = meta.filename

    if (meta.over_max) throw new Error(this.overMaxMessageValue)

    if (total === 0) {
      if (this.hasStatusTarget) this.statusTarget.textContent = this.emptyMessageValue
      if (this.hasBarTarget) this.barTarget.removeAttribute("value")
      return
    }

    let cursor = null
    let snapshotToken = null
    let page = 0
    while (true) {
      page += 1
      if (this.hasStatusTarget) this.statusTarget.textContent = this.loadingLabel(page, total)
      if (this.hasFractionTarget) this.fractionTarget.textContent = `${page} / ${total}`
      if (this.hasBarTarget) {
        this.barTarget.value = Math.min(99, Math.round((100 * page) / Math.max(total, page)))
      }

      const batchUrl = new URL(batchBaseUrl, window.location.origin)
      batchUrl.searchParams.delete("export_cursor")
      batchUrl.searchParams.delete("export_snapshot")
      if (cursor) batchUrl.searchParams.set("export_cursor", cursor)
      if (snapshotToken) batchUrl.searchParams.set("export_snapshot", snapshotToken)

      const batchRes = await fetch(batchUrl.toString(), {
        credentials: "same-origin",
        signal,
        headers: { Accept: "*/*", "X-Requested-With": "XMLHttpRequest" },
      })
      if (!batchRes.ok) {
        throw new Error(
          this.failedBatchTemplateValue
            .replace("%{page}", String(page))
            .replace("%{message}", "stopped"),
        )
      }
      const text = await batchRes.text()
      this.parts.push(this.exportFmt === "xml" ? text.trim() : text)

      const nextSnapshot = batchRes.headers.get("X-Batched-Export-Snapshot")
      if (nextSnapshot) snapshotToken = nextSnapshot
      cursor = batchRes.headers.get("X-Batched-Export-Next")
      if (!cursor) break
    }

    if (this.hasBarTarget) this.barTarget.value = 100
    this.offerSave(this.baseFilename)
    if (this.hasStatusTarget) this.statusTarget.textContent = this.readyMessageValue
  }

  keepPartialFile(err) {
    const cancelled = err && err.name === "AbortError"
    if (this.parts.length > 0) {
      const base = this.baseFilename || "export"
      this.offerSave(`incomplete-${base}`)
      if (this.hasStatusTarget) this.statusTarget.textContent = this.incompleteMessageValue
    }
    this.showError(cancelled ? this.cancelledMessageValue : (err.message || String(err)))
  }

  save() {
    if (!this.readyBlob || !this.filename) return
    const url = URL.createObjectURL(this.readyBlob)
    const anchor = document.createElement("a")
    anchor.href = url
    anchor.download = this.filename
    anchor.rel = "noopener"
    anchor.click()
    URL.revokeObjectURL(url)
  }
}
