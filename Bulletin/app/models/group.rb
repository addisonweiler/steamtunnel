class Group < ActiveRecord::Base
	has_many :events
	has_and_belongs_to_many :users
  has_and_belongs_to_many :tags
  serialize :data # Hack for storing GroupSync officer data

  validates :name, :uniqueness => true

  def self.find_by_name_or_create(name)
    group = self.find_by_name(name)
    if group.nil?
      group = self.create(:name => name)
    end
    return group
  end
end
