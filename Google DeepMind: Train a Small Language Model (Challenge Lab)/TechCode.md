# 🌐 Google DeepMind: Train a Small Language Model (Challenge Lab) || GSP531 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.skills.google/course_templates/1453/labs/595070)

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

---

## 👉Task 3. Generating text from an n-gram model
```bash
import random
from typing import Literal

def argmax(arr: list[float]) -> int:
    """Get the index of the largest element in list of float elements."""
    return max(range(len(arr)), key=arr.__getitem__)

def generate_text_from_ngram_model(
        start_prompt: str,
        n_tokens: int,
        ngram_model: dict[str, dict[str, float]],
        tokenizer,
        sampling_mode: Literal["random", "greedy"] = "random"
) -> str:
    """Generate text based on a starting prompt using an ngram model."""
    # Tokenize the starting prompt.
    start_tokens = tokenizer.character_tokenize(start_prompt)

    generated_tokens = start_tokens.copy()

    # Determine n-1 from model context length
    n_minus_1 = len(next(iter(ngram_model.keys()))) if ngram_model else 1

    # Generate new tokens
    for _ in range(n_tokens):
        context = "".join(generated_tokens[-(n_minus_1):])
        if context in ngram_model:
            next_token_probs = ngram_model[context]
        else:
            # Fallback: use all probabilities combined (flattened)
            all_tokens = [tok for ctx in ngram_model.values() for tok in ctx.keys()]
            next_token_probs = {tok: 1/len(all_tokens) for tok in all_tokens}

        tokens = list(next_token_probs.keys())
        probs = list(next_token_probs.values())

        if sampling_mode == "random":
            next_token = random.choices(tokens, weights=probs, k=1)[0]
        else:  # greedy
            next_token = tokens[argmax(probs)]

        generated_tokens.append(next_token)

    generated_text = tokenizer.join_text(generated_tokens)
    return generated_text
```

---

## 👉Task 4. Preparing dataset for training character-based language model
### 1️⃣ Place 1 — EnhancedTokenizer class
```bash
class EnhancedTokenizer(SimpleArabicCharacterTokenizer):
    UNKNOWN_TOKEN = "<UNK>"
    PAD_TOKEN = "<PAD>"

    def __init__(self, corpus: list[str], vocabulary: list[str] | None = None):
        super().__init__()
        if vocabulary is None:
            if isinstance(corpus, str):
                corpus = [corpus]
            tokens = []
            for text in corpus:
                tokens.extend(self.character_tokenize(text))
            vocabulary = sorted(list(set(tokens)))
            self.vocabulary = [self.PAD_TOKEN] + vocabulary + [self.UNKNOWN_TOKEN]
        else:
            self.vocabulary = vocabulary

        self.vocabulary_size = len(self.vocabulary)
        self.token_to_index = {t: i for i, t in enumerate(self.vocabulary)}
        self.index_to_token = {i: t for i, t in enumerate(self.vocabulary)}
        self.pad_token_id = self.token_to_index[self.PAD_TOKEN]
        self.unknown_token_id = self.token_to_index[self.UNKNOWN_TOKEN]

    def encode(self, text: str) -> list[int]:
        return [self.token_to_index.get(tok, self.unknown_token_id)
                for tok in self.character_tokenize(text)]

    def decode(self, indices: list[int]) -> str:
        return self.join_text([self.index_to_token.get(i, self.UNKNOWN_TOKEN)
                               for i in indices])
```

### 2️⃣ Support Function — segment_encoded_sequence
```bash
def segment_encoded_sequence(
        sequence: list[int],
        max_length: int,
        n_overlap: int
) -> list[list[int]]:
    """Segment a long encoded sequence into overlapping subsequences."""
    subsequences = []
    start = 0
    while start < len(sequence):
        end = start + max_length
        subsequences.append(sequence[start:end])
        if end >= len(sequence):
            break
        start = end - n_overlap
    return subsequences
```

### 3️⃣ Place 2 — Inside create_training_sequences()

```bash
def create_training_sequences(
        dataset: list[str],
        context_length: int,
        n_overlap: int,
        tokenizer: EnhancedTokenizer
) -> tuple[np.ndarray, np.ndarray]:
    """Create training input-target sequence pairs from text dataset."""

    segmentation_length = context_length + 1
    pad_token_id = tokenizer.pad_token_id
    encoded_tokens = []

    # Add your code here

    # Padding and formatting provided below
    padded_sequences = keras.preprocessing.sequence.pad_sequences(
            encoded_tokens,
            maxlen=segmentation_length,
            padding="post",
            value=pad_token_id)
    inputs = padded_sequences[:, :-1]
    targets = padded_sequences[:, 1:]
    return inputs, targets
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
