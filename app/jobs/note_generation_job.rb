class NoteGenerationJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3 do |job, error|
    material = Material.find_by(id: job.arguments.first)
    next unless material

    material.failed!
    Study::GenerationTracker.fail_note_generation(material_id: material.id, error_message: error.message)
    broadcast_material_state(material)
  end

  def perform(material_id, idempotency_key)
    material = Material.find(material_id)
    Study::NoteGenerationService.new(material: material, idempotency_key: idempotency_key).call
    Study::GenerationTracker.finish_note_generation(material_id: material.id)
    Study::GenerationTracker.clear_note_error!(material.id)
    self.class.broadcast_material_state(material)
  end

  private

  def self.broadcast_material_state(material)
    note_in_progress = material.processing? || Study::GenerationTracker.note_in_progress?(material.id)
    quiz_in_progress = Study::GenerationTracker.quiz_in_progress?(material.id)

    Turbo::StreamsChannel.broadcast_replace_to(
      material,
      target: ActionView::RecordIdentifier.dom_id(material, :status_panel),
      partial: "materials/status_panel",
      locals: {
        material: material,
        note_generation_in_progress: note_in_progress,
        quiz_generation_in_progress: quiz_in_progress,
        note_error_message: Study::GenerationTracker.note_error(material.id),
        quiz_error_message: Study::GenerationTracker.quiz_error(material.id)
      }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      material,
      target: ActionView::RecordIdentifier.dom_id(material, :notes_panel),
      partial: "materials/notes_panel",
      locals: { material: material, notes: material.notes.recent }
    )
  end
end
