# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
user = User.find_or_create_by!(email: "demo@studywise.app") do |u|
  u.name = "Demo Student"
  u.password = "password123"
  u.password_confirmation = "password123"
end

material = user.materials.find_or_create_by!(title: "Biology 101 - Cell Structure") do |m|
  m.source_type = "text"
  m.raw_text = <<~TEXT
    Cells are the basic unit of life. Eukaryotic cells contain membrane-bound organelles,
    including nucleus, mitochondria, endoplasmic reticulum, and Golgi apparatus.
    Cell membranes regulate transport using passive and active mechanisms.
  TEXT
end

material.notes.find_or_create_by!(title: "Smart Note: Biology 101 - Cell Structure") do |note|
  note.content = <<~NOTE
    Summary
    - Cells are the fundamental unit of life.
    - Eukaryotic cells contain organelles with specialized functions.
    - Membrane transport controls movement of molecules.

    Key Questions
    1. What is the role of the mitochondrion?
    2. How does active transport differ from diffusion?
  NOTE
end
