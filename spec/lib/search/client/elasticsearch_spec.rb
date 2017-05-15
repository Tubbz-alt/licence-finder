require 'rails_helper'
require "search/client/elasticsearch"

RSpec.describe Search::Client::Elasticsearch do
  before(:each) do
    @index_name = 'test-index'
    @es_config = {
        url:    'localhost',
    }
    @client = Search::Client::Elasticsearch.new(
      index_name: @index_name,
      settings: 'test-create',
      type: 'test-type',
      config: @es_config
    )
  end

  describe "indexing" do
    it "deletes and creates index with mapping before re-indexing" do
      allow_any_instance_of(
        Elasticsearch::API::Indices::IndicesClient
      ).to receive(:delete).with(index: @index_name, ignore: [404])

      allow_any_instance_of(
        Elasticsearch::API::Indices::IndicesClient
      ).to receive(:create).with(index: @index_name, body: /.*/).and_return(true)

      @client.pre_index
    end

    it "indexes provided sectors" do
      s1 = FactoryGirl.create(:sector, public_id: 1, name: "Sector One")
      allow_any_instance_of(
        Elasticsearch::Transport::Client
      ).to receive(:create).with(
        hash_including(@client.to_document(s1))
      ).and_return(true)

      s2 = FactoryGirl.create(:sector, public_id: 2, name: "Sector Two")
      allow_any_instance_of(
        Elasticsearch::Transport::Client
      ).to receive(:create).with(
        hash_including(@client.to_document(s2))
      ).and_return(true)

      s3 = FactoryGirl.create(:sector, public_id: 3, name: "Sector Three")
      allow_any_instance_of(
        Elasticsearch::Transport::Client
      ).to receive(:create).with(
        hash_including(@client.to_document(s3))
      ).and_return(true)

      @client.index([s1, s2, s3])
    end

    it "converts a sector to a hash with the correct fields set" do
      document = @client.to_document(
        FactoryGirl.build(
          :sector,
          public_id: 123,
          name: "Test Sector"
        )
      )

      expect(document).to eq(
        id: 123,
        type: "test-type",
        body: {
          public_id: 123,
          title: "Test Sector",
          extra_terms: [],
          activities: []
        }
      )
    end

    it "adds extra_terms to document when available" do
      allow(@client).to receive(:extra_terms).and_return(
        123 => %w(foo bar monkey)
      )
      document = @client.to_document(
        FactoryGirl.build(
          :sector,
          public_id: 321,
          correlation_id: 123,
          name: "Test Sector"
        )
      )

      expect(document).to eq(
        id: 321,
        type: "test-type",
        body: {
          public_id: 321,
          title: "Test Sector",
          extra_terms: %w(foo bar monkey),
          activities: []
        }
      )
    end

    it "commits after re-indexing" do
      allow_any_instance_of(
        Elasticsearch::API::Indices::IndicesClient
      ).to receive(:refresh).with(index: @index_name)

      @client.post_index
    end
  end

  describe "deleting" do
    it "deletes the index" do
      allow_any_instance_of(
        Elasticsearch::API::Indices::IndicesClient
      ).to receive(:delete).with(index: @index_name, ignore: [404])

      @client.delete_index
    end
  end

  describe "searching" do
    it "searches the title with a text query and just returns ids" do
      es_response = {
        'hits' => {
          'hits' => [
            { 'fields' => { 'public_id' => [123] } },
            { 'fields' => { 'public_id' => [234] } },
          ]
        }
      }

      allow_any_instance_of(Elasticsearch::Transport::Client).to receive(:search).with(
        index: @index_name,
        q: 'query',
        fields: %w(public_id title extra_terms activities),
        sort: '_score:desc',
      ).and_return(es_response)

      expect(@client.search("query")).to eq([123, 234])
    end
  end

  describe "Lucene search escaping characters" do
    it "returns valid strings back" do
      expect(@client.escape_lucene_chars("blargh")).to eq("blargh")
      expect(@client.escape_lucene_chars("Testing")).to eq("Testing")
    end

    it "removes expected special chars" do
      %w(+ - && || ! ( ) { } [ ] ^ " ~ * ? \ :).each { |char|
        char.strip!
        expect(@client.escape_lucene_chars("#{char}blargh")).to eq("\\#{char}blargh")
      }
    end

    it "downcases search keywords" do
      expect(@client.downcase_ending_keywords("bleh AND")).to eq("bleh and")
      expect(@client.downcase_ending_keywords("bleh OR")).to eq("bleh or")
      expect(@client.downcase_ending_keywords("bleh NOT")).to eq("bleh not")
    end
  end
end
