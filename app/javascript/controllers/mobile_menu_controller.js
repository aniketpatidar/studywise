import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  open() {
    this.menuTarget.classList.remove("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }
}
