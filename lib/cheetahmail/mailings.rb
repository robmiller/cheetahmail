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

          mailings[:data][:data].map do |id, name, subject, _, _, segment, _, _, _, _, sent, wostart, _, _, _, aid|

            if sent
              Chronic.parse(sent_at = sent[/(\S+ \S+) /, 1])
              sent_to = sent[/\(([0-9]+)\)/, 1].to_i
            else
              sent_to = 0
              sent_at = nil
            end
            Mailing.new(id, name, subject, segment, sent_to, sent_at, wostart, aid)
          end
        end
    end
  end

  Mailing = Struct.new(:id, :name, :subject, :segment, :sent_to, :sent_at, :wostart, :aid) do
    class NotSentError < StandardError; end

    def reporting_url
      "https://app.cheetahmail.com/cgi-bin/mailers/rep/mailsum.cgi?desired_aid=#{aid}&pid=#{id}&wostart=#{wostart}"
    end

    def report
      @report ||=
        begin
          page = nil

          with_retries(max_tries: 20, base_sleep_seconds: 1, max_sleep_seconds: 30, rescue: NotGeneratedError) do
            page = AGENT.get(reporting_url)

            if page.search("body").text =~ /report is not available/
              fail NotSentError
            end

            if page.search("body").text =~ /currently being generated/
              $stderr.puts "The mailing report hasn't been generated yet. Waiting"
              fail NotGeneratedError
            end

            received = received(page)
            opens    = opens(page)
            clicks   = clicks(page)

            { received: received, opens: opens, clicks: clicks }
            end
        rescue NotSentError
          { received: 0, opens: { all: 0, unique: 0 }, clicks: { all: 0, unique: 0 } }
        end
    end

    private
    def received(page)
      page.search("a")
        .find { |a| a.attr("href").include? "message=rec" }
        .text
        .delete(",")
        .to_i
    end

    def opens(page)
      all = page
        .search("td")
        .find { |td| td.text == "All:" }
        .parent
        .css("td:nth-child(2)")
        .text
        .delete(",")
        .to_i

      unique = page
        .search("td")
        .find { |td| td.text == "Unique:" }
        .parent
        .css("td:nth-child(2)")
        .text
        .delete(",")
        .to_i

      { all: all, unique: unique }
    end

    def clicks(page)
      all = page
        .search("td")
        .find { |td| td.text == "All:" }
        .parent
        .css("td:nth-child(5)")
        .text
        .delete(",")
        .to_i

      unique = page
        .search("td")
        .find { |td| td.text =~ /^Unique.+Clickers:$/ }
        .parent
        .css("td:nth-child(3)")
        .text
        .delete(",")
        .to_i

      { all: all, unique: unique }
    end
  end
end
