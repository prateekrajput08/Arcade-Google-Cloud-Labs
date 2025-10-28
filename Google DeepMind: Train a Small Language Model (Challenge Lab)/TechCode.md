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
# --- Imports ---
from collections import defaultdict, Counter
from typing import Literal
import random

# --- Simple Arabic Character Tokenizer (minimal version) ---
class SimpleArabicCharacterTokenizer:
    """Simple tokenizer that splits Arabic text into characters and joins them back."""
    def character_tokenize(self, text: str) -> list[str]:
        return list(text)
    def join_text(self, tokens: list[str]) -> str:
        return "".join(tokens)

# --- N-gram Model Functions ---

def generate_character_ngrams(text: str, n: int, tokenizer: SimpleArabicCharacterTokenizer) -> list[tuple[str]]:
    tokens = tokenizer.character_tokenize(text)
    ngrams = []
    for i in range(0, len(tokens) - n + 1):
        ngrams.append(tuple(tokens[i:i + n]))
    return ngrams

def get_character_ngram_counts(dataset: list[str], n: int, tokenizer: SimpleArabicCharacterTokenizer) -> dict[str, Counter]:
    ngram_counts = defaultdict(Counter)
    for paragraph in dataset:
        for ngram in generate_character_ngrams(paragraph, n, tokenizer):
            context = "".join(ngram[:-1])
            next_token = ngram[-1]
            ngram_counts[context][next_token] += 1
    return dict(ngram_counts)

def build_ngram_model(dataset: list[str], n: int, tokenizer: SimpleArabicCharacterTokenizer) -> dict[str, dict[str, float]]:
    ngram_model = {}
    ngram_counts = get_character_ngram_counts(dataset, n, tokenizer)
    for context, next_tokens in ngram_counts.items():
        total = sum(next_tokens.values())
        ngram_model[context] = {token: count / total for token, count in next_tokens.items()}
    return ngram_model

# --- Helper Function ---
def argmax(arr: list[float]) -> int:
    return max(range(len(arr)), key=arr.__getitem__)

# --- Your Completed Task 3 Function ---
def generate_text_from_ngram_model(
        start_prompt: str,
        n_tokens: int,
        ngram_model: dict[str, dict[str, float]],
        tokenizer: SimpleArabicCharacterTokenizer,
        sampling_mode: Literal["random", "greedy"] = "random"
) -> str:
    start_tokens = tokenizer.character_tokenize(start_prompt)
    generated_tokens = start_tokens + []

    # infer context length (n-1)
    if len(ngram_model) > 0:
        first_key = next(iter(ngram_model))
        context_length = len(first_key)
    else:
        context_length = 1

    for _ in range(n_tokens):
        context = "".join(generated_tokens[-context_length:])
        if context not in ngram_model:
            context = random.choice(list(ngram_model.keys()))
        probs = ngram_model[context]
        tokens = list(probs.keys())
        probabilities = list(probs.values())

        if sampling_mode == "greedy":
            next_token = tokens[argmax(probabilities)]
        else:
            next_token = random.choices(tokens, weights=probabilities, k=1)[0]

        generated_tokens.append(next_token)

    generated_text = tokenizer.join_text(generated_tokens)
    return generated_text
```
```bash
def generate_text_from_ngram_model(
        start_prompt: str,
        n_tokens: int,
        ngram_model: dict[str, dict[str, float]],
        tokenizer: SimpleArabicCharacterTokenizer,
        sampling_mode: Literal["random", "greedy"] = "random"
) -> str:
    """Generate text based on a starting prompt using an ngram model.

    Args:
        start_prompt: The initial prompt to start the generation.
        n_tokens: The number of tokens to generate after the prompt.
        model: An ngram model mapping contexts of n-1 tokens to distributions
            over next token.
        tokenizer: The tokenizer to encode and decode text.
        sampling_mode: Whether to use random or greedy sampling. Supported
            options are "random" and "greedy".

    Returns:
        The generated text from the prompt.
    """
    # Tokenize the starting prompt.
    start_tokens = tokenizer.character_tokenize(start_prompt)

    generated_tokens = start_tokens + []

    # ---------- Added code starts here ----------
    import random

    # Infer context length (n-1)
    if len(ngram_model) > 0:
        first_key = next(iter(ngram_model))
        context_length = len(first_key)
    else:
        context_length = 1

    # Generate tokens iteratively
    for _ in range(n_tokens):
        # Current context = last (n-1) tokens
        context = "".join(generated_tokens[-context_length:])

        # If unseen context, pick a random one from model
        if context not in ngram_model:
            context = random.choice(list(ngram_model.keys()))

        probs = ngram_model[context]
        tokens = list(probs.keys())
        probabilities = list(probs.values())

        # Choose next token
        if sampling_mode == "greedy":
            next_token = tokens[argmax(probabilities)]
        else:
            next_token = random.choices(tokens, weights=probabilities, k=1)[0]

        generated_tokens.append(next_token)
    # ---------- Added code ends here ----------

    # Generated tokens are converted back to str.
    generated_text = tokenizer.join_text(generated_tokens)
    return generated_text
```

---


## 👉Task 4. Preparing dataset for training character-based language model
### Complete the segment_encoded_sequence function.

```bash
# --- Imports ---
from collections import defaultdict, Counter
from typing import Literal
import random

