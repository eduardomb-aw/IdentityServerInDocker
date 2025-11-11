// Playwright AdminUI End-to-End Tests
// This script tests the AdminUI and IdentityServer Docker setup
// Run with: npx playwright test

import { test, expect } from '@playwright/test';

// Configuration for different environments
const CONFIG = {
  identityServerUrl: process.env.IDENTITY_SERVER_URL || 'https://localhost:5001',
  adminUiUrl: process.env.ADMIN_UI_URL || 'https://localhost:5003'
};

test.describe('IdentityServer + AdminUI Docker Setup', () => {
  
  test('AdminUI Dashboard loads and displays correct information', async ({ page }) => {
    // Navigate to AdminUI
    await page.goto(CONFIG.adminUiUrl);
    
    // Verify page title and main content
    await expect(page).toHaveTitle(/Dashboard - Identity Server Admin UI/);
    await expect(page.locator('h1')).toContainText('Identity Server Admin Dashboard');
    
    // Verify statistics cards
    await expect(page.locator('text=3')).toBeVisible(); // Clients count
    await expect(page.locator('text=Clients')).toBeVisible();
    await expect(page.locator('text=1')).toBeVisible(); // API Scopes count
    await expect(page.locator('text=API Scopes')).toBeVisible();
    await expect(page.locator('text=2')).toBeVisible(); // Identity Resources count
    await expect(page.locator('text=Identity Resources')).toBeVisible();
    
    // Verify Quick Actions section
    await expect(page.locator('text=Quick Actions')).toBeVisible();
    await expect(page.locator('text=Manage Clients')).toBeVisible();
    await expect(page.locator('text=View Discovery')).toBeVisible();
    await expect(page.locator('text=Open Identity Server')).toBeVisible();
    
    // Verify System Information table
    await expect(page.locator('text=System Information')).toBeVisible();
    await expect(page.locator('text=Identity Server URL:')).toBeVisible();
    await expect(page.locator('text=https://localhost:5001')).toBeVisible();
    await expect(page.locator('text=Admin UI URL:')).toBeVisible();
    await expect(page.locator('text=https://localhost:5003')).toBeVisible();
    await expect(page.locator('text=Database:')).toBeVisible();
    await expect(page.locator('text=SQL Server')).toBeVisible();
  });

  test('IdentityServer welcome page loads and has correct links', async ({ page }) => {
    // Navigate to IdentityServer
    await page.goto('https://localhost:5001/');
    
    // Verify page title and content
    await expect(page).toHaveTitle(/Identity Server - Identity Server/);
    await expect(page.locator('h1')).toContainText('Identity Server');
    await expect(page.locator('text=Welcome to Identity Server')).toBeVisible();
    
    // Verify sections
    await expect(page.locator('text=Discovery Document')).toBeVisible();
    await expect(page.locator('text=View the OpenID Connect discovery document')).toBeVisible();
    await expect(page.locator('text=Admin UI')).toBeVisible();
    await expect(page.locator('text=Manage clients, resources, and configuration')).toBeVisible();
  });

  test('IdentityServer discovery endpoint returns valid JSON', async ({ page }) => {
    // Navigate to discovery endpoint (with correct hyphen)
    await page.goto('https://localhost:5001/.well-known/openid-configuration');
    
    // Get the page content as text
    const content = await page.textContent('body');
    
    // Verify it's valid JSON and contains expected properties
    const discoveryDoc = JSON.parse(content);
    expect(discoveryDoc.issuer).toBe('https://localhost:5001');
    expect(discoveryDoc.authorization_endpoint).toBe('https://localhost:5001/connect/authorize');
    expect(discoveryDoc.token_endpoint).toBe('https://localhost:5001/connect/token');
    expect(discoveryDoc.userinfo_endpoint).toBe('https://localhost:5001/connect/userinfo');
    expect(discoveryDoc.jwks_uri).toBe('https://localhost:5001/.well-known/openid-configuration/jwks');
    
    // Verify supported scopes
    expect(discoveryDoc.scopes_supported).toContain('openid');
    expect(discoveryDoc.scopes_supported).toContain('profile');
    expect(discoveryDoc.scopes_supported).toContain('api1');
    expect(discoveryDoc.scopes_supported).toContain('offline_access');
    
    // Verify supported grant types
    expect(discoveryDoc.grant_types_supported).toContain('authorization_code');
    expect(discoveryDoc.grant_types_supported).toContain('client_credentials');
    expect(discoveryDoc.grant_types_supported).toContain('refresh_token');
  });

  test('Cross-navigation between IdentityServer and AdminUI works', async ({ page, context }) => {
    // Start at IdentityServer
    await page.goto('https://localhost:5001/');
    
    // Click "Open Admin UI" link
    const [newPage] = await Promise.all([
      context.waitForEvent('page'),
      page.click('text=Open Admin UI')
    ]);
    
    // Verify AdminUI opened in new tab
    await newPage.waitForLoadState();
    await expect(newPage).toHaveTitle(/Dashboard - Identity Server Admin UI/);
    
    // Go back to AdminUI and test "Open Identity Server" link
    await page.goto('https://localhost:5003/');
    
    const [identityServerPage] = await Promise.all([
      context.waitForEvent('page'),
      page.click('text=Open Identity Server')
    ]);
    
    // Verify IdentityServer opened in new tab
    await identityServerPage.waitForLoadState();
    await expect(identityServerPage).toHaveTitle(/Identity Server - Identity Server/);
  });

  test('AdminUI navigation menu works', async ({ page }) => {
    await page.goto('https://localhost:5003/');
    
    // Test Dashboard link
    await page.click('text=Dashboard');
    await expect(page).toHaveURL('https://localhost:5003/Home');
    
    // Test "Identity Server Admin" brand link
    await page.click('text=Identity Server Admin');
    await expect(page).toHaveURL('https://localhost:5003/');
    
    // Test "Identity Server" external link
    const [identityServerPage] = await Promise.all([
      page.context().waitForEvent('page'),
      page.click('a[href="https://localhost:5001"]')
    ]);
    
    await identityServerPage.waitForLoadState();
    await expect(identityServerPage).toHaveTitle(/Identity Server - Identity Server/);
  });

  test('AdminUI Clients page shows expected error (missing view)', async ({ page }) => {
    await page.goto('https://localhost:5003/');
    
    // Click on Clients link
    await page.click('text=Clients');
    
    // Verify we get the expected error about missing view
    await expect(page).toHaveTitle(/Internal Server Error/);
    await expect(page.locator('text=An unhandled exception occurred')).toBeVisible();
    await expect(page.locator('text=The view \'Index\' was not found')).toBeVisible();
    await expect(page.locator('text=/Views/Clients/Index.cshtml')).toBeVisible();
  });

  test('AdminUI placeholder links return to dashboard properly', async ({ page }) => {
    await page.goto('https://localhost:5003/');
    
    // Verify placeholder links exist but don't navigate away
    const apiScopesLink = page.locator('text=API Scopes').locator('..').locator('text=View Details');
    await expect(apiScopesLink).toHaveAttribute('href', '#');
    
    const identityResourcesLink = page.locator('text=Identity Resources').locator('..').locator('text=View Details');
    await expect(identityResourcesLink).toHaveAttribute('href', '#');
    
    const apiResourcesLink = page.locator('text=API Resources').locator('..').locator('text=View Details');
    await expect(apiResourcesLink).toHaveAttribute('href', '#');
  });

  test('System Information displays correct URLs and configuration', async ({ page }) => {
    await page.goto('https://localhost:5003/');
    
    // Verify system information table
    const systemInfoSection = page.locator('text=System Information').locator('..');
    
    await expect(systemInfoSection.locator('text=Identity Server URL:')).toBeVisible();
    await expect(systemInfoSection.locator('a[href="https://localhost:5001"]')).toBeVisible();
    
    await expect(systemInfoSection.locator('text=Admin UI URL:')).toBeVisible();
    await expect(systemInfoSection.locator('text=https://localhost:5003')).toBeVisible();
    
    await expect(systemInfoSection.locator('text=Database:')).toBeVisible();
    await expect(systemInfoSection.locator('text=SQL Server')).toBeVisible();
  });

  test('Page styling and Bootstrap components work correctly', async ({ page }) => {
    await page.goto('https://localhost:5003/');
    
    // Take a screenshot for visual verification
    await page.screenshot({ path: 'adminui-visual-test.png', fullPage: true });
    
    // Verify Bootstrap classes are applied
    await expect(page.locator('.navbar')).toBeVisible();
    await expect(page.locator('.container-fluid')).toBeVisible();
    await expect(page.locator('.card')).toHaveCount(4); // Statistics cards
    await expect(page.locator('.btn')).toHaveCount(4); // Quick action buttons
    await expect(page.locator('.table')).toBeVisible(); // System info table
  });

  test('IdentityServer discovery link works correctly (Issue #5)', async ({ page, context }) => {
    // Navigate to IdentityServer welcome page
    await page.goto('https://localhost:5001/');
    
    // Verify the "View Discovery" link exists
    const discoveryLink = page.locator('text=View Discovery');
    await expect(discoveryLink).toBeVisible();
    
    // Click the discovery link and wait for new tab
    const [discoveryPage] = await Promise.all([
      context.waitForEvent('page'),
      discoveryLink.click()
    ]);
    
    // Wait for the discovery page to load
    await discoveryPage.waitForLoadState();
    
    // Verify we're on the correct discovery endpoint URL
    await expect(discoveryPage).toHaveURL('https://localhost:5001/.well-known/openid-configuration');
    
    // Verify the discovery document loads successfully (not 404)
    const content = await discoveryPage.textContent('body');
    expect(content).not.toContain('404');
    expect(content).not.toContain('Not Found');
    
    // Verify it's valid JSON with expected issuer
    const discoveryDoc = JSON.parse(content);
    expect(discoveryDoc.issuer).toBe('https://localhost:5001');
    expect(discoveryDoc.authorization_endpoint).toBe('https://localhost:5001/connect/authorize');
  });
});

// Known Issues Test Suite
test.describe('Known Issues Documentation', () => {
  
  test('Documents missing Clients view issue', async ({ page }) => {
    // This test documents the known issue for tracking
    console.log('KNOWN ISSUE: AdminUI /Clients route returns 500 error due to missing Views/Clients/Index.cshtml');
    console.log('RESOLUTION: Need to create ClientsController view files');
    
    await page.goto('https://localhost:5003/Clients');
    await expect(page.locator('text=The view \'Index\' was not found')).toBeVisible();
  });
  
  test('Documents discovery URL inconsistency', async ({ page }) => {
    // This test documents the URL format inconsistency
    console.log('KNOWN ISSUE: Some links use openid_configuration (underscore) vs openid-configuration (hyphen)');
    console.log('ACTUAL ENDPOINT: Uses openid-configuration (hyphen) which is correct');
    console.log('RESOLUTION: Update UI link texts to match the correct format');
    
    // Verify the actual endpoint works with hyphen
    await page.goto('https://localhost:5001/.well-known/openid-configuration');
    const content = await page.textContent('body');
    const discoveryDoc = JSON.parse(content);
    expect(discoveryDoc.issuer).toBe('https://localhost:5001');
  });
});