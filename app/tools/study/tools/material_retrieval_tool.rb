module Study
  module Tools
    class MaterialRetrievalTool < RubyLLM::Tool
      description "Retrieve the most relevant chunks from the material.
        Use question to rank context by similarity to the user's query."
      param :question, desc: "The question needing context."
      param :limit, desc: "How many chunks to return."

      def initialize(material:)
        @material = material
      end

      def execute(question:, limit: 3)
        return "No material context available yet." unless @material&.material_chunks&.exists?

        results = Study::MaterialRetrievalIndex.fetch_relevant(material: @material, query: question, limit: limit)
        return "No relevant context found for this question." if results.empty?

        results.map.with_index do |item, idx|
          "Chunk #{idx + 1}: #{item[:summary]}\n#{item[:text]}"
        end.join("\n\n")
      end
    end
  end
end
