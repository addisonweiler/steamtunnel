class User < ActiveRecord::Base
	has_and_belongs_to_many :groups
  has_and_belongs_to_many :favorites, :class_name => "Event", :join_table => :favorites_users
  has_and_belongs_to_many :selections, :class_name => "Group", :join_table => :selections_users
  serialize :friends # FB Friends

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  #validates :email, :uniqueness => true
  after_create :create_personal_group
  after_create :create_personal_group

  # Store FB Friends
  def add_friends(token)
    @graph = Koala::Facebook::API.new(oauth_access_token)
  end

  # Create a group for the user to post personal events
  def create_personal_group
    pgroup = Group.create(:name => self.email, :personal => true)
    pgroup.users << self
  end

  # User name defaults to email until set by FB connect
  def name
    val = read_attribute(:name)
    return val.nil? ? self.email : val
  end

  def first_name
    return self.name.split[0]
  end

  # The name of the user's Facebook group
  def fb_group
    return self.first_name + "'s Facebook Events"
  end
end
