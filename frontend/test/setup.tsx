import "@testing-library/jest-dom"
import * as React from "react"
import { vi } from "vitest"

// Mock the useAuth hook
vi.mock("@/hooks/useAuth", () => ({
  default: () => ({
    user: {
      id: "1",
      email: "test@example.com",
      full_name: "Test User",
      is_active: true,
      is_superuser: false,
    },
    logout: vi.fn(),
    error: null,
    resetError: vi.fn(),
    signUpMutation: { mutate: vi.fn() },
    loginMutation: { mutate: vi.fn() },
  }),
}))

// Mock theme.tsx and button.recipe.ts to avoid defineRecipe issues
vi.mock("../src/theme", () => ({
  system: {},
}))

vi.mock("../src/theme/button.recipe", () => ({
  buttonRecipe: {},
}))

// Mock Chakra UI components using importOriginal
vi.mock("@chakra-ui/react", async (importOriginal) => {
  try {
    // Try to import the actual module
    const actual = await importOriginal<typeof import("@chakra-ui/react")>()

    // Create a mock for createToaster
    const mockToaster = {
      create: vi.fn(),
      success: vi.fn(),
      error: vi.fn(),
      warning: vi.fn(),
      info: vi.fn(),
      loading: vi.fn(),
      close: vi.fn(),
      closeAll: vi.fn(),
      isActive: vi.fn(),
      update: vi.fn(),
    }

    return {
      ...actual,
      // Mock UI components
      ChakraProvider: ({ children }: { children: React.ReactNode }) => (
        <>{children}</>
      ),
      Button: ({ children, ...props }: any) => (
        <button type="button" {...props}>
          {children}
        </button>
      ),
      Flex: ({ children, ...props }: any) => <div {...props}>{children}</div>,
      Box: ({ children, ...props }: any) => <div {...props}>{children}</div>,
      Text: ({ children, ...props }: any) => <span {...props}>{children}</span>,
      IconButton: ({ children, ...props }: any) => (
        <button type="button" {...props}>
          {children}
        </button>
      ),
      Image: ({ alt, src, ...props }: any) => (
        <img alt={alt} src={src} {...props} />
      ),

      // Mock functions
      createToaster: vi.fn().mockReturnValue(mockToaster),
      defineRecipe: vi.fn().mockImplementation((config) => {
        return {
          ...config,
          __recipe: true,
        }
      }),
      useColorMode: () => ({ colorMode: "light", toggleColorMode: vi.fn() }),
    }
  } catch (error) {
    // Fallback if import fails
    const mockToaster = {
      create: vi.fn(),
      success: vi.fn(),
      error: vi.fn(),
      warning: vi.fn(),
      info: vi.fn(),
      loading: vi.fn(),
      close: vi.fn(),
      closeAll: vi.fn(),
      isActive: vi.fn(),
      update: vi.fn(),
    }

    return {
      ChakraProvider: ({ children }: { children: React.ReactNode }) => (
        <>{children}</>
      ),
      Button: ({ children, ...props }: any) => (
        <button type="button" {...props}>
          {children}
        </button>
      ),
      Flex: ({ children, ...props }: any) => <div {...props}>{children}</div>,
      Box: ({ children, ...props }: any) => <div {...props}>{children}</div>,
      Text: ({ children, ...props }: any) => <span {...props}>{children}</span>,
      IconButton: ({ children, ...props }: any) => (
        <button type="button" {...props}>
          {children}
        </button>
      ),
      Image: ({ alt, src, ...props }: any) => (
        <img alt={alt} src={src} {...props} />
      ),
      createToaster: vi.fn().mockReturnValue(mockToaster),
      defineRecipe: vi.fn().mockImplementation((config) => {
        return {
          ...config,
          __recipe: true,
        }
      }),
      useColorMode: () => ({ colorMode: "light", toggleColorMode: vi.fn() }),
    }
  }
})

// Always mock window.matchMedia for tests
Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(), // deprecated
    removeListener: vi.fn(), // deprecated
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})

// Mock ResizeObserver which is not implemented in JSDOM
Object.defineProperty(window, "ResizeObserver", {
  writable: true,
  value: vi.fn().mockImplementation(() => ({
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn(),
  })),
})

// Mock next-themes to avoid matchMedia issues
vi.mock("next-themes", () => ({
  ThemeProvider: ({ children }: { children: React.ReactNode }) => (
    <>{children}</>
  ),
  useTheme: () => ({
    theme: "light",
    setTheme: vi.fn(),
    resolvedTheme: "light",
  }),
}))

// Mock TanStack Router with importOriginal to include all required exports
vi.mock("@tanstack/react-router", async (importOriginal) => {
  try {
    // Try to import the actual module
    const actual =
      await importOriginal<typeof import("@tanstack/react-router")>()
    return {
      ...actual,
      RouterProvider: ({ children }: { children: React.ReactNode }) => (
        <>{children}</>
      ),
      useRouter: () => ({
        navigate: vi.fn(),
        currentRoute: {
          path: "/",
          fullPath: "/",
        },
      }),
      Link: ({ children, to, ...props }: any) => (
        <a href={to} data-testid="router-link" {...props}>
          {children}
        </a>
      ),
      // Add missing exports
      createRootRoute: vi.fn().mockReturnValue({
        addChildren: vi.fn().mockReturnValue({
          addChildren: vi.fn().mockReturnValue({}),
        }),
      }),
      createRoute: vi.fn().mockReturnValue({
        addChildren: vi.fn().mockReturnValue({}),
      }),
      createRouter: vi.fn().mockReturnValue({}),
      useNavigate: () => vi.fn(),
    }
  } catch (error) {
    // Fallback if import fails
    return {
      RouterProvider: ({ children }: { children: React.ReactNode }) => (
        <>{children}</>
      ),
      useRouter: () => ({
        navigate: vi.fn(),
        currentRoute: {
          path: "/",
          fullPath: "/",
        },
      }),
      Link: ({ children, to, ...props }: any) => (
        <a href={to} data-testid="router-link" {...props}>
          {children}
        </a>
      ),
      createRootRoute: vi.fn().mockReturnValue({
        addChildren: vi.fn().mockReturnValue({
          addChildren: vi.fn().mockReturnValue({}),
        }),
      }),
      createRoute: vi.fn().mockReturnValue({
        addChildren: vi.fn().mockReturnValue({}),
      }),
      createRouter: vi.fn().mockReturnValue({}),
      useNavigate: () => vi.fn(),
    }
  }
})
