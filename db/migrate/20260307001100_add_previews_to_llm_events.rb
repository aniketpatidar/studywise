class AddPreviewsToLlmEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :llm_events, :prompt_preview, :text
    add_column :llm_events, :response_preview, :text
  end
end
