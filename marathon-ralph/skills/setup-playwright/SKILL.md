---
name: setup-playwright
description: Configure Playwright for E2E testing. Use when setting up end-to-end tests, when no E2E framework is detected, or when the user asks to configure browser testing.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Setup Playwright

Configure Playwright as the end-to-end testing framework with fixtures and best practices.

## When to Use This Skill

- No E2E framework is configured in the project
- User requests to set up E2E testing
- Project is a web application needing browser testing
- Migrating from Cypress to Playwright

## Installation

Use `ni` to auto-detect the package manager:

```bash
# Install Playwright
ni -D @playwright/test

# Install browsers
npx playwright install --with-deps

# For CI optimization, install only needed browsers
npx playwright install chromium --with-deps
```

## Configuration

### playwright.config.ts

Create `playwright.config.ts` at the project root:

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  // Test directory
  testDir: './tests/e2e',

  // Run tests in parallel
  fullyParallel: true,

  // Fail build on CI if test.only is left in code
  forbidOnly: !!process.env.CI,

  // Retry failed tests (more on CI)
  retries: process.env.CI ? 2 : 0,

  // Parallel workers
  workers: process.env.CI ? 1 : undefined,

  // Reporter configuration
  reporter: process.env.CI
    ? [['github'], ['html', { open: 'never' }]]
    : [['list'], ['html']],

  // Timeouts
  timeout: 30000,
  expect: {
    timeout: 5000,
  },

  // Shared settings for all projects
  use: {
    // Base URL for page.goto('/')
    baseURL: process.env.BASE_URL || 'http://localhost:3000',

    // Collect trace on first retry
    trace: 'on-first-retry',

    // Screenshot on failure
    screenshot: 'only-on-failure',

    // Video on first retry
    video: 'on-first-retry',
  },

  // Browser projects
  projects: [
    // Setup project for authentication
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
    },

    // Desktop Chrome
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },

    // Desktop Firefox (optional)
    {
      name: 'firefox',
      use: {
        ...devices['Desktop Firefox'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },

    // Desktop Safari (optional)
    {
      name: 'webkit',
      use: {
        ...devices['Desktop Safari'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },

    // Mobile Chrome (optional)
    {
      name: 'Mobile Chrome',
      use: {
        ...devices['Pixel 5'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],

  // Run dev server before tests
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
})
```

### Directory Structure

Create the recommended directory structure:

```
project/
├── tests/
│   └── e2e/
│       ├── fixtures/
│       │   └── test-fixtures.ts    # Custom fixtures
│       ├── pages/
│       │   ├── login.page.ts       # Page objects
│       │   └── home.page.ts
│       ├── auth.setup.ts           # Authentication setup
│       ├── home.spec.ts            # Test files
│       └── login.spec.ts
├── playwright/
│   └── .auth/
│       └── .gitkeep                # Auth state storage
├── playwright.config.ts
└── package.json
```

Create the directories:

```bash
mkdir -p tests/e2e/fixtures tests/e2e/pages playwright/.auth
touch playwright/.auth/.gitkeep
```

### .gitignore

Add to `.gitignore`:

```gitignore
# Playwright
playwright-report/
test-results/
playwright/.auth/
!playwright/.auth/.gitkeep
```

### Package.json Scripts

Add test scripts:

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:headed": "playwright test --headed",
    "test:e2e:debug": "playwright test --debug",
    "test:e2e:report": "playwright show-report"
  }
}
```

## Authentication Setup

Create `tests/e2e/auth.setup.ts` for shared authentication:

```typescript
import { test as setup, expect } from '@playwright/test'

const authFile = 'playwright/.auth/user.json'

setup('authenticate', async ({ page }) => {
  // Navigate to login
  await page.goto('/login')

  // Fill credentials
  await page.getByLabel(/email/i).fill('test@example.com')
  await page.getByLabel(/password/i).fill('password123')
  await page.getByRole('button', { name: /sign in/i }).click()

  // Wait for authentication to complete
  await expect(page).toHaveURL('/dashboard')

  // Save authentication state
  await page.context().storageState({ path: authFile })
})
```

## Custom Fixtures

Create `tests/e2e/fixtures/test-fixtures.ts`:

```typescript
import { test as base, expect } from '@playwright/test'
import { LoginPage } from '../pages/login.page'
import { HomePage } from '../pages/home.page'

// Declare fixture types
type MyFixtures = {
  loginPage: LoginPage
  homePage: HomePage
}

// Extend base test with custom fixtures
export const test = base.extend<MyFixtures>({
  loginPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page)
    await use(loginPage)
  },

  homePage: async ({ page }, use) => {
    const homePage = new HomePage(page)
    await use(homePage)
  },
})

export { expect }
```

## Page Object Model

Create `tests/e2e/pages/login.page.ts`:

```typescript
import { type Page, type Locator } from '@playwright/test'

export class LoginPage {
  readonly page: Page
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly submitButton: Locator
  readonly errorMessage: Locator

  constructor(page: Page) {
    this.page = page
    this.emailInput = page.getByLabel(/email/i)
    this.passwordInput = page.getByLabel(/password/i)
    this.submitButton = page.getByRole('button', { name: /sign in/i })
    this.errorMessage = page.getByRole('alert')
  }

  async goto() {
    await this.page.goto('/login')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }
}
```

## GitHub Actions CI

Create `.github/workflows/playwright.yml`:

```yaml
name: Playwright Tests

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  test:
    timeout-minutes: 60
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: lts/*
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright Browsers
        run: npx playwright install chromium --with-deps

      - name: Run Playwright tests
        run: npx playwright test

      - uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

## Verification

After setup, verify with:

```bash
# Run all tests
nr test:e2e

# Run in UI mode
nr test:e2e:ui

# Run headed (visible browser)
nr test:e2e:headed

# Debug mode
nr test:e2e:debug

# View report
nr test:e2e:report
```

## Key Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `testDir` | Directory containing tests | `./tests` |
| `fullyParallel` | Run tests in parallel | `true` |
| `retries` | Retry failed tests | `0` |
| `workers` | Parallel workers | Auto |
| `timeout` | Test timeout (ms) | `30000` |
| `trace` | Trace collection | `'on-first-retry'` |
| `screenshot` | Screenshot capture | `'only-on-failure'` |
| `video` | Video recording | `'off'` |
| `baseURL` | Base URL for navigation | Required |

## CLI Commands Reference

| Command | Description |
|---------|-------------|
| `npx playwright test` | Run all tests |
| `npx playwright test --ui` | UI mode |
| `npx playwright test --headed` | Visible browser |
| `npx playwright test --debug` | Debug mode |
| `npx playwright test file.spec.ts` | Run specific file |
| `npx playwright test --project=chromium` | Run specific project |
| `npx playwright codegen` | Generate tests |
| `npx playwright show-report` | Open HTML report |
