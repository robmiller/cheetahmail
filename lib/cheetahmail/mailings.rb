require "json"
require "retries"
require "chronic"

module CheetahMail
  class Mailings
    def initialize
      @mailings_url = "https://app.cheetahmail.com/cm/r/mailings?sort=date&dir=DESC"
    end

    def mailings
      @mailings ||=
        begin
          fail NotAuthorised unless CheetahMail.logged_in?

          json = AGENT.get_file(@mailings_url)
          json = json.force_encoding("UTF-8").delete("\xEF\xBB\xBF")
          mailings = JSON.parse(json, symbolize_names: true)

          mailings[:data][:data].map do |id, name, subject, _, _, segment, _, _, _, _, sent|

            if sent
              Chronic.parse(sent_at = sent[/(\S+ \S+) /, 1])
              sent_to = sent[/\(([0-9]+)\)/, 1].to_i
            else
              sent_to = 0
              sent_at = nil
            end
            Mailing.new(id, name, subject, segment, sent_to, sent_at)
          end
        end
    end
  end

  Mailing = Struct.new(:id, :name, :subject, :segment, :sent_to, :sent_at)
end
