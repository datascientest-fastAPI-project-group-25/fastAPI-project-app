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
    const errDetail = (err.body as any)?.detail
    let errorMessage = errDetail || "Authentication failed. Please check your credentials."
    
    if (Array.isArray(errDetail) && errDetail.length > 0) {
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
      console.log("Using API URL:", import.meta.env.VITE_API_URL || 'Not set in env')
      
      // Check if we're using the correct credentials from memory
      if (data.username === 'admin@example.com') {
        console.log("Using admin credentials from memory")
      }
      
      // Create a proper URLSearchParams object for form data
      const formData = new URLSearchParams();
      formData.append('username', data.username);
      formData.append('password', data.password);
      formData.append('grant_type', 'password');
      
      console.log("Sending login request with credentials for:", data.username)
      console.log("Form data being sent:", formData.toString())
      
      // Use fetch directly with the correct content type
      const apiUrl = import.meta.env.VITE_API_URL || 'http://api.localhost';
      console.log("Using API URL:", apiUrl)
      
      const response = await fetch(`${apiUrl}/api/v1/login/access-token`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData,
      }).then(res => {
        if (!res.ok) {
          throw new Error(`Login failed with status: ${res.status}`);
        }
        return res.json();
      })
      
      console.log("Login response received:", response)
      
      if (response && response.access_token) {
        console.log("Storing access token in localStorage")
        localStorage.setItem("access_token", response.access_token)
        console.log("Token stored successfully:", localStorage.getItem("access_token"))
        return response
      } else {
        console.error("No access token in response")
        throw new Error("No access token received")
      }
    } catch (error) {
      console.error("Login error:", error)
      
      // Log more details about the error
      if ((error as any).body) {
        console.error("Error response body:", (error as any).body)
      }
      
      if ((error as any).status) {
        console.error("Error status code:", (error as any).status)
      }
      
      if ((error as any).response) {
        console.error("Error response:", (error as any).response)
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
    onError: (err: ApiError) => {
      console.error("Login mutation error:", err)
      handleAuthError(err)
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
