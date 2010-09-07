if not defined? JRUBY_VERSION
  raise "jruby streaming update solr server only runs under jruby"
end

# Load .jar files locally if they haven't already been pulled in.
begin
  include_class Java::org.apache.solr.client.solrj.impl.StreamingUpdateSolrServer
  include_class Java::org.apache.solr.common.SolrInputDocument
rescue NameError  => e
  jardir = File.join(File.dirname(__FILE__), '..', 'jars')
  Dir.glob("#{jardir}/*.jar") do |x|
    require x
  end  
  retry
end

# Sugar on top of the org.apache.solr.client.solr.impl.StreamingUpdateSolrServer
# 
# Note that several important methods, new and commit, are direct from the java and hence
# not represented here where I'm just opening up the class to add some sugar. Full documentation
# for the raw java methods is available at 
# http://lucene.apache.org/solr/api/org/apache/solr/client/solrj/impl/StreamingUpdateSolrServer.html
#
# A quick look at important java methods you can call:
# 
# <b>suss = StreamingUpdateSolrServer.new(solrURL, queueSize, numberOfThreads)</b>
#   The constructor.
#
#   [String] solrURL The URL to your solr instance (i.e., http://solr-machine:port/solr)
#   [Integer] queueSize The size of the queue from which consumer threads will pull
#     documents ready to be added to Solr and actually do the sending.
#   [Integer] numberOfThreads The number of consumer threads to do the sending-to-Solr
# 
# <b>suss.commit</b>
#   Send the commit to the solr server
#   
# <b>suss.optimize</b>
#   Send the optimize commnd to the Solr server
#
# <b>suss.deleteById(id)</b>
#
# <b>suss.deleteById([id1, id2, id3, ...])</b>
#   Delete the given ID or IDs
#
# <b>suss.deleteByQuery(query)</b>
#   Delete everything that matches +query+
#   [String] query A valid solr query. Everything that matches will be deleted. So, you can ditch
#     it all by sending, e.g., '*:*'
#
# @author Bill Dueber

class  StreamingUpdateSolrServer

  # Send requests using the Javabin binary format instead of serializing to XML
  # Requires /update/javabin to be defined in solrconfig.xml as 
  # <requestHandler name="/update/javabin" class="solr.BinaryUpdateRequestHandler" />
  
  def useJavabin!
    self.setRequestWriter Java::org.apache.solr.client.solrj.impl.BinaryRequestWriter.new
  end
  


  # Hang onto the java #add for internal use
  alias_method :sussadd, :add
  
  # Add a document to the SUSS 
  # @param [SolrInputDocument, #each_pair] doc The SolrInputDocument or hash (or hash-like object
  # that responds to #each_pair) to add. The latter must be of the form solrfield => value or
  # solrfield => [list, of, values]. They keys must be strings.
  #
  # @example Create and add a SolrInputDocument
  #   url = 'http://solrmachine:port/solr' # URL to solr
  #   queuesize = 10 # Size of producer cache 
  #   threads = 2 # Number of consumer threads to push docs from queue to solr
  #
  #   suss = StreamingUpdateSolrServer.new(url,queuesize,threads)
  #
  #   doc = SolrInputDocument.new
  #   doc << ['title', 'This is the title']
  #   doc << ['id', 1]
  #   suss.add doc  # or suss << doc
  #   # repeat as desired
  #   suss.commit
  #
  # @example Create and add as a hash
  #   # The "hash" just needs to be an object that responds to each_pair with field,value(s)
  #   suss = StreamingUpdateSolrServer.new(url,queuesize,threads)
  #   doc = {}
  #   doc['title'] = This is the title'
  #   doc['author'] = ['Bill', 'Mike']
  #   suss << doc
  #   # repeat as desired
  #   suss.commit
  
  def add doc
    if doc.is_a? org.apache.solr.common.SolrInputDocument
      sussadd doc
    elsif doc.respond_to? :each_pair
      newdoc = SolrInputDocument.new
      doc.each_pair do |f,v|
        newdoc << [f,v]
      end
      sussadd newdoc
    else
      raise ArgumentError "Need to pass either an org.apache.solr.common.SolrInputDocument or a hash"
    end
  end
  
  alias_method :<<, :add
  
end

# Add some sugar to the SolrInputDocument
#
# @author Bill Dueber

