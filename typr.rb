#!/usr/bin/env ruby
# frozen_string_literal: true

require 'io/console'
require 'time'
require 'optparse'

# A CLI typing speed test application that measures typing speed and accuracy.
#
# Features:
# - Timer starts on first keystroke
# - Real-time color feedback: gray (untyped), white (correct), red (incorrect)
# - Backspace support (disabled after pressing space)
# - Space bar completes words
# - Extra characters past word end are shown in red and preserved
# - Translucent cursor shows current typing position
# - Auto-completion when last word is typed correctly
# - Final statistics: WPM, accuracy percentage, and time
#
# Usage:
#   typr = Typr.new
#   typr.run
#
# Controls:
#   - Type characters to test typing speed
#   - Backspace to correct mistakes (except after space)
#   - Space to complete current word
#   - Ctrl+C to exit
#
# @example
#   test = Typr.new
#   test.run
class Typr
  # Load all words once when class loads
  ALL_WORDS = File.readlines(File.join(File.dirname(__FILE__), 'db', 'oxford_3000.txt'))
                  .map(&:strip)
                  .reject(&:empty?)
                  .select { |word| word.match?(/^[a-zA-Z]+$/) && word.length >= 3 }
                  .freeze

  # Difficulty-based word filtering
  DIFFICULTY_FILTERS = {
    'easy' => ->(word) { word.length < 5 },
    'normal' => ->(word) { word.length < 7 },
    'hard' => ->(word) { word.length < 10 },
    'masochist' => ->(word) { word.length > 11 }
  }.freeze

  # Terminal color codes
  COLORS = {
    gray: "\e[90m",
    white: "\e[97m",
    red: "\e[91m",
    reset: "\e[0m"
  }.freeze

  # Terminal control codes
  TERMINAL = {
    clear_line: "\e[2K\r",
    move_up: "\e[A",
    clear_screen: "\e[2J\e[H",
    cursor_bg: "\e[48;5;240m"
  }.freeze

  # Key codes
  KEYS = {
    ctrl_c: 3,
    backspace: [127, 8],
    space: 32,
    enter: [13, 10],
    tab: 9
  }.freeze

  def initialize(word_count = 25, difficulty = 'normal')
    @word_count = word_count
    @difficulty = difficulty
    @test_text = generate_test_text
    @terminal_width = IO.console.winsize[1] - 10 # Leave 10 chars padding on right
    initialize_state
  end

  def run
    setup_display
    main_loop
    show_results
  end

  private

  def generate_test_text
    filtered_words = ALL_WORDS.select(&DIFFICULTY_FILTERS[@difficulty])
    selected_words = filtered_words.sample(@word_count)
    selected_words.join(' ') + '.'
  end

  def initialize_state
    @words = @test_text.split(' ')
    @current_word_index = 0
    @current_char_index = 0
    @typed_chars = []
    @completed_words = []
    @start_time = nil
    @end_time = nil
    @correct_chars = 0
    @total_chars = 0
    @word_complete = false
    @tab_pressed = false
  end

  def setup_display
    print TERMINAL[:clear_screen]
    print "\e[?25l" # Hide the real cursor
    puts "Type the text below:\n"
    display_text
  end

  def display_text
    # Build the entire display as lines, wrapping when needed
    lines = []
    current_line = ''

    @words.each_with_index do |word, word_index|
      word_display = build_word_display(word, word_index)
      # Remove ANSI escape codes to calculate actual display width
      word_width = word_display.gsub(/\e\[[0-9;]*m/, '').length

      # Check if adding this word would exceed terminal width
      if current_line.gsub(/\e\[[0-9;]*m/, '').length + word_width > @terminal_width
        lines << current_line.rstrip # Remove trailing space
        current_line = word_display
      else
        current_line += word_display
      end
    end

    # Add the last line if it has content
    lines << current_line.rstrip if current_line.strip.length > 0

    output = lines.join("\n")
    output += "\n\nProgress: #{@current_word_index}/#{@words.length} words"

    # Clear and print everything at once
    print "\e[3;1H\e[J" # Move to position and clear from cursor to end of screen
    print output
    print "\e[3;1H" # Move cursor back to text position
  end

  def position_cursor
    print "\e[3;1H"
  end

  def clear_current_line
    print TERMINAL[:clear_line]
  end

  def build_word_display(word, word_index)
    case word_status(word_index)
    when :completed
      build_completed_word(word, word_index)
    when :current
      build_current_word(word, word_index)
    when :future
      build_future_word(word)
    end
  end

  def word_status(word_index)
    if word_index < @current_word_index
      :completed
    elsif word_index == @current_word_index
      :current
    else
      :future
    end
  end

  def build_completed_word(word, word_index)
    result = ''
    if @completed_words[word_index]
      typed_word = @completed_words[word_index]
      result += build_typed_word_characters(word, typed_word)
      result += build_extra_characters(word, typed_word)
    else
      result += colorize(word, :white)
    end
    result += ' '
    result
  end

  def build_typed_word_characters(word, typed_word)
    # Clean the typed word to remove any potential cursor formatting
    clean_typed_word = typed_word.gsub(/\e\[[0-9;]*m/, '')
    result = ''

    word.chars.each_with_index do |char, char_index|
      if char_index < clean_typed_word.length
        color = clean_typed_word[char_index] == char ? :white : :red
        result += colorize(clean_typed_word[char_index], color)
      else
        result += colorize(char, :gray)
      end
    end
    result
  end

  def build_extra_characters(word, typed_word)
    return '' unless typed_word.length > word.length

    # Clean the typed word to remove any potential cursor formatting
    clean_typed_word = typed_word.gsub(/\e\[[0-9;]*m/, '')
    return '' unless clean_typed_word.length > word.length

    result = ''
    extra_chars = clean_typed_word[word.length..-1]
    extra_chars.chars.each do |char|
      result += colorize(char, :red)
    end
    result
  end

  def build_current_word(word, word_index)
    result = ''
    word.chars.each_with_index do |char, char_index|
      result += build_current_word_character(char, char_index, word_index)
    end

    result += build_current_word_extras(word)
    result
  end

  def build_current_word_character(char, char_index, word_index)
    if char_index < @typed_chars.length
      color = @typed_chars[char_index] == char ? :white : :red
      colorize(@typed_chars[char_index], color)
    elsif char_index == @current_char_index && word_index == @current_word_index
      cursor_with_char(char)
    else
      colorize(char, :gray)
    end
  end

  def build_current_word_extras(word)
    result = ''
    if @typed_chars.length > word.length
      extra_chars = @typed_chars[word.length..-1]
      extra_chars.each { |char| result += colorize(char, :red) }

      result += if @current_char_index > word.length
                  cursor_space
                else
                  ' '
                end
    elsif @current_char_index >= word.length
      result += cursor_space
    else
      result += ' '
    end
    result
  end

  def build_future_word(word)
    colorize(word, :gray) + ' '
  end

  def cursor_with_char(char)
    # Force terminal reset and use a different approach
    "\e[0m\e[100m\e[37m" + char + "\e[0m"
  end

  def cursor_space
    "\e[0m\e[100m " + "\e[0m"
  end

  def colorize(text, color)
    COLORS[color] + text + COLORS[:reset]
  end

  def display_progress
    print "\n\nProgress: #{@current_word_index}/#{@words.length} words"
  end

  def main_loop
    loop do
      char = STDIN.getch
      start_timer_if_first_keystroke

      handle_input(char)
      display_text

      break if test_complete?
    end
  end

  def start_timer_if_first_keystroke
    @start_time ||= Time.now
  end

  def handle_input(char)
    case char.ord
    when KEYS[:ctrl_c]
      exit_test
    when *KEYS[:backspace]
      handle_backspace
    when KEYS[:space]
      handle_space
    when KEYS[:tab]
      handle_tab
    when *KEYS[:enter]
      # Do nothing for enter
    else
      handle_character(char)
    end
  end

  def exit_test
    print TERMINAL[:clear_screen] # Clear entire screen
    print "\e[?25h" # Show the real cursor again
    puts 'Test cancelled.'
    exit
  end

  def test_complete?
    if @current_word_index >= @words.length
      @end_time = Time.now
      return true
    end

    if on_last_word? && last_word_completed_correctly?
      @end_time = Time.now
      @current_word_index += 1
      return true
    end

    false
  end

  def on_last_word?
    @current_word_index == @words.length - 1
  end

  def last_word_completed_correctly?
    @typed_chars.join == @words[@current_word_index]
  end

  def handle_character(char)
    return if @word_complete

    @tab_pressed = false
    @typed_chars << char
    @total_chars += 1

    update_correct_chars_count(char)
    @current_char_index += 1
  end

  def update_correct_chars_count(char)
    current_word = @words[@current_word_index]

    return unless character_is_correct?(char, current_word)

    @correct_chars += 1
  end

  def character_is_correct?(char, current_word)
    @current_char_index < current_word.length && char == current_word[@current_char_index]
  end

  def handle_backspace
    return if cannot_backspace?

    @tab_pressed = false
    
    # If current word is empty, try to go back to previous word
    if @typed_chars.empty? && @current_word_index > 0
      go_back_to_previous_word
    else
      # Normal backspace within current word
      @typed_chars.pop
      @current_char_index -= 1 if @current_char_index > 0
      @total_chars -= 1 if @total_chars > 0
    end
  end

  def cannot_backspace?
    @word_complete || (@typed_chars.empty? && cannot_go_back_to_previous_word?)
  end

  def cannot_go_back_to_previous_word?
    return true if @current_word_index == 0
    
    # Check if all previous words are correct
    (0...@current_word_index).all? do |i|
      word_is_correct?(i)
    end
  end

  def word_is_correct?(word_index)
    return false unless @completed_words[word_index]
    
    expected_word = @words[word_index]
    typed_word = @completed_words[word_index].gsub(/\e\[[0-9;]*m/, '') # Remove ANSI codes
    typed_word == expected_word
  end

  def go_back_to_previous_word
    @current_word_index -= 1
    @typed_chars = @completed_words[@current_word_index].gsub(/\e\[[0-9;]*m/, '').chars
    @current_char_index = @typed_chars.length
    @completed_words[@current_word_index] = nil
    @word_complete = false
  end

  def handle_tab
    @tab_pressed = true
  end

  def handle_space
    if @tab_pressed
      restart_test
      return
    end

    save_current_word
    move_to_next_word
  end

  def restart_test
    @test_text = generate_test_text
    initialize_state
    setup_display
  end

  def save_current_word
    @completed_words[@current_word_index] = @typed_chars.join
  end

  def move_to_next_word
    @current_word_index += 1
    @current_char_index = 0
    @typed_chars = []
    @word_complete = false
  end

  def show_results
    print TERMINAL[:clear_screen] # Clear entire screen
    print "\e[?25h" # Show the real cursor again
    print_results_header
    print_statistics
  end

  def print_results_header
    header_width = [@terminal_width + 10, 50].min  # Use terminal width or 50, whichever is smaller
    puts '=' * header_width
    puts 'Test Complete!'
    puts '=' * header_width
  end

  def print_statistics
    stats = calculate_statistics

    puts "WPM: #{stats[:wpm]}"
    puts "Time: #{stats[:duration]} seconds"
    puts "Words typed: #{stats[:words_typed]}"
    puts "Accuracy: #{stats[:accuracy]}%"
    puts "Correct characters: #{@correct_chars}/#{@total_chars}"
  end

  def calculate_statistics
    duration = (@end_time - @start_time).round(2)
    words_typed = @current_word_index
    wpm = (words_typed / (duration / 60)).round(2)
    accuracy = (@correct_chars.to_f / @total_chars * 100).round(2)

    {
      duration: duration,
      words_typed: words_typed,
      wpm: wpm,
      accuracy: accuracy
    }
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: typr [options]'

    opts.on('-l', '--length NUMBER', Integer, 'Number of words to generate (default: 25)') do |length|
      options[:length] = length
    end

    opts.on('-d', '--difficulty LEVEL', ['easy', 'normal', 'hard', 'masochist'], 
            'Difficulty level: easy (<5 chars), normal (<7 chars), hard (<10 chars), masochist (>11 chars) (default: normal)') do |difficulty|
      options[:difficulty] = difficulty
    end

    opts.on('-h', '--help', 'Show this help message') do
      puts opts
      exit
    end
  end.parse!

  word_count = options[:length] || 25
  difficulty = options[:difficulty] || 'normal'
  test = Typr.new(word_count, difficulty)
  test.run
end
