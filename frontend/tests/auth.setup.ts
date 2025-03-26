import fs from "node:fs"
import path from "node:path"
import { test as setup } from "@playwright/test"
import { firstSuperuser, firstSuperuserPassword } from "./config.ts"

const authFile = "playwright/.auth/user.json"

// Ensure the auth directory exists
const authDir = path.dirname(authFile)
if (!fs.existsSync(authDir)) {
  fs.mkdirSync(authDir, { recursive: true })
}

setup("authenticate", async ({ page }) => {
  console.log("Starting authentication setup...")
  console.log(`Using credentials: ${firstSuperuser} / [password hidden]`)

  // Navigate to login page with longer timeout and retry
  await page.goto("/login", { timeout: 60000 })

  // Wait for the login form to be visible
  await page
    .getByPlaceholder("Email")
    .waitFor({ state: "visible", timeout: 10000 })

  // Fill in credentials
  await page.getByPlaceholder("Email").fill(firstSuperuser)
  await page.getByPlaceholder("Password").fill(firstSuperuserPassword)

  // Click login and wait for navigation with extended timeout
  await page.getByRole("button", { name: "Log In" }).click()

  try {
    // Increase timeout for navigation to 60 seconds
    await page.waitForURL("/", { timeout: 60000 })
    console.log("Successfully navigated to home page")
  } catch (error: any) {
    // Safely log error information without accessing page content
    console.error("Navigation timeout occurred.")
    try {
      // Only try to access URL if page is still available
      console.error("Current URL (if available):", page.url())
    } catch (e) {
      console.error("Could not access page URL - page may be closed")
    }
    throw new Error(
      `Authentication failed: ${error.message || "Unknown error"}`,
    )
  }

  // Save authentication state
  await page.context().storageState({ path: authFile })
  console.log("Authentication state saved successfully")
})
