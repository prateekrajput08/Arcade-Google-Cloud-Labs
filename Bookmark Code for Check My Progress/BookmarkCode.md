# Enable Check My Progress Bar ✅

## 👉 Method 1
```javascript
javascript:(function () {
    const removeLearboard = document.querySelector('.js-lab-leaderboard');
    const showScore = document.querySelector('.games-labs');

    removeLearboard.remove();
    showScore.className = "lab-show l-full no-nav application-new lab-show l-full no-nav "
})();
```
---

## 👉 Method 2

🔗 Install Chrome Extension [Tampermonkey](https://chromewebstore.google.com/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo).

### Script Code
```javascript
// ==UserScript==
// @name         Check My Progress Bar
// @namespace    http://tampermonkey.net/
// @version      1.1
// @description  Automatically show assessment panel and hide leaderboard.
// @author       Gourav Sen
// @match        https://www.skills.google/games/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Helper function to apply styles to an element
    const applyStyle = (selector, styles, elementName) => {
        const element = document.querySelector(selector);
        if (element) {
            Object.assign(element.style, styles);
            console.log(`${elementName} updated with styles: ${JSON.stringify(styles)}`);
        } else {
            console.warn(`${elementName} not found.`);
        }
    };

    // Wait for element and apply styles
    const waitForElement = (selector, callback, timeout = 5000) => {
        const startTime = Date.now();
        const interval = setInterval(() => {
            const element = document.querySelector(selector);
            if (element) {
                clearInterval(interval);
                callback(element);
            } else if (Date.now() - startTime > timeout) {
                clearInterval(interval);
                console.warn(`Timed out waiting for element: ${selector}`);
            }
        }, 100);
    };

    // Notify user
    const showNotification = (message, duration = 3000) => {
        const notification = document.createElement('div');
        notification.textContent = message;
        Object.assign(notification.style, {
            position: 'fixed',
            bottom: '10px',
            right: '10px',
            backgroundColor: '#28a745',
            color: '#fff',
            padding: '10px 15px',
            borderRadius: '8px',
            fontSize: '14px',
            boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
            zIndex: 9999,
        });
        document.body.appendChild(notification);
        setTimeout(() => notification.remove(), duration);
    };

    // Process elements
    waitForElement('.lab-assessment__tab.js-open-lab-assessment-panel', (el) => {
        el.style.display = 'block';
        console.log('Assessment Tab is now visible.');
    });
    waitForElement('ql-leaderboard-container', (el) => {
        el.style.display = 'none';
        console.log('Leaderboard is now hidden.');
    });
    waitForElement('.lab-assessment__panel.js-lab-assessment-panel', (el) => {
        el.style.display = 'block';
        console.log('Assessment Panel is now visible.');
    });

    // Notify user when script is executed
    showNotification('Follow Tech & Code');
})();
```

---
---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

<div style="text-align:center; padding: 10px 0; max-width: 640px; margin: 0 auto;">
  <h3 style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin-bottom: 14px;">📱 Join the Tech & Code Community</h3>

  <a href="https://www.youtube.com/@TechCode9?sub_confirmation=1" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Subscribe-Tech%20&%20Code-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel">
  </a>

  <a href="https://www.linkedin.com/in/prateekrajput08/" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/LinkedIn-Prateek%20Rajput-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn Profile">
  </a>

  <a href="https://t.me/techcode9" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Telegram-Tech%20Code-0088cc?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram Channel">
  </a>

  <a href="https://www.instagram.com/techcodefacilitator" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Instagram-Tech%20Code-E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram Profile">
  </a>
</div>

---

<div align="center">
  <p style="font-size: 12px; color: #586069;">
    <em>This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.</em>
  </p>
  <p style="font-size: 12px; color: #586069;">
    <em>Last updated: October 2025</em>
  </p>
</div>
