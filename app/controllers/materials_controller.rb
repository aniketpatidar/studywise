class MaterialsController < ApplicationController
  before_action :set_material, only: %i[show edit update destroy generate_note generate_quiz preview_extraction]
  before_action :limit_note_generation!, only: :generate_note
  before_action :limit_quiz_generation!, only: :generate_quiz
  SAMPLE_MATERIAL_CONTENT = <<~TEXT.freeze
    Photosynthesis is the process plants use to convert light energy into chemical energy.
    It occurs mainly in chloroplasts, using chlorophyll pigments to absorb sunlight.

    Core equation:
    6CO2 + 6H2O + light energy -> C6H12O6 + 6O2

    Two major stages:
    1) Light-dependent reactions:
    - Occur in thylakoid membranes.
    - Produce ATP and NADPH.
    - Split water and release oxygen.

    2) Calvin cycle (light-independent reactions):
    - Occurs in the stroma.
    - Uses ATP and NADPH to fix CO2 into sugars.

    Why it matters:
    - Produces oxygen needed by many organisms.
    - Forms the base of most food chains.
    - Stores solar energy as glucose.
  TEXT

  def index
    @materials = current_user.materials.recent
  end

  def show
    load_material_show_state
  end

  def preview_extraction
    load_material_show_state
    extraction_result = Study::ContentExtractionService.new(material: @material).preview(max_chars: 4_000)
    @extraction_preview = extraction_result.content
    @extraction_warnings = extraction_result.warnings
    if @extraction_preview.blank?
      flash.now[:alert] = "Extraction preview is empty. Add richer text content and try again."
    else
      flash.now[:notice] = "Extraction preview loaded. Review before generating notes or quizzes."
    end
    render :show
  rescue Study::ContentExtractionService::ExtractionError => e
    load_material_show_state
    @extraction_preview = nil
    @extraction_warnings = []
    flash.now[:alert] = e.message
    render :show, status: :unprocessable_entity
  end

  def new
    @material = current_user.materials.new
  end

  def create
    first_material = !current_user.materials.exists?
    @material = current_user.materials.new(material_params)

    if @material.save
      if first_material && source_content_present?(@material)
        result = enqueue_note_generation(material: @material, idempotency_key: SecureRandom.uuid)
        if result == :started
          redirect_to @material, notice: "Material created. We started note generation automatically for your first material."
        else
          redirect_to @material, notice: "Material created. Next step: generate your first smart note."
        end
      else
        redirect_to @material, notice: "Material created. Next step: generate your first smart note."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def import_sample
    material = current_user.materials.create!(
      title: "Sample Material: Photosynthesis Basics",
      source_type: "text",
      raw_text: SAMPLE_MATERIAL_CONTENT
    )
    result = enqueue_note_generation(material: material, idempotency_key: SecureRandom.uuid)
    notice = result == :started ? "Sample material imported. Note generation started." : "Sample material imported."
    redirect_to material, notice: notice
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
    result = enqueue_note_generation(material: @material, idempotency_key: params[:idempotency_key].presence || SecureRandom.uuid)
    case result
    when :started
      redirect_to @material, notice: "Note generation started."
    when :duplicate
      redirect_to @material, notice: "This note-generation request was already accepted."
    when :in_progress
      redirect_to @material, alert: "Note generation is already in progress."
    else
      redirect_to @material, alert: "Unable to start note generation right now. Please retry."
    end
  end

  def generate_quiz
    unless @material.notes.exists?
      redirect_to @material, alert: "Generate a note first, then start quiz generation."
      return
    end

    idempotency_key = params[:idempotency_key].presence || SecureRandom.uuid
    result = Study::GenerationTracker.start_quiz_generation(material_id: @material.id, idempotency_key: idempotency_key)
    case result
    when :started
      QuizGenerationJob.perform_later(@material.id, idempotency_key)
      redirect_to @material, notice: "Quiz generation started."
    when :duplicate
      redirect_to @material, notice: "This quiz-generation request was already accepted."
    when :in_progress
      redirect_to @material, alert: "Quiz generation is already in progress."
    else
      redirect_to @material, alert: "Unable to start quiz generation right now. Please retry."
    end
  end

  private

  def set_material
    @material = current_user.materials.friendly.find(params[:id])
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

  def source_content_present?(material)
    material.raw_text.to_s.strip.present? || material.source_file.attached? || material.source_url.to_s.strip.present?
  end

  def enqueue_note_generation(material:, idempotency_key:)
    result = Study::GenerationTracker.start_note_generation(material_id: material.id, idempotency_key: idempotency_key)
    if result == :started
      material.processing! unless material.processing?
      NoteGenerationJob.perform_later(material.id, idempotency_key)
    end
    result
  end

  def load_material_show_state
    @notes = @material.notes.recent
    @quizzes = @material.quizzes.recent
    @note_generation_in_progress = @material.processing? || Study::GenerationTracker.note_in_progress?(@material.id)
    @quiz_generation_in_progress = Study::GenerationTracker.quiz_in_progress?(@material.id)
    @note_error_message = Study::GenerationTracker.note_error(@material.id)
    @quiz_error_message = Study::GenerationTracker.quiz_error(@material.id)
    @note_idempotency_key = SecureRandom.uuid
    @quiz_idempotency_key = SecureRandom.uuid
    @extraction_preview = nil
    @extraction_warnings = []
    @study_chat_started = @material.chat_sessions.joins(:chat_messages).where(mode: "study").exists?
  end
end
