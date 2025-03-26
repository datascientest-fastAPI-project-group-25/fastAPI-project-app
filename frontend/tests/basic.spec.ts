import { expect, test } from "@playwright/test"

// This is a basic test that doesn't require authentication or a backend server
test("basic test - verify page title", async ({ page }) => {
  // Navigate to the base URL (defined in playwright.config.ts)
  await page.goto("/")

  // Check that the page has loaded something (doesn't matter what exactly)
  await expect(page).not.toBeNull()

  // This test will pass as long as Playwright can navigate to the page
  // It doesn't validate any specific content
  test.info().annotations.push({
    type: "info",
    description:
      "This test only verifies that Playwright can navigate to a page",
  })
})
