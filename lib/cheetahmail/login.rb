module CheetahMail
  class LoginError < StandardError; end

  class Login
    def initialize(url: nil)
      @url = url || "https://app.cheetahmail.com/cm/login"
    end

    def call(username:, password:)
      first_page = AGENT.get(@url)
      login_form = first_page.forms.find { |f| f.action.include? "login" }
      login_form.username = username

      second_page = AGENT.submit(login_form)
      login_form = second_page.forms.find { |f| f.action.include? "login" }
      login_form.cleartext = password
      login_button = login_form.button_with(value: "Login")

      account_page = login_form.click_button(login_button)
      unless account_page.search("title").first.text.include? "Welcome"
        fail LoginError
      end

      CheetahMail.logged_in = true
    end
  end
end
