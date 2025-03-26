import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import { useNavigate } from "@tanstack/react-router"
import { useState } from "react"
import useCustomToast from "./useCustomToast"

import {
  type Body_login_login_access_token as AccessToken,
  type ApiError,
  type UserPublic,
  type UserRegister,
  UsersService,
} from "@/client"

const isLoggedIn = () => {
  return localStorage.getItem("access_token") !== null
}

const useAuth = () => {
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { showSuccessToast, showErrorToast } = useCustomToast()

  const { data: user } = useQuery<UserPublic | null, Error>({
    queryKey: ["currentUser"],
    queryFn: UsersService.readUserMe,
    enabled: isLoggedIn(),
  })

  // Custom error handler for authentication issues
  const handleAuthError = (err: ApiError) => {
    console.error("Authentication error:", err)
    const errDetail = (err.body as { detail?: string | Array<{ msg: string }> })
      ?.detail
    let errorMessage = "Authentication failed. Please check your credentials."

    if (typeof errDetail === "string") {
      errorMessage = errDetail
    } else if (Array.isArray(errDetail) && errDetail.length > 0) {
      errorMessage = errDetail[0].msg
    }

    setError(errorMessage)

    showErrorToast(errorMessage)
  }

  const signUpMutation = useMutation({
    mutationFn: (data: UserRegister) =>
      UsersService.registerUser({ requestBody: data }),

    onSuccess: () => {
      navigate({ to: "/login" })
    },
    onError: (err: ApiError) => {
      handleAuthError(err)
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] })
    },
  })

  const login = async (data: AccessToken) => {
    try {
      console.log("Attempting login with:", { username: data.username })
      console.log(
        "Using API URL:",
        import.meta.env.VITE_API_URL || "Not set in env",
      )

      // Check if we're using the correct credentials from memory
      if (data.username === "admin@example.com") {
        console.log("Using admin credentials from memory")
      }

      // Create a proper URLSearchParams object for form data
      const formData = new URLSearchParams()
      formData.append("username", data.username)
      formData.append("password", data.password)
      formData.append("grant_type", "password")

      console.log("Sending login request with credentials for:", data.username)
      console.log("Form data being sent:", formData.toString())

      // Use fetch directly with the correct content type
      const apiUrl = import.meta.env.VITE_API_URL || "http://api.localhost"
      console.log("Using API URL:", apiUrl)

      const res = await fetch(`${apiUrl}/api/v1/login/access-token`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: formData,
      })

      // Enhanced error handling - capture the response text for better debugging
      if (!res.ok) {
        const errorText = await res.text()
        console.error(`Login failed with status: ${res.status}`, {
          status: res.status,
          statusText: res.statusText,
          errorText,
        })
        throw new Error(
          `Login failed: ${res.status} ${res.statusText} - ${
            errorText || "No error details"
          }`,
        )
      }

      const response = await res.json()
      console.log("Login response received:", response)

      if (response?.access_token) {
        console.log("Storing access token in localStorage")
        localStorage.setItem("access_token", response.access_token)
        console.log(
          "Token stored successfully:",
          localStorage.getItem("access_token"),
        )
        return response
      }
      console.error("No access token in response", response)
      throw new Error("No access token received in response")
    } catch (error) {
      // Improved error logging
      console.error("Login error:", {
        message: error instanceof Error ? error.message : "Unknown error",
        error,
      })

      // Attempt to extract more information from the error
      if (error instanceof Error) {
        setError(`Authentication failed: ${error.message}`)
      } else {
        setError("Authentication failed: Unknown error occurred")
      }

      throw error
    }
  }

  const loginMutation = useMutation({
    mutationFn: login,
    onSuccess: () => {
      console.log("Login successful, redirecting to home")
      showSuccessToast("Welcome back!")
      navigate({ to: "/" })
    },
    onError: (err: unknown) => {
      console.error("Login mutation error:", {
        message: err instanceof Error ? err.message : "Unknown error",
        error: err,
      })

      // Improved error handling
      if (err instanceof Error) {
        setError(`Authentication failed: ${err.message}`)
      } else {
        setError("Authentication failed: Unknown error occurred")
      }

      // Still call the original handler
      handleAuthError(err as ApiError)
    },
  })

  const logout = () => {
    localStorage.removeItem("access_token")
    navigate({ to: "/login" })
  }

  return {
    signUpMutation,
    loginMutation,
    logout,
    user,
    error,
    resetError: () => setError(null),
  }
}

export { isLoggedIn }
export default useAuth
