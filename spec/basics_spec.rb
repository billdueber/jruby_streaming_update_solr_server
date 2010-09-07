require 'spec_helper'

describe "SolrDocument" do
  
  before do
    @doc = SolrInputDocument.new
  end
  
  it "starts out empty" do
    @doc.empty?.should.equal true
    @doc.size.should.equal 0
    @doc.values.should.equal []
    @doc.keys.should.equal []
  end
  
  it "reports nil for an unset field" do
    @doc['notinhere'].should.equal nil
  end
  
  it "sets using =" do
    @doc['t'] = 1
    @doc['t'].should.equal [1]
    @doc['t'] = 2
    @doc['t'].should.equal [2]
  end
  
  it "adds using <<" do
    @doc << ['t', 1]
    @doc['t'].should.equal [1]
    @doc << ['t', 2]
    @doc['t'].should.equal [1,2]
  end

  it "adds items in hash via merge!" do
    @doc << ['id', '1']
    h = {'id' => '2', 'name' => 'Bill'}
    @doc.merge! h
    @doc['id'].should.equal ['1', '2']
    @doc['name'].should.equal ['Bill']
    @doc.values.sort.should.equal ['1', '2','Bill'].sort
  end

  it "aliases additive_merge! as well" do
    @doc << ['id', 1]
    h = {'id' => 2, 'name' => 'Bill'}
    @doc.additive_merge! h
    @doc['id'].should.equal [1,2]
    @doc['name'].should.equal ['Bill']    
  end  
  
  it "correctly finds keys and values" do
    @doc << ['id', '1']
    @doc << ['name', 'Bill']
    @doc.has_key?('name').should.equal true
    @doc.has_key?('id').should.equal true
    @doc.has_key?('junk').should.equal false
    @doc.has_value?('1').should.equal true
    @doc.has_value?('Bill').should.equal true
    @doc.has_value?('junk').should.equal false
  end
  
  it "can add multiple items at once" do
    @doc.add('name', ['Bill', 'Mike', 'Molly'])
    @doc['name'].sort.should.equal ['Bill', 'Mike', 'Molly'].sort
  end
  
  it "boosts the doc" do
    @doc.boost = 100
    @doc.boost.should.equal 100
  end
  
  it "boosts a field" do
    @doc.add('id', '1')
    @doc.fieldBoost('id').should.equal 1.0
    @doc.setFieldBoost('id', 100.0)
    @doc.fieldBoost('id').should.equal 100.0
    @doc.setFieldBoost('junk', 100.0).should.equal nil
    @doc.fieldBoost('junk').should.equal nil
    
  end
  
end
