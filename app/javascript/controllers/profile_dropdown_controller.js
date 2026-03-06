import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.documentClickHandler = this.handleDocumentClick.bind(this)
    this.toggleButton = this.element.querySelector("[data-action*='profile-dropdown#toggle']")
  }

  disconnect() {
    document.removeEventListener("click", this.documentClickHandler)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const isHidden = this.menuTarget.classList.contains("hidden")
    this.menuTarget.classList.toggle("hidden")
    if (isHidden) {
      document.addEventListener("click", this.documentClickHandler)
    } else {
      document.removeEventListener("click", this.documentClickHandler)
    }
    this.syncAriaExpanded(!isHidden)
  }

  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  close() {
    if (!this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden")
      this.syncAriaExpanded(false)
    }
    document.removeEventListener("click", this.documentClickHandler)
  }

  syncAriaExpanded(value) {
    if (this.toggleButton) {
      this.toggleButton.setAttribute("aria-expanded", value.toString())
    }
  }
}
