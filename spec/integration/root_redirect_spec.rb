describe "Redirecting the root URL" do

  specify "visiting the root URL redirects me to the licence-finder start page" do
    visit "/"

    i_should_be_on "/#{APP_SLUG}"
  end
end
