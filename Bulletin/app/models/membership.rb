class Membership < ActiveRecord::Base
	# A link between a user and a group they belong to
	belongs_to :user
	belongs_to :group
end
