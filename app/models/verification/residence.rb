class Verification::Residence
  include ActiveModel::Model
  include ActiveModel::Dates
  include ActiveModel::Validations::Callbacks

  attr_accessor :user, :document_number, :document_type, :date_of_birth, :postal_code, :terms_of_service, :redeemable_code

  before_validation :call_census_api

  validates_presence_of :document_number
  validates_presence_of :document_type
  validates_presence_of :date_of_birth
  validates_presence_of :postal_code
  validates :terms_of_service, acceptance: { allow_nil: false }
  validates :postal_code, length: { is: 5 }

  validate :allowed_age
  validate :document_number_uniqueness
  validate :postal_code_in_madrid
  validate :residence_in_madrid
  validate :redeemable_code_is_redeemable

  def initialize(attrs={})
    self.date_of_birth = parse_date('date_of_birth', attrs)
    attrs = remove_date('date_of_birth', attrs)
    super
    self.redeemable_code ||= self.user.try(:redeemable_code)
    clean_document_number
  end

  def save
    return false unless valid?
    user.update(document_number:       document_number,
                document_type:         document_type,
                geozone:               self.geozone,
                residence_verified_at: Time.now)

    if redeemable_code.present?
      RedeemableCode.redeem(redeemable_code, self.geozone, user)
    end
    true
  end

  def allowed_age
    return if errors[:date_of_birth].any?
    errors.add(:date_of_birth, I18n.t('verification.residence.new.error_not_allowed_age')) unless self.date_of_birth <= 16.years.ago
  end

  def document_number_uniqueness
    errors.add(:document_number, I18n.t('errors.messages.taken')) if User.where(document_number: document_number).any?
  end

  def postal_code_in_madrid
    errors.add(:postal_code, I18n.t('verification.residence.new.error_not_allowed_postal_code')) unless valid_postal_code?
  end

  def redeemable_code_is_redeemable
    return if redeemable_code.blank?
    unless RedeemableCode.redeemable?(redeemable_code, self.geozone)
      errors.add(:redeemable_code, I18n.t('verification.residence.new.error_can_not_redeem_code'))
    end
  end

  def residence_in_madrid
    return if errors.any?

    unless residency_valid?
      errors.add(:residence_in_madrid, false)
      store_failed_attempt
      Lock.increase_tries(user)
    end
  end

  def store_failed_attempt
    FailedCensusCall.create({
      user: user,
      document_number: document_number,
      document_type:   document_type,
      date_of_birth:   date_of_birth,
      postal_code:     postal_code
      #hot fix. Check out the Census API to catch the exception earlier.
      #district_code:   district_code
    })
  end

  def geozone
    Geozone.where(census_code: district_code).first
  end

  def district_code
    @census_api_response.district_code
  end

  private

    def call_census_api
      @census_api_response = CensusApi.new.call(document_type, document_number)
    end

    def residency_valid?
      @census_api_response.valid? &&
        @census_api_response.postal_code == postal_code &&
        @census_api_response.date_of_birth == date_to_string(date_of_birth)
    end

    def clean_document_number
      self.document_number = self.document_number.gsub(/[^a-z0-9]+/i, "").upcase unless self.document_number.blank?
    end

    def valid_postal_code?
      postal_code =~ /^280/
    end

end
