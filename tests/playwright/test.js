const { chromium, firefox } = require('playwright');

async function testBrowser(browserType, browserName, channel) {
    console.log(`\n=== Testing ${browserName} ===`);
    
    let browser;
    try {
        console.log(`Launching ${browserName}...`);
        // Docker-specific browser launch options
        const launchOptions = {
            headless: true,
            args: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-gpu'
            ]
        };
        
        if (browserName === 'Chromium') {
            // Additional Chromium-specific options for Docker
            launchOptions.args.push('--disable-web-security');
            launchOptions.args.push('--disable-features=IsolateOrigins,site-per-process');
        }
        
        if (channel) {
            launchOptions.channel = channel;
        }
        
        browser = await browserType.launch(launchOptions);
        
        console.log(`Browser launched successfully. Creating new page in ${browserName}...`);
        let page;
        try {
            page = await browser.newPage();
        } catch (pageError) {
            console.error(`Failed to create new page: ${pageError.message}`);
            console.log('Retrying with timeout...');
            await new Promise(resolve => setTimeout(resolve, 1000));
            page = await browser.newPage();
        }
        
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
        { type: firefox, name: 'Firefox' }
    ];
    
    let failedTests = 0;
    
    for (const browser of browsers) {
        try {
            await testBrowser(browser.type, browser.name, browser.channel);
        } catch {
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
runAllTests().catch(() => {
    process.exit(1);
});
