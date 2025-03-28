import { createSystem } from '@chakra-ui/react';

// Create a minimal test system for testing
export const testSystem = createSystem({
  theme: {
    tokens: {
      sizes: {
        container: {
          sm: { value: "640px" },
          md: { value: "768px" },
          lg: { value: "1024px" },
          xl: { value: "1280px" }
        }
      },
      breakpoints: {
        base: { value: "0px" },
        sm: { value: "480px" },
        md: { value: "768px" },
        lg: { value: "992px" },
        xl: { value: "1280px" }
      },
      colors: {
        gray: {
          "100": { value: "#f7fafc" },
          "200": { value: "#edf2f7" }
        }
      }
    },
  }
});
