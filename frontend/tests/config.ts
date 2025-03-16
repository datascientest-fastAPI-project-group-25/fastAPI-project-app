import path from "node:path";
import { fileURLToPath } from "node:url";
import dotenv from "dotenv";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Try to load environment variables from different locations
dotenv.config({ path: path.join(__dirname, "../.env") });
dotenv.config({ path: path.join(__dirname, "../../.env") });

// Default values for tests if environment variables are not set
const FIRST_SUPERUSER = process.env.FIRST_SUPERUSER || "admin@yourdomain.com";
const FIRST_SUPERUSER_PASSWORD =
  process.env.FIRST_SUPERUSER_PASSWORD || "your_secure_password_here";

// Export the values for use in tests
export const firstSuperuser = FIRST_SUPERUSER;
export const firstSuperuserPassword = FIRST_SUPERUSER_PASSWORD;

// Log the values being used (helpful for debugging)
console.log(`Using test credentials: ${FIRST_SUPERUSER} / [password hidden]`);
