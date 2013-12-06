require 'spec_helper'

describe "Start page" do

  specify "Inspecting the start page" do

    visit "/#{APP_SLUG}"

    within '#content' do
      

      within 'article[role=article]' do
        within 'section.intro' do
          page.should have_link("Find licences", :href => sectors_path)
        end
      end

      page.should have_selector(".article-container #test-report_a_problem")
    end

  end

  context "Seeing popular licences on the start page" do
    before :each do
      @popular_licence_ids = LicenceFinderController::POPULAR_LICENCE_IDS
      @popular_licence_ids.each do |gds_id|
        FactoryGirl.create(:licence, :gds_id => gds_id)
      end
    end

    specify "should not see popular licences section if none of the popular licences are available in Content API" do
      visit "/#{APP_SLUG}"

      page.should_not have_selector('div.popular-licences')
      page.should_not have_content('Popular licences')
    end

    specify "should display licences available in Content API" do
      content_api_has_licence :licence_identifier => @popular_licence_ids[0],
        :slug => 'licence-one', :title => 'Licence 1',
        :licence_short_description => "Short description of licence 1"
      content_api_has_licence :licence_identifier => @popular_licence_ids[1],
        :slug => 'licence-two', :title => 'Licence 2',
        :licence_short_description => "Short description of licence 2"

      visit "/#{APP_SLUG}"

      within 'div.popular-licences' do
        page.should have_content("Popular licences")

        page.all('li a').map(&:text).map(&:strip).should == [
          'Licence 1',
          'Licence 2',
        ]

        within_section "list item containing Licence 1" do
          page.should have_link("Licence 1", :href => "http://www.test.gov.uk/licence-one")
          page.should have_content("Short description of licence 1")
        end

        within_section "list item containing Licence 2" do
          page.should have_link("Licence 2", :href => "http://www.test.gov.uk/licence-two")
          page.should have_content("Short description of licence 2")
        end
      end
    end

    specify "should only display the first 3 that are available" do
      content_api_has_licence :licence_identifier => @popular_licence_ids[0], :slug => 'licence-one', :title => 'Licence 1',
            :licence_short_description => "Short description of licence 1"
      content_api_has_licence :licence_identifier => @popular_licence_ids[1], :slug => 'licence-two', :title => 'Licence 2',
            :licence_short_description => "Short description of licence 2"
      content_api_has_licence :licence_identifier => @popular_licence_ids[3], :slug => 'licence-four', :title => 'Licence 4',
            :licence_short_description => "Short description of licence 4"
      content_api_has_licence :licence_identifier => @popular_licence_ids[4], :slug => 'licence-five', :title => 'Licence 5',
            :licence_short_description => "Short description of licence 5"

      visit "/#{APP_SLUG}"

      within 'div.popular-licences' do
        page.all('li a').map(&:text).map(&:strip).should == [
          'Licence 1',
          'Licence 2',
          'Licence 4',
        ]
      end
    end
  end
end
