const htmlDir = process.argv[2];
const outFile = process.argv[3];

(async function() {
  const puppeteer = require('puppeteer');
  const express = require('express');
  const app = express();
  app.use(express.static(htmlDir));
  const server = app.listen(3000);

  const pdfOptions = {
    path: outFile,
    landscape: false,
    format: 'A4',
    printBackground: true,
    displayHeaderFooter: false,
    margin :{
      top: 0,
      right: 0,
      bottom: 0,
      left: 0
    }
  };
  console.log("pdfOptions\n", pdfOptions);

  const launchOptions = {
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
    executablePath: '/usr/bin/chromium-browser'
  };

  const browser = await puppeteer.launch(launchOptions);
  const chromeVersion = await browser.version();
  console.log("ChromeVersion: ", chromeVersion);

  // Open HTML
  const page = await browser.newPage();
  await page.goto('http://localhost:3000/', {
    timeout: 10000,
    waitUntil:["load", "domcontentloaded"]
  });   

  // Save PDF
  await page.pdf(pdfOptions);

  // Shutdown
  await browser.close();
  server.close();
})();

