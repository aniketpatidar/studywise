class MaterialsController < ApplicationController
  before_action :set_material, only: %i[show edit update destroy generate_note generate_quiz]
  before_action :limit_note_generation!, only: :generate_note
  before_action :limit_quiz_generation!, only: :generate_quiz

  def index
    @materials = current_user.materials.recent
  end

  def show
    @notes = @material.notes.recent
    @quizzes = @material.quizzes.recent
  end

  def new
    @material = current_user.materials.new
  end

  def create
    @material = current_user.materials.new(material_params)

    if @material.save
      redirect_to @material, notice: "Material created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @material.update(material_params)
      redirect_to @material, notice: "Material updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @material.destroy
    redirect_to materials_path, notice: "Material deleted."
  end

  def generate_note
    @material.processing!
    NoteGenerationJob.perform_later(@material.id)
    redirect_to @material, notice: "Note generation started."
  end

  def generate_quiz
    quiz = Study::QuizGenerationService.new(material: @material).call
    redirect_to material_quiz_path(@material, quiz), notice: "Quiz generated."
  end

  private

  def set_material
    @material = current_user.materials.find(params[:id])
  end

  def material_params
    params.expect(material: %i[title source_type source_url raw_text source_file])
  end

  def limit_note_generation!
    enforce_rate_limit!(bucket: "generate_note", limit: 10, window: 1.hour.to_i)
  end

  def limit_quiz_generation!
    enforce_rate_limit!(bucket: "generate_quiz", limit: 10, window: 1.hour.to_i)
  end
end
