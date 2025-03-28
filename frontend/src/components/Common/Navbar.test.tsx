import "@testing-library/jest-dom"
import { screen } from "@testing-library/react"
import { render } from "@testing-library/react"
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest"

// Mock Chakra UI components
vi.mock("@chakra-ui/react", () => ({
  Box: ({ children, ...props }: any) => (
    <div data-testid="chakra-box" {...props}>
      {children}
    </div>
  ),
  Flex: ({ children, ...props }: any) => (
    <div data-testid="chakra-flex" {...props}>
      {children}
    </div>
  ),
  Link: ({ children, ...props }: any) => (
    <a data-testid="chakra-link" {...props}>
      {children}
    </a>
  ),
  Image: ({ alt, src, ...props }: any) => (
    <img data-testid="chakra-image" alt={alt} src={src} {...props} />
  ),
  useBreakpointValue: () => "flex",
}))

// Mock TanStack Router
vi.mock("@tanstack/react-router", () => ({
  Link: ({ children, to, ...props }: any) => (
    <a href={to} data-testid="router-link" {...props}>
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
