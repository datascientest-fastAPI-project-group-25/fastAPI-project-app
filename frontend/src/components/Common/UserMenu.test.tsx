import "@testing-library/jest-dom"
import { describe, expect, test, vi } from "vitest"

// Mock Chakra UI components
vi.mock("@chakra-ui/react", () => ({
  Menu: ({ children, ...props }: any) => (
    <div data-testid="chakra-menu" {...props}>
      {children}
    </div>
  ),
  MenuButton: ({ children, ...props }: any) => (
    <button type="button" data-testid="chakra-menu-button" {...props}>
      {children}
    </button>
  ),
  MenuList: ({ children, ...props }: any) => (
    <div data-testid="chakra-menu-list" {...props}>
      {children}
    </div>
  ),
  MenuItem: ({ children, ...props }: any) => (
    <div data-testid="chakra-menu-item" {...props}>
      {children}
    </div>
  ),
  Button: ({ children, ...props }: any) => (
    <button type="button" data-testid="chakra-button" {...props}>
      {children}
    </button>
  ),
  useColorMode: () => ({
    colorMode: "light",
    toggleColorMode: vi.fn(),
  }),
}))

// TODO: Add tests for UserMenu component
describe("UserMenu Component", () => {
  test("placeholder test", () => {
    expect(true).toBe(true)
  })
})
