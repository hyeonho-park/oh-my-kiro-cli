---
name: playwright
description: Browser automation and testing with Playwright. Use when the user needs browser-based testing, E2E tests, UI verification, or web automation.
---

# Playwright Skill

## Browser Automation Mode

### When to Use

- Browser-based testing
- UI verification (screenshots, visual regression)
- Form filling and interaction testing
- E2E test writing

### Setup Check

```bash
npx playwright --version
# If not installed:
npm install -D @playwright/test
npx playwright install
```

### Test Writing Pattern

```typescript
import { test, expect } from '@playwright/test';

test('description of what is being tested', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.click('button:has-text("Submit")');
  await expect(page.locator('h1')).toContainText('Welcome');
});
```

### Selector Priority

| Priority | Selector Type | Example |
|----------|--------------|---------|
| 1 | Role-based | `page.getByRole('button', { name: 'Submit' })` |
| 2 | Text-based | `page.getByText('Welcome')` |
| 3 | Test ID | `page.getByTestId('submit-btn')` |
| 4 | CSS | `page.locator('.submit-button')` |

### Constraints

- Always clean up test data after tests
- Never hardcode credentials in tests
- Use environment variables for URLs
- Keep tests independent and idempotent
