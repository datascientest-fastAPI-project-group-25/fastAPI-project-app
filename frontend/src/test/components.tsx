import type React from "react"

// Mock ChakraProvider that just renders children
export const ChakraProvider: React.FC<any> = ({ children }) => <>{children}</>

// Additional components
export const Button: React.FC<any> = ({ children, ...props }) => (
  <button type="button" {...props} data-testid="chakra-button">
    {children}
  </button>
)

// Simple component implementations for testing
export const Box: React.FC<any> = ({ children, ...props }) => (
  <div {...props} data-testid="chakra-box">
    {children}
  </div>
)

export const Flex: React.FC<any> = ({ children, ...props }) => (
  <div
    role="group"
    {...props}
    data-testid="chakra-flex"
    style={{ display: "flex" }}
  >
    {children}
  </div>
)

export const Link: React.FC<any> = ({ children, ...props }) => (
  <a {...props} data-testid="chakra-link">
    {children}
  </a>
)

export const Image: React.FC<{
  alt?: string
  src?: string
  h?: string
  display?: string
}> = ({ alt, src, h, display }) => (
  <img
    alt={alt || "Descriptive alt text for image"}
    src={src}
    data-testid="chakra-image"
  />
)

export const Menu: React.FC<any> = ({ children, ...props }) => (
  <div role="menu" {...props} data-testid="chakra-menu">
    {children}
  </div>
)

export const MenuButton: React.FC<any> = ({ children, ...props }) => (
  <button type="button" {...props} data-testid="chakra-menu-button">
    {children}
  </button>
)

export const MenuList: React.FC<any> = ({ children, ...props }) => (
  <div role="menu" {...props} data-testid="chakra-menu-list">
    {children}
  </div>
)

export const MenuItem: React.FC<any> = ({ children, ...props }) => (
  <div role="menuitem" {...props} data-testid="chakra-menu-item">
    {children}
  </div>
)

// Mock hooks
export const useBreakpointValue = (values: any) => values.md || values.base
export const useColorMode = () => ({
  colorMode: "light",
  toggleColorMode: () => {},
})
export const useDisclosure = () => ({
  isOpen: false,
  onOpen: () => {},
  onClose: () => {},
})

// Export all mocked components and hooks
export const chakra = {
  div: Box,
  button: Button,
}
