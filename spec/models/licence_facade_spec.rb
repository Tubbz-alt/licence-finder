require 'spec_helper'

describe LicenceFacade do

  def licence_hash(licence)
    {
      "title" => "Publisher title",
      "id" => "http://example.org/licence-slug.json",
      "web_url" =>  "http://www.test.gov.uk/licence-slug",
      "format" => "licence",
      "details" => {
        "need_id" => nil,
        "business_proposition" => false,
        "alternative_title" => nil,
        "overview" => nil,
        "will_continue_on" => nil,
        "continuation_link" => nil,
        "licence_identifier" => licence.gds_id,
        "licence_short_description" => "Short description of licence",
        "licence_overview" => nil,
        "updated_at" => "2012-10-06T12:00:05+01:00"
      },
      "tags" => [],
      "related" => []
    }
  end

  def json_response_data(*licences)
    {
      "_response_info" => { "status" => "ok" },
      "description" => "Licences",
      "total" => 1,
      "start_index" => 1,
      "page_size" => 1,
      "current_page" => 1,
      "pages" => 1,
      "results" => licences.map { |l| licence_hash(l) }
    }.to_json
  end

  def api_response_data(licence)
    response = OpenStruct.new(
      code: 200,
      body: json_response_data(licence)
    )
    GdsApi::Response.new(response)
  end

  describe "create_for_licences" do
    before :each do
      GdsApi::ContentApi.any_instance.stub(:licences_for_ids).and_return([])
      @l1 = FactoryGirl.create(:licence)
      @l2 = FactoryGirl.create(:licence)
    end

    it "should query Content API for licence details" do
      GdsApi::ContentApi.any_instance.should_receive(:licences_for_ids).with([@l1.gds_id, @l2.gds_id]).and_return([])
      LicenceFacade.create_for_licences([@l1, @l2])
    end

    it "should skip querying Content API if not given any licences" do
      GdsApi::ContentApi.any_instance.unstub(:licences_for_ids) # clear the stub above, otherwise the next line won't work
      GdsApi::ContentApi.any_instance.should_not_receive(:licences_for_ids)
      LicenceFacade.create_for_licences([])
    end

    it "should construct Facades for each licence maintaining order" do
      result = LicenceFacade.create_for_licences([@l1, @l2])
      result.map(&:licence).should == [@l1, @l2]
    end

    it "should add the Content API details to each Facade where details exist" do
      pub_data2 = api_response_data(@l2)
      GdsApi::ContentApi.any_instance.should_receive(:licences_for_ids).and_return(pub_data2)

      result = LicenceFacade.create_for_licences([@l1, @l2])
      result[0].licence.should == @l1
      result[0].publisher_data.should == nil
      result[1].licence.should == @l2
      result[1].publisher_data.should == licence_hash(@l2)
    end

    context "when Content API returns nil" do
      before :each do
        GdsApi::ContentApi.any_instance.stub(:licences_for_ids).and_return(nil)
      end

      it "should continue with no content API data" do
        result = LicenceFacade.create_for_licences([@l1, @l2])
        result[0].licence.should == @l1
        result[0].publisher_data.should == nil
        result[1].licence.should == @l2
        result[1].publisher_data.should == nil
      end

      it "should log the error" do
        Rails.logger.should_receive(:warn).with("Error fetching licence details from Content API")
        LicenceFacade.create_for_licences([@l1, @l2])
      end
    end

    context "when Content API times out" do
      before :each do
        GdsApi::ContentApi.any_instance.stub(:licences_for_ids).and_raise(GdsApi::TimedOutException)
      end

      it "should continue with no Content API data" do
        result = LicenceFacade.create_for_licences([@l1, @l2])
        result[0].licence.should == @l1
        result[0].publisher_data.should == nil
        result[1].licence.should == @l2
        result[1].publisher_data.should == nil
      end

      it "should log the error" do
        Rails.logger.should_receive(:warn).with("GdsApi::TimedOutException fetching licence details from Content API")
        LicenceFacade.create_for_licences([@l1, @l2])
      end
    end

    context "when Content API errors" do
      before :each do
        GdsApi::ContentApi.any_instance.stub(:licences_for_ids).and_raise(GdsApi::HTTPErrorResponse.new(503))
      end

      it "should continue with no API data" do
        result = LicenceFacade.create_for_licences([@l1, @l2])
        result[0].licence.should == @l1
        result[0].publisher_data.should == nil
        result[1].licence.should == @l2
        result[1].publisher_data.should == nil
      end

      it "should log the error" do
        Rails.logger.should_receive(:warn).with("GdsApi::HTTPErrorResponse(503) fetching licence details from Content API")
        LicenceFacade.create_for_licences([@l1, @l2])
      end
    end
  end

  describe "attribute accessors" do
    before :each do
      @licence = FactoryGirl.create(:licence)
    end

    context "with API data" do
      before :each do
        @pub_data = licence_hash(@licence)
        @lf = LicenceFacade.new(@licence, @pub_data)
      end

      it "should be published" do
        @lf.published?.should == true
      end

      it "should return the API title" do
        @lf.title.should == @pub_data['title']
      end

      it "should return the frontend url" do
        @lf.url.should == @pub_data['web_url']
      end

      it "should return the API short description" do
        @lf.short_description.should == @pub_data['details']['licence_short_description']
      end
    end

    context "without API data" do
      before :each do
        @lf = LicenceFacade.new(@licence, nil)
      end

      it "should not be published?" do
        @lf.published?.should == false
      end

      it "should return the licence name" do
        @lf.title.should == @licence.name
      end

      it "should return nil for the url" do
        @lf.url.should == nil
      end

      it "should return nil for the short_description" do
        @lf.short_description.should == nil
      end
    end
  end
end
