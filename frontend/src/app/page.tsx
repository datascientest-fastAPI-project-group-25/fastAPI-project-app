"use client"

import { Box, Container, Paper, Typography } from "@mui/material"
import { useEffect, useState } from "react"

interface HealthStatus {
  status: string
}

export default function Home() {
  const [health, setHealth] = useState<HealthStatus | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/health`,
        )
        const data = await response.json()
        setHealth(data)
      } catch (err) {
        setError("Failed to connect to the API")
        console.error("Health check failed:", err)
      }
    }

    checkHealth()
  }, [])

  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Typography variant="h2" component="h1" gutterBottom>
          DevOps Demo
        </Typography>
        <Paper sx={{ p: 3, mt: 2 }}>
          <Typography variant="h5" gutterBottom>
            API Health Status
          </Typography>
          {health ? (
            <Typography
              color={
                health.status === "healthy" ? "success.main" : "error.main"
              }
            >
              {health.status}
            </Typography>
          ) : error ? (
            <Typography color="error.main">{error}</Typography>
          ) : (
            <Typography>Checking health status...</Typography>
          )}
        </Paper>
      </Box>
    </Container>
  )
}
