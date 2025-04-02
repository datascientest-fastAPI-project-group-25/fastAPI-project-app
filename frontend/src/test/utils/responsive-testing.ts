import { vi } from "vitest"

// Breakpoint sizes based on common device widths
export enum BreakpointSize {
  XS = "xs", // Extra small (< 480px)
  SM = "sm", // Small (≥ 480px)
  MD = "md", // Medium (≥ 768px)
  LG = "lg", // Large (≥ 992px)
  XL = "xl", // Extra large (≥ 1280px)
  XXL = "2xl", // Extra extra large (≥ 1536px)
}

// Mock window.matchMedia for different breakpoints
export const mockMediaQuery = (breakpoint: BreakpointSize): void => {
  // Define breakpoint values in pixels
  const breakpointValues = {
    [BreakpointSize.XS]: 0,
    [BreakpointSize.SM]: 480,
    [BreakpointSize.MD]: 768,
    [BreakpointSize.LG]: 992,
    [BreakpointSize.XL]: 1280,
    [BreakpointSize.XXL]: 1536,
  }

  // Create a function to check if a media query matches the current breakpoint
  const matchMediaMock = (query: string): MediaQueryList => {
    // Parse the min-width value from the query
    const minWidthMatch = query.match(/min-width:\s*(\d+)px/)
    const maxWidthMatch = query.match(/max-width:\s*(\d+)px/)

    let matches = false

    if (minWidthMatch) {
      const minWidth = Number.parseInt(minWidthMatch[1], 10)
      matches = breakpointValues[breakpoint] >= minWidth
    } else if (maxWidthMatch) {
      const maxWidth = Number.parseInt(maxWidthMatch[1], 10)
      matches = breakpointValues[breakpoint] <= maxWidth
    }

    return {
      matches,
      media: query,
      onchange: null,
      addListener: vi.fn(), // deprecated
      removeListener: vi.fn(), // deprecated
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    }
  }

  // Mock window.matchMedia
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    value: matchMediaMock,
  })
}

// Mock useBreakpointValue for different breakpoints
export const mockUseBreakpointValue = (breakpoint: BreakpointSize): void => {
  // Import the mock directly from vitest
  const mockUseBreakpointValue = vi.fn()

  // Mock the implementation based on the breakpoint
  mockUseBreakpointValue.mockImplementation((values: Record<string, any>) => {
    // Return the value for the specified breakpoint, or fall back to smaller breakpoints
    const breakpointOrder = [
      BreakpointSize.XXL,
      BreakpointSize.XL,
      BreakpointSize.LG,
      BreakpointSize.MD,
      BreakpointSize.SM,
      BreakpointSize.XS,
      "base",
    ]

    const breakpointIndex = breakpointOrder.indexOf(breakpoint)

    // Look for a value starting from the current breakpoint and going down
    for (let i = breakpointIndex; i < breakpointOrder.length; i++) {
      const bp = breakpointOrder[i]
      if (values[bp] !== undefined) {
        return values[bp]
      }
    }

    // If no matching breakpoint is found, return the base value or undefined
    return values.base
  })
}

// Reset all responsive testing mocks
export const resetResponsiveMocks = (): void => {
  vi.restoreAllMocks()
}
