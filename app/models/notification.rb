class Notification < ActiveRecord::Base
  include Notifiable

  belongs_to :user, counter_cache: true
  belongs_to :notifiable, polymorphic: true

  scope :unread,      -> { all }
  scope :recent,      -> { order(id: :desc) }
  scope :not_emailed, -> { where(emailed_at: nil) }
  scope :for_render,  -> { includes(:notifiable) }

  def timestamp
    notifiable.created_at
  end

  def mark_as_read
    destroy
  end

  def self.add(user_id, notifiable)
    notification = Notification.find_by(user_id: user_id, notifiable: notifiable)

    if notification.present?
      Notification.increment_counter(:counter, notification.id)
    else
      Notification.create!(user_id: user_id, notifiable: notifiable)
    end
  end

end