namespace :panopticon do
  desc "Register application metadata with panopticon"
  task register: :environment do
    PanopticonNotifier.notify
  end
end
