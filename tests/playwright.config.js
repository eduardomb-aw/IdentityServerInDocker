// playwright.config.js
import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for IdentityServer + AdminUI Docker testing
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['html'],
    ['list'],
    ['junit', { outputFile: 'results.xml' }]
  ],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    // baseURL: 'https://localhost:5003',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
    
    /* Take screenshot on failure */
    screenshot: 'only-on-failure',
    
    /* Ignore HTTPS errors for self-signed certificates */
    ignoreHTTPSErrors: true,
    
    /* Set timeout for each action */
    actionTimeout: 10000,
    
    /* Set timeout for navigation */
    navigationTimeout: 30000,
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },

    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },

    /* Test against mobile viewports. */
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },

    /* Test against branded browsers. */
    {
      name: 'Microsoft Edge',
      use: { ...devices['Desktop Edge'], channel: 'msedge' },
    },
    {
      name: 'Google Chrome',
      use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    },
  ],

  /* Run your local dev server before starting the tests */
  webServer: [
    {
      command: 'docker-compose ps',
      port: 5001,
      reuseExistingServer: true,
      ignoreHTTPSErrors: true,
    },
    {
      command: 'docker-compose ps', 
      port: 5003,
      reuseExistingServer: true,
      ignoreHTTPSErrors: true,
    }
  ],
  
  /* Global timeout for the entire test suite */
  globalTimeout: 300000, // 5 minutes
  
  /* Timeout for each test */
  timeout: 60000, // 1 minute per test
  
  /* Expect timeout for assertions */
  expect: {
    timeout: 10000 // 10 seconds for expect assertions
  },
  
  /* Output directory for test results */
  outputDir: 'test-results/',
});