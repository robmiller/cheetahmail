require "json"
require "retries"

module CheetahMail
  class Segmentation
    def initialize
      @segments_url = "https://app.cheetahmail.com/cm/r/segments/active"
    end

    def segments
      @segments ||=
        begin
          fail NotAuthorised unless CheetahMail.logged_in?

          json = AGENT.get_file(@segments_url)
          json = json.force_encoding("UTF-8").delete("\xEF\xBB\xBF")
          segments = JSON.parse(json, symbolize_names: true)

          segments[:data][:data].map { |id, name| Segment.new(id.to_i, name) }
        end
    end
  end

  Segment = Struct.new(:id, :name) do
    def filename
      CheetahMail.output_dir + "segment_#{id}_#{safe_name}.csv"
    end

    def safe_name
      @safe_name ||= name.downcase
        .gsub(/\s+/, "-")
        .gsub(/[^a-zA-Z0-9_\-]/, "")
    end

    def download
      file_url = "https://app.cheetahmail.com/cm/r/segment/file"

      AGENT.post(
        file_url,
        {
          "id"          => "[#{id}]",
          "fields"      => '["EMAIL"]',
          "delimiter"   => ",",
          "want_quoted" => "0",
          "want_header" => "1",
          "ttb_path"    => "",
        }
      )

      with_retries(max_tries: 20, base_sleep_seconds: 1, max_sleep_seconds: 30, rescue: NotGeneratedError) do
        CheetahMail.log "Attempting to download segment #{id}."

        begin
          response = AGENT.get("#{file_url}?id=#{id}")
        rescue Mechanize::ResponseCodeError
          CheetahMail.log "File doesn't seem to be generated yet."
          raise NotGeneratedError
        end

        if response.body.length < 1
          CheetahMail.log "File exists, but isn't yet generated."
          raise NotGeneratedError
        end

        CheetahMail.log "File is downloaded for segment #{id}"
        response.save!(filename)
      end
    end
  end
end
