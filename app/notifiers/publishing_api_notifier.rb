require 'services'

class PublishingApiNotifier
  LICENCE_FINDER_FORM_DETAILS = {
    "/licence-finder/sectors" => "4ade13fa-7e79-4bee-b809-61dbe5c3aa22",
    "/licence-finder/activities" => "82162026-c815-4cc5-93ef-514fe467409a",
    "/licence-finder/location" => "45cb0572-d71a-4c22-a84f-fdc53c2e7bc4",
    "/licence-finder/licences" => "e1dc997a-3afe-4180-8c8d-880e7c1ca5a1",
    "/licence-finder/browse-sectors" => "2cae8a3f-1231-4379-bdca-1de9b4668508"
  }.freeze

  def self.publish
    LICENCE_FINDER_FORM_DETAILS.each do |base_path, content_id|
      new.publish(LicenceFinderFormContentItemPresenter.new(base_path, content_id))
    end
    new.publish(LicenceFinderContentItemPresenter.new)
  end

  def publish(presenter)
    Services.publishing_api.put_content(presenter.content_id, presenter.payload)
    Services.publishing_api.publish(presenter.content_id, presenter.update_type)
  end
end