# SolrInputDocument is a wrapper around the {http://lucene.apache.org/solr/api/org/apache/solr/common/SolrInputDocument.html Java SolrInputDocument}. 
# In addition to the methods below, you can call the java methods directly. Common ones are:
# * `#clear` to empty the document

class SolrInputDocument
    
  # Add a value to a field. Will add all elements of an array in turn
  # @param [String] field The field to add a value or values to
  # @param [String, Numeric, #each] val The value or array-like of values to add.
  # @return [Array<String,Numeric>] An array of the field's values after this addition
  
  def add(field, val)
    return if val == nil
    if val.is_a? String or val.is_a? Numeric
      self.addField(field, val)
    else
      begin
        val.each {|v| self.add(field, v)}
      rescue NoMethodError => e
        raise NoMethodError, "SolrInputDocument values must be a string, numeric, or an array-like (responds to #each) of same, not #{val.inspect}"
      end
    end
    self[field]
  end  
  
  
  # An alternate syntax for #add.
  #
  # @param [Array<String>] fv A two-element array of Strings of the form [field, value] or [field, [value1, value2, ...]]
  # @return [Array<String>] the list of current values for the field in fv[0]
  #
  # @example Add some fields
  #  doc = SolrInputDocument.new
  #  doc << ['title', 'Mein Kopf'] #=> ['Mein Kopf']
  #  doc << ['title', 'My Head!']  #=> ['Mein Kopf', 'My Head!']
  #  doc << ['author', ['Bill', 'Mike', 'Molly']] #=> ['Bill', 'Mike', 'Molly']
  
  def << fv
    field = fv[0]
    value = fv[1]
    self.add(field, value)
  end  
  
  # Get a list of the currently-set values for the passed field
  #
  # Note that this will always return either nil (not found) or an array, even of one element
  #
  # @param [String] field The field whose values you want (as String)
  # @return [Array<String>] An array of values (or nil on not found)
  #
  def [] field
    f = self.get(field)
    return nil if (f == nil)
    return f.values.to_a
  end
  
  # Set the value(s) for the given field, destroying any values that were already in there
  #
  # Note that this is destructive; see #<< to add multiple values to a field
  #
  # @param [String] field The solr field you're setting the value of
  # @param [String, Array<String>] value The value or array of values to set
  # @return [Array<String>] The list of values (i.e., either +value+ or +[value]+)
  #
  # @example
  #  doc = SolrInputDocument.new
  #  doc['id'] = 1 #=> [1]
  #  doc['author'] = 'Mike' #=> ['Mike']
  #  doc['author'] = 'Bill' #=> ['Bill']
  #  doc['author'] #=> ['Bill']
  
  def []= field, value
    self.removeField(field)
    self.add(field, value)
  end
  
  
  # Add keys and values from a hash or hash-like object to the document without removing any
  # already-added values.
  #
  # @param [#each_pair] h A set of field=>value pairs, probably in a Hash. Can be either 
  # field=>value or field=>[list,of,values]
  #
  # @example Merge a hash into an existing document
  #   doc = SolrInputDocument.new
  #   doc << ['author', 'Bill']
  #   h = {}
  #   h['author'] = 'Mike'
  #   h['id'] = 1
  #   h['copies'] = ['Grad reference', 'Long-term storage']
  #   doc.merge! h
  #   doc['id'] #=> 1
  #   doc['author'] #=> ['Bill', 'Mike']
  #   doc['copies'] #=> ['Grad reference', 'Long-term storage']
  
  def merge! h
    unless h.respond_to? :each_pair
      raise ArgumentError, "Argument must respond to #each_pair"
    end
    h.each_pair do |k,v|
      self.add(k, v)
    end
  end
  
  alias_method :additive_merge!, :merge!
  
  # pretty-print
  # @return A string representation of the fields and values
  def to_s
    return "SolrInputDocument #{self.object_id}\n  " + (self.keys.map {|k| "#{k} => #{self[k].inspect}"}).join("\n  ")
  end


  # Get the list of keys for this document
  # @return [Array<String>] The list of keys
  
  def keys
    return self.keySet.to_a
  end

  # Does this doc contain the given key?
  # @param [String] field The field whose presence you want to check
  # @return [Boolean] True if the key is present
  
  def has_key? field
    return self.containsKey(field)
  end

  # Does this doc have the given value?
  # @param [String] value to look for
  # @return [Boolean]
  
  def has_value? val
    self.keys.each do |k|
      return true if self[k].include? val
    end
    return false
  end
  
end


