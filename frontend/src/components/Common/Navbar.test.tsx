import "@testing-library/jest-dom"
import { render, screen } from "@testing-library/react"
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest"

// Mock Chakra UI components
vi.mock("@chakra-ui/react", () => ({
  Box: ({ children }: any) => (
    <div data-testid="chakra-box">{children}</div>
  ),
  Flex: ({ children }: any) => <div data-testid="chakra-flex">{children}</div>,
  Link: ({ children, href }: any) => (
    <a data-testid="chakra-link" href={href}>
      {children}
    </a>
  ),
  Image: ({ alt, src }: any) => (
    <img
      data-testid="chakra-image"
      alt={alt || "Descriptive alt text for image"}
      src={src}
    />
  ),
  Button: ({ children, onClick, ...props }: any) => (
    <button data-testid="chakra-button" onClick={onClick} {...props}>
      {children}
    </button>
  ),
  useColorMode: vi.fn(() => ({ colorMode: 'light', toggleColorMode: vi.fn() })),
  useTheme: vi.fn(() => ({ colors: { gray: { '800': '#1A202C' } } })),
  IconButton: ({ children, 'aria-label': ariaLabel, onClick }: any) => (
    <button aria-label={ariaLabel} onClick={onClick} data-testid="chakra-iconbutton">
      {children}
    </button>
  ),
  useBreakpointValue: () => "flex",
}))

// Mock TanStack Router
vi.mock("@tanstack/react-router", () => ({
  Link: ({ children, to }: any) => (
    <a href={to} data-testid="router-link">
      {children}
    </a>
  ),
  useRouter: () => ({
    navigate: vi.fn(),
    currentRoute: {
      path: "/",
      fullPath: "/",
    },
  }),
  useNavigate: () => vi.fn(),
  createRootRoute: vi.fn(),
  createRoute: vi.fn(),
  createRouter: vi.fn(),
  RouterProvider: ({ children }: { children: React.ReactNode }) => (
    <>{children}</>
  ),
}))

// Mock the UserMenu component
vi.mock("./UserMenu", () => ({
  default: () => <div data-testid="user-menu">User Menu</div>,
}))

// Import the component after all mocks are set up
import Navbar from "./Navbar"

describe("Navbar Component", () => {
  beforeEach(() => {
    // Reset mocks before each test
    vi.clearAllMocks()
  })

  afterEach(() => {
    // Reset mocks after each test
    vi.resetAllMocks()
    // Clear any mock implementations
    vi.restoreAllMocks()
  })

  test("renders the navbar component", () => {
    const { container } = render(<Navbar />)

    // Check that the component renders without errors
    expect(container).toBeTruthy()
  })

  test("renders the logo", () => {
    render(<Navbar />)

    // Find the logo by its test ID and alt text
    const logoImage = screen.getByTestId("chakra-image")
    expect(logoImage).toBeInTheDocument()
    expect(logoImage).toHaveAttribute("alt", "FastAPI Project")
  })

  test("renders the user menu", () => {
    render(<Navbar />)

    // Check that the user menu component is rendered
    expect(screen.getByTestId("user-menu")).toBeInTheDocument()
  })
})
