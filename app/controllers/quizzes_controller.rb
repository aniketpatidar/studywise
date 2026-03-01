class QuizzesController < ApplicationController
  before_action :set_material
  before_action :set_quiz, only: %i[show submit]

  def show
    @latest_attempt = @quiz.quiz_attempts.where(user: current_user).order(created_at: :desc).first
  end

  def submit
    score = 0
    answers = {}
    questions = Array(@quiz.questions)

    questions.each_with_index do |q, idx|
      picked = params.dig(:answers, idx.to_s).to_i
      correct_index = q["answer_index"].to_i
      correct = picked == correct_index
      score += 1 if correct
      answers[idx.to_s] = {
        "selected_index" => picked,
        "correct_index" => correct_index,
        "correct" => correct,
        "question" => q["question"],
        "options" => q["options"],
        "explanation" => q["explanation"]
      }
    end

    @quiz.quiz_attempts.create!(
      user: current_user,
      score:,
      total: questions.size,
      answers:
    )

    redirect_to material_quiz_path(@material, @quiz), notice: "Quiz submitted. Score: #{score}/#{questions.size}"
  end

  private

  def set_material
    @material = current_user.materials.find(params[:material_id])
  end

  def set_quiz
    @quiz = @material.quizzes.find(params[:id])
  end
end
