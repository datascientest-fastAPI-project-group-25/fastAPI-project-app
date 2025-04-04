import { ChakraProvider } from "@chakra-ui/react"
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { RouterProvider, createRouter } from "@tanstack/react-router"
import {
  type RenderOptions,
  render as rtlRender,
  screen,
} from "@testing-library/react"
import type React from "react"
import type { ReactElement } from "react"
import { ColorModeProvider } from "../components/ui/color-mode"
import { Toaster } from "../components/ui/toaster"
import { routeTree } from "../routeTree.gen"
import { system } from "../theme"

const createTestQueryClient = () => {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
}

export function renderWithProviders(
  ui: ReactElement,
  {
    route = "/",
    ...renderOptions
  }: { route?: string } & Omit<RenderOptions, "wrapper"> = {},
) {
  const testQueryClient = createTestQueryClient()
  const router = createRouter({
    routeTree,
    defaultPreload: "intent",
    context: {},
  })

  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={testQueryClient}>
      <ChakraProvider value={system}>
        <ColorModeProvider defaultTheme="light">
          <RouterProvider router={router} />
          {children}
          <Toaster />
        </ColorModeProvider>
      </ChakraProvider>
    </QueryClientProvider>
  )

  return rtlRender(ui, { wrapper: Wrapper, ...renderOptions })
}

// Re-export everything
export * from "@testing-library/react"
export { renderWithProviders as render, screen }
