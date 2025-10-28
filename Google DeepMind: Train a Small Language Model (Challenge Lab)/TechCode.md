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
def segment_encoded_sequence(
        sequence: list[int],
        max_length: int,
        n_overlap: int
) -> list[list[int]]:
    """Segment a long encoded sequence into overlapping subsequences of maximum
    length.

    Divides the input sequence into chunks of max_length tokens with specified
    overlap between consecutive segments. The final segment may be shorter than
    max_length if insufficient tokens remain.

    Args:
        sequence: List of token indices to segment.
        max_length: Maximum length for each subsequence.
        n_overlap: Number of tokens to overlap between consecutive segments.

    Returns:
        List of subsequences, each with at most max_length token indices. All
        segments except possibly the last will have exactly max_length tokens.
    """
    subsequences = []

    # ---------- Added code starts here ----------
    step = max_length - n_overlap
    start = 0

    while start < len(sequence):
        end = start + max_length
        subseq = sequence[start:end]
        subsequences.append(subseq)
        if end >= len(sequence):
            break
        start += step
    # ---------- Added code ends here ----------

    return subsequences
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
