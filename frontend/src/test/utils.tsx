import React, { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { system } from '../theme'; // Import the system theme

// Create a fresh query client for each test to avoid cache issues
const createTestQueryClient = () => new QueryClient({
  defaultOptions: {
    queries: {
      retry: false, // Disable retries for tests
    },
  },
});

// Custom render function that includes all necessary providers
interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  queryClient?: QueryClient;
}

export function renderWithProviders(
  ui: ReactElement,
  {
    queryClient = createTestQueryClient(),
    ...renderOptions
  }: CustomRenderOptions = {}
) {
  function AllTheProviders({ children }: { children: React.ReactNode }) {
    return (
      <ChakraProvider value={system}>
        <QueryClientProvider client={queryClient}>
          {children}
        </QueryClientProvider>
      </ChakraProvider>
    );
  }

  return render(ui, { wrapper: AllTheProviders, ...renderOptions });
}

// Re-export everything from testing-library
export * from '@testing-library/react';

// Override the render method with our custom render
export { renderWithProviders as render };
