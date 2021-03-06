class Game < ApplicationRecord
  belongs_to :player_one, class_name: 'Player', foreign_key: 'player_one_id'
  belongs_to :player_two, class_name: 'Player', foreign_key: 'player_two_id'

  accepts_nested_attributes_for :player_one
  accepts_nested_attributes_for :player_two

  def self.DECK_SIZE
    6
  end

  def decks_full?
    self.player_one.has_full_deck? and self.player_two.has_full_deck?
  end

  def current_player
    self.turn == 1 ? self.player_one : self.player_two
  end

  def idle_player
    self.turn == 1 ? self.player_two : self.player_one
  end

  def update_state
    new_state = case self.state
    when "new"
      if self.player_one_id.present? and self.player_two_id.present?
        "building_decks"
      end
    when "building_decks"
      if self.decks_full?
        "battle"
      end
    when "battle"
      if self.ended?
        "ended"
      end
    end
    if new_state and new_state != self.state
      self.update_attributes(state: new_state, turn: 1)
    end
  end

  def advance_turn
    self.turn = 3 - self.turn
    self.update_state
    if self.state == "building_decks"
      if self.player_one.has_full_deck?
        self.update_attribute(:turn, 2)
        return
      elsif self.player_two.has_full_deck?
        self.update_attribute(:turn, 1)
        return
      end
    end
    self.save
  end

  def ended?
    self.player_one.defeated? || self.player_two.defeated?
  end

  def winner
    return unless self.ended?
    self.player_one.defeated? ? self.player_two : self.player_one
  end

  # For development
  def fill_decks
    self.player_one.fill_deck
    self.player_two.fill_deck
  end

  def to_hash
    {
      id: self.id,
      players: [
        self.player_one.to_hash,
        self.player_two.to_hash,
      ],
      state: self.state,
      question: MultipleChoiceQuestion.all.sample.to_hash,
      turn: self.turn,
      ended: self.ended?,
      winner: self.winner,
    }
  end
end