# --- Simple Arabic Character Tokenizer ---
class SimpleArabicCharacterTokenizer:
    """Simple tokenizer that splits Arabic text into characters and joins them back."""
    def character_tokenize(self, text: str) -> list[str]:
        return list(text)
    def join_text(self, tokens: list[str]) -> str:
        return "".join(tokens)

# --- N-gram Helper Functions ---
def generate_character_ngrams(text: str, n: int, tokenizer: SimpleArabicCharacterTokenizer):
    tokens = tokenizer.character_tokenize(text)
    ngrams = []
    for i in range(0, len(tokens) - n + 1):
        ngrams.append(tuple(tokens[i:i + n]))
    return ngrams

def get_character_ngram_counts(dataset: list[str], n: int, tokenizer: SimpleArabicCharacterTokenizer):
    ngram_counts = defaultdict(Counter)
    for paragraph in dataset:
        for ngram in generate_character_ngrams(paragraph, n, tokenizer):
            context = "".join(ngram[:-1])
            next_token = ngram[-1]
            ngram_counts[context][next_token] += 1
    return dict(ngram_counts)

def build_ngram_model(dataset: list[str], n: int, tokenizer: SimpleArabicCharacterTokenizer):
    ngram_model = {}
    ngram_counts = get_character_ngram_counts(dataset, n, tokenizer)
    for context, next_tokens in ngram_counts.items():
        total = sum(next_tokens.values())
        ngram_model[context] = {token: count / total for token, count in next_tokens.items()}
    return ngram_model

def argmax(arr):
    return max(range(len(arr)), key=arr.__getitem__)

# --- Generate text using n-gram model ---
def generate_text_from_ngram_model(
        start_prompt: str,
        n_tokens: int,
        ngram_model: dict[str, dict[str, float]],
        tokenizer: SimpleArabicCharacterTokenizer,
        sampling_mode: Literal["random", "greedy"] = "random"
) -> str:
    start_tokens = tokenizer.character_tokenize(start_prompt)
    generated_tokens = start_tokens.copy()

    # infer context length (n-1)
    if len(ngram_model) > 0:
        first_key = next(iter(ngram_model))
        context_length = len(first_key)
    else:
        context_length = 1

    for _ in range(n_tokens):
        context = "".join(generated_tokens[-context_length:])
        if context not in ngram_model:
            context = random.choice(list(ngram_model.keys()))
        probs = ngram_model[context]
        tokens = list(probs.keys())
        probabilities = list(probs.values())

        if sampling_mode == "greedy":
            next_token = tokens[argmax(probabilities)]
        else:
            next_token = random.choices(tokens, weights=probabilities, k=1)[0]

        generated_tokens.append(next_token)

    generated_text = tokenizer.join_text(generated_tokens)
    return generated_text

# --- Enhanced Tokenizer ---
class EnhancedTokenizer:
    """Enhanced tokenizer that builds a vocabulary from dataset and encodes/decodes text."""
    def __init__(self, dataset: list[str]):
        unique_chars = sorted(set("".join(dataset)))
        self.char_to_id = {ch: i for i, ch in enumerate(unique_chars)}
        self.id_to_char = {i: ch for ch, i in self.char_to_id.items()}

    def encode(self, text: str) -> list[int]:
        return [self.char_to_id[ch] for ch in text if ch in self.char_to_id]

    def decode(self, ids: list[int]) -> str:
        return "".join(self.id_to_char[i] for i in ids if i in self.id_to_char)

    def __len__(self):
        return len(self.char_to_id)
```

## 👉Task 4. Preparing dataset for training character-based language model
### Complete the create_training_sequences function.

```bash
def create_training_sequences(
        dataset: list[str],
        context_length: int,
        n_overlap: int,
        tokenizer: EnhancedTokenizer
) -> tuple[np.ndarray, np.ndarray]:
    """Create training input-target sequence pairs from text dataset.

    Encodes text data into token sequences, segments them into fixed-length
    overlapping windows, and creates input-target pairs for language modeling
    where targets are inputs shifted by one position.

    Args:
        dataset: List of text strings to process into training sequences.
        context_length: Maximum sequence length for model input.
        n_overlap: Number of tokens to overlap between consecutive segments.
        tokenizer: Tokenizer object with encode method for text-to-tokens
            conversion.

    Returns:
        Tuple of (inputs, targets) where:
        - inputs: Array of token sequences of length context_length.
        - targets: Array of target sequences (inputs shifted by one position).
    """

    segmentation_length = context_length + 1
    # The segments are one token longer than the model's maximum input length,
    # because the target (next) tokens to predict are the input tokens shifted
    # by one position.

    pad_token_id = tokenizer.pad_token_id
    encoded_tokens = []

    # ---------- Added code starts here ----------
    for text in dataset:
        encoded_seq = tokenizer.encode(text)
        segmented = segment_encoded_sequence(encoded_seq, segmentation_length, n_overlap)
        encoded_tokens.extend(segmented)
    # ---------- Added code ends here ----------

    # Create padded sequences one token longer than the maximum input length.
    padded_sequences = keras.preprocessing.sequence.pad_sequences(
            encoded_tokens,
            maxlen=segmentation_length,
            padding="post",
            value=pad_token_id)

    # Create inputs and targets from padded sequences.
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
