import {
  MutationCache,
  QueryCache,
  QueryClient,
  QueryClientProvider,
} from "@tanstack/react-query"
import { RouterProvider, createRouter } from "@tanstack/react-router"
import { StrictMode } from "react"
import ReactDOM from "react-dom/client"
import { routeTree } from "./routeTree.gen"

import { ApiError, OpenAPI } from "./client"
import { CustomProvider } from "./components/ui/provider"

// Use the correct API URL for the FastAPI backend
// The backend API is available through Traefik routing
OpenAPI.BASE = import.meta.env.VITE_API_URL || "http://api.localhost"
console.log("API Base URL set to:", OpenAPI.BASE)
OpenAPI.TOKEN = async () => {
  return localStorage.getItem("access_token") || ""
}

const handleApiError = (error: Error) => {
  if (error instanceof ApiError && [401, 403].includes(error.status)) {
    localStorage.removeItem("access_token")
    window.location.href = "/login"
  }
}
const queryClient = new QueryClient({
  queryCache: new QueryCache({
    onError: handleApiError,
  }),
  mutationCache: new MutationCache({
    onError: handleApiError,
  }),
})

const router = createRouter({ routeTree })
declare module "@tanstack/react-router" {
  interface Register {
    router: typeof router
  }
}

function InnerApp() {
  return <RouterProvider router={router} />
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <CustomProvider>
      <QueryClientProvider client={queryClient}>
        <InnerApp />
      </QueryClientProvider>
    </CustomProvider>
  </StrictMode>,
)

// Custom error handling for API errors
ApiError.prototype.toString = function () {
  let message = `API Error: ${this.status} ${this.statusText} - ${this.url}\n`
  if (this.body && typeof this.body === "object") {
    // Safely check for detail property using a type guard
    let detailMessage = JSON.stringify(this.body) // Default
    if ("detail" in this.body && typeof this.body.detail === "string") {
      detailMessage = this.body.detail
    } else if ("detail" in this.body && Array.isArray(this.body.detail)) {
      // Handle cases like HTTPValidationError where detail is an array of objects
      try {
        detailMessage = this.body.detail
          .map((err: any) => `${err.loc?.join(".") || "error"}: ${err.msg}`)
          .join(", ")
      } catch (e) {
        // Fallback if mapping fails
        detailMessage = JSON.stringify(this.body.detail)
      }
    }
    message += `Detail: ${detailMessage}`
  } else if (this.body) {
    message += `Body: ${this.body}`
  }
  return message
}
