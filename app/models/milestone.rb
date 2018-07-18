class Milestone < ActiveRecord::Base
  include Imageable
  include Documentable
  documentable max_documents_allowed: 3,
               max_file_size: 3.megabytes,
               accepted_content_types: [ "application/pdf" ]

  translates :title, :description, touch: true
  globalize_accessors locales: [:en, :es, :fr, :nl, :val, :pt_br]

  belongs_to :milestoneable, polymorphic: true
  belongs_to :status

  validates :title, presence: true
  validates :milestoneable, presence: true
  validates :publication_date, presence: true
  validate :description_or_status_present?

  scope :order_by_publication_date, -> { order(publication_date: :asc) }

  def self.find_milestoneable(type, id)
    # TODO maybe try adding included callback to Milestoneable concern, where
    # base is added to a class var on Milestone, or Milestoneable. Can then
    # be retrieved. Then just make sure type string is one of them.
    #
    # Or:
    #
    # ObjectSpace.each_object(Class).select { |c| c.included_modules.include? MyMod }
    type.constantize.find(id)
  end

  def self.title_max_length
    80
  end

  def description_or_status_present?
    unless description.present? || status_id.present?
      errors.add(:description)
    end
  end
end
