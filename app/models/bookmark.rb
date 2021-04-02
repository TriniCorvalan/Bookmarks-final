class Bookmark < ApplicationRecord
  has_many :bookmark_categories, dependent: :destroy
  has_many :categories, through: :bookmark_categories
  
  has_many :bookmark_kinds, dependent: :destroy
  has_many :kinds, through: :bookmark_kinds
  
end
