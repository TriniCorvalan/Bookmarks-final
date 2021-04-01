# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'faker'

20.times do |i|
  title = Faker::Commerce.department + (i + 1).to_s
  Kind.create!(title: title)
end

5.times do |i|
  title = Faker::Hipster.word + (i + 1).to_s
  is_public = [true, false].sample
  Seed = Category.create!(title: title, is_public: is_public)
  10.times do |j|
    title = Faker::Hipster.word + (j + 1).to_s
    is_public = [true, false].sample
    category_id = Seed.id
    Category.create!(title: title, is_public: is_public, category_id: category_id)
  end
end