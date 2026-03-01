import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

import MobileMenuController from "./mobile_menu_controller"
application.register("mobile-menu", MobileMenuController)
