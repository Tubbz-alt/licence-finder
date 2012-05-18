class Activity
  include Mongoid::Document
  field :public_id, :type => Integer
  index :public_id, :unique => true
  field :correlation_id, :type => Integer
  index :correlation_id, :unique => true
  field :name, :type => String
  has_and_belongs_to_many :sectors

  validates :name, :presence => true

  before_save :set_public_id

  def self.find_by_public_id(public_id)
    where(public_id: public_id).first
  end

  def self.find_by_public_ids(public_ids)
    self.any_in public_id: public_ids
  end

  def self.find_by_correlation_id(correlation_id)
    where(correlation_id: correlation_id).first
  end

  def self.find_by_sectors(sectors)
    activity_ids = sectors.map(&:activity_ids).flatten
    self.any_in _id: activity_ids
  end

  def to_s
    self.name
  end

  def set_public_id
    # TODO: factor out
    if self.public_id.nil?
      counter = Mongoid.database["counters"].find_and_modify(
        :query  => {:_id  => "activity"},
        :update => {:$inc => {:count => 1}},
        :new    => true,
        :upsert => true
      )["count"]
      self.public_id = counter
    end
  end
end
