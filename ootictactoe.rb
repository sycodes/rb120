module Markable
  INITIAL_MARKER = " "
  attr_accessor :marker
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  include Markable

  def initialize
    @squares = {}
    reset
  end

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def joinor(arr, delimiter = ', ', word = 'or')
    case arr.size
    when 0 then ''
    when 1 then arr.first
    when 2 then arr.join(" #{word} ")
    else
      arr[-1] = "#{word} #{arr.last}"
      arr.join(delimiter)
    end
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def square_number(player) # returns integer
    square_number = nil
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if two_identical_markers?(squares, player)
        square_number = line.select { |key| @squares[key].unmarked? }.first
      end
    end
    square_number
  end

  def square_five?
    true if @squares[5].unmarked?
  end

  def winning?(player)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      return true if two_identical_markers?(squares, player)
    end
    false
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end

  def two_identical_markers?(squares, player)
    markers = squares.collect(&:marker)
    markers.count(player.marker) == 2 && markers.count(INITIAL_MARKER) == 1
  end
end

class Square
  include Markable

  def initialize(marker=INITIAL_MARKER)
    self.marker = marker
  end

  def to_s
    marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  GRAND_WINNER = 5

  attr_accessor :score, :name

  include Markable

  def initialize
    @score = 0
  end
end

class Human < Player
  def set_name
    valid_chars = ("A".."Z").to_a + ("a".."z").to_a

    loop do
      puts "What is your name? "
      self.name = gets.chomp.capitalize
      puts ""
      break if name.chars.all? { |char| valid_chars.include?(char) }
      puts "Sorry, that's not a valid name."
    end

    puts "Hello #{name}!"
  end

  def assign_marker
    loop do
      puts "Which marker do you want? (X or O): "
      self.marker = gets.chomp.upcase
      puts ""
      break if ["X", "O"].include?(marker)
      puts "Sorry, that's not a valid choice."
    end
  end
end

class Computer < Player
  def set_name
    computer_name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
    puts "The computer's name is #{computer_name}."
    puts ""
    @name = computer_name
  end

  def assign_marker(human)
    self.marker = human.marker == "X" ? "O" : "X"
  end
end

class TTTGame
  @@current_marker = ''
  @@first_player = ''

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
  end

  def play
    clear
    display_welcome_message
    main_game
    display_goodbye_message
  end

  private

  def main_game
    set_names
    loop do
      set_game
      five_games
      display_grand_winner
      break unless play_again?
      reset_board_and_score
      display_play_again_message
    end
  end

  def five_games
    loop do
      display_board
      player_move
      keep_score
      display_result
      break if best_of_five?
      reset_board
    end
  end

  def set_game
    human.assign_marker
    computer.assign_marker(human)
    first_to_move
    press_key_to_start
    clear
  end

  def set_names
    human.set_name
    computer.set_name
  end

  def first_to_move
    answer = nil

    loop do
      puts "Do you want to go first? (y/n): "
      answer = gets.chomp
      puts ""
      break if %w(y n).include?(answer.downcase)
      puts "Sorry, that's not a valid choice."
    end

    @@first_player = answer == 'y' ? human.marker : computer.marker

    @@current_marker = @@first_player
  end

  def best_of_five?
    five_wins = Player::GRAND_WINNER
    human.score == five_wins || computer.score == five_wins
  end

  def display_grand_winner
    clear

    if human.score == Player::GRAND_WINNER
      puts "#{human.name} is the grand winner!"
    else
      puts "#{computer.name} is the grand winner!"
    end
  end

  def press_key_to_start
    puts "Press any key to start the game!"
    gets.chomp
  end

  def press_key_to_continue
    puts ""
    puts "Press any key to continue."
    gets.chomp
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts "The best of five wins the game."
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def human_turn?
    @@current_marker == human.marker
  end

  def display_board
    puts "#{human.name} is a #{human.marker}."
    puts "#{computer.name} is a #{computer.marker}."
    puts ""
    board.draw
    puts ""
  end

  def human_moves
    square = square_picked
    board[square] = human.marker
  end

  def integer?(square)
    board.unmarked_keys.include?(square.to_i) && square.to_i.to_s == square
  end

  def square_picked
    loop do
      puts "Choose a square (#{board.joinor(board.unmarked_keys)}): "
      square = gets.chomp
      puts ""
      if integer?(square)
        square = square.to_i
        return square
      end
      puts "Sorry, that's not a valid choice."
    end
  end

  def computer_moves
    if board.winning?(computer)
      offensive_square
    elsif board.winning?(human)
      defensive_square
    elsif board.square_five?
      middle_square
    else
      random_square
    end
  end

  def defensive_square
    board[board.square_number(human)] = computer.marker
  end

  def offensive_square
    board[board.square_number(computer)] = computer.marker
  end

  def random_square
    board[board.unmarked_keys.sample] = computer.marker
  end

  def middle_square
    board[5] = computer.marker
  end

  def current_player_moves
    if human_turn?
      human_moves
      @@current_marker = computer.marker
    else
      computer_moves
      @@current_marker = human.marker
    end
  end

  def keep_score
    case board.winning_marker
    when human.marker
      human.score += 1
    when computer.marker
      computer.score += 1
    end
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won!"
    when computer.marker
      puts "Computer won!"
    else
      puts "It's a tie!"
    end

    display_total_score
  end

  def display_total_score
    puts ""
    puts "You won a total of #{human.score} times."
    puts "Computer won a total of #{computer.score} times."
    press_key_to_continue
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      puts ""
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def clear
    system "clear"
  end

  def reset_board
    board.reset
    @@current_marker = @@first_player
    clear
  end

  def reset_board_and_score
    reset_board
    human.score = 0
    computer.score = 0
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end
end

game = TTTGame.new
game.play
