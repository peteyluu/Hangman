class Hangman
  MAX_GUESSES = 8

  attr_reader :guesser, :referee, :board

  def initialize(guesser, referee)
    @guesser = guesser
    @referee = referee
    @board = "_"
    @guesses_remaining = MAX_GUESSES
  end

  def play
    puts "Welcome to Hangman!"
    setup
    #puts "Secret word is: #{referee.require_secret}"
    while @guesses_remaining > 0
      p board
      take_turn

      if won?
        p @board
        puts "Guesser wins!"
        return
      end
    end
    puts "Secret word is #{referee.require_secret}!"
    puts "Guesser loses!"
  end

  def setup
    length = referee.pick_secret_word
    leng2 = guesser.register_secret_length(length)
    @board = @board * length
  end

  def take_turn
    current_guess = guesser.guess(board)
    current_indices = referee.check_guess(current_guess)
    if current_indices.empty?
      @guesses_remaining -= 1
    end
    puts "You have #{@guesses_remaining} guesses left!"
    update_board(current_guess, current_indices)
    guesser.handle_response(current_guess, current_indices)
  end

  def update_board(guess, indices)
    indices.each { |i| @board[i] = guess }
  end

  def won?
    @board.split('').none? { |el| el == "_" }
  end
end

class HumanPlayer

  def pick_secret_word
    puts "Think of a secret word. How long?"
    begin
      Integer(gets.chomp)
    rescue ArgumentError
      puts "Enter a valid length!"
      retry
    end
  end

  def guess(board)
    p board
    print "Input guess: "
    gets.chomp
  end

  def handle_response(guess, response)
    puts "Found #{guess} at positions #{response}"
  end

  def register_secret_length(length)
    puts "The length of secret word is #{length} letters long."
  end

  def check_guess(guess)
    puts "Player guessed #{guess}"
    puts "What positions does that occur at? If none, enter none!"

    input = gets.chomp
    if input == "none"
      return []
    end
    # didn't check for bogus input here; got lazy :-)
    input.split(",").map { |i_str| Integer(i_str) }
  end

  def require_secret
    puts "What word were you thinking of?"
    gets.chomp
  end

end

class ComputerPlayer
  attr_reader :dict, :candidate_words

  def self.player_with_dict_file(filename)
    dictionary = File.readlines(filename).map(&:chomp)
    ComputerPlayer.new(dictionary)
  end

  def initialize(dict)
    @dict = dict
  end

  def guess(board)
    letter_count = Hash.new(0)

    board_empty = board.split('').none?
    if board_empty
      @candidate_words.each do |word|
        word.each_char do |letter|
          letter_count[letter] += 1
        end
      end

      best_letter = find_common_letter(letter_count)
      return best_letter
    else
      @candidate_words.each do |word|
        word.each_char do |letter|
          if !board.include?(letter)
            letter_count[letter] += 1
          end
        end
      end

      best_letter = find_common_letter(letter_count)
      return best_letter
    end
  end

  def find_common_letter(hash)
    best_count = 0
    best_letter = nil
    hash.each do |k, v|
      if v > best_count
        best_count = v
        best_letter = k
      end
    end
    return best_letter
  end

  def handle_response(letter, positions)
    delete_word = false
    @candidate_words.each do |word|
      current_word_a = word.split('')
      if !positions.empty?
        positions.each do |pos|
          if current_word_a[pos] == letter
            delete_word = false
          else
            delete_word = true
          end
        end
        if delete_word
          @candidate_words.delete(word)
        end
      else
        if current_word_a.include?(letter)
          @candidate_words.delete(word)
        end
      end
    end
  end

  def register_secret_length(length)
    @candidate_words = @dict.select { |word| word.length == length }
  end

  def pick_secret_word
    @secret_word = @dict.sample
    @secret_word.length
  end

  def check_guess(letter)
    positions = []
    @secret_word.split('').each_with_index do |char, i|
      if letter == char
        positions << i
      end
    end
    positions
  end

  def require_secret
    @secret_word
  end
end

if __FILE__ == $PROGRAM_NAME
  # use print so that user input happens on the same line
  print "Guesser: Computer (yes/no)? "
  if gets.chomp == "yes"
    guesser = ComputerPlayer.player_with_dict_file("dictionary.txt")
  else
    guesser = HumanPlayer.new
  end

  print "Referee: Computer (yes/no)? "
  if gets.chomp == "yes"
    referee = ComputerPlayer.player_with_dict_file("dictionary.txt")
  else
    referee = HumanPlayer.new
  end

  Hangman.new(guesser, referee).play
end
