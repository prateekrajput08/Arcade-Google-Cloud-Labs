# 🌐 Kickstarting Application Development with Gemini Code Assist: Challenge Lab || GSP 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)]()

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## Task-2 `backend/index.test.ts`:

```bash
// @Gemini: Write a Jest test for a new endpoint called '/outofstock'
// that checks for a 200 response and ensures 2 items are returned.
describe('GET /outofstock', () => {

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return a 200 status code and 2 out-of-stock items', async () => {
    // Mock the Firestore response specifically for the /outofstock endpoint
    const mockOutOfStockProducts = [
      {
        id: 'oos1',
        data: () => ({
          name: 'Wasabi Party Mix',
          price: 5,
          quantity: 0,
          imgfile: 'product-images/wasabipartymix.png',
          timestamp: new Date().toISOString(),
          actualdateadded: new Date().toISOString(),
        }),
      },
      {
        id: 'oos2',
        data: () => ({
          name: 'Jalapeno Seasoning',
          price: 3,
          quantity: 0,
          imgfile: 'product-images/jalapenoseasoning.png',
          timestamp: new Date().toISOString(),
          actualdateadded: new Date().toISOString(),
        }),
      },
    ];

    mockCollection.where.mockImplementation((field, op, value) => {
      if (field === 'quantity' && op === '<=' && value === 0) {
        return {
          get: jest.fn().mockResolvedValue({
            empty: false,
            docs: mockOutOfStockProducts,
            forEach: jest.fn(callback => {
              mockOutOfStockProducts.forEach(doc => callback(doc));
            }),
          }),
        };
      }
      return mockCollection;
    });

    const response = await request(app).get('/outofstock');

    expect(response.statusCode).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
    expect(response.body).toHaveLength(2);
    expect(response.body[0].name).toBe('Wasabi Party Mix');
    expect(response.body[0].quantity).toBe(0);
    expect(response.body[1].name).toBe('Jalapeno Seasoning');
  });
});
```
```bash
cd cymbal-superstore/backend
```
```bash
npm install
npm run test
```

</div>

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
    <em>Last updated: November 2025</em>
  </p>
</div>
