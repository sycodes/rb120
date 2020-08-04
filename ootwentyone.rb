require 'pry'

module Hand
  attr_accessor :cards
  attr_reader :suit, :value, :value_name
  attr_writer :total

  def busted?
    total > 21
  end

  def total
    cards.map(&:value).reduce(:+)
  end

  def arr_cards
    cards.map { |card| "The #{card.value_name} of #{card.suit}" }
  end
end

class Participant
  attr_accessor :name

  def initialize
    @cards = []
  end

  def hit(deck, participant)
    deck.deal(deck, participant)
  end
end

class Player < Participant
  include Hand

  def set_name
    loop do
      puts "What is your name? "
      self.name = gets.chomp.capitalize
      puts ""
      break if valid_name?
      puts "Sorry, that's not a valid name."
    end
  end

  def display_cards(arr_cards)
    puts "Your hand is: "
    arr_cards.each { |card| puts card }
    puts ""
  end

  private

  def valid_name?
    valid_chars = ("A".."Z").to_a + ("a".."z").to_a
    !name.empty? && name.chars.all? { |char| valid_chars.include?(char) }
  end
end

class Dealer < Participant
  include Hand

  def initialize
    @name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
    super
  end

  def stay?
    total >= 17
  end

  def display_cards(arr_cards)
    puts "#{name}'s hand is: "
    puts arr_cards.first
    puts "#{cards.size - 1} unknown card(s)"
    puts ""
  end
end

class Deck
  attr_reader :cards

  def initialize
    @cards = []

    ["Spade", "Diamond", "Club", "Heart"].each do |suit|
      ["Ace", "Jack", "Queen", "King", "2", "3",
       "4", "5", "6", "7", "8", "9", "10"].each do |value|
        cards << Card.new(suit, value)
      end
    end
  end

  def deal(deck, participant)
    dealt_card = deck.cards.sample
    participant.cards << dealt_card
    deck.cards.delete(dealt_card)
  end
end

class Card
  include Hand

  def initialize(suit, value)
    @suit = suit
    @value = if %w(Jack Queen King).include?(value)
               10
             elsif %w(Ace).include?(value)
               [1, 11].sample
             else
               value.to_i
             end
    @value_name = value
  end
end

class Game
  attr_accessor :deck
  attr_reader :player, :dealer

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def start
    clear
    display_welcome_message
    set_game
    loop do
      main_game
      break unless play_again?
      reset
    end
    display_goodbye_message
  end

  private

  def main_game
    deal_cards
    player_turn
    dealer_turn
    display_winner
  end

  def display_welcome_message
    puts "Welcome to Twenty-One!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing Twenty-One! Goodbye."
  end

  def set_game
    player.set_name

    puts "Hello #{player.name}!"
    puts "The dealer's name is #{dealer.name}"
    puts ""

    press_key_to_continue
  end

  def press_key_to_continue
    puts "Press any key to continue."
    gets.chomp
    clear
  end

  def clear
    system 'clear'
  end

  def deal_player_cards
    2.times do
      dealt_card = deck.cards.sample
      player.cards << dealt_card
      deck.cards.delete(dealt_card)
    end
  end

  def deal_dealer_cards
    2.times do
      dealt_card = deck.cards.sample
      dealer.cards << dealt_card
      deck.cards.delete(dealt_card)
    end
  end

  def deal_cards
    deal_player_cards
    deal_dealer_cards
  end

  def display_all_cards
    dealer.display_cards(dealer.arr_cards)
    player.display_cards(player.arr_cards)
  end

  def display_player_total
    puts "Your total is #{player.total}."
    puts ""
  end

  def player_move
    answer = nil

    loop do
      puts "Do you want to hit or stay?: "
      answer = gets.chomp.downcase
      puts ""
      break if %w(hit stay).include?(answer)
      puts "Sorry, that's not a valid choice."
      puts ""
    end

    answer
  end

  def player_turn
    loop do
      display_all_cards
      display_player_total

      move = player_move

      if move == "hit"
        player.hit(deck, player)
        clear
      end

      break if move == "stay" || player.busted?
    end
  end

  def dealer_stayed
    puts "#{dealer.name} chose to stay!"
    press_key_to_continue
  end

  def dealer_busted
    puts "#{dealer.name} busted!"
    press_key_to_continue
  end

  def dealer_hit
    puts "#{dealer.name} chooses hit."
    dealer.hit(deck, dealer)
    press_key_to_continue
  end

  def dealer_stayed_or_busted
    if dealer.stay?
      dealer_stayed
    elsif dealer.busted?
      dealer_busted
    end
  end

  def dealer_moves
    loop do
      clear_and_display_all_cards

      if dealer.stay? || dealer.busted?
        dealer_stayed_or_busted
        break
      else
        dealer_hit
      end
    end
  end

  def dealer_turn
    return show_result if player.busted?
    dealer_moves
    show_result
  end

  def clear_and_display_all_cards
    clear
    display_all_cards
  end

  def show_result
    clear
    display_all_cards
    puts "Your score is #{player.total}."
    puts "#{dealer.name}'s score is #{dealer.total}."
    puts ""
  end

  def play_again?
    answer = nil

    loop do
      puts "Would you like to play again? (y/n): "
      answer = gets.chomp.downcase
      puts ""
      break if %w(y n).include?(answer)
      puts "Sorry, that is not a valid choice."
      puts ""
    end

    answer == 'y'
  end

  def reset
    clear
    self.deck = Deck.new
    player.cards = []
    dealer.cards = []
    player.total = 0
    dealer.total = 0
  end

  def someone_busted?
    player.busted? || dealer.busted?
  end

  def busted_winners
    if player.busted?
      puts "#{dealer.name} is the winner!"
    elsif dealer.busted?
      puts "You are the winner!"
    end
  end

  def total_winners
    if dealer.total > player.total
      puts "#{dealer.name} are the winner!"
    elsif player.total > dealer.total
      puts "You are the winner!"
    else
      puts "It's a tie!"
    end
  end

  def display_winner
    if someone_busted?
      busted_winners
    else
      total_winners
    end
  end
end

Game.new.start
