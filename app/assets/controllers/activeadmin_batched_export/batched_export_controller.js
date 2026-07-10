import { Controller } from "@hotwired/stimulus"

// Progressive ActiveAdmin export: sequential batch fetches + single client-side save.
export default class extends Controller {
  static targets = ["progressWrap", "status", "fraction", "bar", "error", "start", "save", "columnCheckbox"]
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
  }

  connect() {
    this.parts = []
    this.filename = null
    this.mime = "application/octet-stream"
    this.readyBlob = null
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
    const u = new URL(urlString, window.location.origin)
    u.searchParams.delete("export_columns[]")
    u.searchParams.delete("export_columns")

    if (!this.hasColumnCheckboxTarget) return u.toString()

    const checked = this.columnCheckboxTargets.filter((cb) => cb.checked)
    if (checked.length === 0) {
      throw new Error(this.needsColumnMessageValue)
    }
    checked.forEach((cb) => u.searchParams.append("export_columns[]", cb.value))
    return u.toString()
  }

  async start() {
    this.hideError()
    this.parts = []
    this.readyBlob = null
    this.filename = null

    if (this.hasStartTarget) this.startTarget.disabled = true
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
      const batchBaseUrl = this.urlWithExportColumns(this.batchBaseUrlValue)

      let meta = this.hasMetaValue ? this.metaValue : null
      if (!meta || typeof meta.total_batches !== "number") {
        const metaUrl = this.urlWithExportColumns(this.metaUrlValue)
        const metaRes = await fetch(metaUrl, {
          credentials: "same-origin",
          headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
        })
        if (!metaRes.ok) throw new Error(`${metaRes.status} ${metaRes.statusText}`)
        meta = await metaRes.json()
      }

      this.filename = meta.filename
      const total = meta.total_batches
      const exportFmt = meta.export_format || this.formatValue

      if (total === 0) {
        if (this.hasStatusTarget) this.statusTarget.textContent = this.emptyMessageValue
        if (this.hasBarTarget) this.barTarget.removeAttribute("value")
        if (this.hasStartTarget) this.startTarget.disabled = false
        return
      }

      if (exportFmt === "csv") {
        this.mime = "text/csv;charset=utf-8"
      } else if (exportFmt === "json") {
        this.mime = "application/json;charset=utf-8"
      } else if (exportFmt === "xml") {
        this.mime = "application/xml;charset=utf-8"
      }

      const collectedJsonRows = []
      const xmlFragments = []

      for (let page = 1; page <= total; page += 1) {
        if (this.hasStatusTarget) this.statusTarget.textContent = this.loadingLabel(page, total)
        if (this.hasFractionTarget) this.fractionTarget.textContent = `${page} / ${total}`

        const batchUrl = new URL(batchBaseUrl, window.location.origin)
        batchUrl.searchParams.set("batch_page", String(page))

        const batchRes = await fetch(batchUrl.toString(), {
          credentials: "same-origin",
          headers: { Accept: "*/*", "X-Requested-With": "XMLHttpRequest" },
        })
        if (!batchRes.ok) {
          const msg = this.failedBatchTemplateValue
            .replace("%{page}", String(page))
            .replace("%{message}", `${batchRes.status} ${batchRes.statusText}`)
          throw new Error(msg)
        }
        const text = await batchRes.text()

        if (exportFmt === "csv") {
          this.parts.push(text)
        } else if (exportFmt === "json") {
          let chunk
          try {
            chunk = JSON.parse(text)
          } catch (parseErr) {
            throw new Error(
              this.failedBatchTemplateValue
                .replace("%{page}", String(page))
                .replace("%{message}", parseErr.message || "invalid JSON"),
            )
          }
          collectedJsonRows.push(...chunk)
        } else if (exportFmt === "xml") {
          xmlFragments.push(text.trim())
        }

        if (this.hasBarTarget) this.barTarget.value = Math.round((100 * page) / total)
      }

      if (exportFmt === "json") {
        this.parts = [JSON.stringify(collectedJsonRows)]
      } else if (exportFmt === "xml") {
        this.parts = [
          `<?xml version="1.0" encoding="UTF-8"?>\n<export>\n${xmlFragments.join("\n")}\n</export>\n`,
        ]
      }

      this.readyBlob = new Blob(this.parts, { type: this.mime })
      if (this.hasSaveTarget) {
        this.saveTarget.classList.remove("hidden")
        this.saveTarget.disabled = false
      }
      if (this.hasStatusTarget) this.statusTarget.textContent = this.readyMessageValue
    } catch (err) {
      this.showError(err.message || String(err))
    } finally {
      if (this.hasStartTarget) this.startTarget.disabled = false
    }
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
