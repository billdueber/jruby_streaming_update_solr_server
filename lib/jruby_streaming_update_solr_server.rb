
include_class Java::OrgApacheSolrClientSolrjImpl::StreamingUpdateSolrServer
include_class Java::OrgApacheSolrCommon::SolrInputDocument

class  StreamingUpdateSolrServer
  alias_method :susadd, :add 
  
  def add doc
    if doc.is_a? org.apache.solr.common.SolrInputDocument
      susadd doc
    elsif doc.respond_to? :each_pair
      newdoc = SolrInputDocument.new
      doc.each_pair do |f,v|
        newdoc << [f,v]
      end
      susadd newdoc
    else
      puts "ERROR: Need to pass either a org.apache.solr.common.SolrInputDocument or a hash"
    end
  end
  
  alias_method :<<, :add
  
end


class SolrInputDocument
  def << fv
    field = fv[0]
    value = fv[1]
    if field.is_a?(Symbol)
      field = field.to_s
    end
    if value.respond_to?(:each)
      value.each do |v|
        self.addField(field, v)
      end
    else
      self.addField(field, value)
    end
    self[field]
  end
  
  def [] field
    if field.is_a?(Symbol)
      field = field.to_s
    end
    f = self.get(field)
    return nil if (f == nil)
    
    v = f.value
    if v.class == Java::JavaUtil::ArrayList
      return v.to_a
    else 
      return v
    end
  end
  
  def []= field, value
    if field.is_a?(Symbol)
      field = field.to_s
    end
    self.setField(field, value)
    self[field]
  end
  
  def merge! h
    # throw an error unless h.respond_to?(:each_pair)
    h.each_pair do |k,v|
      self << [k,v]
    end
  end
end




