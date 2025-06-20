const { chromium, firefox, webkit } = require('playwright');

async function testBrowser(browserType, browserName) {
    console.log(`\n=== Testing ${browserName} ===`);
    
    let browser;
    try {
        console.log(`Launching ${browserName}...`);
        browser = await browserType.launch({ headless: true });
        
        console.log(`Creating new page in ${browserName}...`);
        const page = await browser.newPage();
        
        // Test basic navigation
        console.log('Navigating to example.com...');
        await page.goto('https://example.com');
        
        // Test page title
        const title = await page.title();
        console.log(`Page title: ${title}`);
        
        if (!title.includes('Example Domain')) {
            throw new Error(`Unexpected page title: ${title}`);
        }
        
        // Test element selection
        console.log('Testing element selection...');
        const heading = await page.textContent('h1');
        console.log(`H1 content: ${heading}`);
        
        if (!heading.includes('Example Domain')) {
            throw new Error(`Unexpected heading content: ${heading}`);
        }
        
        // Test screenshot capability
        console.log('Taking screenshot...');
        await page.screenshot({ path: `${browserName.toLowerCase()}-test.png` });
        
        // Test JavaScript execution
        console.log('Testing JavaScript execution...');
        const result = await page.evaluate(() => {
            return {
                url: window.location.href,
                userAgent: navigator.userAgent,
                timestamp: Date.now()
            };
        });
        
        console.log(`Current URL: ${result.url}`);
        console.log(`User Agent: ${result.userAgent.substring(0, 50)}...`);
        console.log(`Timestamp: ${new Date(result.timestamp).toISOString()}`);
        
        console.log(`✅ ${browserName} test completed successfully!`);
        
    } catch (error) {
        console.error(`❌ ${browserName} test failed:`, error.message);
        throw error;
    } finally {
        if (browser) {
            await browser.close();
        }
    }
}

async function runAllTests() {
    console.log('=== Playwright Browser Automation Test ===');
    
    const browsers = [
        { type: chromium, name: 'Chromium' },
        { type: firefox, name: 'Firefox' },
        { type: webkit, name: 'WebKit' }
    ];
    
    let failedTests = 0;
    
    for (const browser of browsers) {
        try {
            await testBrowser(browser.type, browser.name);
        } catch (error) {
            failedTests++;
            console.error(`\n❌ ${browser.name} test failed!`);
        }
    }
    
    console.log('\n=== Test Summary ===');
    console.log(`Total browsers tested: ${browsers.length}`);
    console.log(`Successful tests: ${browsers.length - failedTests}`);
    console.log(`Failed tests: ${failedTests}`);
    
    if (failedTests > 0) {
        console.log('\n❌ Some browser tests failed!');
        process.exit(1);
    } else {
        console.log('\n✅ All browser tests passed!');
    }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

// Run the tests
runAllTests().catch(error => {
    console.error('Test runner failed:', error);
    process.exit(1);
});
