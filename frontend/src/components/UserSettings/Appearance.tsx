import { Container, Heading, Stack } from "@chakra-ui/react"
import { useState, useEffect } from "react"

import { Radio, RadioGroup } from "@/components/ui/radio"

const Appearance = () => {
  const [theme, setTheme] = useState<string>(
    localStorage.getItem("theme") || "system",
  )

  useEffect(() => {
    const root = window.document.documentElement
    root.classList.remove("light", "dark")
    root.classList.add(theme)

    // Save theme preference to localStorage
    localStorage.setItem("theme", theme)
  }, [theme])

  return (
    <>
      <Container maxW="full">
        <Heading size="sm" py={4}>
          Appearance
        </Heading>

        <RadioGroup
          onValueChange={(e) => {
            if (e && e.value) {
              setTheme(e.value)
            }
          }}
          value={theme}
          colorPalette="teal"
        >
          <Stack>
            <Radio value="system">System</Radio>
            <Radio value="light">Light Mode</Radio>
            <Radio value="dark">Dark Mode</Radio>
          </Stack>
        </RadioGroup>
      </Container>
    </>
  )
}
export default Appearance
