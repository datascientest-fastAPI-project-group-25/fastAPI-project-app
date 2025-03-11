# 🕹️ DevOps Demo Application - Frontend

![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black) ![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white) ![Vite](https://img.shields.io/badge/Vite-646CFF?style=for-the-badge&logo=vite&logoColor=white) ![Chakra UI](https://img.shields.io/badge/Chakra_UI-319795?style=for-the-badge&logo=chakra-ui&logoColor=white)

The frontend of our DevOps demo application is a modern, responsive web interface built with cutting-edge technologies:

- **[Vite](https://vitejs.dev/)**: Next-generation frontend tooling
- **[React](https://reactjs.org/)**: Component-based UI library
- **[TypeScript](https://www.typescriptlang.org/)**: Type-safe JavaScript
- **[TanStack Query](https://tanstack.com/query)**: Data fetching and state management
- **[TanStack Router](https://tanstack.com/router)**: Type-safe routing
- **[Chakra UI](https://chakra-ui.com/)**: Accessible component library

## 💻 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Development Setup](#-development-setup)
  - [Docker-based Development](#docker-based-development)
  - [Local Development](#local-development)
- [Project Structure](#-project-structure)
- [Testing](#-testing)
- [Building for Production](#-building-for-production)
- [Deployment](#-deployment)

## ✨ Features

- **Modern React with Hooks**: Functional components and React hooks
- **Type-safe Development**: Full TypeScript integration
- **Responsive Design**: Mobile-first approach with Chakra UI
- **Efficient Data Fetching**: TanStack Query for API interactions
- **Declarative Routing**: Type-safe routing with TanStack Router
- **Dark/Light Mode**: Built-in theme support
- **Authentication**: JWT-based authentication flow

## 📍 Requirements

- [Node.js](https://nodejs.org/) 18+ (use nvm or fnm for version management)
- [npm](https://www.npmjs.com/) 9+ (comes with Node.js)
- [Docker](https://www.docker.com/) (optional, for containerized development)

## 🔧 Development Setup

### Docker-based Development

The easiest way to get started is using Docker Compose from the project root:

```bash
# From the project root directory
docker compose up -d
```

This will start:
- Frontend at http://dashboard.localhost
- Backend API at http://api.localhost
- Database and other services

### Local Development

For a more responsive development experience, you can run the frontend locally.

1. **Node.js Version Management**

Before you begin, ensure that you have either the Node Version Manager (nvm) or Fast Node Manager (fnm) installed:

```bash
# Install fnm (recommended)
# macOS with Homebrew
brew install fnm

# Or install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
```

2. **Install Dependencies**

```bash
# Navigate to frontend directory
cd frontend

# Use the correct Node.js version
fnm use    # or: nvm use

# Install dependencies
npm install
```

3. **Start Development Server**

```bash
npm run dev
```

The development server will start at http://localhost:5173 with hot module replacement enabled.

## 📂 Project Structure

```
frontend/
├── public/              # Static assets
├── src/
│   ├── api/              # API client and hooks
│   ├── components/       # Reusable UI components
│   ├── features/          # Feature-specific components
│   ├── hooks/             # Custom React hooks
│   ├── lib/               # Utilities and helpers
│   ├── providers/         # Context providers
│   ├── routes/            # Application routes
│   ├── theme/             # Chakra UI theme customization
│   ├── types/             # TypeScript type definitions
│   ├── App.tsx            # Main application component
│   └── main.tsx           # Application entry point
├── .eslintrc.js         # ESLint configuration
├── package.json         # Dependencies and scripts
├── tsconfig.json        # TypeScript configuration
└── vite.config.ts        # Vite configuration
```

## 🧪 Testing

The frontend includes a test suite using Vitest and React Testing Library:

```bash
# Run tests
npm test

# Run tests with coverage
npm test -- --coverage

# Run tests in watch mode
npm test -- --watch
```

## 💾 Building for Production

To create a production build:

```bash
npm run build
```

The build output will be in the `dist` directory. You can preview the production build locally:

```bash
npm run preview
```

## 🚀 Deployment

The frontend is designed to be deployed as a static site or as a Docker container. The deployment is handled automatically by GitHub Actions when changes are pushed to the appropriate branches.

### Environment Variables

The frontend uses environment variables for configuration. In development, these are defined in `.env.development`. For production, they are injected during the build process.

Key environment variables:

| Variable | Purpose | Example |
|----------|---------|--------|
| `VITE_API_URL` | Backend API URL | `https://api.example.com` |
| `VITE_APP_ENV` | Application environment | `production` |

For more information on the deployment process, see the CI/CD Pipeline section in the main README.
