require 'spec_helper'

describe Sector do
  it "should use the correct field types on the model" do
    Sector.safely.create!(
      :public_id => 42,
      :name => "Some Sector"
    )
    sector = Sector.first
    sector.public_id.should == 42
    sector.name.should == "Some Sector"
  end

  describe "validations" do
    before :each do
      @sector = FactoryGirl.build(:sector)
    end

    it "should have a database level uniqueness constraint on public_id" do
      FactoryGirl.create(:sector, :public_id => 42)
      @sector.public_id = 42
      lambda do
        @sector.safely.save
      end.should raise_error(Mongo::OperationFailure)
    end

    it "should require a name" do
      @sector.name = ''
      @sector.should_not be_valid
    end
  end

  describe "associations" do
    it "has many activities" do
      a1 = FactoryGirl.create(:activity)
      a2 = FactoryGirl.create(:activity)

      s = FactoryGirl.build(:sector)
      s.activities << a1
      s.activities << a2
      s.save!

      s.reload
      s.activities.should == [a1, a2]
    end
  end

  describe "retrieval" do
    before :each do
      @sector = FactoryGirl.create(:sector)
    end

    it "should be able to retrieve by public_id" do
      found_sector = Sector.find_by_public_id(@sector.public_id)
      found_sector.should == @sector
    end

    it "should fail to retrieve a non-existent public_id" do
      found_sector = Sector.find_by_public_id(@sector.public_id + 1)
      found_sector.should == nil
    end
  end
end
