class NoteGenerationJob < ApplicationJob
  queue_as :default

  def perform(material_id)
    material = Material.find(material_id)
    Study::NoteGenerationService.new(material: material).call
    broadcast_material(material)
  rescue StandardError
    material&.failed!
    broadcast_material(material) if material
    raise
  end

  private

  def broadcast_material(material)
    Turbo::StreamsChannel.broadcast_replace_to(
      material,
      target: ActionView::RecordIdentifier.dom_id(material, :status_panel),
      partial: "materials/status_panel",
      locals: { material: material }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      material,
      target: ActionView::RecordIdentifier.dom_id(material, :notes_panel),
      partial: "materials/notes_panel",
      locals: { material: material, notes: material.notes.recent }
    )
  end
end
