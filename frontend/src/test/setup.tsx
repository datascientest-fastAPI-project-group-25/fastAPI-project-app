import "@testing-library/jest-dom"
import { cleanup } from "@testing-library/react"
import type { ImgHTMLAttributes } from "react"
import { afterAll, afterEach, beforeAll, beforeEach, vi } from "vitest"
import { server } from "./mocks/server"

// Mock @tanstack/react-router
vi.mock("@tanstack/react-router", () => {
  return {
    // Keep the original exports
    RouterProvider: vi.fn(),
    createRouter: vi.fn(),
    // Add missing exports that are used in the app
    createFileRoute: vi.fn().mockImplementation(() => () => ({
      component: vi.fn(),
      beforeLoad: vi.fn(),
    })),
    // Add any other exports needed
    Outlet: vi.fn(),
    Link: vi.fn(),
    useNavigate: vi.fn(),
    useParams: vi.fn(),
    Image: ({ alt, src }: ImgHTMLAttributes<HTMLImageElement>) => (
      <img alt={alt || "Descriptive alt text for image"} src={src} />
    ),
  }
})

// Mock our custom hooks if needed
vi.mock("../hooks/useNavbarDisplay", () => ({
  useNavbarDisplay: () => "flex",
}))

// Setup before all tests
beforeAll(() => {
  server.listen()
})

// Setup before each test
beforeEach(() => {
  // Mock localStorage
  const localStorageMock = {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn(),
  }
  global.localStorage = localStorageMock as any

  // Mock window.innerWidth
  Object.defineProperty(window, "innerWidth", {
    writable: true,
    configurable: true,
    value: 1024,
  })
})

// Cleanup after each test
afterEach(() => {
  cleanup()
  server.resetHandlers()
})

// Cleanup after all tests
afterAll(() => server.close())

// Re-export everything from testing-library
export * from "@testing-library/react"
