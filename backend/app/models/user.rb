class User < ApplicationRecord
  has_many :receipts, dependent: :destroy

  validates :clerk_id, uniqueness: true, allow_nil: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: /\A[^@\s]+@[^@\s]+\z/ }

  before_validation { self.email = email.to_s.strip.downcase }

  # Finds the local user for a Clerk user id. The first time a Clerk user is
  # seen, an existing local user with the same email is linked to it (so
  # receipts survive the migration); otherwise a new one is created.
  def self.from_clerk(clerk_id)
    find_by(clerk_id: clerk_id) || link_or_create(Clerk.fetch_user(clerk_id))
  rescue ActiveRecord::RecordNotUnique
    find_by!(clerk_id: clerk_id)
  end

  def self.link_or_create(payload)
    email = payload["email_addresses"]
      .find { |e| e["id"] == payload["primary_email_address_id"] }&.fetch("email_address")
    raise Clerk::InvalidToken, "clerk user has no email" if email.blank?

    user = find_by(clerk_id: nil, email: email.downcase) || new(email: email)
    user.clerk_id = payload["id"]
    user.name = [ payload["first_name"], payload["last_name"] ].compact_blank.join(" ").presence ||
      payload["username"].presence || email.split("@").first if user.name.blank?
    user.save!
    user
  end
end
