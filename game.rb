require "timeout"

class Game
  attr_reader :players, :dealer, :deck, :score

  def initialize(server: nil)
    @round = 1
    @score = []
    log "what is your name player?"
    begin
      player_name = Timeout::timeout(10) { gets.chomp }
    rescue Timeout::Error
    end
    if player_name
      @player_1 = Player.new(player_name)
    else
      @player_1 = Player.new("Player 1")
    end
    @players = Array.new(4) { |i| Player.new("cpu_#{i}") }
    @players.push(@player_1)
    @dealer = Dealer.new CardDeck.new.cards
    launch_game
  end

  def launch_game
    play_round
    while @round < 6
      log "Would you like to play another hand? (y/n)"
      begin
        new_hand = Timeout::timeout(5) { gets.chomp }
      rescue Timeout::Error
      end
      if new_hand === "y"
        play_round
      else
        log "Thanks for playing! See you next time!"
        log @score.group_by { |i| i[1]}
            .map {|i, v| [i, v.size]}
        return
      end
    end
  end

  def play_round
    log "Round " + @round.to_s + ":"
    @dealer.shuffle_deck
    @players.each do |player|
      player.receive_hand(*@dealer.deal(2))
    end
    log "your hand is:"
    log @player_1.reveal_hand
    sleep 3
    log "the other players hands are:"
    (@players - [@player_1]).each do |player|
      log player.reveal_hand
    end
    winner = @dealer.determine_winner @players
    @score.push(["round: #{@round}", winner])
    winner.wins.push(@round)

    log "This round goes to our winner #{winner.name}!!!"
    reset_round
  end

  def reset_round
    @round += 1
    @players.each do |player|
      @dealer.undeal(*player.return_cards)
    end
  end

  def log(content)
    puts content
  end
end

class Agent
  attr_reader :cards_on_hand, :name, :remote

  def initialize
    @remote = false
    @cards_on_hand = []
  end

  def add_card(card)
    @cards_on_hand.push(card)
  end

  def remove_card
    @cards_on_hand.pop
  end
end

class Dealer < Agent
  def initialize(card_deck = [])
    super()
    card_deck.each do |card|
      add_card card
    end
  end

  def undeal(*cards)
    cards.map { |card| add_card(card) }
  end

  def deal(num_of_cards)
    num_of_cards.times.map { remove_card }
  end

  def shuffle_deck
    @cards_on_hand.shuffle!
  end

  def determine_winner(players)
    players
      .map { |player|
      [player, player.cards_on_hand
        .reduce(0) { |r, o| r += o.value }]
    }
      .sort { |a, b| a[1] <=> b[1] }
      .last[0]
  end
end

class Player < Agent
  attr_accessor :wins, :losses

  def initialize(name)
    super()
    @name = name
    @wins = []
    @losses = []
  end

  def receive_hand(*cards)
    cards.each { |card| add_card card }
  end

  def return_cards
    num_cards = @cards_on_hand.size
    num_cards.times.map do |card|
      remove_card
    end
  end

  def reveal_hand
    "#{name}: #{@cards_on_hand.map { |card| "#{card.rank} of #{card.suit}" }}"
  end
end

class CardDeck
  attr_reader :cards

  def initialize()
    @cards = PlayingCard::RANKS.product(PlayingCard::SUITS).map {
      |card_dets|
      PlayingCard.new(card_dets[0], card_dets[1])
    }
  end
end

class PlayingCard
  attr_accessor :suit, :rank
  attr_reader :value
  SUITS = [
    CLUBS = "\u2663",
    DIAMONDS = "\u25C6",
    HEARTS = "\u2665",
    SPADES = "\u2660",
  ]
  RANKS = [ACE = "A", *(2..10), JACK = "J", QUEEN = "Q", KING = "K"]

  def initialize(rank = nil, suit = nil)
    if suit
      @suit = suit
    else
      @suit = SUITS.sample
    end
    if rank
      @rank = rank
    else
      @rank = RANKS.sample
    end
    set_value
  end

  def set_value
    if @rank === ACE
      @value = 11
    elsif [JACK, QUEEN, KING].include? @rank
      @value = 10
    else
      @value = @rank.to_i
    end
  end
end

Game.new
