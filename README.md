# typr

A fast, terminal-based typing speed test with real-time visual feedback.

## Features

- **Instant feedback**: Characters turn white (correct) or red (incorrect) as you type
- **Visual cursor**: Highlighted cursor shows your current position
- **Smart backspace**: Correct mistakes before moving to the next word
- **Accurate metrics**: WPM calculation, accuracy percentage, and timing
- **Clean interface**: Minimalist terminal UI focused on performance

## Installation

### Homebrew (Recommended)

```bash
brew tap willyamjarcand/typr
brew install typr
```

### Manual Installation

```bash
git clone https://github.com/willyamjarcand/homebrew-typr.git
cd typr
ruby typr.rb
```

## Usage

Simply run:
```bash
typr
```

### demo

Uploading typr_demo (1).mov…

**Controls:**
- Type to test your speed
- Backspace to correct mistakes (disabled after space)
- Space to complete current word
- Ctrl+C to exit

## Sample Output

```
Type the text below:

The quick brown fox jumps over the lazy dog.

Progress: 8/12 words

==================================================
Test Complete!
==================================================
Time: 23.45 seconds
Words typed: 12
WPM: 30.7
Accuracy: 94.2%
```

## Requirements

- Ruby 2.6+
- Terminal with ANSI color support
