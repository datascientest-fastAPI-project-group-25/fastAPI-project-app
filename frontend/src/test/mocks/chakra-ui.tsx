import type { ReactNode } from "react"
import type { FC } from "react"
import { vi } from "vitest"

// Mock implementation for useBreakpointValue
export const mockUseBreakpointValue = vi.fn().mockImplementation((values) => {
  // Default to returning the md value, or base if md is not provided
  return values.md || values.base
})

// Mock implementation for useColorMode
export const mockUseColorMode = vi.fn().mockReturnValue({
  colorMode: "light",
  toggleColorMode: vi.fn(),
})

// Mock implementation for useDisclosure
export const mockUseDisclosure = vi.fn().mockReturnValue({
  isOpen: false,
  onOpen: vi.fn(),
  onClose: vi.fn(),
  onToggle: vi.fn(),
  isControlled: false,
  getButtonProps: vi.fn().mockReturnValue({}),
  getDisclosureProps: vi.fn().mockReturnValue({}),
})

// Create a mock for the entire @chakra-ui/react module
export const createChakraMock = () => {
  const ChakraProvider: FC<{ children: ReactNode }> = ({ children }) => (
    <>{children}</>
  )
  const Box: FC<any> = ({ children, ...props }) => (
    <div data-testid="chakra-box" {...props}>
      {children}
    </div>
  )
  const Flex: FC<any> = ({ children, ...props }) => (
    <div data-testid="chakra-flex" {...props}>
      {children}
    </div>
  )
  const Text: FC<any> = ({ children, ...props }) => (
    <span data-testid="chakra-text" {...props}>
      {children}
    </span>
  )
  const Button: FC<any> = ({ children, ...props }) => (
    <button type="button" data-testid="chakra-button" {...props}>
      {children}
    </button>
  )
  const IconButton: FC<any> = ({ "aria-label": ariaLabel, ...props }) => (
    <button
      type="button"
      data-testid="chakra-icon-button"
      aria-label={ariaLabel}
      {...props}
    />
  )
  const Image: FC<{
    alt?: string
    src?: string
  }> = ({ alt, src }) => (
    <img
      data-testid="chakra-image"
      alt={alt || "Descriptive alt text for image"}
      src={src}
    />
  )
  const Menu: FC<any> = ({ children, ...props }) => (
    <div data-testid="chakra-menu" {...props}>
      {children}
    </div>
  )
  const MenuButton: FC<any> = ({ children, ...props }) => (
    <button type="button" data-testid="chakra-menu-button" {...props}>
      {children}
    </button>
  )
  const MenuList: FC<any> = ({ children, ...props }) => (
    <div data-testid="chakra-menu-list" {...props}>
      {children}
    </div>
  )
  const MenuItem: FC<any> = ({ children, ...props }) => (
    <div data-testid="chakra-menu-item" {...props}>
      {children}
    </div>
  )

  return {
    ChakraProvider,
    Box,
    Flex,
    Text,
    Button,
    IconButton,
    Image,
    Menu,
    MenuButton,
    MenuList,
    MenuItem,
    useBreakpointValue: mockUseBreakpointValue,
    useColorMode: mockUseColorMode,
    useDisclosure: mockUseDisclosure,
  }
}

// Setup function to mock Chakra UI in tests
export const setupChakraMocks = () => {
  vi.mock("@chakra-ui/react", async () => {
    const actual = await vi.importActual("@chakra-ui/react")
    return {
      ...(actual as object),
      ...createChakraMock(),
    }
  })
}

// Reset function to clear all mocks
export const resetChakraMocks = () => {
  mockUseBreakpointValue.mockClear()
  mockUseColorMode.mockClear()
  mockUseDisclosure.mockClear()
}
