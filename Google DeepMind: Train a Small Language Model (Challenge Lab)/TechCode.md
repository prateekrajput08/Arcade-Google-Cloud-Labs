# 🌐  || GSP 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)]()

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## 👉Task 2. Character Tokenizer
### Tokenize the string into character tokens.

```bash
tokens = list(text)
```

### Join the list of character tokens into a string.

```bash
text = "".join(tokens)
```

## 👉Task 3. Generating text from an n-gram model

```bash
if not ngram_model:
      return tokenizer.join_text(generated_tokens)

    context_size = len(tokenizer.character_tokenize(next(iter(ngram_model))))

    for _ in range(n_tokens):
      if len(generated_tokens) < context_size:
        break

      context_tokens = generated_tokens [-context_size:]
      context_key = tokenizer.join_text(context_tokens)
      
      if context_key not in ngram_model:
        break

      next_token_distribution = ngram_model [context_key]
      
      if not next_token_distribution:
        break

      next_token = ""
      if sampling_mode == "random":
        tokens = list(next_token_distribution.keys())
        probabilities = list(next_token_distribution.values())

        next_token = random.choices (tokens, weights=probabilities, k=1) [0]
      elif sampling_mode == "greddy":
        next_token = max(next_token_distribution, key=next_token_distribution.get)
      else:
        raise ValueError(f"Unsupported sampling_mode: '{sampling_mode}")

      generated_tokens.append(next_token)
```

## 👉Task 4. Preparing dataset for training character-based language model

```bash
start = 0
    while start < len(sequence):
      end = start + max_length
      subsequences.append(sequence[start:end])
      if end >= len(sequence): 
        break

      start = end - n_overlap
```

## 👉Task 4. Preparing dataset for training character-based language model

```bash
for text in dataset:
      token_ids = tokenizer.encode(text)
      segments = segment_encoded_sequence (token_ids, segmentation_length, n_overlap)
      encoded_tokens.extend(segments)
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
    <em>Last updated: October 2025</em>
  </p>
</div>
