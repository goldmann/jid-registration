class Messages
  def self.errors
    {
      :invalid_captcha => { :log => "ERR-001: Invalid captcha, username '#USERNAME#'", :message => "Niepoprawny tekst z obrazka, spróbuj jeszcze raz"},
      :empty_password => { :log => "ERR-002: Empty password", :message => "Nie podano hasła"},
      :password_too_short => { :log => "ERR-003: Password too short", :message => "Hasło jest zbyt krótkie, użyj minimum 6 znaków"},
      :password_mismatch => { :log => "ERR-004: Password do not match", :message => "Podane hasła nie zgadzają się"},
      :user_exists => { :log => "ERR-005: User '#USERNAME#' already exists", :message => "Użytkownik '#USERNAME#' już istnieje, wybierz inną nazwę"},
      :request_not_authorized => { :log => "ERR-006: Request is not authorized", :message => "Wystąpił błąd podczas zakładania konta - w przypadku, gdy sytuacja będzie się powtarzać - skontaktuj się z administratorem"},
      :shared_group_exception => { :log => "ERR-007: Shared group exception", :message => "Wystąpił błąd podczas zakładania konta - w przypadku, gdy sytuacja będzie się powtarzać - skontaktuj się z administratorem"},
      :registration_disabled => { :log => "ERR-008: Registration is disabled", :message => "Rejestracja jest wyłączona - spróbuj w innym momencie"},
      :unknown_error => { :log => "ERR-009: Bad thing happened", :message => "Wystąpił błąd podczas zakładania konta - w przypadku, gdy sytuacja będzie się powtarzać - skontaktuj się z administratorem"},
      :empty_username => { :log => "ERR-010: Empty username", :message => "Nie podano nazwy użytkownika"},
      :limit_exceeded => { :log => "ERR-011: Limit exceeded", :message => "Zbyt duża ilość rejestracji z wybranego adresu IP, spróbuj później"}
    }
  end

  def self.infos
    {
      :user_registered => { :log => "OK-001: User '#USERNAME#' registered", :message => "Konto '#USERNAME#' zostało założone"}
    }
  end
end
