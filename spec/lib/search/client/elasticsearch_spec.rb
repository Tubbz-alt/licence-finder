require "spec_helper"
require "search/client/elasticsearch"

describe Search::Client::Elasticsearch do
  before(:each) do
    @es_config = {
        url:    'localhost',
        index:  'test-index',
        type:   'test-type',
        create: 'test-create'
    }
    @es_indexer = stub()
    @client = Search::Client::Elasticsearch.new(@es_config)
    @client.stub(:indexer).and_return(@es_indexer)
  end

  describe "indexing" do
    it "should delete and create index with mapping before re-indexing" do
      @es_indexer.should_receive(:delete)
      @es_indexer.should_receive(:create).with("test-create").and_return(true)
      @client.pre_index
    end

    it "should index provided sectors" do
      s1 = FactoryGirl.create(:sector, public_id: 1, name: "Sector One")
      s2 = FactoryGirl.create(:sector, public_id: 2, name: "Sector Two")
      s3 = FactoryGirl.create(:sector, public_id: 3, name: "Sector Three")
      # indexing = sequence("indexing")
      @client.should_receive(:to_document).with(s1).and_return(:doc1)
      @es_indexer.should_receive(:store).with(:doc1)
      @client.should_receive(:to_document).with(s2).and_return(:doc2)
      @es_indexer.should_receive(:store).with(:doc2)
      @client.should_receive(:to_document).with(s3).and_return(:doc3)
      @es_indexer.should_receive(:store).with(:doc3)

      @client.index [s1, s2, s3]
    end

    it "should convert a sector to a hash with the correct fields set" do
      document = @client.to_document(FactoryGirl.build(:sector, public_id: 123, name: "Test Sector"))
      document.should == {_id: 123, type: "test-type", public_id: 123, title: "Test Sector", extra_terms: [], activities: []}
    end

    it "should add extra_terms to document when available" do
      @client.stub(:extra_terms).and_return({123 => %w(foo bar monkey)})
      document = @client.to_document(FactoryGirl.build(:sector, public_id: 321, correlation_id: 123, name: "Test Sector"))
      document.should == {_id: 321, type: "test-type", public_id: 321, title: "Test Sector", extra_terms: %w(foo bar monkey), activities: []}
    end

    it "should commit after re-indexing" do
      @es_indexer.should_receive(:refresh)
      @client.post_index
    end
  end

  describe "deleting" do
    it "should delete the index" do
      @es_indexer.should_receive(:delete)

      @client.delete_index
    end
  end

  describe "searching" do
    it "should search the title with a text query and just return ids" do
      d1 = stub()
      d1.should_receive(:public_id).and_return(123)
      d2 = stub()
      d2.should_receive(:public_id).and_return(234)
      response = stub()
      response.should_receive(:results).and_return([d1, d2])

      Tire.should_receive(:search).with(@es_config[:index], {
          query: {
              query_string: {
                  fields: %w(title extra_terms activities),
                  query: "query"
              }
          }
      }).and_return(response)
      @client.search("query").should == [123, 234]
    end
  end

  describe "Lucene search escaping characters" do
    it "should return valid strings back" do
      @client.escape_lucene_chars("blargh").should == "blargh"
      @client.escape_lucene_chars("Testing").should == "Testing"
    end

    it "should remove expected special chars" do
      %w(+ - && || ! ( ) { } [ ] ^ " ~ * ? \ :).each { |char|
        char.strip!
        @client.escape_lucene_chars("#{char}blargh").should == "\\#{char}blargh"
      }
    end

    it "should downcase search keywords" do
      @client.downcase_ending_keywords("bleh AND").should == "bleh and"
      @client.downcase_ending_keywords("bleh OR").should == "bleh or"
      @client.downcase_ending_keywords("bleh NOT").should == "bleh not"
    end
  end
end
