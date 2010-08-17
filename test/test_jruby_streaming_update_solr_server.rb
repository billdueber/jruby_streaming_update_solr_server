require 'helper'

class TestJrubyStreamingUpdateSolrServer < Test::Unit::TestCase
  should "Write some tests, but don't know how to mock up a solr server" do
    assert_equal 1, 1
  end

  should "Report nil for a document that doesn't include a field" do 
    doc = SolrInputDocument.new
    assert_equal nil, doc[:notinthere]
  end
  
  should "Return single and multiple values in arrays" do
    doc = SolrInputDocument.new
    doc << [:id, 1]
    assert_equal [1], doc[:id]
    doc << [:id, 2]
    assert_equal [1,2], doc[:id]
  end
  
  should "Add items in hash via merge!" do
    doc = SolrInputDocument.new
    doc << [:id, 1]
    h = {:id => 2, :name => 'Bill'}
    doc.merge! h
    assert_equal [1,2], doc[:id]
    assert_equal ['Bill'], doc[:name]
  end
  
  should "Allow additive_merge! as well" do
    doc = SolrInputDocument.new
    doc << [:id, 1]
    h = {:id => 2, :name => 'Bill'}
    doc.additive_merge! h
    assert_equal [1,2], doc[:id]
    assert_equal ['Bill'], doc[:name]
    
  end
  
  should "Destroy existing items via []=" do
    doc = SolrInputDocument.new
    doc[:id] = 1
    assert_equal [1], doc[:id]
    doc[:id] = 2
    assert_equal [2], doc[:id]
  end    
    

end
