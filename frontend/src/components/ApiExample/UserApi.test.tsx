import "@testing-library/jest-dom"
import { describe, expect, test, vi } from "vitest"

// Mock Chakra UI components
vi.mock("@chakra-ui/react", () => ({
  Box: ({ children, ...props }: any) => (
    <div data-testid="chakra-box" {...props}>
      {children}
    </div>
  ),
  Heading: ({ children, ...props }: any) => (
    <h2 data-testid="chakra-heading" {...props}>
      {children}
    </h2>
  ),
  Text: ({ children, ...props }: any) => (
    <p data-testid="chakra-text" {...props}>
      {children}
    </p>
  ),
  Button: ({ children, ...props }: any) => (
    <button type="button" data-testid="chakra-button" {...props}>
      {children}
    </button>
  ),
}))

// Mock the API client
vi.mock("../../client", () => ({
  UserService: {
    usersMeGet: vi.fn(),
  },
}))

// TODO: Add tests for UserApi component
describe("UserApi Component", () => {
  test("placeholder test", () => {
    expect(true).toBe(true)
  })
})
