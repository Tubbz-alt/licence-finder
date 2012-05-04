require 'spec_helper'

describe Sector do
  it "should use the correct field types on the model" do
    Sector.safely.create!(
      :public_id => 42,
      :name => "Some Sector",
      :activities => [1, 34, 42]
    )
    sector = Sector.first
    sector.public_id.should == 42
    sector.name.should == "Some Sector"
    sector.activities.should == [1, 34, 42]
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
  end
end
