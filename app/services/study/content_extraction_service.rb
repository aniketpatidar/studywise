require "pdf/reader"
require "json"
require "net/http"
require "rexml/document"
require "zip"
require "uri"

module Study
  class ContentExtractionService
    class ExtractionError < StandardError; end

    def initialize(material:)
      @material = material
    end

    def call
      content = [@material.raw_text.to_s.strip]
      content << extract_from_file if @material.source_file.attached?
      content << extract_from_youtube if @material.source_type == "youtube" && @material.source_url.present?

      combined = content.compact.join("\n\n").strip
      raise ExtractionError, "No content could be extracted from this material." if combined.blank?

      combined.first(24_000)
    end

    private

    def extract_from_file
      filename = @material.source_file.filename.to_s.downcase
      data = @material.source_file.download
      return data.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace) if filename.end_with?(".txt", ".md")
      return extract_pdf_text(data) if filename.end_with?(".pdf")
      return extract_docx_text(data) if filename.end_with?(".docx")
      return extract_pptx_text(data) if filename.end_with?(".pptx")

      "Attached file #{filename} (unsupported parser)."
    rescue StandardError => e
      raise ExtractionError, "File extraction failed: #{e.message}"
    end

    def extract_pdf_text(binary)
      temp = Tempfile.new(%w[studywise .pdf])
      temp.binmode
      temp.write(binary)
      temp.flush

      reader = PDF::Reader.new(temp.path)
      pages = reader.pages.first(20).map { |page| page.text.to_s.strip }.reject(&:blank?)
      text = pages.join("\n\n")
      raise ExtractionError, "PDF extraction returned empty text." if text.blank?

      text
    ensure
      temp&.close!
    end

    def extract_from_youtube
      video_id = youtube_video_id(@material.source_url)
      raise ExtractionError, "Invalid YouTube URL." if video_id.blank?

      transcript = fetch_youtube_data_api_transcript(video_id) || fetch_json_transcript(video_id) || fetch_xml_transcript(video_id)
      raise ExtractionError, "Could not fetch transcript for this YouTube video." if transcript.blank?

      [youtube_video_header(video_id), transcript].compact.join("\n\n")
    rescue StandardError => e
      raise ExtractionError, "YouTube extraction failed: #{e.message}"
    end

    def youtube_video_id(url)
      uri = URI.parse(url)
      host = uri.host.to_s
      return uri.path.delete_prefix("/") if host.include?("youtu.be")

      query = URI.decode_www_form(uri.query.to_s).to_h
      query["v"]
    rescue URI::InvalidURIError
      nil
    end

    def fetch_json_transcript(video_id)
      endpoint = "https://youtubetranscript.com/?format=json&server_vid2=#{video_id}"
      response = http_get(endpoint)
      data = JSON.parse(response)
      return if !data.is_a?(Array) || data.empty?

      data.map { |line| line["text"].to_s.strip }.reject(&:blank?).join(" ")
    rescue StandardError
      nil
    end

    def fetch_xml_transcript(video_id)
      endpoint = "https://www.youtube.com/api/timedtext?lang=en&v=#{video_id}"
      xml = http_get(endpoint)
      parse_timedtext_xml(xml)
    rescue StandardError
      nil
    end

    def fetch_youtube_data_api_transcript(video_id)
      key = ENV["YOUTUBE_API_KEY"].to_s
      return if key.blank?

      data = youtube_data_api_get(
        path: "/youtube/v3/captions",
        params: { part: "snippet", videoId: video_id, key: key }
      )
      items = Array(data["items"])
      return if items.empty?

      tracks = preferred_caption_tracks(items)
      tracks.each do |item|
        xml = fetch_timedtext_for_track(video_id, item["snippet"] || {})
        next if xml.blank?

        parsed = parse_timedtext_xml(xml)
        return parsed if parsed.present?
      end

      nil
    rescue StandardError
      nil
    end

    def youtube_video_header(video_id)
      key = ENV["YOUTUBE_API_KEY"].to_s
      return if key.blank?

      data = youtube_data_api_get(
        path: "/youtube/v3/videos",
        params: { part: "snippet", id: video_id, key: key }
      )
      item = Array(data["items"]).first
      title = item.dig("snippet", "title").to_s.strip
      return if title.blank?

      "YouTube video: #{title}"
    rescue StandardError
      nil
    end

    def preferred_caption_tracks(items)
      preferred_langs = ENV.fetch("YOUTUBE_TRANSCRIPT_LANGS", "en,en-US").split(",").map(&:strip).reject(&:blank?)
      manual, auto = items.partition { |item| item.dig("snippet", "trackKind").to_s.casecmp("asr") != 0 }
      ordered = manual + auto

      preferred_langs.flat_map do |lang|
        ordered.select { |item| item.dig("snippet", "language") == lang }
      end.uniq + ordered
    end

    def fetch_timedtext_for_track(video_id, snippet)
      params = {
        v: video_id,
        lang: snippet["language"].presence || "en"
      }
      track_kind = snippet["trackKind"].to_s.downcase
      params[:kind] = "asr" if track_kind == "asr"
      track_name = snippet["name"].to_s
      params[:name] = track_name if track_name.present?

      endpoint = "https://www.youtube.com/api/timedtext?#{URI.encode_www_form(params)}"
      http_get(endpoint)
    rescue StandardError
      nil
    end

    def parse_timedtext_xml(xml)
      doc = REXML::Document.new(xml)
      lines = []
      doc.elements.each("transcript/text") do |node|
        lines << node.text.to_s.strip
      end
      lines.reject(&:blank?).join(" ")
    end

    def youtube_data_api_get(path:, params:)
      endpoint = URI::HTTPS.build(host: "www.googleapis.com", path: path, query: URI.encode_www_form(params))
      response = http_get_response(endpoint)
      JSON.parse(response.body)
    end

    def http_get(url)
      uri = URI.parse(url)
      response = http_get_response(uri)
      response.body
    end

    def http_get_response(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.read_timeout = 8
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      raise ExtractionError, "Upstream request failed (#{response.code})." unless response.is_a?(Net::HTTPSuccess)

      response
    end

    def extract_docx_text(binary)
      text = []
      Zip::File.open_buffer(binary) do |zip|
        entry = zip.find_entry("word/document.xml")
        raise ExtractionError, "DOCX file has no document.xml." unless entry

        doc = REXML::Document.new(entry.get_input_stream.read)
        doc.elements.each("//w:t") do |node|
          value = node.text.to_s.strip
          text << value if value.present?
        end
      end

      joined = text.join(" ")
      raise ExtractionError, "DOCX extraction returned empty text." if joined.blank?

      joined
    end

    def extract_pptx_text(binary)
      text = []
      Zip::File.open_buffer(binary) do |zip|
        slide_entries = zip.entries.select { |entry| entry.name.match?(%r{\A(ppt/slides/slide\d+\.xml|ppt/notesSlides/notesSlide\d+\.xml)\z}) }
        raise ExtractionError, "PPTX contains no readable slide XML." if slide_entries.empty?

        slide_entries.each do |entry|
          doc = REXML::Document.new(entry.get_input_stream.read)
          doc.elements.each("//a:t") do |node|
            value = node.text.to_s.strip
            text << value if value.present?
          end
        end
      end

      joined = text.join(" ")
      raise ExtractionError, "PPTX extraction returned empty text." if joined.blank?

      joined
    end
  end
end
