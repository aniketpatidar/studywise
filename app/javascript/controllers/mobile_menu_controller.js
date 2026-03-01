import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Mobile menu controller connected")
  }

  open() {
    console.log("Opening mobile menu")
    this.menuTarget.classList.remove("hidden")
  }

  close() {
    console.log("Closing mobile menu")
    this.menuTarget.classList.add("hidden")
  }
}
