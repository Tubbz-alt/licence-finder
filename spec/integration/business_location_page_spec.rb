require "spec_helper"

describe "Business location page" do
  def set_up
    @s1 = FactoryGirl.create(:sector, name: "Fooey Sector")
    @s2 = FactoryGirl.create(:sector, name: "Balooey Sector")

    @a1 = FactoryGirl.create(:activity, name: "Fooey Activity", sectors: [@s1])
    @a2 = FactoryGirl.create(:activity, name: "Kablooey Activity", sectors: [@s2])
    @a3 = FactoryGirl.create(:activity, name: "Kabloom", sectors: [@s1, @s2])
  end

  it "should allow user to set location" do
    set_up
    sectors = [@s1, @s2].map(&:public_id).join('_')
    activities = [@a1, @a2].map(&:public_id).join('_')
    visit "/#{APP_SLUG}/location?sectors=#{sectors}&activities=#{activities}"

    within_section 'completed questions' do
      page.all(:xpath, ".//h3[contains(@class, 'question')]/text()").map(&:text).map(&:strip).reject(&:blank?).should == [
        "What kind of activities or business do you need a licence for?",
        'What will your activities or business involve doing?',
      ]
    end
    within_section 'completed question 1' do
      page.all('.answer li').map(&:text).should == [
        'Fooey Sector',
        'Balooey Sector'
      ]
    end
    within_section 'completed question 2' do
      page.all('.answer li').map(&:text).should == [
        'Fooey Activity',
        'Kablooey Activity'
      ]
    end

    within_section 'current question' do
      page.should have_content('Where will your activities or business be located?')

      page.all(:xpath, '//select[@id="location"]//option/@value').map(&:text).should == [
        '',
        'england',
        'scotland',
        'wales',
        'northern_ireland'
      ]
    end

    page.should_not have_selector(*selector_of_section('upcoming questions'))

    select('England', from: 'location')

    click_on 'Set location'

    i_should_be_on "/#{APP_SLUG}/licences", ignore_query: true
  end

  it "should complain if no sectors are provided"
  it "should complain if no activities are provided"
  it "should complain if the activities provided are not valid for the sectors"
end
