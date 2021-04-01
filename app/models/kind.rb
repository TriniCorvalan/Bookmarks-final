class Kind < ApplicationRecord
  validates :title, uniqueness: true

  def to_s
    title
  end
end
