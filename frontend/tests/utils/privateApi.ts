// Mock the PrivateService since it's not available in the generated client
import { OpenAPI } from "../../src/client";

OpenAPI.BASE = `${process.env.VITE_API_URL || "http://api.localhost"}`;

// Create a mock PrivateService for testing
const PrivateService = {
  createUser: async ({
    requestBody,
  }: {
    requestBody: {
      email: string;
      is_verified?: boolean;
      full_name?: string;
      password: string;
    };
  }) => {
    // For tests, we'll just return a mock response
    // In a real scenario, we would make an actual API call
    console.log("Mock createUser called with:", requestBody);
    return {
      id: "mock-user-id",
      email: requestBody.email,
      is_active: true,
      is_superuser: false,
      is_verified: requestBody.is_verified,
      full_name: requestBody.full_name,
    };
  },
};

export const createUser = async ({
  email,
  password,
}: {
  email: string;
  password: string;
}) => {
  return await PrivateService.createUser({
    requestBody: {
      email,
      password,
      is_verified: true,
      full_name: "Test User",
    },
  });
};
